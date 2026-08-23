import 'package:factorino/core/security/database_encryption_key.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the connection-open ordering that DECISIONS.md D-020 depends on.
///
/// These tests exist because the failure they prevent is invisible at runtime:
/// a statement issued before `pragma key` produces a plaintext database *and*
/// an exception that blames file corruption. Nothing in the application's
/// behaviour would reveal it.
void main() {
  final key = DatabaseEncryptionKey.fromHex(
    'ab' * DatabaseEncryptionKey.lengthBytes,
  );

  group('connectionSetupStatements', () {
    test('applies the key before anything that touches the database', () {
      final statements = connectionSetupStatements(key);
      final keyIndex = statements.indexWhere(
        (s) => s.trim().toLowerCase().startsWith('pragma key'),
      );

      expect(keyIndex, isNonNegative, reason: 'the key is never applied');

      for (var i = 0; i < keyIndex; i++) {
        final normalized = statements[i].trim().toLowerCase();
        expect(
          kPragmasAllowedBeforeKey.any(normalized.startsWith),
          isTrue,
          reason:
              'statement "${statements[i]}" precedes "pragma key" and is not a '
              'cipher-configuration pragma (D-020)',
        );
      }
    });

    test('selects the SQLCipher-compatible format before keying', () {
      // Order matters and is not interchangeable: issued after the key, this
      // pragma is silently ignored and the file is written with the sqlite3mc
      // default cipher instead. Verified empirically -- see D-020.
      final statements = connectionSetupStatements(key)
          .map((s) => s.toLowerCase())
          .toList();
      final cipher = statements.indexWhere(
        (s) => s.startsWith('pragma cipher'),
      );
      final legacy = statements.indexWhere(
        (s) => s.startsWith('pragma legacy'),
      );
      final keyIndex = statements.indexWhere((s) => s.startsWith('pragma key'));

      expect(cipher, isNonNegative);
      expect(legacy, isNonNegative);
      expect(cipher, lessThan(keyIndex));
      expect(legacy, lessThan(keyIndex));
    });

    test('enables foreign keys, after the key (D-017)', () {
      final statements = connectionSetupStatements(key)
          .map((s) => s.toLowerCase())
          .toList();
      final keyIndex = statements.indexWhere((s) => s.startsWith('pragma key'));
      final foreignKeys = statements.indexWhere(
        (s) => s.startsWith('pragma foreign_keys'),
      );

      expect(foreignKeys, isNonNegative);
      expect(foreignKeys, greaterThan(keyIndex));
    });

    test('carries the key as a raw hex blob, not a passphrase', () {
      final keyStatement = connectionSetupStatements(key)
          .firstWhere((s) => s.toLowerCase().startsWith('pragma key'));
      expect(keyStatement, contains("x'${key.hex}'"));
    });
  });

  group('assertKeyPrecedesDatabaseAccess', () {
    test('rejects a statement issued before the key', () {
      expect(
        () => assertKeyPrecedesDatabaseAccess(<String>[
          'create table early (x integer);',
          'pragma key = "x\'00\'";',
        ]),
        throwsA(isA<DatabaseEncryptionFailure>()),
      );
    });

    test('rejects an innocuous-looking read before the key', () {
      // `pragma user_version` is exactly what a version delegate would issue.
      // It reads page 1, so it decides the file format before the key exists.
      expect(
        () => assertKeyPrecedesDatabaseAccess(<String>[
          'pragma user_version;',
          'pragma key = "x\'00\'";',
        ]),
        throwsA(isA<DatabaseEncryptionFailure>()),
      );
    });

    test('rejects a sequence that never keys the connection', () {
      expect(
        () => assertKeyPrecedesDatabaseAccess(<String>[
          "pragma cipher = 'sqlcipher';",
          'pragma foreign_keys = on;',
        ]),
        throwsA(isA<DatabaseEncryptionFailure>()),
      );
    });

    test('accepts the sequence the application actually uses', () {
      expect(
        () => assertKeyPrecedesDatabaseAccess(connectionSetupStatements(key)),
        returnsNormally,
      );
    });
  });

  group('applyConnectionSetup', () {
    test('executes the statements in the declared order', () {
      final executed = <String>[];
      applyConnectionSetup(executed.add, key);

      expect(executed, equals(connectionSetupStatements(key)));
      expect(executed.first.toLowerCase(), startsWith('pragma cipher'));
      expect(
        executed.indexWhere((s) => s.toLowerCase().startsWith('pragma key')),
        lessThan(
          executed.indexWhere(
            (s) => s.toLowerCase().startsWith('pragma foreign_keys'),
          ),
        ),
      );
    });

    test('issues nothing at all when the order is invalid', () {
      // The check runs before the first execute, so a bad sequence cannot
      // half-apply and leave a partly configured connection behind.
      final executed = <String>[];
      try {
        assertKeyPrecedesDatabaseAccess(<String>['select 1;']);
        executed.add('select 1;');
      } on DatabaseEncryptionFailure {
        // expected
      }
      expect(executed, isEmpty);
    });
  });

  group('DatabaseEncryptionKey', () {
    test('generates a distinct 256-bit key each time', () {
      final a = DatabaseEncryptionKey.generate();
      final b = DatabaseEncryptionKey.generate();

      expect(a.hex.length, DatabaseEncryptionKey.lengthBytes * 2);
      expect(a.hex, isNot(equals(b.hex)));
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(a.hex), isTrue);
    });

    test('rejects malformed key material', () {
      expect(() => DatabaseEncryptionKey.fromHex('abc'), throwsArgumentError);
      expect(
        () => DatabaseEncryptionKey.fromHex(
          'zz' * DatabaseEncryptionKey.lengthBytes,
        ),
        throwsArgumentError,
      );
    });

    test('never renders the key material', () {
      final generated = DatabaseEncryptionKey.generate();
      expect(generated.toString(), isNot(contains(generated.hex)));
      expect('$generated', contains('redacted'));
    });
  });
}
