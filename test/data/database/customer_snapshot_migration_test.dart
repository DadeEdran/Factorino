import 'dart:io';

// `hide isNull`: drift exports a SQL `isNull` expression builder, and this
// file asserts with the matcher of the same name.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:factorino/core/security/database_encryption_key.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/models/payment_method.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

/// The project's second schema migration (D-052): the five
/// `customer_*_snapshot` columns on `invoices`, so an issued invoice keeps the
/// party it was issued to, and `settings.payment_term_days`, so the default
/// due date stops being a constant in the source.
///
/// The same two claims the v1 -> v2 suite makes, for the same reasons — the
/// shape is right, and the data survives through the real production path with
/// foreign keys on — plus two this migration needs and that one did not:
///
/// * **The ladder works from v1, not only from v2.** A device that has not
///   been updated since the first release arrives here at v1 and runs both
///   steps in one open. The first of them rebuilds `invoices` from the table
///   as it is declared *today*, which means the snapshot columns already exist
///   by the time the second step runs. A plain `addColumn` would fail with
///   `duplicate column name` for exactly those users, on open, and for nobody
///   else.
/// * **This step is safe inside a transaction**, which is what makes D-049's
///   guard inapplicable here rather than merely omitted. `ADD COLUMN` drops
///   nothing, so it has no `PRAGMA foreign_keys = OFF` to be silently ignored
///   — and the test below runs it in the exact condition that destroys data in
///   the v1 -> v2 rebuild, with children present, and counts them afterwards.
void main() {
  group('the migrated schema is the declared v3 schema', () {
    late SchemaVerifier verifier;

    setUpAll(() {
      // Foreign keys on, for the reason the v1 -> v2 suite gives: the
      // application's opener enables them and `beforeOpen` asserts it, so
      // without this the migration refuses to run at all.
      verifier = SchemaVerifier(
        GeneratedHelper(),
        setup: (raw) => raw.execute('PRAGMA foreign_keys = ON;'),
      );
    });

    test('v2 upgrades to v3', () async {
      final connection = await verifier.startAt(2);
      final db = AppDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 3);
    });

    // The v1 -> current *shape* is checked by
    // `invoice_number_migration_test.dart`, which owns the step that rebuilds
    // the table and is therefore where a failure would point. What is checked
    // here is the v1 -> v3 **data**, further down: that is the claim this step
    // could break and that one could not.
  });

  group('a v2 database survives the upgrade, through the production path', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('factorino_v3');
      file = File('${directory.path}${Platform.pathSeparator}test.db');
    });

    tearDown(() {
      try {
        directory.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows holds the handle briefly after close.
      }
    });

    test('every row survives, and the new columns arrive empty', () async {
      await _seedV2(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      expect(await _count(db, 'customers'), 1);
      expect(await _count(db, 'invoices'), 2);
      expect(await _count(db, 'invoice_items'), 3);
      expect(await _count(db, 'payments'), 2);
      expect(await _count(db, 'settings'), 1);

      // soft-delete-exempt: a migration assertion over every row.
      final rows = await db.select(db.invoices).get();
      final byId = <String, InvoiceRow>{
        for (final InvoiceRow row in rows) row.id: row,
      };

      expect(byId['invoice-issued']!.number, 'INV-1405-0001');
      expect(byId['invoice-issued']!.grandTotalRial, 21230000);

      // **The decision this migration makes about the past, as a test.** An
      // invoice issued before v3 has no snapshot and gets none. The migration
      // cannot know what the customer record said on the day that document was
      // printed, and writing today's values in would look like a snapshot
      // while being exactly the live join it replaces. So the columns stay
      // null and the read path falls back to the live customer — which is the
      // behaviour those invoices already had, unchanged (D-052).
      expect(byId['invoice-issued']!.customerNameSnapshot, isNull);
      expect(byId['invoice-issued']!.customerCompanySnapshot, isNull);
      expect(byId['invoice-issued']!.customerNationalIdSnapshot, isNull);
      expect(byId['invoice-issued']!.customerAddressSnapshot, isNull);
    });

    test('the payment term arrives at the default, not at null', () async {
      await _seedV2(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      // A `NOT NULL` column added to a table that already has rows takes its
      // declared default for each of them. Worth pinning: the point of the
      // column is that the app can read a term without handling "not
      // configured", and an existing user's settings row is exactly the row
      // that would have been missed.
      // soft-delete-exempt: the single settings row, asserted after migration.
      final SettingsRow row = await db.select(db.settings).getSingle();
      expect(row.paymentTermDays, kDefaultPaymentTermDays);
    });

    test('the migration leaves foreign keys on and the file encrypted', () async {
      await _seedV2(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      // soft-delete-exempt: a connection pragma, not a read of user rows.
      final fk = await db.customSelect('pragma foreign_keys').getSingle();
      expect(fk.data.values.first, 1);

      // The production opener migrates to the *current* schemaVersion, not to
      // v3, so this suite's data-survival tests run every later step too. Read
      // from the database rather than written down: pinning `3` here would fail
      // on the next migration for a reason that has nothing to do with the
      // claim being made.
      expect(await _userVersion(db), db.schemaVersion);
      expect(inspectDatabaseFile(file), DatabaseFileState.encrypted);
    });
  });

  group('a v1 database reaches the current schema in one open', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('factorino_v1_v3');
      file = File('${directory.path}${Platform.pathSeparator}test.db');
    });

    tearDown(() {
      try {
        directory.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows holds the handle briefly after close.
      }
    });

    test('both steps run, and every line and payment survives', () async {
      await _seedV1(file);

      // The whole ladder in one open: a table rebuild followed by six column
      // additions, on a real encrypted file with foreign keys on. This is the
      // test that fails with `duplicate column name: customer_name_snapshot`
      // if the second step stops tolerating columns the first one already
      // created — a failure that would reach only the users who had not
      // updated since the first release, and would leave their database
      // unopenable.
      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      expect(await _userVersion(db), db.schemaVersion);
      expect(await _count(db, 'invoices'), 1);
      expect(await _count(db, 'invoice_items'), 2);
      expect(await _count(db, 'payments'), 1);

      // soft-delete-exempt: a migration assertion over every row.
      final InvoiceRow invoice = await db.select(db.invoices).getSingle();
      expect(invoice.number, 'INV-1405-0001');
      expect(invoice.numberSequence, 1);
      expect(invoice.grandTotalRial, 21230000);
      expect(invoice.customerNameSnapshot, isNull);

      // soft-delete-exempt: the single settings row, asserted after migration.
      final SettingsRow settings = await db.select(db.settings).getSingle();
      expect(settings.paymentTermDays, kDefaultPaymentTermDays);
    });
  });

  group('why this step needs no D-049 guard, demonstrated', () {
    late Directory directory;
    late AppDatabase db;

    setUp(() async {
      directory = Directory.systemTemp.createTempSync('factorino_v3_txn');
      db = await openAppDatabase(
        keyStore: _FixedKeyStore(),
        file: File('${directory.path}${Platform.pathSeparator}test.db'),
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

    test('it runs inside a transaction without touching a row', () async {
      // `assertForeignKeysCanBeDisabled` checks one property: that
      // `PRAGMA foreign_keys = OFF` takes effect on this connection. The
      // v1 -> v2 rebuild needs it because its step 6 is `DROP TABLE invoices`,
      // which with foreign keys on cascades through every line and every
      // payment in the database (D-048). `ADD COLUMN` drops nothing and
      // therefore has no such precondition — so the guard is not called there,
      // and this is that claim performed rather than asserted.
      //
      // The condition below is exactly the one that destroys data in the
      // rebuild: inside a transaction, where the pragma is silently ignored,
      // with children present.
      await _seedRows(db);
      expect(await _count(db, 'invoice_items'), 1);
      expect(await _count(db, 'payments'), 1);

      // Put the database back into its pre-v3 column state without copying
      // the migration: drop exactly the columns the step adds. `ALTER TABLE
      // DROP COLUMN` rewrites rows in place and drops no table, so it is safe
      // here — and it is test setup, not something the application does.
      //
      // `customer_economic_id_snapshot` is **not** in this list: v7 dropped it
      // (D-106), so a database created at the current version never has it.
      // The step still creates it, which is what keeps a migrated v3 the same
      // shape as the v3 dump — see `_addRetiredColumnIfAbsent`.
      for (final String column in <String>[
        'customer_name_snapshot',
        'customer_company_snapshot',
        'customer_national_id_snapshot',
        'customer_address_snapshot',
      ]) {
        await db.customStatement('alter table invoices drop column $column');
      }
      await db.customStatement(
        'alter table settings drop column payment_term_days',
      );

      await db.transaction(() async {
        await migrateV2ToV3(db.createMigrator());
      });

      // Nothing lost. Under the rebuild, in this same condition, both of these
      // read zero and nothing raises.
      expect(
        await _count(db, 'invoice_items'),
        1,
        reason: 'ADD COLUMN drops no table, so there is nothing to cascade',
      );
      expect(await _count(db, 'payments'), 1);

      // And the columns really came back, so the run above was not a no-op
      // that would have proved nothing.
      // soft-delete-exempt: a schema pragma, not a read of user rows.
      final columns = await db
          .customSelect('pragma table_info(invoices)')
          .get();
      expect(
        columns.map((QueryRow row) => row.read<String>('name')),
        contains('customer_national_id_snapshot'),
      );
    });

    test('and running it a second time changes nothing', () async {
      // The existence check that makes the v1 path work is the same one that
      // makes the step idempotent. Worth pinning on its own: a migration that
      // threw on a second run would turn a partially-applied open into an
      // unopenable database.
      await _seedRows(db);

      await migrateV2ToV3(db.createMigrator());
      await migrateV2ToV3(db.createMigrator());

      expect(await _count(db, 'invoices'), 1);
      // soft-delete-exempt: the single settings row.
      final SettingsRow settings = await db.select(db.settings).getSingle();
      expect(settings.paymentTermDays, kDefaultPaymentTermDays);
    });
  });
}

/// Builds a **v2** database in [file], through the encrypted opener the
/// application uses, holding what a real one would.
Future<void> _seedV2(File file) async {
  final db = v2.DatabaseAtV2(openEncryptedDatabase(file: file, key: _fixedKey));

  await db.batch((Batch batch) {
    batch.insert(
      db.settings,
      v2.SettingsCompanion.insert(id: 'settings', createdAt: _t, updatedAt: _t),
    );
    batch.insert(
      db.customers,
      v2.CustomersCompanion.insert(
        id: 'customer-1',
        createdAt: _t,
        updatedAt: _t,
        fullName: 'مشتری نمونه',
      ),
    );
    batch.insertAll(db.invoices, <v2.InvoicesCompanion>[
      v2.InvoicesCompanion.insert(
        id: 'invoice-issued',
        createdAt: _t,
        updatedAt: _t,
        number: const Value<String>('INV-1405-0001'),
        numberYear: const Value<int>(1405),
        numberSequence: const Value<int>(1),
        customerId: 'customer-1',
        issueDate: _t,
        status: InvoiceStatus.partiallyPaid.index,
        grandTotalRial: const Value<int>(21230000),
      ),
      // A numberless draft, which is what v2 made possible (D-048).
      v2.InvoicesCompanion.insert(
        id: 'invoice-draft',
        createdAt: _t,
        updatedAt: _t,
        customerId: 'customer-1',
        issueDate: _t,
        status: InvoiceStatus.draft.index,
        grandTotalRial: const Value<int>(55000000),
      ),
    ]);
    batch.insertAll(db.invoiceItems, <v2.InvoiceItemsCompanion>[
      for (int i = 0; i < 2; i++)
        v2.InvoiceItemsCompanion.insert(
          id: 'item-issued-$i',
          createdAt: _t,
          updatedAt: _t,
          invoiceId: 'invoice-issued',
          titleSnapshot: 'خدمات',
          unitSnapshot: 'عدد',
          unitPriceRial: 1000000,
          quantityMilli: 1000,
          resolvedTaxRateBp: 1000,
        ),
      v2.InvoiceItemsCompanion.insert(
        id: 'item-draft',
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
    batch.insertAll(db.payments, <v2.PaymentsCompanion>[
      for (int i = 0; i < 2; i++)
        v2.PaymentsCompanion.insert(
          id: 'payment-$i',
          createdAt: _t,
          updatedAt: _t,
          invoiceId: 'invoice-issued',
          amountRial: 3000000,
          paidAt: _t,
          method: 0,
        ),
    ]);
  });

  expect(await _userVersion(db), 2, reason: 'the fixture must start at v2');
  await db.close();
}

/// Builds a **v1** database in [file] — the release a device that has never
/// been updated is still on.
Future<void> _seedV1(File file) async {
  final db = v1.DatabaseAtV1(openEncryptedDatabase(file: file, key: _fixedKey));

  await db.batch((Batch batch) {
    batch.insert(
      db.settings,
      v1.SettingsCompanion.insert(id: 'settings', createdAt: _t, updatedAt: _t),
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
      db.invoices,
      v1.InvoicesCompanion.insert(
        id: 'invoice-1',
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
    );
    batch.insertAll(db.invoiceItems, <v1.InvoiceItemsCompanion>[
      for (int i = 0; i < 2; i++)
        v1.InvoiceItemsCompanion.insert(
          id: 'item-$i',
          createdAt: _t,
          updatedAt: _t,
          invoiceId: 'invoice-1',
          titleSnapshot: 'خدمات',
          unitSnapshot: 'عدد',
          unitPriceRial: 1000000,
          quantityMilli: 1000,
          resolvedTaxRateBp: 1000,
        ),
    ]);
    batch.insert(
      db.payments,
      v1.PaymentsCompanion.insert(
        id: 'payment-1',
        createdAt: _t,
        updatedAt: _t,
        invoiceId: 'invoice-1',
        amountRial: 6000000,
        paidAt: _t,
        method: 0,
      ),
    );
  });

  expect(await _userVersion(db), 1, reason: 'the fixture must start at v1');
  await db.close();
}

/// A customer, an invoice, a line and a payment, on a current database.
Future<void> _seedRows(AppDatabase db) async {
  await db.batch((Batch batch) {
    batch.insert(
      db.customers,
      CustomersCompanion.insert(
        id: const Value<String>('c1'),
        fullName: 'مشتری',
      ),
    );
    batch.insert(
      db.invoices,
      InvoicesCompanion.insert(
        id: const Value<String>('i1'),
        customerId: 'c1',
        issueDate: _t,
        status: InvoiceStatus.unpaid,
      ),
    );
    batch.insert(
      db.invoiceItems,
      InvoiceItemsCompanion.insert(
        invoiceId: 'i1',
        titleSnapshot: 'خط اول',
        unitSnapshot: 'عدد',
        unitPriceRial: 1000000,
        quantityMilli: 1000,
        resolvedTaxRateBp: 0,
      ),
    );
    batch.insert(
      db.payments,
      PaymentsCompanion.insert(
        invoiceId: 'i1',
        amountRial: 500000,
        paidAt: _t,
        method: PaymentMethod.cash,
      ),
    );
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
