import 'package:factorino/core/date/jalali_instant.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/widgets/jalali_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../features/screen_harness.dart';

/// The Jalali date picker.
///
/// Built rather than taken from a package, and rather than localizing
/// Material's, because Material's is a **Gregorian** grid: Persian digits over
/// Gregorian month lengths, where Farvardin does not exist and the user counts
/// days in the wrong month.
///
/// The two claims that make it correct, and that a rendering test can actually
/// check: the grid puts each day in the right column for the **Iranian** week,
/// and what comes back is the UTC instant that Jalali day begins at (D-005) —
/// not a formatted string, and not a Gregorian date.
void main() {
  /// Opens the picker over a trivial host and returns whatever it produced.
  Future<DateTime?> pick(
    WidgetTester tester, {
    required DateTime initial,
    DateTime? firstAllowed,
    required Future<void> Function(WidgetTester tester) interact,
  }) async {
    DateTime? result;
    bool completed = false;

    await pumpScreen(
      tester,
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async {
            result = await showJalaliDatePicker(
              context,
              initial: initial,
              firstAllowed: firstAllowed,
            );
            completed = true;
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await interact(tester);
    await tester.pumpAndSettle();

    expect(completed, isTrue, reason: 'the picker never returned');
    return result;
  }

  AppStrings stringsOf(WidgetTester tester) =>
      AppStrings.of(tester.element(find.byType(AlertDialog)));

  testWidgets('it opens on the Jalali month of the initial date', (
    WidgetTester tester,
  ) async {
    // 1405/06/02 — Shahrivar, which in Gregorian terms straddles August and
    // September. A Gregorian grid would show one of those two.
    final DateTime initial = startOfJalaliDayUtc(Jalali(1405, 6, 2));

    await pick(
      tester,
      initial: initial,
      interact: (WidgetTester tester) async {
        expect(find.textContaining('شهریور'), findsOneWidget);
        expect(find.textContaining('۱۴۰۵'), findsOneWidget);
        await tester.tap(
          find.text(
            AppStrings.of(tester.element(find.byType(AlertDialog)))
                .actionCancel,
          ),
        );
      },
    );
  });

  testWidgets('picking a day returns the UTC instant that day begins at', (
    WidgetTester tester,
  ) async {
    final DateTime? picked = await pick(
      tester,
      initial: startOfJalaliDayUtc(Jalali(1405, 6, 2)),
      interact: (WidgetTester tester) async {
        final AppStrings strings = stringsOf(tester);
        // ۱۵ in Persian digits — the grid renders day numbers, not indices.
        await tester.tap(find.text('۱۵'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.actionSave));
      },
    );

    expect(picked, isNotNull);
    // The instant, not a string, and it is midnight Tehran expressed in UTC —
    // 20:30 on the previous UTC day, because Iran is UTC+3:30.
    expect(picked, startOfJalaliDayUtc(Jalali(1405, 6, 15)));
    expect(picked!.isUtc, isTrue);
    // And it reads back as the day that was tapped.
    expect(jalaliAt(picked).year, 1405);
    expect(jalaliAt(picked).month, 6);
    expect(jalaliAt(picked).day, 15);
  });

  testWidgets('the week starts on Saturday, so days land in the right column', (
    WidgetTester tester,
  ) async {
    // The claim: the grid is laid out on `Jalali.weekDay`, where **Saturday is
    // 1**, and not on `DateTime.weekday`, where Monday is 1 and Sunday is 7.
    // Getting that wrong does not look broken — it looks like a calendar — it
    // just puts every date in the month under the wrong heading.
    final Jalali first = Jalali(1405, 6, 1);
    final int iranianColumn = first.weekDay - 1;
    final int gregorianColumn =
        first.toDateTime().weekday % 7; // Dart's Sunday(7) -> 0
    expect(
      iranianColumn,
      isNot(gregorianColumn),
      reason:
          'a date where the two conventions disagree, or this proves '
          'nothing',
    );

    await pick(
      tester,
      initial: startOfJalaliDayUtc(first),
      interact: (WidgetTester tester) async {
        final AppStrings strings = stringsOf(tester);
        final List<String> headings = <String>[
          strings.weekdayShanbeShort,
          strings.weekdayYekshanbeShort,
          strings.weekdayDoshanbeShort,
          strings.weekdaySeshanbeShort,
          strings.weekdayChaharshanbeShort,
          strings.weekdayPanjshanbeShort,
          strings.weekdayJomeShort,
        ];
        final List<double> columnX = <double>[
          for (final String heading in headings)
            tester.getCenter(find.text(heading)).dx,
        ];

        // Right-to-left: the first column (Saturday) is the rightmost.
        expect(
          columnX.first,
          greaterThan(columnX.last),
          reason: 'the grid must run right to left',
        );

        final double dayOneX = tester.getCenter(find.text('۱')).dx;
        expect(
          dayOneX,
          closeTo(columnX[iranianColumn], 1),
          reason: 'day 1 sits under its Iranian weekday',
        );
        expect(
          (dayOneX - columnX[gregorianColumn]).abs(),
          greaterThan(1),
          reason: 'and not where DateTime.weekday would have put it',
        );

        await tester.tap(find.text(strings.actionCancel));
      },
    );
  });

  testWidgets('days before firstAllowed cannot be picked', (
    WidgetTester tester,
  ) async {
    // What a due date does: it may not precede its invoice's issue date.
    // Enforced by making the days unselectable rather than by validating
    // afterwards — a rule the user meets before breaking it.
    final DateTime? picked = await pick(
      tester,
      initial: startOfJalaliDayUtc(Jalali(1405, 6, 15)),
      firstAllowed: startOfJalaliDayUtc(Jalali(1405, 6, 10)),
      interact: (WidgetTester tester) async {
        final AppStrings strings = stringsOf(tester);
        await tester.tap(find.text('۵'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.actionSave));
      },
    );

    // The tap on day 5 did nothing, so the selection is still the initial day.
    expect(picked, startOfJalaliDayUtc(Jalali(1405, 6, 15)));
  });

  testWidgets('browsing months does not move the selection', (
    WidgetTester tester,
  ) async {
    final DateTime? picked = await pick(
      tester,
      initial: startOfJalaliDayUtc(Jalali(1405, 6, 2)),
      interact: (WidgetTester tester) async {
        final AppStrings strings = stringsOf(tester);
        await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_right));
        await tester.pumpAndSettle();
        expect(find.textContaining('مهر'), findsOneWidget);

        await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.actionSave));
      },
    );

    // Unmoved: browsing is navigation, not selection.
    expect(picked, startOfJalaliDayUtc(Jalali(1405, 6, 2)));
  });

  testWidgets('a 31-day month browses without falling off a 30-day one', (
    WidgetTester tester,
  ) async {
    // Esfand has 29 days in a common year. Adding a month to Farvardin 31 by
    // calendar fields lands on a day that does not exist, and `shamsi_date`
    // throws rather than clamping — which is why the picker moves by month on
    // day 1, never on the selected day.
    await pick(
      tester,
      initial: startOfJalaliDayUtc(Jalali(1405, 1, 31)),
      interact: (WidgetTester tester) async {
        final AppStrings strings = stringsOf(tester);
        for (int i = 0; i < 13; i++) {
          await tester.tap(
            find.widgetWithIcon(IconButton, Icons.chevron_right),
          );
          await tester.pumpAndSettle();
        }
        // Twelve months on from Farvardin 1405 is Farvardin 1406, plus one.
        expect(find.textContaining('اردیبهشت'), findsOneWidget);
        expect(find.textContaining('۱۴۰۶'), findsOneWidget);
        await tester.tap(find.text(strings.actionCancel));
      },
    );
  });
}
