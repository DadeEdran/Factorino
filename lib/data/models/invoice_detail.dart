import '../../core/money/money.dart';
import 'customer.dart';
import 'customer_snapshot.dart';
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
    this.customerIsDeleted = false,
  });

  final Invoice invoice;

  /// The customer as they are **now**.
  ///
  /// This is the live record: the contact details to reach them on, and the
  /// row a "go to customer" action navigates to. It is **not** what the
  /// document says about the party — see [party].
  final Customer customer;

  /// Whether [customer] is a **soft-deleted** row.
  ///
  /// The customer behind an invoice is read soft-delete-exempt, because §6
  /// guarantees a referenced customer is soft-deleted and never removed, and an
  /// invoice that stopped opening when its customer was deleted would break the
  /// promise the delete dialog makes in Persian. That exemption is what makes
  /// this flag necessary: [customer] is a live record that may no longer be in
  /// the customer list, and a screen offering «رفتن به مشتری» has to know the
  /// difference between a record and a headstone.
  ///
  /// [Customer] itself carries no delete state on purpose — everywhere else in
  /// the application a deleted customer simply is not returned, and putting the
  /// flag on the model would invite a screen to check it where the query has
  /// already answered. This aggregate is the one read path where the question
  /// survives, so this is where the answer lives.
  final bool customerIsDeleted;

  /// The party as the **document** states them (D-052).
  ///
  /// The snapshot taken at issue, or the live record for a draft and for
  /// anything issued before schema v3. Anything rendering or printing this
  /// invoice reads here, not [customer]: a name, a کد ملی or a کد اقتصادی
  /// corrected after the fact must not change a document that has been sent,
  /// paid and filed, which is D-004's rule applied to the party rather than
  /// the price.
  ///
  /// The mobile number is deliberately not part of it and still comes from
  /// [customer]: contact detail, not document content.
  CustomerSnapshot get party => invoice.party(customer);

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
