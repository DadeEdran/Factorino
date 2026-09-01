import 'package:factorino/data/database/encrypted_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the backup container's key handling (D-069).
///
/// The failures these prevent are all silent and all discovered at restore
/// time, which is the worst moment: the user is already relying on the file.
void main() {
  group('backupConnectionSetupStatements', () {
    test('keys with a passphrase, not with raw bytes', () {
      // The whole point of the container: sqlite3mc runs its SQLCipher KDF over
      // the passphrase, so the file is portable to the replacement device. The
      // live database is keyed the other way, x'..' raw, and confusing the two
      // would either skip the KDF or hand the KDF a hex string.
      final statements = backupConnectionSetupStatements('rmz-2026');
      final key = statements.firstWhere(
        (s) => s.trim().toLowerCase().startsWith('pragma key'),
      );

      expect(key, contains("'rmz-2026'"));
      expect(
        key,
        isNot(contains("x'")),
        reason: 'a passphrase keyed as raw bytes would skip the KDF',
      );
    });

    test('applies the key before anything that touches the database', () {
      // The same D-020 ordering as the live connection, asserted against the
      // same shared checker rather than against a copy of the rule.
      expect(
        () => assertKeyPrecedesDatabaseAccess(
          backupConnectionSetupStatements('rmz-2026'),
        ),
        returnsNormally,
      );
    });

    test('selects the SQLCipher-compatible format before keying', () {
      final statements = backupConnectionSetupStatements('rmz-2026');
      final cipher = statements.indexWhere(
        (s) => s.toLowerCase().contains('cipher'),
      );
      final legacy = statements.indexWhere(
        (s) => s.toLowerCase().contains('legacy'),
      );
      final key = statements.indexWhere(
        (s) => s.trim().toLowerCase().startsWith('pragma key'),
      );

      expect(cipher, lessThan(key));
      expect(legacy, lessThan(key));
    });

    test('refuses an empty passphrase', () {
      // Under SQLCipher semantics an empty key produces an UNENCRYPTED
      // database. A backup is the entire customer and invoice database in one
      // portable file, so this is the one outcome it may never have.
      expect(
        () => backupConnectionSetupStatements(''),
        throwsA(
          isA<BackupPassphraseRejected>().having(
            (e) => e.reason,
            'reason',
            BackupPassphraseProblem.empty,
          ),
        ),
      );
    });

    test('refuses a passphrase containing NUL', () {
      // NUL terminates the key inside the C API: the file would be keyed by a
      // prefix of what was typed and would then refuse the full password.
      expect(
        () => backupConnectionSetupStatements(
          String.fromCharCodes(<int>[114, 109, 0, 122]),
        ),
        throwsA(
          isA<BackupPassphraseRejected>().having(
            (e) => e.reason,
            'reason',
            BackupPassphraseProblem.containsNul,
          ),
        ),
      );
    });

    test('an exception carries no passphrase', () {
      // Nothing about a backup is logged, and toString() is what ends up in a
      // crash report (D-069).
      const secret = 'the-user-actual-password';
      try {
        backupConnectionSetupStatements(
          String.fromCharCodes(<int>[...secret.codeUnits, 0]),
        );
        fail('expected a rejection');
      } on BackupPassphraseRejected catch (e) {
        expect(e.toString(), isNot(contains(secret)));
      }
    });
  });

  group('escapeSqlStringLiteral', () {
    // `pragma key` cannot take a bound variable, so this escaping is the
    // reviewed exception D-018 allows for -- and getting it wrong is a
    // data-loss bug rather than a syntax error, because the file would be
    // keyed with a string other than the one the user typed.
    test('doubles a single quote', () {
      expect(escapeSqlStringLiteral("o'brien"), "o''brien");
    });

    test('doubles every single quote, not only the first', () {
      expect(escapeSqlStringLiteral("a'b'c"), "a''b''c");
    });

    test('leaves a passphrase without quotes untouched', () {
      expect(escapeSqlStringLiteral('rmz-2026'), 'rmz-2026');
    });

    test('does not escape backslashes', () {
      // SQLite string literals have no backslash escape: doubling one here
      // would change the key.
      expect(escapeSqlStringLiteral(r'a\b'), r'a\b');
    });

    test('produces a literal that closes exactly once', () {
      // The property that actually matters: after escaping, the only unescaped
      // quotes in "'<escaped>'" are the delimiters.
      const passphrase = "'; drop table customers; --";
      final literal = "'${escapeSqlStringLiteral(passphrase)}'";
      final inner = literal.substring(1, literal.length - 1);

      var i = 0;
      var lone = 0;
      while (i < inner.length) {
        if (inner[i] == "'") {
          if (i + 1 < inner.length && inner[i + 1] == "'") {
            i += 2;
            continue;
          }
          lone++;
        }
        i++;
      }
      expect(lone, 0, reason: 'the literal would terminate early: $literal');
    });
  });
}
