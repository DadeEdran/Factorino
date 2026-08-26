import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:factorino/core/security/database_encryption_key.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;

/// The project's first schema migration (D-048): `invoices.number`,
/// `number_year` and `number_sequence` become nullable so a draft can exist
/// without consuming an invoice number.
///
/// Two different claims are checked here, and neither implies the other:
///
/// * **The shape is right.** `SchemaVerifier` migrates a v1 database and
///   compares the result against the declared v2 schema. This is drift's own
///   generated-migration machinery and it runs on an
///   unencrypted in-memory database, because that is all it can do.
/// * **The data survives.** A v1 database holding invoices, their lines and
///   their payments is migrated through the **real production path** -- a real
///   encrypted file, opened by `openAppDatabase`, with foreign keys on -- and
///   every row is counted afterwards.
///
/// The second is the one that would have caught the failure worth fearing.
/// Step 6 of SQLite's table rebuild is `DROP TABLE invoices`, and with foreign
/// keys enabled that cascades into `invoice_items` and `payments`: a migration
/// that "succeeds", produces exactly the right schema, and silently takes
/// every line and every payment in the database with it. A schema comparison
/// cannot see that, and `SchemaVerifier.testWithDataIntegrity` cannot either --
/// it documents that it disables foreign keys, which is precisely the
/// condition under which the bug does not reproduce.
void main() {
  group('the migrated schema is the declared v2 schema', () {
    late SchemaVerifier verifier;

    setUpAll(() {
      // `setup` runs on every connection the verifier opens. Foreign keys are
      // enabled here because the application's opener does it (D-017, D-020)
      // and `beforeOpen` asserts it took effect -- without this the migration
      // refuses to run at all, which is the assertion working. It also means
      // the schema comparison runs under the same foreign-key conditions the
      // real migration does, rather than a laxer set.
      verifier = SchemaVerifier(
        GeneratedHelper(),
        setup: (raw) => raw.execute('PRAGMA foreign_keys = ON;'),
      );
    });

    test('v1 upgrades to v2', () async {
      final connection = await verifier.startAt(1);
      final db = AppDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 2);
    });
  });

  group('a v1 database survives the upgrade, through the production path', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('factorino_migration');
      file = File('${directory.path}${Platform.pathSeparator}test.db');
    });

    tearDown(() {
      try {
        directory.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows holds the handle briefly after close.
      }
    });

    /// Builds a **v1** database in [file], through the same encrypted opener
    /// the application uses, and fills it with the rows a real one would hold.
    Future<void> seedV1() async {
      final db = v1.DatabaseAtV1(
        openEncryptedDatabase(file: file, key: _fixedKey),
      );

      await db.batch((Batch batch) {
        batch.insert(
          db.settings,
          v1.SettingsCompanion.insert(
            id: 'settings',
            createdAt: _t,
            updatedAt: _t,
          ),
        );
        batch.insert(
          db.customers,
          v1.CustomersCompanion.insert(
            id: 'customer-1',
            createdAt: _t,
            updatedAt: _t,
            fullName: 'مشتری نمونه',
          ),
        );
        batch.insert(
          db.products,
          v1.ProductsCompanion.insert(
            id: 'product-1',
            createdAt: _t,
            updatedAt: _t,
            name: 'خدمات',
            type: 0,
            priceRial: 1000000,
            unit: 'عدد',
          ),
        );

        // An issued invoice with two lines and two payments, and -- the shape
        // D-048 exists to stop -- a *draft* that already burned a number,
        // because in v1 every invoice got one at creation.
        batch.insertAll(db.invoices, <v1.InvoicesCompanion>[
          v1.InvoicesCompanion.insert(
            id: 'invoice-issued',
            createdAt: _t,
            updatedAt: _t,
            number: 'INV-1405-0001',
            numberYear: 1405,
            numberSequence: 1,
            customerId: 'customer-1',
            issueDate: _t,
            status: InvoiceStatus.partiallyPaid.index,
            grandTotalRial: const Value<int>(21230000),
          ),
          v1.InvoicesCompanion.insert(
            id: 'invoice-draft',
            createdAt: _t,
            updatedAt: _t,
            number: 'INV-1405-0002',
            numberYear: 1405,
            numberSequence: 2,
            customerId: 'customer-1',
            issueDate: _t,
            status: InvoiceStatus.draft.index,
            grandTotalRial: const Value<int>(55000000),
          ),
        ]);

        batch.insertAll(db.invoiceItems, <v1.InvoiceItemsCompanion>[
          v1.InvoiceItemsCompanion.insert(
            id: 'item-1',
            createdAt: _t,
            updatedAt: _t,
            invoiceId: 'invoice-issued',
            titleSnapshot: 'خدمات',
            unitSnapshot: 'عدد',
            unitPriceRial: 1000000,
            quantityMilli: 1000,
            resolvedTaxRateBp: 1000,
          ),
          v1.InvoiceItemsCompanion.insert(
            id: 'item-2',
            createdAt: _t,
            updatedAt: _t,
            invoiceId: 'invoice-issued',
            titleSnapshot: 'حمل و نقل',
            unitSnapshot: 'عدد',
            unitPriceRial: 500000,
            quantityMilli: 2000,
            resolvedTaxRateBp: 1000,
          ),
          v1.InvoiceItemsCompanion.insert(
            id: 'item-3',
            createdAt: _t,
            updatedAt: _t,
            invoiceId: 'invoice-draft',
            titleSnapshot: 'مشاوره',
            unitSnapshot: 'ساعت',
            unitPriceRial: 5000000,
            quantityMilli: 10000,
            resolvedTaxRateBp: 1000,
          ),
        ]);

        batch.insertAll(db.payments, <v1.PaymentsCompanion>[
          v1.PaymentsCompanion.insert(
            id: 'payment-1',
            createdAt: _t,
            updatedAt: _t,
            invoiceId: 'invoice-issued',
            amountRial: 4000000,
            paidAt: _t,
            method: 0,
          ),
          v1.PaymentsCompanion.insert(
            id: 'payment-2',
            createdAt: _t,
            updatedAt: _t,
            invoiceId: 'invoice-issued',
            amountRial: 2000000,
            paidAt: _t,
            method: 0,
          ),
        ]);
      });

      // The version the file records is what makes the reopen an *upgrade*
      // rather than a create. `DatabaseAtV1` writes it on first open.
      expect(await _userVersion(db), 1);
      await db.close();
    }

    test('every row survives, and the lines and payments most of all', () async {
      await seedV1();

      // The production bootstrap: real key, real cipher pragmas, foreign keys
      // on, migration run on open, encrypted-header assertion at the end.
      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      expect(await _count(db, 'customers'), 1);
      expect(await _count(db, 'products'), 1);
      expect(await _count(db, 'invoices'), 2);

      // The cascade check. `DROP TABLE invoices` with foreign keys enabled
      // would have emptied both of these and reported nothing at all.
      expect(
        await _count(db, 'invoice_items'),
        3,
        reason:
            'the table rebuild dropped `invoices`; if foreign keys were on, '
            'ON DELETE CASCADE took every line with it (D-048)',
      );
      expect(
        await _count(db, 'payments'),
        2,
        reason: 'the payment history is cascade-deleted by the same route',
      );

      // Settings is a single row behind a CHECK constraint; losing it would
      // make every read path handle "configuration missing" for the first time.
      expect(await _count(db, 'settings'), 1);
    });

    test('every invoice keeps the number it was issued with', () async {
      await seedV1();

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      // soft-delete-exempt: a migration assertion over every row, including
      // any that were deleted -- their numbers are spent too (D-013).
      final rows = await db.select(db.invoices).get();
      final byId = <String, InvoiceRow>{
        for (final InvoiceRow row in rows) row.id: row,
      };

      expect(byId['invoice-issued']!.number, 'INV-1405-0001');
      expect(byId['invoice-issued']!.numberYear, 1405);
      expect(byId['invoice-issued']!.numberSequence, 1);
      expect(byId['invoice-issued']!.grandTotalRial, 21230000);

      // A draft that already has a number keeps it. The migration does not go
      // back and free numbers already spent: the gap is in the past, and
      // rewriting a document's identity is worse than a gap (D-013).
      expect(byId['invoice-draft']!.number, 'INV-1405-0002');
      expect(byId['invoice-draft']!.numberSequence, 2);
    });

    test('the migration leaves foreign keys on and the version at 2', () async {
      await seedV1();

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      // `alterTable` turns foreign keys off for the rebuild and back on after.
      // If the restore were ever missed, integrity would be off for the rest
      // of the session with nothing to indicate it -- so this is asserted on
      // the connection the application goes on to use, not on a fresh one.
      // soft-delete-exempt: a connection pragma, not a read of user rows.
      final fk = await db.customSelect('pragma foreign_keys').getSingle();
      expect(fk.data.values.first, 1);

      expect(await _userVersion(db), 2);
    });
  });

  group('what nullable numbers make possible (D-048)', () {
    late Directory directory;
    late AppDatabase db;

    setUp(() async {
      directory = Directory.systemTemp.createTempSync('factorino_nulls');
      db = await openAppDatabase(
        keyStore: _FixedKeyStore(),
        file: File('${directory.path}${Platform.pathSeparator}test.db'),
      );
      await db
.into(db.customers)
.insert(
            CustomersCompanion.insert(
              id: const Value<String>('c1'),
              fullName: 'مشتری',
            ),
          );
    });

    tearDown(() async {
      await db.close();
      try {
        directory.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows holds the handle briefly after close.
      }
    });

    test('two numberless drafts can coexist', () async {
      // This is the entire reason the columns are nullable rather than
      // carrying an empty-string sentinel: SQLite's unique index treats `''`
      // as equal to `''` and would reject the second draft, while **NULLs are
      // distinct** in a unique index.
      for (var i = 0; i < 2; i++) {
        await db
.into(db.invoices)
.insert(
              InvoicesCompanion.insert(
                customerId: 'c1',
                issueDate: _t,
                status: InvoiceStatus.draft,
              ),
            );
      }

      expect(await _count(db, 'invoices'), 2);
    });

    test('a duplicate real number is still refused', () async {
      Future<void> insertNumbered() => db
.into(db.invoices)
.insert(
            InvoicesCompanion.insert(
              number: const Value<String>('INV-1405-0001'),
              numberYear: const Value<int>(1405),
              numberSequence: const Value<int>(1),
              customerId: 'c1',
              issueDate: _t,
              status: InvoiceStatus.unpaid,
            ),
          );

      await insertNumbered();

      // Making the column nullable must not have weakened the guarantee that
      // matters: two documents may never share one identity (D-013).
      await expectLater(insertNumbered(), throwsA(isA<Exception>()));
    });
  });
}

/// 2026-08-24T12:00Z, the instant the repository fixtures use.
final int _t = DateTime.utc(2026, 8, 24, 12).millisecondsSinceEpoch;

final DatabaseEncryptionKey _fixedKey = DatabaseEncryptionKey.fromHex(
  '7f' * DatabaseEncryptionKey.lengthBytes,
);

class _FixedKeyStore implements DatabaseKeyStore {
  @override
  Future<DatabaseEncryptionKey> obtain() async => _fixedKey;
}

// soft-delete-exempt: counts every row on purpose. A migration that dropped
// soft-deleted rows would be data loss, so the filter would hide the failure.
Future<int> _count(GeneratedDatabase db, String table) async {
  final row = await db
.customSelect('select count(*) as c from $table')
.getSingle();
  return row.read<int>('c');
}

// soft-delete-exempt: a schema pragma, not a read of user rows.
Future<int> _userVersion(GeneratedDatabase db) async {
  final row = await db.customSelect('pragma user_version').getSingle();
  return row.data.values.first as int;
}
