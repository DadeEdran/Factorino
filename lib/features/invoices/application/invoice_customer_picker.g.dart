// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_customer_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The window the invoice form's customer picker is asking the database for.
///
/// Its own provider rather than `CustomerListQuery`, for the reason
/// `InvoiceProductPickerQuery` records: the customers screen may be sitting on
/// another destination with its own search and scroll position, and closing
/// this sheet must not leave that screen filtered by a term the user typed
/// here.

@ProviderFor(InvoiceCustomerPickerQuery)
final invoiceCustomerPickerQueryProvider =
    InvoiceCustomerPickerQueryProvider._();

/// The window the invoice form's customer picker is asking the database for.
///
/// Its own provider rather than `CustomerListQuery`, for the reason
/// `InvoiceProductPickerQuery` records: the customers screen may be sitting on
/// another destination with its own search and scroll position, and closing
/// this sheet must not leave that screen filtered by a term the user typed
/// here.
final class InvoiceCustomerPickerQueryProvider
    extends $NotifierProvider<InvoiceCustomerPickerQuery, ListQuery> {
  /// The window the invoice form's customer picker is asking the database for.
  ///
  /// Its own provider rather than `CustomerListQuery`, for the reason
  /// `InvoiceProductPickerQuery` records: the customers screen may be sitting on
  /// another destination with its own search and scroll position, and closing
  /// this sheet must not leave that screen filtered by a term the user typed
  /// here.
  InvoiceCustomerPickerQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoiceCustomerPickerQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoiceCustomerPickerQueryHash();

  @$internal
  @override
  InvoiceCustomerPickerQuery create() => InvoiceCustomerPickerQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListQuery>(value),
    );
  }
}

String _$invoiceCustomerPickerQueryHash() =>
    r'5c1154be7a559d9c750c7e67485ff4e2fc10908e';

/// The window the invoice form's customer picker is asking the database for.
///
/// Its own provider rather than `CustomerListQuery`, for the reason
/// `InvoiceProductPickerQuery` records: the customers screen may be sitting on
/// another destination with its own search and scroll position, and closing
/// this sheet must not leave that screen filtered by a term the user typed
/// here.

abstract class _$InvoiceCustomerPickerQuery extends $Notifier<ListQuery> {
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

/// The customer list, as the picker sees it.
///
/// **`watchSearch` is the normalization-insensitive search** (D-025, D-029),
/// not a second path built for this sheet: the repository folds the term
/// through `searchKey` — the same normalizer that wrote `search_name` — so a
/// customer saved as «علي» is found by typing «علی», and ZWNJ and diacritics
/// fold away on both sides. A picker that filtered a loaded list in Dart would
/// be a parallel implementation of that, and it would be the one that quietly
/// stopped matching.

@ProviderFor(invoiceCustomerPickerList)
final invoiceCustomerPickerListProvider = InvoiceCustomerPickerListProvider._();

/// The customer list, as the picker sees it.
///
/// **`watchSearch` is the normalization-insensitive search** (D-025, D-029),
/// not a second path built for this sheet: the repository folds the term
/// through `searchKey` — the same normalizer that wrote `search_name` — so a
/// customer saved as «علي» is found by typing «علی», and ZWNJ and diacritics
/// fold away on both sides. A picker that filtered a loaded list in Dart would
/// be a parallel implementation of that, and it would be the one that quietly
/// stopped matching.

final class InvoiceCustomerPickerListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Customer>>,
          List<Customer>,
          Stream<List<Customer>>
        >
    with $FutureModifier<List<Customer>>, $StreamProvider<List<Customer>> {
  /// The customer list, as the picker sees it.
  ///
  /// **`watchSearch` is the normalization-insensitive search** (D-025, D-029),
  /// not a second path built for this sheet: the repository folds the term
  /// through `searchKey` — the same normalizer that wrote `search_name` — so a
  /// customer saved as «علي» is found by typing «علی», and ZWNJ and diacritics
  /// fold away on both sides. A picker that filtered a loaded list in Dart would
  /// be a parallel implementation of that, and it would be the one that quietly
  /// stopped matching.
  InvoiceCustomerPickerListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoiceCustomerPickerListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoiceCustomerPickerListHash();

  @$internal
  @override
  $StreamProviderElement<List<Customer>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Customer>> create(Ref ref) {
    return invoiceCustomerPickerList(ref);
  }
}

String _$invoiceCustomerPickerListHash() =>
    r'97e2d901ca469aa613df2cdfcac611bb58987b00';
