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
import 'package:factorino/data/models/payment.dart';
import 'package:factorino/data/models/payment_method.dart';
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

import 'device_assertions.dart';

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
/// **It writes as well as renders.** (c) added a payment recorded and taken
/// back off again through the real sheet; (d) adds the cancellation — the menu,
/// the confirmation with money on the invoice, and the two sentences a void
/// document carrying payments owes afterwards. Every status is read back from
/// the **database**, never from the screen, because the screen believing it is
/// not the claim.
///
/// It also exercises the two states a screenshot of a happy invoice never shows:
/// a customer **renamed after issue**, so the document and the record disagree
/// and D-052's notice has to render; and an invoice whose **gross was never
/// recorded**, so «ثبت‌نشده» has to fit where a figure would have gone.
///
/// **It reads the page by scrolling to what it asserts, not by assuming where
/// things are.** The narrow tiers order the page summary → lines → payments →
/// party → dates → notes, and the desktop tier puts the party and the summary
/// in a side panel — genuinely different layouts (§10), not one squeezed. The
/// first phone-tier run of this file failed on the party assertion for exactly
/// that reason, with the product behaving correctly; [reach] is the fix.
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

      // **Every rung carries an invoice-level discount, including the top
      // one, and that is the point of this line rather than an incidental.**
      // Writing this fixture is what surfaced known issue 19: largest-remainder
      // allocation multiplied the discount by each line's net into an `int`, and
      // that product is quadratic in the invoice total, so 100,000,000 تومان with
      // a 5% discount threw `MoneyRangeError` here before it ever reached a
      // screen. `mulDivFloor` removed the intermediate (D-059) and the rung came
      // back. If this ever needs a special case again, the fix has regressed.

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
              discount: Money.rial(rial ~/ 20),
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

    debugPrint('=== PHASE 5 (b)+(c)+(d) DETAIL SCREEN ON DEVICE ===');
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
      //
      // Scrolled to rather than asserted where it happens to be: on a phone the
      // party card is below the lines and the payments (§10, D-044), so it is
      // not in the tree at all until the page is moved. See [reach].
      await reach(tester, find.text('مریم احمدی'));
      expect(
        find.text('مریم احمدی'),
        findsOneWidget,
        reason: 'the document must keep the party it was issued to',
      );
      await reach(tester, find.text(strings.invoiceDetailPartyDiverged));
      expect(
        find.text(strings.invoiceDetailPartyDiverged),
        findsOneWidget,
        reason: 'and it must say why that is not the name in the record',
      );

      // Whether the figure that was never recorded is admitted rather than
      // zeroed, on the widest invoice of the four.
      await reach(tester, find.text(strings.invoiceFigureUnrecorded));
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

      // ---- record a payment through the real sheet (Phase 5 (c)) ----------
      //
      // Only on the first invoice, and only once: what this adds over the
      // widget tests is the **real** modal sheet, the real Jalali field, the
      // real dialog and the real encrypted database, at the target's own
      // metrics in Vazirmatn. Repeating it four times would add running time
      // and no evidence.
      if (index == 0) {
        // On a phone this is the floating action, which is not in the list at
        // all; on the wider tiers it is the inline button inside the payments
        // card, which is (D-060). One finder reaches both because each tier
        // offers the action exactly once, under the same Persian label.
        await reach(tester, find.text(strings.invoiceDetailRecordPayment));
        await tester.ensureVisible(
          find.text(strings.invoiceDetailRecordPayment).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.invoiceDetailRecordPayment).first);
        await tester.pumpAndSettle();

        expect(
          find.text(strings.paymentFieldAmount),
          findsOneWidget,
          reason: 'the payment sheet must open on the device too',
        );

        // Through the sheet's own convenience, so the figure written is the
        // balance the aggregate computed rather than one this test worked out.
        await tester.tap(find.text(strings.paymentAmountFillRemaining));
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.paymentMethodCardTransfer));
        await tester.pumpAndSettle();

        // **The amount field carries `autofocus: true`, so on a real phone the
        // keyboard is already up** — this sheet has no state in which a user
        // sees it without one. That is what makes it the right place to assert
        // the rule rather than merely to measure it (D-062): «ذخیره» is pinned
        // by `EditorSheet` and must be inside the space the keyboard leaves.
        //
        // **No `ensureVisible` before the tap, deliberately.** Scrolling to the
        // button first is what the previous run did, and it would hide a
        // regression of exactly the defect this assertion exists for: the tap
        // must land on a button that was already reachable.
        final Finder save = find.widgetWithText(
          FilledButton,
          strings.actionSave,
        );
        expectActionAboveKeyboard(tester, save, sheet: 'payment sheet');
        await tester.tap(save);
        await tester.pumpAndSettle();

        // The write went through the repository's transaction, so the status was
        // recomputed with it (§6) -- read back from the database rather than from
        // the screen, because the screen believing it is not the claim.
        final Invoice afterPayment = (await container
            .read(invoiceRepositoryProvider)
            .findById(invoice.id))!;
        final int paid = await container
            .read(paymentRepositoryProvider)
            .totalPaidRial(invoice.id);

        debugPrint(
          'payment       : $paid rial recorded, status ${afterPayment.status.name}',
        );
        expect(paid, afterPayment.grandTotal.rial);
        expect(afterPayment.status, InvoiceStatus.paid);

        // And the page followed the row: the badge is the live query's, not
        // something the payments card set.
        await tester.pumpAndSettle();
        expect(find.text(strings.statusPaid), findsOneWidget);

        // ---- and take it back off again -------------------------------------
        await reach(tester, find.byTooltip(strings.paymentDeleteAction));
        await tester.ensureVisible(
          find.byTooltip(strings.paymentDeleteAction).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(strings.paymentDeleteAction).first);
        await tester.pumpAndSettle();

        // The warning is only shown where removing this payment genuinely takes
        // the invoice out of «پرداخت شده», which is exactly this case.
        expect(
          find.text(strings.paymentDeleteStatusWarning),
          findsOneWidget,
          reason: 'removing the only payment on a paid invoice must warn',
        );
        await tester.tap(
          find.widgetWithText(FilledButton, strings.paymentDeleteAction),
        );
        await tester.pumpAndSettle();

        final Invoice afterDelete = (await container
            .read(invoiceRepositoryProvider)
            .findById(invoice.id))!;
        debugPrint('deletion      : status ${afterDelete.status.name}');
        expect(afterDelete.status, InvoiceStatus.unpaid);
        expect(
          await container
              .read(paymentRepositoryProvider)
              .totalPaidRial(invoice.id),
          0,
        );

        // ---- cancel it, with money on it (Phase 5 (d)) ----------------------
        //
        // The payment is written through the repository this time rather than
        // through the sheet: the sheet is already proven three paragraphs up,
        // and what (d) adds is the **menu, the confirmation and the two
        // sentences a cancelled invoice owes afterwards** — on the real target,
        // in Vazirmatn, with a real amount sitting on the document.
        await container
            .read(paymentRepositoryProvider)
            .record(
              invoice.id,
              PaymentDraft(
                amount: Money.rial(invoice.grandTotal.rial ~/ 3),
                paidAt: DateTime.utc(2026, 8, 25),
                method: PaymentMethod.cash,
              ),
            );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.invoiceCancelAction).first);
        await tester.pumpAndSettle();

        // The half of the copy that only appears where money has changed hands
        // (D-061). This is the sentence the increment exists for, so it is
        // asserted on the device and not only in the widget sweep.
        expect(
          find.text(strings.invoiceCancelBody),
          findsOneWidget,
          reason: 'the confirmation must say what cancelling does not do',
        );
        expect(
          find.textContaining('بازگردانده نمی‌شود'),
          findsOneWidget,
          reason: 'and, with a payment on it, that nothing is refunded',
        );

        await tester.tap(
          find.widgetWithText(FilledButton, strings.invoiceCancelAction),
        );
        await tester.pumpAndSettle();

        // Read back from the database rather than from the screen: the money
        // stayed, and the status did not derive its way back out of
        // `cancelled` (§6, D-061).
        final Invoice afterCancel = (await container
            .read(invoiceRepositoryProvider)
            .findById(invoice.id))!;
        final int paidAfterCancel = await container
            .read(paymentRepositoryProvider)
            .totalPaidRial(invoice.id);
        debugPrint(
          'cancellation  : status ${afterCancel.status.name}, '
          '$paidAfterCancel rial still on record, '
          'number ${afterCancel.number}',
        );
        expect(afterCancel.status, InvoiceStatus.cancelled);
        expect(paidAfterCancel, invoice.grandTotal.rial ~/ 3);
        expect(
          afterCancel.number,
          invoice.number,
          reason: 'a spent number stays spent (D-013)',
        );

        // And the page says both of the things a void document carrying money
        // has to say, rather than leaving a paid figure to be read as a fault.
        //
        // The two sentences live in **different cards** — the payments card and
        // the paid/due card — which on a phone are separated by the whole line
        // table, so they are never on screen together and each has to be
        // reached in turn.
        await tester.pumpAndSettle();
        await reach(
          tester,
          find.text(strings.invoiceDetailCancelledPaymentsNote),
        );
        expect(
          find.text(strings.invoiceDetailCancelledPaymentsNote),
          findsOneWidget,
        );
        await reach(tester, find.text(strings.invoiceDetailCancelledDueNote));
        expect(
          find.text(strings.invoiceDetailCancelledDueNote),
          findsOneWidget,
        );

        // Correcting the money record is still possible, and it does not
        // resurrect the invoice.
        await reach(tester, find.byTooltip(strings.paymentDeleteAction));
        await tester.ensureVisible(
          find.byTooltip(strings.paymentDeleteAction).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(strings.paymentDeleteAction).first);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('باطل می‌ماند'),
          findsOneWidget,
          reason:
              'the cancelled invoice gets its own wording: nothing is owed on '
              'a void document, so no balance goes up',
        );
        await tester.tap(
          find.widgetWithText(FilledButton, strings.paymentDeleteAction),
        );
        await tester.pumpAndSettle();

        final Invoice afterCorrection = (await container
            .read(invoiceRepositoryProvider)
            .findById(invoice.id))!;
        debugPrint('correction    : status ${afterCorrection.status.name}');
        expect(afterCorrection.status, InvoiceStatus.cancelled);
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
