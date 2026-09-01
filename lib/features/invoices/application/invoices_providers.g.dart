// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoices_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The window **and the filter** the invoice list is currently asking the
/// database for.
///
/// The same one-value-not-two shape as the customer and product lists, for the
/// same reason (D-038) — and since Phase 5 (e) it carries the filter too, so
/// that narrowing the list resets the window rather than asking the database
/// for eight pages of a set the user has just made smaller. See [InvoiceQuery].

@ProviderFor(InvoiceListQuery)
final invoiceListQueryProvider = InvoiceListQueryProvider._();

/// The window **and the filter** the invoice list is currently asking the
/// database for.
///
/// The same one-value-not-two shape as the customer and product lists, for the
/// same reason (D-038) — and since Phase 5 (e) it carries the filter too, so
/// that narrowing the list resets the window rather than asking the database
/// for eight pages of a set the user has just made smaller. See [InvoiceQuery].
final class InvoiceListQueryProvider
    extends $NotifierProvider<InvoiceListQuery, InvoiceQuery> {
  /// The window **and the filter** the invoice list is currently asking the
  /// database for.
  ///
  /// The same one-value-not-two shape as the customer and product lists, for the
  /// same reason (D-038) — and since Phase 5 (e) it carries the filter too, so
  /// that narrowing the list resets the window rather than asking the database
  /// for eight pages of a set the user has just made smaller. See [InvoiceQuery].
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
  Override overrideWithValue(InvoiceQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InvoiceQuery>(value),
    );
  }
}

String _$invoiceListQueryHash() => r'a3535141b0429465903e0e06f8c0dca414562dd8';

/// The window **and the filter** the invoice list is currently asking the
/// database for.
///
/// The same one-value-not-two shape as the customer and product lists, for the
/// same reason (D-038) — and since Phase 5 (e) it carries the filter too, so
/// that narrowing the list resets the window rather than asking the database
/// for eight pages of a set the user has just made smaller. See [InvoiceQuery].

abstract class _$InvoiceListQuery extends $Notifier<InvoiceQuery> {
  InvoiceQuery build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<InvoiceQuery, InvoiceQuery>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InvoiceQuery, InvoiceQuery>,
              InvoiceQuery,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
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

@ProviderFor(invoiceList)
final invoiceListProvider = InvoiceListProvider._();

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

String _$invoiceListHash() => r'e5c7079eb8a96b347a7452f78090caec4f190c5c';

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

@ProviderFor(invoiceDetail)
final invoiceDetailProvider = InvoiceDetailFamily._();

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

final class InvoiceDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<InvoiceDetail?>,
          InvoiceDetail?,
          Stream<InvoiceDetail?>
        >
    with $FutureModifier<InvoiceDetail?>, $StreamProvider<InvoiceDetail?> {
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
  InvoiceDetailProvider._({
    required InvoiceDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'invoiceDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$invoiceDetailHash();

  @override
  String toString() {
    return r'invoiceDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<InvoiceDetail?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<InvoiceDetail?> create(Ref ref) {
    final argument = this.argument as String;
    return invoiceDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InvoiceDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$invoiceDetailHash() => r'3fcc7de3d6573d7138cc8b7d0285dc77b8d885a6';

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

final class InvoiceDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<InvoiceDetail?>, String> {
  InvoiceDetailFamily._()
    : super(
        retry: null,
        name: r'invoiceDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

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

  InvoiceDetailProvider call(String id) =>
      InvoiceDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'invoiceDetailProvider';
}
