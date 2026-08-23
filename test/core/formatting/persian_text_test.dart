import 'package:factorino/core/formatting/persian_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// the project spec and D-025, case by case.
///
/// Several pairs below are visually identical in most fonts, so each one is
/// checked against its code point before it is used. A test written with two
/// literals that an editor, a paste, or a transcoding step had quietly unified
/// would pass while proving nothing at all -- and it would keep passing.
void main() {
  // ARABIC LETTER YEH vs FARSI YEH: the pair §9 names.
  const arabicAli = 'علي';
  const persianAli = 'علی';

  // ARABIC LETTER KAF vs KEHEH: the other pair §9 names.
  const arabicKetab = 'كتاب';
  const persianKetab = 'کتاب';

  /// Joins two words with U+200C ZERO WIDTH NON-JOINER.
  ///
  /// A function rather than an interpolated constant because the character is
  /// invisible: `'x' + zwnj + 'y'` written inline is a literal no reviewer can
  /// tell from `'xy'`, and an editor that dropped it would leave every test
  /// below passing for the wrong reason.
  String withZwnj(String left, String right) => '$left‌$right';

  group('the literals in this file are what they claim to be', () {
    test('withZwnj really inserts U+200C', () {
      // The character is invisible, so the helper is checked rather than
      // trusted. Without this, an editor that dropped the ZWNJ would leave
      // every ZWNJ test below comparing two identical strings and passing.
      final joined = withZwnj('a', 'b');
      expect(joined.length, 3);
      expect(joined.codeUnitAt(1), 0x200C);
    });

    test('the two spellings of the name differ only in the yeh', () {
      expect(arabicAli.length, persianAli.length);
      expect(arabicAli, isNot(persianAli));
      expect(arabicAli.codeUnitAt(2), 0x064A, reason: 'ARABIC LETTER YEH');
      expect(persianAli.codeUnitAt(2), 0x06CC, reason: 'FARSI YEH');
      expect(arabicAli.substring(0, 2), persianAli.substring(0, 2));
    });

    test('the two spellings of the word differ only in the kaf', () {
      expect(arabicKetab, isNot(persianKetab));
      expect(arabicKetab.codeUnitAt(0), 0x0643, reason: 'ARABIC LETTER KAF');
      expect(persianKetab.codeUnitAt(0), 0x06A9, reason: 'KEHEH');
      expect(arabicKetab.substring(1), persianKetab.substring(1));
    });
  });

  group('normalizePersianDigits', () {
    test('folds Persian digits to ASCII', () {
      expect(normalizePersianDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    });

    test('folds Arabic-Indic digits to ASCII', () {
      expect(normalizePersianDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    });

    test('leaves ASCII digits alone', () {
      expect(normalizePersianDigits('0123456789'), '0123456789');
    });

    test('folds all three digit sets mixed in one string', () {
      // The realistic case: two keyboards and a paste, in one field.
      expect(normalizePersianDigits('۱٢3۴٥6'), '123456');
    });

    test('leaves everything that is not a digit exactly as it was', () {
      final input = '$persianAli ۱۲۳ ok';
      expect(normalizePersianDigits(input), '$persianAli 123 ok');
    });

    test('handles an empty string', () {
      expect(normalizePersianDigits(''), '');
    });
  });

  group('toPersianDigits', () {
    test('renders ASCII digits as Persian ones', () {
      expect(toPersianDigits('0123456789'), '۰۱۲۳۴۵۶۷۸۹');
    });

    test('round-trips with normalizePersianDigits', () {
      expect(normalizePersianDigits(toPersianDigits('1405')), '1405');
    });

    test('leaves non-digits alone', () {
      expect(toPersianDigits('INV-1405-0001'), 'INV-۱۴۰۵-۰۰۰۱');
    });
  });

  group('normalizePersianLetters', () {
    test('folds the Arabic yeh and kaf to their Persian forms', () {
      expect(normalizePersianLetters(arabicAli), persianAli);
      expect(normalizePersianLetters(arabicKetab), persianKetab);
    });

    test('leaves spacing and ZWNJ intact', () {
      // Unlike searchKey: this one produces a string that can still be shown.
      final input = '${withZwnj('علی', 'رضا')} محمدی';
      expect(normalizePersianLetters(input), input);
      expect(normalizePersianLetters(input).contains('‌'), isTrue);
    });

    test('leaves digits alone', () {
      expect(normalizePersianLetters('۱۲۳'), '۱۲۳');
    });
  });

  group('searchKey - the §9 requirement', () {
    test('a customer saved as "علي" is found by typing "علی"', () {
      // The example the contract gives, verbatim.
      expect(searchKey(arabicAli), searchKey(persianAli));
    });

    test('the kaf variants match each other', () {
      expect(searchKey(arabicKetab), searchKey(persianKetab));
    });

    test('ZWNJ, a space, and nothing at all are the same word', () {
      final zwnjForm = searchKey(withZwnj('علی', 'رضا'));
      final withSpace = searchKey('علی رضا');
      final joined = searchKey('علیرضا');

      expect(zwnjForm, joined);
      expect(withSpace, joined);
    });

    test('the three digit sets match each other inside a name', () {
      final persian = searchKey('کالای ۱۲۳');
      final arabic = searchKey('کالای ١٢٣');
      final latin = searchKey('کالای 123');

      expect(persian, latin);
      expect(arabic, latin);
    });

    test('Persian, Arabic-Indic and Latin digits mixed in one string', () {
      // The owner's stated case: one field, three digit sets, both letter
      // variants, and a ZWNJ.
      final stored = searchKey(withZwnj('كالاي', 'شماره ۱٢3'));
      final typed = searchKey('کالای شماره 123');

      expect(stored, typed);
    });

    test('drops diacritics, tatweel and invisible bidi marks', () {
      // U+0640 TATWEEL, U+064E FATHA, U+200E LEFT-TO-RIGHT MARK.
      expect(searchKey('کـتاب'), searchKey('کتاب'));
      expect(searchKey('کَتاب'), searchKey('کتاب'));
      expect(searchKey('‎کتاب'), searchKey('کتاب'));
    });

    test('folds alef and heh variants', () {
      expect(searchKey('آرش'), searchKey('ارش'));
      expect(searchKey('فاطمة'), searchKey('فاطمه'));
    });

    test('lowercases Latin text', () {
      expect(searchKey('Sharif Co'), 'sharifco');
    });

    test('removes surrounding and interior whitespace', () {
      expect(searchKey('  شرکت   سهامی  '), searchKey('شرکتسهامی'));
    });

    test('is idempotent', () {
      // It must be: the stored value is normalized once at write time and
      // compared against a term normalized separately at query time.
      final once = searchKey(withZwnj('كالاي', 'شماره ۱٢3'));
      expect(searchKey(once), once);
    });

    test('does not merge words that Persian spells differently on purpose', () {
      // U+0626 YEH WITH HAMZA ABOVE is a distinct Persian letter, not a
      // variant to fold: رئیس and رییس are different spellings.
      expect(searchKey('رئیس'), isNot(searchKey('رییس')));
    });

    test('keeps distinct names distinct', () {
      expect(searchKey('احمد'), isNot(searchKey('محمد')));
      expect(searchKey('رضا'), isNot(searchKey('رضایی')));
    });

    test('handles an empty string', () {
      expect(searchKey(''), '');
      expect(searchKey('   '), '');
    });

    test('a substring of a normalized name still matches it', () {
      // What a LIKE '%term%' query does. Removing spaces must not break
      // matching an individual word from a multi-word name.
      final stored = searchKey('احمد رضایی');
      expect(stored.contains(searchKey('رضایی')), isTrue);
      expect(stored.contains(searchKey('احمد')), isTrue);
    });
  });
}
