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

@ProviderFor(customerDetail)
final customerDetailProvider = CustomerDetailFamily._();

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

final class CustomerDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<CustomerDetailView?>,
          CustomerDetailView?,
          FutureOr<CustomerDetailView?>
        >
    with
        $FutureModifier<CustomerDetailView?>,
        $FutureProvider<CustomerDetailView?> {
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
  CustomerDetailProvider._({
    required CustomerDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customerDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerDetailHash();

  @override
  String toString() {
    return r'customerDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CustomerDetailView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CustomerDetailView?> create(Ref ref) {
    final argument = this.argument as String;
    return customerDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerDetailHash() => r'c746d01b84ca4c4d3826bf4a509fefdc7582c9ff';

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

final class CustomerDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CustomerDetailView?>, String> {
  CustomerDetailFamily._()
    : super(
        retry: null,
        name: r'customerDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

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

  CustomerDetailProvider call(String id) =>
      CustomerDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'customerDetailProvider';
}

/// The two figures, as one live SQL aggregate.
///
/// Private, like the dashboard's: a widget that watched this on its own could
/// render a balance from a different moment than the list beside it, which is
/// what [CustomerDetailView] exists to prevent.

@ProviderFor(_customerTotals)
final _customerTotalsProvider = _CustomerTotalsFamily._();

/// The two figures, as one live SQL aggregate.
///
/// Private, like the dashboard's: a widget that watched this on its own could
/// render a balance from a different moment than the list beside it, which is
/// what [CustomerDetailView] exists to prevent.

final class _CustomerTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CustomerTotals>,
          CustomerTotals,
          Stream<CustomerTotals>
        >
    with $FutureModifier<CustomerTotals>, $StreamProvider<CustomerTotals> {
  /// The two figures, as one live SQL aggregate.
  ///
  /// Private, like the dashboard's: a widget that watched this on its own could
  /// render a balance from a different moment than the list beside it, which is
  /// what [CustomerDetailView] exists to prevent.
  _CustomerTotalsProvider._({
    required _CustomerTotalsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'_customerTotalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_customerTotalsHash();

  @override
  String toString() {
    return r'_customerTotalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<CustomerTotals> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<CustomerTotals> create(Ref ref) {
    final argument = this.argument as String;
    return _customerTotals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is _CustomerTotalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_customerTotalsHash() => r'3d61c63ce0e8cbe4d28997939d4aea0d6fc96b8d';

/// The two figures, as one live SQL aggregate.
///
/// Private, like the dashboard's: a widget that watched this on its own could
/// render a balance from a different moment than the list beside it, which is
/// what [CustomerDetailView] exists to prevent.

final class _CustomerTotalsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<CustomerTotals>, String> {
  _CustomerTotalsFamily._()
    : super(
        retry: null,
        name: r'_customerTotalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The two figures, as one live SQL aggregate.
  ///
  /// Private, like the dashboard's: a widget that watched this on its own could
  /// render a balance from a different moment than the list beside it, which is
  /// what [CustomerDetailView] exists to prevent.

  _CustomerTotalsProvider call(String id) =>
      _CustomerTotalsProvider._(argument: id, from: this);

  @override
  String toString() => r'_customerTotalsProvider';
}

/// This customer's invoices.
///
/// `watchForCustomer` was built in increment (d) for this screen and had no
/// call site until now. Using it rather than adding a parallel read is
/// deliberate: a second query answering the same question is a second place for
/// the soft-delete filter and the ordering to be got wrong.

@ProviderFor(_customerInvoices)
final _customerInvoicesProvider = _CustomerInvoicesFamily._();

/// This customer's invoices.
///
/// `watchForCustomer` was built in increment (d) for this screen and had no
/// call site until now. Using it rather than adding a parallel read is
/// deliberate: a second query answering the same question is a second place for
/// the soft-delete filter and the ordering to be got wrong.

final class _CustomerInvoicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Invoice>>,
          List<Invoice>,
          Stream<List<Invoice>>
        >
    with $FutureModifier<List<Invoice>>, $StreamProvider<List<Invoice>> {
  /// This customer's invoices.
  ///
  /// `watchForCustomer` was built in increment (d) for this screen and had no
  /// call site until now. Using it rather than adding a parallel read is
  /// deliberate: a second query answering the same question is a second place for
  /// the soft-delete filter and the ordering to be got wrong.
  _CustomerInvoicesProvider._({
    required _CustomerInvoicesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'_customerInvoicesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_customerInvoicesHash();

  @override
  String toString() {
    return r'_customerInvoicesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Invoice>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Invoice>> create(Ref ref) {
    final argument = this.argument as String;
    return _customerInvoices(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is _CustomerInvoicesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_customerInvoicesHash() => r'b3f1ed70e7769384ea7c3d82471215cb37ad94e9';

/// This customer's invoices.
///
/// `watchForCustomer` was built in increment (d) for this screen and had no
/// call site until now. Using it rather than adding a parallel read is
/// deliberate: a second query answering the same question is a second place for
/// the soft-delete filter and the ordering to be got wrong.

final class _CustomerInvoicesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Invoice>>, String> {
  _CustomerInvoicesFamily._()
    : super(
        retry: null,
        name: r'_customerInvoicesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// This customer's invoices.
  ///
  /// `watchForCustomer` was built in increment (d) for this screen and had no
  /// call site until now. Using it rather than adding a parallel read is
  /// deliberate: a second query answering the same question is a second place for
  /// the soft-delete filter and the ordering to be got wrong.

  _CustomerInvoicesProvider call(String id) =>
      _CustomerInvoicesProvider._(argument: id, from: this);

  @override
  String toString() => r'_customerInvoicesProvider';
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

String _$customerEditorHash() => r'cc0099cfb836143a95a61c4238dd42ad4dc23da8';

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
