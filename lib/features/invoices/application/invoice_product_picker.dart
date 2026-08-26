import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/list_query.dart';
import '../../../data/models/product.dart';
import '../../../data/providers.dart';

part 'invoice_product_picker.g.dart';

/// The window the invoice form's product picker is asking the database for.
///
/// **Its own provider, not `ProductListQuery`.** The picker is a sheet opened
/// over the invoice form while the products screen may be sitting behind it on
/// another destination with its own search and its own scroll position.
/// Sharing the window would mean typing a search here silently re-queried that
/// screen and lost the user's place on it — and, worse, that closing the sheet
/// left the products screen filtered by a term the user typed somewhere else.
///
/// The same reasoning `ProductListQuery` records for not sharing with
/// `CustomerListQuery`, one screen further along.
@riverpod
class InvoiceProductPickerQuery extends _$InvoiceProductPickerQuery {
  @override
  ListQuery build() => const ListQuery();

  void search(String term) => state = state.searching(term);

  void loadMore() => state = state.loadingMore();
}

/// The catalogue, as the picker sees it.
///
/// A live query like every other list (§13): the limit reaches SQL rather than
/// being applied after loading everything. Auto-disposed with the sheet, so
/// the next invoice opens a picker with no search term left in it.
@riverpod
Stream<List<Product>> invoiceProductPickerList(Ref ref) {
  final ListQuery query = ref.watch(invoiceProductPickerQueryProvider);
  final repository = ref.watch(productRepositoryProvider);

  return query.isSearching
      ? repository.watchSearch(query.term, limit: query.limit)
      : repository.watchAll(limit: query.limit);
}
