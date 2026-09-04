import 'dart:io';

import 'package:factorino/core/date/jalali_instant.dart';
import 'package:factorino/core/date/jalali_period.dart';
import 'package:factorino/core/formatting/persian_text.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/theme/app_theme.dart';
import 'package:factorino/core/widgets/jalali_month_grid.dart';
import 'package:factorino/core/widgets/stat_tile.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/daily_sales.dart';
import 'package:factorino/data/models/invoice_draft.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/features/dashboard/presentation/daily_sales_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'device_assertions.dart';

/// «فروش روزانه» on the real target, against real encrypted SQL.
///
/// **What only this can check.** The calendar's marks and the day's total come
/// from a `GROUP BY` on an expression — `(issue_date + offset) / 86400000` —
/// and a widget test answers that from a fake. Nothing below the repository
/// interface is exercised until the statement actually runs in SQLite, and the
/// two things most likely to be wrong about it are exactly the two SQLite
/// decides: whether `/` on two integers truncates the way Dart's `~/` does,
/// and whether a `GROUP BY` over a bound-variable expression binds it the same
/// way in both the projection and the grouping clause. A wrong answer to
/// either puts a day's sales under the wrong date, and nothing on the screen
/// would look broken.
///
/// So the fixture is seeded **across a Tehran midnight**: two invoices three
/// hours apart, on the same UTC date and on different Iranian days. If the
/// grouping is done on the raw stored instant they land on one day, and this
/// fails.
///
/// It also runs the amount ladder (D-057) through the day tile, because the
/// day's total is a money site with a fixed neighbour and no other check
/// renders it on the target's own metrics.
///
/// Uses a probe database, so running it never touches the real one.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// The ladder, restated rather than imported, for the reason the other device
  /// suites record: `integration_test/` does not see `test/`, and duplicating
  /// four integers beats moving the ladder into `lib/`, where it is not
  /// application code.
  const List<int> stressToman = <int>[100000, 1000000, 10000000, 100000000];

  final List<String> layoutErrors = <String>[];

  testWidgets('the day view, its calendar and its grouped SQL, on the target', (
    WidgetTester tester,
  ) async {
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final String message = details.exceptionAsString();
      if (message.contains('overflowed')) layoutErrors.add(message);
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    // ---- a probe database, through the production bootstrap ---------------
    final File file = await defaultDatabaseFile(name: 'daily_probe.db');
    for (final String suffix in <String>['', '-wal', '-shm']) {
      final File stale = File('${file.path}$suffix');
      if (stale.existsSync()) stale.deleteSync();
    }
    final AppDatabase db = await openAppDatabase(file: file);
    addTearDown(() async {
      await db.close();
      for (final String suffix in <String>['', '-wal', '-shm']) {
        final File probe = File('${file.path}$suffix');
        if (probe.existsSync()) probe.deleteSync();
      }
    });

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final Customer customer = await container
        .read(customerRepositoryProvider)
        .create(
          const CustomerDraft(
            fullName: 'مریم احمدی‌نژاد',
            companyName: 'کارگاه نمونه تهران',
            mobile: '09121234567',
          ),
        );

    Future<void> seed({
      required int toman,
      required DateTime issued,
      InvoiceStatus status = InvoiceStatus.unpaid,
    }) async {
      await container
          .read(invoiceRepositoryProvider)
          .create(
            InvoiceDraft(
              customerId: customer.id,
              issueDate: issued,
              items: <InvoiceItemDraft>[
                InvoiceItemDraft(
                  title: 'مشاوره فنی و مهندسی',
                  unit: 'ساعت',
                  unitPrice: Money.rial(toman * 10),
                  quantityMilli: 1000,
                ),
              ],
            ),
            status: status,
          );
    }

    // The Jalali day the run happens on, and the two either side of it inside
    // the same Jalali month — resolved from the clock rather than written out,
    // because the screen opens on today and today is whenever this is run.
    final Jalali today = jalaliAt(DateTime.now().toUtc());
    final Jalali anchor = today.day >= 3 && today.day <= 26
        ? today
        // Near a month edge, work from a day with room either side, so the
        // fixture never needs the previous or next month on screen.
        : Jalali(today.year, today.month, 10);

    /// Noon Tehran on a Jalali day — well inside it, so an off-by-one grouping
    /// fails rather than passing on a boundary.
    DateTime noonOn(Jalali day) =>
        startOfJalaliDayUtc(day).add(const Duration(hours: 12));

    // The whole ladder on one day, so the day tile is rendered at every rung.
    for (final int toman in stressToman) {
      await seed(toman: toman, issued: noonOn(anchor));
    }

    // A second day with sales, two days along, so "which days are marked" has
    // more than one answer and the gaps between are real.
    await seed(toman: stressToman[1], issued: noonOn(anchor.addDays(2)));

    // A draft on the day between, which must NOT mark it (D-039).
    await seed(
      toman: stressToman[2],
      issued: noonOn(anchor.addDays(1)),
      status: InvoiceStatus.draft,
    );

    // **The Tehran-midnight pair.** 20:30 UTC is exactly midnight Tehran, so
    // 20:00 and 21:00 UTC are half an hour either side of it: the same UTC
    // date, two different Iranian days. Placed on the day after the draft so
    // it has a day of its own to land on.
    final Jalali crossing = anchor.addDays(3);
    final DateTime tehranMidnight = startOfJalaliDayUtc(crossing.addDays(1));
    await seed(
      toman: stressToman[0],
      issued: tehranMidnight.subtract(const Duration(minutes: 30)),
    );
    await seed(
      toman: stressToman[0],
      issued: tehranMidnight.add(const Duration(minutes: 30)),
    );

    // ---- what the SQL itself says, before any widget renders it -----------
    final DailySales month = await container
        .read(invoiceRepositoryProvider)
        .watchDailySales(jalaliMonth(anchor.year, anchor.month))
        .first;

    debugPrint('=== DAILY SALES ON DEVICE ===');
    debugPrint('platform      : ${Platform.operatingSystem}');
    debugPrint('anchor day    : ${anchor.year}/${anchor.month}/${anchor.day}');
    debugPrint('active days   : ${month.activeDayCount}');

    expect(
      month.on(anchor).invoiceCount,
      stressToman.length,
      reason: 'the four ladder invoices group onto the anchor day',
    );
    expect(month.hasSales(anchor.addDays(1)), isFalse, reason: 'a draft only');
    expect(month.hasSales(anchor.addDays(2)), isTrue);

    // The pair that straddles Tehran midnight must be two days, not one. This
    // is the assertion the whole file is built around.
    expect(
      month.on(crossing).invoiceCount,
      1,
      reason: '20:00 UTC is 23:30 Tehran and belongs to $crossing',
    );
    expect(
      month.on(crossing.addDays(1)).invoiceCount,
      1,
      reason: '21:00 UTC is 00:30 Tehran and belongs to the NEXT Iranian day',
    );
    expect(
      tehranMidnight.subtract(const Duration(minutes: 30)).toUtc().day,
      tehranMidnight.add(const Duration(minutes: 30)).toUtc().day,
      reason: 'and both are stored on the same UTC date, which is the trap',
    );
    debugPrint('midnight pair : split across two Iranian days, from real SQL');

    // And the days of the month reconcile with the month's own total — the two
    // readings the dashboard and this screen each show.
    expect(
      month.total.rial,
      await container
          .read(invoiceRepositoryProvider)
          .totalIssuedRial(jalaliMonth(anchor.year, anchor.month)),
    );
    debugPrint('reconciles    : days sum to the month total');

    // ---- the real screen --------------------------------------------------
    final GoRouter router = GoRouter(
      initialLocation: '/day',
      routes: <RouteBase>[
        GoRoute(
          path: '/day',
          builder: (_, _) =>
              const Scaffold(body: SafeArea(child: DailySalesScreen())),
        ),
        GoRoute(
          path: '/invoices/:id',
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('fa'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
          builder: (BuildContext context, Widget? child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final BuildContext screen = tester.element(find.byType(DailySalesScreen));
    final AppStrings strings = AppStrings.of(screen);
    final Size size = MediaQuery.sizeOf(screen);
    debugPrint('logical size  : ${size.width} x ${size.height}');
    debugPrint('pixel ratio   : ${tester.view.devicePixelRatio}');

    expect(find.byType(JalaliMonthGrid), findsOneWidget);
    expect(find.text(strings.dailySalesLegend), findsOneWidget);
    expect(find.byType(StatTile), findsNWidgets(2));

    // The marks, counted on the rendered tree. Three days in this month have
    // issued invoices: the anchor, the anchor plus two, and — unless the
    // crossing pair spills into the next month — the two crossing days.
    final SemanticsHandle handle = tester.ensureSemantics();
    final int marked = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(JalaliMonthGrid),
            matching: find.byType(Semantics),
          ),
        )
        .where(
          (Semantics s) => s.properties.label == strings.dailySalesMarkedDay,
        )
        .length;
    handle.dispose();
    expect(
      marked,
      month.activeDayCount,
      reason: 'every day the query says has sales carries a mark, and no other',
    );
    debugPrint('marks         : $marked, matching the query exactly');

    // ---- the ladder, on the day tile, on the target's own metrics ---------
    //
    // The whole ladder is on the anchor day, so selecting it puts the largest
    // rung's sum — 111,100,000 تومان — on a tile that sits beside a count.
    await tester.tap(
      find.descendant(
        of: find.byType(JalaliMonthGrid),
        matching: find.text(toPersianDigits('${anchor.day}')),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(StatTile),
        matching: find.text(toPersianDigits('${stressToman.length}')),
      ),
      findsOneWidget,
      reason: 'the count tile shows the four invoices on the anchor day',
    );
    expectNoCrushedText(tester, where: 'the daily sales screen');
    debugPrint('ladder        : the day total laid out at every rung');

    // ---- a day with nothing -----------------------------------------------
    await tester.tap(
      find.descendant(
        of: find.byType(JalaliMonthGrid),
        matching: find.text(toPersianDigits('${anchor.addDays(1).day}')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(strings.dailySalesEmptyTitle),
      findsOneWidget,
      reason: 'a day holding only a draft has no sales, and says so',
    );
    expectNoCrushedText(tester, where: 'the daily sales empty state');

    expect(
      layoutErrors,
      isEmpty,
      reason:
          'overflows on the daily sales screen:\n${layoutErrors.join('\n')}',
    );
    debugPrint('layout errors : ${layoutErrors.length}');
  });
}
