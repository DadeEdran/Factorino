import 'package:drift/drift.dart';

import '../../core/money/invoice_calculator.dart';
import '../../core/money/money.dart';
import 'app_database.dart';
import 'soft_delete.dart';

/// Fills in the three figures schema v4 added, for invoices written before it
/// existed (D-055).
///
/// ## What makes this backfillable when D-052's snapshot was not
///
/// The two look alike and are not. A party snapshot could not be backfilled
/// because the migration cannot know what the customer record said on the day
/// the document was printed — any value it wrote would be a fabricated history.
/// These three figures are not history. They are **arithmetic over columns the
/// row already carries**: the unit price, the quantity, the effective line
/// discount, the invoice discount and the resolved tax rate are all stored, and
/// §4 turns them into a gross and an allocation deterministically.
///
/// ## It does not *assume* the rounding rule is unchanged — it checks, per invoice
///
/// D-055's argument for storing rather than recomputing is that §4 step 1
/// carries a rounding rule, so a recomputed gross is today's rule applied to
/// yesterday's document. That argument applies to this file too, and the answer
/// is not to trust that the rule has never changed. It is to **run the engine
/// over the row's own stored inputs and refuse to write unless the output
/// reproduces every figure already on the row** — each line's discount, net,
/// tax and total, and the invoice's subtotal, total discount, total tax and
/// grand total. Only then are the three new figures the ones that invoice was
/// issued under, and only then are they written.
///
/// Where anything disagrees — a rounding rule that did change, a row edited by
/// hand, a half-written invoice from a crash — **every one of that invoice's new
/// columns stays null**, and the read path says so in Persian rather than
/// printing a summary that fails its own invariant. `NOT NULL DEFAULT 0` was
/// refused for exactly this: zero is a number a document prints.
///
/// **Null is per invoice, never per line.** An invoice with a gross on three
/// lines and a null on the fourth is a document that reconciles nowhere and
/// admits nothing; the invoice is the honest unit to refuse.
///
/// ## Why it is allowed to call `calculateInvoice`
///
/// It is the third sanctioned caller in `single_calculation_path_test.dart`,
/// and it is a different kind of caller from the other two. The preview and the
/// write both *produce* figures a user sees. This one produces nothing it has
/// not first checked against what is already stored — the engine's output is a
/// hypothesis here and the database is the authority. Open-coding step 1 and
/// the largest-remainder allocation instead would have put a second
/// implementation of §4 in the data layer, which is the thing D-046 exists to
/// prevent.
Future<InvoiceFiguresBackfillReport> backfillInvoiceFigures(
  AppDatabase db,
) async {
  var reconciled = 0;
  var refused = 0;

  // Paged rather than read whole: this runs on a phone, over a database
  // designed for thousands of invoices (§13), and a migration that needs the
  // entire table resident is one that fails on the largest install rather than
  // the smallest. Keyed on `id` so the pages partition the table instead of
  // sliding over rows this loop is itself updating.
  String? after;
  while (true) {
    final String? cursor = after;
    // soft-delete-exempt: a soft-deleted invoice is still a document that may
    // be restored or arrive on another device, and skipping it would leave the
    // one invoice that cannot be printed. Backfilled like the rest.
    final query = db.select(db.invoices)
      ..where(
        (r) => cursor == null
            ? const Constant<bool>(true)
            : r.id.isBiggerThanValue(cursor),
      )
      ..orderBy(<OrderClauseGenerator<$InvoicesTable>>[
        (r) => OrderingTerm.asc(r.id),
      ])
      ..limit(_pageSize);

    final List<InvoiceRow> page = await query.get();

    if (page.isEmpty) break;
    after = page.last.id;

    final List<String> ids = page.map((InvoiceRow row) => row.id).toList();

    // The lines those totals were computed from: alive only, in `position`
    // order. The order matters — largest-remainder allocation breaks ties
    // toward the earlier line, so reading them in another order reproduces a
    // different allocation for the same invoice, and the check below would
    // (correctly) refuse it.
    final List<InvoiceItemRow> itemRows =
        await (db.selectAlive(db.invoiceItems)
              ..where((r) => r.invoiceId.isIn(ids))
              ..orderBy(<OrderClauseGenerator<$InvoiceItemsTable>>[
                (r) => OrderingTerm.asc(r.position),
                (r) => OrderingTerm.asc(r.id),
              ]))
            .get();

    final Map<String, List<InvoiceItemRow>> byInvoice =
        <String, List<InvoiceItemRow>>{};
    for (final InvoiceItemRow row in itemRows) {
      byInvoice.putIfAbsent(row.invoiceId, () => <InvoiceItemRow>[]).add(row);
    }

    for (final InvoiceRow invoice in page) {
      final List<InvoiceItemRow> lines =
          byInvoice[invoice.id] ?? const <InvoiceItemRow>[];

      final _ReconciledFigures? figures = _reconcile(invoice, lines);
      if (figures == null) {
        refused++;
        continue;
      }
      reconciled++;

      await (db.update(
        db.invoices,
      )..where((r) => r.id.equals(invoice.id))).write(
        InvoicesCompanion(grossTotalRial: Value<int?>(figures.grossTotal)),
      );

      for (int i = 0; i < lines.length; i++) {
        await (db.update(
          db.invoiceItems,
        )..where((r) => r.id.equals(lines[i].id))).write(
          InvoiceItemsCompanion(
            lineGrossRial: Value<int?>(figures.lineGross[i]),
            allocatedInvoiceDiscountRial: Value<int?>(figures.allocated[i]),
          ),
        );
      }
    }
  }

  return InvoiceFiguresBackfillReport(reconciled: reconciled, refused: refused);
}

/// How many pre-v4 invoices the backfill could account for, and how many it
/// refused to.
///
/// Returned rather than logged: the counts are the migration's own result and
/// the tests assert on them, while §7 forbids logging anything carrying a
/// customer's figures. A non-zero [refused] is not an error — it is the
/// migration reporting, honestly, that some documents cannot be reconstructed
/// and will say so on screen.
class InvoiceFiguresBackfillReport {
  const InvoiceFiguresBackfillReport({
    required this.reconciled,
    required this.refused,
  });

  final int reconciled;
  final int refused;

  int get total => reconciled + refused;

  @override
  String toString() =>
      'InvoiceFiguresBackfillReport(reconciled: $reconciled, '
      'refused: $refused)';
}

/// The three figures for one invoice, or `null` if its stored numbers and the
/// engine disagree about anything at all.
_ReconciledFigures? _reconcile(InvoiceRow invoice, List<InvoiceItemRow> lines) {
  final CalculatedInvoice calculated;
  try {
    calculated = calculateInvoice(
      InvoiceInput(
        lines: <InvoiceLineInput>[
          for (final InvoiceItemRow line in lines)
            InvoiceLineInput(
              unitPrice: Money.rial(line.unitPriceRial),
              quantityMilli: line.quantityMilli,
              // The **effective** discount as an absolute amount, and
              // deliberately not `discountPercentBp` (D-027). The stored amount
              // is the figure the document printed; passing the percentage
              // would ask the engine to re-derive it, which is the one thing
              // this file must not do. Feeding the effective amount makes
              // `requested == effective`, so a line that was clamped when it
              // was written stays clamped to the same number here.
              discount: Money.rial(line.discountRial),
              taxRateBp: line.resolvedTaxRateBp,
            ),
        ],
        // Likewise: the stored invoice discount is already the clamped one.
        discount: Money.rial(invoice.discountRial),
        // Every line above carries an explicit resolved rate, so item-level
        // resolution wins at step 6 and neither of these is ever consulted.
        // Passing the settings default would make what this migration accepts
        // depend on a value the user can change after the fact.
        defaultTaxRateBp: 0,
        // Rounding applies to the grand total only and can move neither a gross
        // nor an allocation. The stored adjustment is added back below rather
        // than recomputed, so a changed rounding *unit* cannot silently alter
        // what is accepted here.
        roundingUnitRial: 0,
      ),
    );
  } on Object {
    // Any refusal from the engine — a range error on a corrupt quantity, an
    // out-of-range rate, a reconciliation failure — means this row cannot be
    // accounted for. It must never mean an unopenable database: a migration
    // that throws leaves the user with an app that will not start, over one
    // invoice that was already unprintable.
    return null;
  }

  if (calculated.lines.length != lines.length) return null;

  for (int i = 0; i < lines.length; i++) {
    final InvoiceItemRow stored = lines[i];
    final CalculatedLine line = calculated.lines[i];

    if (line.discount.rial != stored.discountRial) return null;
    if (line.netAfterInvoiceDiscount.rial != stored.lineNetRial) return null;
    if (line.tax.rial != stored.lineTaxRial) return null;
    if (line.total.rial != stored.lineTotalRial) return null;
  }

  if (calculated.subtotal.rial != invoice.subtotalRial) return null;
  if (calculated.totalDiscount.rial != invoice.totalDiscountRial) return null;
  if (calculated.totalTax.rial != invoice.totalTaxRial) return null;

  // The engine ran with rounding disabled, so its grand total is the
  // pre-rounding one. The stored adjustment is taken as given — it is a
  // recorded delta, not a figure to re-derive — and added back.
  if (calculated.grandTotal.rial + invoice.roundingAdjustmentRial !=
      invoice.grandTotalRial) {
    return null;
  }

  return _ReconciledFigures(
    grossTotal: calculated.grossTotal.rial,
    lineGross: <int>[
      for (final CalculatedLine line in calculated.lines) line.gross.rial,
    ],
    allocated: <int>[
      for (final CalculatedLine line in calculated.lines)
        line.allocatedInvoiceDiscount.rial,
    ],
  );
}

class _ReconciledFigures {
  const _ReconciledFigures({
    required this.grossTotal,
    required this.lineGross,
    required this.allocated,
  });

  final int grossTotal;
  final List<int> lineGross;
  final List<int> allocated;
}

/// Invoices per page. Small enough that the working set stays trivial on a
/// phone, large enough that a few thousand invoices is a few dozen queries.
const int _pageSize = 100;
