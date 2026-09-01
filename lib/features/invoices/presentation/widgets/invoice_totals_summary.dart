import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/invoice_summary_figures.dart';

/// What the invoice comes to.
///
/// **Every figure here is read off [InvoiceSummaryFigures]; nothing on this
/// widget adds anything up.** `single_calculation_path_test.dart` fails the
/// build if a screen calls `calculateInvoice`, and this is the widget that
/// would most naturally try — a summary is exactly where a "just subtract the
/// discount" helper appears.
///
/// **It takes the view model rather than the engine's output**, so that the
/// live preview on the form and a stored invoice on the detail screen render
/// through the same rows. The one difference between them is that a stored
/// invoice's gross may be **unrecorded** (D-055), and this is where that is
/// said: «ثبت‌نشده» in the row, and a sentence beneath explaining that the
/// payable amount is unaffected. Never a zero — a gross of zero beside a real
/// grand total is a document contradicting itself.
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

  final InvoiceSummaryFigures totals;
  final AppStrings strings;

  /// Tighter spacing for the sticky bar on a phone, where the panel shares the
  /// screen with the form rather than sitting beside it.
  ///
  /// **Spacing only.** It used to pick the grand total's size as well —
  /// [AmountSize.large] in the panel, one step down in the bar — and that is
  /// what overflowed; see [_GrandTotal].
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
          _GrandTotal(totals: totals, strings: strings),
          // Only where a figure is genuinely missing, and beneath the grand
          // total rather than beside the gross: the reassurance is about the
          // amount the user is looking at, and it would not fit in the row.
          if (!totals.reconciles) ...<Widget>[
            SizedBox(height: gap),
            Text(
              strings.invoiceSummaryGrossUnrecordedNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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

  /// Null where the figure was never recorded (D-055). Rendered as Persian
  /// copy, never as zero and never as a blank cell.
  final Money? amount;

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
        if (amount case final Money value)
          AmountText(
            value,
            unitLabel: strings.unitToman,
            size: AmountSize.small,
          )
        else
          Text(
            strings.invoiceFigureUnrecorded,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// The figure the user actually agrees to.
///
/// The most salient element on the panel (§10), which is a claim about this
/// panel and not about the application: at [AmountSize.medium] it is a bold 19
/// against the 15 of the rows above it and the 14 of their labels.
///
/// **Stacked, not label-beside-figure, and that is measured rather than
/// stylistic.** The panel is 320 logical pixels wide on desktop; a grand total
/// sharing a row with «مبلغ قابل پرداخت» overflowed it by 58 pixels — an amount
/// clipped on the one line of a document that must never be clipped. Giving the
/// figure the full width of the panel is what lets it stay the largest thing on
/// it. Found by `invoice_editor_screen_test.dart`, which is the first test this
/// screen had.
///
/// **[AmountSize.medium], on every tier, and that is the second measurement.**
/// Stacking bought the panel one magnitude and no more. Inside
/// `AppLayout.detailPanelWidth` the card leaves 288 logical pixels, and the
/// large style needs [AppLayout.amountWidthLarge] — 376 — at the top of the
/// stress ladder, 344 at ten million تومان, 316 at one million. So the panel
/// overflowed on **every invoice above a million تومان**, which is very nearly
/// every real one. It went unseen for a whole increment because the phone
/// variant already stepped down a size and never overflowed at any magnitude,
/// and the phone was the tier the device pass ran on (D-057).
///
/// The size does not vary by tier any more. It could — the phone's bar has 336
/// pixels and the desktop panel has 288 — but a grand total that is one size on
/// a phone and another on a desktop is a difference nobody asked for, and the
/// binding constraint is the narrower of the two. `dense` keeps the spacing
/// difference, which is what it was for.
class _GrandTotal extends StatelessWidget {
  const _GrandTotal({required this.totals, required this.strings});

  final InvoiceSummaryFigures totals;
  final AppStrings strings;

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
        AmountText(
          totals.grandTotal,
          unitLabel: strings.unitToman,
          size: AmountSize.medium,
        ),
      ],
    );
  }
}
