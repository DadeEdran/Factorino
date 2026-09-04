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

    return _LineCards(invoice: invoice, items: items, strings: strings);
  }
}

/// One column of the document table, named so that a shape can be a list of
/// them rather than a set of booleans nobody can read at a glance.
enum _LineColumn { description, quantity, unitPrice, gross, total }

/// The shapes the document table can take, widest first.
///
/// **A column that degrades to unreadable is worse than one that is not shown**
/// (D-065). Every money column here is fixed-width by D-037, so when the table
/// is composed into a region narrower than they need, the *flexible* columns
/// absorb the whole shortfall — and `Expanded` is a tight fit, so they absorb it
/// all the way down to nothing. That is what happened: on the detail screen the
/// table sits beside a `detailPanelWidth` panel, and the description was laid
/// out at **21.6 logical pixels**, rendering Persian one glyph per row, at every
/// desktop width, with no overflow and no error of any kind.
///
/// So the table gives up **columns** rather than giving up width it does not
/// have. The two alternatives were considered and refused:
///
/// * **Horizontal scrolling** — a document is read by carrying the description
///   across to the total, and a scroll that puts those on different screens
///   breaks the one comparison the page exists for. It also hides figures below
///   the fold sideways, where nothing suggests they are there.
/// * **Wrapping the row** — a row that takes two lines has stopped being a
///   table, and this file already has the shape for a line that is not a table
///   row. It is [_LineCard], and it is what the narrow tiers use.
///
/// **Nothing is lost when a column goes.** Each dropped figure reappears as a
/// labelled detail line under the description, through the same strings the
/// card already uses — so the wide table, the narrow table and the card all say
/// the same things in the same words, which is the rule this file was built on.
const List<List<_LineColumn>> _lineTableShapes = <List<_LineColumn>>[
  <_LineColumn>[
    _LineColumn.description,
    _LineColumn.quantity,
    _LineColumn.unitPrice,
    _LineColumn.gross,
    _LineColumn.total,
  ],
  // مبلغ کل goes first. It is the one figure on the row that is a *step* in the
  // arithmetic rather than a term of the agreement — the customer checks the
  // unit price they agreed and the total they owe; the gross between them is
  // working. It is already a sentence on every card for the same reason.
  <_LineColumn>[
    _LineColumn.description,
    _LineColumn.quantity,
    _LineColumn.unitPrice,
    _LineColumn.total,
  ],
  <_LineColumn>[
    _LineColumn.description,
    _LineColumn.quantity,
    _LineColumn.total,
  ],
  // The floor. شرح and جمع are what a document line *is*: what was sold, and
  // what it came to. Below the width even these two need, the table becomes
  // cards rather than becoming unreadable.
  <_LineColumn>[_LineColumn.description, _LineColumn.total],
];

/// A real table on desktop (§10).
///
/// **Five columns at its widest, and the choice of which five is a
/// measurement.** The printed Iranian line is شرح · تعداد · مبلغ واحد · مبلغ کل
/// · تخفیف · مبلغ پس از تخفیف · مالیات · جمع — six money columns. A money
/// column is fixed-width by D-037 and `AppLayout.tablePriceWidth` is 244 of
/// them, so six is 1464 logical pixels before the description has any. **Eight
/// columns do not fit at any window size**, exactly as the summary panel did not
/// fit beside the editor's table (D-053).
///
/// **And five do not always fit either, which is the half that was missed.**
/// D-058 checked the five against **1144**, the full desktop content column —
/// but on the detail screen this table is composed into what is left beside a
/// 320-pixel panel, which is **768**, and three fixed money columns are 732 of
/// it. That is §10's own composition rule, missed in the file that quotes it: a
/// widget measured at its own full width has not been measured at the width it
/// is composed into. The shape is chosen from the width the table is actually
/// given now — see [_lineTableShapes].
class _LinesTable extends StatelessWidget {
  const _LinesTable({
    required this.invoice,
    required this.items,
    required this.strings,
  });

  final Invoice invoice;
  final List<InvoiceItem> items;
  final AppStrings strings;

  /// Fixed-width and leading-aligned for the money columns, like every money
  /// column in the application: numbers render left-to-right whatever the
  /// surrounding direction, so `alignEnd` in RTL lines up their *first* digits
  /// and leaves the units ragged (D-037).
  TableColumnSpec _spec(_LineColumn column) => switch (column) {
    _LineColumn.description => TableColumnSpec.flexible(
      label: strings.invoiceLineColumnDescription,
      flex: 3,
      minWidth: AppLayout.tableMinTextWidth,
    ),
    _LineColumn.quantity => TableColumnSpec.flexible(
      label: strings.invoiceLineColumnQuantity,
      flex: 2,
      minWidth: AppLayout.tableMinValueWidth,
    ),
    _LineColumn.unitPrice => TableColumnSpec.fixed(
      label: strings.invoiceLineColumnUnitPrice,
      width: AppLayout.tablePriceWidth,
    ),
    _LineColumn.gross => TableColumnSpec.fixed(
      label: strings.invoiceLineColumnGross,
      width: AppLayout.tablePriceWidth,
    ),
    _LineColumn.total => TableColumnSpec.fixed(
      label: strings.invoiceLineColumnTotal,
      width: AppLayout.tablePriceWidth,
    ),
  };

  /// The widest shape that fits in [available], or null if not even the floor
  /// does.
  List<_LineColumn>? _shapeFor(double available) {
    for (final List<_LineColumn> shape in _lineTableShapes) {
      if (tableMinimumWidth(shape.map(_spec).toList()) <= available) {
        return shape;
      }
    }
    return null;
  }

  /// The figures [shape] gave up, said as sentences instead.
  ///
  /// Ordered as the columns were, so a reader who has seen the wide table finds
  /// them in the sequence they expect.
  List<String> _droppedDetails(List<_LineColumn> shape, InvoiceItem item) {
    final List<String> details = <String>[];

    // Quantity and unit price share one sentence — «۲٫۵ ساعت × ۱۲۵٬۰۰۰ تومان» —
    // which is the string the card has always used, so a line reads the same
    // way in both places rather than nearly the same way.
    if (!shape.contains(_LineColumn.quantity)) {
      details.add(
        strings.invoiceLineLabelQuantity(
          formatQuantityMilli(item.quantityMilli),
          item.unit,
          formatGroupedPersian(item.unitPrice.toman),
        ),
      );
    } else if (!shape.contains(_LineColumn.unitPrice)) {
      details.add(
        strings.invoiceLineLabelUnitPrice(
          formatGroupedPersian(item.unitPrice.toman),
        ),
      );
    }

    if (!shape.contains(_LineColumn.gross)) {
      details.add(switch (item.gross) {
        final Money gross => strings.invoiceLineLabelGross(
          formatGroupedPersian(gross.toman),
        ),
        // Null means *unknown*, never zero (D-055). The admission keeps its
        // label whether the figure is a column or a sentence.
        null => strings.invoiceLineLabelUnrecorded(
          strings.invoiceLineColumnGross,
        ),
      });
    }

    return details;
  }

  Widget _cell(
    _LineColumn column,
    List<_LineColumn> shape,
    InvoiceItem item,
    ThemeData theme,
  ) => switch (column) {
    _LineColumn.description => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(item.title),
        for (final String detail in <String>[
          ..._droppedDetails(shape, item),
          ...lineDetails(invoice, item, strings),
        ])
          Text(detail, style: theme.textTheme.bodySmall),
      ],
    ),
    _LineColumn.quantity => Text(
      '${formatQuantityMilli(item.quantityMilli)} ${item.unit}',
    ),
    _LineColumn.unitPrice => AmountText(item.unitPrice, size: AmountSize.small),
    _LineColumn.gross => _MaybeAmount(amount: item.gross, strings: strings),
    _LineColumn.total => AmountText(item.lineTotal, size: AmountSize.small),
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final List<_LineColumn>? shape = _shapeFor(constraints.maxWidth);

        // Narrower than even شرح · جمع needs. A table is not the shape for this
        // width, and the application already has the one that is.
        if (shape == null) {
          return _LineCards(invoice: invoice, items: items, strings: strings);
        }

        final List<TableColumnSpec> columns = shape.map(_spec).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTableHeader(columns: columns),
            for (final InvoiceItem item in items)
              AppTableRow(
                columns: columns,
                cells: <Widget>[
                  for (final _LineColumn column in shape)
                    _cell(column, shape, item, theme),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// The lines as cards: the narrow tiers, and the fallback for a table region
/// too narrow to be a table.
class _LineCards extends StatelessWidget {
  const _LineCards({
    required this.invoice,
    required this.items,
    required this.strings,
  });

  final Invoice invoice;
  final List<InvoiceItem> items;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
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
              AmountText(item.lineTotal, size: AmountSize.small),
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
    return AmountText(value, size: AmountSize.small);
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
