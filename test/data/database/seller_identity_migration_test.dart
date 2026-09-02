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
import 'package:factorino/data/models/seller_identity.dart';
import 'package:factorino/data/repositories/drift/drift_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v4.dart' as v4;

/// The project's fourth schema migration (D-077): the four nullable
/// `settings.seller_*` columns, so the printed invoice can name the business
/// that issued it.
///
/// **What this migration is about is what it does *not* write.** The three
/// before it each had something to say about existing data — v2 made numbers
/// nullable, v3 added snapshot columns it deliberately left empty, v4 added
/// figures and **backfilled** them where the row reconciled. This one adds four
/// columns and writes nothing into any of them, on purpose and permanently:
/// the database has never been told anything about the user's business, so
/// there is nothing to compute and nothing to copy.
///
/// The alternative was a `withDefault`, and it is worth naming because it is
/// the one shape that would have *produced a document*: a fabricated seller
/// block, on the page the customer keeps, that nobody would ever question
/// because it looks exactly like a real one. So the tests below assert the
/// **absence** as hard as the earlier suites assert their figures.
///
/// The two claims every migration suite here makes are made too — the shape is
/// right, and the data survives through the real production path with foreign
/// keys on — plus the one specific to a settings change: **the single row is
/// still single afterwards.** `settings` carries a `CHECK (singleton = 1)`
/// constraint, and a step that duplicated or dropped it would leave `getSingle`
/// throwing on every read in the application.
void main() {
  group('the migrated schema is the declared v5 schema', () {
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

    test('v4 upgrades to v5', () async {
      final connection = await verifier.startAt(4);
      final db = AppDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 5);
    });

    test('v1 upgrades to v5 through every step', () async {
      // The device that has never been updated. It runs a table rebuild and
      // nine column additions in one open before it reaches this step.
      final connection = await verifier.startAt(1);
      final db = AppDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 5);
    });
  });

  group('a v4 database survives the upgrade, through the production path', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('factorino_v5');
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
        await _seedV4(file);

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

    test('the four columns arrive empty, and stay empty', () async {
      // **The claim this migration exists to make.** Not "the columns are
      // there" — a `withDefault` would satisfy that and would put an invented
      // business name on a customer-facing document. Four nulls, and the
      // settings the user already had, untouched beside them.
      await _seedV4(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      final SettingsRow row = await _settings(db);
      expect(row.sellerName, isNull);
      expect(row.sellerEconomicId, isNull);
      expect(row.sellerAddress, isNull);
      expect(row.sellerPhone, isNull);

      expect(
        row.defaultTaxRateBp,
        900,
        reason: 'the seeded rate is the one the fixture set, not a default',
      );
      expect(row.invoiceNumberPrefix, 'FCT');
      expect(row.paymentTermDays, 45);
    });

    test(
      'the empty row reads back as an empty identity, not as null',
      () async {
        // The distinction the domain model makes: `SellerIdentity.none` is a
        // value every read path can handle, and there is no "configuration
        // missing" case anywhere. `isPrintable` false is what the document
        // consults, and it is false here for every existing user.
        await _seedV4(file);

        final db = await openAppDatabase(
          keyStore: _FixedKeyStore(),
          file: file,
        );
        addTearDown(db.close);

        final AppSettings settings = await DriftSettingsRepository(db).read();
        expect(settings.seller, SellerIdentity.none);
        expect(settings.seller.isEmpty, isTrue);
        expect(settings.seller.isPrintable, isFalse);
      },
    );

    test('the columns are writable, not merely present', () async {
      // A column added by a migration that then refuses writes is a defect the
      // user meets the first time they fill the form in — days after the
      // update, with no way to connect the two. Written and read back through
      // the real repository, on the migrated file.
      await _seedV4(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      final DriftSettingsRepository repository = DriftSettingsRepository(db);
      final AppSettings before = await repository.read();

      await repository.write(
        before.copyWith(
          seller: const SellerIdentity(
            name: 'کارگاه صنعتی نمونه پارس',
            economicId: '14003456789012',
            address: 'تهران، خیابان ولی‌عصر، پلاک ۱۲۳',
            phone: '02188776655',
          ),
        ),
      );

      final AppSettings after = await repository.read();
      expect(after.seller.name, 'کارگاه صنعتی نمونه پارس');
      expect(after.seller.economicId, '14003456789012');
      expect(after.seller.address, 'تهران، خیابان ولی‌عصر، پلاک ۱۲۳');
      expect(after.seller.phone, '02188776655');
      expect(after.seller.isPrintable, isTrue);

      // And the invoicing settings the same row carries are untouched, which
      // is the property that makes two editors safe against one row.
      expect(after.defaultTaxRateBp, 900);
      expect(after.invoiceNumberPrefix, 'FCT');
      expect(after.paymentTermDays, 45);
    });

    test('clearing a stored seller writes nulls, not the old value', () async {
      // **The defect `SellerIdentity` exists to make impossible.** `copyWith`
      // on four nullable strings cannot express "this one is now empty", so
      // `?? this.name` would write the old name straight back and the user
      // would find out on the next document they printed. Asserted at the
      // column, because that is where the old value would survive.
      await _seedV4(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      final DriftSettingsRepository repository = DriftSettingsRepository(db);
      await repository.write(
        (await repository.read()).copyWith(
          seller: const SellerIdentity(
            name: 'کارگاه صنعتی نمونه پارس',
            phone: '02188776655',
          ),
        ),
      );

      await repository.write(
        (await repository.read()).copyWith(seller: SellerIdentity.none),
      );

      final SettingsRow row = await _settings(db);
      expect(row.sellerName, isNull);
      expect(row.sellerPhone, isNull);
      expect((await repository.read()).seller, SellerIdentity.none);
    });

    test('whitespace never reaches a column', () async {
      // A name of three spaces would satisfy every `isNotEmpty` check on the
      // way in, and would print as a blank line under the seller heading —
      // which reads as a document that failed rather than as one that was
      // never filled in. Folded at the repository as well as at the sheet,
      // because a restored backup or a future sync does not go through a
      // sheet.
      await _seedV4(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      final DriftSettingsRepository repository = DriftSettingsRepository(db);
      await repository.write(
        (await repository.read()).copyWith(
          seller: const SellerIdentity(name: '   ', address: '  \n '),
        ),
      );

      final SettingsRow row = await _settings(db);
      expect(row.sellerName, isNull);
      expect(row.sellerAddress, isNull);
    });
  });

  group('a v1 database reaches v5 through all four steps', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('factorino_v5_v1');
      file = File('${directory.path}${Platform.pathSeparator}test.db');
    });

    tearDown(() {
      try {
        directory.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows holds the handle briefly after close.
      }
    });

    test('every step runs, and the settings row arrives with four nulls', () async {
      // The device furthest behind: a table rebuild, then nine column
      // additions and a backfill, then these four — all in one open, on a real
      // encrypted file with foreign keys on. `settings` is rebuilt by no step,
      // so all four are absent on this path too; `_addColumnIfAbsent` is used
      // anyway, so that a future step which *does* rebuild this table cannot
      // turn this open into `duplicate column name` for exactly these users.
      await _seedV1(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      expect(await _userVersion(db), db.schemaVersion);
      expect(await _count(db, 'settings'), 1);
      expect(await _count(db, 'customers'), 1);

      final SettingsRow row = await _settings(db);
      expect(row.sellerName, isNull);
      expect(row.sellerEconomicId, isNull);
      expect(row.sellerAddress, isNull);
      expect(row.sellerPhone, isNull);

      expect(inspectDatabaseFile(file), DatabaseFileState.encrypted);
    });
  });
}

final int _t = DateTime.utc(2026, 9, 2, 12).millisecondsSinceEpoch;

final DatabaseEncryptionKey _fixedKey = DatabaseEncryptionKey.fromHex(
  '7f' * DatabaseEncryptionKey.lengthBytes,
);

class _FixedKeyStore implements DatabaseKeyStore {
  @override
  Future<DatabaseEncryptionKey> obtain() async => _fixedKey;
}

/// A v4 file with settings the user has actually changed.
///
/// Deliberately **not** the seeded defaults: a migration that reset the row
/// would pass every assertion made against `1000` / `INV` / `30`, and would be
/// wrong for exactly the users who had configured anything.
Future<void> _seedV4(File file) async {
  final db = v4.DatabaseAtV4(openEncryptedDatabase(file: file, key: _fixedKey));

  await db.batch((Batch batch) {
    batch.insert(
      db.settings,
      v4.SettingsCompanion.insert(
        id: 'settings',
        createdAt: _t,
        updatedAt: _t,
        defaultTaxRateBp: const Value<int>(900),
        invoiceNumberPrefix: const Value<String>('FCT'),
        paymentTermDays: const Value<int>(45),
      ),
    );
    batch.insert(
      db.customers,
      v4.CustomersCompanion.insert(
        id: 'customer-1',
        createdAt: _t,
        updatedAt: _t,
        fullName: 'مشتری نمونه',
      ),
    );
    batch.insert(
      db.invoices,
      v4.InvoicesCompanion.insert(
        id: 'invoice-1',
        createdAt: _t,
        updatedAt: _t,
        number: const Value<String>('FCT-1405-0001'),
        numberYear: const Value<int>(1405),
        numberSequence: const Value<int>(1),
        customerId: 'customer-1',
        issueDate: _t,
        status: 1,
        subtotalRial: const Value<int>(1000000),
        grandTotalRial: const Value<int>(1000000),
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
      ),
    );
    // v1 required a number on every invoice; D-048 is what made it nullable.
    batch.insert(
      db.invoices,
      v1.InvoicesCompanion.insert(
        id: 'invoice-1',
        createdAt: _t,
        updatedAt: _t,
        number: 'FCT-1405-0001',
        numberYear: 1405,
        numberSequence: 1,
        customerId: 'customer-1',
        issueDate: _t,
        status: 1,
        subtotalRial: const Value<int>(1000000),
        grandTotalRial: const Value<int>(1000000),
      ),
    );
  });

  await db.close();
}

// soft-delete-exempt: the single configuration row, read by identity.
Future<SettingsRow> _settings(AppDatabase db) =>
    db.select(db.settings).getSingle();

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
