// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoices_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The window the invoice list is currently asking the database for.
///
/// The same one-value-not-two shape as the customer and product lists, for the
/// same reason (D-038). The search term is unused here in Phase 1 — the invoice
/// list has no search field yet — but the window still exists, because the
/// paging is what makes the list survive five thousand invoices, and that is
/// needed on the first day rather than the day someone notices.

@ProviderFor(InvoiceListQuery)
final invoiceListQueryProvider = InvoiceListQueryProvider._();

/// The window the invoice list is currently asking the database for.
///
/// The same one-value-not-two shape as the customer and product lists, for the
/// same reason (D-038). The search term is unused here in Phase 1 — the invoice
/// list has no search field yet — but the window still exists, because the
/// paging is what makes the list survive five thousand invoices, and that is
/// needed on the first day rather than the day someone notices.
final class InvoiceListQueryProvider
    extends $NotifierProvider<InvoiceListQuery, ListQuery> {
  /// The window the invoice list is currently asking the database for.
  ///
  /// The same one-value-not-two shape as the customer and product lists, for the
  /// same reason (D-038). The search term is unused here in Phase 1 — the invoice
  /// list has no search field yet — but the window still exists, because the
  /// paging is what makes the list survive five thousand invoices, and that is
  /// needed on the first day rather than the day someone notices.
  InvoiceListQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoiceListQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoiceListQueryHash();

  @$internal
  @override
  InvoiceListQuery create() => InvoiceListQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListQuery>(value),
    );
  }
}

String _$invoiceListQueryHash() => r'906619579a240a1ea118848158cba018aa7f47a4';

/// The window the invoice list is currently asking the database for.
///
/// The same one-value-not-two shape as the customer and product lists, for the
/// same reason (D-038). The search term is unused here in Phase 1 — the invoice
/// list has no search field yet — but the window still exists, because the
/// paging is what makes the list survive five thousand invoices, and that is
/// needed on the first day rather than the day someone notices.

abstract class _$InvoiceListQuery extends $Notifier<ListQuery> {
  ListQuery build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ListQuery, ListQuery>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ListQuery, ListQuery>,
              ListQuery,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The invoice list, as a live query over the current window.
///
/// **The limit reaches SQL** (D-038), and the customer name is resolved by the
/// same query rather than by a lookup per row (D-040).

@ProviderFor(invoiceList)
final invoiceListProvider = InvoiceListProvider._();

/// The invoice list, as a live query over the current window.
///
/// **The limit reaches SQL** (D-038), and the customer name is resolved by the
/// same query rather than by a lookup per row (D-040).

final class InvoiceListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InvoiceListItem>>,
          List<InvoiceListItem>,
          Stream<List<InvoiceListItem>>
        >
    with
        $FutureModifier<List<InvoiceListItem>>,
        $StreamProvider<List<InvoiceListItem>> {
  /// The invoice list, as a live query over the current window.
  ///
  /// **The limit reaches SQL** (D-038), and the customer name is resolved by the
  /// same query rather than by a lookup per row (D-040).
  InvoiceListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoiceListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoiceListHash();

  @$internal
  @override
  $StreamProviderElement<List<InvoiceListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<InvoiceListItem>> create(Ref ref) {
    return invoiceList(ref);
  }
}

String _$invoiceListHash() => r'181e311f9992be47d8556c328f6238a8c7a7816b';
