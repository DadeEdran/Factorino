import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:factorino/data/backup/backup_service.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../database/generated/schema_v3.dart' as v3;
import '../repositories/repository_harness.dart';

/// Phase 6 (c): import, and what every refusal leaves behind.
///
/// The ordering of these groups is the ordering of the risk. A restore that
/// half-succeeds is the worst outcome the application can produce — worse than
/// refusing, worse than crashing — because the user is left with a database
/// that is neither what they had nor what they backed up, and no way to tell
/// which rows are which.
void main() {
  late RepositoryHarness harness;
  late Directory outDir;

  setUp(() async {
    harness = await RepositoryHarness.open();
    outDir = Directory.systemTemp.createTempSync('factorino_import');
  });

  tearDown(() async {
    await harness.close();
    try {
      outDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows holds the handle briefly after close.
    }
  });

  File target([String name = 'import.factorino']) =>
      File('${outDir.path}${Platform.pathSeparator}$name');

  const String passphrase = 'گذرواژهٔ بازیابی ۱۴۰۵';

  BackupService service() => DriftBackupService(harness.db);

  /// The state of the live database, in the terms a refusal has to preserve.
  Future<Map<String, int>> liveCounts() async {
    final Map<String, int> counts = <String, int>{};
    for (final String table in kBackupTableOrder) {
      final rows = await harness.db
          .customSelect('select count(*) as c from $table')
          .get();
      counts[table] = rows.single.read<int>('c');
    }
    return counts;
  }

  Future<List<String>> liveCustomerNames() async {
    final List<CustomerRow> rows = await harness.db
        .select(harness.db.customers)
        .get();
    final List<String> names = rows.map((CustomerRow c) => c.fullName).toList();
    names.sort();
    return names;
  }

  // -------------------------------------------------------------------------
  group('the round trip', () {
    test('every stored figure comes back to the Rial', () async {
      final String customerId = (await harness.customer(name: 'پیشرو')).id;
      final result = await harness.invoices.create(
        harness.draft(
          customerId,
          unitPriceRial: 45000000,
          quantityMilli: 12500,
          discountRial: 3000000,
          taxRateBp: 900,
        ),
      );
      await harness.invoices.issue(result.invoice.id);

      final List<InvoiceRow> invoicesBefore = await harness.db
          .select(harness.db.invoices)
          .get();
      final List<InvoiceItemRow> itemsBefore = await harness.db
          .select(harness.db.invoiceItems)
          .get();

      await service().exportTo(file: target(), passphrase: passphrase);

      // Wipe the live database the hard way, so the comparison afterwards is
      // against restored rows rather than rows that were simply never removed.
      await harness.db.customStatement('delete from invoices');
      expect(await liveCounts(), containsPair('invoices', 0));

      await service().importFrom(file: target(), passphrase: passphrase);

      expect(
        await harness.db.select(harness.db.invoices).get(),
        equals(invoicesBefore),
      );
      expect(
        await harness.db.select(harness.db.invoiceItems).get(),
        equals(itemsBefore),
      );
    });

    test('a tombstone restores as a tombstone', () async {
      // Pinned on the import side as well as the export side. A restore that
      // resurrected a deleted customer would look like a successful restore.
      final String goneId = (await harness.customer(name: 'حذف‌شده')).id;
      await harness.customer(name: 'باقی‌مانده');
      await harness.customers.softDelete(goneId);

      await service().exportTo(file: target(), passphrase: passphrase);
      await harness.db.customStatement('delete from customers');
      await service().importFrom(file: target(), passphrase: passphrase);

      final List<CustomerRow> rows = await harness.db
          .select(harness.db.customers)
          .get();
      expect(rows, hasLength(2));
      expect(
        rows.firstWhere((CustomerRow c) => c.id == goneId).deletedAt,
        isNotNull,
        reason: 'the deleted customer came back alive',
      );
    });

    test('settings restore, and defaults are not reseeded over them', () async {
      await harness.db
          .update(harness.db.settings)
          .write(
            const SettingsCompanion(
              defaultTaxRateBp: Value<int>(900),
              invoiceNumberPrefix: Value<String>('FCT'),
              paymentTermDays: Value<int>(45),
            ),
          );

      await service().exportTo(file: target(), passphrase: passphrase);

      // Put the defaults back, so a restore that reseeded would be
      // indistinguishable from one that did nothing.
      await harness.db
          .update(harness.db.settings)
          .write(
            const SettingsCompanion(
              defaultTaxRateBp: Value<int>(1000),
              invoiceNumberPrefix: Value<String>('INV'),
              paymentTermDays: Value<int>(30),
            ),
          );

      await service().importFrom(file: target(), passphrase: passphrase);

      final List<SettingsRow> rows = await harness.db
          .select(harness.db.settings)
          .get();
      expect(rows, hasLength(1), reason: 'the single-row invariant broke');
      expect(rows.single.defaultTaxRateBp, 900);
      expect(rows.single.invoiceNumberPrefix, 'FCT');
      expect(rows.single.paymentTermDays, 45);
    });

    test('it replaces rather than merges', () async {
      // The behaviour the Persian confirmation copy promises (D-069). A user
      // expecting a merge loses everything entered since the backup, so the
      // code had better actually do what the copy says.
      await harness.customer(name: 'قدیمی');
      await service().exportTo(file: target(), passphrase: passphrase);

      await harness.customer(name: 'بعد از پشتیبان');
      expect(await liveCustomerNames(), hasLength(2));

      await service().importFrom(file: target(), passphrase: passphrase);

      expect(await liveCustomerNames(), <String>['قدیمی']);
    });

    test('an older backup migrates itself up the ladder', () async {
      // Version compatibility downward, through the REAL ladder rather than a
      // second implementation of it: the container is opened as an
      // AppDatabase, so drift runs the same onUpgrade steps the application
      // runs, which already have migration tests of their own.
      final File old = target('v3.factorino');
      final v3.DatabaseAtV3 container = v3.DatabaseAtV3(
        openPassphraseKeyedDatabase(file: old, passphrase: passphrase),
      );
      await container.customStatement(
        'create table backup_meta (format_version integer not null, '
        'app_schema_version integer not null, created_at integer not null)',
      );
      await container.customStatement(
        'create table backup_table_counts (table_name text not null '
        'primary key, row_count integer not null)',
      );
      await container.customStatement(
        'insert into backup_meta values (?, ?, ?)',
        <Object?>[kBackupFormatVersion, 3, 1756000000000],
      );
      await container.customStatement(
        'insert into customers (id, full_name, search_name, created_at, '
        'updated_at, sync_status) values (?, ?, ?, ?, ?, ?)',
        <Object?>['c-v3', 'مشتری نسخهٔ سه', 'مشتری نسخه سه', 1, 1, 0],
      );
      // Counted from the container rather than asserted: DatabaseAtV3 is the
      // generated schema, so it does NOT run AppDatabase's onCreate and does
      // not seed a settings row. Hard-coding the counts encoded that
      // assumption and the verification -- correctly -- refused the file.
      for (final String table in kBackupTableOrder) {
        final rows = await container
            .customSelect('select count(*) as c from $table')
            .get();
        await container.customStatement(
          'insert into backup_table_counts values (?, ?)',
          <Object?>[table, rows.single.read<int>('c')],
        );
      }
      await container.close();

      final BackupSummary summary = await service().importFrom(
        file: old,
        passphrase: passphrase,
      );

      expect(summary.appSchemaVersion, 3, reason: 'reports what the FILE said');

      final List<CustomerRow> rows = await harness.db
          .select(harness.db.customers)
          .get();
      expect(rows.single.fullName, 'مشتری نسخهٔ سه');

      // And the migrated container gained the v4 columns, which is what made
      // the copy above type-check against the live schema at all.
      final List<InvoiceRow> invoices = await harness.db
          .select(harness.db.invoices)
          .get();
      expect(invoices, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  group('every refusal leaves the live database exactly as it was', () {
    late Map<String, int> before;
    late List<String> namesBefore;

    setUp(() async {
      await harness.customer(name: 'الف');
      await harness.customer(name: 'ب');
      final String id = (await harness.customer(name: 'ج')).id;
      await harness.invoices.create(harness.draft(id));
      before = await liveCounts();
      namesBefore = await liveCustomerNames();
    });

    Future<void> expectUntouched() async {
      expect(await liveCounts(), before);
      expect(await liveCustomerNames(), namesBefore);
    }

    test('a wrong passphrase', () async {
      await service().exportTo(file: target(), passphrase: passphrase);

      await expectLater(
        service().importFrom(file: target(), passphrase: 'گذرواژهٔ اشتباه'),
        throwsA(
          isA<BackupImportFailure>().having(
            (BackupImportFailure e) => e.problem,
            'problem',
            BackupImportProblem.cannotOpen,
          ),
        ),
      );
      await expectUntouched();
    });

    test('a tampered file', () async {
      await service().exportTo(file: target(), passphrase: passphrase);

      final List<int> bytes = await target().readAsBytes();
      bytes[2048] = bytes[2048] ^ 0xFF;
      await target().writeAsBytes(bytes, flush: true);

      await expectLater(
        service().importFrom(file: target(), passphrase: passphrase),
        throwsA(
          isA<BackupImportFailure>().having(
            (BackupImportFailure e) => e.problem,
            'problem',
            // Same problem as a wrong passphrase, and deliberately so: the
            // page HMAC cannot tell "wrong key" from "altered bytes", and
            // claiming otherwise would be a guess about the user's file.
            BackupImportProblem.cannotOpen,
          ),
        ),
      );
      await expectUntouched();
    });

    test('a file that is not a backup at all', () async {
      // Opens perfectly well -- it is a keyed database -- and has no
      // backup_meta. The passphrase was right; the file is not ours.
      final File notOurs = target('not_a_backup.factorino');
      final AppDatabase other = AppDatabase(
        openPassphraseKeyedDatabase(file: notOurs, passphrase: passphrase),
      );
      await other.customSelect('select 1').get();
      await other.close();

      await expectLater(
        service().importFrom(file: notOurs, passphrase: passphrase),
        throwsA(
          isA<BackupImportFailure>().having(
            (BackupImportFailure e) => e.problem,
            'problem',
            BackupImportProblem.notABackup,
          ),
        ),
      );
      await expectUntouched();
    });

    test('a backup from a newer version', () async {
      await service().exportTo(file: target(), passphrase: passphrase);
      await _editMeta(
        target(),
        passphrase,
        'update backup_meta set app_schema_version = app_schema_version + 1',
      );

      await expectLater(
        service().importFrom(file: target(), passphrase: passphrase),
        throwsA(
          isA<BackupImportFailure>().having(
            (BackupImportFailure e) => e.problem,
            'problem',
            BackupImportProblem.fromNewerVersion,
          ),
        ),
      );
      await expectUntouched();
    });

    test('a newer container FORMAT, separately from the schema', () async {
      // The two versions move for different reasons, so both are checked.
      await service().exportTo(file: target(), passphrase: passphrase);
      await _editMeta(
        target(),
        passphrase,
        'update backup_meta set format_version = format_version + 1',
      );

      await expectLater(
        service().importFrom(file: target(), passphrase: passphrase),
        throwsA(
          isA<BackupImportFailure>().having(
            (BackupImportFailure e) => e.problem,
            'problem',
            BackupImportProblem.fromNewerVersion,
          ),
        ),
      );
      await expectUntouched();
    });

    test('a valid container whose counts do not match its contents', () async {
      await service().exportTo(file: target(), passphrase: passphrase);
      await _editMeta(
        target(),
        passphrase,
        "update backup_table_counts set row_count = row_count + 5 "
        "where table_name = 'customers'",
      );

      await expectLater(
        service().importFrom(file: target(), passphrase: passphrase),
        throwsA(
          isA<BackupImportFailure>().having(
            (BackupImportFailure e) => e.problem,
            'problem',
            BackupImportProblem.countMismatch,
          ),
        ),
      );
      await expectUntouched();
    });

    test('an empty passphrase, which never reaches the file at all', () async {
      await service().exportTo(file: target(), passphrase: passphrase);

      await expectLater(
        service().importFrom(file: target(), passphrase: ''),
        throwsA(isA<BackupPassphraseRejected>()),
      );
      await expectUntouched();
    });
  });

  // -------------------------------------------------------------------------
  group('the replace-all transaction', () {
    test('a failure part-way through leaves the database exactly as it was', () async {
      // **The most expensive thing in this phase to get wrong.** Not simulated
      // with an injected hook: the container is made genuinely invalid in a way
      // that only bites part-way through the restore -- two issued invoices
      // sharing one invoice number, which the live unique index refuses.
      //
      // By the time that insert runs, `customers` and `products` have already
      // been deleted and reinserted. If the transaction were not doing its job,
      // this test would find the database holding restored customers and no
      // invoices.
      final String customerId = (await harness.customer(name: 'اصلی')).id;
      final result = await harness.invoices.create(harness.draft(customerId));
      await harness.invoices.issue(result.invoice.id);
      await harness.customer(name: 'دومی');

      await service().exportTo(file: target(), passphrase: passphrase);

      final Map<String, int> before = await liveCounts();
      final List<String> namesBefore = await liveCustomerNames();
      final List<InvoiceRow> invoicesBefore = await harness.db
          .select(harness.db.invoices)
          .get();

      // Duplicate the issued invoice under a new id but the SAME number, and
      // fix the counts so the container passes verification and the failure
      // happens during the restore rather than before it.
      await _editMeta(target(), passphrase, null, (
        AppDatabase container,
      ) async {
        // The container carries the same unique index, so it refuses the
        // duplicate too -- which is itself reassuring, and means the index has
        // to come out of the CONTAINER first. The result is a backup that is
        // internally consistent, passes every pre-flight check, and cannot be
        // restored: exactly the file this test needs.
        final indexes = await container
            .customSelect(
              "select name from sqlite_master where type = 'index' "
              "and tbl_name = 'invoices' and sql like '%UNIQUE%'",
            )
            .get();
        for (final row in indexes) {
          await container.customStatement(
            'drop index ${row.read<String>('name')}',
          );
        }

        final List<InvoiceRow> rows = await container
            .select(container.invoices)
            .get();
        final InvoiceRow original = rows.firstWhere(
          (InvoiceRow r) => r.number != null,
        );
        await container
            .into(container.invoices)
            .insert(original.copyWith(id: 'duplicate-number-row'));
        await container.customStatement(
          "update backup_table_counts set row_count = row_count + 1 "
          "where table_name = 'invoices'",
        );
      });

      await expectLater(
        service().importFrom(file: target(), passphrase: passphrase),
        throwsA(
          isA<BackupImportFailure>().having(
            (BackupImportFailure e) => e.problem,
            'problem',
            BackupImportProblem.restoreFailed,
          ),
        ),
      );

      expect(await liveCounts(), before, reason: 'rows were lost or added');
      expect(await liveCustomerNames(), namesBefore);
      expect(
        await harness.db.select(harness.db.invoices).get(),
        equals(invoicesBefore),
        reason: 'the invoices are not the ones that were there before',
      );
    });
  });

  // -------------------------------------------------------------------------
  group('inspect', () {
    test('reports what the file holds without touching live data', () async {
      await harness.customer(name: 'الف');
      await harness.customer(name: 'ب');
      await service().exportTo(file: target(), passphrase: passphrase);

      final Map<String, int> before = await liveCounts();
      final BackupSummary summary = await service().inspect(
        file: target(),
        passphrase: passphrase,
      );

      expect(summary.rowCounts['customers'], 2);
      expect(summary.formatVersion, kBackupFormatVersion);
      expect(summary.appSchemaVersion, harness.db.schemaVersion);
      expect(await liveCounts(), before);
    });

    test(
      'raises the same refusal an import would, before any change',
      () async {
        await service().exportTo(file: target(), passphrase: passphrase);

        await expectLater(
          service().inspect(file: target(), passphrase: 'اشتباه'),
          throwsA(isA<BackupImportFailure>()),
        );
      },
    );
  });

  group('a failure carries nothing sensitive', () {
    test('no passphrase and no path in toString', () {
      const BackupImportFailure failure = BackupImportFailure(
        BackupImportProblem.cannotOpen,
      );
      expect(failure.toString(), 'BackupImportFailure: cannotOpen');
      expect(failure.toString(), isNot(contains(Platform.pathSeparator)));
    });
  });
}

/// Opens a finished container and edits it, so a test can make it invalid in a
/// way only a real container could be.
Future<void> _editMeta(
  File file,
  String passphrase,
  String? statement, [
  Future<void> Function(AppDatabase container)? edit,
]) async {
  final AppDatabase container = AppDatabase(
    openPassphraseKeyedDatabase(file: file, passphrase: passphrase),
  );
  try {
    if (statement != null) await container.customStatement(statement);
    if (edit != null) await edit(container);
  } finally {
    await container.close();
  }
}
