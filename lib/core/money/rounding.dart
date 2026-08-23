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
