// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'products_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The window the product list is currently asking the database for.
///
/// The same shape as `CustomerListQuery`, and deliberately a separate provider
/// rather than a shared one: the two lists are on different destinations, each
/// keeps its own scroll position and its own search, and a shared window would
/// reset one when the user searched the other.

@ProviderFor(ProductListQuery)
final productListQueryProvider = ProductListQueryProvider._();

/// The window the product list is currently asking the database for.
///
/// The same shape as `CustomerListQuery`, and deliberately a separate provider
/// rather than a shared one: the two lists are on different destinations, each
/// keeps its own scroll position and its own search, and a shared window would
/// reset one when the user searched the other.
final class ProductListQueryProvider
    extends $NotifierProvider<ProductListQuery, ListQuery> {
  /// The window the product list is currently asking the database for.
  ///
  /// The same shape as `CustomerListQuery`, and deliberately a separate provider
  /// rather than a shared one: the two lists are on different destinations, each
  /// keeps its own scroll position and its own search, and a shared window would
  /// reset one when the user searched the other.
  ProductListQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productListQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productListQueryHash();

  @$internal
  @override
  ProductListQuery create() => ProductListQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListQuery>(value),
    );
  }
}

String _$productListQueryHash() => r'21aabab38fc004018dd8b22e41846c5a06169848';

/// The window the product list is currently asking the database for.
///
/// The same shape as `CustomerListQuery`, and deliberately a separate provider
/// rather than a shared one: the two lists are on different destinations, each
/// keeps its own scroll position and its own search, and a shared window would
/// reset one when the user searched the other.

abstract class _$ProductListQuery extends $Notifier<ListQuery> {
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

/// The product list, as a live query over the current window.

@ProviderFor(productList)
final productListProvider = ProductListProvider._();

/// The product list, as a live query over the current window.

final class ProductListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Product>>,
          List<Product>,
          Stream<List<Product>>
        >
    with $FutureModifier<List<Product>>, $StreamProvider<List<Product>> {
  /// The product list, as a live query over the current window.
  ProductListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productListHash();

  @$internal
  @override
  $StreamProviderElement<List<Product>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Product>> create(Ref ref) {
    return productList(ref);
  }
}

String _$productListHash() => r'c9eadb2732adb923fa83c0c41ea5b506ba18c536';

/// One product, for the edit form.

@ProviderFor(productById)
final productByIdProvider = ProductByIdFamily._();

/// One product, for the edit form.

final class ProductByIdProvider
    extends
        $FunctionalProvider<AsyncValue<Product?>, Product?, FutureOr<Product?>>
    with $FutureModifier<Product?>, $FutureProvider<Product?> {
  /// One product, for the edit form.
  ProductByIdProvider._({
    required ProductByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productByIdHash();

  @override
  String toString() {
    return r'productByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Product?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Product?> create(Ref ref) {
    final argument = this.argument as String;
    return productById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productByIdHash() => r'0676d184e8f7c93e5dd99c0ff5151786dcf8a13b';

/// One product, for the edit form.

final class ProductByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Product?>, String> {
  ProductByIdFamily._()
    : super(
        retry: null,
        name: r'productByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One product, for the edit form.

  ProductByIdProvider call(String id) =>
      ProductByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'productByIdProvider';
}

/// The product write path.
///
/// The customer editor's twin, and it exists for the same reason: a widget
/// never calls a repository (`ARCHITECTURE.md` §B.1), and the logging rule from
/// §7 is held in one place rather than in every form.

@ProviderFor(ProductEditor)
final productEditorProvider = ProductEditorProvider._();

/// The product write path.
///
/// The customer editor's twin, and it exists for the same reason: a widget
/// never calls a repository (`ARCHITECTURE.md` §B.1), and the logging rule from
/// §7 is held in one place rather than in every form.
final class ProductEditorProvider
    extends $AsyncNotifierProvider<ProductEditor, void> {
  /// The product write path.
  ///
  /// The customer editor's twin, and it exists for the same reason: a widget
  /// never calls a repository (`ARCHITECTURE.md` §B.1), and the logging rule from
  /// §7 is held in one place rather than in every form.
  ProductEditorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productEditorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productEditorHash();

  @$internal
  @override
  ProductEditor create() => ProductEditor();
}

String _$productEditorHash() => r'939537a43550f91d543ed2b0d763f89d060e5219';

/// The product write path.
///
/// The customer editor's twin, and it exists for the same reason: a widget
/// never calls a repository (`ARCHITECTURE.md` §B.1), and the logging rule from
/// §7 is held in one place rather than in every form.

abstract class _$ProductEditor extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
