import 'package:factorino/core/money/discount_allocation.dart';
import 'package:factorino/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/money_magnitudes.dart';

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

  group('exact at every invoice size (D-059, known issue 19)', () {
    // **The defect this group exists for.** Until this was fixed, allocation
    // multiplied the discount by each line's net into an `int` and checked the
    // product against 2^53. That product is *quadratic in the invoice total* --
    // it is the only place in §4 where two figures that both scale with the
    // invoice are multiplied together -- so it passed the limit at a few
    // hundred million Rial. A 30,000,000 تومان invoice with a 10% discount,
    // which is ordinary Iranian business, threw `MoneyRangeError`.
    //
    // And it threw in a place that could not fail gracefully:
    // `InvoiceEditorState`'s constructor runs the engine, so it landed on the
    // **preview**, as the user typed, and replaced the form with an error view.
    // Nothing was ever silently wrong -- the guard did exactly its job, which is
    // why this was a blocked invoice and never a wrong total. The fix removes
    // the intermediate, not the guard.

    /// A plausible invoice: [lineCount] lines that between them come to
    /// [totalRial], deliberately **not** equal, so the remainder distribution
    /// has something to do.
    List<int> lines(int totalRial, int lineCount) {
      final List<int> weights = <int>[];
      var left = totalRial;
      for (var i = 0; i < lineCount - 1; i++) {
        final int share = (left * 3) ~/ 7;
        weights.add(share);
        left -= share;
      }
      weights.add(left);
      return weights;
    }

    /// Whether the implementation this replaced would have refused these
    /// inputs -- the predicate its `checkedMultiply` used, restated rather than
    /// remembered, so the sweep reports the truth if the ladder ever moves.
    bool oldWouldHaveThrown(int amount, List<int> weights) =>
        amount != 0 && weights.any((int w) => w > kMaxSafeInteger ~/ amount);

    var everThrew = false;

    for (final int toman in kMoneyStressToman) {
      for (final int percent in <int>[1, 5, 10, 25]) {
        test('$toman toman with a $percent% discount', () {
          final int totalRial = toman * 10;
          final List<int> weights = lines(totalRial, 3);
          final int amount = (totalRial * percent) ~/ 100;

          if (oldWouldHaveThrown(amount, weights)) everThrew = true;

          final List<int> allocations = allocateByLargestRemainder(
            amount: amount,
            weights: weights,
          );

          // Exactness, which is the property the whole method exists for: the
          // shares sum to the discount to the Rial, or the invoice's lines do
          // not sum to its total.
          expect(
            allocations.reduce((a, b) => a + b),
            amount,
            reason: 'the allocation must still sum to the discount exactly',
          );
          expect(allocations, hasLength(weights.length));
          for (var i = 0; i < allocations.length; i++) {
            expect(allocations[i], greaterThanOrEqualTo(0));
            expect(
              allocations[i],
              lessThanOrEqualTo(weights[i]),
              reason: 'no line may be discounted below zero',
            );
          }

          // Determinism, which is why largest-remainder breaks ties toward the
          // earlier line: two devices must produce the same allocation for the
          // same invoice, or they will disagree about it after sync.
          expect(
            allocateByLargestRemainder(amount: amount, weights: weights),
            allocations,
          );
        });
      }
    }

    test('the sweep still covers magnitudes the old code refused', () {
      // Guards the guard. If the ladder in `money_magnitudes.dart` ever drops
      // below the old failure boundary, every case above would still pass while
      // covering nothing, and this is where that is noticed.
      expect(
        everThrew,
        isTrue,
        reason:
            'no rung of the ladder now reaches the product that used to '
            'overflow, so this group has stopped testing the regression',
      );
    });

    test('at the exact boundary the old implementation broke on', () {
      // 94906265 is the largest n whose square is inside 2^53, so this pair is
      // the last invoice the old code could allocate and the first it could
      // not -- derived from the limit rather than picked to look convincing.
      // Written as a division, which is the predicate the old check used, so
      // the assertion itself cannot overflow.
      const int lastThatFitted = 94906265;
      const int firstThatDidNot = 94906266;

      expect(lastThatFitted <= kMaxSafeInteger ~/ lastThatFitted, isTrue);
      expect(firstThatDidNot > kMaxSafeInteger ~/ firstThatDidNot, isTrue);

      // A whole-invoice discount on a single line: the allocation is the whole
      // amount, and the only question is whether the arithmetic survives.
      expect(
        allocateByLargestRemainder(
          amount: lastThatFitted,
          weights: <int>[lastThatFitted],
        ),
        <int>[lastThatFitted],
      );
      expect(
        allocateByLargestRemainder(
          amount: firstThatDidNot,
          weights: <int>[firstThatDidNot],
        ),
        <int>[firstThatDidNot],
      );

      // And the same magnitude split across lines, where the remainder
      // distribution actually runs.
      final List<int> split = allocateByLargestRemainder(
        amount: firstThatDidNot,
        weights: <int>[firstThatDidNot, firstThatDidNot + 1],
      );
      expect(split.reduce((a, b) => a + b), firstThatDidNot);
    });

    test('agrees with plain-int arithmetic wherever plain int is still valid', () {
      // **Not a circular check.** The reference below is the *old* algorithm --
      // multiply, then divide, in a plain `int` -- run only on inputs small
      // enough for it to be exact. Where it is valid it is authoritative, and
      // the new implementation must match it share for share. That is the claim
      // the fix rests on: the arithmetic's range changed and nothing else did.
      List<int> reference(int amount, List<int> weights) {
        final int totalWeight = weights.reduce((a, b) => a + b);
        final List<int> shares = <int>[];
        final List<int> remainders = <int>[];
        var distributed = 0;
        for (final int w in weights) {
          final int exact = amount * w;
          final int share = exact ~/ totalWeight;
          shares.add(share);
          remainders.add(exact - share * totalWeight);
          distributed += share;
        }
        final List<int> order =
            <int>[for (var i = 0; i < weights.length; i++) i]..sort((a, b) {
              final int byRemainder = remainders[b].compareTo(remainders[a]);
              return byRemainder != 0 ? byRemainder : a.compareTo(b);
            });
        var leftover = amount - distributed;
        for (var i = 0; i < order.length && leftover > 0; i++) {
          shares[order[i]]++;
          leftover--;
        }
        return shares;
      }

      const List<List<int>> weightSets = <List<int>>[
        <int>[1, 1, 1],
        <int>[7, 11, 13, 17],
        <int>[1, 999999],
        <int>[333, 333, 334],
        <int>[100, 0, 100],
        <int>[12500000, 18750000, 3125000],
        <int>[999999937, 1000000007],
      ];

      for (final List<int> weights in weightSets) {
        final int total = weights.reduce((a, b) => a + b);
        for (final int amount in <int>[
          0,
          1,
          2,
          7,
          total ~/ 100,
          total ~/ 7,
          total ~/ 2,
          total - 1,
          total,
        ]) {
          if (amount < 0 || amount > total) continue;
          // Only where the reference itself is exact.
          if (amount != 0 &&
              weights.any((int w) => w > kMaxSafeInteger ~/ amount)) {
            continue;
          }
          expect(
            allocateByLargestRemainder(amount: amount, weights: weights),
            reference(amount, weights),
            reason: 'weights=$weights amount=$amount',
          );
        }
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
