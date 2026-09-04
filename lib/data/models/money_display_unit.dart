import '../../core/money/money.dart';

/// Which unit amounts are **shown and entered** in.
///
/// Storage is unaffected and stays integer Rial (§4, D-002). This is a display
/// decision and nothing else: the same invoice reads ۳٬۰۰۰٬۰۰۰ تومان or
/// ۳۰٬۰۰۰٬۰۰۰ ریال depending on this setting, and the row in the database is
/// the same 30,000,000 either way.
///
/// Stored as the **enum index**, like [AppThemeMode] and every other enum this
/// schema holds, so these values must never be reordered and new ones may only
/// be appended. [toman] is index 0 and therefore the column default, which is
/// what every database created before this setting existed silently had.
///
/// Lives in `data/models/` rather than in `core/money/`, for the reason
/// `app_theme_mode.dart` does: it is a value a domain model carries and a
/// column stores, and the domain layer must not import drift (§3).
enum MoneyDisplayUnit {
  /// The primary display unit (§9), and what the application did before the
  /// setting existed.
  toman,

  rial,
}

/// Conversion in both directions, and the entry ceiling.
///
/// **No arithmetic of its own.** Both directions go through [Money], which is
/// the only calculator in the application (§4): `Money.toman` multiplies and
/// `Money.toman` the getter divides, both with the range guard attached. A
/// `× 10` written here would be a second money path, and the point of having
/// one is that there is only one.
extension MoneyDisplayUnitConversion on MoneyDisplayUnit {
  /// The figure to show for [amount], in this unit.
  int amountOf(Money amount) => switch (this) {
    MoneyDisplayUnit.toman => amount.toman,
    MoneyDisplayUnit.rial => amount.rial,
  };

  /// The amount a user meant by typing [value] into a field labelled with this
  /// unit.
  Money moneyOf(int value) => switch (this) {
    MoneyDisplayUnit.toman => Money.toman(value),
    MoneyDisplayUnit.rial => Money.rial(value),
  };

  /// The largest value a field in this unit may accept, past which the money
  /// engine refuses the amount rather than truncating it (D-002).
  ///
  /// The guard is [Money]'s; this is the number the form checks against so the
  /// user gets a Persian message instead of an exception.
  int get maxEnterableValue => switch (this) {
    MoneyDisplayUnit.toman => kMaxAmountRial ~/ 10,
    MoneyDisplayUnit.rial => kMaxAmountRial,
  };
}
