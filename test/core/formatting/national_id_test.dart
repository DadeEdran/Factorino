import 'package:factorino/core/formatting/national_id.dart';
import 'package:flutter_test/flutter_test.dart';

/// the project spec: national ID (کد ملی) checksum validation, **field optional**.
///
/// Every value here is synthetic: constructed from the published checksum rule
/// rather than taken from a real record.
void main() {
  /// The official rule, written out independently of the implementation so the
  /// tests below check the specification rather than echo the code.
  String withValidCheckDigit(String nineDigits) {
    assert(nineDigits.length == 9);
    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += (nineDigits.codeUnitAt(i) - 0x30) * (10 - i);
    }
    final remainder = sum % 11;
    final check = remainder < 2 ? remainder : 11 - remainder;
    return '$nineDigits$check';
  }

  group('the checksum', () {
    test('accepts known-good values', () {
      expect(isValidNationalId('0079542311'), isTrue);
      expect(isValidNationalId('1234567891'), isTrue);
    });

    test('rejects a wrong check digit', () {
      expect(isValidNationalId('1234567890'), isFalse);
      expect(isValidNationalId('0079542310'), isFalse);
    });

    test('accepts the correct check digit and rejects all nine others', () {
      // The property that makes the checksum worth having: exactly one of the
      // ten possible final digits is accepted.
      for (final prefix in <String>[
        '007954231',
        '123456789',
        '000000001',
        '999999998',
        '456789123',
      ]) {
        final valid = withValidCheckDigit(prefix);
        expect(isValidNationalId(valid), isTrue, reason: '$valid should pass');

        for (var d = 0; d <= 9; d++) {
          final candidate = '$prefix$d';
          if (candidate == valid) continue;
          expect(
            isValidNationalId(candidate),
            isFalse,
            reason: '$candidate should fail: only $valid checksums',
          );
        }
      }
    });

    test('catches a transposition, which is what the checksum is for', () {
      // Two adjacent digits swapped -- the commonest data-entry slip.
      expect(isValidNationalId('0079542311'), isTrue);
      expect(isValidNationalId('0079452311'), isFalse); // 54 -> 45
      expect(isValidNationalId('0097542311'), isFalse); // 79 -> 97
    });

    test(
      'a transposition can survive, and that is the algorithm, not a bug',
      () {
        // 0079542311 -> 0079542131 swaps the 3 and the 1, and still validates.
        //
        // The reason is in the rule itself: the check digit is `r` when the
        // remainder `r` is below 2 and `11 - r` otherwise, so remainders 1 and
        // 10 both produce the check digit 1. Any error that moves the weighted
        // sum between those two remainders is invisible to the check.
        //
        // Recorded as a test so nobody later "fixes" this by inventing a
        // stricter rule than the one the government issues numbers under. A
        // checksum narrows the space of typos; it does not close it.
        expect(isValidNationalId('0079542131'), isTrue);
      },
    );

    test('rejects ten repetitions of one digit even where the maths works', () {
      // Several of these satisfy the arithmetic; none are issued, and they are
      // what gets typed to get past a required field.
      for (var d = 0; d <= 9; d++) {
        final repeated = '$d' * 10;
        expect(
          isValidNationalId(repeated),
          isFalse,
          reason: '$repeated must be rejected',
        );
      }
    });
  });

  group('normalizeNationalId', () {
    test('folds all three digit sets', () {
      expect(normalizeNationalId('۰۰۷۹۵۴۲۳۱۱'), '0079542311');
      expect(normalizeNationalId('٠٠٧٩٥٤٢٣١١'), '0079542311');
      expect(normalizeNationalId('۰۰۷۹٥٤۲۳۱۱'), '0079542311');
    });

    test('accepts the separators people write on paper', () {
      expect(normalizeNationalId('0079-5423-11'), '0079542311');
      expect(normalizeNationalId('0079 5423 11'), '0079542311');
    });

    test('preserves leading zeros, which is why this is stored as text', () {
      final normalized = normalizeNationalId('0079542311');
      expect(normalized, '0079542311');
      expect(normalized!.startsWith('00'), isTrue);
    });

    test('rejects the wrong number of digits', () {
      expect(normalizeNationalId('123456789'), isNull);
      expect(normalizeNationalId('12345678901'), isNull);
    });

    test('rejects a value containing letters', () {
      expect(normalizeNationalId('00795423a1'), isNull);
      expect(normalizeNationalId('کد ملی'), isNull);
    });

    test('a Persian-digit ID validates through the checksum', () {
      expect(isValidNationalId('۰۰۷۹۵۴۲۳۱۱'), isTrue);
      expect(isValidNationalId('۰۰۷۹-۵۴۲۳-۱۱'), isTrue);
    });
  });

  group('the field is optional', () {
    test('blank is acceptable', () {
      expect(isValidOptionalNationalId(null), isTrue);
      expect(isValidOptionalNationalId(''), isTrue);
      expect(isValidOptionalNationalId('   '), isTrue);
    });

    test('but an entered value must be valid', () {
      expect(isValidOptionalNationalId('0079542311'), isTrue);
      expect(isValidOptionalNationalId('1234567890'), isFalse);
      expect(isValidOptionalNationalId('123'), isFalse);
    });

    test('blank is not the same as valid-and-empty for storage', () {
      // The caller stores normalizeNationalId's output, which is null here --
      // so a blank field stores NULL rather than an empty string.
      expect(normalizeNationalId(''), isNull);
    });
  });
}
