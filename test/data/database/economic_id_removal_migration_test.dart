import 'dart:io';

// `hide isNull, isNotNull`: drift exports SQL expression builders of both
// names, and this file asserts with the matchers.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:factorino/core/security/database_encryption_key.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/repositories/drift/drift_customer_repository.dart';
import 'package:factorino/data/repositories/drift/drift_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v6.dart' as v6;

/// The project's sixth schema migration (D-106): کد اقتصادی leaves the schema.
///
/// **The first migration in this project that destroys data, which is why it is
/// tested differently from the five before it.** Every earlier step added a
/// column or rebuilt a table while copying every value across, so the claim
/// under test was always "nothing was lost". Here something is deliberately
/// lost — three columns and whatever the user had typed into them — and the
/// claim splits in two:
///
/// 1. **The three go**, on every arrival path, from a fresh open and from a
///    v1 device that has never been updated.
/// 2. **Nothing beside them goes.** That is the half a destructive migration
///    gets wrong quietly: `DROP COLUMN` rewrites every row of the table, so a
///    step that named the wrong column, or that ran on the wrong table, would
///    be indistinguishable from success until a user opened a record.
///
/// The suite's two standing claims are made too — the shape is right, and the
/// data survives through the real production path with foreign keys on and the
/// file still encrypted — plus the one every `settings` change owes: the single
/// row is still single, because that table carries `CHECK (singleton = 1)` and
/// a step that duplicated or dropped it would leave `getSingle` throwing on
/// every read in the application.
void main() {
  group('the migrated schema is the declared v7 schema', () {
    late SchemaVerifier verifier;

    setUpAll(() {
      // Foreign keys on, for the reason every earlier suite gives: the
      // application's opener enables them and `beforeOpen` asserts it, so
      // without this the migration refuses to run at all.
      verifier = SchemaVerifier(
        GeneratedHelper(),
        setup: (raw) => raw.execute('PRAGMA foreign_keys = ON;'),
      );
    });

    test('v6 upgrades to v7', () async {
      final connection = await verifier.startAt(6);
      final db = AppDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 7);
    });

    test('v1 upgrades to v7 through every step', () async {
      // **The path that exercises the awkward part of D-106.** A v1 database
      // runs `migrateV2ToV3` and `migrateV4ToV5`, both of which still *create*
      // a column this step then removes — because editing a shipped migration
      // to skip it would make a migrated v3 a different shape from the v3 dump
      // (§6). So the same open adds two columns and drops three, and the only
      // thing that proves the two halves agree is this comparison.
      final connection = await verifier.startAt(1);
      final db = AppDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 7);
    });
  });

  group('a v6 database survives the upgrade, through the production path', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('factorino_v7');
      file = File('${directory.path}${Platform.pathSeparator}test.db');
    });

    tearDown(() {
      try {
        directory.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows holds the handle briefly after close.
      }
    });

    test(
      'the version and the encryption hold, and the row stays single',
      () async {
        await _seedV6(file);

        final db = await openAppDatabase(
          keyStore: _FixedKeyStore(),
          file: file,
        );
        addTearDown(db.close);

        expect(await _userVersion(db), db.schemaVersion);
        expect(
          await _count(db, 'settings'),
          1,
          reason:
              'settings carries CHECK (singleton = 1); a step that duplicated '
              'or dropped the row would leave getSingle throwing on every read',
        );
        expect(await _count(db, 'customers'), 1);
        expect(await _count(db, 'invoices'), 1);

        // soft-delete-exempt: a connection pragma, not a read of user rows.
        final fk = await db.customSelect('pragma foreign_keys').getSingle();
        expect(fk.data.values.first, 1);
        expect(inspectDatabaseFile(file), DatabaseFileState.encrypted);
      },
    );

    test('all three columns are gone, from all three tables', () async {
      // Asked of the database rather than of the Dart declarations: the
      // generated code cannot disagree with itself, and what is under test is
      // the statement that ran on this file.
      await _seedV6(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      expect(await _columns(db, 'customers'), isNot(contains('economic_id')));
      expect(
        await _columns(db, 'settings'),
        isNot(contains('seller_economic_id')),
      );
      expect(
        await _columns(db, 'invoices'),
        isNot(contains('customer_economic_id_snapshot')),
      );
    });

    test('every field beside them is untouched', () async {
      // **The half a destructive migration gets wrong quietly.** `DROP COLUMN`
      // rewrites every row of the table, so a step that named the wrong column
      // — or ran on the wrong table — produces a database that opens, reports
      // the right version, and has silently emptied a field nobody looks at
      // until they open a record. Read back through the real repositories,
      // which is how the user meets these values.
      await _seedV6(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      final AppSettings settings = await DriftSettingsRepository(db).read();
      expect(settings.seller.name, 'کارگاه نمونه');
      expect(settings.seller.phone, '02188776655');
      expect(settings.seller.address, 'تهران، خیابان ولی‌عصر، پلاک ۱۲۳');
      expect(settings.defaultTaxRateBp, 900);
      expect(settings.invoiceNumberPrefix, 'FCT');
      expect(settings.paymentTermDays, 45);

      final Customer? customer = await DriftCustomerRepository(db)
          .findById('customer-1');
      expect(customer, isNotNull);
      expect(customer!.fullName, 'مریم احمدی');
      expect(customer.companyName, 'کارگاه نمونه');
      expect(customer.mobile, '09123456789');
      expect(
        customer.nationalId,
        '0079542311',
        reason:
            'کد ملی sits beside the dropped column in the same table and is '
            'the field a mis-aimed DROP would have taken instead',
      );
      expect(customer.address, 'تهران، خیابان ولیعصر، پلاک ۱۰');
      expect(customer.notes, 'یادداشت نمونه');

      // The invoice's remaining snapshot fields, read straight off the row: the
      // dropped one sat between the national ID and the address, so both
      // neighbours are worth naming.
      final row = await db
          .customSelect(
            'select customer_name_snapshot as n, '
            'customer_national_id_snapshot as nid, '
            'customer_address_snapshot as addr from invoices',
          )
          .getSingle();
      expect(row.data['n'], 'مریم احمدی');
      expect(row.data['nid'], '0079542311');
      expect(row.data['addr'], 'تهران، خیابان ولیعصر، پلاک ۱۰');
    });

    test('the tables are still writable, not merely present', () async {
      // A table a migration rewrites and the write path then refuses is a
      // defect the user meets days later with no way to connect the two.
      // `DROP COLUMN` recreates the row format, so this is not a formality.
      await _seedV6(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      final DriftCustomerRepository customers = DriftCustomerRepository(db);
      final Customer created = await customers.create(
        const CustomerDraft(fullName: 'حسین رضایی', mobile: '09121112233'),
      );
      expect((await customers.findById(created.id))!.fullName, 'حسین رضایی');

      final DriftSettingsRepository settings = DriftSettingsRepository(db);
      await settings.write(
        (await settings.read()).copyWith(defaultTaxRateBp: 1000),
      );
      expect((await settings.read()).defaultTaxRateBp, 1000);
    });
  });

  group('a v1 database reaches v7 through all six steps', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('factorino_v7_v1');
      file = File('${directory.path}${Platform.pathSeparator}test.db');
    });

    tearDown(() {
      try {
        directory.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows holds the handle briefly after close.
      }
    });

    test('the columns v3 and v5 add are the columns v7 removes', () async {
      // The device that has never been updated, on the production path: a
      // table rebuild, eleven column additions, a backfill and three drops, all
      // in one open. `customers.economic_id` is the one that has been there
      // since v1 and is carried the whole way only to be dropped at the end.
      await _seedV1(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      expect(await _userVersion(db), db.schemaVersion);
      expect(await _count(db, 'settings'), 1);
      expect(await _count(db, 'customers'), 1);

      expect(await _columns(db, 'customers'), isNot(contains('economic_id')));
      expect(
        await _columns(db, 'settings'),
        isNot(contains('seller_economic_id')),
      );
      expect(
        await _columns(db, 'invoices'),
        isNot(contains('customer_economic_id_snapshot')),
      );

      final Customer? customer = await DriftCustomerRepository(db)
          .findById('customer-1');
      expect(customer?.fullName, 'مشتری نمونه');
      expect(inspectDatabaseFile(file), DatabaseFileState.encrypted);
    });
  });
}

final int _t = DateTime.utc(2026, 9, 3, 12).millisecondsSinceEpoch;

final DatabaseEncryptionKey _fixedKey = DatabaseEncryptionKey.fromHex(
  '7f' * DatabaseEncryptionKey.lengthBytes,
);

class _FixedKeyStore implements DatabaseKeyStore {
  @override
  Future<DatabaseEncryptionKey> obtain() async => _fixedKey;
}

/// A v6 file with **every** economic-ID column filled, and every neighbouring
/// field filled too.
///
/// Filling the columns that are about to be dropped is what makes the drop
/// observable at all; filling their neighbours is what makes a mis-aimed drop
/// observable. A fixture with only the doomed values set would pass whether the
/// step removed the right column or the wrong one.
Future<void> _seedV6(File file) async {
  final db = v6.DatabaseAtV6(openEncryptedDatabase(file: file, key: _fixedKey));

  await db.batch((Batch batch) {
    batch.insert(
      db.settings,
      v6.SettingsCompanion.insert(
        id: 'settings',
        createdAt: _t,
        updatedAt: _t,
        defaultTaxRateBp: const Value<int>(900),
        invoiceNumberPrefix: const Value<String>('FCT'),
        paymentTermDays: const Value<int>(45),
        sellerName: const Value<String>('کارگاه نمونه'),
        sellerEconomicId: const Value<String>('14003456789012'),
        sellerAddress: const Value<String>('تهران، خیابان ولی‌عصر، پلاک ۱۲۳'),
        sellerPhone: const Value<String>('02188776655'),
      ),
    );
    batch.insert(
      db.customers,
      v6.CustomersCompanion.insert(
        id: 'customer-1',
        createdAt: _t,
        updatedAt: _t,
        fullName: 'مریم احمدی',
        companyName: const Value<String>('کارگاه نمونه'),
        mobile: const Value<String>('09123456789'),
        nationalId: const Value<String>('0079542311'),
        economicId: const Value<String>('411111111111'),
        address: const Value<String>('تهران، خیابان ولیعصر، پلاک ۱۰'),
        notes: const Value<String>('یادداشت نمونه'),
        searchName: const Value<String>('مریم احمدی'),
      ),
    );
    batch.insert(
      db.invoices,
      v6.InvoicesCompanion.insert(
        id: 'invoice-1',
        createdAt: _t,
        updatedAt: _t,
        customerId: 'customer-1',
        issueDate: _t,
        status: 1,
        number: const Value<String>('FCT-1405-0001'),
        numberYear: const Value<int>(1405),
        numberSequence: const Value<int>(1),
        customerNameSnapshot: const Value<String>('مریم احمدی'),
        customerNationalIdSnapshot: const Value<String>('0079542311'),
        customerEconomicIdSnapshot: const Value<String>('411111111111'),
        customerAddressSnapshot: const Value<String>(
          'تهران، خیابان ولیعصر، پلاک ۱۰',
        ),
        grandTotalRial: const Value<int>(20000000),
      ),
    );
  });

  await db.close();
}

/// A v1 file: the device that has never been updated.
Future<void> _seedV1(File file) async {
  final db = v1.DatabaseAtV1(openEncryptedDatabase(file: file, key: _fixedKey));

  await db.batch((Batch batch) {
    batch.insert(
      db.settings,
      v1.SettingsCompanion.insert(
        id: 'settings',
        createdAt: _t,
        updatedAt: _t,
        defaultTaxRateBp: const Value<int>(900),
        invoiceNumberPrefix: const Value<String>('FCT'),
      ),
    );
    batch.insert(
      db.customers,
      v1.CustomersCompanion.insert(
        id: 'customer-1',
        createdAt: _t,
        updatedAt: _t,
        fullName: 'مشتری نمونه',
        economicId: const Value<String>('411111111111'),
      ),
    );
  });

  await db.close();
}

/// The columns [table] actually has on this file.
Future<Set<String>> _columns(AppDatabase db, String table) async {
  // soft-delete-exempt: a schema pragma, not a read of user rows.
  final rows = await db.customSelect('pragma table_info($table)').get();
  return rows.map((QueryRow row) => row.read<String>('name')).toSet();
}

// soft-delete-exempt: counts every row on purpose. A migration that dropped
// soft-deleted rows would be data loss, so the filter would hide the failure.
Future<int> _count(AppDatabase db, String table) async {
  final row = await db
      .customSelect('select count(*) as c from $table')
      .getSingle();
  return row.data['c'] as int;
}

Future<int> _userVersion(AppDatabase db) async {
  // soft-delete-exempt: a connection pragma, not a read of user rows.
  final row = await db.customSelect('pragma user_version').getSingle();
  return row.data.values.first as int;
}
