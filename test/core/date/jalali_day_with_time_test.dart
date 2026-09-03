import 'package:factorino/core/date/jalali_instant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// [jalaliDayWithTimeOf] — the arithmetic behind D-092.
///
/// The date picker returns a **day** (`startOfJalaliDayUtc`), which is correct
/// for what it is asked. An invoice's `issueDate` is a **moment**, and since
/// the screen and the printed page now show its time, assigning the picked day
/// whole would stamp ۰۰:۰۰ on any invoice whose date was ever corrected — a
/// specific claim, and a false one.
///
/// Two properties, and the second is the one that matters more:
///
/// * the time of day is carried across;
/// * **the result never leaves the picked Jalali day.** Every reporting period
///   in this application is a Jalali month resolved to UTC instants (§5, D-006),
///   so a carry that could overflow a day boundary would file an invoice under
///   the wrong month on the dashboard — the exact failure that whole layer
///   exists to prevent.
void main() {
  /// 14:30 Tehran on 1405/06/02.
  final DateTime afternoon = DateTime.utc(2026, 8, 24, 11);

  test('the day comes from the pick and the clock from the source', () {
    final DateTime picked = startOfJalaliDayUtc(Jalali(1405, 9, 1));
    final DateTime result = jalaliDayWithTimeOf(picked, source: afternoon);

    final Jalali landed = jalaliAt(result);
    expect(<int>[landed.year, landed.month, landed.day], <int>[1405, 9, 1]);
    expect(<int>[landed.hour, landed.minute], <int>[14, 30]);
  });

  test('a source already at midnight stays at midnight', () {
    // Nothing is invented. An invoice whose recorded instant genuinely is the
    // start of a day keeps saying so.
    final DateTime midnight = startOfJalaliDayUtc(Jalali(1405, 6, 2));
    final DateTime result = jalaliDayWithTimeOf(
      startOfJalaliDayUtc(Jalali(1405, 9, 1)),
      source: midnight,
    );

    expect(result, startOfJalaliDayUtc(Jalali(1405, 9, 1)));
  });

  test('it never crosses a day boundary, at either edge of the clock', () {
    // The property the reporting periods depend on. Checked at the two
    // instants a naive implementation would break on -- one minute after
    // midnight and one minute before it -- across a month end, a year end and
    // a leap day.
    final List<DateTime> sources = <DateTime>[
      // 00:01 Tehran
      DateTime.utc(2026, 8, 24, 20, 31),
      // 23:59 Tehran
      DateTime.utc(2026, 8, 24, 20, 29),
      afternoon,
    ];

    final List<Jalali> days = <Jalali>[
      Jalali(1405, 1, 1),
      Jalali(1405, 6, 31),
      Jalali(1405, 7, 1),
      Jalali(1405, 12, 29),
      // 1403 is a leap year in the Jalali calendar: Esfand has 30 days.
      Jalali(1403, 12, 30),
    ];

    for (final Jalali day in days) {
      for (final DateTime source in sources) {
        final Jalali landed = jalaliAt(
          jalaliDayWithTimeOf(startOfJalaliDayUtc(day), source: source),
        );
        expect(
          <int>[landed.year, landed.month, landed.day],
          <int>[day.year, day.month, day.day],
          reason: 'carrying $source onto $day crossed a day boundary',
        );
      }
    }
  });

  test('the result is a UTC instant, like every stored value (D-005)', () {
    expect(
      jalaliDayWithTimeOf(
        startOfJalaliDayUtc(Jalali(1405, 9, 1)),
        source: afternoon,
      ).isUtc,
      isTrue,
    );
  });
}
