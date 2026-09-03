import 'package:factorino/core/date/jalali_instant.dart';
import 'package:factorino/core/date/jalali_period.dart';
import 'package:factorino/core/formatting/jalali_display.dart';
import 'package:factorino/core/formatting/number_display.dart';
import 'package:factorino/core/formatting/persian_text.dart';
import 'package:factorino/core/localization/month_names.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/payment.dart';
import 'package:factorino/features/invoices/presentation/widgets/payment_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screen_harness.dart';

/// The payment sheet's two owner requests: settling the balance in one action,
/// and recording *when* the money arrived (D-109, D-110).
void main() {
  /// 09:30 Tehran on 1405/06/02 — deliberately not midnight, because midnight
  /// is the value the old code produced and every assertion here is about
  /// telling the two apart.
  final DateTime now = DateTime.utc(2026, 8, 24, 6);

  /// The ceiling rung of D-057's ladder, so the fill button is exercised at the
  /// magnitude a fixed-width control actually has to survive rather than at
  /// whatever the fixture happened to hold.
  final Money due = Money.rial(kCeilingRial);

  /// Opens the sheet and hands back both the strings and the draft it produced.
  ///
  /// The draft arrives asynchronously — the sheet pops with it — so the future
  /// is captured rather than awaited, and read after the sheet has closed.
  Future<(AppStrings, Future<PaymentDraft?>)> openSheet(
    WidgetTester tester, {
    Money? amountDue,
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
      size: const Size(400, 800),
    );

    final Future<PaymentDraft?> draft = showPaymentEditorSheet(
      hostContext,
      amountDue: amountDue ?? due,
      today: now,
    );
    await tester.pumpAndSettle();
    return (AppStrings.of(hostContext), draft);
  }

  group('settling the balance in one action (D-109)', () {
    testWidgets('the fill control puts the whole balance in the field', (
      WidgetTester tester,
    ) async {
      final (AppStrings strings, Future<PaymentDraft?> result) =
          await openSheet(tester);

      await tester.tap(find.text(strings.paymentAmountFillRemaining));
      await tester.pumpAndSettle();

      // The field now holds the balance in Toman, so «ذخیره» alone completes
      // the commonest payment there is.
      expect(
        find.widgetWithText(TextField, '${due.toman}'),
        findsOneWidget,
        reason: 'tapping the control must fill the amount field',
      );

      await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
      await tester.pumpAndSettle();

      final PaymentDraft? draft = await result;
      expect(draft, isNotNull);
      expect(
        draft!.amount,
        due,
        reason: 'and the draft that reaches the repository must be the balance',
      );
    });

    testWidgets('it is a button, not a run of text', (
      WidgetTester tester,
    ) async {
      // **The whole defect was that this read as helper copy.** The owner
      // tested a build that already had the feature and asked for it, which is
      // the only evidence about an affordance that counts. A `FilledButton`
      // subclass is what makes it read as a control; if someone flattens it
      // back to a `TextButton`, this fails and says why.
      final (AppStrings strings, Future<PaymentDraft?> result) =
          await openSheet(tester);

      expect(
        find.widgetWithText(FilledButton, strings.paymentAmountFillRemaining),
        findsOneWidget,
        reason:
            'a flat text link under a grey helper line is two lines of prose '
            'to anyone scanning for a button (D-109)',
      );

      await tester.tap(find.byTooltip(strings.actionCancel));
      await tester.pumpAndSettle();
      await result;
    });

    testWidgets('and it is absent when there is nothing left to settle', (
      WidgetTester tester,
    ) async {
      // A settled invoice can still take money — the record has to be able to
      // hold a double payment — but there is no balance to fill in, and a
      // control that would write zero is worse than no control.
      final (AppStrings strings, Future<PaymentDraft?> result) =
          await openSheet(tester, amountDue: Money.zero);

      expect(find.text(strings.paymentAmountFillRemaining), findsNothing);
      expect(
        find.text(
          strings.paymentAmountRemainingHelper(formatGroupedPersian(0)),
        ),
        findsOneWidget,
        reason: 'the balance is still stated; only the action goes',
      );

      await tester.tap(find.byTooltip(strings.actionCancel));
      await tester.pumpAndSettle();
      await result;
    });
  });

  group('a payment is a moment, not a day (D-110)', () {
    testWidgets('the draft carries the time of day it was entered at', (
      WidgetTester tester,
    ) async {
      // **The defect, stated as a test.** `jalaliDayOf(today).start` truncated
      // this to ۰۰:۰۰ on every payment ever recorded — D-092's fault one column
      // over, and invisible for exactly as long as nothing displayed the time.
      final (AppStrings strings, Future<PaymentDraft?> result) =
          await openSheet(tester);

      await tester.tap(find.text(strings.paymentAmountFillRemaining));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
      await tester.pumpAndSettle();

      final PaymentDraft draft = (await result)!;
      expect(
        draft.paidAt,
        now,
        reason: 'the instant the page was built against, not its midnight',
      );
      expect(
        draft.paidAt,
        isNot(jalaliDayOf(now).start),
        reason: 'and specifically not the start of the day',
      );
    });

    testWidgets('and it stays inside the Jalali day the clock is in', (
      WidgetTester tester,
    ) async {
      // The property every reporting period depends on (§5, D-006): a payment
      // entered today must file under today's Jalali month on the dashboard.
      final (AppStrings strings, Future<PaymentDraft?> result) =
          await openSheet(tester);

      await tester.tap(find.text(strings.paymentAmountFillRemaining));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
      await tester.pumpAndSettle();

      expect(jalaliDayOf(now).contains((await result)!.paidAt), isTrue);
    });

    testWidgets('picking a different day keeps the time of day', (
      WidgetTester tester,
    ) async {
      // D-092's rule, applied here: the picker answers "which day", and
      // assigning what it returns whole would reset a corrected payment to
      // ۰۰:۰۰ — not a missing value but a false one, on a financial record.
      final (AppStrings strings, Future<PaymentDraft?> result) =
          await openSheet(tester);

      await tester.tap(find.text(strings.paymentAmountFillRemaining));
      await tester.pumpAndSettle();

      // The field renders the current value; tapping it opens the calendar.
      await tester.tap(
        find.text(
          formatJalaliDateLong(now, monthNames: jalaliMonthNames(strings)),
        ),
      );
      await tester.pumpAndSettle();
      // The first of the month the picker opens on, which is not today.
      await tester.tap(find.text(toPersianDigits('1')));
      await tester.pumpAndSettle();
      // Scoped to the dialog: the sheet's own «ذخیره» is still in the tree
      // behind it and says the same word.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, strings.actionSave),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
      await tester.pumpAndSettle();

      final DateTime paidAt = (await result)!.paidAt;
      expect(
        jalaliAt(paidAt).day,
        1,
        reason: 'the day moved to the one that was picked',
      );
      expect(
        <int>[jalaliAt(paidAt).hour, jalaliAt(paidAt).minute],
        <int>[jalaliAt(now).hour, jalaliAt(now).minute],
        reason: 'and the clock came with it, rather than being reset to ۰۰:۰۰',
      );
    });
  });
}

/// The ceiling of the amount ladder, in Rial. Named rather than inlined so the
/// magnitude this sheet is exercised at is a decision somebody made (D-057).
const int kCeilingRial = 1000000000;
