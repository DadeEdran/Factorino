import 'dart:io';
import 'dart:typed_data';

import 'package:factorino/core/formatting/jalali_display.dart';
import 'package:factorino/core/formatting/number_display.dart';
import 'package:factorino/core/localization/generated/app_strings_fa.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/pdf/document_text.dart';
import 'package:factorino/core/pdf/font_glyph_safety.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/customer_snapshot.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_detail.dart';
import 'package:factorino/data/models/invoice_item.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/models/payment.dart';
import 'package:factorino/features/invoices/document/invoice_document_view.dart';
import 'package:factorino/features/invoices/document/invoice_document_view_builder.dart';
import 'package:factorino/features/invoices/document/pdf_invoice_document_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/money_magnitudes.dart';

/// What the view model owes the renderer, and what it must never do.
///
/// The page itself is checked by rendering and looking at it
/// (`invoice_document_render_test.dart`). This file checks the things a
/// rendered page cannot show you: that the figures printed are the **stored**
/// ones rather than recomputed ones, that every string crossed the boundary,
/// and that a label and a value never became one string.
void main() {
  late FontGlyphSafety safety;
  late DocumentTextBoundary boundary;
  late AppStringsFa strings;

  setUpAll(() {
    final Uint8List bytes = File('assets/fonts/Vazirmatn-Regular.ttf')
        .readAsBytesSync();
    safety = FontGlyphSafety.parse(bytes);
    boundary = DocumentTextBoundary(safety);
    strings = AppStringsFa();
  });

  InvoiceDocumentView viewOf(InvoiceDetail detail) => buildInvoiceDocumentView(
    detail: detail,
    strings: strings,
    boundary: boundary,
  );

  /// Every string the view would hand the renderer.
  List<DocumentText> allText(InvoiceDocumentView view) => <DocumentText>[
    view.title,
    if (view.draftBanner != null) view.draftBanner!,
    view.number.label,
    view.number.value,
    view.issueDate.label,
    view.issueDate.value,
    if (view.dueDate != null) ...<DocumentText>[
      view.dueDate!.label,
      view.dueDate!.value,
    ],
    view.party.heading,
    view.party.name,
    for (final DocumentField f in view.party.fields) ...<DocumentText>[
      f.label,
      f.value,
    ],
    if (view.party.sourceNote != null) view.party.sourceNote!,
    ...view.lineColumns,
    for (final InvoiceDocumentLine line in view.lines) ...<DocumentText>[
      line.rowNumber,
      line.description,
      line.quantity,
      line.unitPrice.digits,
      line.unitPrice.unit,
      line.gross.digits,
      line.gross.unit,
      line.total.digits,
      line.total.unit,
    ],
    for (final DocumentAmountRow row in view.totals) ...<DocumentText>[
      row.label,
      row.amount.digits,
      row.amount.unit,
    ],
    view.grandTotal.label,
    view.grandTotal.amount.digits,
    view.grandTotal.amount.unit,
    if (view.notes != null) view.notes!,
  ];

  group('the figures are the stored ones', () {
    test('at every rung of the ladder', () {
      // Not "a number appears": the exact string the stored Money formats to.
      // A renderer that recomputed would agree at 100,000 and diverge by a
      // Rial somewhere above it, which is the failure that reaches a customer.
      for (final int rung in kMoneyStressToman) {
        final InvoiceDetail detail = _detail(toman: rung);
        final InvoiceDocumentView view = viewOf(detail);
        expect(
          view.grandTotal.amount.digits.value,
          formatGroupedPersian(detail.invoice.grandTotal.toman),
          reason: 'grand total at $rung',
        );
        expect(
          view.lines.single.total.digits.value,
          formatGroupedPersian(detail.items.single.lineTotal.toman),
          reason: 'line total at $rung',
        );
      }
    });

    test('a zero discount row is omitted, not printed as zero', () {
      final InvoiceDocumentView view = viewOf(
        _detail(toman: 1000000, discountToman: 0),
      );
      expect(
        view.totals.map((DocumentAmountRow r) => r.label.value),
        isNot(contains(strings.invoiceSummaryDiscount)),
      );
    });

    test('and appears when there is one', () {
      final InvoiceDocumentView view = viewOf(
        _detail(toman: 1000000, discountToman: 50000),
      );
      expect(
        view.totals.map((DocumentAmountRow r) => r.label.value),
        contains(strings.invoiceSummaryDiscount),
      );
    });

    test('an unrecorded gross is an admission, never a zero', () {
      // D-055: null means unknown. A pre-v4 line whose gross the backfill
      // refused must not print «۰», which is a claim about the sale.
      final InvoiceDocumentView view = viewOf(
        _detail(toman: 1000000, lineGrossRecorded: false),
      );
      expect(view.lines.single.gross.digits.value, contains('ثبت'));
      expect(view.lines.single.gross.digits.value, isNot(contains('۰')));
      expect(
        view.lines.single.gross.unit.isEmpty,
        isTrue,
        reason: '«ثبت‌نشده تومان» is nonsense: nothing for the unit to qualify',
      );
    });

    test(
      'the line description is the snapshot title, not the live product',
      () {
        final InvoiceDetail detail = _detail(toman: 1000000);
        expect(viewOf(detail).lines.single.description.value, 'خدمات پشتیبانی');
      },
    );
  });

  group('every string crossed the boundary', () {
    test('nothing the renderer receives carries a control it cannot draw', () {
      for (final InvoiceDetail detail in <InvoiceDetail>[
        _detail(toman: kMoneyStressCeilingToman),
        _detail(toman: 1000000, status: InvoiceStatus.draft),
        _detail(toman: 1000000, withSnapshot: false),
        _detail(toman: 1000000, lineGrossRecorded: false),
      ]) {
        for (final DocumentText text in allText(viewOf(detail))) {
          expect(
            boundary.wouldStrip(text.value),
            isFalse,
            reason: 'a control survived into "${text.value.length} chars"',
          );
        }
      }
    });

    test('the national ID keeps all ten digits', () {
      // The whole point of the boundary, at the one field where the loss is
      // both silent and legally consequential (D-070 finding 1).
      final InvoiceDocumentView view = viewOf(_detail(toman: 1000000));
      final DocumentField id = view.party.fields.firstWhere(
        (DocumentField f) => f.label.value == strings.customerFieldNationalId,
      );
      expect(id.value.value.runes.length, 10);
    });

    test('and the negative control: the raw formatter output would not', () {
      // Without this, the assertion above could pass because the formatter
      // stopped isolating rather than because the boundary strips. The real
      // §9 formatter is called, not a string that imitates its output.
      expect(
        boundary.wouldStrip(formatIdentifierForDisplay('0069543210')),
        isTrue,
      );
    });
  });

  group('rule 2 -- a label and a value are never one string', () {
    test('no value contains its own label', () {
      final InvoiceDocumentView view = viewOf(_detail(toman: 1000000));
      for (final DocumentField field in <DocumentField>[
        view.number,
        view.issueDate,
        ...view.party.fields,
      ]) {
        expect(
          field.value.value,
          isNot(contains(field.label.value)),
          reason: '${field.label.value} was concatenated into its value',
        );
      }
    });

    test('and no amount contains its unit', () {
      final InvoiceDocumentView view = viewOf(_detail(toman: 1000000));
      expect(
        view.grandTotal.amount.digits.value,
        isNot(contains(strings.unitToman)),
      );
    });
  });

  group('the draft and the party, as D-075 decided them', () {
    test('a draft is marked and has no number', () {
      final InvoiceDocumentView view = viewOf(
        _detail(toman: 1000000, status: InvoiceStatus.draft),
      );
      expect(view.draftBanner, isNotNull);
      expect(view.number.value.value, strings.invoiceNumberPending);
    });

    test('an issued invoice is not marked', () {
      expect(viewOf(_detail(toman: 1000000)).draftBanner, isNull);
    });

    test('only the pre-snapshot case says where the party came from', () {
      expect(viewOf(_detail(toman: 1000000)).party.sourceNote, isNull);
      expect(
        viewOf(_detail(toman: 1000000, status: InvoiceStatus.draft))
            .party
            .sourceNote,
        isNull,
        reason: 'the draft band has already said nothing is final',
      );
      expect(
        viewOf(_detail(toman: 1000000, withSnapshot: false)).party.sourceNote,
        isNotNull,
      );
    });

    test('a diverged snapshot prints the snapshot and says nothing', () {
      // The document is right; the divergence is the app user's business.
      final InvoiceDetail detail = _detail(toman: 1000000, renamedSince: true);
      final InvoiceDocumentView view = viewOf(detail);
      expect(view.party.name.value, 'خدمات فنی آریا');
      expect(view.party.sourceNote, isNull);
    });
  });

  group('the declared table geometry', () {
    test('leaves the description column a workable width', () {
      // D-065: the on-screen document table shipped a description column 21.6
      // points wide, and laid out successfully, and reported no error. The
      // only thing that catches it is asserting the number.
      expect(
        InvoiceDocumentLayout.fixedColumnsWidth,
        lessThan(InvoiceDocumentLayout.contentWidth),
      );
      expect(
        InvoiceDocumentLayout.descriptionWidth,
        greaterThan(120),
        reason: 'a Persian line title needs room for more than one glyph',
      );
    });

    test('and the money columns hold the ladder ceiling', () {
      // A rough width model, deliberately generous about the glyph advance, so
      // it fails early rather than at exactly the point of overflow. The real
      // check is the rendered page at kMoneyStressCeilingToman.
      const double perGlyph = 0.62 * InvoiceDocumentLayout.lineFontSize;
      final String widest = formatGroupedPersian(kMoneyStressCeilingToman);
      final double needed =
          widest.runes.length * perGlyph +
          'تومان'.runes.length * perGlyph * InvoiceDocumentLayout.unitScale;
      expect(InvoiceDocumentLayout.moneyColumnWidth, greaterThan(needed * 0.9));
    });
  });
}

InvoiceDetail _detail({
  required int toman,
  InvoiceStatus status = InvoiceStatus.unpaid,
  bool withSnapshot = true,
  bool renamedSince = false,
  bool lineGrossRecorded = true,
  int discountToman = 0,
}) {
  final DateTime issued = DateTime.utc(2026, 8, 24, 6, 30);
  final Money grand = Money.toman(toman);

  final Customer live = Customer(
    id: 'c1',
    fullName: renamedSince ? 'آریا صنعت پارس' : 'خدمات فنی آریا',
    nationalId: '0069543210',
    createdAt: issued,
    updatedAt: issued,
  );
  final Customer atIssue = Customer(
    id: 'c1',
    fullName: 'خدمات فنی آریا',
    nationalId: '0069543210',
    createdAt: issued,
    updatedAt: issued,
  );

  return InvoiceDetail(
    invoice: Invoice(
      id: 'i1',
      number: status == InvoiceStatus.draft ? null : 'INV-1405-0001',
      numberYear: status == InvoiceStatus.draft ? null : 1405,
      numberSequence: status == InvoiceStatus.draft ? null : 1,
      customerId: 'c1',
      issueDate: issued,
      status: status,
      discount: Money.toman(discountToman),
      grossTotal: grand,
      subtotal: grand,
      totalDiscount: Money.toman(discountToman),
      totalTax: Money.zero,
      roundingAdjustment: Money.zero,
      grandTotal: grand,
      customerSnapshot: withSnapshot ? CustomerSnapshot.of(atIssue) : null,
      createdAt: issued,
      updatedAt: issued,
    ),
    customer: live,
    items: <InvoiceItem>[
      InvoiceItem(
        id: 'l1',
        invoiceId: 'i1',
        position: 0,
        title: 'خدمات پشتیبانی',
        unit: 'ماه',
        unitPrice: grand,
        quantityMilli: 1000,
        discount: Money.zero,
        resolvedTaxRateBp: 0,
        allocatedInvoiceDiscount: Money.zero,
        gross: lineGrossRecorded ? grand : null,
        lineNet: grand,
        lineTax: Money.zero,
        lineTotal: grand,
      ),
    ],
    payments: const <Payment>[],
  );
}
