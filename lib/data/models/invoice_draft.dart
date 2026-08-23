import '../../core/money/money.dart';

/// An invoice as a form produces it: what the user chose, with nothing
/// computed and no number allocated.
///
/// Everything derived -- line totals, tax, the invoice number, the grand total
/// -- is the repository's to produce, inside the transaction that writes it.
/// A draft that carried computed totals would let a caller supply totals that
/// disagreed with the lines, and the invoice would be persisted before anything
/// noticed.
class InvoiceDraft {
  const InvoiceDraft({
    required this.customerId,
    required this.issueDate,
    required this.items,
    this.dueDate,
    this.discount = Money.zero,
    this.discountPercentBp,
    this.taxRateBp,
    this.notes,
  });

  final String customerId;

  /// UTC (D-005). The Jalali year of this instant is what the invoice number
  /// is allocated against (D-013).
  final DateTime issueDate;
  final DateTime? dueDate;

  final List<InvoiceItemDraft> items;

  /// Invoice-level discount, allocated across the lines before tax (§4 step 4).
  final Money discount;
  final int? discountPercentBp;

  /// `null` inherits the settings default; `0` is a real rate meaning zero
  /// percent (D-026).
  final int? taxRateBp;

  final String? notes;
}

/// One line as a form produces it.
///
/// [title], [unit] and [unitPrice] are given explicitly even when [productId]
/// is set, because they are **snapshots** (D-004): the caller states what the
/// invoice says, and the repository stores exactly that. Resolving them from
/// the product row at write time would look equivalent and would quietly make
/// the line follow later price changes.
class InvoiceItemDraft {
  const InvoiceItemDraft({
    required this.title,
    required this.unit,
    required this.unitPrice,
    required this.quantityMilli,
    this.productId,
    this.discount = Money.zero,
    this.discountPercentBp,
    this.taxRateBp,
  });

  /// Traceability only; never a pricing reference.
  final String? productId;

  final String title;
  final String unit;
  final Money unitPrice;

  /// Scaled by 1000: `1.5` is `1500` (§4).
  final int quantityMilli;

  final Money discount;
  final int? discountPercentBp;

  /// Item-level tax rate, the first step of the resolution order
  /// item → invoice → settings default (§4 step 6).
  final int? taxRateBp;
}
