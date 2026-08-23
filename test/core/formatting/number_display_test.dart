import 'package:factorino/core/formatting/number_display.dart';
import 'package:flutter_test/flutter_test.dart';

/// Display formatting (§9): Persian digits, thousands separators, and the
/// units that must always accompany a number.
void main() {
  group('grouping', () {
    test('groups thousands with the Persian separator', () {
      expect(formatGroupedAscii(1250000), '1٬250٬000');
      expect(formatGroupedPersian(1250000), '۱٬۲۵۰٬۰۰۰');
    });

    test('leaves short numbers alone', () {
      expect(formatGroupedPersian(0), '۰');
      expect(formatGroupedPersian(7), '۷');
      expect(formatGroupedPersian(999), '۹۹۹');
    });

    test('groups at the boundary', () {
      expect(formatGroupedAscii(1000), '1٬000');
      expect(formatGroupedAscii(10000), '10٬000');
      expect(formatGroupedAscii(100000), '100٬000');
    });

    test('keeps a negative sign', () {
      expect(formatGroupedAscii(-1500), '-1٬500');
    });

    test('uses the thousands separator, not the Arabic comma', () {
      // U+066C, not U+060C: the latter is punctuation for prose.
      expect(kPersianGroupSeparator.codeUnitAt(0), 0x066C);
    });
  });

  group('percentages', () {
    test('renders a whole percentage', () {
      expect(formatPercentFromBasisPoints(1000), '۱۰٪');
      expect(formatPercentFromBasisPoints(900), '۹٪');
      expect(formatPercentFromBasisPoints(0), '۰٪');
    });

    test('renders a fractional percentage without trailing zeros', () {
      expect(formatPercentFromBasisPoints(850), '۸٫۵٪');
      expect(formatPercentFromBasisPoints(825), '۸٫۲۵٪');
      expect(formatPercentFromBasisPoints(805), '۸٫۰۵٪');
    });

    test('uses the Arabic percent sign, which mirrors correctly in RTL', () {
      expect(kPersianPercentSign.codeUnitAt(0), 0x066A);
    });
  });

  group('quantities', () {
    test('drops the milli scale for a whole quantity', () {
      expect(formatQuantityMilli(2000), '۲');
      expect(formatQuantityMilli(0), '۰');
    });

    test('shows a fraction without trailing zeros', () {
      expect(formatQuantityMilli(1500), '۱٫۵');
      expect(formatQuantityMilli(1050), '۱٫۰۵');
      expect(formatQuantityMilli(1005), '۱٫۰۰۵');
      expect(formatQuantityMilli(250), '۰٫۲۵');
    });
  });
}
