import 'package:shamsi_date/shamsi_date.dart';

/// Converting between the instants the database stores and the Jalali civil
/// dates the user thinks in (D-005).
///
/// Pure Dart, and pure in the stronger sense too: **nothing here reads the
/// clock or the device timezone.** Every function takes the instant it works on
/// and the offset it works in, so the same input gives the same answer on a
/// phone in Tehran and a laptop in Berlin. `DateTime.now()` belongs to the
/// caller, which makes every boundary below testable against fixed values.
///
/// Two rules govern this file:
///
/// * **Stored values are UTC epoch milliseconds. Displayed values are Jalali.**
///   A localized date string is never the source of truth (D-005) -- it cannot
///   be compared, ranged, or re-localized, and it bakes one device's timezone
///   into the data permanently.
/// * **A "day" is a day in Iran, not a day in UTC.** An invoice issued at
///   22:00 Tehran on 1405/06/02 is stored as 18:30 UTC on the same date, but an
///   invoice issued at 02:00 Tehran is stored as 22:30 UTC on the *previous*
///   Gregorian date. Grouping by the UTC date would file it under the wrong
///   day, and the user would see yesterday's takings change overnight.

/// Iran Standard Time: UTC+03:30.
///
/// Iran abolished daylight saving in 2022 (the last transition was on
/// 2022-09-21), so this offset is constant for every date this application
/// will ever handle. It is a named constant rather than a literal scattered
/// through the file, and every function takes it as a **parameter** with this
/// as the default -- which is what D-006 means by deriving the boundary
/// explicitly rather than hardcoding it:
///
/// * a device set to another timezone still gets Iranian business boundaries,
///   because nothing here consults the device at all;
/// * if Iran ever restores DST, there is exactly one constant to replace and
///   one parameter through which a date-dependent rule could be supplied,
///   rather than a search for `3.5` across the codebase.
///
/// A timezone database (`package:timezone`) would be the general answer, and is
/// the right one if this app ever serves a second timezone. For a fixed-offset
/// zone with no transitions in range, it would add a dependency and an
/// initialization step to produce the same number.
const Duration kIranStandardOffset = Duration(hours: 3, minutes: 30);

/// The Jalali civil date and time in effect at [instant], seen from [offset].
///
/// [instant] may be UTC or local; it is converted to UTC first, so the caller
/// cannot leak their device's timezone in by accident.
Jalali jalaliAt(DateTime instant, {Duration offset = kIranStandardOffset}) {
  // Adding the offset to a UTC instant produces a UTC-flagged DateTime whose
  // calendar fields read as Tehran wall-clock time. `Jalali.fromDateTime` reads
  // exactly those fields, which is why this is a shift and not a conversion.
  return Jalali.fromDateTime(instant.toUtc().add(offset));
}

/// The UTC instant at which the Jalali day containing [date] begins in
/// [offset] -- that day's local midnight.
///
/// Any time-of-day on [date] is discarded: this is the start of the *day*.
DateTime startOfJalaliDayUtc(
  Jalali date, {
  Duration offset = kIranStandardOffset,
}) {
  final localMidnight = Jalali(date.year, date.month, date.day).toUtcDateTime();
  return localMidnight.subtract(offset);
}

/// Milliseconds in one day. The unit the day index below is counted in.
const int kMillisecondsPerDay = 86400000;

/// Which **Iranian civil day** [instantMillis] falls in, as a count of days
/// since the Iranian day that contained the epoch.
///
/// The one number a SQL `GROUP BY` can compute without a calendar. Grouping
/// invoices by day in SQLite means grouping them by *something*, and the stored
/// column is a UTC instant: `issue_date / 86400000` groups by the **UTC** day,
/// which files an invoice issued at 02:00 Tehran under the previous day. Adding
/// the offset first shifts the boundary to Tehran midnight, and the division
/// then lands every instant of one Iranian day on one integer.
///
/// The index is not itself a date and must not be shown to anyone; it is a
/// grouping key that [jalaliFromDayIndex] turns back into a date. The pair is
/// here rather than at the call site because §5 keeps calendar arithmetic in
/// this file, and because the two halves have to agree about the offset -- a
/// query grouped on one boundary and read back on another is off by a day for
/// three and a half hours out of every twenty-four.
///
/// **Truncating division, so this is only correct for instants at or after the
/// epoch.** Dart and SQLite both truncate toward zero, which for a negative
/// numerator rounds the wrong way and would collapse two days into one. Every
/// instant this application stores is a business date well after 1970, and
/// [dayIndexRange] refuses a range that reaches before it rather than returning
/// a quietly wrong grouping.
int dayIndexAtMillis(
  int instantMillis, {
  Duration offset = kIranStandardOffset,
}) {
  return (instantMillis + offset.inMilliseconds) ~/ kMillisecondsPerDay;
}

/// The Jalali date of the Iranian civil day numbered [dayIndex].
///
/// The inverse of [dayIndexAtMillis]: the index times a day, less the offset,
/// is the UTC instant that Iranian day began at.
Jalali jalaliFromDayIndex(
  int dayIndex, {
  Duration offset = kIranStandardOffset,
}) {
  return jalaliAt(
    DateTime.fromMillisecondsSinceEpoch(
      dayIndex * kMillisecondsPerDay - offset.inMilliseconds,
      isUtc: true,
    ),
    offset: offset,
  );
}

/// [day]'s Jalali date, carrying the Tehran time of day that [source] has.
///
/// **Why a picked date is not simply the start of a day.** The date picker
/// returns `startOfJalaliDayUtc`, which is correct for what it is asked -- a
/// day, not a moment. But an invoice's `issueDate` is the instant the document
/// states it was issued at, and the screen and the printed page now show the
/// time beside the date (D-092). Snapping to midnight every time the user
/// opened the picker would replace a real time with `۰۰:۰۰` on any invoice
/// whose date was ever touched, which is worse than showing no time at all: it
/// is a specific claim, and a false one.
///
/// So changing the *day* changes only the day. The form opens with the clock's
/// own instant, and that time of day survives a date correction.
///
/// **It cannot move the invoice into a different Jalali day**, which is the
/// property the reporting periods depend on: the result is that day's midnight
/// plus a time of day strictly less than 24 hours.
DateTime jalaliDayWithTimeOf(
  DateTime day, {
  required DateTime source,
  Duration offset = kIranStandardOffset,
}) {
  final DateTime local = source.toUtc().add(offset);
  final Duration timeOfDay = Duration(
    hours: local.hour,
    minutes: local.minute,
    seconds: local.second,
    milliseconds: local.millisecond,
  );
  return startOfJalaliDayUtc(
    jalaliAt(day, offset: offset),
    offset: offset,
  ).add(timeOfDay);
}

/// The UTC instant corresponding to a Jalali wall-clock date and time in
/// [offset].
///
/// The counterpart to [jalaliAt]: `jalaliAt(jalaliToUtc(d)) == d`.
DateTime jalaliToUtc(Jalali date, {Duration offset = kIranStandardOffset}) {
  return date.toUtcDateTime().subtract(offset);
}
