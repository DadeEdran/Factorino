import 'dart:async';

import 'package:factorino/core/date/jalali_instant.dart';
import 'package:factorino/core/date/jalali_period.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/utils/clock.dart';
import 'package:factorino/core/widgets/amount_text.dart';
import 'package:factorino/core/widgets/app_table.dart';
import 'package:factorino/core/widgets/empty_state.dart';
import 'package:factorino/core/widgets/skeleton.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_list_item.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/customer_repository.dart';
import 'package:factorino/features/dashboard/presentation/dashboard_screen.dart';
import 'package:factorino/core/widgets/stat_tile.dart';
import 'package:factorino/features/invoices/presentation/invoices_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../invoices/fake_invoice_repository.dart';
import '../screen_harness.dart';

/// The dashboard, on real repository reads.
///
/// The two things this file exists to hold down are the ones that would be
/// wrong without looking wrong: that the period is a **Jalali** month, and that
/// every figure on screen is one the data layer produced rather than one the
/// widget worked out.
void main() {
  /// 24 August 2026, 06:00 UTC — which is 2 Shahrivar 1405 in Tehran. Chosen
  /// because the Jalali month it falls in (Shahrivar) and the Gregorian one
  /// (August) have completely different boundaries, so a Gregorian period
  /// cannot accidentally pass these tests.
  final DateTime now = DateTime.utc(2026, 8, 24, 6);

  InvoiceListItem item(String id, {required String liveCustomerName}) {
    final DateTime issued = DateTime.utc(2026, 8, 20, 6);
    return InvoiceListItem(
      liveCustomerName: liveCustomerName,
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
        // Deliberately not the same figure as any tile, so an assertion on a
        // tile's amount cannot be satisfied by the row beneath it.
        grandTotal: Money.rial(9000000),
        createdAt: issued,
        updatedAt: issued,
      ),
    );
  }

  List<Override> overridesFor(
    FakeInvoiceRepository invoices,
    _FakeCustomerRepository customers,
  ) {
    return <Override>[
      invoiceRepositoryProvider.overrideWithValue(invoices),
      customerRepositoryProvider.overrideWithValue(customers),
      nowProvider.overrideWithValue(now),
    ];
  }

  group('the reporting period is Jalali', () {
    testWidgets('the aggregates are asked for the Jalali month, not August', (
      WidgetTester tester,
    ) async {
      // D-006, and the single most consequential thing on this screen. Shahrivar
      // 1405 runs 23 August to 22 September 2026; a Gregorian August period
      // would start on the 1st. The assertion is on the range the repository
      // was handed, so it holds whatever the screen renders.
      final FakeInvoiceRepository invoices = FakeInvoiceRepository(
        <InvoiceListItem>[item('a', liveCustomerName: 'مریم احمدی')],
        issuedTotalRial: 12000000,
        issuedCount: 1,
      );
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(invoices, _FakeCustomerRepository(1)),
      );
      await tester.pumpAndSettle();

      expect(invoices.lastPeriod, isNotNull);
      expect(invoices.issuedTotalPeriods, contains(jalaliMonthOf(now)));
      // Belt and braces: the same range, named explicitly, so this test still
      // means something if `jalaliMonthOf` is ever the thing that broke.
      expect(invoices.issuedTotalPeriods, contains(jalaliMonth(1405, 6)));
      expect(jalaliMonth(1405, 6).contains(now), isTrue);
    });

    testWidgets('the week is شنبه to جمعه, and the year is Farvardin-based', (
      WidgetTester tester,
    ) async {
      // The two new periods, asserted on the ranges the repository was handed
      // rather than on what the tiles render — the same reason the month
      // assertion above is written that way.
      //
      // `now` is 1405/06/02, a دوشنبه — the *third* day of the Iranian week —
      // so the week under test starts two days earlier, on شنبه 1405/05/31,
      // and runs through جمعه 1405/06/06. It crosses a month boundary, which
      // is the case worth pinning: Mordad has 31 days and Shahrivar starts the
      // next, and a week computed by subtracting a fixed number of days from
      // the month's first would land in the wrong month here. A Monday-start
      // week would begin a day later and a rolling seven-day window six days
      // earlier; both would still look like a plausible figure on the tile,
      // which is why this is pinned to exact instants.
      final FakeInvoiceRepository invoices = FakeInvoiceRepository(
        <InvoiceListItem>[item('a', liveCustomerName: 'مریم احمدی')],
      );
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(invoices, _FakeCustomerRepository(1)),
      );
      await tester.pumpAndSettle();

      expect(jalaliAt(now).weekDay, 3, reason: 'دوشنبه, the third day');
      expect(
        invoices.issuedTotalPeriods,
        contains(
          InstantRange(
            startOfJalaliDayUtc(Jalali(1405, 5, 31)),
            startOfJalaliDayUtc(Jalali(1405, 6, 7)),
          ),
        ),
        reason: 'the week runs شنبه 1405/05/31 to جمعه 1405/06/06 inclusive',
      );
      expect(
        invoices.issuedTotalPeriods,
        contains(jalaliYear(1405)),
        reason: 'the year is Farvardin to Farvardin, not January to January',
      );
    });

    testWidgets('the period tiles name the Jalali month on screen', (
      WidgetTester tester,
    ) async {
      // "این ماه" alone asks the user to trust that the app means the month
      // they mean. Naming it is what makes the figure checkable.
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(
          FakeInvoiceRepository(
            <InvoiceListItem>[item('a', liveCustomerName: 'مریم احمدی')],
            issuedTotalRial: 12000000,
            issuedCount: 1,
          ),
          _FakeCustomerRepository(1),
        ),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, DashboardScreen);
      expect(find.text('${strings.monthShahrivar} ۱۴۰۵'), findsWidgets);
    });
  });

  group('the figures come from the data layer', () {
    testWidgets('each tile shows the repository figure, through AmountText', (
      WidgetTester tester,
    ) async {
      // **Three different figures for the three periods**, so the tiles cannot
      // pass by all reading the same query. Week is inside month is inside
      // year, so the amounts ascend the way real ones would.
      final FakeInvoiceRepository invoices =
          FakeInvoiceRepository(
              <InvoiceListItem>[item('a', liveCustomerName: 'مریم احمدی')],
              issuedCount: 3,
              outstandingRial: 5000000,
            )
            ..issuedTotalByPeriod = <InstantRange, int>{
              jalaliWeekOf(now): 3000000,
              jalaliMonthOf(now): 12000000,
              jalaliYearOf(now): 90000000,
            };

      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(invoices, _FakeCustomerRepository(7)),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, DashboardScreen);
      expect(find.byType(StatTile), findsNWidgets(6));
      expect(find.text(strings.dashboardSalesThisWeek), findsOneWidget);
      expect(find.text(strings.dashboardSalesThisMonth), findsOneWidget);
      expect(find.text(strings.dashboardSalesThisYear), findsOneWidget);
      expect(find.text(strings.dashboardInvoiceCount), findsOneWidget);
      expect(find.text(strings.dashboardOutstanding), findsOneWidget);
      expect(find.text(strings.dashboardCustomerCount), findsOneWidget);

      // Money goes through AmountText: Persian digits, Toman, unit label —
      // 3,000,000 Rial is 300,000 Toman, 12,000,000 is 1,200,000, 90,000,000
      // is 9,000,000, and 5,000,000 outstanding is 500,000.
      // Scoped to the tiles, because the recent-invoices row underneath shows
      // an amount too — through the same widget, which is the point.
      expect(
        find.descendant(
          of: find.byType(StatTile),
          matching: find.byType(AmountText),
        ),
        findsNWidgets(4),
      );
      expect(find.text('۳۰۰٬۰۰۰'), findsOneWidget);
      expect(find.text('۱٬۲۰۰٬۰۰۰'), findsOneWidget);
      expect(find.text('۹٬۰۰۰٬۰۰۰'), findsOneWidget);
      expect(find.text('۵۰۰٬۰۰۰'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StatTile),
          matching: find.text(strings.unitToman),
        ),
        findsNWidgets(4),
      );

      // Counts are Persian digits with no unit — a count of invoices under a
      // tile that names them is not ambiguous the way an amount is.
      expect(find.text('۳'), findsOneWidget);
      expect(find.text('۷'), findsOneWidget);
    });

    testWidgets('an outstanding balance is not coloured as a warning', (
      WidgetTester tester,
    ) async {
      // D-033: colour means status in this design. Money never carries it —
      // an outstanding balance is not bad news, it is money on its way, and a
      // red figure would be a judgement the app is not entitled to make.
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(
          FakeInvoiceRepository(<InvoiceListItem>[
            item('a', liveCustomerName: 'مریم احمدی'),
          ], outstandingRial: 5000000),
          _FakeCustomerRepository(1),
        ),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      for (final AmountText amount in tester.widgetList<AmountText>(
        find.byType(AmountText),
      )) {
        expect(amount.color, isNull);
      }
    });

    testWidgets('shows a skeleton, not a spinner, while loading', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(
          FakeInvoiceRepository.pending(),
          _FakeCustomerRepository(0),
        ),
      );
      await tester.pump();

      expect(find.byType(StatTileSkeleton), findsWidgets);
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('surfaces a failure as Persian copy, never as the exception', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(
          FakeInvoiceRepository.failing(
            StateError('SUM(grand_total_rial) -- C:\\Users\\x\\factorino.db'),
          ),
          _FakeCustomerRepository(0),
        ),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, DashboardScreen);
      expect(find.text(strings.errorGenericTitle), findsOneWidget);
      expect(find.textContaining('grand_total_rial'), findsNothing);
      expect(find.textContaining('factorino.db'), findsNothing);
    });
  });

  group('the empty state means empty, not merely invoiceless', () {
    testWidgets('nothing at all shows the designed empty state', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(
          FakeInvoiceRepository(const <InvoiceListItem>[]),
          _FakeCustomerRepository(0),
        ),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, DashboardScreen);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(strings.emptyDashboardTitle), findsOneWidget);
      expect(find.byType(StatTile), findsNothing);
    });

    testWidgets('customers but no invoices still shows the tiles', (
      WidgetTester tester,
    ) async {
      // A user who has entered twenty customers has done real work. Meeting
      // them with "nothing to show yet" would be both wrong and discouraging,
      // and the customer tile has something true to say.
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(
          FakeInvoiceRepository(const <InvoiceListItem>[]),
          _FakeCustomerRepository(20),
        ),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(StatTile), findsNWidgets(6));
      expect(find.text('۲۰'), findsOneWidget);
    });

    testWidgets('the recent-invoices section is absent when there are none', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(
          FakeInvoiceRepository(const <InvoiceListItem>[]),
          _FakeCustomerRepository(20),
        ),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, DashboardScreen);
      expect(find.text(strings.dashboardRecentInvoices), findsNothing);
    });
  });

  group('recent invoices', () {
    testWidgets('reuses the invoice list row widgets', (
      WidgetTester tester,
    ) async {
      // Not a compact variant of its own: an invoice that looks one way here
      // and another way one tap along is two designs to keep in step, and the
      // difference is where a badge or an amount format quietly diverges.
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(
          FakeInvoiceRepository(<InvoiceListItem>[
            item('a', liveCustomerName: 'مریم احمدی'),
          ]),
          _FakeCustomerRepository(1),
        ),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, DashboardScreen);
      expect(find.text(strings.dashboardRecentInvoices), findsOneWidget);
      expect(find.byType(InvoiceTableRow), findsOneWidget);
      expect(find.byType(AppTableHeader), findsOneWidget);
      expect(find.text('مریم احمدی'), findsOneWidget);
    });

    testWidgets('mobile shows cards there too', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(
          FakeInvoiceRepository(<InvoiceListItem>[
            item('a', liveCustomerName: 'مریم احمدی'),
          ]),
          _FakeCustomerRepository(1),
        ),
        size: kMobileSize,
      );
      await tester.pumpAndSettle();

      // **Scrolled to, because on a phone it is below the fold.** Six tiles in
      // one column is roughly a screen and a half before the recent list
      // begins, and the `ListView` does not build what is not on screen — so a
      // finder that did not scroll would report the section missing rather
      // than off-screen. That is a real property of the page, not a test
      // artefact: the tiles are what the dashboard is for, and the recent
      // invoices are a glance below them.
      await tester.scrollUntilVisible(find.byType(InvoiceCard), 200);

      expect(find.byType(InvoiceCard), findsOneWidget);
      expect(find.byType(AppTableHeader), findsNothing);
    });

    testWidgets('"view all" goes to the invoice destination', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(
          FakeInvoiceRepository(<InvoiceListItem>[
            item('a', liveCustomerName: 'مریم احمدی'),
          ]),
          _FakeCustomerRepository(1),
        ),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, DashboardScreen);
      await tester.tap(find.text(strings.actionViewAll));
      await tester.pumpAndSettle();

      expect(lastLocation, '/invoices');
    });
  });
}

/// A [CustomerRepository] that only has to be able to count.
class _FakeCustomerRepository implements CustomerRepository {
  _FakeCustomerRepository(this._count);

  final int _count;

  @override
  Stream<int> watchCount() => Stream<int>.value(_count);

  @override
  Future<int> count() async => _count;

  @override
  Stream<List<Customer>> watchAll({int limit = 100, int offset = 0}) =>
      Stream<List<Customer>>.value(const <Customer>[]);

  @override
  Stream<List<Customer>> watchSearch(
    String term, {
    int limit = 100,
    int offset = 0,
  }) => Stream<List<Customer>>.value(const <Customer>[]);

  @override
  Future<List<Customer>> search(
    String term, {
    int limit = 100,
    int offset = 0,
  }) async => const <Customer>[];

  @override
  Future<Customer?> findById(String id) async => null;

  @override
  Future<Customer> create(CustomerDraft draft) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Future<Customer> update(String id, CustomerDraft draft) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Future<void> softDelete(String id) async {}
}
