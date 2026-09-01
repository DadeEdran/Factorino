import 'money.dart';

/// Integer arithmetic with **half-up rounding at the Rial**.
///
/// "Half-up" here means ties round away from zero: 0.5 → 1, and −0.5 → −1.
/// Every amount in an invoice is non-negative apart from the rounding
/// adjustment, but the sign is handled explicitly rather than left to whatever
/// `~/` happens to do with negatives (it truncates toward zero, which would
/// round −0.6 to 0).

/// Multiplies, rejecting a product that could not be represented exactly.
///
/// Checked against 2^53 rather than the 64-bit range so that the Dart VM and
/// the Web reject the same inputs (D-002). A financial calculation that
/// succeeds on Android and silently loses digits on the Web is worse than one
/// that fails on both.
int checkedMultiply(int a, int b) {
  if (a == 0 || b == 0) return 0;
  if (b.abs() > kMaxSafeInteger ~/ a.abs()) {
    throw MoneyRangeError(
      'product out of range: $a x $b exceeds the exact-integer limit '
      '($kMaxSafeInteger). Rejected rather than truncated.',
    );
  }
  return a * b;
}

/// `numerator / divisor`, rounded half-up.
int divideHalfUp(int numerator, int divisor) {
  if (divisor == 0) {
    throw ArgumentError.value(divisor, 'divisor', 'must not be zero');
  }

  final negative = (numerator < 0) != (divisor < 0);
  final n = numerator.abs();
  final d = divisor.abs();

  final quotient = n ~/ d;
  final remainder = n - quotient * d;
  // `remainder * 2` cannot overflow: remainder is strictly less than d, and d
  // is a divisor drawn from this engine's small constants (1000, 10000) or a
  // rounding unit.
  final rounded = remainder * 2 >= d ? quotient + 1 : quotient;

  return negative ? -rounded : rounded;
}

/// `value × multiplier ÷ divisor`, rounded half-up, with the product checked.
///
/// This is the shape every §4 step takes: a price times a milli-quantity over
/// 1000, or a net amount times basis points over 10000.
int mulDivHalfUp(int value, int multiplier, int divisor) {
  return divideHalfUp(checkedMultiply(value, multiplier), divisor);
}

/// `a × b ÷ c` floored, with the remainder floor discarded — computed
/// **exactly**, however wide `a × b` would be.
///
/// **Why this exists beside [mulDivHalfUp], which rejects a wide product.** The
/// two are used for different shapes of arithmetic, and the difference is the
/// whole point:
///
/// * [mulDivHalfUp] multiplies an amount by a **small factor** — a milli-
///   quantity, a basis-point rate, a rounding unit. There, a product past 2^53
///   means an *input* is out of range, and [checkedMultiply] rejecting it is
///   exactly right (D-002).
/// * This one multiplies an amount by **another amount**: an invoice discount
///   by a line's net (§4 step 4). That product is quadratic in the invoice
///   total, so it passes 2^53 at an invoice total of a few hundred million
///   Rial — a few tens of millions of Toman, which is ordinary Iranian
///   business. **The wide value here is an intermediate the user never sees**,
///   so rejecting it would invent a business rule out of an implementation
///   detail. See `docs/DECISIONS.md` D-059.
///
/// **`BigInt` is used for the intermediate, and only for the intermediate.**
/// the project spec forbids `double` and `num` in the money path because they lose
/// digits; `BigInt` is an exact integer type that loses none, it is dart:core
/// on every target, and nothing here stores or returns one. Both results are
/// checked back into the exactly-representable range before they leave, so the
/// VM and the Web still agree on every value this produces — the parity
/// guarantee D-002 asks for, held here rather than given up.
///
/// [a] and [b] must be non-negative and [c] positive; the caller in `§4` has all
/// three by construction.
({int quotient, int remainder}) mulDivFloor(int a, int b, int c) {
  if (a < 0) throw ArgumentError.value(a, 'a', 'must not be negative');
  if (b < 0) throw ArgumentError.value(b, 'b', 'must not be negative');
  if (c <= 0) throw ArgumentError.value(c, 'c', 'must be positive');

  // Every input has to be exactly representable to mean anything at all: on
  // the Web an `int` past 2^53 has already lost digits before it reaches here,
  // and multiplying a value that is already wrong exactly is no improvement.
  for (final (String name, int value) in <(String, int)>[
    ('a', a),
    ('b', b),
    ('c', c),
  ]) {
    if (value > kMaxSafeInteger) {
      throw MoneyRangeError(
        'operand out of range: $name = $value exceeds the exact-integer limit '
        '($kMaxSafeInteger). Rejected rather than truncated.',
      );
    }
  }

  if (a == 0 || b == 0) return (quotient: 0, remainder: 0);

  final BigInt product = BigInt.from(a) * BigInt.from(b);
  final BigInt divisor = BigInt.from(c);
  final BigInt quotient = product ~/ divisor;

  // The result, unlike the intermediate, must fit — it is a figure that goes on
  // to be an amount. `remainder` needs no check: it is strictly less than [c],
  // which was checked above.
  if (quotient > BigInt.from(kMaxSafeInteger)) {
    throw MoneyRangeError(
      'quotient out of range: $a x $b / $c exceeds the exact-integer limit '
      '($kMaxSafeInteger). Rejected rather than truncated.',
    );
  }

  return (
    quotient: quotient.toInt(),
    remainder: (product - quotient * divisor).toInt(),
  );
}

/// `amountRial × rateBp ÷ 10000`, rounded half-up.
///
/// Percentages are basis points throughout (D-002): 10% is `1000`, 9% is `900`,
/// 8.5% is `850`. Integer basis points mean a rate like 8.5% needs no decimal
/// anywhere in the money path.
int applyBasisPoints(int amountRial, int rateBp) =>
    mulDivHalfUp(amountRial, rateBp, 10000);

/// Rounds to the nearest multiple of [unitRial], half-up.
///
/// `unitRial <= 1` disables it and returns [amountRial] unchanged, which is the
/// default (`roundingUnitRial = 0`, §4).
int roundToUnit(int amountRial, int unitRial) {
  if (unitRial < 0) {
    throw ArgumentError.value(unitRial, 'unitRial', 'must not be negative');
  }
  if (unitRial <= 1) return amountRial;
  return checkedMultiply(divideHalfUp(amountRial, unitRial), unitRial);
}
