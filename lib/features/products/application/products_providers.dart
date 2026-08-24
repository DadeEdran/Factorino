import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/security/app_log.dart';
import '../../../core/utils/list_query.dart';
import '../../../data/models/product.dart';
import '../../../data/providers.dart';

part 'products_providers.g.dart';

/// The window the product list is currently asking the database for.
///
/// The same shape as `CustomerListQuery`, and deliberately a separate provider
/// rather than a shared one: the two lists are on different destinations, each
/// keeps its own scroll position and its own search, and a shared window would
/// reset one when the user searched the other.
@riverpod
class ProductListQuery extends _$ProductListQuery {
  @override
  ListQuery build() => const ListQuery();

  void search(String term) => state = state.searching(term);

  void loadMore() => state = state.loadingMore();
}

/// The product list, as a live query over the current window.
@riverpod
Stream<List<Product>> productList(Ref ref) {
  final ListQuery query = ref.watch(productListQueryProvider);
  final repository = ref.watch(productRepositoryProvider);

  return query.isSearching
      ? repository.watchSearch(query.term, limit: query.limit)
      : repository.watchAll(limit: query.limit);
}

/// One product, for the edit form.
@riverpod
Future<Product?> productById(Ref ref, String id) {
  return ref.watch(productRepositoryProvider).findById(id);
}

/// The product write path.
///
/// The customer editor's twin, and it exists for the same reason: a widget
/// never calls a repository (`ARCHITECTURE.md` §B.1), and the logging rule from
/// §7 is held in one place rather than in every form.
@riverpod
class ProductEditor extends _$ProductEditor {
  @override
  FutureOr<void> build() {}

  /// Creates when [id] is null, otherwise replaces.
  Future<Product?> save({String? id, required ProductDraft draft}) async {
    state = const AsyncValue<void>.loading();
    try {
      final repository = ref.read(productRepositoryProvider);
      final Product saved = id == null
          ? await repository.create(draft)
          : await repository.update(id, draft);

      // The id only: a price is a monetary amount, which §7 forbids logging.
      AppLog.info(() => 'product saved: ${saved.id}', scope: 'products');
      state = const AsyncValue<void>.data(null);
      return saved;
    } catch (error, stack) {
      AppLog.error(
        () => 'product save failed',
        error: error,
        stackTrace: stack,
        scope: 'products',
      );
      state = AsyncValue<void>.error(error, stack);
      return null;
    }
  }

  /// Soft-deletes (D-003). A product referenced by an invoice must survive —
  /// though the invoice would be unaffected either way, because it snapshotted
  /// the title, unit and price when it was issued (D-004).
  Future<bool> delete(String id) async {
    state = const AsyncValue<void>.loading();
    try {
      await ref.read(productRepositoryProvider).softDelete(id);
      AppLog.info(() => 'product soft-deleted: $id', scope: 'products');
      state = const AsyncValue<void>.data(null);
      return true;
    } catch (error, stack) {
      AppLog.error(
        () => 'product delete failed',
        error: error,
        stackTrace: stack,
        scope: 'products',
      );
      state = AsyncValue<void>.error(error, stack);
      return false;
    }
  }
}
