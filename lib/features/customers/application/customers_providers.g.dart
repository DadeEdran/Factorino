// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customers_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The window the customer list is currently asking the database for.
///
/// Held as one value rather than as separate term and page providers, so that
/// starting a search resets the page window in the same state change — see
/// [ListQuery.searching]. Two providers would let the two drift apart for one
/// frame, and the symptom would be a search that quietly asks for two thousand
/// matches.

@ProviderFor(CustomerListQuery)
final customerListQueryProvider = CustomerListQueryProvider._();

/// The window the customer list is currently asking the database for.
///
/// Held as one value rather than as separate term and page providers, so that
/// starting a search resets the page window in the same state change — see
/// [ListQuery.searching]. Two providers would let the two drift apart for one
/// frame, and the symptom would be a search that quietly asks for two thousand
/// matches.
final class CustomerListQueryProvider
    extends $NotifierProvider<CustomerListQuery, ListQuery> {
  /// The window the customer list is currently asking the database for.
  ///
  /// Held as one value rather than as separate term and page providers, so that
  /// starting a search resets the page window in the same state change — see
  /// [ListQuery.searching]. Two providers would let the two drift apart for one
  /// frame, and the symptom would be a search that quietly asks for two thousand
  /// matches.
  CustomerListQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerListQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerListQueryHash();

  @$internal
  @override
  CustomerListQuery create() => CustomerListQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListQuery>(value),
    );
  }
}

String _$customerListQueryHash() => r'f74bb9216b02b49400267273ff79c759c426f509';

/// The window the customer list is currently asking the database for.
///
/// Held as one value rather than as separate term and page providers, so that
/// starting a search resets the page window in the same state change — see
/// [ListQuery.searching]. Two providers would let the two drift apart for one
/// frame, and the symptom would be a search that quietly asks for two thousand
/// matches.

abstract class _$CustomerListQuery extends $Notifier<ListQuery> {
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

/// The customer list, as a live query over the current window.
///
/// **The limit reaches SQL.** `watchAll` and `watchSearch` both take it
/// straight to the query, so growing the window is a wider `LIMIT` rather than
/// a longer list filtered in Dart (§13).
///
/// Auto-disposed: there is no reason to hold a query open while the customer
/// screen is not on screen (§3).

@ProviderFor(customerList)
final customerListProvider = CustomerListProvider._();

/// The customer list, as a live query over the current window.
///
/// **The limit reaches SQL.** `watchAll` and `watchSearch` both take it
/// straight to the query, so growing the window is a wider `LIMIT` rather than
/// a longer list filtered in Dart (§13).
///
/// Auto-disposed: there is no reason to hold a query open while the customer
/// screen is not on screen (§3).

final class CustomerListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Customer>>,
          List<Customer>,
          Stream<List<Customer>>
        >
    with $FutureModifier<List<Customer>>, $StreamProvider<List<Customer>> {
  /// The customer list, as a live query over the current window.
  ///
  /// **The limit reaches SQL.** `watchAll` and `watchSearch` both take it
  /// straight to the query, so growing the window is a wider `LIMIT` rather than
  /// a longer list filtered in Dart (§13).
  ///
  /// Auto-disposed: there is no reason to hold a query open while the customer
  /// screen is not on screen (§3).
  CustomerListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerListHash();

  @$internal
  @override
  $StreamProviderElement<List<Customer>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Customer>> create(Ref ref) {
    return customerList(ref);
  }
}

String _$customerListHash() => r'0c33ab060c8abc7b8362790c154fd0a05ec9d85c';

/// One customer, for the edit form.
///
/// A provider rather than an object handed through the route, so that opening
/// `/customers/<id>/edit` directly — a restored deep link, a typed Web URL —
/// loads the same screen as tapping the row does.

@ProviderFor(customerById)
final customerByIdProvider = CustomerByIdFamily._();

/// One customer, for the edit form.
///
/// A provider rather than an object handed through the route, so that opening
/// `/customers/<id>/edit` directly — a restored deep link, a typed Web URL —
/// loads the same screen as tapping the row does.

final class CustomerByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Customer?>,
          Customer?,
          FutureOr<Customer?>
        >
    with $FutureModifier<Customer?>, $FutureProvider<Customer?> {
  /// One customer, for the edit form.
  ///
  /// A provider rather than an object handed through the route, so that opening
  /// `/customers/<id>/edit` directly — a restored deep link, a typed Web URL —
  /// loads the same screen as tapping the row does.
  CustomerByIdProvider._({
    required CustomerByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customerByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerByIdHash();

  @override
  String toString() {
    return r'customerByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Customer?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Customer?> create(Ref ref) {
    final argument = this.argument as String;
    return customerById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerByIdHash() => r'56d8eb7c69f7b13bfaf85bc410979ab8a70bda44';

/// One customer, for the edit form.
///
/// A provider rather than an object handed through the route, so that opening
/// `/customers/<id>/edit` directly — a restored deep link, a typed Web URL —
/// loads the same screen as tapping the row does.

final class CustomerByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Customer?>, String> {
  CustomerByIdFamily._()
    : super(
        retry: null,
        name: r'customerByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One customer, for the edit form.
  ///
  /// A provider rather than an object handed through the route, so that opening
  /// `/customers/<id>/edit` directly — a restored deep link, a typed Web URL —
  /// loads the same screen as tapping the row does.

  CustomerByIdProvider call(String id) =>
      CustomerByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'customerByIdProvider';
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

@ProviderFor(CustomerEditor)
final customerEditorProvider = CustomerEditorProvider._();

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
final class CustomerEditorProvider
    extends $AsyncNotifierProvider<CustomerEditor, void> {
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
  CustomerEditorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerEditorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerEditorHash();

  @$internal
  @override
  CustomerEditor create() => CustomerEditor();
}

String _$customerEditorHash() => r'0c311a9a4af8d103e9ac0746950df32e1472a67b';

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

abstract class _$CustomerEditor extends $AsyncNotifier<void> {
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
