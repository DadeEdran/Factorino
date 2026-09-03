import 'package:factorino/core/date/jalali_instant.dart';
import 'package:factorino/core/date/jalali_period.dart';
import 'package:factorino/core/formatting/jalali_display.dart';
import 'package:factorino/core/formatting/persian_text.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/utils/clock.dart';
import 'package:factorino/data/models/invoice_filter.dart';
import 'package:factorino/features/invoices/application/invoices_providers.dart';
import 'package:factorino/features/invoices/presentation/widgets/invoice_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../screen_harness.dart';

/// The invoice filter's custom Jalali range (D-111).
///
/// **What the presets could not express.** «این ماه», «ماه گذشته» and «امسال»
/// answer what a billing application is usually asked; they cannot answer "the
/// fortnight I did that job in". The sheet's own header used to call a custom
/// range "a later phase's problem, not a gap here", and the owner found the gap
/// in use.
///
/// The assertions worth having are the two that are easy to get wrong and
/// impossible to see:
///
/// * **the end day is included.** The user picks an inclusive last day and
///   `InstantRange` is half-open, so the bound stored has to be the *next* day's
///   start. Passing the picked instant straight through drops the last day of
///   every range anyone ever chooses, and looks right in every screenshot.
/// * **the filter reaches the query**, not a `.where` over a loaded page — the
///   rule the rest of this feature's tests turn on (§13).
void main() {
  /// 1405/06/02, 09:30 Tehran.
  final DateTime now = DateTime.utc(2026, 8, 24, 6);

  /// Opens the filter sheet over a bare host and returns the strings plus a
  /// ref, so the resulting query can be read back.
  Future<(AppStrings, WidgetRef)> openFilterSheet(WidgetTester tester) async {
    late BuildContext hostContext;
    late WidgetRef capturedRef;

    await pumpScreen(
      tester,
      Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          capturedRef = ref;
          hostContext = context;
          return const Scaffold(body: SizedBox.expand());
        },
      ),
      size: const Size(400, 900),
      overrides: <Override>[nowProvider.overrideWithValue(now)],
    );

    unawaited(showInvoiceFilterSheet(hostContext));
    await tester.pumpAndSettle();
    return (AppStrings.of(hostContext), capturedRef);
  }

  /// Taps day [day] in the calendar currently open, then confirms it.
  Future<void> pickDay(WidgetTester tester, AppStrings strings, int day) async {
    await tester.tap(find.text(toPersianDigits('$day')));
    await tester.pumpAndSettle();
    // Scoped to the dialog: the sheet behind it has its own «ذخیره».
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, strings.actionSave),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the chip is offered beside the presets', (
    WidgetTester tester,
  ) async {
    final (AppStrings strings, _) = await openFilterSheet(tester);

    expect(find.text(strings.invoiceFilterPeriodCustom), findsOneWidget);
    // Beside, not instead of: a preset is still one tap.
    expect(find.text(strings.invoiceFilterPeriodThisMonth), findsOneWidget);
    expect(find.text(strings.invoiceFilterPeriodAny), findsOneWidget);
  });

  testWidgets('two Jalali calendars, headed so the ends can be told apart', (
    WidgetTester tester,
  ) async {
    final (AppStrings strings, _) = await openFilterSheet(tester);

    await tester.tap(find.text(strings.invoiceFilterPeriodCustom));
    await tester.pumpAndSettle();
    expect(
      find.text(strings.invoiceFilterPeriodCustomFrom),
      findsOneWidget,
      reason: 'two identical «انتخاب تاریخ» dialogs tell the user nothing',
    );

    await pickDay(tester, strings, 1);
    expect(find.text(strings.invoiceFilterPeriodCustomTo), findsOneWidget);
  });

  testWidgets('the picked range reaches the query, with the last day in it', (
    WidgetTester tester,
  ) async {
    final (AppStrings strings, WidgetRef ref) = await openFilterSheet(tester);

    await tester.tap(find.text(strings.invoiceFilterPeriodCustom));
    await tester.pumpAndSettle();
    await pickDay(tester, strings, 1);
    await pickDay(tester, strings, 10);

    final InvoiceFilter filter = ref.read(invoiceListQueryProvider).filter;
    final InstantRange range = filter.period!;

    expect(
      range.start,
      startOfJalaliDayUtc(Jalali(1405, 6, 1)),
      reason: 'the range opens at the start of the first day picked',
    );
    // **The assertion that matters.** The user picked the 10th as the last day
    // and means the whole of it; a half-open range's upper bound is therefore
    // the 11th's start. Storing the 10th's start would silently exclude every
    // invoice issued on the day the user named.
    expect(
      range.end,
      startOfJalaliDayUtc(Jalali(1405, 6, 11)),
      reason: 'the last day the user picked is inside the range, not its edge',
    );

    final DateTime lastMoment = startOfJalaliDayUtc(Jalali(1405, 6, 11))
        .subtract(const Duration(milliseconds: 1));
    expect(range.contains(lastMoment), isTrue);
    expect(range.contains(startOfJalaliDayUtc(Jalali(1405, 6, 11))), isFalse);
  });

  testWidgets('and the chip then states the range it is showing', (
    WidgetTester tester,
  ) async {
    // A user returning to the sheet must be able to read what the list is
    // narrowed to without opening two calendars to find out.
    final (AppStrings strings, _) = await openFilterSheet(tester);

    await tester.tap(find.text(strings.invoiceFilterPeriodCustom));
    await tester.pumpAndSettle();
    await pickDay(tester, strings, 1);
    await pickDay(tester, strings, 10);

    expect(
      find.text(
        strings.invoiceFilterPeriodCustomRange(
          formatJalaliDate(startOfJalaliDayUtc(Jalali(1405, 6, 1))),
          // The **inclusive** last day, which is not the stored bound: showing
          // the stored instant would name the 11th on a range the user set to
          // end on the 10th — off by one, on the label that says what they are
          // looking at.
          formatJalaliDate(startOfJalaliDayUtc(Jalali(1405, 6, 10))),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(strings.invoiceFilterPeriodCustom), findsNothing);
  });

  testWidgets('a preset taken afterwards puts the chip back', (
    WidgetTester tester,
  ) async {
    // «بازهٔ دلخواه» is selected iff the period is none of the presets, derived
    // rather than stored — so choosing «این ماه» has to release it without
    // anything being told to.
    final (AppStrings strings, WidgetRef ref) = await openFilterSheet(tester);

    await tester.tap(find.text(strings.invoiceFilterPeriodCustom));
    await tester.pumpAndSettle();
    await pickDay(tester, strings, 1);
    await pickDay(tester, strings, 10);

    await tester.tap(find.text(strings.invoiceFilterPeriodThisMonth));
    await tester.pumpAndSettle();

    expect(
      ref.read(invoiceListQueryProvider).filter.period,
      jalaliMonthOf(now),
    );
    expect(find.text(strings.invoiceFilterPeriodCustom), findsOneWidget);
  });

  testWidgets('dismissing either calendar changes nothing', (
    WidgetTester tester,
  ) async {
    // A cancelled pick must not leave a half-built range, and must not clear
    // whatever was there — a filter that resets itself because the user backed
    // out of a dialog is a list that lost its place.
    final (AppStrings strings, WidgetRef ref) = await openFilterSheet(tester);

    await tester.tap(find.text(strings.invoiceFilterPeriodThisMonth));
    await tester.pumpAndSettle();

    await tester.tap(find.text(strings.invoiceFilterPeriodCustom));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, strings.actionCancel),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      ref.read(invoiceListQueryProvider).filter.period,
      jalaliMonthOf(now),
    );

    // And the same on the second calendar, which is the one that could leave a
    // start with no end.
    await tester.tap(find.text(strings.invoiceFilterPeriodCustom));
    await tester.pumpAndSettle();
    await pickDay(tester, strings, 1);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, strings.actionCancel),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      ref.read(invoiceListQueryProvider).filter.period,
      jalaliMonthOf(now),
    );
  });
}

void unawaited(Future<void> future) {}
