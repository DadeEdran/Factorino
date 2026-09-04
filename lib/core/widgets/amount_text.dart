import 'package:flutter/material.dart';

import '../../data/models/money_display_unit.dart';
import '../formatting/number_display.dart';
import '../localization/generated/app_strings.dart';
import '../money/money.dart';
import 'money_display_scope.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

/// How prominent an amount is on the surface it appears on.
enum AmountSize {
  /// A dashboard tile or an invoice total: the largest thing on the card.
  large,

  /// A list row's amount.
  medium,

  /// A table cell or a secondary figure.
  small,
}

/// A monetary amount, rendered the one way this application renders money.
///
/// Three rules, all from the project spec, held in one widget so no
/// screen can hold them differently:
///
/// * **Never a bare number.** The unit label is always present. An amount
///   without one is ambiguous by a factor of ten in a country that quotes in
///   Toman and stores in Rial.
/// * **Persian digits**, produced by [toPersianDigits] in `core/formatting/`,
///   never by a font that substitutes glyphs (D-022) — so the behaviour stays
///   testable and switchable in one place.
/// * **The most salient element on its card** (§10), which is what
///   [AppTypography.amountLarge] is for.
///
/// **Which unit is the user's choice** (D-117), read from [MoneyDisplayScope]
/// rather than passed in at twenty-odd call sites — an amount that showed
/// Toman on one card and Rial on the next because a call site was missed is
/// exactly the ambiguity the setting exists to remove. The label comes from
/// the localization layer for the unit in force, so the figure and the word
/// beside it cannot disagree. The conversion is [Money]'s, not this widget's.
class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    this.size = AmountSize.medium,
    this.inRial = false,
    this.color,
    super.key,
  });

  final Money amount;

  final AmountSize size;

  /// Show the exact Rial figure whatever the chosen unit is. Rial amounts that
  /// are not a whole number of Toman do occur — a 9% tax on an odd figure — and
  /// this is how those are shown without rounding. It overrides the setting
  /// rather than following it, because the reason for it is precision rather
  /// than preference.
  final bool inRial;

  /// Overrides the neutral. Used only where a status genuinely colours the
  /// figure, such as an overdue balance.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color resolved = color ?? theme.colorScheme.onSurface;

    final MoneyDisplayUnit unit = inRial
        ? MoneyDisplayUnit.rial
: MoneyDisplayScope.of(context);
    final String digits = formatGroupedPersian(unit.amountOf(amount));
    final String unitLabel = moneyUnitLabel(unit, AppStrings.of(context));

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(
          digits,
          style: _numeralStyle.copyWith(
            color: resolved,
            fontFamily: AppTypography.fontFamily,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          unitLabel,
          style: AppTypography.amountUnit.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFamily: AppTypography.fontFamily,
          ),
        ),
      ],
    );
  }

  TextStyle get _numeralStyle => switch (size) {
    AmountSize.large => AppTypography.amountLarge,
    AmountSize.medium => AppTypography.amountMedium,
    AmountSize.small => AppTypography.amountSmall,
  };
}
