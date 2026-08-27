import 'package:factorino/core/formatting/number_display.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/invoice_calculator.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_item.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/features/invoices/domain/invoice_summary_figures.dart';
import 'package:factorino/features/invoices/presentation/widgets/invoice_totals_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screen_harness.dart';

/// What a read path does with a gross that was never recorded (D-055).
///
/// The backfill leaves the three v4 columns null on any pre-v4 invoice whose
/// stored figures it could not reconcile, and refusing to invent a figure is
/// only half the decision — the other half is what the user is then shown. This
/// suite pins that half, in the two places it has to hold:
///
/// * **The view model**, [InvoiceSummaryFigures], which is what the detail
///   screen and the future document renderer will both be handed (§12). Its
///   `grossTotal` is `Money?`, so there is no zero for either of them to print
///   by accident; a read site that wanted to print one would have to write the
///   code to do it.
/// * **The panel**, which says «ثبت‌نشده» — not a blank cell, on the same
///   principle as «بدون شماره» (D-048), and not a zero, which is a figure a
///   document prints.
void main() {
  final DateTime issued = DateTime.utc(2026, 8, 1);

  Invoice invoice({required Money? grossTotal}) => Invoice(
    id: 'i1',
    number: 'INV-1405-0001',
    numberYear: 1405,
    numberSequence: 1,
    customerId: 'c1',
    issueDate: issued,
    status: InvoiceStatus.unpaid,
    discount: Money.zero,
    grossTotal: grossTotal,
    subtotal: Money.rial(21000000),
    // Every figure on the panel is deliberately distinct and none of them is
    // zero, so that the "no zero is rendered" assertion below is a claim about
    // the gross row rather than about a fixture that happens to be empty.
    totalDiscount: Money.rial(1000000),
    totalTax: Money.rial(1230000),
    roundingAdjustment: Money.zero,
    grandTotal: Money.rial(21230000),
    createdAt: issued,
    updatedAt: issued,
  );

  group('the view model carries the absence rather than flattening it', () {
    test('a stored invoice without a gross has no gross', () {
      final figures = InvoiceSummaryFigures.ofStored(invoice(grossTotal: null));

      expect(figures.grossTotal, isNull);
      expect(
        figures.grossTotal,
        isNot(Money.zero),
        reason:
            'a gross of zero beside a grand total of 21,230,000 is a document '
            'contradicting itself; an admission is only an incomplete one',
      );
      expect(figures.reconciles, isFalse);

      // Everything else is still exactly what the row says, and still correct.
      // What is lost is the term the subtraction starts from, not the amount
      // the customer owes.
      expect(figures.grandTotal, Money.rial(21230000));
    });

    test('a stored invoice with one reconciles, by hand', () {
      final figures = InvoiceSummaryFigures.ofStored(
        invoice(grossTotal: Money.rial(21000000)),
      );

      expect(figures.grossTotal, Money.rial(21000000));
      expect(figures.reconciles, isTrue);

      // The equation the panel renders, checked the way a customer would:
      // gross − discount + tax + rounding == the amount payable.
      expect(
        figures.grossTotal!.rial -
            figures.totalDiscount.rial +
            figures.totalTax.rial +
            figures.roundingAdjustment.rial,
        figures.grandTotal.rial,
      );
    });

    test('the live preview always reconciles', () {
      // The engine produces a gross and asserts the summary adds up before it
      // returns, so this path has no absence to carry. Pinned so that the
      // nullable field cannot quietly start being null on the form as well.
      final CalculatedInvoice totals = calculateInvoice(
        InvoiceInput(
          lines: <InvoiceLineInput>[
            InvoiceLineInput(
              unitPrice: Money.rial(1000000),
              quantityMilli: 2000,
            ),
          ],
          defaultTaxRateBp: 900,
        ),
      );

      final figures = InvoiceSummaryFigures.ofCalculation(totals);
      expect(figures.reconciles, isTrue);
      expect(figures.grossTotal, Money.rial(2000000));
    });
  });

  group('a line carries it the same way', () {
    InvoiceItem item({required Money? gross}) => InvoiceItem(
      id: 'l1',
      invoiceId: 'i1',
      position: 0,
      title: 'خدمات',
      unit: 'عدد',
      unitPrice: Money.rial(1000000),
      quantityMilli: 1000,
      discount: Money.zero,
      resolvedTaxRateBp: 0,
      gross: gross,
      allocatedInvoiceDiscount: gross == null ? null : Money.zero,
      lineNet: Money.rial(1000000),
      lineTax: Money.zero,
      lineTotal: Money.rial(1000000),
    );

    test('an unrecorded line reports it rather than reading zero', () {
      final InvoiceItem line = item(gross: null);
      expect(line.gross, isNull);
      expect(line.allocatedInvoiceDiscount, isNull);
      expect(line.hasStoredGross, isFalse);
    });

    test('a recorded line reconciles from its own stored figures', () {
      final InvoiceItem line = item(gross: Money.rial(1000000));
      expect(line.hasStoredGross, isTrue);
      expect(
        line.gross!.rial -
            line.discount.rial -
            line.allocatedInvoiceDiscount!.rial,
        line.lineNet.rial,
      );
    });
  });

  group('the panel says so, in Persian', () {
    testWidgets('an unrecorded gross renders «ثبت‌نشده», never a zero', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _Host(
          figures: InvoiceSummaryFigures.ofStored(invoice(grossTotal: null)),
        ),
      );

      final AppStrings strings = stringsOf(tester, InvoiceTotalsSummary);

      expect(find.text(strings.invoiceFigureUnrecorded), findsOneWidget);

      // The reassurance, which is the half that stops «ثبت‌نشده» reading as a
      // fault in the invoice rather than a gap in what was stored about it.
      expect(
        find.text(strings.invoiceSummaryGrossUnrecordedNote),
        findsOneWidget,
      );

      // **The thing that must not be on screen.** A `۰` in the gross row would
      // be a figure the customer could try to reconcile against, and it would
      // not reconcile. Every other figure on this fixture is non-zero, so a
      // zero anywhere on the panel could only be the gross. Rendered through
      // the application's own formatter rather than a literal, because the
      // group separator lives in one place and a test spelling it out would
      // pass or fail on that rather than on this.
      expect(find.text(formatGroupedPersian(0)), findsNothing);

      // And the amount that *is* known is still shown, at full prominence.
      expect(
        find.text(formatGroupedPersian(2123000)),
        findsOneWidget,
        reason: 'the grand total in Toman is unaffected by the missing gross',
      );
    });

    testWidgets('a recorded gross renders as an amount and no note', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _Host(
          figures: InvoiceSummaryFigures.ofStored(
            invoice(grossTotal: Money.rial(21000000)),
          ),
        ),
      );

      final AppStrings strings = stringsOf(tester, InvoiceTotalsSummary);

      expect(find.text(strings.invoiceFigureUnrecorded), findsNothing);
      expect(
        find.text(strings.invoiceSummaryGrossUnrecordedNote),
        findsNothing,
      );
      // All four terms, each rendered once: the panel is the equation.
      expect(find.text(formatGroupedPersian(2100000)), findsOneWidget);
      expect(find.text(formatGroupedPersian(100000)), findsOneWidget);
      expect(find.text(formatGroupedPersian(123000)), findsOneWidget);
      expect(find.text(formatGroupedPersian(2123000)), findsOneWidget);
    });
  });
}

/// The panel alone, in the application's locale, direction and theme.
class _Host extends StatelessWidget {
  const _Host({required this.figures});

  final InvoiceSummaryFigures figures;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('fa'),
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            // **400, not the desktop panel's own 320, and that is a
            // deliberate limitation of this test rather than the width it
            // will run at.** The panel's grand total is `AmountSize.large`
            // and it overflows 320 at any amount from 1,000,000 تومان
            // upward — measured, and recorded as a known issue for (b),
            // which is where this panel next renders a stored invoice. This
            // suite is about what the copy says, so it is given room to say
            // it; the width is `invoice_editor_screen_test.dart`'s subject
            // and will be the detail screen's.
            child: SizedBox(
              width: 400,
              child: InvoiceTotalsSummary(
                totals: figures,
                strings: AppStrings.of(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
