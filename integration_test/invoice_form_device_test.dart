import 'dart:io';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/theme/app_theme.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/product.dart';
import 'package:factorino/data/models/product_type.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/features/invoices/presentation/invoice_editor_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

/// The assembled invoice form, on the real phone — Phase 4 (d).
///
/// **Why this exists when there are already sixteen widget tests for it.** A
/// widget test renders at a size the test chose, with a fallback font whose
/// glyphs are wider than Vazirmatn's, and with no keyboard. This runs at the
/// device's own resolution and text scale, in Vazirmatn, through the real
/// modal sheets — which is where a numeric-heavy form on a phone actually goes
/// wrong: a sheet that does not fit above the keyboard, a field that scrolls
/// under it, a grid that clips at 360 logical pixels.
///
/// **It is not a substitute for a person using it.** Synthetic taps never miss,
/// never hesitate, and never try the thing nobody designed for. What this can
/// do is fail loudly on the faults a person would find slowly — every layout
/// overflow raised anywhere in the run is collected and reported at the end —
/// and print the metrics the layout was judged against, so the manual pass
/// starts from facts rather than from an impression.
///
/// Uses a probe database, so running it never touches the real one.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Every layout error Flutter raised during the run.
  ///
  /// Collected rather than left to the default handler, because an overflow in
  /// an integration test prints a red band and carries on: the run would pass
  /// with content the user cannot see, which is the exact defect this is here
  /// to catch.
  final List<String> layoutErrors = <String>[];

  testWidgets('a whole invoice, entered through the real sheets', (
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
    final File file = await defaultDatabaseFile(name: 'form_probe.db');
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
            companyName: 'کارگاه نمونهٔ تهران',
            nationalId: '0079542311',
          ),
        );
    final Product product = await container
        .read(productRepositoryProvider)
        .create(
          ProductDraft(
            name: 'مشاورهٔ فنی و مهندسی',
            type: ProductType.service,
            price: Money.rial(12500000),
            unit: 'ساعت',
          ),
        );

    // ---- the real screen, in the real shell -------------------------------
    final GoRouter router = GoRouter(
      initialLocation: '/invoices/new',
      routes: <RouteBase>[
        GoRoute(
          path: '/invoices/new',
          // A `Scaffold`, because `AdaptiveScaffold` is what supplies one in
          // the real shell and the screen expects a `Material` ancestor for
          // its ink. Standing the screen up without one is a harness fault,
          // not an application one.
          builder: (_, _) =>
              const Scaffold(body: SafeArea(child: InvoiceEditorScreen())),
        ),
        GoRoute(path: '/invoices', builder: (_, _) => const SizedBox.shrink()),
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

    final BuildContext screen = tester.element(
      find.byType(InvoiceEditorScreen),
    );
    final AppStrings strings = AppStrings.of(screen);
    final Size size = MediaQuery.sizeOf(screen);
    final double textScale = MediaQuery.textScalerOf(screen).scale(16);

    debugPrint('=== PHASE 4 (d) FORM ON DEVICE ===');
    debugPrint('platform      : ${Platform.operatingSystem}');
    debugPrint('logical size  : ${size.width} x ${size.height}');
    debugPrint('pixel ratio   : ${tester.view.devicePixelRatio}');
    debugPrint('16sp renders  : $textScale');

    // ---- how far down is the first thing a user wants to touch? ------------
    //
    // The measurement that decided the fold (D-054), taken both ways on the
    // real device rather than reasoned about.
    final double addLineFolded = _distanceDown(
      tester,
      find.text(strings.invoiceLineAddFromCatalogue),
    );
    final Rect addLineBox = tester.getRect(
      find.text(strings.invoiceLineAddFromCatalogue),
    );
    // Where the scrolling region actually ends: the top of the pinned bar.
    final double barTop = tester
        .getTopLeft(find.text(strings.invoiceActionIssue))
        .dy;
    debugPrint(
      'add-line folded: ${addLineFolded.toStringAsFixed(0)} px, '
      'bottom ${addLineBox.bottom.toStringAsFixed(0)}',
    );
    debugPrint('pinned bar top : ${barTop.toStringAsFixed(0)} px');
    debugPrint('fits unscrolled: ${addLineBox.bottom < barTop}');

    await tester.tap(find.text(strings.invoiceDetailsTitle));
    await tester.pumpAndSettle();
    final double datesShown = _distanceDown(
      tester,
      find.text(strings.invoiceFieldIssueDate),
    );
    debugPrint('dates unfolded : ${datesShown.toStringAsFixed(0)} px');

    // ---- the customer picker ----------------------------------------------
    await tester.tap(find.text(strings.invoiceFieldCustomerEmpty));
    await tester.pumpAndSettle();
    expect(
      find.text(strings.invoiceCustomerPickerSearchHint),
      findsOneWidget,
      reason: 'the customer sheet must open on the device too',
    );
    // Through the sheet's own search field, folded by `searchKey` (D-029):
    // typed with the Arabic ي, matching a customer stored with the Persian ی.
    await tester.enterText(find.byType(TextField).first, 'مريم');
    await tester.pumpAndSettle();
    await tester.tap(find.text(customer.fullName));
    await tester.pumpAndSettle();
    debugPrint('customer      : picked through search');

    // ---- the product picker, then the line sheet ---------------------------
    //
    // With the section open the add-line buttons are below the fold again,
    // which is the measurement the fold exists to answer -- reported above.
    final double scrolled = await _scrollTo(
      tester,
      find.text(strings.invoiceLineAddFromCatalogue),
    );
    debugPrint('add-line open  : scrolled ${scrolled.toStringAsFixed(0)} px');

    await tester.tap(find.text(strings.invoiceLineAddFromCatalogue));
    await tester.pumpAndSettle();
    debugPrint('on screen     : ${_visibleTexts(tester).take(12).join(" | ")}');
    await tester.tap(find.text(product.name));
    await tester.pumpAndSettle();

    expect(
      find.text(strings.invoiceLineFieldQuantity),
      findsOneWidget,
      reason: 'picking a product opens the line sheet pre-filled (D-050)',
    );

    // **The numeric field, on the real phone.** A fractional quantity through
    // `tryParseScaledInput(scale: 1000)`, typed in Persian digits as a user
    // would with the Persian keyboard.
    await tester.enterText(
      find.widgetWithText(TextField, strings.invoiceLineFieldQuantity),
      '۲٫۵',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.actionSave));
    await tester.pumpAndSettle();
    debugPrint('line          : added at quantity ۲٫۵');

    // ---- the calendar grid --------------------------------------------------
    await _scrollTo(tester, find.text(strings.invoiceFieldIssueDate));
    await tester.tap(find.text(strings.invoiceFieldIssueDate));
    await tester.pumpAndSettle();
    // Saturday is the first column (D-051's finding); the grid renders day
    // numbers, so tapping one is the whole interaction.
    await tester.tap(find.text('۱۵').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.actionSave));
    await tester.pumpAndSettle();
    debugPrint('issue date    : picked from the Jalali grid');

    // ---- the summary, and the two actions ----------------------------------
    expect(
      find.text(strings.invoiceSummaryGrandTotal),
      findsWidgets,
      reason: 'the pinned bar must be showing a total by now',
    );

    await tester.tap(find.text(strings.invoiceActionIssue));
    await tester.pumpAndSettle();
    expect(find.text(strings.invoiceIssueConfirmTitle), findsOneWidget);
    await tester.tap(find.text(strings.invoiceIssueConfirmAction));
    await tester.pumpAndSettle();

    final List<Invoice> written = await container
        .read(invoiceRepositoryProvider)
        .watchAll()
        .first;
    expect(written, hasLength(1));
    expect(written.single.number, isNotNull);
    debugPrint('issued        : ${written.single.number}');
    debugPrint('grand total   : ${written.single.grandTotal.rial} rial');
    debugPrint('party         : ${written.single.customerSnapshot != null}');

    // 12,500,000 rial x 2.5 = 31,250,000 gross, and the engine is the only
    // thing that computed it — this asserts the device produced the same
    // arithmetic the VM does, which is the other half of what running here is
    // for.
    expect(written.single.subtotal.rial, 31250000);

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

/// Scrolls the form until [target] is on screen, and returns how far it had to.
///
/// Returns the distance in logical pixels, because "how far down is the first
/// thing a user wants to touch" is the question a phone layout has to answer
/// and the only place to answer it is on a phone.
Future<double> _scrollTo(WidgetTester tester, Finder target) async {
  double scrolled = 0;
  while (target.evaluate().isEmpty && scrolled < 4000) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    scrolled += 200;
  }
  // Existing in the tree is not the same as being on screen: a `ListView`
  // builds a little beyond the viewport, so the loop above stops while the
  // target is still below the fold — and a tap there misses silently, which is
  // exactly the mistake a person does not make and a script does.
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  return scrolled;
}

/// Every string currently rendered, for the debug line above.
List<String> _visibleTexts(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((Text text) => text.data ?? '')
      .where((String value) => value.isNotEmpty)
      .toList();
}

/// How far below the top of the window [target] sits, or -1 if it is not built.
///
/// The question a phone layout has to answer — how far down is the thing a user
/// reaches for first — and the only place to answer it is on a phone.
double _distanceDown(WidgetTester tester, Finder target) {
  if (target.evaluate().isEmpty) return -1;
  return tester.getTopLeft(target).dy;
}
