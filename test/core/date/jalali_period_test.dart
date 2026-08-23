import 'package:factorino/core/date/jalali_instant.dart';
import 'package:factorino/core/date/jalali_period.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// D-006: business and reporting periods are **Jalali**, computed in the Jalali
/// calendar and converted to UTC instants.
///
/// Every expected value here is a fixed, independently known date rather than
/// whatever the implementation produces. A conversion test that asserts against
/// its own output tests nothing.
void main() {
  // Nowruz anchors. Iran's new year falls on 20 or 21 March depending on the
  // year, which is precisely why these are written out rather than computed.
  const nowruz1403 = '2024-03-20';
  const nowruz1404 = '2025-03-21';
  const nowruz1405 = '2026-03-21';
  const nowruz1406 = '2027-03-21';

  /// Tehran midnight on a Gregorian date, as a UTC instant.
  ///
  /// Midnight at UTC+03:30 is 20:30 UTC on the previous day -- the shift that
  /// makes "the last day of the month" and "the first day of the next" fall on
  /// different Gregorian dates than a naive reading suggests.
  DateTime tehranMidnight(String gregorianDate) {
    return DateTime.parse('${gregorianDate}T00:00:00Z')
        .subtract(kIranStandardOffset);
  }

  group('instant to Jalali', () {
    test('converts a known instant', () {
      // 2026-08-24 12:00 UTC is 15:30 in Tehran on 1405/06/02.
      final jalali = jalaliAt(DateTime.utc(2026, 8, 24, 12));
      expect(jalali.year, 1405);
      expect(jalali.month, 6);
      expect(jalali.day, 2);
      expect(jalali.hour, 15);
      expect(jalali.minute, 30);
    });

    test(
      'a local DateTime gives the same answer as the same instant in UTC',
      () {
        // The device timezone must not reach the result (D-006).
        final instant = DateTime.utc(2026, 8, 24, 12);
        expect(
          jalaliAt(instant.toLocal()).toDateTime(),
          jalaliAt(instant).toDateTime(),
        );
      },
    );

    test('late evening in Tehran is still the same Jalali day', () {
      // 20:29 UTC is 23:59 Tehran: the last minute of 1405/06/02.
      final jalali = jalaliAt(DateTime.utc(2026, 8, 24, 20, 29));
      expect(jalali.day, 2);

      // 20:30 UTC is midnight: the next Jalali day has begun.
      expect(jalaliAt(DateTime.utc(2026, 8, 24, 20, 30)).day, 3);
    });

    test('round-trips through jalaliToUtc', () {
      final instant = DateTime.utc(2026, 8, 24, 12, 34, 56);
      expect(jalaliToUtc(jalaliAt(instant)), instant);
    });
  });

  group('jalaliMonth - the boundaries that actually break', () {
    test('Farvardin 1405 starts at Tehran midnight on Nowruz', () {
      final range = jalaliMonth(1405, 1);
      expect(range.start, tehranMidnight(nowruz1405));
      // The first six Jalali months have 31 days.
      expect(range.duration, const Duration(days: 31));
    });

    test(
      'a 31-day month, a 30-day month and Esfand have the right lengths',
      () {
        expect(jalaliMonth(1405, 1).duration, const Duration(days: 31));
        expect(jalaliMonth(1405, 6).duration, const Duration(days: 31));
        expect(jalaliMonth(1405, 7).duration, const Duration(days: 30));
        expect(jalaliMonth(1405, 11).duration, const Duration(days: 30));
        // 1405 is not a leap year, so Esfand has 29 days.
        expect(jalaliMonth(1405, 12).duration, const Duration(days: 29));
      },
    );

    test('Esfand has 30 days in a leap year', () {
      expect(isJalaliLeapYear(1403), isTrue);
      expect(jalaliMonth(1403, 12).duration, const Duration(days: 30));
      expect(jalaliMonthLength(1403, 12), 30);

      expect(isJalaliLeapYear(1405), isFalse);
      expect(jalaliMonthLength(1405, 12), 29);
    });

    test(
      'Esfand ends exactly where Farvardin begins - the year transition',
      () {
        // The single most consequential boundary in the file: an invoice issued
        // in the last hour of Esfand belongs to the old business year.
        final esfand1404 = jalaliMonth(1404, 12);
        final farvardin1405 = jalaliMonth(1405, 1);

        expect(esfand1404.end, farvardin1405.start);
        expect(farvardin1405.start, tehranMidnight(nowruz1405));
      },
    );

    test('the leap-year Esfand 30 is inside its month, and 1405 has none', () {
      final esfand1403 = jalaliMonth(1403, 12);
      final lastDay = jalaliToUtc(Jalali(1403, 12, 30, 12));

      expect(esfand1403.contains(lastDay), isTrue);
      // Esfand 30 of 1403 is 2025-03-20, the day before Nowruz 1404.
      expect(esfand1403.end, tehranMidnight(nowruz1404));
    });

    test('consecutive months tile the timeline with no gap and no overlap', () {
      for (var month = 1; month < 12; month++) {
        expect(
          jalaliMonth(1405, month).end,
          jalaliMonth(1405, month + 1).start,
          reason: 'month $month must end where month ${month + 1} begins',
        );
      }
    });

    test('rejects a month outside 1-12', () {
      expect(() => jalaliMonth(1405, 0), throwsA(isA<ArgumentError>()));
      expect(() => jalaliMonth(1405, 13), throwsA(isA<ArgumentError>()));
    });
  });

  group('jalaliMonthOf - what a dashboard tile means', () {
    test('an instant in the middle of a month resolves to that month', () {
      final range = jalaliMonthOf(DateTime.utc(2026, 8, 24, 12));
      expect(range, jalaliMonth(1405, 6));
    });

    test('the first instant of a Jalali month resolves to that month', () {
      // Tehran midnight on Nowruz: the boundary case a >= / > mistake breaks.
      final firstInstant = tehranMidnight(nowruz1405);
      expect(jalaliMonthOf(firstInstant), jalaliMonth(1405, 1));
      expect(jalaliMonth(1405, 1).contains(firstInstant), isTrue);
    });

    test('the last instant of a Jalali month resolves to that month', () {
      final lastInstant = jalaliMonth(
        1405,
        1,
      ).end.subtract(const Duration(milliseconds: 1));
      expect(jalaliMonthOf(lastInstant), jalaliMonth(1405, 1));
    });

    test('one millisecond later is the next month, not neither', () {
      final firstOfNext = jalaliMonth(1405, 1).end;
      expect(jalaliMonth(1405, 1).contains(firstOfNext), isFalse);
      expect(jalaliMonth(1405, 2).contains(firstOfNext), isTrue);
      expect(jalaliMonthOf(firstOfNext), jalaliMonth(1405, 2));
    });

    test('a Gregorian month boundary would give a different answer', () {
      // The bug D-006 exists to prevent, stated as a test. 2026-03-25 is in
      // Gregorian March but in Farvardin 1405 -- and 2026-03-15 is in the same
      // Gregorian month but in Esfand 1404, the previous business *year*.
      final afterNowruz = DateTime.utc(2026, 3, 25, 12);
      final beforeNowruz = DateTime.utc(2026, 3, 15, 12);

      expect(jalaliMonthOf(afterNowruz), jalaliMonth(1405, 1));
      expect(jalaliMonthOf(beforeNowruz), jalaliMonth(1404, 12));
      expect(jalaliMonthOf(afterNowruz), isNot(jalaliMonthOf(beforeNowruz)));
      expect(jalaliYearOf(afterNowruz), isNot(jalaliYearOf(beforeNowruz)));
    });
  });

  group('jalaliDay', () {
    test('runs Tehran midnight to Tehran midnight', () {
      final range = jalaliDayOf(DateTime.utc(2026, 8, 24, 12));
      expect(range.duration, const Duration(days: 1));
      expect(range.start, DateTime.utc(2026, 8, 23, 20, 30));
      expect(range.end, DateTime.utc(2026, 8, 24, 20, 30));
    });

    test('an instant just after Tehran midnight belongs to the new day', () {
      // 21:00 UTC on 23 August is 00:30 Tehran on 24 August: a sale made
      // "last night" that a UTC-day grouping would file under the day before.
      final lateNight = DateTime.utc(2026, 8, 23, 21);
      expect(jalaliAt(lateNight).day, 2);
      expect(jalaliDayOf(lateNight).start, DateTime.utc(2026, 8, 23, 20, 30));
    });

    test('crosses a month end correctly', () {
      // The last day of Esfand 1404, which is a 29-day month.
      final lastDay = jalaliDay(Jalali(1404, 12, 29));
      expect(lastDay.end, jalaliMonth(1405, 1).start);
    });
  });

  group('jalaliYear', () {
    test('runs Farvardin 1 to Farvardin 1', () {
      final year = jalaliYear(1405);
      expect(year.start, tehranMidnight(nowruz1405));
      expect(year.end, tehranMidnight(nowruz1406));
      expect(year.duration, const Duration(days: 365));
    });

    test('a leap year is 366 days', () {
      final year = jalaliYear(1403);
      expect(year.start, tehranMidnight(nowruz1403));
      expect(year.end, tehranMidnight(nowruz1404));
      expect(year.duration, const Duration(days: 366));
    });

    test('the twelve months exactly fill the year', () {
      for (final y in <int>[1403, 1404, 1405]) {
        final year = jalaliYear(y);
        expect(jalaliMonth(y, 1).start, year.start);
        expect(jalaliMonth(y, 12).end, year.end);

        var days = 0;
        for (var m = 1; m <= 12; m++) {
          days += jalaliMonthLength(y, m);
        }
        expect(Duration(days: days), year.duration, reason: 'year $y');
      }
    });

    test('jalaliYearOf resolves an instant to its business year', () {
      expect(jalaliYearOf(DateTime.utc(2026, 8, 24, 12)), jalaliYear(1405));
    });
  });

  group('the offset is a parameter, not a hidden assumption', () {
    test('a different offset moves the boundary by exactly that much', () {
      final tehran = jalaliMonth(1405, 1);
      final utc = jalaliMonth(1405, 1, offset: Duration.zero);

      expect(tehran.start, utc.start.subtract(kIranStandardOffset));
      expect(tehran.duration, utc.duration);
    });

    test('Iran Standard Time is UTC+03:30', () {
      expect(kIranStandardOffset, const Duration(hours: 3, minutes: 30));
    });
  });

  group('InstantRange', () {
    test('is half-open: start included, end excluded', () {
      final range = jalaliMonth(1405, 1);
      expect(range.contains(range.start), isTrue);
      expect(range.contains(range.end), isFalse);
      expect(
        range.contains(range.end.subtract(const Duration(milliseconds: 1))),
        isTrue,
      );
    });

    test('exposes epoch milliseconds for querying', () {
      final range = jalaliMonth(1405, 1);
      expect(range.startMillis, range.start.millisecondsSinceEpoch);
      expect(range.endMillis, range.end.millisecondsSinceEpoch);
      expect(range.startMillis, lessThan(range.endMillis));
    });

    test('normalizes both bounds to UTC', () {
      final range = InstantRange(
        DateTime.utc(2026, 1, 1).toLocal(),
        DateTime.utc(2026, 2, 1).toLocal(),
      );
      expect(range.start.isUtc, isTrue);
      expect(range.end.isUtc, isTrue);
      expect(range.start, DateTime.utc(2026, 1, 1));
    });

    test('rejects an empty or inverted range', () {
      expect(
        () => InstantRange(DateTime.utc(2026, 2, 1), DateTime.utc(2026, 1, 1)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => InstantRange(DateTime.utc(2026, 1, 1), DateTime.utc(2026, 1, 1)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('compares by value', () {
      expect(jalaliMonth(1405, 1), jalaliMonth(1405, 1));
      expect(jalaliMonth(1405, 1), isNot(jalaliMonth(1405, 2)));
      expect(jalaliMonth(1405, 1).hashCode, jalaliMonth(1405, 1).hashCode);
    });
  });
}
