import 'invoice.dart';

/// An invoice as a list shows it: the header, plus the one field a list needs
/// that the header does not carry.
///
/// [Invoice] holds `customerId` and nothing else about the customer, which is
/// correct for a header — but a list of invoices that shows an id is useless,
/// and a list that resolves each id separately is an N+1 read issued from the
/// presentation layer. So the join happens once, in SQL, and this is what it
/// produces.
///
/// **It deliberately carries no payment information.** Nothing here would let a
/// widget compare payments against a total and decide for itself whether an
/// invoice is paid — that determination is made in the repository on every
/// payment write and persisted, and a second, independent
/// answer computed at display time is exactly the disagreement that puts a
/// wrong badge on a financial document. The UI cannot recompute it because the
/// UI is not given the inputs.
class InvoiceListItem {
  const InvoiceListItem({required this.invoice, required this.customerName});

  final Invoice invoice;

  /// The customer's name **as it is now**, matching `InvoiceDetail.customer`.
  ///
  /// Present even when the customer has been soft-deleted: §6 guarantees a
  /// customer referenced by an invoice is never hard-deleted, and the Persian
  /// copy on the delete dialog promises the invoices survive untouched. An
  /// invoice that dropped out of the list, or listed under a blank name, the
  /// moment its customer was deleted would make that promise false.
  final String customerName;

  @override
  bool operator ==(Object other) =>
      other is InvoiceListItem &&
      other.invoice == invoice &&
      other.customerName == customerName;

  @override
  int get hashCode => Object.hash(invoice, customerName);

  @override
  String toString() => 'InvoiceListItem(${invoice.id})';
}
