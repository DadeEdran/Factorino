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

  group('jalaliMonthShifted - «ماه گذشته», and why it is not a subtraction', () {
    test('one step back is the previous Jalali month', () {
      final now = DateTime.utc(2026, 8, 24, 12);
      expect(jalaliMonthOf(now), jalaliMonth(1405, 6));
      expect(jalaliMonthShifted(now, -1), jalaliMonth(1405, 5));
      expect(jalaliMonthShifted(now, 1), jalaliMonth(1405, 7));
      expect(jalaliMonthShifted(now, 0), jalaliMonthOf(now));
    });

    test('it rolls over the Jalali year in both directions', () {
      // Farvardin is month 1: one step back is Esfand of the *previous* year,
      // and that is the boundary a naive `month - 1` gets wrong.
      final inFarvardin = DateTime.utc(2026, 3, 25, 12);
      expect(jalaliMonthOf(inFarvardin), jalaliMonth(1405, 1));
      expect(jalaliMonthShifted(inFarvardin, -1), jalaliMonth(1404, 12));

      final inEsfand = DateTime.utc(2026, 3, 15, 12);
      expect(jalaliMonthOf(inEsfand), jalaliMonth(1404, 12));
      expect(jalaliMonthShifted(inEsfand, 1), jalaliMonth(1405, 1));
    });

    test('a fixed span of days would be wrong, and here is where', () {
      // **The reason this helper exists rather than a subtraction at the call
      // site.** Shahrivar is 31 days. Stand on its last day and step back the
      // thirty days somebody would reach for, and you land on its *first* day
      // — the same month. «ماه گذشته» would then show the month the user is
      // already looking at, and only in some months of the year.
      final lastDayOfShahrivar = jalaliMonth(
        1405,
        6,
      ).start.add(const Duration(days: 30));
      expect(jalaliMonthOf(lastDayOfShahrivar), jalaliMonth(1405, 6));

      final naive = lastDayOfShahrivar.subtract(const Duration(days: 30));
      expect(
        jalaliMonthOf(naive),
        jalaliMonth(1405, 6),
        reason:
            'thirty days before the last day of a 31-day month is still that '
            'month, which is exactly why «ماه گذشته» may not be a subtraction',
      );
      expect(jalaliMonthShifted(lastDayOfShahrivar, -1), jalaliMonth(1405, 5));
    });

    test('a whole year of steps returns the same month a year earlier', () {
      final now = DateTime.utc(2026, 8, 24, 12);
      expect(jalaliMonthShifted(now, -12), jalaliMonth(1404, 6));
      expect(jalaliMonthShifted(now, 12), jalaliMonth(1406, 6));
    });

    test('the offset is a parameter here too', () {
      // Same rule as every other helper in this file: the Iran offset is a
      // default, never a hidden assumption.
      final now = DateTime.utc(2026, 8, 24, 12);
      expect(
        jalaliMonthShifted(now, -1, offset: Duration.zero),
        isNot(jalaliMonthShifted(now, -1)),
      );
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

  group('lastJalaliDayOf', () {
    // The inclusive last day of a half-open range -- the pair that is off by
    // one and whose difference nothing on screen would reveal (D-111).

    test('a day-aligned end belongs to the day before it', () {
      // «۱ تا ۱۰», stored as [1st 00:00, 11th 00:00). The user picked the 10th.
      final range = InstantRange(
        startOfJalaliDayUtc(Jalali(1405, 6, 1)),
        startOfJalaliDayUtc(Jalali(1405, 6, 11)),
      );

      expect(lastJalaliDayOf(range), startOfJalaliDayUtc(Jalali(1405, 6, 10)));
    });

    test(
      'a whole Jalali month ends on its own last day, whatever its length',
      () {
        // The three lengths a Jalali month has, which is exactly what a
        // fixed-duration step back would get wrong on one of them.
        expect(
          lastJalaliDayOf(jalaliMonth(1405, 1)), // Farvardin: 31
          startOfJalaliDayUtc(Jalali(1405, 1, 31)),
        );
        expect(
          lastJalaliDayOf(jalaliMonth(1405, 8)), // Aban: 30
          startOfJalaliDayUtc(Jalali(1405, 8, 30)),
        );
        expect(
          lastJalaliDayOf(jalaliMonth(1404, 12)), // Esfand, common year: 29
          startOfJalaliDayUtc(Jalali(1404, 12, 29)),
        );
      },
    );

    test('and on a leap Esfand it is the 30th', () {
      final leap = <int>[
        for (int year = 1400; year < 1420; year++)
          if (isJalaliLeapYear(year)) year,
      ].first;

      expect(
        lastJalaliDayOf(jalaliMonth(leap, 12)),
        startOfJalaliDayUtc(Jalali(leap, 12, 30)),
      );
    });

    test('a year ends on the last day of Esfand', () {
      expect(
        lastJalaliDayOf(jalaliYear(1405)),
        startOfJalaliDayUtc(Jalali(1405, 12, Jalali(1405, 12, 1).monthLength)),
      );
    });

    test('an end part-way through a day makes that day the last one', () {
      // Not a range this application builds, and the helper still has to be
      // right about it rather than assuming its own callers.
      final range = InstantRange(
        startOfJalaliDayUtc(Jalali(1405, 6, 1)),
        startOfJalaliDayUtc(Jalali(1405, 6, 10)).add(const Duration(hours: 5)),
      );

      expect(lastJalaliDayOf(range), startOfJalaliDayUtc(Jalali(1405, 6, 10)));
    });

    test('the result is always inside the range', () {
      // The property that makes it safe to display: whatever day comes back,
      // the range actually covers it.
      for (final range in <InstantRange>[
        jalaliMonth(1405, 1),
        jalaliMonth(1405, 8),
        jalaliMonth(1404, 12),
        jalaliYear(1405),
        jalaliDay(Jalali(1405, 6, 2)),
      ]) {
        expect(range.contains(lastJalaliDayOf(range)), isTrue);
      }
    });
  });
}
