import '../models/invoice.dart';
import '../models/payment.dart';

/// The payment boundary. Must not import drift -- see `CustomerRepository`.
///
/// Every write here **recomputes and persists the invoice's derived status in
/// the same transaction**. Splitting the two would leave a
/// window in which a paid invoice still reads as unpaid, and a crash inside
/// that window would make it permanent -- a wrong badge on a financial
/// document, with the payment sitting right there contradicting it.
abstract interface class PaymentRepository {
  /// Payments against [invoiceId], most recent first.
  Stream<List<Payment>> watchForInvoice(String invoiceId);

  Future<List<Payment>> findForInvoice(String invoiceId);

  /// The sum of payments against [invoiceId], in Rial, computed in SQL.
  Future<int> totalPaidRial(String invoiceId);

  /// Records a payment and returns the invoice as it stands afterwards, so the
  /// caller sees the recomputed status without a second read.
  ///
  /// Throws [PaymentNotAccepted] if the invoice is a draft or cancelled:
  /// a draft is not yet a claim on anyone, and a cancelled invoice is not one
  /// any more.
  Future<PaymentResult> record(String invoiceId, PaymentDraft draft);

  /// Soft-deletes a payment and recomputes the invoice status, in one
  /// transaction -- an unrecorded payment moves the status back just as a
  /// recorded one moves it forward.
  Future<PaymentResult> softDelete(String paymentId);
}

/// A payment write and the invoice state it produced.
class PaymentResult {
  const PaymentResult({required this.invoice, required this.payment});

  final Invoice invoice;

  /// `null` when the write was a deletion.
  final Payment? payment;
}

/// Raised when a payment is recorded against an invoice that cannot take one.
class PaymentNotAccepted implements Exception {
  const PaymentNotAccepted(this.invoiceId, this.reason);

  final String invoiceId;
  final String reason;

  @override
  String toString() => 'PaymentNotAccepted: invoice $invoiceId -- $reason';
}
