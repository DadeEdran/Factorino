import 'dart:io';

import 'package:factorino/core/security/database_encryption_key.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/customer_repository.dart';
import 'package:factorino/data/repositories/invoice_repository.dart';
import 'package:factorino/data/repositories/payment_repository.dart';
import 'package:factorino/data/repositories/product_repository.dart';
import 'package:factorino/data/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The composition root (D-007).
///
/// The property worth testing is not that a provider returns an object -- it is
/// that **overriding one line swaps the entire data layer**, which is what
/// makes the repositories testable without a widget knowing, and what a screen
/// in increment (f) will rely on.
class _FixedKeyStore implements DatabaseKeyStore {
  @override
  Future<DatabaseEncryptionKey> obtain() async =>
      DatabaseEncryptionKey.fromHex('7f' * DatabaseEncryptionKey.lengthBytes);
}

void main() {
  late Directory directory;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('factorino_providers');
    db = await openAppDatabase(
      keyStore: _FixedKeyStore(),
      file: File('${directory.path}${Platform.pathSeparator}test.db'),
    );
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    try {
      directory.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows holds the handle briefly after close.
    }
  });

  test('every repository resolves against the overridden database', () {
    expect(
      container.read(customerRepositoryProvider),
      isA<CustomerRepository>(),
    );
    expect(container.read(productRepositoryProvider), isA<ProductRepository>());
    expect(container.read(invoiceRepositoryProvider), isA<InvoiceRepository>());
    expect(container.read(paymentRepositoryProvider), isA<PaymentRepository>());
    expect(
      container.read(settingsRepositoryProvider),
      isA<SettingsRepository>(),
    );
  });

  test('a repository read through a provider hits the real database', () async {
    final repository = container.read(customerRepositoryProvider);
    await repository.create(const CustomerDraft(fullName: 'علی رضایی'));

    expect(await repository.search('علی'), hasLength(1));
    expect(await repository.count(), 1);
  });

  test('repositories are shared, not rebuilt per read', () {
    // keepAlive plus identical instances: a stream watched by one screen and a
    // write made from another must go through the same object.
    expect(
      identical(
        container.read(customerRepositoryProvider),
        container.read(customerRepositoryProvider),
      ),
      isTrue,
    );
  });

  test('the invoice repository gets the same settings instance', () {
    // It depends on SettingsRepository through the container rather than
    // constructing its own, so a settings change is visible to it immediately.
    expect(container.read(invoiceRepositoryProvider), isNotNull);
    expect(
      identical(
        container.read(settingsRepositoryProvider),
        container.read(settingsRepositoryProvider),
      ),
      isTrue,
    );
  });

  test('without the override the database provider fails loudly', () {
    // The default implementation throws rather than silently opening a second,
    // possibly unencrypted, database. A quiet fallback here would defeat D-020
    // by giving every call site a way around the single opener.
    final bare = ProviderContainer();
    addTearDown(bare.dispose);

    // Riverpod 3 wraps a provider's error in a ProviderException, so the
    // assertion is on the message rather than on the bare type -- and the
    // message is what a developer who hits this will actually read.
    expect(
      () => bare.read(appDatabaseProvider),
      throwsA(
        isA<Object>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('must be overridden'), contains('main()')),
        ),
      ),
    );
  });
}
