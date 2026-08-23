import 'package:flutter/material.dart';

import '../formatting/number_display.dart';
import '../money/money.dart';
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
/// Toman is the display unit; Rial is available where the extra precision
/// matters. The conversion is [Money]'s, not this widget's.
class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    required this.unitLabel,
    this.size = AmountSize.medium,
    this.inRial = false,
    this.color,
    super.key,
  });

  final Money amount;

  /// The Persian unit, from the localization layer. Passed in rather than read
  /// here so this widget stays free of any string of its own (§1).
  final String unitLabel;

  final AmountSize size;

  /// Show the exact Rial figure instead of Toman. Rial amounts that are not a
  /// whole number of Toman do occur — a 9% tax on an odd figure — and this is
  /// how those are shown without rounding.
  final bool inRial;

  /// Overrides the neutral. Used only where a status genuinely colours the
  /// figure, such as an overdue balance.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color resolved = color ?? theme.colorScheme.onSurface;

    final int value = inRial ? amount.rial : amount.toman;
    final String digits = formatGroupedPersian(value);

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
