import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/invoice_detail.dart';
import '../../../data/models/invoice_filter.dart';
import '../../../data/models/invoice_list_item.dart';
import '../../../data/providers.dart';
import '../domain/invoice_query.dart';

part 'invoices_providers.g.dart';

/// The window **and the filter** the invoice list is currently asking the
/// database for.
///
/// The same one-value-not-two shape as the customer and product lists, for the
/// same reason (D-038) — and since Phase 5 (e) it carries the filter too, so
/// that narrowing the list resets the window rather than asking the database
/// for eight pages of a set the user has just made smaller. See [InvoiceQuery].
@riverpod
class InvoiceListQuery extends _$InvoiceListQuery {
  @override
  InvoiceQuery build() => const InvoiceQuery();

  void loadMore() => state = state.loadingMore();

  /// Replaces the whole filter. The screen builds the new value from the old
  /// one — `filter.withStatuses(...)`, `withCustomer(null)` — so there is one
  /// way in rather than one method per field, and clearing is not a special
  /// case.
  void filter(InvoiceFilter value) => state = state.filtering(value);

  void clearFilter() => state = state.filtering(InvoiceFilter.none);
}

/// The invoice list, as a live query over the current window and filter.
///
/// **Both the limit and the filter reach SQL** (D-038, and §13's rule that
/// aggregation and narrowing run as queries rather than as Dart loops over a
/// loaded page). The customer name is resolved by the same query rather than by
/// a lookup per row (D-040).
///
/// Nothing here narrows the returned list. If this provider ever grows a
/// `.where(...)` over `items`, the limit has already been applied to the
/// unfiltered set and the page is wrong — that is the failure mode the
/// repository test `the filter reaches SQL, so the page is of matches` pins.
@riverpod
Stream<List<InvoiceListItem>> invoiceList(Ref ref) {
  final InvoiceQuery query = ref.watch(invoiceListQueryProvider);
  return ref
      .watch(invoiceRepositoryProvider)
      .watchList(filter: query.filter, limit: query.window.limit);
}

/// One invoice, with its lines, its payments and its customer, as a live query.
///
/// **Assembled by the repository in one read**, never by this provider and
/// never by the screen (§3): a page that fetched the header, then the lines,
/// then the payments would be doing data-layer work in the presentation layer
/// and would render a half-loaded document while it did.
///
/// Watched rather than read, because the detail screen is where a payment is
/// recorded (increment (c)) and the derived status is recomputed by the write —
/// so the page has to follow the row rather than the row having to tell the
/// page. It re-reads on any change to the invoice table, which is correct but
/// not minimal; that is known issue 4 and belongs to Phase 13.
///
/// Auto-disposed with the screen, which is the whole reason it is a family
/// rather than a single provider holding an id.
@riverpod
Stream<InvoiceDetail?> invoiceDetail(Ref ref, String id) {
  return ref.watch(invoiceRepositoryProvider).watchDetail(id);
}
