import 'package:factorino/core/formatting/iranian_phone.dart';
import 'package:flutter_test/flutter_test.dart';

/// the project spec: Iranian mobile formatting and validation, with graceful
/// handling of `+98` and `0098` prefixes.
void main() {
  const canonical = '09123456789';

  group('the accepted prefixes all reach one stored form', () {
    test('the local form passes through unchanged', () {
      expect(normalizeIranianMobile('09123456789'), canonical);
    });

    test('a dropped leading zero is restored', () {
      expect(normalizeIranianMobile('9123456789'), canonical);
    });

    test('the +98 form', () {
      expect(normalizeIranianMobile('+989123456789'), canonical);
    });

    test('the 0098 form', () {
      expect(normalizeIranianMobile('00989123456789'), canonical);
    });

    test('the bare country code', () {
      expect(normalizeIranianMobile('989123456789'), canonical);
    });
  });

  group('formatting a user actually types', () {
    test('spaces, hyphens, dots and parentheses are ignored', () {
      expect(normalizeIranianMobile('0912 345 6789'), canonical);
      expect(normalizeIranianMobile('0912-345-6789'), canonical);
      expect(normalizeIranianMobile('(0912) 345.6789'), canonical);
      expect(normalizeIranianMobile('+98 912 345 6789'), canonical);
    });

    test('Persian digits are folded', () {
      expect(normalizeIranianMobile('۰۹۱۲۳۴۵۶۷۸۹'), canonical);
    });

    test('Arabic-Indic digits are folded', () {
      expect(normalizeIranianMobile('٠٩١٢٣٤٥٦٧٨٩'), canonical);
    });

    test('the three digit sets mixed in one number', () {
      expect(normalizeIranianMobile('۰۹۱٢٣٤5678۹'), canonical);
    });

    test('surrounding whitespace', () {
      expect(normalizeIranianMobile('  09123456789  '), canonical);
    });
  });

  group('rejection', () {
    test('too short and too long', () {
      expect(normalizeIranianMobile('0912345678'), isNull);
      expect(normalizeIranianMobile('091234567890'), isNull);
    });

    test('a landline is not a mobile', () {
      // Tehran landline: valid Iranian number, wrong field.
      expect(normalizeIranianMobile('02188776655'), isNull);
      expect(normalizeIranianMobile('+982188776655'), isNull);
    });

    test('a number that does not start 09 after normalization', () {
      expect(normalizeIranianMobile('08123456789'), isNull);
    });

    test('a foreign number is rejected, not reinterpreted', () {
      // +1 202 555 0143. Stripping a country code that is not 98 and calling
      // the remainder Iranian is the failure worth guarding against.
      expect(normalizeIranianMobile('+12025550143'), isNull);
      expect(normalizeIranianMobile('+442071234567'), isNull);
    });

    test('empty and non-numeric input', () {
      expect(normalizeIranianMobile(''), isNull);
      expect(normalizeIranianMobile('   '), isNull);
      expect(normalizeIranianMobile('تلفن ندارد'), isNull);
    });
  });

  group('all four operator prefix families are accepted', () {
    // The ranges are not enumerated in the implementation on purpose: an app
    // that rejects a freshly allocated number is worse than one that accepts
    // a typo. These confirm nothing narrower slipped in.
    for (final number in <String>[
      '09011112222', // 090x
      '09121112222', // 091x
      '09301112222', // 093x
      '09211112222', // 092x
      '09901112222', // 099x
    ]) {
      test('accepts $number', () {
        expect(normalizeIranianMobile(number), number);
      });
    }
  });

  test('isValidIranianMobile agrees with normalizeIranianMobile', () {
    expect(isValidIranianMobile('+98 912 345 6789'), isTrue);
    expect(isValidIranianMobile('02188776655'), isFalse);
  });

  test('normalization is idempotent', () {
    final once = normalizeIranianMobile('+98 912 345 6789')!;
    expect(normalizeIranianMobile(once), once);
  });
}
