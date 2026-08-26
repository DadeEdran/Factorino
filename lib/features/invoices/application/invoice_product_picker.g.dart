// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_product_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(InvoiceProductPickerQuery)
final invoiceProductPickerQueryProvider = InvoiceProductPickerQueryProvider._();

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
final class InvoiceProductPickerQueryProvider
    extends $NotifierProvider<InvoiceProductPickerQuery, ListQuery> {
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
  InvoiceProductPickerQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoiceProductPickerQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoiceProductPickerQueryHash();

  @$internal
  @override
  InvoiceProductPickerQuery create() => InvoiceProductPickerQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListQuery>(value),
    );
  }
}

String _$invoiceProductPickerQueryHash() =>
    r'ee19179c41ee9b448c8c06e1bf986ddf0c253b97';

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

abstract class _$InvoiceProductPickerQuery extends $Notifier<ListQuery> {
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

/// The catalogue, as the picker sees it.
///
/// A live query like every other list (§13): the limit reaches SQL rather than
/// being applied after loading everything. Auto-disposed with the sheet, so
/// the next invoice opens a picker with no search term left in it.

@ProviderFor(invoiceProductPickerList)
final invoiceProductPickerListProvider = InvoiceProductPickerListProvider._();

/// The catalogue, as the picker sees it.
///
/// A live query like every other list (§13): the limit reaches SQL rather than
/// being applied after loading everything. Auto-disposed with the sheet, so
/// the next invoice opens a picker with no search term left in it.

final class InvoiceProductPickerListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Product>>,
          List<Product>,
          Stream<List<Product>>
        >
    with $FutureModifier<List<Product>>, $StreamProvider<List<Product>> {
  /// The catalogue, as the picker sees it.
  ///
  /// A live query like every other list (§13): the limit reaches SQL rather than
  /// being applied after loading everything. Auto-disposed with the sheet, so
  /// the next invoice opens a picker with no search term left in it.
  InvoiceProductPickerListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoiceProductPickerListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoiceProductPickerListHash();

  @$internal
  @override
  $StreamProviderElement<List<Product>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Product>> create(Ref ref) {
    return invoiceProductPickerList(ref);
  }
}

String _$invoiceProductPickerListHash() =>
    r'8303c3d2cce7477b83314d7c500b151d51881c92';
