import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/list_query.dart';
import '../../../data/models/invoice_detail.dart';
import '../../../data/models/invoice_list_item.dart';
import '../../../data/providers.dart';

part 'invoices_providers.g.dart';

/// The window the invoice list is currently asking the database for.
///
/// The same one-value-not-two shape as the customer and product lists, for the
/// same reason (D-038). The search term is unused here in Phase 1 — the invoice
/// list has no search field yet — but the window still exists, because the
/// paging is what makes the list survive five thousand invoices, and that is
/// needed on the first day rather than the day someone notices.
@riverpod
class InvoiceListQuery extends _$InvoiceListQuery {
  @override
  ListQuery build() => const ListQuery();

  void loadMore() => state = state.loadingMore();
}

/// The invoice list, as a live query over the current window.
///
/// **The limit reaches SQL** (D-038), and the customer name is resolved by the
/// same query rather than by a lookup per row (D-040).
@riverpod
Stream<List<InvoiceListItem>> invoiceList(Ref ref) {
  final ListQuery query = ref.watch(invoiceListQueryProvider);
  return ref.watch(invoiceRepositoryProvider).watchList(limit: query.limit);
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
