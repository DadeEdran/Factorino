import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// The Phase 6 (a) container proof, on a real Android device and on Windows.
///
/// D-069 makes a backup an encrypted SQLite database keyed by the user's
/// password, which buys the KDF and the per-page HMAC from a library already
/// shipping instead of hand-rolling either. **That claim is worth exactly as
/// much as the proof of it**, and a Dart-VM probe cannot supply it: what is
/// under test is the native library reached through Flutter's packaging path
/// on the real platform.
///
/// Four questions, in the D-020 style:
///   1. Is the file actually encrypted on disk?
///   2. Does the right passphrase open it and return the data?
///   3. Does the WRONG passphrase fail cleanly, before touching anything?
///   4. Does a tampered byte fail authentication rather than being read?
///
/// Run:
///   flutter test integration_test/backup_container_proof_test.dart -d `device`
///   flutter test integration_test/backup_container_proof_test.dart -d windows

/// A schema-less drift database, as in the D-020 proof: what is under test is
/// the connection, which every drift database shares.
class _ContainerDatabase extends GeneratedDatabase {
  _ContainerDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 1;
}

/// Stands in for a national ID: something whose presence in the raw bytes would
/// prove the file is readable without the key.
const String _sentinel = 'sentinel-0069543210-national-id-stand-in';

/// Deliberately carries an apostrophe. `pragma key` cannot take a bound
/// variable, so the passphrase reaches SQL through `escapeSqlStringLiteral`,
/// and a quote is exactly what would break it -- silently, by keying the file
/// with something other than what the user typed (D-069).
const String _rightPassphrase = "correct horse's battery staple";

/// One character shorter than the right one.
const String _wrongPassphrase = "correct horse's battery stapl";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;

  setUpAll(() async {
    support = await getApplicationSupportDirectory();
    debugPrint(
      '=== BACKUP CONTAINER PROOF (D-069) on ${Platform.operatingSystem} '
      '(${Platform.operatingSystemVersion}) ===',
    );
    debugPrint('sqlite3 library : ${sqlite3.version}');
  });

  File containerFile(String name) =>
      File('${support.path}${Platform.pathSeparator}$name');

  void discard(File file) {
    for (final path in <String>[
      file.path,
      '${file.path}-wal',
      '${file.path}-shm',
    ]) {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    }
  }

  /// Writes a container holding [_sentinel] and closes it properly.
  Future<void> writeContainer(File file, String passphrase) async {
    final db = _ContainerDatabase(
      openPassphraseKeyedDatabase(file: file, passphrase: passphrase),
    );
    await db.customStatement(
      'create table if not exists backup_meta ('
      'format_version integer not null, note text not null)',
    );
    await db.customStatement(
      'insert into backup_meta (format_version, note) values (?, ?)',
      <Object?>[1, _sentinel],
    );
    await db.close();
  }

  testWidgets('the container on disk is encrypted', (WidgetTester _) async {
    final file = containerFile('proof_encrypted.backup');
    discard(file);
    addTearDown(() => discard(file));

    await writeContainer(file, _rightPassphrase);

    expect(
      inspectDatabaseFile(file),
      DatabaseFileState.encrypted,
      reason: 'the container carries the plaintext SQLite header',
    );

    // The stronger check: the sentinel must not be findable in the raw bytes.
    // A file can fail to start with the magic and still leak its contents.
    final bytes = await file.readAsBytes();
    final haystack = String.fromCharCodes(bytes);
    expect(
      haystack.contains(_sentinel),
      isFalse,
      reason: 'the sentinel is readable in the raw file: NOT encrypted',
    );
    debugPrint('container size  : ${bytes.length} bytes, sentinel absent');
  });

  testWidgets('the right passphrase reopens it and returns the data', (
    WidgetTester _,
  ) async {
    final file = containerFile('proof_roundtrip.backup');
    discard(file);
    addTearDown(() => discard(file));

    await writeContainer(file, _rightPassphrase);

    // Reopened as a separate connection, which is what a restore does -- and
    // what an export must do before reporting success (D-069), since a keying
    // fault is otherwise discovered only when the user needs the file.
    final reopened = _ContainerDatabase(
      openPassphraseKeyedDatabase(file: file, passphrase: _rightPassphrase),
    );
    addTearDown(reopened.close);

    final rows = await reopened
        .customSelect('select format_version, note from backup_meta')
        .get();

    expect(rows, hasLength(1));
    expect(rows.single.read<int>('format_version'), 1);
    expect(rows.single.read<String>('note'), _sentinel);
  });

  testWidgets('a passphrase differing by one character is refused', (
    WidgetTester _,
  ) async {
    final file = containerFile('proof_wrong_passphrase.backup');
    discard(file);
    addTearDown(() => discard(file));

    await writeContainer(file, _rightPassphrase);
    final sizeBefore = file.lengthSync();

    // The failure must land at OPEN time. If it surfaced later, at some
    // arbitrary query, a partially-applied import would already be possible.
    Object? thrown;
    try {
      final db = _ContainerDatabase(
        openPassphraseKeyedDatabase(file: file, passphrase: _wrongPassphrase),
      );
      await db.customSelect('select 1').get();
      await db.close();
    } catch (error) {
      thrown = error;
    }

    expect(
      thrown,
      isNotNull,
      reason: 'the wrong passphrase opened the container',
    );
    debugPrint('wrong passphrase: ${thrown.runtimeType}');

    // And it must leave the file alone -- a refusal that truncated the user's
    // only backup would be worse than the thing it refused.
    expect(file.lengthSync(), sizeBefore);
  });

  testWidgets('a tampered byte fails authentication', (WidgetTester _) async {
    final file = containerFile('proof_tampered.backup');
    discard(file);
    addTearDown(() => discard(file));

    await writeContainer(file, _rightPassphrase);

    // Flip one byte well inside the file, past the header. Under SQLCipher's
    // per-page HMAC-SHA512 this must fail authentication rather than decrypt
    // to plausible garbage -- that HMAC is the integrity check D-069 relies on
    // instead of adding a second one of our own.
    final bytes = await file.readAsBytes();
    final offset = min(2048, bytes.length - 1);
    bytes[offset] = bytes[offset] ^ 0xFF;
    await file.writeAsBytes(bytes, flush: true);

    Object? thrown;
    try {
      final db = _ContainerDatabase(
        openPassphraseKeyedDatabase(file: file, passphrase: _rightPassphrase),
      );
      await db.customSelect('select note from backup_meta').get();
      await db.close();
    } catch (error) {
      thrown = error;
    }

    expect(
      thrown,
      isNotNull,
      reason:
          'a tampered container was read without complaint at byte $offset; '
          'the per-page HMAC is not doing what D-069 assumes',
    );
    debugPrint('tampered byte   : ${thrown.runtimeType}');
  });

  testWidgets('an empty passphrase is refused before a file is created', (
    WidgetTester _,
  ) async {
    // An empty key yields an UNENCRYPTED database under SQLCipher semantics.
    // Asserted here as well as in the unit test because the unit test checks
    // the statement list, and this checks that nothing reaches the disk.
    final file = containerFile('proof_empty_passphrase.backup');
    discard(file);
    addTearDown(() => discard(file));

    expect(
      () => openPassphraseKeyedDatabase(file: file, passphrase: ''),
      throwsA(isA<BackupPassphraseRejected>()),
    );
    expect(file.existsSync(), isFalse);
  });
}
