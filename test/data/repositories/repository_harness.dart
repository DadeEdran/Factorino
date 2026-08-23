import 'dart:io';

import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/security/database_encryption_key.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/invoice_draft.dart';
import 'package:factorino/data/models/product.dart';
import 'package:factorino/data/models/product_type.dart';
import 'package:factorino/data/repositories/drift/drift_customer_repository.dart';
import 'package:factorino/data/repositories/drift/drift_invoice_repository.dart';
import 'package:factorino/data/repositories/drift/drift_payment_repository.dart';
import 'package:factorino/data/repositories/drift/drift_product_repository.dart';
import 'package:factorino/data/repositories/drift/drift_settings_repository.dart';

/// Repository tests run against a **real encrypted database file** opened
/// through the production bootstrap, not an in-memory stand-in.
///
/// The things these tests are about -- transactions, the unique index on the
/// invoice number, cascades, `LIKE` against the stored bytes -- are properties
/// of the real file and of real SQLite. An in-memory unencrypted double would
/// exercise a different code path and could pass while the shipped one failed.
class _FixedKeyStore implements DatabaseKeyStore {
  @override
  Future<DatabaseEncryptionKey> obtain() async =>
      DatabaseEncryptionKey.fromHex('7f' * DatabaseEncryptionKey.lengthBytes);
}

/// Everything a repository test needs, wired the way the app wires it.
class RepositoryHarness {
  RepositoryHarness._(this._directory, this.db)
    : settings = DriftSettingsRepository(db),
      customers = DriftCustomerRepository(db),
      products = DriftProductRepository(db);

  static Future<RepositoryHarness> open() async {
    final directory = Directory.systemTemp.createTempSync('factorino_repo');
    final db = await openAppDatabase(
      keyStore: _FixedKeyStore(),
      file: File('${directory.path}${Platform.pathSeparator}test.db'),
    );
    return RepositoryHarness._(directory, db);
  }

  final Directory _directory;
  final AppDatabase db;

  final DriftSettingsRepository settings;
  final DriftCustomerRepository customers;
  final DriftProductRepository products;

  late final DriftInvoiceRepository invoices = DriftInvoiceRepository(
    db,
    settings,
  );
  late final DriftPaymentRepository payments = DriftPaymentRepository(db);

  Future<void> close() async {
    await db.close();
    try {
      _directory.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows holds the handle briefly after close.
    }
  }

  // ---- fixtures -----------------------------------------------------------

  Future<Customer> customer({String name = 'مشتری نمونه'}) {
    return customers.create(CustomerDraft(fullName: name));
  }

  Future<Product> product({
    String name = 'کالای نمونه',
    int priceRial = 1000000,
  }) {
    return products.create(
      ProductDraft(
        name: name,
        type: ProductType.product,
        price: Money.rial(priceRial),
        unit: 'عدد',
      ),
    );
  }

  /// A one-line invoice draft for [customerId], issued in Shahrivar 1405.
  InvoiceDraft draft(
    String customerId, {
    int unitPriceRial = 1000000,
    int quantityMilli = 1000,
    int discountRial = 0,
    int? taxRateBp,
    DateTime? issueDate,
  }) {
    return InvoiceDraft(
      customerId: customerId,
      issueDate: issueDate ?? DateTime.utc(2026, 8, 24, 12),
      taxRateBp: taxRateBp,
      items: <InvoiceItemDraft>[
        InvoiceItemDraft(
          title: 'خدمات',
          unit: 'عدد',
          unitPrice: Money.rial(unitPriceRial),
          quantityMilli: quantityMilli,
          discount: Money.rial(discountRial),
        ),
      ],
    );
  }
}
