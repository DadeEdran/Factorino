import 'dart:io';

// drift exports SQL expression helpers named `isNull`/`isNotNull`; the
// matcher versions are what a test wants.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:factorino/core/security/database_encryption_key.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/soft_delete.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/models/payment_method.dart';
import 'package:factorino/data/models/product_type.dart';
import 'package:factorino/data/models/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Schema behaviour, against a real encrypted database opened through the
/// production bootstrap -- not an in-memory stand-in. Referential integrity,
/// cascades and CHECK constraints are properties of the actual file, and an
/// unencrypted in-memory database would not be exercising the path that ships.
class _FixedKeyStore implements DatabaseKeyStore {
  @override
  Future<DatabaseEncryptionKey> obtain() async =>
      DatabaseEncryptionKey.fromHex('7f' * DatabaseEncryptionKey.lengthBytes);
}

void main() {
  late Directory directory;
  late File file;
  late AppDatabase db;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('factorino_schema');
    file = File('${directory.path}${Platform.pathSeparator}test.db');
    db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
  });

  tearDown(() async {
    await db.close();
    try {
      directory.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows holds the handle briefly after close.
    }
  });

  Future<String> insertCustomer({String name = 'مشتری نمونه'}) async {
    final row = await db
        .into(db.customers)
        .insertReturning(CustomersCompanion.insert(fullName: name));
    return row.id;
  }

  Future<String> insertInvoice(
    String customerId, {
    String number = 'INV-1405-0001',
    int sequence = 1,
  }) async {
    final row = await db
        .into(db.invoices)
        .insertReturning(
          InvoicesCompanion.insert(
            // Explicit here even though a draft would normally carry none
            // (D-048): these tests are about the schema's constraints -- the
            // unique index and the cascades -- which need a real number to
            // have anything to be about.
            number: Value<String>(number),
            numberYear: const Value<int>(1405),
            numberSequence: Value<int>(sequence),
            customerId: customerId,
            issueDate: DateTime.utc(2026, 8, 23).millisecondsSinceEpoch,
            status: InvoiceStatus.draft,
          ),
        );
    return row.id;
  }

  group('startup', () {
    test('creates the schema and leaves an encrypted file on disk', () async {
      final tables = await db
          .customSelect(
            "select name from sqlite_master where type = 'table' "
            "and name not like 'sqlite_%'",
          )
          .get();
      final names = tables.map((r) => r.data['name'] as String).toSet();

      expect(
        names,
        containsAll(<String>[
          'customers',
          'products',
          'invoices',
          'invoice_items',
          'payments',
          'settings',
        ]),
      );

      // openAppDatabase asserts this itself; re-checked here so a regression
      // in the bootstrap ordering fails in a unit test, not only on device.
      final header = file.readAsBytesSync().take(15).toList();
      expect(String.fromCharCodes(header), isNot('SQLite format 3'));
    });

    test(
      'seeds exactly one settings row, with the declared defaults',
      () async {
        final rows = await db.select(db.settings).get();

        expect(rows, hasLength(1));
        expect(rows.single.defaultTaxRateBp, 1000); // 10%
        expect(rows.single.roundingUnitRial, 0); // disabled
        expect(rows.single.invoiceNumberPrefix, 'INV');
        expect(rows.single.devicePrefix, isNull);
        expect(rows.single.lastBackupAt, isNull);
      },
    );

    test('refuses a second settings row', () async {
      // The CHECK keeps the table single-row at the schema level, so no code
      // path can produce a second, quietly-ignored configuration.
      await expectLater(
        db
            .into(db.settings)
            .insert(SettingsCompanion.insert(singleton: const Value(2))),
        throwsA(anything),
      );
    });

    test('enables foreign keys on the connection', () async {
      final row = await db.customSelect('pragma foreign_keys').getSingle();
      expect(row.data.values.first, 1);
    });
  });

  group('sync-ready columns', () {
    test('assigns a UUID id and timestamps without being asked', () async {
      final before = DateTime.now().toUtc().millisecondsSinceEpoch;
      final id = await insertCustomer();
      final row = await (db.select(
        db.customers,
      )..where((t) => t.id.equals(id))).getSingle();

      expect(
        row.id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
            r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(row.createdAt, greaterThanOrEqualTo(before));
      expect(row.updatedAt, greaterThanOrEqualTo(before));
      expect(row.deletedAt, isNull);
      expect(row.syncStatus, SyncStatus.local);
      expect(row.lastSyncedAt, isNull);
    });
  });

  group('referential integrity', () {
    test('rejects an invoice item pointing at no invoice', () async {
      await expectLater(
        db
            .into(db.invoiceItems)
            .insert(
              InvoiceItemsCompanion.insert(
                invoiceId: 'does-not-exist',
                titleSnapshot: 'خدمات',
                unitSnapshot: 'ساعت',
                unitPriceRial: 1000000,
                quantityMilli: 1000,
                resolvedTaxRateBp: 1000,
              ),
            ),
        throwsA(anything),
      );
    });

    test('cascades a hard invoice delete to items and payments', () async {
      final customerId = await insertCustomer();
      final invoiceId = await insertInvoice(customerId);

      await db
          .into(db.invoiceItems)
          .insert(
            InvoiceItemsCompanion.insert(
              invoiceId: invoiceId,
              titleSnapshot: 'خدمات',
              unitSnapshot: 'ساعت',
              unitPriceRial: 1000000,
              quantityMilli: 1500,
              resolvedTaxRateBp: 1000,
            ),
          );
      await db
          .into(db.payments)
          .insert(
            PaymentsCompanion.insert(
              invoiceId: invoiceId,
              amountRial: 500000,
              paidAt: DateTime.utc(2026, 8, 23).millisecondsSinceEpoch,
              method: PaymentMethod.cash,
            ),
          );

      await (db.delete(db.invoices)..where((t) => t.id.equals(invoiceId))).go();

      expect(await db.select(db.invoiceItems).get(), isEmpty);
      expect(await db.select(db.payments).get(), isEmpty);
    });

    test('refuses to hard-delete a customer that has invoices', () async {
      // Customers referenced by an invoice are soft-deleted only (D-003). The
      // schema is what makes that a guarantee rather than a convention.
      final customerId = await insertCustomer();
      await insertInvoice(customerId);

      await expectLater(
        (db.delete(db.customers)..where((t) => t.id.equals(customerId))).go(),
        throwsA(anything),
      );
    });

    test('rejects a duplicate invoice number', () async {
      final customerId = await insertCustomer();
      await insertInvoice(customerId);

      await expectLater(
        insertInvoice(customerId, sequence: 2),
        throwsA(anything),
      );
    });

    test('keeps a soft-deleted invoice number spent', () async {
      // A number that has been issued must not be reusable: two documents
      // sharing one identity is a worse outcome than a gap in the sequence.
      final customerId = await insertCustomer();
      final invoiceId = await insertInvoice(customerId);

      await (db.update(
        db.invoices,
      )..where((t) => t.id.equals(invoiceId))).write(
        InvoicesCompanion(
          deletedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );

      await expectLater(
        insertInvoice(customerId, sequence: 2),
        throwsA(anything),
      );
    });
  });

  group('soft delete helper', () {
    test('selectAlive hides soft-deleted rows, select does not', () async {
      final keptId = await insertCustomer(name: 'باقی');
      final goneId = await insertCustomer(name: 'حذف شده');

      await (db.update(db.customers)..where((t) => t.id.equals(goneId))).write(
        CustomersCompanion(
          deletedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );

      final alive = await db.selectAlive(db.customers).get();
      final all = await db.select(db.customers).get();

      expect(alive.map((c) => c.id), <String>[keptId]);
      expect(all, hasLength(2));
    });

    test('countAlive aggregates in SQL', () async {
      await insertCustomer(name: 'یک');
      final goneId = await insertCustomer(name: 'دو');
      await (db.update(db.customers)..where((t) => t.id.equals(goneId))).write(
        CustomersCompanion(
          deletedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );

      expect(await db.countAlive(db.customers).getSingle(), 1);
    });

    test('works for every table in the database', () async {
      for (final table in db.allTables) {
        expect(
          () => aliveFilter(table),
          returnsNormally,
          reason: '${table.entityName} cannot be filtered by deleted_at',
        );
      }
    });
  });

  group('money and enum storage', () {
    test('stores Rial and basis points as integers', () async {
      final id = await db
          .into(db.products)
          .insertReturning(
            ProductsCompanion.insert(
              name: 'میز اداری',
              type: ProductType.product,
              priceRial: 125000000,
              unit: 'عدد',
            ),
          )
          .then((r) => r.id);

      final raw = await db
          .customSelect(
            'select price_rial, type from products where id = ?',
            variables: <Variable<Object>>[Variable<String>(id)],
          )
          .getSingle();

      expect(raw.data['price_rial'], isA<int>());
      expect(raw.data['price_rial'], 125000000);
      expect(raw.data['type'], ProductType.product.index);
    });
  });
}
