import 'package:factorino/core/money/discount_allocation.dart';
import 'package:flutter_test/flutter_test.dart';

/// §4 step 4: the invoice discount is allocated proportionally by line net,
/// with remainders distributed by the largest-remainder method **so that the
/// allocations sum to the discount exactly, to the Rial**.
///
/// The exactness is the whole point. One Rial lost here is an invoice whose
/// lines do not sum to its total.
void main() {
  group('exactness', () {
    test('distributes a remainder that does not divide evenly', () {
      // 100 across three equal lines: 33.33 each. Naive rounding gives 99.
      final allocations = allocateByLargestRemainder(
        amount: 100,
        weights: <int>[1000, 1000, 1000],
      );

      expect(allocations.reduce((a, b) => a + b), 100);
      expect(allocations, <int>[34, 33, 33]);
    });

    test('sums exactly across a wide range of awkward splits', () {
      // Property check: whatever the shape, nothing may be lost or invented.
      const weightSets = <List<int>>[
        <int>[1, 1, 1],
        <int>[1, 2, 3],
        <int>[7, 11, 13, 17],
        <int>[1, 999999],
        <int>[333, 333, 334],
        <int>[100, 0, 100],
        <int>[5],
      ];

      for (final weights in weightSets) {
        final total = weights.reduce((a, b) => a + b);
        for (var amount = 0; amount <= total && amount <= 500; amount++) {
          final allocations = allocateByLargestRemainder(
            amount: amount,
            weights: weights,
          );

          expect(
            allocations.reduce((a, b) => a + b),
            amount,
            reason: 'weights=$weights amount=$amount',
          );
          expect(allocations, hasLength(weights.length));
          expect(
            allocations.every((a) => a >= 0),
            isTrue,
            reason: 'weights=$weights amount=$amount produced a negative share',
          );
        }
      }
    });

    test('never allocates more to a line than that line is worth', () {
      final allocations = allocateByLargestRemainder(
        amount: 1000,
        weights: <int>[1, 999],
      );

      expect(allocations.reduce((a, b) => a + b), 1000);
      for (var i = 0; i < allocations.length; i++) {
        expect(allocations[i], lessThanOrEqualTo(<int>[1, 999][i]));
      }
    });
  });

  group('proportionality', () {
    test('splits in proportion to weight', () {
      expect(
        allocateByLargestRemainder(amount: 300, weights: <int>[100, 200]),
        <int>[100, 200],
      );
      expect(
        allocateByLargestRemainder(amount: 90, weights: <int>[1000, 2000]),
        <int>[30, 60],
      );
    });

    test('gives a zero-weight line nothing', () {
      final allocations = allocateByLargestRemainder(
        amount: 100,
        weights: <int>[0, 1000, 0],
      );
      expect(allocations, <int>[0, 100, 0]);
    });
  });

  group('determinism', () {
    test('breaks ties toward the earlier line, every time', () {
      // Two devices must produce the same allocation for the same invoice, or
      // they will disagree about it after sync.
      for (var run = 0; run < 50; run++) {
        expect(
          allocateByLargestRemainder(amount: 1, weights: <int>[500, 500]),
          <int>[1, 0],
        );
        expect(
          allocateByLargestRemainder(amount: 2, weights: <int>[10, 10, 10]),
          <int>[1, 1, 0],
        );
      }
    });
  });

  group('edges', () {
    test('allocates nothing when there is nothing to allocate', () {
      expect(
        allocateByLargestRemainder(amount: 0, weights: <int>[100, 200]),
        <int>[0, 0],
      );
    });

    test('allocates nothing across lines that are all worth zero', () {
      // There is no honest proportional split of a discount over nothing; the
      // caller treats the effective discount as zero.
      expect(
        allocateByLargestRemainder(amount: 50, weights: <int>[0, 0]),
        <int>[0, 0],
      );
    });

    test('handles an empty invoice', () {
      expect(allocateByLargestRemainder(amount: 0, weights: <int>[]), isEmpty);
    });

    test('rejects a discount larger than the lines it covers', () {
      // Clamping is the caller's decision, made where the context is.
      expect(
        () => allocateByLargestRemainder(amount: 101, weights: <int>[50, 50]),
        throwsArgumentError,
      );
    });

    test('rejects negative inputs', () {
      expect(
        () => allocateByLargestRemainder(amount: -1, weights: <int>[10]),
        throwsArgumentError,
      );
      expect(
        () => allocateByLargestRemainder(amount: 1, weights: <int>[-10]),
        throwsArgumentError,
      );
    });
  });
}
