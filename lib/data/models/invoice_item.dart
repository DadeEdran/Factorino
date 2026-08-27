import '../../core/money/money.dart';

/// One line of an invoice.
///
/// **The snapshot fields are the point** (D-004). [title], [unit] and
/// [unitPrice] are copies taken when the invoice was created, not references
/// resolved at read time. [productId] is kept for traceability only and must
/// never be used to look a price back up.
class InvoiceItem {
  const InvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.position,
    required this.title,
    required this.unit,
    required this.unitPrice,
    required this.quantityMilli,
    required this.discount,
    required this.resolvedTaxRateBp,
    required this.gross,
    required this.allocatedInvoiceDiscount,
    required this.lineNet,
    required this.lineTax,
    required this.lineTotal,
    this.productId,
    this.discountPercentBp,
  });

  final String id;
  final String invoiceId;

  /// Ordering within the invoice, so lines render as the user arranged them.
  final int position;

  /// Kept for traceability. **Not** a pricing reference.
  final String? productId;

  final String title;
  final String unit;
  final Money unitPrice;

  /// Quantity scaled by 1000: `1.5` is `1500` (§4). Integer, so a fractional
  /// kilogram or hour never introduces floating point into the money path.
  final int quantityMilli;

  /// The discount **actually given** on this line, after clamping to the
  /// line's gross (D-027).
  final Money discount;
  final int? discountPercentBp;

  /// The rate that actually applied, snapshotted so a later change to the
  /// settings default cannot alter an issued invoice (§4 step 6, D-026).
  final int resolvedTaxRateBp;

  /// **مبلغ کل** on the printed line: `unitPrice x quantity`, half-up (§4
  /// step 1). Null only on a pre-v4 row the backfill refused (D-055).
  final Money? gross;

  /// This line's share of the invoice-level discount (§4 step 4), without which
  /// [lineNet] cannot be explained on the document — it is already net of this
  /// amount, and the header prints the same deduction again. Null exactly when
  /// [gross] is.
  final Money? allocatedInvoiceDiscount;

  /// `gross - discount - allocatedInvoiceDiscount` — **مبلغ پس از تخفیف**.
  final Money lineNet;

  final Money lineTax;
  final Money lineTotal;

  /// Whether this line can be laid out as a document line without any figure
  /// being re-derived.
  bool get hasStoredGross => gross != null;

  /// The quantity as a decimal, for display only. Never used in arithmetic --
  /// the money path stays integer throughout (D-002).
  double get quantityForDisplay => quantityMilli / 1000;

  @override
  bool operator ==(Object other) => other is InvoiceItem && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'InvoiceItem($id)';
}
