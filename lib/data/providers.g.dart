// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The data layer's composition root: the one place that decides which
/// implementation of each repository the application runs on (D-007).
///
/// **Every provider here is typed as the interface, never the implementation.**
/// A widget or controller that watches `customerRepositoryProvider` gets a
/// [CustomerRepository] and cannot reach a drift type through it, which is the
/// same boundary `domain_boundary_test.dart` enforces on the signatures --
/// held here at the wiring instead.
///
/// This file lives outside `repositories/` on purpose. It has to import both
/// the interfaces and the drift implementations, and the guard test requires
/// that nothing directly in `repositories/` can see drift at all.
/// The open database, supplied at startup.
///
/// Deliberately **not** an async provider. Opening the database is a
/// fail-loud, must-succeed step (D-020): if it fails, the app has no business
/// rendering a partially-working UI while a `FutureProvider` resolves. So
/// `main` opens it first and overrides this provider with the result, and every
/// dependent provider is plainly synchronous.
///
/// The same override is what lets a test run the entire data layer against a
/// temporary encrypted file with no widget knowing the difference.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// The data layer's composition root: the one place that decides which
/// implementation of each repository the application runs on (D-007).
///
/// **Every provider here is typed as the interface, never the implementation.**
/// A widget or controller that watches `customerRepositoryProvider` gets a
/// [CustomerRepository] and cannot reach a drift type through it, which is the
/// same boundary `domain_boundary_test.dart` enforces on the signatures --
/// held here at the wiring instead.
///
/// This file lives outside `repositories/` on purpose. It has to import both
/// the interfaces and the drift implementations, and the guard test requires
/// that nothing directly in `repositories/` can see drift at all.
/// The open database, supplied at startup.
///
/// Deliberately **not** an async provider. Opening the database is a
/// fail-loud, must-succeed step (D-020): if it fails, the app has no business
/// rendering a partially-working UI while a `FutureProvider` resolves. So
/// `main` opens it first and overrides this provider with the result, and every
/// dependent provider is plainly synchronous.
///
/// The same override is what lets a test run the entire data layer against a
/// temporary encrypted file with no widget knowing the difference.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// The data layer's composition root: the one place that decides which
  /// implementation of each repository the application runs on (D-007).
  ///
  /// **Every provider here is typed as the interface, never the implementation.**
  /// A widget or controller that watches `customerRepositoryProvider` gets a
  /// [CustomerRepository] and cannot reach a drift type through it, which is the
  /// same boundary `domain_boundary_test.dart` enforces on the signatures --
  /// held here at the wiring instead.
  ///
  /// This file lives outside `repositories/` on purpose. It has to import both
  /// the interfaces and the drift implementations, and the guard test requires
  /// that nothing directly in `repositories/` can see drift at all.
  /// The open database, supplied at startup.
  ///
  /// Deliberately **not** an async provider. Opening the database is a
  /// fail-loud, must-succeed step (D-020): if it fails, the app has no business
  /// rendering a partially-working UI while a `FutureProvider` resolves. So
  /// `main` opens it first and overrides this provider with the result, and every
  /// dependent provider is plainly synchronous.
  ///
  /// The same override is what lets a test run the entire data layer against a
  /// temporary encrypted file with no widget knowing the difference.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'3de01ec47d091aa62ea722a06fbdafecf2170df8';

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'0eda22c9c7a5e68c8661bf58b528d73264ef9a19';

@ProviderFor(customerRepository)
final customerRepositoryProvider = CustomerRepositoryProvider._();

final class CustomerRepositoryProvider
    extends
        $FunctionalProvider<
          CustomerRepository,
          CustomerRepository,
          CustomerRepository
        >
    with $Provider<CustomerRepository> {
  CustomerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerRepositoryHash();

  @$internal
  @override
  $ProviderElement<CustomerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CustomerRepository create(Ref ref) {
    return customerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomerRepository>(value),
    );
  }
}

String _$customerRepositoryHash() =>
    r'a6a735b473f5fa03b4a1793b2e61c11945dbfe88';

@ProviderFor(productRepository)
final productRepositoryProvider = ProductRepositoryProvider._();

final class ProductRepositoryProvider
    extends
        $FunctionalProvider<
          ProductRepository,
          ProductRepository,
          ProductRepository
        >
    with $Provider<ProductRepository> {
  ProductRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProductRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductRepository create(Ref ref) {
    return productRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductRepository>(value),
    );
  }
}

String _$productRepositoryHash() => r'0f6b0819da4efe4066045b0593d230f235fc35d3';

@ProviderFor(invoiceRepository)
final invoiceRepositoryProvider = InvoiceRepositoryProvider._();

final class InvoiceRepositoryProvider
    extends
        $FunctionalProvider<
          InvoiceRepository,
          InvoiceRepository,
          InvoiceRepository
        >
    with $Provider<InvoiceRepository> {
  InvoiceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoiceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoiceRepositoryHash();

  @$internal
  @override
  $ProviderElement<InvoiceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InvoiceRepository create(Ref ref) {
    return invoiceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InvoiceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InvoiceRepository>(value),
    );
  }
}

String _$invoiceRepositoryHash() => r'90868b158456e33f805c30f24154d607d022d67a';

@ProviderFor(paymentRepository)
final paymentRepositoryProvider = PaymentRepositoryProvider._();

final class PaymentRepositoryProvider
    extends
        $FunctionalProvider<
          PaymentRepository,
          PaymentRepository,
          PaymentRepository
        >
    with $Provider<PaymentRepository> {
  PaymentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentRepositoryHash();

  @$internal
  @override
  $ProviderElement<PaymentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PaymentRepository create(Ref ref) {
    return paymentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentRepository>(value),
    );
  }
}

String _$paymentRepositoryHash() => r'1251d4490008bdd5f07505e19df928b26f0e0089';
