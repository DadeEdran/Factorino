import 'package:flutter/widgets.dart';

import '../../data/models/money_display_unit.dart';
import '../localization/generated/app_strings.dart';

/// The unit every amount on screen is shown in, installed once at the root.
///
/// **An inherited widget rather than a parameter threaded through the tree.**
/// The unit is read by [AmountText] in twenty-odd places, most of them inside
/// widgets that are three or four levels below anything holding a `WidgetRef`
/// — and an amount that showed Toman in one card and Rial in another because
/// one call site was missed is precisely the confusion this setting exists to
/// remove. One scope, read where the amount is drawn, cannot be missed.
///
/// It is installed in `app.dart` from the settings row, inside the same
/// `builder` the [Directionality] uses, so dialogs and route overlays — which
/// build outside the router's subtree — are covered too.
///
/// The default is [MoneyDisplayUnit.toman]: what the application did before
/// this setting existed, and what a widget test that never installs a scope
/// gets.
class MoneyDisplayScope extends InheritedWidget {
  const MoneyDisplayScope({
    required this.unit,
    required super.child,
    super.key,
  });

  final MoneyDisplayUnit unit;

  static MoneyDisplayUnit of(BuildContext context) {
    final MoneyDisplayScope? scope = context
        .dependOnInheritedWidgetOfExactType<MoneyDisplayScope>();
    return scope?.unit ?? MoneyDisplayUnit.toman;
  }

  @override
  bool updateShouldNotify(MoneyDisplayScope oldWidget) =>
      oldWidget.unit != unit;
}

/// The Persian name of [unit].
///
/// Here rather than on the enum, because the enum is in `data/models/` and has
/// no business importing the localization layer — the same split
/// `invoiceStatusLabel` makes for the same reason.
String moneyUnitLabel(MoneyDisplayUnit unit, AppStrings strings) =>
    switch (unit) {
      MoneyDisplayUnit.toman => strings.unitToman,
      MoneyDisplayUnit.rial => strings.unitRial,
    };
