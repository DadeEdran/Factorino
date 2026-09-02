import 'dart:io';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/theme/app_theme.dart';
import 'package:factorino/core/responsive/breakpoints.dart';
import 'package:factorino/core/widgets/jalali_date_picker.dart';
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

import 'device_assertions.dart';

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

    // **Which layout this target actually gets** (D-062). The form has three
    // (D-053) and they are genuinely different, so everything below either
    // reaches what it asserts or says which tier it is asserting about. This
    // file ran on a phone for two phases and quietly encoded the phone layout:
    // at the desktop tier it failed on the very first measurement, because
    // `_DesktopLayout` is one `ListView` whose second child — the whole lines
    // section — sits past the cache extent at a 681-pixel window and is
    // therefore **not in the tree**. Absence, not invisibility; the same shape
    // of fault the detail suite had, found the same way, by running it
    // somewhere new.
    final LayoutTier tier = Breakpoints.tierFor(size.width);
    debugPrint('tier          : ${tier.name}');

    // ---- how far down is the first thing a user wants to touch? ------------
    //
    // **The fold is a phone ruling** (D-054): the two wider tiers have room for
    // the fields and the lines at once and fold nothing, so these numbers mean
    // something on one tier only. Measured there, and **skipped rather than
    // faked** elsewhere — printing a fold measurement for a layout that has no
    // fold is a device report about a screen that does not exist, which is
    // D-062's mistake in its reporting form.
    final Finder addFromCatalogue = find.text(
      strings.invoiceLineAddFromCatalogue,
    );

    if (tier.isMobile) {
      final double addLineFolded = _distanceDown(tester, addFromCatalogue);
      final Rect addLineBox = tester.getRect(addFromCatalogue);
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

      // The fold toggle, which only this tier has.
      await tester.tap(find.text(strings.invoiceDetailsTitle));
      await tester.pumpAndSettle();
      final double datesShown = _distanceDown(
        tester,
        find.text(strings.invoiceFieldIssueDate),
      );
      debugPrint('dates unfolded : ${datesShown.toStringAsFixed(0)} px');
    } else {
      // Nothing is folded here, so the dates are on screen from the first
      // frame — and the add-line buttons are reached rather than assumed.
      debugPrint(
        'fold          : not applicable at ${tier.name} (D-054), '
        'dates at ${_distanceDown(tester, find.text(strings.invoiceFieldIssueDate)).toStringAsFixed(0)} px',
      );
      final double reached = await _scrollTo(tester, addFromCatalogue);
      debugPrint(
        'add-line       : reached after ${reached.toStringAsFixed(0)} px',
      );
      await _rewind(tester);
    }

    // ---- the customer picker ----------------------------------------------
    await _scrollTo(tester, find.text(strings.invoiceFieldCustomerEmpty));
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

    // ---- known issue 30: the fold, measured in the state a user is in -----
    //
    // The «fits unscrolled: true» reported above is taken on a *pristine* form:
    // details folded, no customer. That is not the state anyone adds a line
    // from. By the time a customer has been picked -- the first thing anyone
    // does -- the details section is open above the lines, and the measurement
    // below is the honest one. Reported rather than asserted: the fix is a
    // layout decision, not a nudge, and a number is worth more to whoever takes
    // it than a rushed change (D-086).
    final double addTopNow = _distanceDown(tester, addFromCatalogue);
    final double barTopNow = _distanceDown(
      tester,
      find.text(strings.invoiceActionIssue),
    );
    final double viewportHeight = MediaQuery.sizeOf(
      tester.element(find.byType(InvoiceEditorScreen)),
    ).height;
    debugPrint(
      'FOLD unfolded+customer: add-line top '
      '${addTopNow.toStringAsFixed(0)} px '
      '(-1 = out of the tree entirely), pinned bar top '
      '${barTopNow.toStringAsFixed(0)}, viewport '
      '${viewportHeight.toStringAsFixed(0)}',
    );

    // And the same with the details section folded back up, which is how the
    // form opens. This is the state a first-time user is actually in when they
    // go looking for the way to add a line.
    await _rewind(tester);
    await tester.tap(find.text(strings.invoiceDetailsTitle));
    await tester.pumpAndSettle();
    final double addFolded = _distanceDown(tester, addFromCatalogue);
    final double barFolded = _distanceDown(
      tester,
      find.text(strings.invoiceActionIssue),
    );
    debugPrint(
      'FOLD folded+customer  : add-line top '
      '${addFolded.toStringAsFixed(0)} px, pinned bar top '
      '${barFolded.toStringAsFixed(0)}, '
      'visible = ${addFolded >= 0 && addFolded < barFolded}',
    );
    // Put it back the way the rest of the run expects to find it.
    await tester.tap(find.text(strings.invoiceDetailsTitle));
    await tester.pumpAndSettle();

    // ---- the product picker, then the line sheet ---------------------------
    //
    // With the section open the add-line buttons are below the fold again,
    // which is the measurement the fold exists to answer -- reported above.
    final double scrolled = await _scrollTo(tester, addFromCatalogue);
    debugPrint('add-line open  : scrolled ${scrolled.toStringAsFixed(0)} px');

    await tester.tap(addFromCatalogue);
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
    //
    // **Tapped before it is typed into, so the real keyboard comes up**
    // (D-062). `enterText` injects straight into the engine and raises nothing,
    // so a device test that only ever calls it is exercising a phone with no
    // keyboard — which is how known issue 21 survived a Windows pass and 892
    // widget tests. This sheet is opened from the catalogue, so its title field
    // does not autofocus and the keyboard has to be asked for.
    final Finder quantity = find.widgetWithText(
      TextField,
      strings.invoiceLineFieldQuantity,
    );
    final double keyboard = await raiseKeyboard(tester, quantity);
    debugPrint('line sheet    : keyboard ${keyboard.toStringAsFixed(1)}');

    expectActionAboveKeyboard(
      tester,
      find.widgetWithText(FilledButton, strings.actionSave),
      sheet: 'line editor sheet',
    );

    await tester.enterText(quantity, '۲٫۵');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
    await tester.pumpAndSettle();
    debugPrint('line          : added at quantity ۲٫۵');

    // The editor's line table has the same shape as the document's — prose
    // beside fixed-width money — so it gets the same check (D-065).
    expectNoCrushedText(tester, where: 'the invoice form, with a line on it');

    // **Put the keyboard away before carrying on with the form**, because a
    // user who dismisses the sheet gets it put away and the rest of this run
    // should be the form as they then see it. Raising it above is the point of
    // the assertion; leaving it up would run the remaining two thirds of the
    // flow against a viewport 254.9 pixels shorter than the real one, which is
    // the same class of mistake as never raising it at all.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    for (int step = 0; step < 40; step++) {
      if (MediaQuery.viewInsetsOf(
            tester.element(find.byType(InvoiceEditorScreen)),
          ).bottom ==
          0) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    // ---- the calendar grid --------------------------------------------------
    //
    // **The field, not its label** (D-062, found by the Phase 5 (f) close).
    // Tapping `find.text(invoiceFieldIssueDate)` warned that the derived offset
    // "would not hit test on the specified widget" and opened the picker
    // anyway: once the field has a value its label floats to the top of the
    // decoration, and the tap landed on the `InputDecorator` underneath, which
    // happens to sit inside the same `InkWell`. It worked by geometry rather
    // than by aiming at the control, and a tap that lands on the right thing by
    // accident stops doing so the moment the decoration is restyled — silently,
    // since the warning is not a failure. `JalaliDateField` is what carries the
    // `onTap`, so it is what a user presses and what this presses.
    final Finder issueDateField = find.ancestor(
      of: find.text(strings.invoiceFieldIssueDate),
      matching: find.byType(JalaliDateField),
    );
    // **Rewound first.** `_scrollTo` only ever scrolls *down*, and after the
    // line was added the desktop tier is parked below the fields — where the
    // date field is neither on screen nor, past the cache extent, in the tree
    // at all. Scrolling further down from there would never reach it.
    await _rewind(tester);
    await _scrollTo(tester, issueDateField);
    await tester.tap(issueDateField);
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
/// Puts the page back at the top.
///
/// `_scrollTo` only searches downwards, which is fine for a form read once from
/// the top and wrong the moment a step needs something *above* where the last
/// one left off. On the desktop tier the whole form is a single `ListView`, so
/// a field scrolled past is not merely off screen — past the cache extent it is
/// out of the tree, and searching further down for it would never end anywhere
/// useful (D-062).
Future<void> _rewind(WidgetTester tester) async {
  for (int step = 0; step < 30; step++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, 240));
    await tester.pumpAndSettle();
  }
}

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
