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
