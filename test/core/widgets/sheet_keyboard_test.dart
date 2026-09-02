import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/theme/app_dimensions.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/utils/clock.dart';
import 'package:factorino/core/widgets/search_field.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/invoice_list_item.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/features/invoices/presentation/widgets/customer_picker_sheet.dart';
import 'package:factorino/features/invoices/presentation/widgets/invoice_filter_sheet.dart';
import 'package:factorino/features/invoices/presentation/widgets/invoice_line_editor_sheet.dart';
import 'package:factorino/features/invoices/presentation/widgets/payment_editor_sheet.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/features/settings/presentation/widgets/backup_password_sheet.dart';
import 'package:factorino/features/settings/presentation/widgets/settings_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/customers/fake_customer_repository.dart';
import '../../features/invoices/fake_invoice_repository.dart';
import '../../features/screen_harness.dart';

/// Every sheet that can raise a soft keyboard, asserted **with the keyboard up**.
///
/// **This file exists because a check that never raises the keyboard is
/// measuring a screen the user never sees** (D-062). The payment sheet shipped
/// in Phase 5 (c) with its «ذخیره» inside its own scroll view. Every widget test
/// passed, the Windows device pass passed, and on the Redmi the keyboard the
/// amount field's `autofocus` raises took **254.9 of 803.6** logical pixels and
/// put the primary action about **70 pixels below the fold** — known issue 21.
///
/// The device pass is where this is proven against a real keyboard on real
/// metrics. This is the cheap guard that fails in seconds on a laptop, so the
/// regression cannot reach a device run in the first place.
///
/// **The inset is the measured one**, not a round number: 255 logical pixels is
/// what a Redmi Note 8 Pro actually takes, and a test that invents a friendlier
/// keyboard is the small-test-data mistake D-057 was written about.
void main() {
  /// A phone, and the keyboard the Redmi actually raises.
  const Size phone = Size(400, 800);
  const double keyboard = 255;

  /// **A password field raises a bigger keyboard, and it was measured rather
  /// than assumed.** On the Redmi the ordinary text keyboard takes 254.9
  /// logical pixels; the one the *password* field raises takes **284.0** — a
  /// different IME layout, 29 pixels taller. Found by the Phase 6 (d) device
  /// pass, after this file had already passed the same sheet at 255.
  ///
  /// So the guard for that sheet uses the number that sheet actually meets. A
  /// cheap check calibrated to a friendlier keyboard than the user's is the
  /// small-test-data mistake D-057 was written about, in a different unit.
  const double passwordKeyboard = 284;

  /// Opens [sheet] from a host screen, with the keyboard already up.
  ///
  /// The inset goes through the harness's own `MediaQuery`, which is where the
  /// real one arrives: a sheet reads `MediaQuery.viewInsetsOf(context)` and
  /// cannot tell this apart from a keyboard the platform raised.
  Future<AppStrings> openSheet(
    WidgetTester tester,
    Future<void> Function(BuildContext context) sheet, {
    double inset = keyboard,
  }) async {
    late BuildContext hostContext;

    await pumpScreen(
      tester,
      Builder(
        builder: (BuildContext context) {
          hostContext = context;
          return const Scaffold(body: SizedBox.expand());
        },
      ),
      size: phone,
      // **The harness had to grow this parameter.** `pumpScreen` installs a
      // fresh `MediaQueryData`, so every screen test in this project has
      // rendered with no keyboard — which is precisely why 892 of them could
      // not see known issue 21.
      viewInsets: EdgeInsets.only(bottom: inset),
    );

    final AppStrings strings = AppStrings.of(hostContext);
    unawaited(sheet(hostContext));
    await tester.pumpAndSettle();
    return strings;
  }

  /// The whole assertion: the action is inside the region the keyboard leaves,
  /// **and no closer to it than the primitive's own bottom padding**.
  ///
  /// **The floor is [AppSpacing.lg], and it is not a tolerance someone picked
  /// here.** `EditorSheet` pads below its action by exactly that, inside a
  /// `SafeArea`, so every sheet built on the primitive lands the same distance
  /// clear of the keyboard by construction. Asserting the floor against the
  /// primitive's own constant is what makes the number govern: a sheet that
  /// bypasses `EditorSheet`, or a change to the primitive's padding, fails here
  /// instead of being rediscovered one sheet at a time on a phone.
  ///
  /// **This corrects D-072's reading of the same 16 pixels.** That entry
  /// recorded them as *margin to watch if the §8 warning copy grows*. They are
  /// not margin and copy growth cannot eat them: `EditorSheet` caps the field
  /// area and scrolls it, and the action stays pinned with the same padding
  /// under it however tall the content above becomes. The number moves only if
  /// [AppSpacing.lg] or the primitive changes — which is exactly what this now
  /// watches.
  void expectActionAboveKeyboard(
    WidgetTester tester,
    Finder action, {
    double inset = keyboard,
  }) {
    expect(action, findsOneWidget, reason: 'the sheet must offer its action');

    final Rect rect = tester.getRect(action);
    final double visibleBottom = 800 - inset;

    expect(
      rect.bottom,
      lessThanOrEqualTo(visibleBottom),
      reason:
          'the primary action must be inside the ${visibleBottom.toInt()} '
          'logical pixels the keyboard leaves, not ${rect.bottom.toInt()} — a '
          'user who types an amount and cannot see «ذخیره» has to discover it '
          'by scrolling (known issue 21, D-062)',
    );
    expect(
      visibleBottom - rect.bottom,
      greaterThanOrEqualTo(AppSpacing.lg),
      reason:
          'the action must clear the keyboard by at least the '
          '${AppSpacing.lg.toInt()} logical pixels EditorSheet pads below it, '
          'and it clears by ${(visibleBottom - rect.bottom).toInt()}. Sitting '
          'flush against the keyboard is a sheet that is not using the '
          'primitive, or a primitive whose padding has changed',
    );
    expect(
      rect.top,
      greaterThanOrEqualTo(0),
      reason: 'and not pushed off the top of the sheet either',
    );
  }

  testWidgets('the payment sheet keeps «ذخیره» above the keyboard', (
    WidgetTester tester,
  ) async {
    // The sheet the defect was found on. Its amount field carries `autofocus`,
    // so on a real phone this is the state it opens in — there is no moment
    // where the user sees it without a keyboard.
    final AppStrings strings = await openSheet(
      tester,
      (BuildContext context) => showPaymentEditorSheet(
        context,
        amountDue: Money.rial(21175000),
        today: DateTime.utc(2026, 8, 24, 12),
      ),
    );

    expectActionAboveKeyboard(
      tester,
      find.widgetWithText(FilledButton, strings.actionSave),
    );
  });

  testWidgets('the line editor sheet does too', (WidgetTester tester) async {
    // This one already pinned its action before there was a primitive for it,
    // and the assertion is here so that stays true rather than being believed.
    final AppStrings strings = await openSheet(
      tester,
      (BuildContext context) => showInvoiceLineEditorSheet(context),
    );

    expectActionAboveKeyboard(
      tester,
      find.widgetWithText(FilledButton, strings.actionSave),
    );
  });

  testWidgets('the backup password sheet keeps «ذخیره» above the keyboard', (
    WidgetTester tester,
  ) async {
    // **The sheet D-062 was written for.** Its password field carries
    // `autofocus`, so a phone raises the keyboard before the user touches
    // anything — and above the field sits the §8 warning, which is several
    // lines of Persian and the tallest thing any sheet in this application has
    // put above its fields. If the warning ever pushes «ذخیره» under the
    // keyboard, the user cannot take a backup at all.
    final AppStrings strings = await openSheet(
      tester,
      (BuildContext context) =>
          showBackupPasswordSheet(context, confirming: true),
      inset: passwordKeyboard,
    );

    expectActionAboveKeyboard(
      tester,
      find.widgetWithText(FilledButton, strings.actionSave),
      inset: passwordKeyboard,
    );
  });

  testWidgets('and so does the settings editor sheet', (
    WidgetTester tester,
  ) async {
    final AppStrings strings = await openSheet(
      tester,
      (BuildContext context) => showSettingsEditorSheet(
        context,
        settings: const AppSettings(
          defaultTaxRateBp: 1000,
          roundingUnitRial: 0,
          invoiceNumberPrefix: 'INV',
        ),
      ),
    );

    expectActionAboveKeyboard(
      tester,
      find.widgetWithText(FilledButton, strings.actionSave),
    );
  });

  testWidgets('a picker keeps its search field above the keyboard', (
    WidgetTester tester,
  ) async {
    // **The pickers do not take `EditorSheet` and should not** — they commit by
    // tapping a row, so the list *is* the action and a pinned button would
    // duplicate it. The rule still has to hold for them in its own form: the
    // control the user types into must stay inside the space the keyboard
    // leaves, with the list beneath it taking the loss.
    await pumpScreen(
      tester,
      Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showCustomerPickerSheet(context),
                child: const Text('open'),
              ),
            ),
          );
        },
      ),
      overrides: <Override>[
        customerRepositoryProvider.overrideWithValue(
          FakeCustomerRepository(const <Customer>[]),
        ),
      ],
      size: phone,
      viewInsets: const EdgeInsets.only(bottom: keyboard),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final Finder search = find.byType(SearchField);
    expect(search, findsOneWidget);
    expect(
      tester.getRect(search).bottom,
      lessThanOrEqualTo(800 - keyboard),
      reason:
          'a search field a user cannot see while typing into it is the same '
          'defect as a save button they cannot see (known issue 21, D-062)',
    );
  });

  testWidgets('the filter sheet pins its action too', (
    WidgetTester tester,
  ) async {
    // It has no text field of its own, so no keyboard rises for it — but it
    // opens the customer picker, which does, and it is built on `EditorSheet`,
    // so the assertion costs nothing and states that the shape is shared.
    await pumpScreen(
      tester,
      Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showInvoiceFilterSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      overrides: <Override>[
        invoiceRepositoryProvider.overrideWithValue(
          FakeInvoiceRepository(const <InvoiceListItem>[]),
        ),
        nowProvider.overrideWithValue(DateTime.utc(2026, 8, 24, 6)),
      ],
      size: phone,
      viewInsets: const EdgeInsets.only(bottom: keyboard),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final AppStrings strings = AppStrings.of(
      tester.element(find.byType(FilterChip).first),
    );
    expectActionAboveKeyboard(
      tester,
      find.widgetWithText(FilledButton, strings.invoiceFilterApply),
    );
  });

  testWidgets('the check fails on a sheet built the way the defect was', (
    WidgetTester tester,
  ) async {
    // **The negative control, and this file needed one.**
    //
    // Raising the inset does not make these assertions fail: `EditorSheet`
    // puts the `viewInsets` padding inside its own height cap, so the action
    // lands on top of whatever keyboard there is *by construction*. That is the
    // primitive working — and it means the inset number documents reality
    // rather than being the thing that bites. Checked directly during the Phase
    // 6 (d) close: the password sheet still passed at an invented 560-pixel
    // keyboard.
    //
    // So what the file actually guards is **a sheet that does not use the
    // primitive's action slot** — which is exactly the shape the payment sheet
    // shipped in as known issue 21. Without this test, a change to `EditorSheet`
    // itself could make every assertion above vacuous and nothing would say so.
    await pumpScreen(
      tester,
      Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (BuildContext context) => const _SheetBuiltTheOldWay(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      size: phone,
      viewInsets: const EdgeInsets.only(bottom: keyboard),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final Finder action = find.byKey(const ValueKey<String>('bad-action'));
    expect(action, findsOneWidget);

    const double visibleBottom = 800 - keyboard;
    expect(
      tester.getRect(action).bottom,
      greaterThan(visibleBottom),
      reason:
          'the deliberately-wrong sheet put its action ABOVE the keyboard, so '
          'this file is no longer able to tell the two shapes apart and every '
          'assertion in it has gone quiet',
    );
  });

  testWidgets('the fields are what gives, and they stay scrollable', (
    WidgetTester tester,
  ) async {
    // The other half of the split (D-053): pinning the action is only correct
    // if everything it displaced is still reachable. A pinned button over
    // fields that can no longer be scrolled to would trade one unreachable
    // control for several.
    final AppStrings strings = await openSheet(
      tester,
      (BuildContext context) => showPaymentEditorSheet(
        context,
        amountDue: Money.rial(21175000),
        today: DateTime.utc(2026, 8, 24, 12),
      ),
    );

    final Finder list = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(Scrollable),
    );
    expect(list, findsWidgets);

    await tester.drag(list.first, const Offset(0, -200));
    await tester.pumpAndSettle();

    // Still pinned after the fields have moved under it, which is the property
    // that distinguishes this from a button that merely happened to be visible.
    expectActionAboveKeyboard(
      tester,
      find.widgetWithText(FilledButton, strings.actionSave),
    );
    expect(find.text(strings.paymentFieldNote), findsOneWidget);
  });
}

/// Fires and forgets the sheet's future: the sheet is dismissed by the test
/// ending, and awaiting it here would deadlock the pump.
void unawaited(Future<void> future) {}

/// The pre-D-062 shape, kept only so the guard above has something to catch:
/// fields and the commit action together in one scroll view, which is how the
/// payment sheet shipped in Phase 5 (c).
class _SheetBuiltTheOldWay extends StatelessWidget {
  const _SheetBuiltTheOldWay();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < 8; i++)
              const SizedBox(height: 80, child: Placeholder()),
            FilledButton(
              key: const ValueKey<String>('bad-action'),
              onPressed: () {},
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }
}
