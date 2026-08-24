import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/list_query.dart';
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
