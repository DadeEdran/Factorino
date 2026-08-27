import 'dart:io';

// `hide isNull, isNotNull`: drift exports SQL expression builders of both
// names, and this file asserts with the matchers.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/security/database_encryption_key.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/invoice_figures_backfill.dart';
import 'package:factorino/data/database/soft_delete.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the v3 -> v4 backfill will and will not write (D-055).
///
/// The migration suite proves it runs on the ladder; this one exercises the
/// judgement it makes on each invoice, which is the part with consequences. The
/// rule under test is a single sentence: **the engine, re-run over the row's
/// own stored inputs, must reproduce every figure already on the row** — and
/// where it does not, the three new columns stay null.
///
/// The fixtures are built on a current database with the new columns left
/// empty, which is the state a pre-v4 invoice is in at the moment the backfill
/// reaches it. That is a faithful stand-in and a far more direct one than
/// re-seeding a v3 file for every case.
void main() {
  late Directory directory;
  late AppDatabase db;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('factorino_backfill');
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

  group('what it writes', () {
    test(
      'a fractional quantity comes back rounded the way §4 rounds',
      () async {
        // 1,000,003 x 1.5 = 1,500,004.5, and §4 step 1 is half-up at the Rial.
        // A backfill that used integer division would write 1,500,004 here and
        // the line would be one Rial short of its own net for the rest of the
        // document's life.
        await _invoice(
          db,
          id: 'i1',
          subtotal: 1500005,
          grandTotal: 1500005,
          lines: <_Line>[
            _Line(unitPrice: 1000003, quantityMilli: 1500, net: 1500005),
          ],
        );

        final report = await backfillInvoiceFigures(db);
        expect(report.reconciled, 1);
        expect(report.refused, 0);

        expect((await _row(db, 'i1')).grossTotalRial, 1500005);
        expect((await _lines(db, 'i1')).single.lineGrossRial, 1500005);
      },
    );

    test('a clamped line discount round-trips as the effective one', () async {
      // The stored discount is the amount **given**, not the amount typed
      // (D-027): a user who entered 5,000,000 against a 1,000,000 line has
      // 1,000,000 on the row. Feeding that back must produce the same net, and
      // must not re-clamp anything or report a warning that changes a figure.
      await _invoice(
        db,
        id: 'i1',
        subtotal: 0,
        grandTotal: 0,
        lines: <_Line>[
          _Line(
            unitPrice: 1000000,
            quantityMilli: 1000,
            discount: 1000000,
            net: 0,
          ),
        ],
      );

      expect((await backfillInvoiceFigures(db)).reconciled, 1);

      final InvoiceItemRow line = (await _lines(db, 'i1')).single;
      expect(line.lineGrossRial, 1000000);
      expect(line.allocatedInvoiceDiscountRial, 0);
      expect(line.lineGrossRial! - line.discountRial, line.lineNetRial);
    });

    test('a stored rounding adjustment is taken as given', () async {
      // Rounding moves the grand total and nothing else. The backfill runs the
      // engine with rounding disabled and adds the stored delta back, so an
      // invoice issued under a rounding unit the user has since changed still
      // reconciles — the recorded adjustment is a fact about the document, not
      // a figure to re-derive.
      await _invoice(
        db,
        id: 'i1',
        subtotal: 1000007,
        grandTotal: 1000000,
        roundingAdjustment: -7,
        lines: <_Line>[
          _Line(unitPrice: 1000007, quantityMilli: 1000, net: 1000007),
        ],
      );

      expect((await backfillInvoiceFigures(db)).reconciled, 1);
      expect((await _row(db, 'i1')).grossTotalRial, 1000007);
    });

    test('an invoice with no lines gets a real zero, not a null', () async {
      // The one place a zero gross is honest: nothing was billed, so the sum
      // over no lines is zero and the document says so. Worth pinning
      // separately, because it is the case where "null means unknown" and
      // "zero means nothing" have to be told apart.
      await _invoice(
        db,
        id: 'i1',
        subtotal: 0,
        grandTotal: 0,
        lines: const <_Line>[],
      );

      expect((await backfillInvoiceFigures(db)).reconciled, 1);
      expect((await _row(db, 'i1')).grossTotalRial, 0);
    });

    test('mixed per-line tax rates are fed back as resolved', () async {
      // Each line stores the rate that actually applied, resolved at creation
      // in the order item -> invoice -> settings default (§4 step 6). The
      // backfill passes those back as **item-level** rates so the settings
      // default is never consulted — a user who changed the default VAT rate
      // since issuing must not thereby make their old invoices unreconcilable.
      await _invoice(
        db,
        id: 'i1',
        subtotal: 2000000,
        totalTax: 280000,
        grandTotal: 2280000,
        lines: <_Line>[
          _Line(
            unitPrice: 1000000,
            quantityMilli: 1000,
            net: 1000000,
            taxRateBp: 1000,
          ),
          _Line(
            unitPrice: 1000000,
            quantityMilli: 1000,
            net: 1000000,
            taxRateBp: 1800,
          ),
        ],
      );

      expect((await backfillInvoiceFigures(db)).reconciled, 1);
      expect((await _row(db, 'i1')).grossTotalRial, 2000000);
    });

    test('soft-deleted lines are neither counted nor filled', () async {
      // `updateDraft` soft-deletes the lines it replaces (D-003), so a real
      // database has superseded lines sitting beside the live ones. They took
      // no part in the totals stored on the invoice, so including them would
      // make every edited invoice unreconcilable — and they belong to no
      // document, so they get no figures of their own.
      await _invoice(
        db,
        id: 'i1',
        subtotal: 1000000,
        grandTotal: 1000000,
        lines: <_Line>[
          _Line(unitPrice: 1000000, quantityMilli: 1000, net: 1000000),
        ],
      );
      await db
          .into(db.invoiceItems)
          .insert(
            InvoiceItemsCompanion.insert(
              id: const Value<String>('dead'),
              invoiceId: 'i1',
              titleSnapshot: 'سطر جایگزین‌شده',
              unitSnapshot: 'عدد',
              unitPriceRial: 9999999,
              quantityMilli: 5000,
              resolvedTaxRateBp: 0,
              deletedAt: Value<int>(_t),
            ),
          );

      expect((await backfillInvoiceFigures(db)).reconciled, 1);

      expect((await _row(db, 'i1')).grossTotalRial, 1000000);
      // soft-delete-exempt: this assertion is *about* the soft-deleted row.
      final InvoiceItemRow dead = await (db.select(
        db.invoiceItems,
      )..where((r) => r.id.equals('dead'))).getSingle();
      expect(dead.lineGrossRial, isNull);
      expect(dead.allocatedInvoiceDiscountRial, isNull);
    });
  });

  group('what it refuses', () {
    test('a line one Rial away from its own inputs', () async {
      await _invoice(
        db,
        id: 'i1',
        subtotal: 999999,
        grandTotal: 999999,
        lines: <_Line>[
          _Line(unitPrice: 1000000, quantityMilli: 1000, net: 999999),
        ],
      );

      final report = await backfillInvoiceFigures(db);
      expect(report.refused, 1);
      expect(report.reconciled, 0);

      expect((await _row(db, 'i1')).grossTotalRial, isNull);
      expect((await _lines(db, 'i1')).single.lineGrossRial, isNull);
    });

    test('a header whose totals do not match its lines', () async {
      // The lines are internally consistent here; the invoice's own subtotal is
      // not. Checked separately from the per-line comparison because a document
      // is wrong if either half is, and a backfill that only looked at lines
      // would write a gross onto a header that contradicts it.
      await _invoice(
        db,
        id: 'i1',
        subtotal: 2000000,
        grandTotal: 2000000,
        lines: <_Line>[
          _Line(unitPrice: 1000000, quantityMilli: 1000, net: 1000000),
        ],
      );

      expect((await backfillInvoiceFigures(db)).refused, 1);
      expect((await _row(db, 'i1')).grossTotalRial, isNull);
    });

    test('a row the engine will not even accept, without throwing', () async {
      // A quantity that puts the product past the exact-integer limit makes the
      // engine raise rather than truncate (D-002). **The backfill must turn
      // that into a refusal, never into an exception**: a migration that throws
      // leaves the user with an application that will not start, over one
      // invoice that was already unprintable.
      await _invoice(
        db,
        id: 'i1',
        subtotal: 1,
        grandTotal: 1,
        lines: <_Line>[
          _Line(
            unitPrice: kMaxAmountRial,
            quantityMilli: kMaxAmountRial,
            net: 1,
          ),
        ],
      );

      expect((await backfillInvoiceFigures(db)).refused, 1);
      expect((await _row(db, 'i1')).grossTotalRial, isNull);
    });

    test('the whole invoice, never a line of it', () async {
      // Two lines, the second one Rial out. The first would reconcile on its
      // own — and must still get nothing, because a document with a gross on
      // one line and an admission on the next reconciles nowhere and explains
      // nothing. The invoice is the unit.
      await _invoice(
        db,
        id: 'i1',
        subtotal: 1999999,
        grandTotal: 1999999,
        lines: <_Line>[
          _Line(unitPrice: 1000000, quantityMilli: 1000, net: 1000000),
          _Line(unitPrice: 1000000, quantityMilli: 1000, net: 999999),
        ],
      );

      expect((await backfillInvoiceFigures(db)).refused, 1);

      final List<InvoiceItemRow> lines = await _lines(db, 'i1');
      expect(lines.map((InvoiceItemRow r) => r.lineGrossRial), <int?>[
        null,
        null,
      ]);
    });

    test('and leaves the invoices beside it alone', () async {
      await _invoice(
        db,
        id: 'good',
        subtotal: 1000000,
        grandTotal: 1000000,
        lines: <_Line>[
          _Line(unitPrice: 1000000, quantityMilli: 1000, net: 1000000),
        ],
      );
      await _invoice(
        db,
        id: 'bad',
        subtotal: 999999,
        grandTotal: 999999,
        lines: <_Line>[
          _Line(unitPrice: 1000000, quantityMilli: 1000, net: 999999),
        ],
      );

      final report = await backfillInvoiceFigures(db);
      expect(report.reconciled, 1);
      expect(report.refused, 1);
      expect(report.total, 2);

      expect((await _row(db, 'good')).grossTotalRial, 1000000);
      expect((await _row(db, 'bad')).grossTotalRial, isNull);
    });
  });

  group('over a database of real size', () {
    test('every invoice past the first page is reached', () async {
      // The backfill pages the invoice table so that a migration on a phone
      // never needs the whole thing resident (§13). A paging bug is invisible
      // on a fixture of three: it shows up as the invoices after the first page
      // silently keeping their nulls, on the largest installs and no others.
      const int count = 250;
      for (int i = 0; i < count; i++) {
        await _invoice(
          db,
          // Zero-padded so the ids sort the way the pager assumes they do.
          id: 'invoice-${i.toString().padLeft(4, '0')}',
          subtotal: 1000000,
          grandTotal: 1000000,
          lines: <_Line>[
            _Line(unitPrice: 1000000, quantityMilli: 1000, net: 1000000),
          ],
        );
      }

      final report = await backfillInvoiceFigures(db);
      expect(report.reconciled, count);

      // soft-delete-exempt: a backfill assertion over every row.
      final List<InvoiceRow> rows = await db.select(db.invoices).get();
      expect(rows, hasLength(count));
      expect(
        rows.every((InvoiceRow row) => row.grossTotalRial == 1000000),
        isTrue,
        reason: 'a page boundary must not leave an invoice unfilled',
      );
    });
  });
}

/// One line of a fixture, in the terms the stored row uses.
class _Line {
  const _Line({
    required this.unitPrice,
    required this.quantityMilli,
    required this.net,
    this.discount = 0,
    this.taxRateBp = 0,
  });

  final int unitPrice;
  final int quantityMilli;
  final int discount;
  final int taxRateBp;

  /// `line_net_rial` as stored: the net **after** the invoice-level discount.
  final int net;

  /// `line_tax_rial`, derived here the way the engine derives it so that a
  /// fixture cannot quietly disagree with itself about its own rate.
  int get tax => (net * taxRateBp) ~/ 10000;
}

/// Inserts an invoice and its lines with the three v4 columns left empty —
/// which is the state the backfill finds a pre-v4 invoice in.
Future<void> _invoice(
  AppDatabase db, {
  required String id,
  required int subtotal,
  required int grandTotal,
  required List<_Line> lines,
  int discount = 0,
  int totalDiscount = 0,
  int totalTax = 0,
  int roundingAdjustment = 0,
}) async {
  await db
      .into(db.invoices)
      .insert(
        InvoicesCompanion.insert(
          id: Value<String>(id),
          customerId: 'c1',
          issueDate: _t,
          status: InvoiceStatus.unpaid,
          discountRial: Value<int>(discount),
          subtotalRial: Value<int>(subtotal),
          totalDiscountRial: Value<int>(
            totalDiscount == 0
                ? lines.fold<int>(0, (int s, _Line l) => s + l.discount) +
                      discount
                : totalDiscount,
          ),
          totalTaxRial: Value<int>(totalTax),
          roundingAdjustmentRial: Value<int>(roundingAdjustment),
          grandTotalRial: Value<int>(grandTotal),
        ),
      );

  for (int i = 0; i < lines.length; i++) {
    final _Line line = lines[i];
    await db
        .into(db.invoiceItems)
        .insert(
          InvoiceItemsCompanion.insert(
            id: Value<String>('$id-$i'),
            invoiceId: id,
            position: Value<int>(i),
            titleSnapshot: 'قلم $i',
            unitSnapshot: 'عدد',
            unitPriceRial: line.unitPrice,
            quantityMilli: line.quantityMilli,
            resolvedTaxRateBp: line.taxRateBp,
            discountRial: Value<int>(line.discount),
            lineNetRial: Value<int>(line.net),
            lineTaxRial: Value<int>(line.tax),
            lineTotalRial: Value<int>(line.net + line.tax),
          ),
        );
  }
}

// soft-delete-exempt: a backfill assertion over a named row.
Future<InvoiceRow> _row(AppDatabase db, String id) =>
    (db.select(db.invoices)..where((r) => r.id.equals(id))).getSingle();

// soft-delete-exempt: the alive lines are asserted by position, and one test
// deliberately asserts about a soft-deleted one.
Future<List<InvoiceItemRow>> _lines(AppDatabase db, String invoiceId) =>
    (db.selectAlive(db.invoiceItems)
          ..where((r) => r.invoiceId.equals(invoiceId))
          ..orderBy(<OrderClauseGenerator<$InvoiceItemsTable>>[
            (r) => OrderingTerm.asc(r.position),
          ]))
        .get();

/// 2026-08-24T12:00Z, the instant the repository fixtures use.
final int _t = DateTime.utc(2026, 8, 24, 12).millisecondsSinceEpoch;

final DatabaseEncryptionKey _fixedKey = DatabaseEncryptionKey.fromHex(
  '7f' * DatabaseEncryptionKey.lengthBytes,
);

class _FixedKeyStore implements DatabaseKeyStore {
  @override
  Future<DatabaseEncryptionKey> obtain() async => _fixedKey;
}
