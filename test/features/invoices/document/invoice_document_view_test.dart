import 'dart:io';
import 'dart:typed_data';

import 'package:factorino/core/formatting/jalali_display.dart';
import 'package:factorino/core/formatting/number_display.dart';
import 'package:factorino/core/formatting/persian_text.dart';
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
import 'package:factorino/data/models/seller_identity.dart';
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

  InvoiceDocumentView viewOf(
    InvoiceDetail detail, {
    SellerIdentity seller = SellerIdentity.none,
  }) => buildInvoiceDocumentView(
    detail: detail,
    strings: strings,
    boundary: boundary,
    seller: seller,
  );

  /// Every string the view would hand the renderer.
  List<DocumentText> allText(InvoiceDocumentView view) => <DocumentText>[
    view.title,
    if (view.banner != null) view.banner!,
    view.number.label,
    view.number.value,
    view.issueDate.label,
    view.issueDate.value,
    if (view.dueDate != null) ...<DocumentText>[
      view.dueDate!.label,
      view.dueDate!.value,
    ],
    if (view.seller != null) ...<DocumentText>[
      view.seller!.heading,
      view.seller!.name,
      for (final DocumentField f in view.seller!.fields) ...<DocumentText>[
        f.label,
        f.value,
      ],
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
        // **No per-line total is asserted, because none is printed** (D-082).
        // «جمع سطر» carried the line's share of the invoice-level discount,
        // apportioned by an allocation the page never showed, so it was the one
        // figure a reader could not reach with a pencil. What the line does
        // print is its gross, and the gross column sums to the summary's first
        // row — which is the reconciliation the customer actually performs.
        expect(
          view.lines.single.gross.digits.value,
          formatGroupedPersian(detail.items.single.gross!.toman),
          reason: 'line gross at $rung',
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

  group('the issue date carries its time (D-092)', () {
    test('the value is the date and the time, as one answer', () {
      // «۲ شهریور ۱۴۰۵، ساعت ۱۰:۰۰» is one answer to "when was this issued",
      // so it is one value with one label -- not a second labelled field for
      // half of it.
      final InvoiceDocumentView view = viewOf(_detail(toman: 1000000));

      expect(view.issueDate.value.value, contains('۲ شهریور ۱۴۰۵'));
      expect(view.issueDate.value.value, contains('۱۰:۰۰'));
    });

    test('the isolates the screen adds do not reach the renderer', () {
      // **The reason this is safe rather than reckless.** `formatJalaliTime`
      // wraps its result in U+2068/U+2069, which is right on screen -- a colon
      // is bidi-neutral and would otherwise reorder -- and fatal on the page,
      // where Vazirmatn has no glyph for either and the shaper drops the last
      // character of the run containing them (D-070 finding 1). The boundary
      // strips them, so the one formatter serves both surfaces.
      final InvoiceDocumentView view = viewOf(_detail(toman: 1000000));

      expect(view.issueDate.value.value, isNot(contains(kFirstStrongIsolate)));
      expect(
        view.issueDate.value.value,
        isNot(contains(kPopDirectionalIsolate)),
      );
      // And nothing was eaten on the way: the last character of the run is
      // still the last digit of the time.
      expect(view.issueDate.value.value.endsWith('۰۰'), isTrue);
    });

    test('a due date is a day and is given no time', () {
      // A due date is the day money is expected by, not a moment. «۰۰:۰۰»
      // beside it would be an invention on a document a customer keeps.
      //
      // The fixture is asked for one explicitly, because it has none by
      // default -- otherwise this would be a check running in a state the
      // claim is not about, which is §6c's whole subject.
      final InvoiceDocumentView view = viewOf(
        _detail(toman: 1000000, withDueDate: true),
      );

      expect(view.dueDate, isNotNull);
      expect(view.dueDate!.value.value, isNot(contains(':')));
      expect(view.issueDate.value.value, contains(':'));
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
      expect(view.banner, isNotNull);
      expect(view.number.value.value, strings.invoiceNumberPending);
    });

    test('an issued invoice is not marked', () {
      expect(viewOf(_detail(toman: 1000000)).banner, isNull);
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

  /// The seller block (D-077).
  ///
  /// **The block that was not there.** Until schema v5 the settings row held no
  /// business identity at all, so the document named the buyer and nobody else
  /// — which is not an invoice anybody can hand to a customer (D-076). The
  /// interesting cases are all about *absence*: what prints when there is
  /// nothing, and what prints when there is something but not enough.
  group('the seller block', () {
    const SellerIdentity full = SellerIdentity(
      name: 'مهندسی نوآوران فناوری پارسیان',
      economicId: '14003456789012',
      address: 'تهران، خیابان ولی‌عصر، بالاتر از میدان ونک، پلاک ۱۲۳',
      phone: '02188776655',
    );

    test('no seller, no block — and nothing invented to fill it', () {
      // **The state every existing database is in.** The block is omitted
      // entirely; it does not become a heading over four blank lines, which on
      // a printed page reads as a document that failed rather than as one that
      // was never filled in. And nothing is substituted: a placeholder seller
      // on the page the customer keeps is the one thing this phase must not
      // do.
      final InvoiceDocumentView view = viewOf(_detail(toman: 1000000));

      expect(view.seller, isNull);
      expect(
        allText(view).map((DocumentText t) => t.value),
        isNot(contains(strings.invoiceDocumentSellerHeading)),
        reason:
            'an omitted block must not leave its heading behind on the page',
      );
    });

    test('a full seller prints every field it was given', () {
      final InvoiceDocumentView view = viewOf(
        _detail(toman: 1000000),
        seller: full,
      );

      expect(view.seller, isNotNull);
      expect(view.seller!.heading.value, strings.invoiceDocumentSellerHeading);
      expect(view.seller!.name.value, full.name);
      expect(view.seller!.fields, hasLength(3));

      final List<String> values = view.seller!.fields
          .map((DocumentField f) => f.value.value)
          .toList();
      // **Persian digits, and the isolates already stripped.** Both
      // identifiers go through `formatIdentifierForDisplay`, which converts to
      // Persian digits and wraps the run in U+2068/U+2069; the boundary then
      // removes the isolates, because those two are not in the font's `cmap`
      // at all and the shaper silently drops the run's last character (D-070
      // finding 1). So the value on the page is neither the raw string nor the
      // screen's string, and asserting either would have passed while the page
      // printed something else.
      //
      // Asserting the Latin form here would have passed *vacuously* — every
      // `contains` false, every `any` false, and the test green only because
      // it was looking for the wrong thing.
      expect(
        values,
        contains(toPersianDigits('14003456789012')),
        reason: '§9: an identifier prints in Persian digits, like every figure',
      );
      expect(values, contains(toPersianDigits('02188776655')));
      expect(values, contains(full.address));

      // And no isolate survived into a string the renderer will draw.
      for (final String value in values) {
        expect(value.contains(kFirstStrongIsolate), isFalse);
        expect(value.contains(kPopDirectionalIsolate), isFalse);
      }
    });

    test('an empty field is omitted, never printed blank', () {
      final InvoiceDocumentView view = viewOf(
        _detail(toman: 1000000),
        seller: const SellerIdentity(name: 'کارگاه فنی مهر'),
      );

      expect(view.seller, isNotNull);
      expect(
        view.seller!.fields,
        isEmpty,
        reason:
            'a labelled empty line on a document reads as data that failed to '
            'print, which is worse than a line that is simply not there',
      );
    });

    test('details with no name are not a block with a gap in it', () {
      // **The ruling, as a test.** An identity carrying an economic ID and a
      // telephone has something in it and still cannot head a block: the
      // heading identifies nobody, and the reader cannot act on any of it. The
      // form refuses to save this; the builder re-checks, because a value that
      // arrived through a restored backup never met the form.
      final InvoiceDocumentView view = viewOf(
        _detail(toman: 1000000),
        seller: const SellerIdentity(
          economicId: '14003456789012',
          phone: '02188776655',
        ),
      );

      expect(view.seller, isNull);
      // The Persian form, which is what would actually be on the page — the
      // Latin form is absent whatever happens, so looking for it would be a
      // check that cannot fail.
      expect(
        allText(view).map((DocumentText t) => t.value).join(),
        isNot(contains(toPersianDigits('14003456789012'))),
        reason:
            'a field whose block was suppressed must not leak onto the page',
      );
    });

    test('whitespace is not a name', () {
      // Three spaces satisfy every `isNotEmpty` check and print as a blank
      // line under the heading. Folded here as well as at the repository,
      // because the builder is the last thing between a stored value and the
      // page.
      final InvoiceDocumentView view = viewOf(
        _detail(toman: 1000000),
        seller: const SellerIdentity(name: '   ', address: '  '),
      );

      expect(view.seller, isNull);
    });

    test('it says nothing about where its details came from', () {
      // D-075's provenance note is about a **buyer** whose details the
      // document never stored. The seller is read from the live settings row
      // by definition and has no snapshot to have diverged from, so there is
      // nothing factual to say — and a document that explains itself where it
      // need not reads as unreliable.
      final InvoiceDocumentView view = viewOf(
        _detail(toman: 1000000),
        seller: full,
      );

      expect(view.seller!.sourceNote, isNull);
    });

    test('the buyer block is unaffected either way', () {
      // Two blocks, one function. A change to the seller that quietly altered
      // what the buyer block says would be invisible in review and visible
      // only on a printed page.
      final InvoiceDocumentView without = viewOf(_detail(toman: 1000000));
      final InvoiceDocumentView with_ = viewOf(
        _detail(toman: 1000000),
        seller: full,
      );

      expect(with_.party.heading.value, without.party.heading.value);
      expect(with_.party.name.value, without.party.name.value);
      expect(with_.party.fields.length, without.party.fields.length);
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

    test('and a party block is wider than the longest word it can hold', () {
      // D-077 set the two blocks side by side rather than stacking them,
      // which costs no page height and is how an Iranian invoice is
      // conventionally set. That trade is only sound if each half is genuinely
      // wide enough — D-065's lesson is that a block laid out too narrow does
      // **not** overflow or report an error, it just renders one glyph per
      // line. So the width is asserted rather than trusted to `Expanded`.
      //
      // The longest unbreakable run either block can hold is an identifier:
      // a fourteen-digit کد اقتصادی, drawn beside its own label at the party
      // font size. Same generous glyph-advance model as the money columns
      // above, so this fails early rather than at the exact point of overflow;
      // the real check is the rendered page.
      const double perGlyph = 0.62 * InvoiceDocumentLayout.partyFontSize;
      final double needed =
          '14003456789012'.length * perGlyph +
          'کد اقتصادی'.runes.length * perGlyph;
      expect(
        InvoiceDocumentLayout.partyBlockWidth,
        greaterThan(needed),
        reason:
            'a party block narrower than one label-and-identifier row would '
            'wrap the identifier, and a broken کد اقتصادی on an invoice is a '
            'wrong number rather than an ugly one',
      );
      expect(
        InvoiceDocumentLayout.partyBlockWidth * 2,
        lessThan(InvoiceDocumentLayout.contentWidth),
        reason: 'two blocks and the gap between them must fit the page',
      );
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
  bool withDueDate = false,
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
      dueDate: withDueDate ? issued.add(const Duration(days: 30)) : null,
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
