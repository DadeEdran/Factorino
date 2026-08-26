import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/list_query.dart';
import '../../../data/models/customer.dart';
import '../../../data/providers.dart';

part 'invoice_customer_picker.g.dart';

/// The window the invoice form's customer picker is asking the database for.
///
/// Its own provider rather than `CustomerListQuery`, for the reason
/// `InvoiceProductPickerQuery` records: the customers screen may be sitting on
/// another destination with its own search and scroll position, and closing
/// this sheet must not leave that screen filtered by a term the user typed
/// here.
@riverpod
class InvoiceCustomerPickerQuery extends _$InvoiceCustomerPickerQuery {
  @override
  ListQuery build() => const ListQuery();

  void search(String term) => state = state.searching(term);

  void loadMore() => state = state.loadingMore();
}

/// The customer list, as the picker sees it.
///
/// **`watchSearch` is the normalization-insensitive search** (D-025, D-029),
/// not a second path built for this sheet: the repository folds the term
/// through `searchKey` — the same normalizer that wrote `search_name` — so a
/// customer saved as «علي» is found by typing «علی», and ZWNJ and diacritics
/// fold away on both sides. A picker that filtered a loaded list in Dart would
/// be a parallel implementation of that, and it would be the one that quietly
/// stopped matching.
@riverpod
Stream<List<Customer>> invoiceCustomerPickerList(Ref ref) {
  final ListQuery query = ref.watch(invoiceCustomerPickerQueryProvider);
  final repository = ref.watch(customerRepositoryProvider);

  return query.isSearching
      ? repository.watchSearch(query.term, limit: query.limit)
      : repository.watchAll(limit: query.limit);
}
