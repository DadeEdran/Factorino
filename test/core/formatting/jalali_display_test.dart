import 'package:factorino/core/formatting/jalali_display.dart';
import 'package:flutter_test/flutter_test.dart';

/// The display side of the date layer. `core/date/` is tested against known
/// Nowruz anchors; this file tests only how a correct value is rendered.
///
/// Every expectation is written against a **fixed instant**, never against the
/// clock, for the same reason `jalali_period_test.dart` is: a test that reads
/// `DateTime.now()` passes today and fails on the day the month rolls over.
void main() {
  /// The twelve month names, as the ARB supplies them at the call site.
  const List<String> monthNames = <String>[
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  /// Nowruz 1405 — 2026-03-21 in Tehran, which is 20:30 UTC the day before.
  final DateTime nowruz1405 = DateTime.utc(2026, 3, 20, 20, 30);

  group('formatJalaliDate', () {
    test('renders zero-padded Persian digits', () {
      expect(_bare(formatJalaliDate(nowruz1405)), '۱۴۰۵/۰۱/۰۱');
    });

    test('pads a single-digit month and day', () {
      // 1405/06/02, the Jalali date for 2026-08-24.
      final DateTime instant = DateTime.utc(2026, 8, 24, 6);
      expect(_bare(formatJalaliDate(instant)), '۱۴۰۵/۰۶/۰۲');
    });

    test('is wrapped in a bidi isolate', () {
      // §9 requires it, and the failure without it is that the same date reads
      // differently depending on the Persian words either side of it.
      final String formatted = formatJalaliDate(nowruz1405);
      expect(formatted.codeUnitAt(0), 0x2068);
      expect(formatted.codeUnitAt(formatted.length - 1), 0x2069);
    });

    test('uses the Iranian day boundary, not the UTC one', () {
      // 21:00 UTC is 00:30 the next day in Tehran. Formatting the UTC date
      // would file this under the previous Jalali day -- the bug D-006 and
      // jalali_instant.dart both exist to prevent, arriving here as a date on
      // screen that disagrees with the one the user remembers.
      final DateTime lateEvening = DateTime.utc(2026, 8, 24, 21);
      expect(_bare(formatJalaliDate(lateEvening)), '۱۴۰۵/۰۶/۰۳');

      final DateTime earlyEvening = DateTime.utc(2026, 8, 24, 19);
      expect(_bare(formatJalaliDate(earlyEvening)), '۱۴۰۵/۰۶/۰۲');
    });

    test('honours an explicit offset rather than the device timezone', () {
      // Nothing in the date layer reads the device (D-028), so a caller in
      // another zone still gets Iranian boundaries unless it asks otherwise.
      expect(
        _bare(
          formatJalaliDate(
            DateTime.utc(2026, 8, 24, 21),
            offset: Duration.zero,
          ),
        ),
        '۱۴۰۵/۰۶/۰۲',
      );
    });
  });

  group('formatJalaliDateLong', () {
    test('names the month', () {
      expect(
        formatJalaliDateLong(
          DateTime.utc(2026, 8, 24, 6),
          monthNames: monthNames,
        ),
        '۲ شهریور ۱۴۰۵',
      );
    });

    test('rejects a month list that is not twelve long', () {
      // The names come from the ARB through a list literal, and a list literal
      // is exactly the thing that loses an entry in an edit. Failing loudly
      // beats rendering the wrong month name.
      expect(
        () => formatJalaliDateLong(
          nowruz1405,
          monthNames: const <String>['فروردین'],
        ),
        throwsArgumentError,
      );
    });
  });

  group('formatJalaliMonthYear', () {
    test('renders the period label a dashboard tile carries', () {
      expect(
        formatJalaliMonthYear(
          DateTime.utc(2026, 8, 24, 6),
          monthNames: monthNames,
        ),
        'شهریور ۱۴۰۵',
      );
    });
  });

  group('formatMobileForDisplay', () {
    test('groups a canonical Iranian mobile', () {
      expect(_bare(formatMobileForDisplay('09123456789')), '۰۹۱۲ ۳۴۵ ۶۷۸۹');
    });

    test('leaves a number that is not an Iranian mobile ungrouped', () {
      // The repository deliberately stores an unrecognised number as typed --
      // a foreign client's number is data the user entered on purpose. Forcing
      // an Iranian grouping onto it would misrepresent it.
      expect(_bare(formatMobileForDisplay('+442071234567')), '+۴۴۲۰۷۱۲۳۴۵۶۷');
    });

    test('accepts a stored value written in Persian digits', () {
      expect(_bare(formatMobileForDisplay('۰۹۱۲۳۴۵۶۷۸۹')), '۰۹۱۲ ۳۴۵ ۶۷۸۹');
    });

    test('isolates the result', () {
      expect(formatMobileForDisplay('09123456789').codeUnitAt(0), 0x2068);
    });
  });

  group('formatIdentifierForDisplay', () {
    test('does not group a national ID', () {
      // کد ملی is quoted as an unbroken ten-digit string on every official
      // document. Inventing a grouping would make the value on screen not match
      // the card the user is copying from.
      expect(_bare(formatIdentifierForDisplay('0079542311')), '۰۰۷۹۵۴۲۳۱۱');
    });
  });

  group('isolate', () {
    test('wraps and does not otherwise alter', () {
      expect(_bare(isolate('INV-1405-0001')), 'INV-1405-0001');
      expect(isolate('x').length, 3);
    });
  });
}

/// The text without its bidi isolate wrapper, so an expectation can be written
/// in the characters a reader would see.
String _bare(String value) => value
    .replaceAll(kFirstStrongIsolate, '')
    .replaceAll(kPopDirectionalIsolate, '');
