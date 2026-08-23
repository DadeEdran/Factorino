import 'package:factorino/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

/// D-002: integer Rial, and a ceiling that **rejects** rather than truncating.
void main() {
  group('construction', () {
    test('keeps the exact Rial amount', () {
      expect(Money.rial(0).rial, 0);
      expect(Money.rial(1).rial, 1);
      expect(Money.rial(125000000).rial, 125000000);
      expect(Money.rial(-500).rial, -500);
    });

    test('converts Toman to Rial', () {
      expect(Money.toman(1).rial, 10);
      expect(Money.toman(12345).rial, 123450);
    });

    test('truncates Rial to Toman for display, keeping Rial authoritative', () {
      // 9% tax on an odd figure genuinely produces non-round Rial amounts.
      final amount = Money.rial(12345);
      expect(amount.toman, 1234);
      expect(amount.rial, 12345);
    });
  });

  group('the kMaxAmountRial ceiling', () {
    test('accepts the ceiling itself', () {
      expect(Money.rial(kMaxAmountRial).rial, kMaxAmountRial);
      expect(Money.rial(-kMaxAmountRial).rial, -kMaxAmountRial);
    });

    test('rejects one Rial past it, rather than truncating', () {
      expect(
        () => Money.rial(kMaxAmountRial + 1),
        throwsA(isA<MoneyRangeError>()),
      );
      expect(
        () => Money.rial(-kMaxAmountRial - 1),
        throwsA(isA<MoneyRangeError>()),
      );
    });

    test('rejects values past the exact-integer limit', () {
      // The failure D-002 warns about: on the Web these lose their low digits
      // silently. Rejecting keeps every platform's answer identical.
      expect(
        () => Money.rial(kMaxSafeInteger),
        throwsA(isA<MoneyRangeError>()),
      );
      expect(
        () => Money.toman(kMaxAmountRial),
        throwsA(isA<MoneyRangeError>()),
      );
    });

    test('rejects an addition that would leave the range', () {
      final large = Money.rial(kMaxAmountRial);
      expect(() => large + Money.rial(1), throwsA(isA<MoneyRangeError>()));
    });

    test('the ceiling is far above any realistic invoice', () {
      // Sanity: ten billion Toman must be comfortably representable.
      expect(() => Money.toman(10000000000), returnsNormally);
    });
  });

  group('arithmetic and comparison', () {
    test('adds and subtracts exactly', () {
      expect(Money.rial(100) + Money.rial(250), Money.rial(350));
      expect(Money.rial(100) - Money.rial(250), Money.rial(-150));
      expect(-Money.rial(100), Money.rial(-100));
    });

    test('clamps to zero where a line must not go negative', () {
      expect(Money.rial(-150).clampedToZero, Money.zero);
      expect(Money.rial(150).clampedToZero, Money.rial(150));
    });

    test('compares and sorts', () {
      expect(Money.rial(100) < Money.rial(200), isTrue);
      expect(Money.rial(200) >= Money.rial(200), isTrue);

      final amounts = <Money>[Money.rial(300), Money.rial(100), Money.rial(200)]
        ..sort();
      expect(amounts.map((m) => m.rial), <int>[100, 200, 300]);
    });

    test('is a value type', () {
      expect(Money.rial(500), Money.rial(500));
      expect(Money.rial(500).hashCode, Money.rial(500).hashCode);
      expect(Money.rial(500), isNot(Money.rial(501)));
    });

    test('reports zero and sign', () {
      expect(Money.zero.isZero, isTrue);
      expect(Money.rial(-1).isNegative, isTrue);
      expect(Money.rial(1).isNegative, isFalse);
    });
  });
}
