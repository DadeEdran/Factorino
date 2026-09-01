import 'dart:io';

import 'package:factorino/core/formatting/number_display.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/theme/app_theme.dart';
import 'package:factorino/core/widgets/search_field.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/invoice_draft.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/features/invoices/presentation/invoices_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'device_assertions.dart';

/// The invoice **list**, its filters and the picker they open, on the real
/// target — Phase 5 (f), and the gap (e) closed by naming rather than by
/// covering.
///
/// **Why this file exists.** `integration_test/` had two suites, the invoice
/// form and the invoice detail screen, and the list had neither — so everything
/// increment (e) built (the filter control and its count, the sheet and its
/// chips, the filtered empty state, the picker reached from inside a sheet) had
/// been checked at three tiers in widget tests and had never once rendered in
/// Vazirmatn on a phone. A widget test renders with a fallback font whose glyphs
/// are wider than Vazirmatn's, so it is conservative about width and silent
/// about everything else a real font, a real modal route and a real soft
/// keyboard do.
///
/// **The three things it proves that the widget sweep cannot:**
///
/// 1. **A sheet opened from inside another sheet still obeys the keyboard
///    rule** (D-062). The customer picker is reached from the filter sheet, so
///    it is a modal route stacked on a modal route, and its search field is the
///    control the user types into while the keyboard is up. The widget sweep
///    opens the picker from a bare host screen; this opens it the way the
///    application does, and [raiseKeyboard] raises the **real** keyboard rather
///    than injecting text into the engine behind its back.
/// 2. **A narrowing that returns nothing shows the filtered empty state**, not
///    «هنوز فاکتوری ثبت نشده» — which would be false for a user with six
///    invoices and would send them looking for lost data instead of at the chips
///    they just tapped (D-063 §4).
/// 3. **The list holds at every rung of the amount ladder** (D-057), on the
///    target's own metrics, with all four on screen at once.
///
/// **It filters against real SQL.** The invoices are seeded through the real
/// repositories into the real encrypted database, and every assertion about
/// what a filter returned is an assertion about what came back from a `WHERE`
/// clause — which is the property D-063 exists to hold down, since a filter
/// applied in Dart would narrow a page rather than page a narrowed set.
///
/// Uses a probe database, so running it never touches the real one.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// The ladder, restated rather than imported, for the reason
  /// `invoice_detail_device_test.dart` records: `integration_test/` does not see
  /// `test/`, and duplicating four integers beats moving the ladder into `lib/`,
  /// where it is not application code. If these ever disagree with
  /// `kMoneyStressToman`, that is a reason to fix it rather than to shrug.
  const List<int> stressToman = <int>[100000, 1000000, 10000000, 100000000];

  /// The party on most of the invoices, and the one the filters narrow away.
  const String busyCustomer = 'مریم احمدی‌نژاد';

  /// One invoice, a Jalali year back, so the period filter has something to
  /// exclude that is genuinely outside the range rather than merely last in the
  /// ordering.
  const String oldCustomer = 'شرکت مهندسی و بازرگانی نمونهٔ ایرانیان';

  final List<String> layoutErrors = <String>[];

  testWidgets('the list, its filters and the picker they open, on the target', (
    WidgetTester tester,
  ) async {
    // Collected rather than left to the default handler: an overflow in an
    // integration test prints a red band and carries on, so the run would pass
    // with content the user cannot see -- which is the exact defect this is
    // here to catch.
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final String message = details.exceptionAsString();
      if (message.contains('overflowed')) layoutErrors.add(message);
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    // ---- a probe database, through the production bootstrap ---------------
    final File file = await defaultDatabaseFile(name: 'list_probe.db');
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

    // ---- the fixture: every rung, two customers, three statuses -----------
    final Customer busy = await container
        .read(customerRepositoryProvider)
        .create(
          const CustomerDraft(
            fullName: busyCustomer,
            companyName: 'کارگاه نمونهٔ تهران',
            mobile: '09121234567',
          ),
        );
    final Customer old = await container
        .read(customerRepositoryProvider)
        .create(
          const CustomerDraft(
            fullName: oldCustomer,
            companyName: 'واحد پشتیبانی و خدمات پس از فروش',
          ),
        );

    final DateTime now = DateTime.now().toUtc();

    Future<void> seed({
      required String customerId,
      required int toman,
      required DateTime issued,
      required InvoiceStatus status,
    }) async {
      await container
          .read(invoiceRepositoryProvider)
          .create(
            InvoiceDraft(
              customerId: customerId,
              issueDate: issued,
              dueDate: issued.add(const Duration(days: 30)),
              items: <InvoiceItemDraft>[
                InvoiceItemDraft(
                  title: 'مشاورهٔ فنی و مهندسی',
                  unit: 'ساعت',
                  unitPrice: Money.rial(toman * 10),
                  quantityMilli: 1000,
                ),
              ],
            ),
            status: status,
          );
    }

    // Four issued invoices, one per rung, in the current Jalali month. All four
    // are on screen together further down, which is the D-057 sweep: a card
    // that fits at 100,000 تومان and breaks at 100,000,000 is invisible to a
    // check that renders one amount.
    for (final int toman in stressToman) {
      await seed(
        customerId: busy.id,
        toman: toman,
        issued: now,
        status: InvoiceStatus.unpaid,
      );
    }

    // A draft, so «پیش‌نویس» is a status the filter can actually select -- and,
    // combined with the other customer, a narrowing that matches nothing.
    await seed(
      customerId: busy.id,
      toman: stressToman.first,
      issued: now,
      status: InvoiceStatus.draft,
    );

    // And one a Jalali year back, for the period filter. 400 days rather than
    // 365: a Jalali year is 365 or 366 days and «امسال» must not be able to
    // reach it on either.
    await seed(
      customerId: old.id,
      toman: stressToman.last,
      issued: now.subtract(const Duration(days: 400)),
      status: InvoiceStatus.unpaid,
    );

    // ---- the real screen, in the real shell -------------------------------
    final GoRouter router = GoRouter(
      initialLocation: '/invoices',
      routes: <RouteBase>[
        GoRoute(
          path: '/invoices',
          // A `Scaffold`, because `AdaptiveScaffold` is what supplies one in
          // the real shell and the screen expects a `Material` ancestor for its
          // ink. Standing the screen up without one is a harness fault, not an
          // application one.
          builder: (_, _) =>
              const Scaffold(body: SafeArea(child: InvoicesScreen())),
        ),
        GoRoute(
          path: '/invoices/new',
          builder: (_, _) => const SizedBox.shrink(),
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

    final BuildContext screen = tester.element(find.byType(InvoicesScreen));
    final AppStrings strings = AppStrings.of(screen);
    final Size size = MediaQuery.sizeOf(screen);

    debugPrint('=== PHASE 5 (f) INVOICE LIST ON DEVICE ===');
    debugPrint('platform      : ${Platform.operatingSystem}');
    debugPrint('logical size  : ${size.width} x ${size.height}');
    debugPrint('pixel ratio   : ${tester.view.devicePixelRatio}');
    debugPrint('16sp renders  : ${MediaQuery.textScalerOf(screen).scale(16)}');

    /// The active-filter label, with the count in Persian digits as the control
    /// renders it. Built through the same formatter rather than written out,
    /// because a hard-coded «۱ فیلتر فعال» would keep passing after somebody
    /// changed how the count is formatted (§9).
    String activeLabel(int count) =>
        strings.invoiceFilterActiveLabel(formatGroupedPersian(count));

    // ---- unfiltered: every rung, laid out at the target's own metrics ------
    //
    // Scrolled through rather than asserted where the page opens: a lazy list
    // never lays out a row it did not build, so a list checked only at its first
    // viewport is a list whose widest row went unchecked -- and the widest row
    // is the one the ladder exists for.
    await reach(tester, find.text(oldCustomer));
    expect(
      find.text(oldCustomer),
      findsOneWidget,
      reason: 'the unfiltered list must hold every invoice, oldest included',
    );
    debugPrint('unfiltered    : both customers rendered, ladder laid out');

    // No column crushed by the fixed money column beside it (D-065). The list's
    // table is the other place in the application where prose shares a row with
    // a fixed-width amount.
    expectNoCrushedText(tester, where: 'the invoice list');

    expect(
      find.text(strings.invoiceFilterAction),
      findsOneWidget,
      reason: 'the filter control sits in the title row at every tier',
    );

    // ---- the sheet, and the picker it opens -------------------------------
    await tester.tap(find.text(strings.invoiceFilterAction));
    await tester.pumpAndSettle();

    // Scoped to the sheet: at the desktop tier «وضعیت» is also the invoice
    // table's status column header behind it, so an unscoped finder reports two
    // and fails a sheet that is laid out perfectly well.
    Finder inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet).last,
      matching: find.text(text),
    );

    expect(inSheet(strings.invoiceFilterStatusSection), findsOneWidget);
    expect(inSheet(strings.invoiceFilterCustomerSection), findsOneWidget);
    expect(inSheet(strings.invoiceFilterPeriodSection), findsOneWidget);
    expect(
      find.byType(FilterChip),
      findsNWidgets(5),
      reason:
          'the five **stored** statuses. «سررسید گذشته» is derived at display '
          'time and is deliberately not a filter (D-063)',
    );

    await tester.tap(find.text(strings.invoiceFilterCustomerChoose));
    await tester.pumpAndSettle();

    // **The keyboard rule, on a sheet opened from a sheet** (D-062). The picker
    // does not take `EditorSheet` and should not -- it commits by tapping a row,
    // so the list is its action -- but the control the user types into has to
    // stay inside the space the keyboard leaves, with the list beneath it taking
    // the loss. On Android [expectActionAboveKeyboard] refuses an assertion made
    // against a keyboard that never came up.
    final Finder search = find.byType(SearchField);
    final double inset = await raiseKeyboard(tester, search);
    debugPrint('picker keybd  : ${inset.toStringAsFixed(1)}');
    expectActionAboveKeyboard(
      tester,
      search,
      sheet: 'customer picker, opened from the filter sheet',
    );

    // A `ListTile` only exists inside the picker: the list behind it is cards on
    // the narrow tiers and table rows on the desktop one, so this cannot match
    // the screen underneath by accident.
    await tester.tap(find.widgetWithText(ListTile, oldCustomer));
    await tester.pumpAndSettle();

    expect(
      inSheet(oldCustomer),
      findsOneWidget,
      reason:
          'the chip must say which customer was chosen, not just that one was',
    );

    await tester.tap(find.text(strings.invoiceFilterApply));
    await tester.pumpAndSettle();

    // ---- the customer filter reached SQL ----------------------------------
    expect(
      find.text(activeLabel(1)),
      findsOneWidget,
      reason:
          'a control that looks identical filtered and unfiltered is how a user '
          'concludes the application lost their invoices (D-063 §4)',
    );
    expect(
      find.text(busyCustomer),
      findsNothing,
      reason:
          'the other customer\'s five invoices must be gone, not merely '
          'further down the page',
    );
    expect(find.text(oldCustomer), findsOneWidget);
    debugPrint('by customer   : narrowed to one invoice, count shown');

    // ---- a narrowing that matches nothing ---------------------------------
    //
    // This customer has one invoice and it is `unpaid`, so «پیش‌نویس» on top of
    // it returns nothing -- while six invoices sit in the database. That is
    // exactly the state in which "you have no invoices yet" would be a lie.
    await tester.tap(find.text(activeLabel(1)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, strings.statusDraft));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.invoiceFilterApply));
    await tester.pumpAndSettle();

    expect(
      find.text(strings.emptyInvoicesFilteredTitle),
      findsOneWidget,
      reason: 'a filtered empty list is its own state (D-063 §4)',
    );
    expect(
      find.text(strings.emptyInvoicesTitle),
      findsNothing,
      reason:
          '«هنوز فاکتوری ثبت نشده» is false for a user with six invoices, and '
          'it sends them looking for lost data instead of at the chips they '
          'just tapped',
    );
    final Finder clearAll = find.widgetWithText(
      FilledButton,
      strings.invoiceFilterClearAll,
    );
    expect(
      clearAll,
      findsOneWidget,
      reason:
          'the way out of this state is not "make an invoice" -- the invoices '
          'exist, the filter is hiding them',
    );
    debugPrint('empty filtered: own state, offering «پاک کردن همه»');

    await tester.tap(clearAll);
    await tester.pumpAndSettle();

    expect(
      find.text(strings.invoiceFilterAction),
      findsOneWidget,
      reason: 'clearing puts the control back to its unfiltered label',
    );
    await reach(tester, find.text(oldCustomer));
    expect(find.text(oldCustomer), findsOneWidget);

    // ---- the period filter is Jalali, and it reaches SQL too --------------
    await tester.tap(find.text(strings.invoiceFilterAction));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ChoiceChip, strings.invoiceFilterPeriodThisMonth),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.invoiceFilterApply));
    await tester.pumpAndSettle();

    expect(find.text(activeLabel(1)), findsOneWidget);
    expect(
      find.text(oldCustomer),
      findsNothing,
      reason:
          'an invoice issued a Jalali year ago is outside «این ماه», and the '
          'boundary was computed in the Jalali calendar rather than by '
          'subtracting a span (D-006, jalaliMonthShifted)',
    );
    await reach(tester, find.text(busyCustomer));
    expect(
      find.text(busyCustomer),
      findsWidgets,
      reason: 'and this month\'s invoices are still there',
    );
    debugPrint('by period     : this Jalali month, the year-old one excluded');

    // ---- back to everything, and scroll the whole page --------------------
    await tester.tap(find.text(activeLabel(1)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.invoiceFilterClearAll));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.invoiceFilterApply));
    await tester.pumpAndSettle();

    for (final Element element in find.byType(ListView).evaluate().toList()) {
      for (int step = 0; step < 12; step++) {
        await tester.drag(find.byWidget(element.widget), const Offset(0, -300));
        await tester.pumpAndSettle();
      }
    }

    debugPrint('layout errors : ${layoutErrors.length}');
    for (final String error in layoutErrors) {
      debugPrint('  ! ${error.split('\n').first}');
    }
    expect(
      layoutErrors,
      isEmpty,
      reason:
          'a layout overflow on the device is content the user cannot see, and '
          'it prints a red band and carries on rather than failing anything',
    );
  });
}
