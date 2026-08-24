import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/security/app_log.dart';
import '../../../core/utils/list_query.dart';
import '../../../data/models/customer.dart';
import '../../../data/providers.dart';

part 'customers_providers.g.dart';

/// The window the customer list is currently asking the database for.
///
/// Held as one value rather than as separate term and page providers, so that
/// starting a search resets the page window in the same state change — see
/// [ListQuery.searching]. Two providers would let the two drift apart for one
/// frame, and the symptom would be a search that quietly asks for two thousand
/// matches.
@riverpod
class CustomerListQuery extends _$CustomerListQuery {
  @override
  ListQuery build() => const ListQuery();

  void search(String term) => state = state.searching(term);

  void loadMore() => state = state.loadingMore();
}

/// The customer list, as a live query over the current window.
///
/// **The limit reaches SQL.** `watchAll` and `watchSearch` both take it
/// straight to the query, so growing the window is a wider `LIMIT` rather than
/// a longer list filtered in Dart (§13).
///
/// Auto-disposed: there is no reason to hold a query open while the customer
/// screen is not on screen (§3).
@riverpod
Stream<List<Customer>> customerList(Ref ref) {
  final ListQuery query = ref.watch(customerListQueryProvider);
  final repository = ref.watch(customerRepositoryProvider);

  return query.isSearching
      ? repository.watchSearch(query.term, limit: query.limit)
      : repository.watchAll(limit: query.limit);
}

/// One customer, for the edit form.
///
/// A provider rather than an object handed through the route, so that opening
/// `/customers/<id>/edit` directly — a restored deep link, a typed Web URL —
/// loads the same screen as tapping the row does.
@riverpod
Future<Customer?> customerById(Ref ref, String id) {
  return ref.watch(customerRepositoryProvider).findById(id);
}

/// The customer write path.
///
/// Exists so that **no widget calls a repository** (`ARCHITECTURE.md` §B.1:
/// widget → provider → repository → DAO). A form that awaited
/// `customerRepositoryProvider` directly would compile and work, and it is
/// precisely the shortcut that erodes the layering: the next screen copies it,
/// and soon the write path is spread across the presentation layer with no
/// single place to test it or to log it.
///
/// It also owns the logging. A save is a data-layer event, not a presentation
/// one, and §7's rule about what may be logged is easier to hold in one
/// controller than in every form that writes.
///
/// Its `AsyncValue` state is the in-flight flag: a form disables its save
/// button while `isLoading`, so a double tap cannot create two customers.
@riverpod
class CustomerEditor extends _$CustomerEditor {
  @override
  FutureOr<void> build() {}

  /// Creates when [id] is null, otherwise replaces. Returns null on failure —
  /// the error is logged and held in [state]; the caller only decides what to
  /// tell the user.
  Future<Customer?> save({String? id, required CustomerDraft draft}) async {
    state = const AsyncValue<void>.loading();
    try {
      final repository = ref.read(customerRepositoryProvider);
      final Customer saved = id == null
          ? await repository.create(draft)
          : await repository.update(id, draft);

      // The id, and nothing else. Every other field on a customer is something
      // §7 forbids logging, and `logging_path_test.dart` fails the build if
      // one appears in an AppLog call.
      AppLog.info(() => 'customer saved: ${saved.id}', scope: 'customers');
      state = const AsyncValue<void>.data(null);
      return saved;
    } catch (error, stack) {
      AppLog.error(
        () => 'customer save failed',
        error: error,
        stackTrace: stack,
        scope: 'customers',
      );
      state = AsyncValue<void>.error(error, stack);
      return null;
    }
  }

  /// Soft-deletes (D-003). Never a hard delete: a customer referenced by an
  /// invoice must survive, and a hard delete cannot be propagated to another
  /// device. Returns whether it succeeded.
  Future<bool> delete(String id) async {
    state = const AsyncValue<void>.loading();
    try {
      await ref.read(customerRepositoryProvider).softDelete(id);
      AppLog.info(() => 'customer soft-deleted: $id', scope: 'customers');
      state = const AsyncValue<void>.data(null);
      return true;
    } catch (error, stack) {
      AppLog.error(
        () => 'customer delete failed',
        error: error,
        stackTrace: stack,
        scope: 'customers',
      );
      state = AsyncValue<void>.error(error, stack);
      return false;
    }
  }
}
