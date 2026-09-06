import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter/foundation.dart';
import 'package:factorino/core/security/database_encryption_key.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// The D-020 proof, on a real Android device and on Windows.
///
/// A Dart-VM probe cannot stand in for this. The question is not whether
/// sqlite3mc can encrypt -- that was settled on the VM -- but whether the
/// native library is found through Flutter's own packaging path at runtime,
/// and whether the OS keystore hands back the same key on the real platform.
/// Both are exactly what a VM probe skips.
///
/// Run:
///   flutter test integration_test/d020_encryption_proof_test.dart -d `device`
///   flutter test integration_test/d020_encryption_proof_test.dart -d windows

/// A minimal drift database. Deliberately schema-less and defined here rather
/// than in `lib/`: the real schema is Phase 1 work, and what is under proof is
/// the connection, which every drift database shares.
class _ProofDatabase extends GeneratedDatabase {
  _ProofDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 1;
}

const String _sentinel = 'sentinel-value-42-national-id-stand-in';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;

  setUpAll(() async {
    support = await getApplicationSupportDirectory();
    debugPrint(
      '=== D-020 PROOF on ${Platform.operatingSystem} '
      '(${Platform.operatingSystemVersion}) ===',
    );
    debugPrint('sqlite3 library : ${sqlite3.version}');
    debugPrint('database dir: ${support.path}');
  });

  File proofFile(String name) =>
      File('${support.path}${Platform.pathSeparator}$name');

  void discard(File file) {
    for (final path in <String>[
      file.path,
      '${file.path}-wal',
      '${file.path}-shm',
      '${file.path}-journal',
    ]) {
      final f = File(path);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } on FileSystemException {
          // Windows may still hold a handle; the next run overwrites it.
        }
      }
    }
  }

  testWidgets('the database directory is per-user app storage', (_) async {
    // the project spec: %APPDATA% on Windows, app-private storage on Android --
    // never beside the executable, never on shared external storage.
    debugPrint('resolved dir: ${support.path}');
    if (Platform.isWindows) {
      expect(support.path.toLowerCase(), contains('appdata'));
      expect(support.path.toLowerCase(), isNot(contains('program files')));
    }
    if (Platform.isAndroid) {
      expect(support.path, startsWith('/data'));
    }
  });

  testWidgets('the OS keystore returns a stable 256-bit key', (_) async {
    const store = SecureStorageDatabaseKeyStore();

    final first = await store.obtain();
    final second = await store.obtain();

    expect(first.hex.length, DatabaseEncryptionKey.lengthBytes * 2);
    expect(
      second.hex,
      equals(first.hex),
      reason: 'a key that changes between launches orphans the database',
    );
    expect(first.toString(), isNot(contains(first.hex)));
    debugPrint(
      'keystore: stable key, '
      '${DatabaseEncryptionKey.lengthBytes * 8}-bit, value not logged',
    );
  });

  testWidgets('drift writes an encrypted database that rejects a wrong key', (
    _,
  ) async {
    final file = proofFile('d020_proof.db');
    discard(file);

    final key = await const SecureStorageDatabaseKeyStore().obtain();

    // ---- write through drift, over the production opener -----------------
    final database = _ProofDatabase(
      openEncryptedDatabase(file: file, key: key),
    );
    await database.customStatement(
      'create table proof (id integer primary key, secret text not null)',
    );
    await database.customStatement(
      'insert into proof (secret) values (?)',
      <Object?>[_sentinel],
    );
    final foreignKeys = await database
        .customSelect('pragma foreign_keys')
        .getSingle();
    await database.close();

    expect(
      foreignKeys.data.values.first,
      1,
      reason: 'foreign keys must be on for this connection (D-017)',
    );

    // ---- 1. the file header is the evidence, not any pragma --------------
    final state = inspectDatabaseFile(file);
    final header = file.readAsBytesSync().take(16).toList();
    debugPrint(
      'header bytes: ${header.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
    );
    debugPrint('file state: ${state.name}');
    expect(state, DatabaseFileState.encrypted);
    expect(() => assertDatabaseFileIsEncrypted(file), returnsNormally);

    // ---- 2. the plaintext must not be recoverable from the raw bytes -----
    final raw = String.fromCharCodes(file.readAsBytesSync());
    expect(
      raw.contains(_sentinel),
      isFalse,
      reason: 'plaintext leaked to disk',
    );
    debugPrint('sentinel on disk: absent');

    // ---- 3. reopening without the key must be rejected -------------------
    Object? unkeyedError;
    try {
      final unkeyed = sqlite3.open(file.path);
      unkeyed.select('select secret from proof');
      unkeyed.close();
    } catch (error) {
      unkeyedError = error;
    }
    expect(
      unkeyedError,
      isNotNull,
      reason: 'the database opened without a key',
    );
    debugPrint(
      'unkeyed reopen: REJECTED -- '
      '${unkeyedError.toString().split('\n').first}',
    );

    // ---- 4. reopening with the wrong key must be rejected ----------------
    final wrongKey = DatabaseEncryptionKey.generate();
    Object? wrongKeyError;
    try {
      final wrong = _ProofDatabase(
        openEncryptedDatabase(file: file, key: wrongKey),
      );
      await wrong.customSelect('select secret from proof').get();
      await wrong.close();
    } catch (error) {
      wrongKeyError = error;
    }
    expect(wrongKeyError, isNotNull, reason: 'a wrong key was accepted');
    debugPrint('wrong-key reopen: REJECTED');

    // ---- 5. reopening with the right key must return the row -------------
    final reopened = _ProofDatabase(
      openEncryptedDatabase(file: file, key: key),
    );
    final rows = await reopened.customSelect('select secret from proof').get();
    await reopened.close();

    expect(rows, hasLength(1));
    expect(rows.single.data['secret'], _sentinel);
    debugPrint('keyed reopen: 1 row, value intact');

    discard(file);
  });

  testWidgets('a statement before the key yields a plaintext database', (
    _,
  ) async {
    // The hazard D-020 exists for, reproduced on the real platform: the file
    // ends up unencrypted *and* the error blames corruption. The startup
    // assertion is what turns this into a loud failure.
    final file = proofFile('d020_ordering.db');
    discard(file);

    final key = await const SecureStorageDatabaseKeyStore().obtain();
    final raw = sqlite3.open(file.path);
    raw.execute('create table early (x integer)'); // one statement too soon

    Object? keyError;
    try {
      raw.execute("pragma cipher = 'sqlcipher'");
      raw.execute('pragma legacy = 4');
      raw.execute('pragma key = "x\'${key.hex}\'"');
      raw.execute('create table late (y integer)');
    } catch (error) {
      keyError = error;
    }
    raw.close();

    debugPrint('out-of-order: ${keyError ?? 'no error raised'}');
    debugPrint('resulting file: ${inspectDatabaseFile(file).name}');

    expect(
      inspectDatabaseFile(file),
      DatabaseFileState.plaintextSqlite,
      reason: 'the hazard did not reproduce; re-read D-020 before relaxing it',
    );

    // The whole point of the startup assertion: this must not be survivable.
    expect(
      () => assertDatabaseFileIsEncrypted(file),
      throwsA(isA<DatabaseEncryptionFailure>()),
    );
    // And the opener must refuse the file rather than write more data into it.
    expect(
      () => openEncryptedDatabase(file: file, key: key),
      throwsA(isA<DatabaseEncryptionFailure>()),
    );
    debugPrint('startup assert: caught the plaintext database');

    discard(file);
  });

  testWidgets('PRAGMA cipher_version and PRAGMA cipher are false witnesses', (
    _,
  ) async {
    // A tripwire, not a behavioural requirement. If either of these ever starts
    // reporting something truthful, D-020's "named traps" section is stale --
    // but until then, neither may be used as evidence of encryption.
    final unencrypted = sqlite3.openInMemory();
    final version = unencrypted.select('pragma cipher_version');
    final reported = version.isEmpty
        ? '(empty)'
        : version.first.values.first.toString();

    unencrypted.execute("pragma cipher = 'sqlcipher'");
    final echoed = unencrypted.select('pragma cipher');
    final echoedValue = echoed.isEmpty
        ? '(empty)'
        : echoed.first.values.first.toString();
    unencrypted.close();

    debugPrint('cipher_version: $reported   <- unusable as an assertion');
    debugPrint(
      'cipher echo: $echoedValue   <- configured value, not the '
      "file's actual cipher",
    );

    expect(
      version.isEmpty || reported.isEmpty,
      isTrue,
      reason: 'cipher_version now reports a value; revisit D-020',
    );
    expect(
      echoedValue,
      'sqlcipher',
      reason: 'this connection has no key at all, yet the pragma agrees',
    );
  });
}
