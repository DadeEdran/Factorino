import '../../data/models/money_display_unit.dart';
import 'generated/app_strings.dart';

/// The unit every amount in the application is shown and entered in.
///
/// **A constant, because it is no longer a choice** (D-121). Toman was briefly
/// a setting with Rial beside it in a dropdown; the owner removed the choice,
/// and this is the one place that now says which unit won. Storage is untouched
/// and stays integer Rial (§4, D-002) — this is the divisor on the way to a
/// screen, a field and a printed page, and nothing else.
///
/// **It replaces an `InheritedWidget`**, which existed only to carry the
/// settings row's value down to twenty-odd `AmountText`s. A scope that can only
/// ever hold one value is a lookup that cannot fail interestingly, and §15
/// says not to keep a layer for the case that was removed.
///
/// The one place a different unit still appears is [AmountText.inRial], which
/// is a **precision** decision rather than a preference: a 9% tax on an odd
/// figure is not a whole number of Toman, and that call site says so at the
/// point where it matters.
const MoneyDisplayUnit kDisplayUnit = MoneyDisplayUnit.toman;

/// The Persian name of [unit].
///
/// Here rather than on the enum, because the enum is in `data/models/` and has
/// no business importing the localization layer — the same split
/// [jalaliMonthNames] makes for the same reason, in the same directory.
String moneyUnitLabel(MoneyDisplayUnit unit, AppStrings strings) =>
    switch (unit) {
      MoneyDisplayUnit.toman => strings.unitToman,
      MoneyDisplayUnit.rial => strings.unitRial,
    };
