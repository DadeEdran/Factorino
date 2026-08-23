import '../../core/money/money.dart';
import 'payment_method.dart';

/// Money received against an invoice.
///
/// The sum of these is what derives an invoice's `partiallyPaid` / `paid`
/// status. That recomputation happens in the **same transaction** as the
/// payment write: a payment that lands without its status
/// update leaves a wrong badge on a financial document.
class Payment {
  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paidAt,
    required this.method,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  final String id;
  final String invoiceId;
  final Money amount;

  /// UTC (D-005).
  final DateTime paidAt;

  final PaymentMethod method;
  final String? note;

  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is Payment && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);

  @override
  String toString() => 'Payment($id)';
}

/// The editable fields of a payment -- what a form produces.
class PaymentDraft {
  const PaymentDraft({
    required this.amount,
    required this.paidAt,
    required this.method,
    this.note,
  });

  final Money amount;
  final DateTime paidAt;
  final PaymentMethod method;
  final String? note;
}
