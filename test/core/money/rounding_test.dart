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
  group('mulDivFloor', () {
    // The primitive behind §4 step 4's allocation (D-059). It is the one place
    // in the engine that multiplies an amount by another amount, so it is the
    // one place the intermediate has to be exact rather than checked.

    test('floors, and hands back the remainder floor discarded', () {
      expect(mulDivFloor(100, 1000, 3000), (quotient: 33, remainder: 1000));
      expect(mulDivFloor(300, 100, 300), (quotient: 100, remainder: 0));
      expect(mulDivFloor(1, 1, 3), (quotient: 0, remainder: 1));
    });

    test('quotient and remainder reconstruct the product exactly', () {
      for (final (int a, int b, int c) in <(int, int, int)>[
        (7, 11, 13),
        (999983, 999979, 1000003),
        (12345678, 87654321, 999999937),
        (100000000, 500000000, 1000000000),
      ]) {
        final result = mulDivFloor(a, b, c);
        // Checked in `BigInt`, because the whole point is that the product
        // does not have to fit in an `int` for the answer to be right.
        expect(
          BigInt.from(result.quotient) * BigInt.from(c) +
              BigInt.from(result.remainder),
          BigInt.from(a) * BigInt.from(b),
          reason: '$a x $b / $c',
        );
        expect(result.remainder, greaterThanOrEqualTo(0));
        expect(result.remainder, lessThan(c));
      }
    });

    test('is exact where the product is far past 2^53', () {
      // The case that used to throw: an invoice discount times a line net, at
      // an invoice total of a billion Rial. The product is 5 x 10^16.
      expect(mulDivFloor(100000000, 500000000, 1000000000), (
        quotient: 50000000,
        remainder: 0,
      ));

      // And the largest product the engine can be handed at all: two amounts
      // at `kMaxAmountRial`, whose product is 10^28.
      final result = mulDivFloor(
        kMaxAmountRial,
        kMaxAmountRial,
        kMaxAmountRial,
      );
      expect(result, (quotient: kMaxAmountRial, remainder: 0));
    });

    test('agrees with plain-int arithmetic wherever plain int is exact', () {
      // Where the old multiply-then-divide was valid it is authoritative, and
      // this is the assertion that the fix widened the range without moving a
      // single answer inside it.
      for (final (int a, int b, int c) in <(int, int, int)>[
        (3, 7, 5),
        (1000, 1000, 7),
        (123456, 654321, 99991),
        (94906265, 94906265, 94906265),
      ]) {
        expect(mulDivFloor(a, b, c), (
          quotient: a * b ~/ c,
          remainder: a * b - (a * b ~/ c) * c,
        ), reason: '$a x $b / $c');
      }
    });

    test('zero on either side is zero, with no remainder', () {
      expect(mulDivFloor(0, 12345, 7), (quotient: 0, remainder: 0));
      expect(mulDivFloor(12345, 0, 7), (quotient: 0, remainder: 0));
    });

    test('rejects an operand that is already inexact', () {
      // Past 2^53 an `int` has already lost digits on the Web before it reaches
      // here, and multiplying an already-wrong value exactly is no improvement.
      // This is where D-002's parity guarantee is kept: the VM refuses what the
      // Web could not have represented.
      expect(
        () => mulDivFloor(kMaxSafeInteger + 1, 2, 3),
        throwsA(isA<MoneyRangeError>()),
      );
      expect(
        () => mulDivFloor(2, kMaxSafeInteger + 1, 3),
        throwsA(isA<MoneyRangeError>()),
      );
      expect(
        () => mulDivFloor(2, 3, kMaxSafeInteger + 1),
        throwsA(isA<MoneyRangeError>()),
      );
    });

    test('rejects a quotient that could not survive the Web', () {
      // The intermediate may be as wide as it likes; the **result** may not,
      // because it goes on to be an amount.
      expect(
        () => mulDivFloor(kMaxSafeInteger, kMaxSafeInteger, 1),
        throwsA(isA<MoneyRangeError>()),
      );
    });

    test('rejects a negative operand and a non-positive divisor', () {
      expect(() => mulDivFloor(-1, 2, 3), throwsArgumentError);
      expect(() => mulDivFloor(1, -2, 3), throwsArgumentError);
      expect(() => mulDivFloor(1, 2, 0), throwsArgumentError);
      expect(() => mulDivFloor(1, 2, -3), throwsArgumentError);
    });
  });
}
