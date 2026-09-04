/// Rendering dates and identifiers for display.
///
/// The display counterpart of `core/date/`, which owns the arithmetic. That
/// file converts instants to Jalali civil dates and computes reporting
/// boundaries; this one turns the result into something a Persian reader reads.
/// The split matters because the arithmetic is on the correctness path — a
/// wrong month boundary is a wrong dashboard figure — while this file only
/// decides how a correct value looks.
///
/// Pure Dart, no Flutter imports, like the rest of `core/formatting/`.
library;

import 'package:shamsi_date/shamsi_date.dart';

import '../date/jalali_instant.dart';
import '../date/jalali_period.dart';
import 'persian_text.dart';

/// The Jalali date at [instant], as `۱۴۰۵/۰۶/۰۲`.
///
/// Zero-padded so a column of dates aligns — with `tnum` on the numeral styles
/// (D-033) an unpadded column would still be ragged, because the missing digit
/// is a missing character rather than a narrow one.
///
/// Wrapped in a bidi isolate: see [isolate].
String formatJalaliDate(
  DateTime instant, {
  Duration offset = kIranStandardOffset,
}) {
  final Jalali date = jalaliAt(instant, offset: offset);
  final String text =
      '${date.year.toString().padLeft(4, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}';
  return isolate(toPersianDigits(text));
}

/// The Jalali date at [instant] with its month named: `۲ شهریور ۱۴۰۵`.
///
/// [monthNames] is the twelve Jalali month names **in order, from the
/// localization layer**. They are passed in rather than held here for the
/// reason D-034 gives: Persian text lives in the ARB and nowhere else, and a
/// month name is copy like any other. `no_hardcoded_strings_test.dart` would
/// fail this file if the names were inlined.
///
/// Used where a date is read rather than scanned — "last backup", an invoice
/// header — because a named month is unambiguous at a glance in a way that
/// `۱۴۰۵/۰۶/۰۲` is not.
String formatJalaliDateLong(
  DateTime instant, {
  required List<String> monthNames,
  Duration offset = kIranStandardOffset,
}) {
  if (monthNames.length != 12) {
    throw ArgumentError.value(
      monthNames.length,
      'monthNames',
      'expected the twelve Jalali month names in order',
    );
  }
  final Jalali date = jalaliAt(instant, offset: offset);
  final String day = toPersianDigits('${date.day}');
  final String year = toPersianDigits('${date.year}');
  return '$day ${monthNames[date.month - 1]} $year';
}

/// The Tehran wall-clock time at [instant], as `۱۴:۳۰`.
///
/// Zero-padded and 24-hour: Iranian business documents quote a 24-hour clock,
/// and an unpadded hour makes a column of times ragged for the same reason
/// [formatJalaliDate] pads a date.
///
/// Wrapped in a bidi isolate, and that is not decoration here. A time is
/// digits joined by a colon, and a colon is bidi-neutral: dropped bare beside
/// Persian words it resolves against whatever sits on either side, and the same
/// time can render as `۳۰:۱۴` depending on the sentence around it. The isolate
/// makes the run resolve against itself. See [isolate].
///
/// The isolates are stripped again at `DocumentTextBoundary` on the way to the
/// PDF, where they would cost a character instead (D-070 finding 1) -- so the
/// one formatter is right for both surfaces.
String formatJalaliTime(
  DateTime instant, {
  Duration offset = kIranStandardOffset,
}) {
  final DateTime local = instant.toUtc().add(offset);
  final String text =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return isolate(toPersianDigits(text));
}

/// The Jalali month and year at [instant]: `شهریور ۱۴۰۵`.
///
/// The label a reporting period carries on a dashboard, where "این ماه" alone
/// leaves the reader to trust that the app and they mean the same month
/// (D-006).
String formatJalaliMonthYear(
  DateTime instant, {
  required List<String> monthNames,
  Duration offset = kIranStandardOffset,
}) {
  if (monthNames.length != 12) {
    throw ArgumentError.value(
      monthNames.length,
      'monthNames',
      'expected the twelve Jalali month names in order',
    );
  }
  final Jalali date = jalaliAt(instant, offset: offset);
  return '${monthNames[date.month - 1]} ${toPersianDigits('${date.year}')}';
}

/// The Jalali year at [instant], as `۱۴۰۵`.
///
/// The caption a yearly figure carries. Digits only — no copy — so it does not
/// take the twelve month names it would otherwise need.
String formatJalaliYear(
  DateTime instant, {
  Duration offset = kIranStandardOffset,
}) {
  return toPersianDigits('${jalaliAt(instant, offset: offset).year}');
}

/// The two ends of [range] as a caption's halves: `(from: '۱', to: '۷ شهریور
/// ۱۴۰۵')`.
///
/// **Returns the parts rather than the sentence**, because the word between
/// them is copy and copy lives in the ARB (§1, D-034). The caller joins them
/// with the localization layer's own «{from} تا {to}».
///
/// **The month and year are stated once when both ends share them.** A week
/// caption reading «۱ شهریور ۱۴۰۵ تا ۷ شهریور ۱۴۰۵» is correct and unreadable
/// on a tile; «۱ تا ۷ شهریور ۱۴۰۵» is the form a Persian reader expects. A week
/// that straddles a month — or a year — gets the fuller form on the end that
/// needs it, so nothing is ever ambiguous.
///
/// **The end is [lastJalaliDayOf], not `range.end`.** The range is half-open,
/// so its end instant is the *following* day's midnight: naming it would put a
/// day outside the figure on the label that says what the figure covers.
({String from, String to}) formatJalaliDayRangeParts(
  InstantRange range, {
  required List<String> monthNames,
  Duration offset = kIranStandardOffset,
}) {
  if (monthNames.length != 12) {
    throw ArgumentError.value(
      monthNames.length,
      'monthNames',
      'expected the twelve Jalali month names in order',
    );
  }
  final Jalali first = jalaliAt(range.start, offset: offset);
  final Jalali last = jalaliAt(
    lastJalaliDayOf(range, offset: offset),
    offset: offset,
  );

  final String to =
      '${toPersianDigits('${last.day}')} ${monthNames[last.month - 1]} '
      '${toPersianDigits('${last.year}')}';

  if (first.year == last.year && first.month == last.month) {
    return (from: toPersianDigits('${first.day}'), to: to);
  }
  if (first.year == last.year) {
    return (
      from: '${toPersianDigits('${first.day}')} ${monthNames[first.month - 1]}',
      to: to,
    );
  }
  return (
    from:
        '${toPersianDigits('${first.day}')} ${monthNames[first.month - 1]} '
        '${toPersianDigits('${first.year}')}',
    to: to,
  );
}

/// An Iranian mobile number, grouped for reading: `۰۹۱۲ ۳۴۵ ۶۷۸۹`.
///
/// Takes the stored canonical `09xxxxxxxxx` produced by
/// `normalizeIranianMobile`. Anything else — a foreign number the repository
/// deliberately kept as typed — is returned isolated but otherwise untouched,
/// because imposing an Iranian grouping on it would misrepresent it.
String formatMobileForDisplay(String stored) {
  final String digits = normalizePersianDigits(stored);
  if (digits.length != 11 || !digits.startsWith('09')) {
    return isolate(toPersianDigits(stored));
  }
  final String grouped =
      '${digits.substring(0, 4)} ${digits.substring(4, 7)} '
      '${digits.substring(7)}';
  return isolate(toPersianDigits(grouped));
}

/// A national or economic ID for display, isolated so it cannot reorder.
///
/// Deliberately **not** grouped. کد ملی is quoted as an unbroken ten-digit
/// string on every official document, and inventing a grouping would make the
/// value on screen not match the one on the card the user is copying from.
String formatIdentifierForDisplay(String value) =>
    isolate(toPersianDigits(value));

/// U+2068 FIRST STRONG ISOLATE and U+2069 POP DIRECTIONAL ISOLATE.
///
/// the project spec: *"Invoice numbers, phone numbers, and national IDs are
/// displayed with proper bidi isolation so they do not visually scramble inside
/// RTL text."*
///
/// The failure this prevents is specific and easy to miss in review. A run like
/// `INV-1405-0001` mixes a Latin prefix (strong LTR), digits, and hyphens
/// (neutral). Dropped bare into a Persian sentence, the bidi algorithm resolves
/// those neutrals against whatever happens to sit on either side — so the same
/// invoice number renders differently depending on the words around it, and a
/// leading or trailing hyphen can jump to the other end. An isolate makes the
/// run resolve against itself and nothing else, so it looks the same wherever
/// it appears.
///
/// First-strong rather than LTR: the run decides its own base direction from
/// its first strong character, which is right for a mixed set where some values
/// are Latin-prefixed and some are pure digits.
String isolate(String value) =>
    '$kFirstStrongIsolate$value$kPopDirectionalIsolate';

/// U+2068 FIRST STRONG ISOLATE.
// l10n-exempt: a bidi format control, not copy. It has no glyph and no
// translation -- it is punctuation for the layout algorithm, and belongs with
// the formatter that applies it, exactly as the thousands separator does.
const String kFirstStrongIsolate = '\u2068';

/// U+2069 POP DIRECTIONAL ISOLATE.
// l10n-exempt: see kFirstStrongIsolate.
const String kPopDirectionalIsolate = '\u2069';

/// A Jalali date for a **file name**: `1405-06-10`.
///
/// Latin digits and hyphens, deliberately, and the one place in the application
/// where a Jalali date is not written in Persian digits. A file name travels
/// outside the app — into a file manager, a cloud drive, an email attachment,
/// a Windows dialog — and Persian digits in a name sort unpredictably, break
/// some pickers, and are awkward to type when the user is looking for the file
/// months later. The *date itself* is still Jalali, which is the part that
/// matters: the user recognises 1405-06-10 as their own calendar.
String formatJalaliDateForFileName(
  DateTime instant, {
  Duration offset = kIranStandardOffset,
}) {
  final Jalali jalali = jalaliAt(instant, offset: offset);
  final String month = jalali.month.toString().padLeft(2, '0');
  final String day = jalali.day.toString().padLeft(2, '0');
  return '${jalali.year}-$month-$day';
}

/// The Tehran wall-clock time for a **file name**: `14-30-05`.
///
/// The same rule [formatJalaliDateForFileName] follows and for the same
/// reasons — Latin digits, and a separator a file system will not object to.
/// Hyphens rather than the colons a clock uses, because a colon is illegal in a
/// Windows filename and is the drive separator besides; a file named with one
/// does not fail loudly, it fails at the save dialog with a message about an
/// invalid name that says nothing about why.
///
/// **Seconds, not minutes**, and that is what makes it useful: it is the
/// component that makes two exports of one invoice different files (D-099). A
/// user re-saving a document after correcting the seller details does it within
/// the same minute, routinely.
String formatJalaliTimeForFileName(
  DateTime instant, {
  Duration offset = kIranStandardOffset,
}) {
  final DateTime local = instant.toUtc().add(offset);
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  final String second = local.second.toString().padLeft(2, '0');
  return '$hour-$minute-$second';
}
