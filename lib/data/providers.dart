import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'backup/backup_file_gateway.dart';
import 'backup/backup_service.dart';
import 'database/app_database.dart';
import 'repositories/customer_repository.dart';
import 'repositories/drift/drift_customer_repository.dart';
import 'repositories/drift/drift_invoice_repository.dart';
import 'repositories/drift/drift_payment_repository.dart';
import 'repositories/drift/drift_product_repository.dart';
import 'repositories/drift/drift_settings_repository.dart';
import 'repositories/invoice_repository.dart';
import 'repositories/payment_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/settings_repository.dart';

part 'providers.g.dart';

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
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden with the database opened in main(). '
    'See lib/main.dart and D-020.',
  );
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    DriftSettingsRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
CustomerRepository customerRepository(Ref ref) =>
    DriftCustomerRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
ProductRepository productRepository(Ref ref) =>
    DriftProductRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
InvoiceRepository invoiceRepository(Ref ref) => DriftInvoiceRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(settingsRepositoryProvider),
);

@Riverpod(keepAlive: true)
PaymentRepository paymentRepository(Ref ref) =>
    DriftPaymentRepository(ref.watch(appDatabaseProvider));

/// Writes and reads encrypted backup containers (D-069).
///
/// Typed as the interface like every provider here, so a test can swap the
/// whole backup path for a fake without a widget knowing.
@Riverpod(keepAlive: true)
BackupService backupService(Ref ref) =>
    DriftBackupService(ref.watch(appDatabaseProvider));

/// Moves a finished backup between app-private storage and a location the user
/// chose (D-071).
///
/// Separate from [backupService] on purpose: this is the only thing in the
/// application that talks to a file picker, and `gateway_boundary_test.dart`
/// keeps it that way so replacing the dated `flutter_file_dialog` stays a
/// one-file change.
@Riverpod(keepAlive: true)
BackupFileGateway backupFileGateway(Ref ref) =>
    const PlatformBackupFileGateway();
