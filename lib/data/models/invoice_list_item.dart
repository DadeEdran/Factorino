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
  const InvoiceListItem({
    required this.invoice,
    required this.liveCustomerName,
  });

  final Invoice invoice;

  /// The customer's name **as it is now**, from the live record.
  ///
  /// Present even when the customer has been soft-deleted: §6 guarantees a
  /// customer referenced by an invoice is never hard-deleted, and the Persian
  /// copy on the delete dialog promises the invoices survive untouched. An
  /// invoice that dropped out of the list, or listed under a blank name, the
  /// moment its customer was deleted would make that promise false.
  ///
  /// Rarely what a row should display — see [customerName].
  final String liveCustomerName;

  /// The name the row shows: the one the **document** states, falling back to
  /// the live record for a draft and for anything issued before schema v3
  /// (D-052).
  ///
  /// A getter rather than a constructor argument, and that is the point. There
  /// are two places an [InvoiceListItem] is built — the list query's join and
  /// the customer detail page, which already has the one name it needs — and a
  /// rule applied at each construction site is a rule one of them eventually
  /// applies differently. Here there is nowhere to put a second answer:
  /// callers supply the live name and the fallback happens once, in
  /// [Invoice.partyName].
  String get customerName => invoice.partyName(liveCustomerName);

  @override
  bool operator ==(Object other) =>
      other is InvoiceListItem &&
      other.invoice == invoice &&
      other.liveCustomerName == liveCustomerName;

  @override
  int get hashCode => Object.hash(invoice, liveCustomerName);

  @override
  String toString() => 'InvoiceListItem(${invoice.id})';
}
