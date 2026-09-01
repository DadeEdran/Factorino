import 'rounding.dart';

/// Splits an invoice-level discount across lines, **proportionally by line net,
/// with remainders distributed by the largest-remainder method** (§4 step 4).
///
/// Why the method matters. Allocating 100 Rial across three equal lines gives
/// 33.33 each; three naive roundings give 33 + 33 + 33 = 99, and one Rial of
/// the user's discount vanishes. The invoice then fails to reconcile — its
/// lines do not sum to its total — which is exactly the class of bug §4 exists
/// to prevent. Largest-remainder hands the leftover Rial to the lines with the
/// largest fractional parts, so **the allocations always sum to the amount
/// exactly**. That property is what makes the §4 invariant
/// `grandTotal == subtotal − invoiceDiscount + totalTax` hold, and it is
/// asserted directly in the tests.
///
/// [amount] must not exceed the sum of [weights]: a discount larger than the
/// thing being discounted is clamped by the caller, not silently absorbed here.
/// Returns a list the same length as [weights], summing to exactly [amount].
///
/// **The arithmetic is exact at every invoice size** (D-059). Until Phase 5 (c)
/// this multiplied the discount by each line's net into an `int` and checked the
/// product against 2^53, which meant an ordinary invoice — 30 million Toman with
/// a 10% discount — could not be entered at all. The proportions, the ordering
/// and the tie-breaking are untouched by that fix: for every invoice the old
/// code accepted, this produces the identical allocation, and a test pins that
/// against a plain-`int` reference wherever the reference is itself valid.
List<int> allocateByLargestRemainder({
  required int amount,
  required List<int> weights,
}) {
  if (amount < 0) {
    throw ArgumentError.value(amount, 'amount', 'must not be negative');
  }
  if (weights.any((w) => w < 0)) {
    throw ArgumentError.value(weights, 'weights', 'must not be negative');
  }

  final allocations = List<int>.filled(weights.length, 0);
  final totalWeight = weights.fold<int>(0, (sum, w) => sum + w);

  // Nothing to spread, or nothing to spread it over. The caller is responsible
  // for treating the effective discount as zero in the second case -- there is
  // no honest way to allocate a discount across lines that are all worth zero.
  if (amount == 0 || totalWeight == 0) return allocations;

  if (amount > totalWeight) {
    throw ArgumentError.value(
      amount,
      'amount',
      'exceeds the total weight ($totalWeight); clamp before allocating',
    );
  }

  // Floor of the exact share, plus the remainder that floor discarded.
  //
  // **`mulDivFloor`, not a multiply followed by a divide**, and that is the fix
  // for known issue 19 (D-059). `amount x weights[i]` is a discount times a line
  // net: two figures that both scale with the invoice, so the product is
  // quadratic in the invoice total and passes 2^53 at a few hundred million
  // Rial. This is the only place in §4 where two amounts are multiplied
  // together -- every other step multiplies an amount by a small factor, a
  // milli-quantity or a basis-point rate -- which is why it is the only place
  // that needs the exact intermediate.
  //
  // `exact - share * totalWeight` was the second half of the same defect: that
  // product is the same magnitude again. The remainder now comes back from the
  // division that produced it, so there is nothing left to recompute.
  final remainders = <_Remainder>[];
  var distributed = 0;

  for (var i = 0; i < weights.length; i++) {
    final split = mulDivFloor(amount, weights[i], totalWeight);
    allocations[i] = split.quotient;
    distributed += split.quotient;
    remainders.add(_Remainder(i, split.remainder));
  }

  // Hand the leftover Rial, one each, to the largest remainders. Ties go to
  // the earlier line, so the result is deterministic: the same invoice must
  // produce the same allocation on every device and every run, or two devices
  // would disagree about an invoice after sync.
  remainders.sort((a, b) {
    final byRemainder = b.remainder.compareTo(a.remainder);
    return byRemainder != 0 ? byRemainder : a.index.compareTo(b.index);
  });

  var leftover = amount - distributed;
  for (var i = 0; i < remainders.length && leftover > 0; i++) {
    allocations[remainders[i].index]++;
    leftover--;
  }

  return allocations;
}

class _Remainder {
  const _Remainder(this.index, this.remainder);

  final int index;
  final int remainder;
}
