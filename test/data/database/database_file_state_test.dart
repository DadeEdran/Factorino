import 'dart:io';
import 'dart:typed_data';

import 'package:factorino/core/security/database_encryption_key.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// The startup assertion required by D-020: the on-disk header is the evidence
/// that encryption is on. `PRAGMA cipher_version` is not -- it returns empty
/// under sqlite3mc even on a correctly encrypted database, and `PRAGMA cipher`
/// echoes back whatever was configured on the connection regardless of what the
/// file actually is. Both would read as success on a plaintext file.
void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync('factorino_hdr'));
  tearDown(() {
    try {
      directory.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows can hold the handle briefly; irrelevant to the assertion.
    }
  });

  File write(String name, List<int> bytes) {
    final file = File('${directory.path}${Platform.pathSeparator}$name');
    file.writeAsBytesSync(Uint8List.fromList(bytes));
    return file;
  }

  test('classifies a plaintext SQLite file', () {
    final file = write('plain.db', <int>[
      ...'SQLite format 3'.codeUnits,
      0,
      16,
      0,
      1,
      1,
      0,
      64,
      32,
      32,
    ]);
    expect(inspectDatabaseFile(file), DatabaseFileState.plaintextSqlite);
  });

  test('classifies an encrypted file', () {
    final file = write(
      'enc.db',
      List<int>.generate(64, (i) => (i * 37) % 251 + 1),
    );
    expect(inspectDatabaseFile(file), DatabaseFileState.encrypted);
  });

  test('classifies a missing and a truncated file', () {
    expect(
      inspectDatabaseFile(File('${directory.path}/nope.db')),
      DatabaseFileState.absent,
    );
    expect(
      inspectDatabaseFile(write('short.db', <int>[1, 2, 3])),
      DatabaseFileState.tooShortToJudge,
    );
    expect(
      inspectDatabaseFile(write('empty.db', <int>[])),
      DatabaseFileState.tooShortToJudge,
    );
  });

  group('assertDatabaseFileIsEncrypted', () {
    test('throws loudly on a plaintext database', () {
      final file = write('plain.db', <int>[
        ...'SQLite format 3'.codeUnits,
        0,
        16,
        0,
        1,
      ]);
      expect(
        () => assertDatabaseFileIsEncrypted(file),
        throwsA(
          isA<DatabaseEncryptionFailure>().having(
            (e) => e.message,
            'message',
            contains('NOT encrypted'),
          ),
        ),
      );
    });

    test('passes on an encrypted database', () {
      final file = write('enc.db', List<int>.generate(64, (i) => 255 - i));
      expect(() => assertDatabaseFileIsEncrypted(file), returnsNormally);
    });

    test('refuses to pass when it cannot see a materialised file', () {
      // Silence here would be the dangerous answer: "no file" must not read as
      // "encrypted".
      expect(
        () => assertDatabaseFileIsEncrypted(File('${directory.path}/nope.db')),
        throwsA(isA<DatabaseEncryptionFailure>()),
      );
      expect(
        () => assertDatabaseFileIsEncrypted(write('empty.db', <int>[])),
        throwsA(isA<DatabaseEncryptionFailure>()),
      );
    });
  });

  test('openEncryptedDatabase refuses an existing plaintext file', () {
    final file = write('existing.db', <int>[
      ...'SQLite format 3'.codeUnits,
      0,
      16,
      0,
      1,
    ]);
    expect(
      () => openEncryptedDatabase(
        file: file,
        key: DatabaseEncryptionKey.fromHex(
          '11' * DatabaseEncryptionKey.lengthBytes,
        ),
      ),
      throwsA(isA<DatabaseEncryptionFailure>()),
    );
  });
}
