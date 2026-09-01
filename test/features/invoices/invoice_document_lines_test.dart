import 'package:factorino/core/formatting/number_display.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/responsive/breakpoints.dart';
import 'package:factorino/core/widgets/app_card.dart';
import 'package:factorino/core/widgets/app_table.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_item.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/features/invoices/presentation/widgets/invoice_document_lines.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/money_magnitudes.dart';
import '../../support/text_fit.dart';
import '../screen_harness.dart';

/// The document line table's degradation ladder (D-065).
///
/// **The defect this file exists for.** Every money column in this table is
/// fixed-width by D-037, and the flexible description absorbed the entire
/// shortfall whenever the table was composed into a region narrower than the
/// fixed columns needed. On the invoice detail screen that region is what is
/// left beside a `detailPanelWidth` panel, and the description was laid out at
/// **21.6 logical pixels** — Persian rendered one glyph per row, vertically, at
/// every desktop width. Nothing failed, because `Expanded` is a tight fit: a
/// column handed no width is laid out successfully at no width.
///
/// **This tests the widget at the widths it is composed into, not at its own.**
/// The screen test could only ever exercise one rung — `AppLayout.maxContentWidth`
/// caps the page, so the table's region on the detail screen is 800 logical
/// pixels no matter how wide the window is. Testing the ladder through the
/// screen would leave three of its four rungs unreached, and an untested rung is
/// a rung that will be wrong when something finally selects it.
void main() {
  final DateTime issued = DateTime.utc(2026, 8, 20, 6);

  InvoiceItem item({String title = PersianFixtures.longLineTitle}) =>
      InvoiceItem(
        id: 'l1',
        invoiceId: 'i1',
        position: 0,
        title: title,
        unit: 'ساعت',
        unitPrice: Money.rial(kMoneyStressCeilingRial),
        quantityMilli: 2500,
        discount: Money.zero,
        resolvedTaxRateBp: 0,
        gross: Money.rial(kMoneyStressCeilingRial),
        allocatedInvoiceDiscount: Money.zero,
        lineNet: Money.rial(kMoneyStressCeilingRial),
        lineTax: Money.zero,
        lineTotal: Money.rial(kMoneyStressCeilingRial),
      );

  final Invoice invoice = Invoice(
    id: 'i1',
    number: 'INV-1405-0001',
    numberYear: 1405,
    numberSequence: 1,
    customerId: 'c1',
    issueDate: issued,
    status: InvoiceStatus.unpaid,
    discount: Money.zero,
    grossTotal: Money.rial(kMoneyStressCeilingRial),
    subtotal: Money.rial(kMoneyStressCeilingRial),
    totalDiscount: Money.zero,
    totalTax: Money.zero,
    roundingAdjustment: Money.zero,
    grandTotal: Money.rial(kMoneyStressCeilingRial),
    createdAt: issued,
    updatedAt: issued,
  );

  /// Renders the table into a region exactly [width] wide, the way the detail
  /// screen composes it into what the side panel leaves.
  Future<AppStrings> pumpAtWidth(WidgetTester tester, double width) async {
    late BuildContext inner;
    await pumpScreen(
      tester,
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: width,
          child: Builder(
            builder: (BuildContext context) {
              inner = context;
              return InvoiceDocumentLines(
                invoice: invoice,
                items: <InvoiceItem>[item()],
                strings: AppStrings.of(context),
                // The tier says "you may be a table"; the width says whether
                // it can be, and which one.
                tier: LayoutTier.desktop,
              );
            },
          ),
        ),
      ),
      // Wide enough that the surrounding page never constrains the SizedBox,
      // and tall enough that nothing is cut off.
      size: const Size(3000, 1600),
    );
    await tester.pumpAndSettle();
    return AppStrings.of(inner);
  }

  /// The four rungs, with a width that selects each. The numbers are the
  /// ladder's own arithmetic, restated here so that a change to a minimum has
  /// to be acknowledged in a test rather than silently reshaping every table.
  ///
  /// row padding 32 + description 244 + quantity 128 + one money column 244:
  ///   full          1130   شرح · تعداد · مبلغ واحد · مبلغ کل · جمع
  ///   without gross  886   شرح · تعداد · مبلغ واحد · جمع
  ///   compact        648   شرح · تعداد · جمع
  ///   minimal        520   شرح · جمع
  const double fullWidth = 1200;
  const double withoutGrossWidth = 900;
  const double compactWidth = 700;
  const double minimalWidth = 560;
  const double tooNarrow = 400;

  group('the widest shape that fits is the one it takes', () {
    testWidgets('all five columns, given the room for five', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpAtWidth(tester, fullWidth);

      for (final String label in <String>[
        strings.invoiceLineColumnDescription,
        strings.invoiceLineColumnQuantity,
        strings.invoiceLineColumnUnitPrice,
        strings.invoiceLineColumnGross,
        strings.invoiceLineColumnTotal,
      ]) {
        expect(find.text(label), findsOneWidget, reason: '$label is a column');
      }
    });

    testWidgets('مبلغ کل is the first column to go, and becomes a sentence', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpAtWidth(tester, withoutGrossWidth);

      expect(find.text(strings.invoiceLineColumnGross), findsNothing);
      expect(find.text(strings.invoiceLineColumnUnitPrice), findsOneWidget);
      // **Nothing is lost, it is only said differently.** A dropped column that
      // simply disappeared would be a document with a figure missing from it.
      expect(
        find.text(
          strings.invoiceLineLabelGross(
            formatGroupedPersian(kMoneyStressCeilingRial ~/ 10),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('then مبلغ واحد, which also becomes a sentence', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpAtWidth(tester, compactWidth);

      expect(find.text(strings.invoiceLineColumnUnitPrice), findsNothing);
      expect(find.text(strings.invoiceLineColumnQuantity), findsOneWidget);
      expect(
        find.text(
          strings.invoiceLineLabelUnitPrice(
            formatGroupedPersian(kMoneyStressCeilingRial ~/ 10),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('then تعداد, which joins the unit price in one sentence', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpAtWidth(tester, minimalWidth);

      expect(find.text(strings.invoiceLineColumnQuantity), findsNothing);
      // شرح and جمع are the floor: what was sold, and what it came to.
      expect(find.text(strings.invoiceLineColumnDescription), findsOneWidget);
      expect(find.text(strings.invoiceLineColumnTotal), findsOneWidget);
      expect(
        find.text(
          strings.invoiceLineLabelQuantity(
            '۲٫۵',
            'ساعت',
            formatGroupedPersian(kMoneyStressCeilingRial ~/ 10),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('and below the floor it stops being a table at all', (
      WidgetTester tester,
    ) async {
      await pumpAtWidth(tester, tooNarrow);

      expect(
        find.byType(AppTableHeader),
        findsNothing,
        reason:
            'a column that degrades to unreadable is worse than one that is '
            'not shown, and worse again than a shape that was never a table',
      );
      expect(
        find.byType(AppCard),
        findsOneWidget,
        reason: 'the application already has a shape for a line at this width',
      );
    });
  });

  group('no rung crushes its text', () {
    // **The ladder is only correct if every rung of it is.** A shape that fits
    // by its own arithmetic and still breaks a word is the same defect one step
    // along, and the arithmetic is exactly the thing that was wrong before.
    for (final double width in <double>[
      fullWidth,
      withoutGrossWidth,
      compactWidth,
      minimalWidth,
      tooNarrow,
      // Two widths that sit just under each threshold, because a ladder is
      // wrong at its boundaries or nowhere.
      1129,
      885,
      647,
      519,
    ]) {
      testWidgets('at ${width.toStringAsFixed(0)} px', (
        WidgetTester tester,
      ) async {
        await pumpAtWidth(tester, width);
        expectNoCrushedText(tester, where: 'the document line table');
      });
    }
  });
}
