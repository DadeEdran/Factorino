import 'package:flutter/material.dart';

import '../../../../core/formatting/number_display.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/money/money.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_table.dart';
import '../../../../data/models/invoice.dart';
import '../../../../data/models/invoice_item.dart';

/// The lines of a **stored** invoice, laid out from storage alone.
///
/// **Nothing here multiplies, divides, rounds or adds.** Every figure on a row
/// is a column on the row in the database — since schema v4 that includes the
/// line's gross and its share of the invoice-level discount, which is what
/// D-055 was for. A read site that worked out `unitPrice × quantity` would be
/// applying *today's* rounding rule to *yesterday's* document, and it would do
/// it where `single_calculation_path_test.dart` cannot see it, because it never
/// calls the engine at all.
///
/// **Not the editor's line section.** That one renders a `CalculatedLine` from
/// the live preview, where every figure is present by construction and every
/// figure is about to change. This one renders an `InvoiceItem`, where two
/// figures are `Money?` and none of them will ever change again. The shapes are
/// deliberately similar — a line should look like a line wherever it is seen —
/// and the sources are not the same, so they are not the same widget.
///
/// **«ثبت‌نشده», never a zero and never a blank cell** (D-055, D-056). A gross
/// of zero beside a real line total is a row contradicting itself; a blank cell
/// reads as data that failed to load. The label stays attached to the admission
/// so the user can see *which* figure is missing rather than finding a row with
/// one fewer fact on it than its neighbours.
class InvoiceDocumentLines extends StatelessWidget {
  const InvoiceDocumentLines({
    required this.invoice,
    required this.items,
    required this.strings,
    required this.tier,
    super.key,
  });

  /// The header, for the one thing a line cannot answer alone: whether this
  /// invoice has an invoice-level discount at all, which decides whether a
  /// line's share of it is a fact worth a row.
  final Invoice invoice;

  /// In `position` order, as the repository read them.
  final List<InvoiceItem> items;

  final AppStrings strings;
  final LayoutTier tier;

  @override
  Widget build(BuildContext context) {
    if (tier.usesTables) {
      return _LinesTable(invoice: invoice, items: items, strings: strings);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < items.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          _LineCard(invoice: invoice, item: items[index], strings: strings),
        ],
      ],
    );
  }
}

/// A real table on desktop (§10).
///
/// **Five columns, and the choice of which five is a measurement.** The printed
/// Iranian line is شرح · تعداد · مبلغ واحد · مبلغ کل · تخفیف · مبلغ پس از
/// تخفیف · مالیات · جمع — six money columns. A money column is fixed-width by
/// D-037 and `AppLayout.tablePriceWidth` is 244 of them, so six is 1464 logical
/// pixels before the description has any, against the 1144 a desktop content
/// column actually has at `AppLayout.maxContentWidth`. **Eight columns do not
/// fit at any window size**, exactly as the summary panel did not fit beside the
/// editor's table (D-053), and the same answer applies: state the constraint
/// rather than squeeze the layout.
///
/// So the three columns that vary independently keep the width — قیمت واحد,
/// مبلغ کل and جمع سطر — and the deductions between them run underneath the
/// description as labelled detail lines, which is the shape the editor's table
/// and every card on the narrow tiers already use. Every stored figure is on
/// the row; what changes is whether it is a column or a line. The eight-column
/// document layout is the renderer's problem (§12), on a page rather than in a
/// viewport, and it has every figure it needs.
class _LinesTable extends StatelessWidget {
  const _LinesTable({
    required this.invoice,
    required this.items,
    required this.strings,
  });

  final Invoice invoice;
  final List<InvoiceItem> items;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Fixed-width and leading-aligned, like every money column in the
    // application: numbers render left-to-right whatever the surrounding
    // direction, so `alignEnd` in RTL lines up their *first* digits and leaves
    // the units ragged (D-037).
    final List<TableColumnSpec> columns = <TableColumnSpec>[
      TableColumnSpec(label: strings.invoiceLineColumnDescription, flex: 3),
      TableColumnSpec(label: strings.invoiceLineColumnQuantity, flex: 2),
      TableColumnSpec(
        label: strings.invoiceLineColumnUnitPrice,
        width: AppLayout.tablePriceWidth,
      ),
      TableColumnSpec(
        label: strings.invoiceLineColumnGross,
        width: AppLayout.tablePriceWidth,
      ),
      TableColumnSpec(
        label: strings.invoiceLineColumnTotal,
        width: AppLayout.tablePriceWidth,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTableHeader(columns: columns),
        for (final InvoiceItem item in items)
          AppTableRow(
            columns: columns,
            cells: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item.title),
                  for (final String detail in lineDetails(
                    invoice,
                    item,
                    strings,
                  ))
                    Text(detail, style: theme.textTheme.bodySmall),
                ],
              ),
              Text('${formatQuantityMilli(item.quantityMilli)} ${item.unit}'),
              AmountText(
                item.unitPrice,
                unitLabel: strings.unitToman,
                size: AmountSize.small,
              ),
              _MaybeAmount(amount: item.gross, strings: strings),
              AmountText(
                item.lineTotal,
                unitLabel: strings.unitToman,
                size: AmountSize.small,
              ),
            ],
          ),
      ],
    );
  }
}

/// A line as a card: mobile and tablet.
class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.invoice,
    required this.item,
    required this.strings,
  });

  final Invoice invoice;
  final InvoiceItem item;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(item.title, style: theme.textTheme.titleMedium),
              ),
              const SizedBox(width: AppSpacing.md),
              // The line total, which is the figure the reader is checking.
              AmountText(
                item.lineTotal,
                unitLabel: strings.unitToman,
                size: AmountSize.small,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings.invoiceLineLabelQuantity(
              formatQuantityMilli(item.quantityMilli),
              item.unit,
              formatGroupedPersian(item.unitPrice.toman),
            ),
            style: theme.textTheme.bodySmall,
          ),
          // The gross is a detail line here rather than a column, because a card
          // has no columns -- but it is the same figure, and it is said whether
          // it is stored or not.
          Text(switch (item.gross) {
            final Money gross => strings.invoiceLineLabelGross(
              formatGroupedPersian(gross.toman),
            ),
            null => strings.invoiceLineLabelUnrecorded(
              strings.invoiceLineColumnGross,
            ),
          }, style: theme.textTheme.bodySmall),
          for (final String detail in lineDetails(invoice, item, strings))
            Text(detail, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// A stored figure, or the Persian for its absence, in a table cell.
class _MaybeAmount extends StatelessWidget {
  const _MaybeAmount({required this.amount, required this.strings});

  final Money? amount;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Money? value = amount;

    if (value == null) {
      return Text(
        strings.invoiceFigureUnrecorded,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return AmountText(
      value,
      unitLabel: strings.unitToman,
      size: AmountSize.small,
    );
  }
}

/// The deductions and the tax on one line, as sentences.
///
/// **Only what applies.** A line with no discount and no tax has no detail
/// lines, because a row of «تخفیف ۰ تومان» is noise a reader has to dismiss on
/// every line of every invoice. The exception is the invoice-level share, which
/// is reported whenever the *invoice* carries a discount: on those documents the
/// deduction is real on every line, and a line silently omitting it is a line
/// whose net cannot be reconciled against its gross.
///
/// Public so the detail screen's tests can assert on the same strings the two
/// layouts render, rather than on one of them.
List<String> lineDetails(
  Invoice invoice,
  InvoiceItem item,
  AppStrings strings,
) {
  final List<String> details = <String>[];

  if (item.discount != Money.zero) {
    details.add(
      strings.invoiceLineLabelDiscount(
        formatGroupedPersian(item.discount.toman),
      ),
    );
  }

  if (invoice.discount != Money.zero) {
    final Money? share = item.allocatedInvoiceDiscount;
    details.add(
      share == null
          // Null means *unknown*, and on a document that carries an
          // invoice-level discount that is exactly the figure whose absence the
          // reader has to be told about: without it the line's net looks wrong.
          ? strings.invoiceLineLabelUnrecorded(
              strings.invoiceDetailInvoiceDiscountShareLabel,
            )
          : strings.invoiceLineLabelInvoiceDiscountShare(
              formatGroupedPersian(share.toman),
            ),
    );
  }

  if (item.discount != Money.zero || invoice.discount != Money.zero) {
    details.add(
      strings.invoiceLineLabelNet(formatGroupedPersian(item.lineNet.toman)),
    );
  }

  if (item.resolvedTaxRateBp != 0) {
    // Rate **and** amount, unlike the editor's line, which shows the rate
    // alone. On the form the amount is one row away in a summary that is about
    // to change; on a document it is a figure the customer reconciles, and the
    // rate without it cannot be checked without doing the multiplication the
    // read site is forbidden to do.
    details.add(
      strings.invoiceLineLabelTaxAmount(
        formatPercentFromBasisPoints(item.resolvedTaxRateBp),
        formatGroupedPersian(item.lineTax.toman),
      ),
    );
  }

  return details;
}
