import 'package:flutter/material.dart';

import '../formatting/number_display.dart';
import '../theme/app_typography.dart';
import 'amount_text.dart';

/// A count, in the same numeral style as an amount but with no unit.
///
/// No unit label, deliberately. §9's "never a bare number" is about money,
/// where the difference between Rial and Toman is a factor of ten; a count of
/// invoices under a tile labelled «فاکتورهای صادرشده» has no such ambiguity,
/// and repeating the noun would be noise.
///
/// Shared rather than owned by the dashboard, because the daily-sales screen
/// puts a count on a tile beside an amount for the same reason and in the same
/// place. Two of these drawn from two files is how one of them ends up in a
/// different numeral style.
class CountText extends StatelessWidget {
  const CountText({required this.value, required this.size, super.key});

  final int value;
  final AmountSize size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle style = switch (size) {
      AmountSize.large => AppTypography.amountLarge,
      AmountSize.medium => AppTypography.amountMedium,
      AmountSize.small => AppTypography.amountSmall,
    };

    return Text(
      formatGroupedPersian(value),
      style: style.copyWith(
        color: theme.colorScheme.onSurface,
        fontFamily: AppTypography.fontFamily,
      ),
    );
  }
}
