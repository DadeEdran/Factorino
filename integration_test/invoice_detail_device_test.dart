import 'dart:io';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/theme/app_theme.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_draft.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/features/invoices/presentation/invoice_detail_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

/// The invoice detail screen on the real target, at every rung of the amount
/// ladder — Phase 5 (b), and the first pass written under D-057.
///
/// **This is the check whose absence let known issue 18 through.** Phase 4 was
/// closed on a device pass that ran on a phone and on a Windows check that the
/// app starts. The summary panel's grand total overflowed its 320-pixel panel on
/// every invoice above a million تومان, on the desktop tier only, and nothing
/// looked at the desktop tier with a real amount in it for two increments.
///
/// So this runs on **whichever target it is given** — on Windows that is the
/// desktop tier and the layout that was never checked — and it runs the same
/// ladder the widget sweep does (`test/support/money_magnitudes.dart`), because
/// the amounts are the other half of the defect. What it adds over the widget
/// sweep is **Vazirmatn**: the widget tests render in a fallback font whose
/// glyphs are much wider, so they are conservative about width and silent about
/// everything else a real font does.
///
/// It also exercises the two states a screenshot of a happy invoice never shows:
/// a customer **renamed after issue**, so the document and the record disagree
/// and D-052's notice has to render; and an invoice whose **gross was never
/// recorded**, so «ثبت‌نشده» has to fit where a figure would have gone.
///
/// Uses a probe database, so running it never touches the real one.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// The ladder, restated rather than imported: `integration_test/` does not
  /// see `test/`, and duplicating four integers is better than either moving
  /// the ladder into `lib/` — where it is not application code — or quietly
  /// checking a friendlier one here. If these ever disagree with
  /// `kMoneyStressToman`, this comment is the reason to fix it rather than to
  /// shrug.
  const List<int> stressToman = <int>[100000, 1000000, 10000000, 100000000];

  final List<String> layoutErrors = <String>[];

  testWidgets('a stored invoice, at every magnitude, on the real target', (
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
    final File file = await defaultDatabaseFile(name: 'detail_probe.db');
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
            fullName: 'مریم احمدی',
            companyName: 'کارگاه نمونهٔ تهران',
            nationalId: '0079542311',
            economicId: '411123456789',
            address: 'تهران، خیابان ولیعصر، پلاک ۱۲۰، واحد ۴',
            mobile: '09121234567',
          ),
        );

    // Every invoice is **issued**, not saved as a draft, so each one carries a
    // real party snapshot and a real number -- the state the detail screen
    // actually shows most of the time.
    final List<Invoice> invoices = <Invoice>[];
    for (final int toman in stressToman) {
      final int rial = toman * 10;

      // **The top rung carries no invoice-level discount, and that is a finding
      // rather than a convenience.** Largest-remainder allocation computes
      // `checkedMultiply(invoiceDiscount, lineNet)` before dividing, and that
      // intermediate is checked against 2^53 so the VM and the Web reject the
      // same inputs (D-002). With a percentage discount the ceiling is therefore
      // on the *product*: a 5% discount refuses an invoice above roughly
      // 42 million تومان, a 10% one above roughly 30 million — far below
      // `kMaxAmountRial`, and inside the range a real project invoice reaches.
      // Writing this fixture is what surfaced it; it is recorded as a known
      // issue and belongs to `core/money/`, not to this screen.
      final bool discountFits = toman < 100000000;

      final created = await container
          .read(invoiceRepositoryProvider)
          .create(
            InvoiceDraft(
              customerId: customer.id,
              issueDate: DateTime.now().toUtc(),
              dueDate: DateTime.now().toUtc().add(const Duration(days: 30)),
              notes: 'تحویل تا پایان شهریور، پرداخت پس از تأیید نهایی.',
              // An invoice-level discount, so each line carries a share of it
              // and the allocated column has something in it.
              discount: discountFits ? Money.rial(rial ~/ 20) : Money.zero,
              items: <InvoiceItemDraft>[
                InvoiceItemDraft(
                  title: 'مشاورهٔ فنی و مهندسی',
                  unit: 'ساعت',
                  unitPrice: Money.rial(rial),
                  quantityMilli: 1000,
                ),
                InvoiceItemDraft(
                  title: 'پشتیبانی ماهانهٔ سامانه',
                  unit: 'ماه',
                  unitPrice: Money.rial(rial),
                  quantityMilli: 1000,
                  discount: Money.rial(rial ~/ 40),
                ),
              ],
            ),
            status: InvoiceStatus.unpaid,
          );
      invoices.add(created.invoice);
    }

    // ---- the two states a happy screenshot never shows --------------------
    //
    // 1. The customer is renamed **after** every invoice was issued, so the
    //    document and the record now disagree and D-052's notice renders on
    //    every one of these pages -- at the device's own metrics, in Vazirmatn,
    //    which is where a three-line Persian sentence in a 320-pixel panel would
    //    go wrong if it were going to.
    await container
        .read(customerRepositoryProvider)
        .update(
          customer.id,
          const CustomerDraft(
            fullName: 'مریم احمدی‌نژاد',
            companyName: 'کارگاه نمونهٔ تهران',
            nationalId: '0079542311',
            economicId: '411123456789',
            address: 'تهران، خیابان ولیعصر، پلاک ۱۲۰، واحد ۴',
            mobile: '09121234567',
          ),
        );

    // 2. The largest invoice loses its stored gross, exactly as a pre-v4 row the
    //    backfill refused would have it (D-056). «ثبت‌نشده» then has to fit
    //    where the widest figure on the ladder would have gone -- which is the
    //    harder of the two cases, not the easier one.
    await db.customStatement(
      'UPDATE invoices SET gross_total_rial = NULL WHERE id = ?',
      <Object?>[invoices.last.id],
    );
    await db.customStatement(
      'UPDATE invoice_items SET line_gross_rial = NULL, '
      'allocated_invoice_discount_rial = NULL WHERE invoice_id = ?',
      <Object?>[invoices.last.id],
    );

    debugPrint('=== PHASE 5 (b) DETAIL SCREEN ON DEVICE ===');
    debugPrint('platform      : ${Platform.operatingSystem}');

    for (int index = 0; index < invoices.length; index++) {
      final Invoice invoice = invoices[index];
      final int toman = stressToman[index];

      final GoRouter router = GoRouter(
        initialLocation: '/invoices/${invoice.id}',
        routes: <RouteBase>[
          GoRoute(
            // A `Scaffold`, because `AdaptiveScaffold` is what supplies one in
            // the real shell and the screen expects a `Material` ancestor for
            // its ink. Standing the screen up without one is a harness fault,
            // not an application one.
            path: '/invoices/:id',
            builder: (_, GoRouterState state) => Scaffold(
              body: SafeArea(
                child: InvoiceDetailScreen(
                  invoiceId: state.pathParameters['id']!,
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/customers/:id',
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

      final BuildContext screen = tester.element(
        find.byType(InvoiceDetailScreen),
      );
      final AppStrings strings = AppStrings.of(screen);
      final Size size = MediaQuery.sizeOf(screen);

      if (index == 0) {
        debugPrint('logical size  : ${size.width} x ${size.height}');
        debugPrint('pixel ratio   : ${tester.view.devicePixelRatio}');
        debugPrint(
          '16sp renders  : ${MediaQuery.textScalerOf(screen).scale(16)}',
        );
      }

      // The party the **document** states, not the record -- the whole of
      // D-052 rendered. The customer was renamed above, so finding the old name
      // here is the assertion, and finding the new one would be the defect.
      expect(
        find.text('مریم احمدی'),
        findsOneWidget,
        reason: 'the document must keep the party it was issued to',
      );
      expect(
        find.text(strings.invoiceDetailPartyDiverged),
        findsOneWidget,
        reason: 'and it must say why that is not the name in the record',
      );

      // Whether the figure that was never recorded is admitted rather than
      // zeroed, on the widest invoice of the four.
      final bool unrecorded = find
          .text(strings.invoiceFigureUnrecorded)
          .evaluate()
          .isNotEmpty;
      debugPrint(
        '$toman تومان : rendered, unrecorded figures shown = $unrecorded',
      );
      if (index == invoices.length - 1) {
        expect(
          unrecorded,
          isTrue,
          reason: 'a refused backfill must show «ثبت‌نشده», never a zero',
        );
      }

      // Scroll the whole page rather than the first viewport: an off-screen
      // widget is never laid out, so a page checked only where it opens is a
      // page whose lower half went unchecked.
      for (final Element element in find.byType(ListView).evaluate().toList()) {
        for (int step = 0; step < 12; step++) {
          await tester.drag(
            find.byWidget(element.widget),
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();
        }
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
