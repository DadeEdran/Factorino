import '../../../core/utils/list_query.dart';
import '../../../data/models/invoice_filter.dart';

/// What the invoice list is currently asking the database for: a window, and a
/// filter.
///
/// **One value rather than two providers**, which is the same decision
/// `ListQuery` records about the search term and the limit (D-038), and it is
/// made here for a sharper reason: **changing the filter must reset the
/// window.** A user who has loaded eight pages of invoices and then narrows to
/// «پرداخت نشده» should not have the app ask the database for three hundred and
/// twenty unpaid invoices. Held as two independent pieces of state that reset
/// is a rule somebody has to remember; held as one value it is [filtering].
///
/// It also means the list never renders a window belonging to one filter beside
/// results belonging to another, which is what two providers settling at
/// different moments would produce.
class InvoiceQuery {
  const InvoiceQuery({
    this.window = const ListQuery(),
    this.filter = InvoiceFilter.none,
  });

  /// The page. `term` is unused here — the invoice list has no search field —
  /// but the limit is what reaches SQL.
  final ListQuery window;

  /// The predicate, applied in SQL by the repository.
  final InvoiceFilter filter;

  bool get isFiltered => filter.isActive;

  /// One more page of the **same** filter.
  InvoiceQuery loadingMore() =>
      InvoiceQuery(window: window.loadingMore(), filter: filter);

  /// A different filter, from the first page.
  InvoiceQuery filtering(InvoiceFilter value) => InvoiceQuery(filter: value);

  @override
  bool operator ==(Object other) =>
      other is InvoiceQuery && other.window == window && other.filter == filter;

  @override
  int get hashCode => Object.hash(window, filter);

  @override
  String toString() => 'InvoiceQuery($window, $filter)';
}
