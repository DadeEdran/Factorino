import '../../../data/models/customer.dart';
import '../../../data/models/customer_totals.dart';
import '../../../data/models/invoice_list_item.dart';

/// Everything the customer detail screen shows, from one moment.
///
/// One value rather than three providers the screen assembles, for the reason
/// `DashboardSummary` is one value: the totals and the invoice list sit on the
/// same page and the user reads them together. Settled independently they would
/// occasionally show a balance from before a payment beside the list from after
/// it — a pair that never existed, and one the user would try to reconcile.
///
/// It also gives the page one loading state and one error state, so there is
/// one skeleton rather than three regions arriving out of step.
class CustomerDetailView {
  const CustomerDetailView({
    required this.customer,
    required this.totals,
    required this.invoices,
  });

  final Customer customer;

  /// Billed and outstanding, both computed in SQL over **every** invoice this
  /// customer has — not over [invoices], which is a page of them.
  final CustomerTotals totals;

  /// This customer's invoices, newest first.
  ///
  /// [InvoiceListItem] rather than `Invoice` so the rows can be the same
  /// widgets the invoice list uses. The customer name they carry is the one
  /// already loaded above, not a second read: resolving it per row would be an
  /// N+1 query issued from a screen that already has the answer.
  final List<InvoiceListItem> invoices;
}
