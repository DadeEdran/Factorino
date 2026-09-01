import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/features/invoices/presentation/widgets/invoice_line_editor_sheet.dart';
import 'package:factorino/features/invoices/presentation/widgets/payment_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  /// Opens [sheet] from a host screen, with the keyboard already up.
  ///
  /// The inset goes through the harness's own `MediaQuery`, which is where the
  /// real one arrives: a sheet reads `MediaQuery.viewInsetsOf(context)` and
  /// cannot tell this apart from a keyboard the platform raised.
  Future<AppStrings> openSheet(
    WidgetTester tester,
    Future<void> Function(BuildContext context) sheet,
  ) async {
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
      viewInsets: const EdgeInsets.only(bottom: keyboard),
    );

    final AppStrings strings = AppStrings.of(hostContext);
    unawaited(sheet(hostContext));
    await tester.pumpAndSettle();
    return strings;
  }

  /// The whole assertion: the action is inside the region the keyboard leaves.
  void expectActionAboveKeyboard(WidgetTester tester, Finder action) {
    expect(action, findsOneWidget, reason: 'the sheet must offer its action');

    final Rect rect = tester.getRect(action);
    const double visibleBottom = 800 - keyboard;

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
