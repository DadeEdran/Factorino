import '../../core/money/money.dart';
import 'customer.dart';
import 'invoice.dart';
import 'invoice_item.dart';
import 'payment.dart';

/// An invoice with everything a detail view or a document renderer needs,
/// assembled in one read.
///
/// The aggregate exists so that no widget assembles it. A screen that fetched
/// the header, then the lines, then the payments would be doing data-layer work
/// in the presentation layer (§3) -- and would show a half-loaded document
/// while it did.
///
/// [amountPaid] and [amountDue] are computed here rather than stored, because
/// unlike the invoice totals they are **not** historical: they change every
/// time a payment is recorded. The invoice's own totals stay snapshots (D-004).
class InvoiceDetail {
  const InvoiceDetail({
    required this.invoice,
    required this.customer,
    required this.items,
    required this.payments,
  });

  final Invoice invoice;

  /// The customer as they are **now**, not as they were at issue time.
  ///
  /// Deliberate: a customer's address or phone changing should show through on
  /// the invoice, unlike pricing, which is snapshotted (D-004). If a future
  /// phase needs the historical party details on a reissued document, that is
  /// a schema change and a decision entry, not a quiet join.
  final Customer customer;

  /// In [InvoiceItem.position] order.
  final List<InvoiceItem> items;

  /// Most recent first.
  final List<Payment> payments;

  /// The sum of payments recorded against this invoice.
  Money get amountPaid =>
      payments.fold(Money.zero, (total, payment) => total + payment.amount);

  /// What is still owed, never negative: an overpayment shows as fully paid
  /// rather than as a negative balance, which is not a thing an invoice can
  /// owe.
  Money get amountDue => (invoice.grandTotal - amountPaid).clampedToZero;

  bool get isFullyPaid => amountPaid >= invoice.grandTotal;

  /// Whether the customer paid more than the invoice asked for. Worth
  /// surfacing rather than hiding -- it is usually a data-entry error, and it
  /// is invisible in [amountDue] by design.
  bool get isOverpaid => amountPaid > invoice.grandTotal;

  @override
  String toString() => 'InvoiceDetail(${invoice.id})';
}
