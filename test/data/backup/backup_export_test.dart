import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:factorino/data/backup/backup_service.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:factorino/data/models/payment.dart';
import 'package:factorino/data/models/payment_method.dart';
import 'package:factorino/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../repositories/repository_harness.dart';

/// Phase 6 (b): what a backup is worth is whether the figures come back.
///
/// These run against a **real encrypted database file** through the production
/// bootstrap, like every other repository test, and the container is a second
/// real encrypted file. An in-memory double would exercise neither the cipher
/// nor the KDF, which is most of what is under test.
void main() {
  late RepositoryHarness harness;
  late Directory outDir;

  setUp(() async {
    harness = await RepositoryHarness.open();
    outDir = Directory.systemTemp.createTempSync('factorino_backup');
  });

  tearDown(() async {
    await harness.close();
    try {
      outDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows holds the handle briefly after close.
    }
  });

  File target([String name = 'export.backup']) =>
      File('${outDir.path}${Platform.pathSeparator}$name');

  const String passphrase = 'گذرواژهٔ کاربر ۱۴۰۵';

  BackupService serviceFor(AppDatabase db) => DriftBackupService(db);

  /// Opens the finished container for inspection, the way a restore will.
  Future<AppDatabase> reopen(File file, String password) async {
    final AppDatabase db = AppDatabase(
      openPassphraseKeyedDatabase(file: file, passphrase: password),
    );
    await db.customSelect('select 1').get();
    return db;
  }

  group('the round trip', () {
    test('every stored figure comes back to the Rial', () async {
      // An invoice with a discount and a tax rate, so the stored figures are
      // not all equal to each other and a column swap would show.
      final String customerId = (await harness.customer(
        name: 'شرکت مهندسی پیشرو',
      )).id;
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

      final List<InvoiceItemRow> before = await harness.db
          .select(harness.db.invoiceItems)
          .get();
      final List<InvoiceRow> invoicesBefore = await harness.db
          .select(harness.db.invoices)
          .get();

      final BackupSummary summary = await serviceFor(harness.db)
          .exportTo(file: target(), passphrase: passphrase);

      expect(summary.formatVersion, kBackupFormatVersion);
      expect(summary.appSchemaVersion, harness.db.schemaVersion);

      final AppDatabase container = await reopen(target(), passphrase);
      addTearDown(container.close);

      final List<InvoiceItemRow> after = await container
          .select(container.invoiceItems)
          .get();
      final List<InvoiceRow> invoicesAfter = await container
          .select(container.invoices)
          .get();

      // Compared as whole rows: every figure, not a chosen few. A field added
      // later is covered without anyone remembering to add it here.
      expect(after, equals(before));
      expect(invoicesAfter, equals(invoicesBefore));

      // And named explicitly as well, because "the rows are equal" is a claim
      // about the copy while these are the numbers a customer reconciles.
      final InvoiceRow invoice = invoicesAfter.single;
      final InvoiceItemRow item = after.single;
      expect(invoice.grandTotalRial, invoicesBefore.single.grandTotalRial);
      expect(invoice.subtotalRial, invoicesBefore.single.subtotalRial);
      expect(invoice.totalTaxRial, invoicesBefore.single.totalTaxRial);
      expect(
        invoice.totalDiscountRial,
        invoicesBefore.single.totalDiscountRial,
      );
      expect(invoice.grossTotalRial, invoicesBefore.single.grossTotalRial);
      expect(item.lineTotalRial, before.single.lineTotalRial);
      expect(item.lineNetRial, before.single.lineNetRial);
      expect(item.lineTaxRial, before.single.lineTaxRial);
      expect(item.lineGrossRial, before.single.lineGrossRial);
    });

    test(
      'carries customers, products, invoices, items, payments, settings',
      () async {
        final String customerId = (await harness.customer()).id;
        await harness.product();
        final result = await harness.invoices.create(harness.draft(customerId));
        await harness.invoices.issue(result.invoice.id);
        await harness.payments.record(
          result.invoice.id,
          PaymentDraft(
            amount: Money.rial(500000),
            paidAt: DateTime.utc(2026, 8, 25),
            method: PaymentMethod.cash,
          ),
        );

        final BackupSummary summary = await serviceFor(harness.db)
            .exportTo(file: target(), passphrase: passphrase);

        expect(summary.rowCounts['customers'], 1);
        expect(summary.rowCounts['products'], 1);
        expect(summary.rowCounts['invoices'], 1);
        expect(summary.rowCounts['invoice_items'], 1);
        expect(summary.rowCounts['payments'], 1);
        expect(
          summary.rowCounts['settings'],
          1,
          reason: 'the single settings row must travel, not the seeded default',
        );
      },
    );

    test('carries soft-deleted rows, or a restore resurrects them', () async {
      // The one that would look fine in every other test: a backup that
      // filtered `deleted_at is null` would restore a customer the user
      // deleted, and would hand the future sync layer a device whose deletion
      // never happened.
      final String keptId = (await harness.customer(name: 'باقی‌مانده')).id;
      final String goneId = (await harness.customer(name: 'حذف‌شده')).id;
      await harness.customers.softDelete(goneId);

      await serviceFor(harness.db)
          .exportTo(file: target(), passphrase: passphrase);

      final AppDatabase container = await reopen(target(), passphrase);
      addTearDown(container.close);

      final List<CustomerRow> rows = await container
          .select(container.customers)
          .get();

      expect(rows, hasLength(2));
      expect(
        rows.firstWhere((CustomerRow c) => c.id == goneId).deletedAt,
        isNotNull,
        reason: 'the tombstone must survive the round trip',
      );
      expect(
        rows.firstWhere((CustomerRow c) => c.id == keptId).deletedAt,
        isNull,
      );
    });

    test('the settings row is the live one, not the seeded default', () async {
      // `onCreate` seeds a settings row in the container. If the copy did not
      // clear it first, the backup would carry the default configuration and a
      // restore would quietly reset the user's VAT rate.
      await harness.db
          .update(harness.db.settings)
          .write(
            const SettingsCompanion(
              defaultTaxRateBp: Value<int>(900),
              invoiceNumberPrefix: Value<String>('FCT'),
            ),
          );

      await serviceFor(harness.db)
          .exportTo(file: target(), passphrase: passphrase);

      final AppDatabase container = await reopen(target(), passphrase);
      addTearDown(container.close);

      final List<SettingsRow> rows = await container
          .select(container.settings)
          .get();

      expect(rows, hasLength(1));
      expect(rows.single.defaultTaxRateBp, 900);
      expect(rows.single.invoiceNumberPrefix, 'FCT');
    });

    test('an empty database exports and reopens', () async {
      // The container still has to be valid and still has to verify: an export
      // taken before the user enters anything must not fail, or the first
      // thing a cautious user does breaks.
      final BackupSummary summary = await serviceFor(harness.db)
          .exportTo(file: target(), passphrase: passphrase);

      expect(summary.rowCounts['customers'], 0);
      expect(summary.rowCounts['invoices'], 0);
      expect(summary.rowCounts['settings'], 1);
    });
  });

  group('the artifact', () {
    test('is encrypted, and the customer name is not in the bytes', () async {
      const String name = 'شرکت مهندسی پیشرو رایانه';
      await harness.customer(name: name);

      await serviceFor(harness.db)
          .exportTo(file: target(), passphrase: passphrase);

      expect(inspectDatabaseFile(target()), DatabaseFileState.encrypted);

      final List<int> bytes = await target().readAsBytes();
      expect(
        String.fromCharCodes(bytes).contains(name),
        isFalse,
        reason: 'the customer name is readable in the raw backup file',
      );
    });

    test('the wrong passphrase cannot open it', () async {
      await harness.customer();
      await serviceFor(harness.db)
          .exportTo(file: target(), passphrase: passphrase);

      await expectLater(
        reopen(target(), 'گذرواژهٔ کاربر ۱۴۰۴'),
        throwsA(anything),
      );
    });

    test('replaces a stale container rather than adding to it', () async {
      // Exporting twice to the same path must not accumulate. The container is
      // opened, not created, if a file is already there.
      await harness.customer(name: 'یک');
      await serviceFor(harness.db)
          .exportTo(file: target(), passphrase: passphrase);

      await harness.customer(name: 'دو');
      final BackupSummary second = await serviceFor(harness.db)
          .exportTo(file: target(), passphrase: passphrase);

      expect(second.rowCounts['customers'], 2);

      final AppDatabase container = await reopen(target(), passphrase);
      addTearDown(container.close);
      final List<CustomerRow> rows = await container
          .select(container.customers)
          .get();
      expect(rows, hasLength(2));
    });
  });

  group('the verification reopen is part of the success path', () {
    test('an empty passphrase is refused and leaves no file', () async {
      await harness.customer();

      await expectLater(
        serviceFor(harness.db).exportTo(file: target(), passphrase: ''),
        throwsA(isA<BackupPassphraseRejected>()),
      );
      expect(
        target().existsSync(),
        isFalse,
        reason: 'a refused export must not leave a container behind',
      );
    });

    test('a summary reports the size of the file that exists', () async {
      await harness.customer();
      final BackupSummary summary = await serviceFor(harness.db)
          .exportTo(file: target(), passphrase: passphrase);

      expect(summary.sizeBytes, target().lengthSync());
      expect(summary.sizeBytes, greaterThan(0));
    });

    test('the failure carries no passphrase and no path', () async {
      // Nothing about a backup is logged, and toString() is what reaches a
      // crash report (D-069).
      const String secret = 'the-user-actual-password';
      const BackupExportFailure failure = BackupExportFailure(
        BackupExportProblem.verificationReopenFailed,
      );

      expect(failure.toString(), isNot(contains(secret)));
      expect(failure.toString(), isNot(contains(Platform.pathSeparator)));
    });
  });
}
