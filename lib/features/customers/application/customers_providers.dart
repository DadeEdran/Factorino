import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/security/app_log.dart';
import '../../../core/utils/list_query.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/customer_totals.dart';
import '../../../data/models/invoice.dart';
import '../../../data/models/invoice_list_item.dart';
import '../../../data/providers.dart';
import '../domain/customer_detail_view.dart';

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

/// Everything the customer detail screen shows, read together.
///
/// Composed here rather than in the screen, so the page has one loading state,
/// one error state and one moment — see [CustomerDetailView]. Each
/// `ref.watch(...future)` below is a **live** query underneath, so a recorded
/// payment or an edited record updates the page without it having to know why.
///
/// Returns null when the id does not resolve: a stale deep link, or a customer
/// soft-deleted while the page was opening. The screen says so in Persian and
/// offers the way back; rendering an empty record would be worse, because it
/// looks like a customer with no details rather than no customer.
@riverpod
Future<CustomerDetailView?> customerDetail(Ref ref, String id) async {
  final Customer? customer = await ref.watch(customerByIdProvider(id).future);
  if (customer == null) return null;

  final CustomerTotals totals = await ref.watch(
    _customerTotalsProvider(id).future,
  );
  final List<Invoice> invoices = await ref.watch(
    _customerInvoicesProvider(id).future,
  );

  return CustomerDetailView(
    customer: customer,
    totals: totals,
    // The name is the one already loaded, not a lookup per row (D-040). A
    // customer's own page is the one place the join `watchList` performs is
    // genuinely unnecessary -- there is exactly one name and it is in hand.
    //
    // The **live** name: an invoice issued under an older one shows the older
    // one, because `InvoiceListItem.customerName` prefers the party snapshot
    // (D-052). On this page in particular that is worth having -- it is the
    // page where a rename is most likely to have just happened.
    invoices: invoices
        .map(
          (Invoice invoice) => InvoiceListItem(
            invoice: invoice,
            liveCustomerName: customer.fullName,
          ),
        )
        .toList(),
  );
}

/// The two figures, as one live SQL aggregate.
///
/// Private, like the dashboard's: a widget that watched this on its own could
/// render a balance from a different moment than the list beside it, which is
/// what [CustomerDetailView] exists to prevent.
@riverpod
Stream<CustomerTotals> _customerTotals(Ref ref, String id) =>
    ref.watch(invoiceRepositoryProvider).watchCustomerTotals(id);

/// This customer's invoices.
///
/// `watchForCustomer` was built in increment (d) for this screen and had no
/// call site until now. Using it rather than adding a parallel read is
/// deliberate: a second query answering the same question is a second place for
/// the soft-delete filter and the ordering to be got wrong.
@riverpod
Stream<List<Invoice>> _customerInvoices(Ref ref, String id) =>
    ref.watch(invoiceRepositoryProvider).watchForCustomer(id);

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
    // A write must outlive the widget that started it.
    //
    // Nothing watches this controller from a list row or a detail page -- they
    // read the notifier and await it -- so without this link the provider
    // auto-disposes during the await, and the `state` write below throws
    // `UnmountedRefException`. The delete had already happened by then, so the
    // user saw no confirmation for something that did occur. The form does not
    // hit this because it watches the controller for its in-flight flag, which
    // is exactly why the defect survived (f1): the one call site that was
    // exercised was the one that happened to keep it alive.
    //
    // Scoped rather than `keepAlive: true` on the provider (§3 prefers
    // auto-disposed): the link is held for the duration of the write and
    // closed after it.
    final link = ref.keepAlive();
    try {
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
    } finally {
      link.close();
    }
  }

  /// Soft-deletes (D-003). Never a hard delete: a customer referenced by an
  /// invoice must survive, and a hard delete cannot be propagated to another
  /// device. Returns whether it succeeded.
  Future<bool> delete(String id) async {
    // A write must outlive the widget that started it.
    //
    // Nothing watches this controller from a list row or a detail page -- they
    // read the notifier and await it -- so without this link the provider
    // auto-disposes during the await, and the `state` write below throws
    // `UnmountedRefException`. The delete had already happened by then, so the
    // user saw no confirmation for something that did occur. The form does not
    // hit this because it watches the controller for its in-flight flag, which
    // is exactly why the defect survived (f1): the one call site that was
    // exercised was the one that happened to keep it alive.
    //
    // Scoped rather than `keepAlive: true` on the provider (§3 prefers
    // auto-disposed): the link is held for the duration of the write and
    // closed after it.
    final link = ref.keepAlive();
    try {
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
    } finally {
      link.close();
    }
  }
}
