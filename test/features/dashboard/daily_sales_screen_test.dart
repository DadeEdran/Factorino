import 'package:factorino/core/date/jalali_period.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/utils/clock.dart';
import 'package:factorino/core/widgets/amount_text.dart';
import 'package:factorino/core/widgets/empty_state.dart';
import 'package:factorino/core/widgets/jalali_month_grid.dart';
import 'package:factorino/core/widgets/stat_tile.dart';
import 'package:factorino/data/models/daily_sales.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_list_item.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/features/dashboard/presentation/daily_sales_screen.dart';
import 'package:factorino/features/invoices/presentation/invoices_screen.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../invoices/fake_invoice_repository.dart';
import '../screen_harness.dart';

/// «فروش روزانه»: pick a day, see that day's sales.
///
/// Three things this file holds down:
///
/// * **The month is fetched once, not once per day.** That is the whole design
///   of the query underneath, and the only way to notice it regressing is to
///   count the calls — a per-day version would look identical on screen and be
///   thirty-one times the work.
/// * **A day with sales is visually distinct from one without**, by the
///   presence of a mark rather than by a colour.
/// * **The mark means an invoice was issued that day** — not a payment
///   received. The decision is recorded on the screen's own doc; this asserts
///   it holds, because a fake that returned payment activity would light the
///   same dots and nothing would fail.
void main() {
  /// 24 August 2026, 06:00 UTC — 2 Shahrivar 1405 in Tehran, the same instant
  /// the dashboard tests use so the two files describe one moment.
  final DateTime now = DateTime.utc(2026, 8, 24, 6);

  final Jalali today = Jalali(1405, 6, 2);

  InvoiceListItem item(String id, {required DateTime issued}) {
    return InvoiceListItem(
      liveCustomerName: 'مریم احمدی',
      invoice: Invoice(
        id: id,
        number: 'INV-1405-0001',
        numberYear: 1405,
        numberSequence: 1,
        customerId: 'c1',
        issueDate: issued,
        status: InvoiceStatus.unpaid,
        discount: Money.zero,
        grossTotal: Money.rial(9000000),
        subtotal: Money.rial(9000000),
        totalDiscount: Money.zero,
        totalTax: Money.zero,
        roundingAdjustment: Money.zero,
        grandTotal: Money.rial(9000000),
        createdAt: issued,
        updatedAt: issued,
      ),
    );
  }

  FakeInvoiceRepository repositoryWith({
    Map<Jalali, DaySales> sales = const <Jalali, DaySales>{},
    List<InvoiceListItem> invoices = const <InvoiceListItem>[],
  }) {
    return FakeInvoiceRepository(invoices)..dailySales = sales;
  }

  List<Override> overridesFor(FakeInvoiceRepository invoices) => <Override>[
    invoiceRepositoryProvider.overrideWithValue(invoices),
    nowProvider.overrideWithValue(now),
  ];

  group('one query for the whole visible month', () {
    testWidgets('the month is asked for once, not once per day', (
      WidgetTester tester,
    ) async {
      // **The assertion the design exists for.** Thirty-one one-day queries
      // would paint the identical calendar, so nothing on screen would tell
      // the two apart — this counts them instead.
      final FakeInvoiceRepository invoices = repositoryWith();
      await pumpScreen(
        tester,
        const DailySalesScreen(),
        overrides: overridesFor(invoices),
      );
      await tester.pumpAndSettle();

      final List<InstantRange> monthQueries = invoices.dailySalesQueries
          .where((InstantRange r) => r.duration > const Duration(days: 1))
          .toList();

      expect(monthQueries, hasLength(1));
      expect(monthQueries.single, jalaliMonth(1405, 6));

      // The one further query is the selected day's own figure, which is the
      // same method over a one-day range rather than a second aggregate.
      final List<InstantRange> dayQueries = invoices.dailySalesQueries
          .where((InstantRange r) => r.duration == const Duration(days: 1))
          .toList();
      expect(dayQueries, hasLength(1));
      expect(dayQueries.single, jalaliDay(today));
    });

    testWidgets('stepping a month is one more query, not thirty-one', (
      WidgetTester tester,
    ) async {
      final FakeInvoiceRepository invoices = repositoryWith();
      await pumpScreen(
        tester,
        const DailySalesScreen(),
        overrides: overridesFor(invoices),
      );
      await tester.pumpAndSettle();
      final AppStrings strings = stringsOf(tester, DailySalesScreen);

      final int before = invoices.dailySalesQueries.length;
      await tester.tap(find.byTooltip(strings.datePickerPreviousMonth));
      await tester.pumpAndSettle();

      expect(
        invoices.dailySalesQueries.length - before,
        1,
        reason: 'stepping to Mordad costs exactly one grouped query',
      );
      expect(invoices.dailySalesQueries.last, jalaliMonth(1405, 5));
    });
  });

  group('days with sales are distinct from days without', () {
    testWidgets('a marked day carries a mark and an unmarked one does not', (
      WidgetTester tester,
    ) async {
      final FakeInvoiceRepository invoices = repositoryWith(
        sales: <Jalali, DaySales>{
          Jalali(1405, 6, 2): DaySales(
            total: Money.rial(9000000),
            invoiceCount: 1,
          ),
          Jalali(1405, 6, 11): DaySales(
            total: Money.rial(4000000),
            invoiceCount: 2,
          ),
        },
      );
      await pumpScreen(
        tester,
        const DailySalesScreen(),
        overrides: overridesFor(invoices),
      );
      await tester.pumpAndSettle();
      final AppStrings strings = stringsOf(tester, DailySalesScreen);

      // The semantics tree is not built in a widget test unless it is asked
      // for, and the point of the mark is that it reaches a screen reader.
      final SemanticsHandle handle = tester.ensureSemantics();

      // Marked days announce themselves, so the distinction is not
      // colour-only and not sighted-only. Two days have sales in Shahrivar;
      // the other twenty-nine must not be marked.
      // A `RegExp`, because the marked cell's node carries the day number too
      // — «۲» and «دارای فروش» merge into one announcement, which is the point:
      // a reader hears which day is marked, not that something is.
      // Scoped to the grid: the empty state's Persian copy explains the mark
      // in words, and would otherwise be counted as one.
      expect(
        find.descendant(
          of: find.byType(JalaliMonthGrid),
          matching: find.bySemanticsLabel(RegExp(strings.dailySalesMarkedDay)),
        ),
        findsNWidgets(2),
      );

      // And the legend says on screen what the mark means, rather than
      // leaving the user to infer it.
      expect(find.text(strings.dailySalesLegend), findsOneWidget);
      handle.dispose();
    });

    testWidgets('no marks at all when the month has no sales', (
      WidgetTester tester,
    ) async {
      final FakeInvoiceRepository invoices = repositoryWith();
      await pumpScreen(
        tester,
        const DailySalesScreen(),
        overrides: overridesFor(invoices),
      );
      await tester.pumpAndSettle();
      final AppStrings strings = stringsOf(tester, DailySalesScreen);
      final SemanticsHandle handle = tester.ensureSemantics();

      expect(find.byType(JalaliMonthGrid), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(JalaliMonthGrid),
          matching: find.bySemanticsLabel(RegExp(strings.dailySalesMarkedDay)),
        ),
        findsNothing,
      );
      handle.dispose();
    });
  });

  group("the selected day's figures", () {
    testWidgets('open on today, and show its total and count', (
      WidgetTester tester,
    ) async {
      final FakeInvoiceRepository invoices = repositoryWith(
        sales: <Jalali, DaySales>{
          today: DaySales(total: Money.rial(12000000), invoiceCount: 3),
        },
        invoices: <InvoiceListItem>[
          item('a', issued: DateTime.utc(2026, 8, 24, 9)),
        ],
      );
      await pumpScreen(
        tester,
        const DailySalesScreen(),
        overrides: overridesFor(invoices),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      // 12,000,000 Rial is 1,200,000 Toman, through AmountText like every
      // other money figure in the application.
      expect(find.byType(StatTile), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(StatTile),
          matching: find.byType(AmountText),
        ),
        findsOneWidget,
      );
      expect(find.text('۱٬۲۰۰٬۰۰۰'), findsOneWidget);
      // Scoped to the tile: «۳» is also a day number in the calendar beside it.
      expect(
        find.descendant(of: find.byType(StatTile), matching: find.text('۳')),
        findsOneWidget,
      );

      // The day is named on the caption, so the figure carries its own scope
      // rather than depending on the calendar beside it.
      expect(find.text('۲ شهریور ۱۴۰۵'), findsWidgets);
    });

    testWidgets('picking another day moves the figures to it', (
      WidgetTester tester,
    ) async {
      final FakeInvoiceRepository invoices = repositoryWith(
        sales: <Jalali, DaySales>{
          today: DaySales(total: Money.rial(12000000), invoiceCount: 3),
          Jalali(1405, 6, 11): DaySales(
            total: Money.rial(50000000),
            invoiceCount: 1,
          ),
        },
      );
      await pumpScreen(
        tester,
        const DailySalesScreen(),
        overrides: overridesFor(invoices),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();
      expect(find.text('۱٬۲۰۰٬۰۰۰'), findsOneWidget);

      await tester.tap(find.text('۱۱'));
      await tester.pumpAndSettle();

      // 50,000,000 Rial is 5,000,000 Toman.
      expect(find.text('۵٬۰۰۰٬۰۰۰'), findsOneWidget);
      expect(find.text('۱٬۲۰۰٬۰۰۰'), findsNothing);
      expect(invoices.dailySalesQueries.last, jalaliDay(Jalali(1405, 6, 11)));
    });

    testWidgets('a day with nothing shows the designed empty state', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const DailySalesScreen(),
        overrides: overridesFor(repositoryWith()),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, DailySalesScreen);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(strings.dailySalesEmptyTitle), findsOneWidget);
      expect(
        find.descendant(of: find.byType(StatTile), matching: find.text('۰')),
        findsNWidgets(2),
        reason: 'a day with nothing reads zero, not blank',
      );
    });
  });

  group('the day list is the invoices the figure is the sum of', () {
    testWidgets('filtered in SQL by the same day and the same statuses', (
      WidgetTester tester,
    ) async {
      final FakeInvoiceRepository invoices = repositoryWith(
        invoices: <InvoiceListItem>[
          item('a', issued: DateTime.utc(2026, 8, 24, 9)),
        ],
      );
      await pumpScreen(
        tester,
        const DailySalesScreen(),
        overrides: overridesFor(invoices),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      expect(invoices.lastFilter, isNotNull);
      expect(invoices.lastFilter!.period, jalaliDay(today));
      expect(
        invoices.lastFilter!.statuses,
        <InvoiceStatus>{
          InvoiceStatus.unpaid,
          InvoiceStatus.partiallyPaid,
          InvoiceStatus.paid,
        },
        reason:
            'drafts and cancellations are excluded, exactly as D-039 has '
            'them excluded from the figure above the list',
      );

      // The same rows the invoice list draws, for the reason the dashboard
      // reuses them.
      expect(find.byType(InvoiceTableRow), findsOneWidget);
      expect(find.text('مریم احمدی'), findsOneWidget);
    });

    testWidgets('mobile shows cards, not a squeezed table', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const DailySalesScreen(),
        overrides: overridesFor(
          repositoryWith(
            invoices: <InvoiceListItem>[
              item('a', issued: DateTime.utc(2026, 8, 24, 9)),
            ],
          ),
        ),
        size: kMobileSize,
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.byType(InvoiceCard), 200);
      expect(find.byType(InvoiceCard), findsOneWidget);
    });
  });
}
