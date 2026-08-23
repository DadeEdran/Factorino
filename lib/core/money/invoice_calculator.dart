import 'discount_allocation.dart';
import 'money.dart';
import 'rounding.dart';

/// The invoice calculation engine, implementing the project spec step for step.
///
/// Pure: no Flutter, no database, no clock, no locale. Given the same input it
/// returns the same output on every platform, which is what makes it testable
/// and what keeps two synced devices agreeing about an invoice.
///
/// The engine **computes**; the schema **records**. Stored totals on `invoices`
/// and `invoice_items` are snapshots of what this produced at issue time
/// (D-004), never recomputed on read.
///
/// It never refuses an invoice over a questionable *input* — it computes the
/// correct totals and reports the input on [CalculatedInvoice.warnings], which
/// the caller is expected to read (D-027). It throws only when its own output
/// fails to reconcile, which is a defect in this file rather than in the data.

/// One line as the user entered it.
class InvoiceLineInput {
  const InvoiceLineInput({
    required this.unitPrice,
    required this.quantityMilli,
    this.discount = Money.zero,
    this.discountPercentBp,
    this.taxRateBp,
  });

  final Money unitPrice;

  /// Quantity scaled by 1000: `1.5` is `1500` (§4). Integer, so a fractional
  /// kilogram or hour never introduces floating point.
  final int quantityMilli;

  /// Absolute discount on this line.
  final Money discount;

  /// If the user entered the discount as a percentage, this is what they typed,
  /// in basis points. When present it **wins**: the absolute amount is resolved
  /// from it, and both are reported so the document can show what was entered
  /// (§4 step 2).
  final int? discountPercentBp;

  /// Item-level tax rate override. First step of the resolution order
  /// item → invoice → settings default (§4 step 6).
  final int? taxRateBp;
}

/// A whole invoice as the user entered it.
class InvoiceInput {
  const InvoiceInput({
    required this.lines,
    required this.defaultTaxRateBp,
    this.discount = Money.zero,
    this.discountPercentBp,
    this.taxRateBp,
    this.roundingUnitRial = 0,
  });

  final List<InvoiceLineInput> lines;

  /// From settings — the last step of the tax resolution order. Never
  /// hardcoded (§4).
  final int defaultTaxRateBp;

  /// Invoice-level discount, allocated across the lines before tax.
  final Money discount;
  final int? discountPercentBp;

  /// Invoice-level tax rate; the middle step of the resolution order.
  final int? taxRateBp;

  /// Optional final rounding of the grand total. `0` disables it (§4).
  final int roundingUnitRial;
}

/// One computed line. Every field here is snapshotted onto `invoice_items`.
class CalculatedLine {
  const CalculatedLine({
    required this.gross,
    required this.discount,
    required this.discountRequested,
    required this.discountPercentBp,
    required this.net,
    required this.allocatedInvoiceDiscount,
    required this.netAfterInvoiceDiscount,
    required this.resolvedTaxRateBp,
    required this.tax,
    required this.total,
  });

  /// `unitPrice × quantityMilli ÷ 1000`, half-up (§4 step 1).
  final Money gross;

  /// The discount **actually given** on this line: the entered amount, or the
  /// line's gross where the entered amount exceeded it (§4 steps 3 and 9).
  ///
  /// This is the figure that appears on the document and the one that feeds
  /// `totalDiscount`, because a customer reconciling the invoice by hand can
  /// only ever arrive at what was actually deducted. See [discountRequested]
  /// for what was typed, and D-027 for why these are two fields.
  final Money discount;

  /// The discount as entered, before clamping (§4 step 2). Kept so the
  /// document can show what the user typed and so the difference is auditable.
  final Money discountRequested;

  final int? discountPercentBp;

  /// `gross − discount`, never negative (§4 step 3). Structurally non-negative
  /// now that [discount] is itself capped at [gross].
  final Money net;

  final Money allocatedInvoiceDiscount;
  final Money netAfterInvoiceDiscount;

  /// The rate that actually applied, recorded so a later settings change
  /// cannot alter an issued invoice (§4 step 6).
  final int resolvedTaxRateBp;

  final Money tax;

  /// `netAfterInvoiceDiscount + tax` (§4 step 7).
  final Money total;

  /// Whether the entered discount exceeded this line and was capped.
  ///
  /// Almost always a data-entry slip rather than an intent, so it is surfaced
  /// rather than absorbed — see [CalculatedInvoice.warnings] (D-027).
  bool get discountWasClamped => discountRequested > discount;
}

/// What the engine wants the caller to see about an invoice it nonetheless
/// computed successfully.
///
/// Deliberately not an exception: the totals are correct and the invoice is
/// usable. What is questionable is the *input*, and only the user can settle
/// that — so the engine reports and the UI asks (D-027).
enum InvoiceWarningKind {
  /// A line's entered discount exceeded that line's gross, so only the line's
  /// worth was deducted.
  lineDiscountClamped,

  /// The invoice-level discount exceeded the subtotal, so only the subtotal
  /// was deducted. Unlike a line discount this one *must* be capped: it is
  /// part of the reconciliation invariant, and a negative grand total is never
  /// a valid document.
  invoiceDiscountClamped,
}

/// A single clamped input, with both figures so the UI can state the
/// difference exactly rather than saying "some discount was ignored".
///
/// Carries no message: user-facing text is Persian and belongs to the
/// localization layer, which this file may not reach.
class InvoiceWarning {
  const InvoiceWarning({
    required this.kind,
    required this.lineIndex,
    required this.requested,
    required this.applied,
  });

  final InvoiceWarningKind kind;

  /// The index into `InvoiceInput.lines`, or `null` for an invoice-level
  /// warning.
  final int? lineIndex;

  /// What the user entered.
  final Money requested;

  /// What was actually deducted.
  final Money applied;

  /// The part of [requested] that had no effect.
  Money get absorbed => requested - applied;

  @override
  String toString() =>
      'InvoiceWarning(${kind.name}, line: $lineIndex, '
      'requested: ${requested.rial}, applied: ${applied.rial})';
}

/// A computed invoice. Snapshotted onto `invoices`.
class CalculatedInvoice {
  const CalculatedInvoice({
    required this.lines,
    required this.subtotal,
    required this.invoiceDiscount,
    required this.invoiceDiscountRequested,
    required this.invoiceDiscountPercentBp,
    required this.totalDiscount,
    required this.totalTax,
    required this.roundingAdjustment,
    required this.grandTotal,
    required this.warnings,
  });

  final List<CalculatedLine> lines;

  /// `Σ lineNet` — before the invoice discount, before tax (§4 step 8).
  final Money subtotal;

  /// The invoice discount **actually applied**, after clamping to [subtotal].
  /// This is the figure the reconciliation invariant uses.
  final Money invoiceDiscount;

  /// The invoice discount as entered, before clamping.
  final Money invoiceDiscountRequested;

  final int? invoiceDiscountPercentBp;

  /// `Σ effective lineDiscount + effective invoiceDiscount` (§4 step 9, as
  /// corrected by D-027).
  ///
  /// **Effective, never as entered.** The number printed on an invoice must be
  /// the discount actually given, or the customer cannot reconcile the
  /// document by hand: a total discount of 150 against a line that only ever
  /// gave 100 is a defect the user finds before we do.
  ///
  /// A reporting figure, not part of the invariant, which is built from
  /// [subtotal].
  final Money totalDiscount;

  final Money totalTax;

  /// The delta introduced by optional whole-invoice rounding, kept so the
  /// invoice still reconciles exactly (§4 "Rounding").
  final Money roundingAdjustment;

  /// `Σ lineTotal`, plus [roundingAdjustment] when rounding is enabled
  /// (§4 step 11).
  final Money grandTotal;

  /// Inputs that were clamped, in line order with the invoice-level warning
  /// last. Empty for a clean invoice.
  ///
  /// The caller is expected to look: an over-large discount is nearly always a
  /// data-entry error, and absorbing it silently is how a wrong figure reaches
  /// a document nobody questions (D-027).
  final List<InvoiceWarning> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
}

/// Raised when the engine's own output fails to reconcile.
///
/// This should be unreachable. It is checked at runtime anyway, because the
/// alternative to crashing on an inconsistent invoice is persisting one.
class InvoiceReconciliationError implements Exception {
  const InvoiceReconciliationError(this.message);

  final String message;

  @override
  String toString() => 'InvoiceReconciliationError: $message';
}

/// Runs §4 in order and returns every intermediate the schema needs to store.
CalculatedInvoice calculateInvoice(InvoiceInput input) {
  _validate(input);

  // -- steps 1-3: per-line gross, discount, net ----------------------------
  final gross = <int>[];
  final requestedLineDiscounts = <int>[];
  final effectiveLineDiscounts = <int>[];
  final nets = <int>[];
  final warnings = <InvoiceWarning>[];

  for (var i = 0; i < input.lines.length; i++) {
    final line = input.lines[i];
    final lineGross = mulDivHalfUp(
      line.unitPrice.rial,
      line.quantityMilli,
      1000,
    );

    // A percentage, when given, is resolved against the line's gross and wins
    // over any absolute amount also supplied. Note that a percentage can never
    // trip the cap below: rates are validated at 0-10000 bp, so the resolved
    // amount is at most the gross. Only an absolute entry can overshoot.
    final requested = line.discountPercentBp != null
        ? applyBasisPoints(lineGross, line.discountPercentBp!)
: line.discount.rial;

    // §4 step 3's "clamped at >= 0", expressed as a cap on the discount rather
    // than on the net. The two produce the same net; capping the discount is
    // what makes step 9 able to report the amount actually given (D-027).
    final effective = requested > lineGross ? lineGross : requested;
    if (effective != requested) {
      warnings.add(
        InvoiceWarning(
          kind: InvoiceWarningKind.lineDiscountClamped,
          lineIndex: i,
          requested: Money.rial(requested),
          applied: Money.rial(effective),
        ),
      );
    }

    gross.add(lineGross);
    requestedLineDiscounts.add(requested);
    effectiveLineDiscounts.add(effective);
    nets.add(lineGross - effective);
  }

  // -- step 8 (computed early: the allocation needs it) --------------------
  final subtotal = nets.fold<int>(0, (sum, n) => sum + n);

  // -- step 4: resolve and clamp the invoice discount ----------------------
  final requestedInvoiceDiscount = input.discountPercentBp != null
      ? applyBasisPoints(subtotal, input.discountPercentBp!)
: input.discount.rial;

  // Clamped for a stronger reason than a line discount: this figure *is* part
  // of the invariant, so letting it exceed the subtotal would produce a
  // negative grand total, which is never a valid document. Reported the same
  // way, though — the caller still needs to know it happened (D-027).
  final invoiceDiscount = requestedInvoiceDiscount > subtotal
      ? subtotal
: requestedInvoiceDiscount;

  final allocations = allocateByLargestRemainder(
    amount: invoiceDiscount,
    weights: nets,
  );

  // -- steps 5-7: allocation, tax, line total ------------------------------
  final lines = <CalculatedLine>[];
  var totalTax = 0;
  var grandTotalFromLines = 0;
  var totalLineDiscount = 0;

  for (var i = 0; i < input.lines.length; i++) {
    final line = input.lines[i];
    final netAfter = nets[i] - allocations[i];

    // First non-null wins: item → invoice → settings default (§4 step 6).
    final rateBp = line.taxRateBp ?? input.taxRateBp ?? input.defaultTaxRateBp;
    final tax = applyBasisPoints(netAfter, rateBp);
    final total = netAfter + tax;

    totalTax += tax;
    grandTotalFromLines += total;
    totalLineDiscount += effectiveLineDiscounts[i];

    lines.add(
      CalculatedLine(
        gross: Money.rial(gross[i]),
        discount: Money.rial(effectiveLineDiscounts[i]),
        discountRequested: Money.rial(requestedLineDiscounts[i]),
        discountPercentBp: line.discountPercentBp,
        net: Money.rial(nets[i]),
        allocatedInvoiceDiscount: Money.rial(allocations[i]),
        netAfterInvoiceDiscount: Money.rial(netAfter),
        resolvedTaxRateBp: rateBp,
        tax: Money.rial(tax),
        total: Money.rial(total),
      ),
    );
  }

  // -- the §4 invariant, enforced rather than assumed ----------------------
  final expected = subtotal - invoiceDiscount + totalTax;
  if (grandTotalFromLines != expected) {
    throw InvoiceReconciliationError(
      'lines sum to $grandTotalFromLines but subtotal - invoiceDiscount + '
      'totalTax is $expected. The invoice-discount allocation did not '
      'distribute exactly; see §4 step 4 and discount_allocation.dart.',
    );
  }

  // -- optional final rounding ---------------------------------------------
  final rounded = roundToUnit(grandTotalFromLines, input.roundingUnitRial);
  final adjustment = rounded - grandTotalFromLines;

  // Appended after the line warnings, so `warnings` reads in document order.
  if (invoiceDiscount != requestedInvoiceDiscount) {
    warnings.add(
      InvoiceWarning(
        kind: InvoiceWarningKind.invoiceDiscountClamped,
        lineIndex: null,
        requested: Money.rial(requestedInvoiceDiscount),
        applied: Money.rial(invoiceDiscount),
      ),
    );
  }

  return CalculatedInvoice(
    lines: lines,
    subtotal: Money.rial(subtotal),
    invoiceDiscount: Money.rial(invoiceDiscount),
    invoiceDiscountRequested: Money.rial(requestedInvoiceDiscount),
    invoiceDiscountPercentBp: input.discountPercentBp,
    totalDiscount: Money.rial(totalLineDiscount + invoiceDiscount),
    totalTax: Money.rial(totalTax),
    roundingAdjustment: Money.rial(adjustment),
    grandTotal: Money.rial(rounded),
    warnings: List.unmodifiable(warnings),
  );
}

void _validate(InvoiceInput input) {
  void checkRate(int? bp, String name) {
    if (bp == null) return;
    if (bp < 0 || bp > 10000) {
      throw ArgumentError.value(
        bp,
        name,
        'basis points must be between 0 and 10000 (0%-100%)',
      );
    }
  }

  checkRate(input.defaultTaxRateBp, 'defaultTaxRateBp');
  checkRate(input.taxRateBp, 'taxRateBp');
  checkRate(input.discountPercentBp, 'discountPercentBp');

  if (input.discount.isNegative) {
    throw ArgumentError.value(
      input.discount.rial,
      'discount',
      'an invoice discount must not be negative',
    );
  }
  if (input.roundingUnitRial < 0) {
    throw ArgumentError.value(
      input.roundingUnitRial,
      'roundingUnitRial',
      'must not be negative',
    );
  }

  for (var i = 0; i < input.lines.length; i++) {
    final line = input.lines[i];
    checkRate(line.taxRateBp, 'lines[$i].taxRateBp');
    checkRate(line.discountPercentBp, 'lines[$i].discountPercentBp');

    if (line.quantityMilli < 0) {
      throw ArgumentError.value(
        line.quantityMilli,
        'lines[$i].quantityMilli',
        'must not be negative',
      );
    }
    if (line.unitPrice.isNegative) {
      throw ArgumentError.value(
        line.unitPrice.rial,
        'lines[$i].unitPrice',
        'must not be negative',
      );
    }
    if (line.discount.isNegative) {
      throw ArgumentError.value(
        line.discount.rial,
        'lines[$i].discount',
        'must not be negative',
      );
    }
  }
}
