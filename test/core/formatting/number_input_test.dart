import 'package:factorino/core/formatting/number_input.dart';
import 'package:flutter_test/flutter_test.dart';

/// the project spec: every numeric input passes through a normalizer before
/// parsing. These are the shapes a real field receives.
void main() {
  group('normalizeNumericInput', () {
    test('folds all three digit sets', () {
      expect(normalizeNumericInput('۱۲۳'), '123');
      expect(normalizeNumericInput('١٢٣'), '123');
      expect(normalizeNumericInput('۱٢3'), '123');
    });

    test('strips thousands separators, Latin and Persian', () {
      expect(normalizeNumericInput('1,250,000'), '1250000');
      expect(normalizeNumericInput('۱٬۲۵۰٬۰۰۰'), '1250000');
      expect(normalizeNumericInput('1 250 000'), '1250000');
    });

    test('normalizes the Persian decimal separator', () {
      expect(normalizeNumericInput('۱٫۵'), '1.5');
    });

    test('normalizes a Unicode minus to a hyphen', () {
      expect(normalizeNumericInput('−5'), '-5');
    });

    test('trims surrounding whitespace', () {
      expect(normalizeNumericInput('  ۱۲۳  '), '123');
    });
  });

  group('tryParseIntInput', () {
    test('parses the three digit sets', () {
      expect(tryParseIntInput('۱۴۰۵'), 1405);
      expect(tryParseIntInput('١٤٠٥'), 1405);
      expect(tryParseIntInput('1405'), 1405);
    });

    test('parses a grouped amount as a user would type it', () {
      expect(tryParseIntInput('۱٬۲۵۰٬۰۰۰'), 1250000);
    });

    test('parses a signed value', () {
      expect(tryParseIntInput('-500'), -500);
      expect(tryParseIntInput('+500'), 500);
    });

    test('rejects a fractional value rather than truncating it', () {
      // Silently dropping the fraction of a price is the quiet arithmetic
      // error §4 exists to prevent.
      expect(tryParseIntInput('1.5'), isNull);
      expect(tryParseIntInput('۱٫۵'), isNull);
    });

    test('rejects text and empty input', () {
      expect(tryParseIntInput(''), isNull);
      expect(tryParseIntInput('   '), isNull);
      expect(tryParseIntInput('صد'), isNull);
      expect(tryParseIntInput('12abc'), isNull);
    });
  });

  group('tryParseScaledInput - quantity_milli', () {
    test('scales a whole number', () {
      expect(tryParseScaledInput('2', scale: 1000), 2000);
    });

    test('scales the fractional quantities §4 exists for', () {
      expect(tryParseScaledInput('1.5', scale: 1000), 1500);
      expect(tryParseScaledInput('0.25', scale: 1000), 250);
      expect(tryParseScaledInput('1.005', scale: 1000), 1005);
    });

    test('scales Persian digits and the Persian decimal separator', () {
      expect(tryParseScaledInput('۱٫۵', scale: 1000), 1500);
      expect(tryParseScaledInput('۰٫۲۵', scale: 1000), 250);
    });

    test('pads a short fraction rather than misreading it', () {
      // "1.5" is one and a half, not one point five thousandths.
      expect(tryParseScaledInput('1.5', scale: 1000), 1500);
      expect(tryParseScaledInput('1.05', scale: 1000), 1050);
    });

    test('accepts a leading decimal point', () {
      expect(tryParseScaledInput('.5', scale: 1000), 500);
    });

    test('rejects more precision than the scale can hold', () {
      // 1.2345 kg cannot be stored in milli-units. Returning 1234 would bill
      // the customer for a quantity they did not enter.
      expect(tryParseScaledInput('1.2345', scale: 1000), isNull);
    });

    test('never routes the value through a double', () {
      // 0.1 + 0.2 in binary floating point is 0.30000000000000004; a parser
      // built on double would produce 300 here only by luck and would drift
      // for other values. Checked at a scale where the error would show.
      expect(tryParseScaledInput('0.3', scale: 1000), 300);
      expect(tryParseScaledInput('8.7', scale: 1000), 8700);
      expect(tryParseScaledInput('1234567.891', scale: 1000), 1234567891);
    });

    test('handles a negative quantity', () {
      expect(tryParseScaledInput('-1.5', scale: 1000), -1500);
    });

    test('rejects malformed input', () {
      expect(tryParseScaledInput('', scale: 1000), isNull);
      expect(tryParseScaledInput('1.2.3', scale: 1000), isNull);
      expect(tryParseScaledInput('abc', scale: 1000), isNull);
      expect(tryParseScaledInput('-', scale: 1000), isNull);
    });

    test('works at scale 1 and scale 100', () {
      expect(tryParseScaledInput('5', scale: 1), 5);
      expect(tryParseScaledInput('5.5', scale: 1), isNull);
      expect(tryParseScaledInput('5.25', scale: 100), 525);
    });

    test('rejects a scale that is not a power of ten', () {
      expect(
        () => tryParseScaledInput('1', scale: 20),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => tryParseScaledInput('1', scale: 0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
