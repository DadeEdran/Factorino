/// Pure Dart. **Nothing in this directory may import Flutter** -- `dart:ui`,
/// `package:flutter/*` or `package:flutter_test/*` -- so the money engine is
/// unit-testable without a widget binding.
/// `test/core/money/no_flutter_imports_test.dart` fails the build if one appears.
library;

/// The largest amount, in Rial, this application will handle.
///
/// 10^14 Rial is ten trillion Toman: orders of magnitude above any invoice an
/// Iranian freelancer or workshop will issue, and far enough below the limits
/// below that intermediate arithmetic has room.
///
/// The ceiling exists because of D-002's Web caveat. On the Web a Dart `int` is
/// a JS number, exact only to 2^53. An amount beyond that does not overflow
/// loudly -- it silently loses its low digits, which on an invoice total is the
/// worst possible failure mode. So the engine **rejects** rather than truncates,
/// and it rejects identically on every platform: a calculation must not produce
/// one answer on Android and another on the Web.
const int kMaxAmountRial = 100000000000000; // 10^14

/// 2^53 − 1: the largest integer that survives a round trip through a JS
/// number. Intermediate products are checked against this, not against the
/// 64-bit range, so the Dart VM and the Web agree.
const int kMaxSafeInteger = 9007199254740991;

/// Thrown when a value is outside the representable range, instead of letting
/// it silently lose precision.
class MoneyRangeError implements Exception {
  const MoneyRangeError(this.message);

  final String message;

  @override
  String toString() => 'MoneyRangeError: $message';
}

/// An exact amount of money, in integer Rial.
///
/// Never `double`, never `num` (D-002). Binary floating point cannot represent
/// decimal currency exactly, and accumulated representation error produces
/// invoices whose lines do not sum to their total -- the single most damaging
/// bug this product can ship.
///
/// A type rather than a bare `int` because the money path is full of integers
/// that are *not* Rial: basis points, milli-quantities, counts. Passing a rate
/// where an amount belongs is the mistake worth making impossible.
class Money implements Comparable<Money> {
  const Money._(this.rial);

  /// Constructs from an amount in Rial, rejecting anything out of range.
  factory Money.rial(int rial) {
    if (rial.abs() > kMaxAmountRial) {
      throw MoneyRangeError(
        'amount out of range: |$rial| Rial exceeds kMaxAmountRial '
        '($kMaxAmountRial). Rejected rather than truncated, because on the Web '
        'a value past 2^53 loses digits silently (D-002).',
      );
    }
    return Money._(rial);
  }

  /// The same, for a column that may hold no figure at all.
  ///
  /// Three of them do (D-055): `invoices.gross_total_rial` and the two per-line
  /// figures beside it are null on an invoice written before schema v4 whose
  /// stored numbers could not be reconciled. Mapping that to [zero] would put a
  /// figure a document prints where the truth is that none is known, so the
  /// absence is carried in the type and every read site has to answer for it.
  static Money? rialOrNull(int? rial) => rial == null ? null : Money.rial(rial);

  /// Constructs from Toman, the primary **display** unit.
  /// Storage and arithmetic stay in Rial.
  factory Money.toman(int toman) => Money.rial(_checkedMul(toman, 10));

  static const Money zero = Money._(0);

  /// The canonical amount. Rial has no sub-unit in practice, so this integer
  /// is exact -- there is nothing below it to lose.
  final int rial;

  /// Toman for display, truncated. Rial amounts that are not a whole number of
  /// Toman do occur (a 9% tax on an odd figure), so the remainder is dropped
  /// deliberately here and the Rial value stays authoritative.
  int get toman => rial ~/ 10;

  bool get isZero => rial == 0;
  bool get isNegative => rial < 0;

  /// The amount, or zero if it is negative. Used where a subtraction must not
  /// take a line below zero (§4 step 3).
  Money get clampedToZero => rial < 0 ? zero : this;

  Money operator +(Money other) => Money.rial(_checkedAdd(rial, other.rial));
  Money operator -(Money other) => Money.rial(_checkedAdd(rial, -other.rial));
  Money operator -() => Money.rial(-rial);

  bool operator <(Money other) => rial < other.rial;
  bool operator <=(Money other) => rial <= other.rial;
  bool operator >(Money other) => rial > other.rial;
  bool operator >=(Money other) => rial >= other.rial;

  @override
  int compareTo(Money other) => rial.compareTo(other.rial);

  @override
  bool operator ==(Object other) => other is Money && other.rial == rial;

  @override
  int get hashCode => rial.hashCode;

  /// Diagnostic only. User-facing rendering is the formatting layer's job:
  /// Persian digits, thousands separators, and a unit label.
  @override
  String toString() => 'Money($rial rial)';
}

int _checkedAdd(int a, int b) {
  final sum = a + b;
  if (sum.abs() > kMaxSafeInteger) {
    throw MoneyRangeError('sum out of range: $a + $b');
  }
  return sum;
}

int _checkedMul(int a, int b) {
  if (a != 0 && b.abs() > kMaxSafeInteger ~/ a.abs()) {
    throw MoneyRangeError('product out of range: $a x $b');
  }
  return a * b;
}
