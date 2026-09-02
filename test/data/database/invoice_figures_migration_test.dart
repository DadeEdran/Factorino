import 'dart:io';

// `hide isNull, isNotNull`: drift exports SQL expression builders of both
// names, and this file asserts with the matchers.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:factorino/core/security/database_encryption_key.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/models/payment_method.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v3.dart' as v3;

/// The project's third schema migration (D-055): `invoices.gross_total_rial`,
/// `invoice_items.line_gross_rial` and
/// `invoice_items.allocated_invoice_discount_rial`, so that every figure an
/// Iranian invoice prints is stored rather than re-derived at render time.
///
/// The two claims every migration suite here makes — the shape is right, and
/// the data survives through the real production path with foreign keys on —
/// plus the two that are specific to this one:
///
/// * **It backfills, and D-052's did not.** So there is a third claim: the
///   figures it writes are the ones the invoice was issued under, and where it
///   cannot establish that it writes **nothing**. The refusal has its own
///   fixture, because a migration that silently wrote a plausible-looking zero
///   is the failure this whole design is arranged against.
/// * **A v1 database and a v3 database arrive at this step in different
///   shapes.** [migrateV1ToV2] rebuilds `invoices` from the table as it is
///   declared today, so a device that has never been updated arrives with
///   `gross_total_rial` already present — while both `invoice_items` columns
///   are absent on every path, that table being rebuilt by no step. That
///   asymmetry is what `_addColumnIfAbsent` exists for, and it is **observed
///   here between the steps** rather than taken on trust.
void main() {
  group('the migrated schema is the declared v4 schema', () {
    late SchemaVerifier verifier;

    setUpAll(() {
      // Foreign keys on, for the reason the earlier suites give: the
      // application's opener enables them and `beforeOpen` asserts it, so
      // without this the migration refuses to run at all.
      verifier = SchemaVerifier(
        GeneratedHelper(),
        setup: (raw) => raw.execute('PRAGMA foreign_keys = ON;'),
      );
    });

    test('v3 upgrades to v4', () async {
      final connection = await verifier.startAt(3);
      final db = AppDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 4);
    });
  });

  group('a v3 database survives the upgrade, through the production path', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('factorino_v4');
      file = File('${directory.path}${Platform.pathSeparator}test.db');
    });

    tearDown(() {
      try {
        directory.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows holds the handle briefly after close.
      }
    });

    test('every row survives, and the version and encryption hold', () async {
      await _seedV3(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      expect(await _count(db, 'customers'), 1);
      expect(await _count(db, 'invoices'), 3);
      expect(await _count(db, 'invoice_items'), 6);
      expect(await _count(db, 'payments'), 1);
      expect(await _count(db, 'settings'), 1);

      expect(await _userVersion(db), db.schemaVersion);

      // soft-delete-exempt: a connection pragma, not a read of user rows.
      final fk = await db.customSelect('pragma foreign_keys').getSingle();
      expect(fk.data.values.first, 1);
      expect(inspectDatabaseFile(file), DatabaseFileState.encrypted);
    });

    test('a reconcilable invoice is backfilled to the Rial', () async {
      await _seedV3(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      final InvoiceRow invoice = await _invoice(db, 'invoice-plain');

      // 2,000,000 + 2,250,000, the two lines' §4 step 1 grosses. Not a figure
      // stored anywhere in the v3 fixture — it is what the migration worked
      // out and had to agree with the row about before it would write it.
      expect(invoice.grossTotalRial, 4250000);

      // The summary equation the panel renders, checked here as arithmetic:
      // gross − totalDiscount + totalTax + rounding == grandTotal.
      expect(
        invoice.grossTotalRial! -
            invoice.totalDiscountRial +
            invoice.totalTaxRial +
            invoice.roundingAdjustmentRial,
        invoice.grandTotalRial,
      );

      final List<InvoiceItemRow> lines = await _lines(db, 'invoice-plain');
      expect(lines.map((InvoiceItemRow r) => r.lineGrossRial), <int>[
        2000000,
        2250000,
      ]);
      // No invoice-level discount on this one, so every share is a real zero
      // rather than an unknown — which is exactly the distinction the nullable
      // column exists to keep.
      expect(
        lines.map((InvoiceItemRow r) => r.allocatedInvoiceDiscountRial),
        <int>[0, 0],
      );

      // And each line reconciles on its own, which is what a printed line has
      // to do: gross − discount − allocated == net.
      for (final InvoiceItemRow line in lines) {
        expect(
          line.lineGrossRial! -
              line.discountRial -
              line.allocatedInvoiceDiscountRial!,
          line.lineNetRial,
        );
      }
    });

    test('an invoice-level discount comes back allocated, remainder '
        'and all', () async {
      await _seedV3(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      final List<InvoiceItemRow> lines = await _lines(db, 'invoice-allocated');

      // Three lines of equal net and a discount of 100 Rial: 33.33 each, and
      // the leftover Rial goes to the earliest line (§4 step 4). This is the
      // figure that cannot be recovered by dividing on read — it depends on
      // the tie-break — and the reason the column exists at all.
      expect(
        lines.map((InvoiceItemRow r) => r.allocatedInvoiceDiscountRial),
        <int>[34, 33, 33],
      );

      // The allocation sums to the discount exactly, which is the property
      // that makes the invoice reconcile.
      expect(
        lines.fold<int>(
          0,
          (int sum, InvoiceItemRow r) => sum + r.allocatedInvoiceDiscountRial!,
        ),
        100,
      );

      final InvoiceRow invoice = await _invoice(db, 'invoice-allocated');
      expect(invoice.grossTotalRial, 3000000);
    });

    test('an invoice that does not add up is left null, not zero', () async {
      await _seedV3(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      // **The decision this migration makes about the past, as a test.** This
      // fixture's line stores a net one Rial away from what its own price and
      // quantity produce. The engine cannot reproduce the row, so the row is
      // not accounted for, so nothing is written — not a zero, and not a
      // plausible gross that would make the document add up to a figure the
      // customer was never shown (D-055).
      final InvoiceRow invoice = await _invoice(db, 'invoice-unreconcilable');
      expect(invoice.grossTotalRial, isNull);
      expect(
        invoice.grandTotalRial,
        1000000,
        reason: 'refusing to backfill must not disturb the stored totals',
      );

      final List<InvoiceItemRow> lines = await _lines(
        db,
        'invoice-unreconcilable',
      );
      expect(lines.single.lineGrossRial, isNull);
      expect(lines.single.allocatedInvoiceDiscountRial, isNull);
    });

    test('refusing one invoice does not refuse the others', () async {
      await _seedV3(file);

      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      // The unit of refusal is the invoice. A database with one unreadable
      // document must not lose the figures on every other one, and a migration
      // that gave up at the first bad row would do exactly that.
      expect((await _invoice(db, 'invoice-plain')).grossTotalRial, isNotNull);
      expect(
        (await _invoice(db, 'invoice-allocated')).grossTotalRial,
        isNotNull,
      );
      expect(
        (await _invoice(db, 'invoice-unreconcilable')).grossTotalRial,
        isNull,
      );
    });
  });

  group('a v1 database reaches v4 in one open', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('factorino_v1_v4');
      file = File('${directory.path}${Platform.pathSeparator}test.db');
    });

    tearDown(() {
      try {
        directory.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows holds the handle briefly after close.
      }
    });

    test('all three steps run, and every line and payment survives', () async {
      await _seedV1(file);

      // The whole ladder in one open on a real encrypted file with foreign
      // keys on: a table rebuild, six column additions, three more and a
      // backfill. This is the test that fails with `duplicate column name:
      // gross_total_rial` if the v4 step stops tolerating a column the v1
      // rebuild already created — a failure that would reach only the users
      // who had not updated since the first release, and would leave their
      // database unopenable.
      final db = await openAppDatabase(keyStore: _FixedKeyStore(), file: file);
      addTearDown(db.close);

      // `db.schemaVersion` rather than a literal, and the sibling suite above
      // already reads it that way. This test's claim is that **the whole
      // ladder runs in one open** on a v1 file, not that the ladder ends at
      // any particular rung — pinning the number here made it fail on the day
      // v5 was added, which is a false alarm about a step this suite is not
      // about. The v4 step's own claims are the assertions below.
      expect(await _userVersion(db), db.schemaVersion);
      expect(await _count(db, 'invoices'), 1);
      expect(await _count(db, 'invoice_items'), 2);
      expect(await _count(db, 'payments'), 1);

      final InvoiceRow invoice = await _invoice(db, 'invoice-1');
      expect(invoice.number, 'INV-1405-0001');
      expect(invoice.customerNameSnapshot, isNull, reason: 'D-052 stands');

      // Two lines of 1,000,000 x 1.0, no discounts, 10% tax: the v1 fixture is
      // internally consistent, so the backfill accounts for it.
      expect(invoice.grossTotalRial, 2000000);
      final List<InvoiceItemRow> lines = await _lines(db, 'invoice-1');
      expect(lines.map((InvoiceItemRow r) => r.lineGrossRial), <int>[
        1000000,
        1000000,
      ]);
      expect(
        lines.map((InvoiceItemRow r) => r.allocatedInvoiceDiscountRial),
        <int>[0, 0],
      );
    });
  });

  group('the shape the v4 step is handed, observed between the steps', () {
    late SchemaVerifier verifier;

    setUpAll(() {
      verifier = SchemaVerifier(
        GeneratedHelper(),
        setup: (raw) => raw.execute('PRAGMA foreign_keys = ON;'),
      );
    });

    test('a v1 database arrives with the invoice column present and the '
        'item columns absent', () async {
      // **Why the ladder is driven by hand here.** The claim is about a state
      // that exists only *between* two steps, and the production open runs
      // them back to back. So the schema is instantiated at v1, `user_version`
      // is set to the current version so that drift performs no migration of
      // its own, and the three public step functions — the same three
      // `onUpgrade` calls — are invoked one at a time with the shape read off
      // `PRAGMA table_info` in between.
      final InitializedSchema schema = await verifier.schemaAt(1);
      schema.rawDatabase.userVersion = 4;

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      expect(await _columns(db, 'invoices'), isNot(contains(_grossColumn)));

      await migrateV1ToV2(db.createMigrator());
      await migrateV2ToV3(db.createMigrator());

      // **The asymmetry, observed.** `alterTable` rebuilt `invoices` from the
      // declaration in `app_database.dart` as it stands today, so a column
      // belonging to a schema version two ahead of this database is already
      // there. `invoice_items` was rebuilt by nothing, so neither of its two
      // is. A plain `addColumn` for all three would fail on the first, for
      // every user still on v1 and for nobody else — which is why
      // `_addColumnIfAbsent` is not a defensive habit but the thing that makes
      // both arrival paths land on the same shape.
      expect(
        await _columns(db, 'invoices'),
        contains(_grossColumn),
        reason: 'the v1 rebuild brings it along from the current declaration',
      );
      expect(
        await _columns(db, 'invoice_items'),
        isNot(contains(_lineGrossColumn)),
      );
      expect(
        await _columns(db, 'invoice_items'),
        isNot(contains(_allocatedColumn)),
      );

      // And the step handles exactly that: it skips the one already there and
      // adds the two that are not.
      await migrateV3ToV4(db.createMigrator());

      expect(await _columns(db, 'invoices'), contains(_grossColumn));
      expect(await _columns(db, 'invoice_items'), contains(_lineGrossColumn));
      expect(await _columns(db, 'invoice_items'), contains(_allocatedColumn));
    });

    test('a v3 database arrives with none of the three', () async {
      // The other arrival path, for contrast: nothing rebuilds `invoices`
      // between v3 and v4, so all three columns are genuinely new. If this
      // test and the one above ever agreed, the asymmetry would have gone and
      // the existence checks could be simplified — which is worth being able
      // to find out.
      final InitializedSchema schema = await verifier.schemaAt(3);
      schema.rawDatabase.userVersion = 4;

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      expect(await _columns(db, 'invoices'), isNot(contains(_grossColumn)));
      expect(
        await _columns(db, 'invoice_items'),
        isNot(contains(_lineGrossColumn)),
      );

      await migrateV3ToV4(db.createMigrator());

      expect(await _columns(db, 'invoices'), contains(_grossColumn));
      expect(await _columns(db, 'invoice_items'), contains(_lineGrossColumn));
      expect(await _columns(db, 'invoice_items'), contains(_allocatedColumn));
    });
  });

  group('why this step needs no D-049 guard, demonstrated', () {
    late Directory directory;
    late AppDatabase db;

    setUp(() async {
      directory = Directory.systemTemp.createTempSync('factorino_v4_txn');
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
      // payment (D-048, D-049). `ADD COLUMN` drops nothing and neither does an
      // `UPDATE`, so this step has no such precondition — and the condition
      // below is exactly the one that destroys data in the rebuild: inside a
      // transaction, where the pragma is silently ignored, with children
      // present.
      await _seedRows(db);
      expect(await _count(db, 'invoice_items'), 1);
      expect(await _count(db, 'payments'), 1);

      // Put the database back into its pre-v4 column state without copying the
      // migration: drop exactly the columns the step adds. `ALTER TABLE DROP
      // COLUMN` rewrites rows in place and drops no table, so it is safe here —
      // and it is test setup, not something the application does.
      await db.customStatement(
        'alter table invoices drop column $_grossColumn',
      );
      await db.customStatement(
        'alter table invoice_items drop column $_lineGrossColumn',
      );
      await db.customStatement(
        'alter table invoice_items drop column $_allocatedColumn',
      );

      await db.transaction(() async {
        await migrateV3ToV4(db.createMigrator());
      });

      expect(
        await _count(db, 'invoice_items'),
        1,
        reason: 'ADD COLUMN drops no table, so there is nothing to cascade',
      );
      expect(await _count(db, 'payments'), 1);

      // And the columns really came back, so the run above was not a no-op
      // that would have proved nothing.
      expect(await _columns(db, 'invoices'), contains(_grossColumn));
      expect(await _columns(db, 'invoice_items'), contains(_lineGrossColumn));
    });

    test('and running it a second time changes nothing', () async {
      // The existence check that makes the v1 path work is the same one that
      // makes the step idempotent, and the backfill is idempotent for its own
      // reason: it recomputes from the row's unchanged inputs and compares
      // against the row's unchanged figures, so a second pass reaches the same
      // verdict. A migration that threw on a second run would turn a
      // partially-applied open into an unopenable database.
      await _seedRows(db);

      await migrateV3ToV4(db.createMigrator());
      final InvoiceRow first = await _invoice(db, 'i1');

      await migrateV3ToV4(db.createMigrator());
      final InvoiceRow second = await _invoice(db, 'i1');

      expect(second.grossTotalRial, first.grossTotalRial);
      expect(await _count(db, 'invoices'), 1);
    });
  });
}

const String _grossColumn = 'gross_total_rial';
const String _lineGrossColumn = 'line_gross_rial';
const String _allocatedColumn = 'allocated_invoice_discount_rial';

/// Builds a **v3** database in [file], through the encrypted opener the
/// application uses, holding three invoices the backfill must treat
/// differently.
Future<void> _seedV3(File file) async {
  final db = v3.DatabaseAtV3(openEncryptedDatabase(file: file, key: _fixedKey));

  await db.batch((Batch batch) {
    batch.insert(
      db.settings,
      v3.SettingsCompanion.insert(id: 'settings', createdAt: _t, updatedAt: _t),
    );
    batch.insert(
      db.customers,
      v3.CustomersCompanion.insert(
        id: 'customer-1',
        createdAt: _t,
        updatedAt: _t,
        fullName: 'مشتری نمونه',
      ),
    );

    // ---- reconcilable, with a line discount and 10% tax ------------------
    //
    // 2,000,000 + 2,250,000 gross; 250,000 off the second line; 10% on the
    // 4,000,000 that is left. Every figure below is what §4 produces for those
    // inputs, worked out by hand so that the fixture is a claim about the rule
    // rather than a copy of the code's output.
    batch.insert(
      db.invoices,
      v3.InvoicesCompanion.insert(
        id: 'invoice-plain',
        createdAt: _t,
        updatedAt: _t,
        number: const Value<String>('INV-1405-0001'),
        numberYear: const Value<int>(1405),
        numberSequence: const Value<int>(1),
        customerId: 'customer-1',
        issueDate: _t,
        status: InvoiceStatus.unpaid.index,
        taxRateBp: const Value<int>(1000),
        subtotalRial: const Value<int>(4000000),
        totalDiscountRial: const Value<int>(250000),
        totalTaxRial: const Value<int>(400000),
        grandTotalRial: const Value<int>(4400000),
      ),
    );
    batch.insertAll(db.invoiceItems, <v3.InvoiceItemsCompanion>[
      v3.InvoiceItemsCompanion.insert(
        id: 'plain-0',
        createdAt: _t,
        updatedAt: _t,
        invoiceId: 'invoice-plain',
        position: const Value<int>(0),
        titleSnapshot: 'خدمات',
        unitSnapshot: 'عدد',
        unitPriceRial: 1000000,
        quantityMilli: 2000,
        resolvedTaxRateBp: 1000,
        lineNetRial: const Value<int>(2000000),
        lineTaxRial: const Value<int>(200000),
        lineTotalRial: const Value<int>(2200000),
      ),
      v3.InvoiceItemsCompanion.insert(
        id: 'plain-1',
        createdAt: _t,
        updatedAt: _t,
        invoiceId: 'invoice-plain',
        position: const Value<int>(1),
        titleSnapshot: 'مشاوره',
        unitSnapshot: 'ساعت',
        unitPriceRial: 1500000,
        quantityMilli: 1500,
        resolvedTaxRateBp: 1000,
        discountRial: const Value<int>(250000),
        lineNetRial: const Value<int>(2000000),
        lineTaxRial: const Value<int>(200000),
        lineTotalRial: const Value<int>(2200000),
      ),
    ]);

    // ---- reconcilable, and the allocation leaves a remainder -------------
    //
    // Three lines of 1,000,000 net and a 100 Rial invoice discount: 33.33 each,
    // and largest-remainder hands the leftover Rial to the earliest line. Tax
    // is zero so the allocation is the only thing under test.
    batch.insert(
      db.invoices,
      v3.InvoicesCompanion.insert(
        id: 'invoice-allocated',
        createdAt: _t,
        updatedAt: _t,
        number: const Value<String>('INV-1405-0002'),
        numberYear: const Value<int>(1405),
        numberSequence: const Value<int>(2),
        customerId: 'customer-1',
        issueDate: _t,
        status: InvoiceStatus.unpaid.index,
        discountRial: const Value<int>(100),
        taxRateBp: const Value<int>(0),
        subtotalRial: const Value<int>(3000000),
        totalDiscountRial: const Value<int>(100),
        grandTotalRial: const Value<int>(2999900),
      ),
    );
    batch.insertAll(db.invoiceItems, <v3.InvoiceItemsCompanion>[
      for (int i = 0; i < 3; i++)
        v3.InvoiceItemsCompanion.insert(
          id: 'allocated-$i',
          createdAt: _t,
          updatedAt: _t,
          invoiceId: 'invoice-allocated',
          position: Value<int>(i),
          titleSnapshot: 'قلم $i',
          unitSnapshot: 'عدد',
          unitPriceRial: 1000000,
          quantityMilli: 1000,
          resolvedTaxRateBp: 0,
          lineNetRial: Value<int>(i == 0 ? 999966 : 999967),
          lineTotalRial: Value<int>(i == 0 ? 999966 : 999967),
        ),
    ]);

    // ---- one Rial out, and therefore not accounted for -------------------
    batch.insert(
      db.invoices,
      v3.InvoicesCompanion.insert(
        id: 'invoice-unreconcilable',
        createdAt: _t,
        updatedAt: _t,
        number: const Value<String>('INV-1405-0003'),
        numberYear: const Value<int>(1405),
        numberSequence: const Value<int>(3),
        customerId: 'customer-1',
        issueDate: _t,
        status: InvoiceStatus.unpaid.index,
        subtotalRial: const Value<int>(1000000),
        grandTotalRial: const Value<int>(1000000),
      ),
    );
    batch.insert(
      db.invoiceItems,
      v3.InvoiceItemsCompanion.insert(
        id: 'unreconcilable-0',
        createdAt: _t,
        updatedAt: _t,
        invoiceId: 'invoice-unreconcilable',
        titleSnapshot: 'قلم مبهم',
        unitSnapshot: 'عدد',
        unitPriceRial: 1000000,
        quantityMilli: 1000,
        resolvedTaxRateBp: 0,
        // 999,999 where the price and quantity give 1,000,000. One Rial, and
        // it is enough: the row cannot be the output of the rule, so the rule
        // is not what produced it, so nothing about it may be asserted.
        lineNetRial: const Value<int>(999999),
        lineTotalRial: const Value<int>(999999),
      ),
    );

    batch.insert(
      db.payments,
      v3.PaymentsCompanion.insert(
        id: 'payment-1',
        createdAt: _t,
        updatedAt: _t,
        invoiceId: 'invoice-plain',
        amountRial: 1000000,
        paidAt: _t,
        method: 0,
      ),
    );
  });

  expect(await _userVersion(db), 3, reason: 'the fixture must start at v3');
  await db.close();
}

/// Builds a **v1** database in [file] — the release a device that has never
/// been updated is still on. Two lines, both internally consistent, so the
/// backfill has something to account for at the far end of the ladder.
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
        taxRateBp: const Value<int>(1000),
        subtotalRial: const Value<int>(2000000),
        totalTaxRial: const Value<int>(200000),
        grandTotalRial: const Value<int>(2200000),
      ),
    );
    batch.insertAll(db.invoiceItems, <v1.InvoiceItemsCompanion>[
      for (int i = 0; i < 2; i++)
        v1.InvoiceItemsCompanion.insert(
          id: 'item-$i',
          createdAt: _t,
          updatedAt: _t,
          invoiceId: 'invoice-1',
          position: Value<int>(i),
          titleSnapshot: 'خدمات',
          unitSnapshot: 'عدد',
          unitPriceRial: 1000000,
          quantityMilli: 1000,
          resolvedTaxRateBp: 1000,
          lineNetRial: const Value<int>(1000000),
          lineTaxRial: const Value<int>(100000),
          lineTotalRial: const Value<int>(1100000),
        ),
    ]);
    batch.insert(
      db.payments,
      v1.PaymentsCompanion.insert(
        id: 'payment-1',
        createdAt: _t,
        updatedAt: _t,
        invoiceId: 'invoice-1',
        amountRial: 600000,
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
        subtotalRial: const Value<int>(1000000),
        grandTotalRial: const Value<int>(1000000),
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
        lineNetRial: const Value<int>(1000000),
        lineTotalRial: const Value<int>(1000000),
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

// soft-delete-exempt: a migration assertion over a named row.
Future<InvoiceRow> _invoice(AppDatabase db, String id) =>
    (db.select(db.invoices)..where((r) => r.id.equals(id))).getSingle();

// soft-delete-exempt: a migration assertion over every line of one invoice.
Future<List<InvoiceItemRow>> _lines(AppDatabase db, String invoiceId) =>
    (db.select(db.invoiceItems)
          ..where((r) => r.invoiceId.equals(invoiceId))
          ..orderBy(<OrderClauseGenerator<$InvoiceItemsTable>>[
            (r) => OrderingTerm.asc(r.position),
          ]))
        .get();

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

// soft-delete-exempt: a schema pragma, not a read of user rows.
Future<Set<String>> _columns(GeneratedDatabase db, String table) async {
  final List<QueryRow> rows = await db
      .customSelect('pragma table_info($table)')
      .get();
  return rows.map((QueryRow row) => row.read<String>('name')).toSet();
}
