import 'dart:io';
import 'dart:typed_data';

import 'package:factorino/core/localization/generated/app_strings_fa.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/pdf/document_typeface.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/customer_snapshot.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_detail.dart';
import 'package:factorino/data/models/invoice_item.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/models/payment.dart';
import 'package:factorino/features/invoices/document/invoice_document_generator.dart';
import 'package:factorino/features/invoices/document/invoice_document_view.dart';
import 'package:factorino/features/invoices/document/invoice_document_view_builder.dart';
import 'package:factorino/features/invoices/document/pdf_invoice_document_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/money_magnitudes.dart';

/// Renders the invoice through the real generator, asserts what a machine can,
/// and **writes the pages to `build/document_pages/` so a human can look**.
///
/// **Why it writes files.** A test can assert that the view carries the right
/// strings and that the declared column widths add up. It cannot tell you
/// whether the page reads as an invoice: whether the totals block sits where an
/// Iranian reader looks for it, whether the draft band is unmissable at arm's
/// length, whether a hundred-million-Toman figure fits its column, or whether
/// the table columns came out in the right order on an RTL page. Those are
/// answered by rasterising the output with `tools/pdf_raster/` and reading the
/// pixels, and putting that one command away behind a flag would add friction
/// to exactly the loop that found every real defect in this phase.
///
/// The output directory is under `build/`, which is gitignored.
///
/// **It drives the real generator.** Rebuilding a simplified page here would be
/// a second renderer with its own faults — D-072's corollary.
void main() {
  const String outputDirectory = 'build/document_pages';

  late DocumentTypeface typeface;
  late AppStringsFa strings;
  late InvoiceDocumentGenerator generator;

  setUpAll(() {
    Directory(outputDirectory).createSync(recursive: true);
    typeface = DocumentTypeface.fromBytes(
      regular: File('$_fontDir/Vazirmatn-Regular.ttf').readAsBytesSync(),
      bold: File('$_fontDir/Vazirmatn-Bold.ttf').readAsBytesSync(),
    );
    strings = AppStringsFa();
    generator = PdfInvoiceDocumentGenerator(typeface);
  });

  Future<Uint8List> render(String name, InvoiceDetail detail) async {
    final InvoiceDocumentView view = buildInvoiceDocumentView(
      detail: detail,
      strings: strings,
      boundary: typeface.boundary,
    );
    final Uint8List bytes = await generator.render(view);
    File('$outputDirectory/$name.pdf').writeAsBytesSync(bytes);
    return bytes;
  }

  test('an issued invoice renders at the ladder ceiling', () async {
    // Small test data is what hides a column that fits at 100,000 and breaks
    // at 100,000,000 (D-057).
    final Uint8List bytes = await render(
      'issued_ceiling',
      _detail(toman: kMoneyStressCeilingToman),
    );
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('and at every other rung', () async {
    for (final int rung in kMoneyStressToman) {
      expect(await render('issued_$rung', _detail(toman: rung)), isNotEmpty);
    }
  });

  test('a draft renders, marked', () async {
    final InvoiceDocumentView view = buildInvoiceDocumentView(
      detail: _detail(toman: 10000000, status: InvoiceStatus.draft),
      strings: strings,
      boundary: typeface.boundary,
    );
    expect(view.draftBanner, isNotNull);
    expect(view.number.value.value, strings.invoiceNumberPending);
    expect(
      await render(
        'draft',
        _detail(toman: 10000000, status: InvoiceStatus.draft),
      ),
      isNotEmpty,
    );
  });

  test('a pre-snapshot invoice renders with the one factual line', () async {
    final InvoiceDetail detail = _detail(toman: 10000000, withSnapshot: false);
    final InvoiceDocumentView view = buildInvoiceDocumentView(
      detail: detail,
      strings: strings,
      boundary: typeface.boundary,
    );
    expect(view.party.sourceNote, isNotNull);
    expect(
      view.party.sourceNote!.value,
      strings.invoiceDocumentPartyFromRecord,
    );
    expect(await render('no_snapshot', detail), isNotEmpty);
  });

  test('an invoice with a snapshot says nothing about provenance', () async {
    final InvoiceDocumentView view = buildInvoiceDocumentView(
      detail: _detail(toman: 10000000),
      strings: strings,
      boundary: typeface.boundary,
    );
    expect(view.party.sourceNote, isNull);
    expect(view.draftBanner, isNull);
  });

  test('enough lines to need a second page', () async {
    expect(
      await render('multipage', _detail(toman: 2500000, lineCount: 28)),
      isNotEmpty,
    );
  });
}

const String _fontDir = 'assets/fonts';

/// A realistic invoice. Persian at the length real data reaches, and a ZWNJ in
/// the line titles, because 19% of this application's own strings carry one.
InvoiceDetail _detail({
  required int toman,
  InvoiceStatus status = InvoiceStatus.unpaid,
  bool withSnapshot = true,
  int lineCount = 3,
}) {
  final DateTime issued = DateTime.utc(2026, 8, 24, 6, 30);

  // The fixture reconciles: gross - discount + tax == grandTotal, the §4
  // invariant. The first version did not -- it set grandTotal and the tax and
  // discount rows independently -- and the rendered page showed a summary that
  // did not add up. Nothing was wrong with the renderer, which is the problem:
  // a demonstration page that cannot be checked with a pencil is one where a
  // real reconciliation defect would look like more of the same.
  final int gross = toman;
  final int discount = toman ~/ 20;
  final int tax = (toman - discount) ~/ 10;
  final Money grand = Money.toman(gross - discount + tax);

  final Customer customer = Customer(
    id: 'c1',
    fullName: 'شرکت مهندسی پیش‌رو صنعت پارس',
    companyName: 'پیش‌رو صنعت',
    mobile: '09121234567',
    nationalId: '0069543210',
    economicId: '14003456789012',
    address:
        'تهران، خیابان ولی‌عصر، بالاتر از میدان ونک، پلاک ۱۲۳، طبقهٔ چهارم',
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
      dueDate: issued.add(const Duration(days: 30)),
      status: status,
      discount: Money.zero,
      grossTotal: Money.toman(gross),
      subtotal: Money.toman(gross - discount),
      totalDiscount: Money.toman(discount),
      totalTax: Money.toman(tax),
      roundingAdjustment: Money.zero,
      grandTotal: grand,
      notes: 'پرداخت تا سررسید انجام شود. هزینهٔ حمل بر عهدهٔ خریدار است.',
      customerSnapshot: withSnapshot ? CustomerSnapshot.of(customer) : null,
      createdAt: issued,
      updatedAt: issued,
    ),
    customer: customer,
    items: <InvoiceItem>[
      for (int i = 0; i < lineCount; i++)
        InvoiceItem(
          id: 'l$i',
          invoiceId: 'i1',
          position: i,
          title: i.isEven
              ? 'طراحی و پیاده‌سازی سامانهٔ نگه‌داری تجهیزات'
              : 'خدمات پشتیبانی ماهانه',
          unit: i.isEven ? 'ساعت' : 'ماه',
          unitPrice: Money.toman(gross ~/ (lineCount * 5) * 2),
          quantityMilli: 2500,
          discount: Money.zero,
          resolvedTaxRateBp: 1000,
          allocatedInvoiceDiscount: Money.zero,
          gross: Money.toman(gross ~/ lineCount),
          lineNet: Money.toman(gross ~/ lineCount),
          lineTax: Money.toman(tax ~/ lineCount),
          lineTotal: Money.toman(gross ~/ lineCount),
        ),
    ],
    payments: const <Payment>[],
  );
}
