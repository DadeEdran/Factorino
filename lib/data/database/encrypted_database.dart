import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';

import '../../core/security/database_encryption_key.dart';

/// The 16 magic bytes at the start of every unencrypted SQLite file:
/// `SQLite format 3` followed by a NUL.
///
/// An encrypted database does not begin with these bytes -- that is the only
/// reliable, implementation-independent evidence that encryption is actually
/// on. See [inspectDatabaseFile] and the traps documented in D-020.
final String kSqliteFormat3Magic = 'SQLite format 3${String.fromCharCode(0)}';

/// What is actually on disk at a database path.
enum DatabaseFileState {
  /// No file at this path yet -- normal on first launch.
  absent,

  /// The file exists but is shorter than the SQLite header, so nothing can be
  /// concluded from it. A zero-length file is what SQLite leaves behind when a
  /// connection is opened but nothing is ever written.
  tooShortToJudge,

  /// The file begins with `SQLite format 3` -- it is an **unencrypted**
  /// database. If this is ever the application's database, encryption at rest
  /// has failed and the data is readable by anyone holding the file.
  plaintextSqlite,

  /// The file does not carry the plaintext SQLite header.
  encrypted,
}

/// Raised when the database on disk is not encrypted, or when the connection
/// setup order that guarantees encryption has been violated.
///
/// Deliberately not a user-facing failure: there is no Persian message and no
/// recovery path, because continuing would mean writing financial records and
/// third-party national IDs to an unencrypted file.
class DatabaseEncryptionFailure implements Exception {
  const DatabaseEncryptionFailure(this.message);

  final String message;

  @override
  String toString() => 'DatabaseEncryptionFailure: $message';
}

/// Statements permitted to precede `pragma key`.
///
/// This list is deliberately tiny and exact. Under `sqlite3mc` the cipher must
/// be selected *before* the key is applied, so "key first, unconditionally" is
/// not implementable -- but every statement that reads or writes the database
/// must still come after the key. Anything not named here is such a statement.
/// See D-020.
const List<String> kPragmasAllowedBeforeKey = <String>[
  'pragma cipher',
  'pragma legacy',
];

const String _keyPragmaPrefix = 'pragma key';

/// The exact, ordered statement sequence issued on every connection.
///
/// Pure and separately testable, so the ordering guarantee is asserted against
/// the same list the application actually executes rather than against a copy
/// of it in a test.
List<String> connectionSetupStatements(DatabaseEncryptionKey key) {
  return <String>[
    // 1. Select the SQLCipher-compatible on-disk format. This MUST precede the
    //    key: issued afterwards it is silently ignored, and the file is
    //    written with the sqlite3mc default cipher instead (D-020).
    "pragma cipher = 'sqlcipher';",
    'pragma legacy = 4;',

    // 2. Apply the key. Everything that touches the database comes after this.
    //    Raw 256-bit key in x'..' form, so no KDF runs and no passphrase
    //    escaping is involved.
    'pragma key = "x\'${key.hex}\'";',

    // 3. Foreign keys are off by default in SQLite and must be enabled per
    //    connection (D-017).
    'pragma foreign_keys = on;',
  ];
}

/// Throws unless [statements] apply the key before anything that could touch
/// the database.
///
/// Runs in production, not only in tests: it is cheap, and the failure it
/// prevents is an unencrypted database.
void assertKeyPrecedesDatabaseAccess(List<String> statements) {
  var keyIndex = -1;
  for (var i = 0; i < statements.length; i++) {
    final normalized = statements[i].trim().toLowerCase();
    if (normalized.startsWith(_keyPragmaPrefix)) {
      keyIndex = i;
      break;
    }
    final allowed = kPragmasAllowedBeforeKey.any(normalized.startsWith);
    if (!allowed) {
      throw DatabaseEncryptionFailure(
        'statement ${i + 1} of the connection setup runs before "pragma key" '
        'and is not a cipher-configuration pragma. On a new file this writes a '
        'plaintext database; on an existing one it fails with "file is not a '
        'database", which points at corruption rather than at the real cause. '
        'See DECISIONS.md D-020.',
      );
    }
  }
  if (keyIndex < 0) {
    throw const DatabaseEncryptionFailure(
      'the connection setup never issues "pragma key"; the database would be '
      'unencrypted. See DECISIONS.md D-020.',
    );
  }
}

/// Issues the setup sequence through [execute], in order, after checking it.
///
/// [execute] is injected so the ordering can be observed in a test without a
/// real database.
void applyConnectionSetup(
  void Function(String sql) execute,
  DatabaseEncryptionKey key,
) {
  final statements = connectionSetupStatements(key);
  assertKeyPrecedesDatabaseAccess(statements);
  for (final statement in statements) {
    execute(statement);
  }
}

/// Reads the first bytes of [file] and classifies it.
DatabaseFileState inspectDatabaseFile(File file) {
  if (!file.existsSync()) return DatabaseFileState.absent;

  final handle = file.openSync();
  try {
    final header = handle.readSync(kSqliteFormat3Magic.length);
    if (header.length < kSqliteFormat3Magic.length) {
      return DatabaseFileState.tooShortToJudge;
    }
    return String.fromCharCodes(header) == kSqliteFormat3Magic
        ? DatabaseFileState.plaintextSqlite
: DatabaseFileState.encrypted;
  } finally {
    handle.closeSync();
  }
}

/// Startup assertion: the database on disk must not be a plaintext SQLite file.
///
/// Call once at startup, after the database has been opened and its first
/// statement has run (before that the file may not exist yet). Failing loudly
/// here is the point: a silently unencrypted database is the exact outcome
/// D-020 exists to prevent, and it is invisible from the app's behaviour.
void assertDatabaseFileIsEncrypted(File file) {
  final state = inspectDatabaseFile(file);
  switch (state) {
    case DatabaseFileState.encrypted:
      return;
    case DatabaseFileState.plaintextSqlite:
      throw const DatabaseEncryptionFailure(
        'the database file begins with "SQLite format 3": it is NOT encrypted. '
        'Refusing to continue -- financial records and national IDs would be '
        'written in the clear. See DECISIONS.md D-020.',
      );
    case DatabaseFileState.absent:
    case DatabaseFileState.tooShortToJudge:
      throw DatabaseEncryptionFailure(
        'cannot verify encryption: the database file is ${state.name}. This '
        'assertion must run after the database has been opened and written to.',
      );
  }
}

/// **The only way this application opens its database.**
///
/// Nothing else may construct a [NativeDatabase] or call `sqlite3.open`; a test
/// scans `lib/` and fails if anything does. Centralising it is what makes the
/// D-020 ordering a property of the codebase rather than of developer memory.
QueryExecutor openEncryptedDatabase({
  required File file,
  required DatabaseEncryptionKey key,
  bool logStatements = false,
}) {
  // An existing plaintext file must never be opened and written to as if it
  // were fine -- it would mean earlier data had been stored in the clear.
  final existing = inspectDatabaseFile(file);
  if (existing == DatabaseFileState.plaintextSqlite) {
    throw const DatabaseEncryptionFailure(
      'refusing to open an "SQLite format 3" (unencrypted) database file. '
      'See DECISIONS.md D-020.',
    );
  }

  file.parent.createSync(recursive: true);

  return NativeDatabase(
    file,
    logStatements: logStatements,
    setup: (CommonDatabase database) {
      applyConnectionSetup(database.execute, key);

      // Force page 1 to be decrypted now. Without this, a wrong key or a
      // broken order surfaces later, at an arbitrary query, as "file is not a
      // database" -- the misleading corruption error from D-020.
      // soft-delete-exempt: sqlite3's own API on schema metadata, not a
      // drift query over user rows.
      database.select('select count(*) from sqlite_master;');
    },
  );
}

/// Raised when a backup passphrase cannot be used as a key.
///
/// Separate from [DatabaseEncryptionFailure] because this one is reachable from
/// user input, so (c) maps it to a Persian message. It carries no passphrase and
/// no path: nothing about a backup is logged (D-069).
class BackupPassphraseRejected implements Exception {
  const BackupPassphraseRejected(this.reason);

  /// Machine-readable, never user-facing. The Persian copy is the UI's job.
  final BackupPassphraseProblem reason;

  @override
  String toString() => 'BackupPassphraseRejected: ${reason.name}';
}

enum BackupPassphraseProblem {
  /// The empty string. Under SQLCipher semantics an empty key produces an
  /// **unencrypted** database -- the one outcome a backup may never have.
  empty,

  /// Contains a NUL, which terminates the key early inside the C API: the file
  /// would be keyed by a prefix of what the user typed, and would then refuse
  /// the full password on restore.
  containsNul,
}

/// Escapes a string for a single-quoted SQL literal by doubling quotes.
///
/// `pragma key` cannot take a bound variable -- pragmas are not parameterizable
/// in SQLite -- so D-018's "bound variables always" is not implementable here
/// and this is the reviewed exception it allows for. The escaping is the whole
/// of the exception: nothing else about the statement is built from input.
///
/// Getting this wrong is not a syntax error, it is a **data-loss** bug: the file
/// would be keyed with a string other than the one the user typed and would
/// refuse that password on restore. The mitigation is not this function alone --
/// an export is not reported successful until the finished file has been
/// **reopened with the same passphrase** (D-069).
String escapeSqlStringLiteral(String value) => value.replaceAll("'", "''");

/// The setup sequence for the **backup container** (D-069).
///
/// Identical in shape to [connectionSetupStatements] and different in exactly
/// one way: the key is a **passphrase**, not raw bytes, so sqlite3mc runs its
/// SQLCipher-compatible KDF -- PBKDF2-HMAC-SHA512 at 256,000 iterations -- and
/// the file is portable to the replacement device that will have to read it.
/// The live database goes the other way, `x'..'` raw, because its key comes from
/// the platform keystore and must not be run through a KDF at all.
List<String> backupConnectionSetupStatements(String passphrase) {
  if (passphrase.isEmpty) {
    throw const BackupPassphraseRejected(BackupPassphraseProblem.empty);
  }
  if (passphrase.codeUnits.contains(0)) {
    throw const BackupPassphraseRejected(BackupPassphraseProblem.containsNul);
  }
  return <String>[
    "pragma cipher = 'sqlcipher';",
    'pragma legacy = 4;',
    "pragma key = '${escapeSqlStringLiteral(passphrase)}';",
    'pragma foreign_keys = on;',
  ];
}

/// Opens the backup container at [file], keyed by [passphrase].
///
/// The second sanctioned opener, and deliberately in this same file: exactly one
/// file in `lib/` may open a database (`single_open_path_test.dart`), and adding
/// a second one would have meant loosening the check that makes D-020
/// structural rather than remembered.
///
/// On a **wrong passphrase** the `sqlite_master` read below throws rather than
/// returning empty -- page 1 fails authentication. That is the intended
/// behaviour and the reason the read is here: the failure lands at open time,
/// before anything has been read or written, instead of at an arbitrary later
/// query.
QueryExecutor openPassphraseKeyedDatabase({
  required File file,
  required String passphrase,
  bool logStatements = false,
}) {
  final existing = inspectDatabaseFile(file);
  if (existing == DatabaseFileState.plaintextSqlite) {
    throw const DatabaseEncryptionFailure(
      'refusing to open an "SQLite format 3" (unencrypted) file as a backup '
      'container. A plaintext backup is the whole customer and invoice '
      'database in the clear. See DECISIONS.md D-069.',
    );
  }

  // Built and checked HERE, eagerly, not inside `setup`. `NativeDatabase`'s
  // setup closure is lazy -- it runs on first use of the connection, not at
  // construction -- so a guard living only in there would let a caller hold an
  // apparently-valid executor for an empty passphrase, and would create the
  // file before refusing. Found by the proof test on Windows, which is what it
  // was written for.
  final statements = backupConnectionSetupStatements(passphrase);
  assertKeyPrecedesDatabaseAccess(statements);

  file.parent.createSync(recursive: true);

  return NativeDatabase(
    file,
    logStatements: logStatements,
    setup: (CommonDatabase database) {
      for (final statement in statements) {
        database.execute(statement);
      }

      // Forces page 1 to be decrypted and authenticated now -- see above.
      // soft-delete-exempt: sqlite3's own API on schema metadata, not a drift
      // query over user rows.
      database.select('select count(*) from sqlite_master;');
    },
  );
}

/// Where the database lives: `%APPDATA%` on Windows, app-private storage on
/// Android -- never beside the executable.
Future<File> defaultDatabaseFile({String name = 'factorino.db'}) async {
  final directory = await getApplicationSupportDirectory();
  return File('${directory.path}${Platform.pathSeparator}$name');
}
