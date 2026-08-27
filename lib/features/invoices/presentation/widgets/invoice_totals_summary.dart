import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/money/invoice_calculator.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/app_card.dart';

/// What the invoice comes to, as the engine computed it.
///
/// **Every figure here is read off [CalculatedInvoice]; nothing on this widget
/// adds anything up.** `single_calculation_path_test.dart` fails the build if a
/// screen calls `calculateInvoice`, and this is the widget that would most
/// naturally try — a summary is exactly where a "just subtract the discount"
/// helper appears.
///
/// **It starts from `grossTotal`, not from `subtotal`, and that is the whole
/// design of the panel** (D-047). `subtotal` is already net of the line
/// discounts, so a panel printing subtotal − discount + tax does **not** reach
/// the grand total: anyone checking it with a pencil subtracts the line
/// discounts twice and finds the document short. Starting from the gross adds
/// up exactly, which is the property the engine asserts at runtime:
///
/// `grossTotal − totalDiscount + totalTax + roundingAdjustment == grandTotal`
///
/// The rows are the four terms of that equation, in that order, so the panel is
/// the equation rendered. A customer can reconcile it by hand, which is the
/// only test of a summary that matters.
class InvoiceTotalsSummary extends StatelessWidget {
  const InvoiceTotalsSummary({
    required this.totals,
    required this.strings,
    this.dense = false,
    super.key,
  });

  final CalculatedInvoice totals;
  final AppStrings strings;

  /// Tighter spacing for the sticky bar on a phone, where the panel shares the
  /// screen with the form rather than sitting beside it.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double gap = dense ? AppSpacing.xs : AppSpacing.sm;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(strings.invoiceSummaryTitle, style: theme.textTheme.titleSmall),
          SizedBox(height: dense ? AppSpacing.sm : AppSpacing.md),
          _Row(
            label: strings.invoiceSummaryGross,
            amount: totals.grossTotal,
            strings: strings,
          ),
          SizedBox(height: gap),
          // Shown even at zero. A discount row that appears and disappears as
          // the user types makes the panel jump under the figure they are
          // reading, and its absence is not the same information as a zero.
          _Row(
            label: strings.invoiceSummaryDiscount,
            amount: totals.totalDiscount,
            strings: strings,
          ),
          SizedBox(height: gap),
          _Row(
            label: strings.invoiceSummaryTax,
            amount: totals.totalTax,
            strings: strings,
          ),
          // Rounding is off by default (§4) and is genuinely absent when the
          // setting is zero -- unlike a discount, there is no such thing as a
          // rounding of nothing to report.
          if (totals.roundingAdjustment != Money.zero) ...<Widget>[
            SizedBox(height: gap),
            _Row(
              label: strings.invoiceSummaryRounding,
              amount: totals.roundingAdjustment,
              strings: strings,
            ),
          ],
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: dense ? AppSpacing.sm : AppSpacing.md,
            ),
            child: Divider(
              height: AppBorders.hairline,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          _GrandTotal(
            totals: totals,
            strings: strings,
            size: dense ? AmountSize.medium : AmountSize.large,
          ),
        ],
      ),
    );
  }
}

/// One term of the reconciliation.
///
/// Label and figure are a `Row` with the label `Expanded`: a Persian label can
/// be long («مالیات بر ارزش افزوده») and the panel is 320 logical pixels wide
/// on desktop and narrower inside a phone's bottom bar, so the label wraps and
/// the amount keeps its width. The reverse -- an amount allowed to shrink --
/// would truncate a figure, which is never acceptable on a document.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.amount,
    required this.strings,
  });

  final String label;
  final Money amount;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        AmountText(
          amount,
          unitLabel: strings.unitToman,
          size: AmountSize.small,
        ),
      ],
    );
  }
}

/// The figure the user actually agrees to.
///
/// The most salient element on the panel (§10) -- `AmountSize.large` where
/// there is room, and one step down inside a phone's bottom bar, where the bar
/// has to leave the form visible above it.
///
/// **Stacked, not label-beside-figure, and that is measured rather than
/// stylistic.** The panel is 320 logical pixels wide on desktop; a grand total
/// in the large amount style, sharing a row with «مبلغ قابل پرداخت», overflowed
/// it by 58 pixels — an amount clipped on the one line of a document that must
/// never be clipped. Giving the figure the full width of the panel is what lets
/// it stay the largest thing on it. Found by
/// `invoice_editor_screen_test.dart`, which is the first test this screen had.
class _GrandTotal extends StatelessWidget {
  const _GrandTotal({
    required this.totals,
    required this.strings,
    required this.size,
  });

  final CalculatedInvoice totals;
  final AppStrings strings;
  final AmountSize size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          strings.invoiceSummaryGrandTotal,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        AmountText(totals.grandTotal, unitLabel: strings.unitToman, size: size),
      ],
    );
  }
}
