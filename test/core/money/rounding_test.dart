import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/money/rounding.dart';
import 'package:flutter_test/flutter_test.dart';

/// §4: all rounding is half-up at the Rial. These are the boundaries where
/// "half-up" and "whatever `~/` does" diverge, which is where a money bug
/// would actually live.
void main() {
  group('divideHalfUp', () {
    test('rounds a tie up, away from zero', () {
      expect(divideHalfUp(5, 10), 1); // 0.5 -> 1
      expect(divideHalfUp(15, 10), 2); // 1.5 -> 2
      expect(divideHalfUp(25, 10), 3); // 2.5 -> 3, not banker's 2
      expect(divideHalfUp(-5, 10), -1); // -0.5 -> -1
    });

    test('rounds below a tie down and above a tie up', () {
      expect(divideHalfUp(4, 10), 0);
      expect(divideHalfUp(6, 10), 1);
      expect(divideHalfUp(-4, 10), 0);
      expect(divideHalfUp(-6, 10), -1);
    });

    test('does not truncate toward zero the way ~/ would', () {
      // The whole reason this function exists: -0.6 truncates to 0.
      expect(-6 ~/ 10, 0);
      expect(divideHalfUp(-6, 10), -1);
    });

    test('is exact when there is no remainder', () {
      expect(divideHalfUp(1000, 10), 100);
      expect(divideHalfUp(0, 10), 0);
    });

    test('rejects division by zero', () {
      expect(() => divideHalfUp(1, 0), throwsArgumentError);
    });
  });

  group('applyBasisPoints', () {
    test('applies whole and fractional percentages', () {
      expect(applyBasisPoints(1000000, 1000), 100000); // 10%
      expect(applyBasisPoints(1000000, 900), 90000); // 9%
      expect(applyBasisPoints(1000000, 850), 85000); // 8.5%
      expect(applyBasisPoints(1000000, 0), 0);
      expect(applyBasisPoints(1000000, 10000), 1000000); // 100%
    });

    test('rounds the half-Rial case up', () {
      // 5 x 1000bp = 0.5 Rial exactly.
      expect(applyBasisPoints(5, 1000), 1);
      // 4 x 1000bp = 0.4 Rial.
      expect(applyBasisPoints(4, 1000), 0);
    });
  });

  group('roundToUnit', () {
    test('is disabled for 0 and 1', () {
      expect(roundToUnit(12345, 0), 12345);
      expect(roundToUnit(12345, 1), 12345);
    });

    test('rounds half-up to the nearest multiple', () {
      expect(roundToUnit(12345, 100), 12300);
      expect(roundToUnit(12350, 100), 12400); // exact half rounds up
      expect(roundToUnit(12351, 100), 12400);
      expect(roundToUnit(12300, 100), 12300);
      expect(roundToUnit(4999, 1000), 5000);
      expect(roundToUnit(4500, 1000), 5000);
      expect(roundToUnit(4499, 1000), 4000);
    });

    test('rejects a negative unit', () {
      expect(() => roundToUnit(100, -10), throwsArgumentError);
    });
  });

  group('checkedMultiply', () {
    test('rejects rather than truncating past the exact-integer limit', () {
      // The D-002 Web caveat made concrete: beyond 2^53 a JS number silently
      // drops low digits, so this must throw on every platform, not just Web.
      expect(
        () => checkedMultiply(kMaxSafeInteger, 2),
        throwsA(isA<MoneyRangeError>()),
      );
      expect(
        () => checkedMultiply(1000000000, 1000000000),
        throwsA(isA<MoneyRangeError>()),
      );
    });

    test('allows the largest exact product', () {
      expect(checkedMultiply(kMaxSafeInteger, 1), kMaxSafeInteger);
      expect(checkedMultiply(0, kMaxSafeInteger), 0);
    });

    test('propagates the guard through mulDivHalfUp', () {
      expect(
        () => mulDivHalfUp(kMaxSafeInteger, 1000, 1000),
        throwsA(isA<MoneyRangeError>()),
      );
    });
  });
}
