import '../../../core/money/invoice_calculator.dart';
import '../../../core/money/money.dart';
import '../../../data/models/invoice.dart';

/// The four terms of the printed summary, plus the figure they arrive at.
///
/// **Why this type exists rather than the two callers each reading their own
/// source.** The invoice form has a [CalculatedInvoice] in hand and its gross is
/// always present; the detail screen and the future document renderer have a
/// stored [Invoice] and its gross may be **null** (D-055). Those are the same
/// panel with the same reconciliation on it, and rendering them from two
/// different shapes is how one of them ends up printing a zero where the other
/// prints an admission.
///
/// So the absence is carried in the type. [grossTotal] is `Money?` and there is
/// no constructor that turns a missing figure into [Money.zero] — a read site
/// cannot print zero for an unknown gross without first writing the code to do
/// it deliberately, which is the whole point.
///
/// **Nothing here computes.** It is a rearrangement of figures the engine or
/// the database already produced (§12): the renderer receives a fully-computed
/// view model, and this is the beginning of it.
class InvoiceSummaryFigures {
  const InvoiceSummaryFigures({
    required this.grossTotal,
    required this.totalDiscount,
    required this.totalTax,
    required this.roundingAdjustment,
    required this.grandTotal,
  });

  /// The live preview on the invoice form.
  ///
  /// The engine always produces a gross and asserts the summary reconciles
  /// before returning, so [grossTotal] is never null on this path.
  InvoiceSummaryFigures.ofCalculation(CalculatedInvoice totals)
    : grossTotal = totals.grossTotal,
      totalDiscount = totals.totalDiscount,
      totalTax = totals.totalTax,
      roundingAdjustment = totals.roundingAdjustment,
      grandTotal = totals.grandTotal;

  /// A stored invoice, as the detail screen and the document renderer see it.
  ///
  /// [grossTotal] is null exactly when the row's is: an invoice written before
  /// schema v4 whose stored numbers the backfill could not reconcile to the
  /// Rial. Every invoice written since carries one.
  InvoiceSummaryFigures.ofStored(Invoice invoice)
    : grossTotal = invoice.grossTotal,
      totalDiscount = invoice.totalDiscount,
      totalTax = invoice.totalTax,
      roundingAdjustment = invoice.roundingAdjustment,
      grandTotal = invoice.grandTotal;

  /// `Σ lineGross` — the first term. **Null where the figure was never
  /// recorded**, which is the one thing a summary may not silently call zero.
  final Money? grossTotal;

  /// The discount **actually given**, never the amount entered (D-027).
  final Money totalDiscount;

  final Money totalTax;
  final Money roundingAdjustment;
  final Money grandTotal;

  /// Whether the panel can be laid out as an equation the customer can check
  /// with a pencil: `gross − discount + tax + rounding == grandTotal`.
  ///
  /// False only for a pre-v4 invoice the backfill refused. The remaining
  /// figures are still correct and still what the customer owes — what is lost
  /// is the term the subtraction starts from, so the panel says so rather than
  /// printing three terms that do not reach the fourth.
  bool get reconciles => grossTotal != null;

  @override
  bool operator ==(Object other) =>
      other is InvoiceSummaryFigures &&
      other.grossTotal == grossTotal &&
      other.totalDiscount == totalDiscount &&
      other.totalTax == totalTax &&
      other.roundingAdjustment == roundingAdjustment &&
      other.grandTotal == grandTotal;

  @override
  int get hashCode => Object.hash(
    grossTotal,
    totalDiscount,
    totalTax,
    roundingAdjustment,
    grandTotal,
  );
}
