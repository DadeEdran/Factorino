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
import 'package:factorino/data/models/app_theme_mode.dart';
import 'package:factorino/data/repositories/drift/drift_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v5.dart' as v5;

/// The project's fifth schema migration (D-087): `settings.theme_mode`, the
/// light/dark choice.
///
/// **What is worth pinning here is that nothing looks different afterwards.**
/// Every database that reaches this step has been following the device, and
/// `AppThemeMode.system` is the value that records exactly that — so the
/// column's default is not a convenience, it is the statement that the
/// migration changes no user's application. A different default would repaint
/// every existing installation on the update that introduced a setting nobody
/// had touched yet.
///
/// The two claims every migration suite here makes are made too: the shape is
/// right, and the data survives through the real production path with foreign
/// keys on — plus the one specific to a settings change, that the single row is
/// still single afterwards. `settings` carries `CHECK (singleton = 1)`, and a
/// step that duplicated or dropped it would leave `getSingle` throwing on every
/// read in the application.
void main() {
  group('the migrated schema is the declared v6 schema', () {
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

    test('v5 upgrades to v6', () async {
      final connection = await verifier.startAt(5);
      final db = AppDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 6);
    });

    test('v1 upgrades to v6 through every step', () async {
      // The device that has never been updated: a table rebuild and ten column
      // additions and a backfill, then this one, all in a single open.
      final connection = await verifier.startAt(1);
      final db = AppDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 6);
    });
  });

  group('a v5 database survives the upgrade, through the production path', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('factorino_v6');
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
        await _seedV5(file);

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

        // soft-delete-exempt: a connection pragma, not a read of user rows.
        final fk = await db.customSelect('pragma foreign_keys').getSingle();
        expect(fk.data.values.first, 1);
        expect(inspectDatabaseFile(file), DatabaseFileState.encrypted);
      },
    );

    test('the column arrives as "follow the device", which is what was already happening', () async {
      // **The claim this migration exists to make.** Not "the column is there"
      // but "nobody's application changed": every existing installation was
      // following the system, and `system` is the value that says so. A
      // default of `light` or `dark` here would be a visible change nobody
      // asked for, arriving with an update whose setting they have not opened.
      await _seedV5(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      final SettingsRow row = await _settings(db);
      expect(row.themeMode, AppThemeMode.system);

      // ...and the settings the same row carries are untouched, which is the
      // property that makes a new column safe on a row several editors write.
      expect(row.defaultTaxRateBp, 900);
      expect(row.invoiceNumberPrefix, 'FCT');
      expect(row.paymentTermDays, 45);
      expect(row.sellerName, 'کارگاه نمونه');
    });

    test('the column is writable, not merely present', () async {
      // A column a migration adds and the write path then refuses is a defect
      // the user meets days later, with no way to connect the two. Written and
      // read back through the real repository, on the migrated file.
      await _seedV5(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      final DriftSettingsRepository repository = DriftSettingsRepository(db);

      for (final AppThemeMode mode in AppThemeMode.values) {
        await repository.write(
          (await repository.read()).copyWith(themeMode: mode),
        );
        expect((await repository.read()).themeMode, mode);
      }

      // The seller and the invoicing settings ride through every one of those
      // writes untouched. `write` sends the whole row, so a field it forgot
      // would be cleared by the theme control rather than by anything about
      // the theme.
      final AppSettings after = await repository.read();
      expect(after.seller.name, 'کارگاه نمونه');
      expect(after.defaultTaxRateBp, 900);
      expect(after.paymentTermDays, 45);
    });

    test('the live query emits the change, which is how the theme repaints', () async {
      // `FactorinoApp` watches `appSettingsProvider`, which is this stream. If
      // a write did not reach it the setting would appear to save and do
      // nothing until the next launch — which is precisely how a preference
      // reads as broken.
      await _seedV5(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      final DriftSettingsRepository repository = DriftSettingsRepository(db);
      final Future<AppThemeMode> next = repository
          .watch()
          .map((AppSettings s) => s.themeMode)
          .firstWhere((AppThemeMode m) => m == AppThemeMode.dark);

      await repository.write(
        (await repository.read()).copyWith(themeMode: AppThemeMode.dark),
      );

      expect(await next, AppThemeMode.dark);
    });
  });

  group('a v1 database reaches v6 through all five steps', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('factorino_v6_v1');
      file = File('${directory.path}${Platform.pathSeparator}test.db');
    });

    tearDown(() {
      try {
        directory.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows holds the handle briefly after close.
      }
    });

    test('every step runs, and the theme arrives as system', () async {
      await _seedV1(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      expect(await _userVersion(db), db.schemaVersion);
      expect(await _count(db, 'settings'), 1);
      expect((await _settings(db)).themeMode, AppThemeMode.system);
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

/// A v5 file with settings the user has actually changed, seller included.
///
/// Deliberately **not** the seeded defaults: a migration that reset the row
/// would pass every assertion made against `1000` / `INV` / `30`, and would be
/// wrong for exactly the users who had configured anything.
Future<void> _seedV5(File file) async {
  final db = v5.DatabaseAtV5(openEncryptedDatabase(file: file, key: _fixedKey));

  await db.batch((Batch batch) {
    batch.insert(
      db.settings,
      v5.SettingsCompanion.insert(
        id: 'settings',
        createdAt: _t,
        updatedAt: _t,
        defaultTaxRateBp: const Value<int>(900),
        invoiceNumberPrefix: const Value<String>('FCT'),
        paymentTermDays: const Value<int>(45),
        sellerName: const Value<String>('کارگاه نمونه'),
      ),
    );
    batch.insert(
      db.customers,
      v5.CustomersCompanion.insert(
        id: 'customer-1',
        createdAt: _t,
        updatedAt: _t,
        fullName: 'مشتری نمونه',
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
  });

  await db.close();
}

// soft-delete-exempt: the single configuration row, read by identity.
Future<SettingsRow> _settings(AppDatabase db) =>
    db.select(db.settings).getSingle();

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
