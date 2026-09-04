import 'package:shamsi_date/shamsi_date.dart';

import 'jalali_instant.dart';

/// Jalali reporting periods, as UTC instant ranges the database can be queried
/// on (D-006).
///
/// the project spec: *"Business/reporting periods are Jalali, not Gregorian.
/// 'فروش این ماه' means the current **Jalali** month."* This file is where that
/// requirement is met. Every period is computed in the Jalali calendar first
/// and only then converted to instants, because the two calendars' month
/// boundaries never coincide: a Gregorian month applied to a dashboard tile
/// produces a number that matches nothing the user recognises, and it does so
/// without looking wrong.
///
/// Nothing here reads the clock. `jalaliMonthOf(DateTime.now())` is the
/// caller's line to write, which keeps every boundary below testable against
/// fixed dates.

/// A half-open range of instants: `start` included, `end` excluded.
///
/// Half-open on purpose. An inclusive end would have to be "the last
/// millisecond of the period", which is the classic off-by-one in period
/// reporting -- a payment recorded in that final millisecond is dropped from
/// one period without appearing in the next. With a half-open range, adjacent
/// periods tile the timeline exactly: one period's `end` is the next one's
/// `start`, and every instant belongs to exactly one of them.
///
/// Query it as `column >= startMillis AND column < endMillis`.
class InstantRange {
  const InstantRange._(this.start, this.end);

  /// Both bounds are normalized to UTC, so a range built in one timezone
  /// cannot be compared wrongly against one built in another.
  factory InstantRange(DateTime start, DateTime end) {
    final utcStart = start.toUtc();
    final utcEnd = end.toUtc();
    if (!utcEnd.isAfter(utcStart)) {
      throw ArgumentError(
        'an InstantRange must be non-empty: end ($utcEnd) must be after '
        'start ($utcStart)',
      );
    }
    return InstantRange._(utcStart, utcEnd);
  }

  /// Inclusive lower bound, UTC.
  final DateTime start;

  /// Exclusive upper bound, UTC.
  final DateTime end;

  /// The bounds as epoch milliseconds -- the form the schema stores (D-005),
  /// so a query needs no further conversion at the call site.
  int get startMillis => start.millisecondsSinceEpoch;
  int get endMillis => end.millisecondsSinceEpoch;

  Duration get duration => end.difference(start);

  bool contains(DateTime instant) {
    final utc = instant.toUtc();
    return !utc.isBefore(start) && utc.isBefore(end);
  }

  @override
  bool operator ==(Object other) =>
      other is InstantRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() =>
      'InstantRange(${start.toIso8601String()} .. ${end.toIso8601String()})';
}

/// The Jalali day [date] falls in, as an instant range.
InstantRange jalaliDay(Jalali date, {Duration offset = kIranStandardOffset}) {
  final start = startOfJalaliDayUtc(date, offset: offset);
  final next = Jalali(date.year, date.month, date.day).addDays(1);
  return InstantRange(start, startOfJalaliDayUtc(next, offset: offset));
}

/// The Jalali month [year]/[month], as an instant range.
///
/// The end bound is the first day of the *following* month, so Esfand's length
/// -- 29 days, or 30 in a leap year -- never has to be computed here. Getting
/// that wrong is the single most likely bug in this file, so the arithmetic is
/// arranged to make it impossible rather than to make it correct.
InstantRange jalaliMonth(
  int year,
  int month, {
  Duration offset = kIranStandardOffset,
}) {
  _checkMonth(month);
  final start = Jalali(year, month, 1);
  final nextMonth = month == 12
      ? Jalali(year + 1, 1, 1)
: Jalali(year, month + 1, 1);
  return InstantRange(
    startOfJalaliDayUtc(start, offset: offset),
    startOfJalaliDayUtc(nextMonth, offset: offset),
  );
}

/// The Jalali week containing [date], as an instant range.
///
/// **The Iranian week runs Saturday to Friday.** `shamsi_date` numbers weekdays
/// 1 for شنبه through 7 for جمعه, which is already that week, so the first day
/// is simply [date] stepped back by `weekDay - 1`. Reaching for
/// `DateTime.weekday` here -- which numbers from Monday -- would shift every
/// week by two days, and the figure would still look plausible: a week's sales
/// is never obviously wrong, it is only wrong.
///
/// Seven days from that Saturday, so the end bound never has to be reasoned
/// about separately, and a week that straddles a month or a year boundary is
/// the same arithmetic as one that does not.
InstantRange jalaliWeek(Jalali date, {Duration offset = kIranStandardOffset}) {
  final Jalali saturday = Jalali(
    date.year,
    date.month,
    date.day,
  ).addDays(-(date.weekDay - 1));
  return InstantRange(
    startOfJalaliDayUtc(saturday, offset: offset),
    startOfJalaliDayUtc(saturday.addDays(7), offset: offset),
  );
}

/// The Jalali year [year], as an instant range: Farvardin 1 to Farvardin 1.
InstantRange jalaliYear(int year, {Duration offset = kIranStandardOffset}) {
  return InstantRange(
    startOfJalaliDayUtc(Jalali(year, 1, 1), offset: offset),
    startOfJalaliDayUtc(Jalali(year + 1, 1, 1), offset: offset),
  );
}

/// The Jalali day containing [instant].
InstantRange jalaliDayOf(
  DateTime instant, {
  Duration offset = kIranStandardOffset,
}) {
  return jalaliDay(jalaliAt(instant, offset: offset), offset: offset);
}

/// The Jalali week containing [instant] -- what "این هفته" means on a
/// dashboard.
InstantRange jalaliWeekOf(
  DateTime instant, {
  Duration offset = kIranStandardOffset,
}) {
  return jalaliWeek(jalaliAt(instant, offset: offset), offset: offset);
}

/// The Jalali month containing [instant] -- what "این ماه" means on a
/// dashboard.
InstantRange jalaliMonthOf(
  DateTime instant, {
  Duration offset = kIranStandardOffset,
}) {
  final date = jalaliAt(instant, offset: offset);
  return jalaliMonth(date.year, date.month, offset: offset);
}

/// The Jalali month [months] steps away from the one [instant] falls in.
///
/// **Calendar arithmetic belongs here and nowhere else** (/// D-006). The tempting one-liner at a call site -- subtract a millisecond from
/// the start of this month, or subtract thirty days -- is wrong in a way that
/// only shows up some months: Jalali months are 31 days for the first six, 30
/// for the next five, and 29 or 30 for Esfand depending on the year. Shifting
/// the month *number* and letting [jalaliMonth] resolve the boundaries is the
/// only form that is right in every month of every year.
///
/// Negative steps go backwards, and the year rolls over in both directions.
InstantRange jalaliMonthShifted(
  DateTime instant,
  int months, {
  Duration offset = kIranStandardOffset,
}) {
  final date = jalaliAt(instant, offset: offset);
  // Counted as absolute months from year zero, so the rollover is a division
  // rather than a pair of if-statements that each have to be got right.
  final absolute = date.year * 12 + (date.month - 1) + months;
  return jalaliMonth(absolute ~/ 12, absolute % 12 + 1, offset: offset);
}

/// The Jalali year containing [instant] -- the user's business and tax year.
InstantRange jalaliYearOf(
  DateTime instant, {
  Duration offset = kIranStandardOffset,
}) {
  return jalaliYear(jalaliAt(instant, offset: offset).year, offset: offset);
}

/// The **last Jalali day inside** [range], as the instant that day begins.
///
/// The counterpart of the half-open bound, and it exists because the two are
/// off by a day and the difference is invisible on screen. `InstantRange.end` is
/// *exclusive*: for a range built from a user picking «۱ تا ۱۰», the stored end
/// is the 11th's midnight, because that is what makes adjacent periods tile the
/// timeline exactly. Showing that instant back to the user names a day they did
/// not pick, and it names it on the label that says what they are looking at.
///
/// **No arithmetic on a duration**, which is what a first attempt reaches for —
/// stepping back a millisecond and reading the day off that. This asks the
/// question directly instead: an end that falls exactly on a day boundary
/// belongs to the day before it, and an end that falls part-way through a day
/// makes that day the last one the range touches. Exact whatever the month
/// length, and there is no magic number to get wrong.
///
/// Used by the invoice filter's custom range (D-111); it lives here rather than
/// in the sheet because "which day is the last one in this range" is calendar
/// arithmetic, and §3 keeps that out of a widget.
DateTime lastJalaliDayOf(
  InstantRange range, {
  Duration offset = kIranStandardOffset,
}) {
  final endDay = jalaliAt(range.end, offset: offset);
  final startOfEndDay = startOfJalaliDayUtc(endDay, offset: offset);
  if (startOfEndDay != range.end) return startOfEndDay;
  return startOfJalaliDayUtc(endDay.addDays(-1), offset: offset);
}

/// The Iranian civil days [range] covers, as the inclusive first and last
/// [dayIndexAtMillis] index.
///
/// What a per-day aggregate is read back against: the query groups on the index
/// and returns only days that have rows, so the caller needs the full span to
/// tell "no sales" from "not in this month" — and it must be the span the query
/// itself used, not one re-derived from a Jalali month, or the two disagree at
/// the boundary.
///
/// **Refuses a range reaching before the epoch.** The index is a truncating
/// division, which rounds toward zero rather than downward, so a negative
/// instant would land on the wrong day rather than fail. That cannot arise from
/// a business date, and if it ever does it should stop rather than report a
/// figure under the wrong heading.
({int first, int last}) dayIndexRange(
  InstantRange range, {
  Duration offset = kIranStandardOffset,
}) {
  if (range.startMillis < 0) {
    throw ArgumentError.value(
      range,
      'range',
      'day indexing is defined only at or after the epoch',
    );
  }
  return (
    first: dayIndexAtMillis(range.startMillis, offset: offset),
    // The end is exclusive, so the last day inside the range is the day the
    // instant *before* it falls in — the same off-by-one [lastJalaliDayOf]
    // exists to keep out of call sites.
    last: dayIndexAtMillis(range.endMillis - 1, offset: offset),
  );
}

/// The number of days in Jalali month [year]/[month]: 31, 30, or 29/30 for
/// Esfand depending on the leap year.
int jalaliMonthLength(int year, int month) {
  _checkMonth(month);
  return Jalali(year, month, 1).monthLength;
}

/// Whether [year] is a Jalali leap year, in which Esfand has 30 days.
bool isJalaliLeapYear(int year) => Jalali(year, 1, 1).isLeapYear();

void _checkMonth(int month) {
  if (month < 1 || month > 12) {
    throw ArgumentError.value(month, 'month', 'must be between 1 and 12');
  }
}
