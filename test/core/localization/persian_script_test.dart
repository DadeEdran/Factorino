import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **No Arabic-only character may appear in a string the user reads** (D-112).
///
/// Persian and Arabic share a script and not an alphabet. Four characters look
/// almost identical in most fonts and are wrong in Persian, and a fifth class —
/// the Arabic-Indic digits — is wrong in a way that is invisible until the
/// digits sit next to Persian ones and two shapes of the same numeral appear on
/// one screen.
///
/// | wrong | right | how it gets in |
/// |---|---|---|
/// | `ك` U+0643 | `ک` U+06A9 | an Arabic keyboard layout, or text pasted from an Arabic source |
/// | `ي` U+064A | `ی` U+06CC | the same, and the commonest of the five |
/// | `ى` U+0649 | `ی` U+06CC | Arabic alef maksura, which renders dotless |
/// | `ة` U+0629 | `ه` U+0647 | Arabic teh marbuta, in borrowed names |
/// | `إ` U+0625 | `ا` U+0627 | hamza below, which Persian does not write |
/// | `ء` U+0621 | — | a standalone hamza; see below |
/// | `ٔ` U+0654 | — | the ezafe mark on ه; see below |
/// | `ۀ` U+06C0 | `ه` | the same mark, precomposed |
/// | `ـ` U+0640 | — | tatweel, a typesetting stretch with no meaning |
/// | `٠`–`٩` U+0660–9 | `۰`–`۹` U+06F0–9 | any Arabic locale's number formatter |
///
/// ## Why the ezafe mark is banned, and the marked letters are not
///
/// `آ` `أ` `ؤ` `ئ` and the fathatan of «لطفاً» are **correct Persian** — «مؤثر»,
/// «متأسفانه» and «لطفاً» are spelt with them — and they stay.
///
/// **U+0654 after ه is also correct Persian, and it is banned anyway, because
/// Vazirmatn cannot draw it acceptably.** This was reported twice from a phone
/// and diagnosed wrongly the first time, so the measurement is recorded here:
///
/// * The font is not missing the glyph and the shaper is not failing. U+0654 is
///   in Vazirmatn's `cmap`, `GDEF` classes it as a mark, and its `GPOS`
///   mark-to-base lookup covers ه and all three of its joined forms with real
///   anchors. The mark lands exactly where the font asks for it.
/// * Where the font asks for it is the problem. Mark anchor (260, 972) against
///   the isolated ه's (424, 1164) puts the hamza's ink bottom at y=1117 while
///   the ه's ink top is 912 — a gap of **205 units on a 2048 em, 0.10 em**,
///   with the mark's centre 0.038 em to the left of the letter's. All three
///   weights agree to within 0.004 em.
/// * At 14–16 sp on a phone that gap is one to two device pixels of clear
///   space, and the mark rasterises as a **free-floating stroke above and to
///   the left of the letter** rather than as part of it. Rendered through the
///   real Vazirmatn at 14 sp and magnified, it reads as a stray mark, which is
///   exactly what was reported.
/// * There is no way to fix it from this side. Vazirmatn composes hamza with
///   fatha and damma only — there is no ه+ء ligature — and U+06C0, the
///   precomposed form, decomposes to the same two glyphs and renders
///   identically. A font-level anchor is not something an application can
///   override.
///
/// **So the ezafe is written with a plain «ه».** «مشاهده همه», «تهیه پشتیبان».
/// That is normal Persian orthography — the mark is optional in modern usage
/// and widely omitted — and a correct letter beats a correct mark in the wrong
/// place. The earlier diagnosis, that the mark appeared alone because `ه` plus
/// U+0654 is one grapheme and a narrow container breaks inside it, was a real
/// effect and a real fix (`text_fit.dart`'s `expectNoCrushedText` still guards
/// it) but it was not this. These strings render wrong with room to spare.
///
/// A Persian word that genuinely ends in a standalone hamza — «جزء», «سوء»,
/// «امضاء» — would belong in [_hamzaAllowed] with the key named. It is empty,
/// and a future entry should be a decision somebody made rather than a ban
/// somebody removed.
///
/// ## What is scanned, and what is deliberately not
///
/// **Translation values in the ARB**, which is every user-facing string in the
/// application: §1 puts them all there and `no_hardcoded_strings_test.dart`
/// forbids a Persian literal anywhere else in `lib/`, so the two guards together
/// cover the screens and the PDF path alike — a document string that is not in
/// the ARB cannot exist. The **generated** Dart is scanned too, so a hand-edit
/// of `app_strings_fa.dart` that never went through the ARB is caught.
///
/// **`@`-prefixed metadata is exempt, exactly as comments are exempt in the
/// sibling scanner.** A description is English documentation that never renders,
/// and one of them quotes «علي» on purpose to explain what the search normalizer
/// folds — a rule that cannot be stated without writing the character it is
/// about.
///
/// `test/` and `integration_test/` are exempt for the same reason at a larger
/// scale: their fixtures feed Arabic input *deliberately*, to prove
/// `searchKey` folds it. A guard that failed on those would be a guard against
/// testing the thing.
void main() {
  const String arbPath = 'lib/core/localization/arb/app_fa.arb';
  const String generatedPath =
      'lib/core/localization/generated/app_strings_fa.dart';

  /// ARB keys allowed a standalone U+0621, with the Persian word that needs it.
  ///
  /// Empty. See the class doc: «جزء» and «سوء» are the words that would earn an
  /// entry, and neither is in the application's copy.
  const Map<String, String> hamzaAllowed = <String, String>{};

  test('no Arabic-only character in any user-facing string', () {
    final Map<String, dynamic> arb =
        jsonDecode(File(arbPath).readAsStringSync()) as Map<String, dynamic>;

    final List<String> offenders = <String>[];

    arb.forEach((String key, dynamic value) {
      // Metadata and the locale marker: documentation, never rendered.
      if (key.startsWith('@')) return;
      if (value is! String) return;

      for (final _ArabicOnly found in _scan(value)) {
        if (found.rune == 0x0621 && hamzaAllowed.containsKey(key)) continue;
        offenders.add('$arbPath "$key": ${found.describe()}');
      }
    });

    expect(
      offenders,
      isEmpty,
      reason:
          'Persian and Arabic share a script, not an alphabet, and these '
          'characters are the Arabic member of a look-alike pair. Replace each '
          'with the Persian one named beside it — at the source, in the ARB, '
          'not by normalizing on the way out (D-112):\n'
          '${offenders.join('\n')}',
    );
  });

  test('nor in the generated strings, which is where a hand-edit would land', () {
    // The ARB is the source; this file is what the widgets actually read. They
    // agree only for as long as nobody edits the second one, and `flutter
    // gen-l10n` is a step somebody can skip.
    final List<String> lines = File(generatedPath).readAsLinesSync();
    final List<String> offenders = <String>[];

    for (int i = 0; i < lines.length; i++) {
      final String code = _stripComments(lines[i]);
      for (final _ArabicOnly found in _scan(code)) {
        offenders.add('$generatedPath:${i + 1}: ${found.describe()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'fix the ARB and re-run `flutter gen-l10n`; if this fails and the ARB '
          'is clean, the generated file has been edited by hand:\n'
          '${offenders.join('\n')}',
    );
  });

  test('the correct Persian characters are not caught by the ban', () {
    // **Guards the guard, in the direction that would do real damage.** A ban
    // list that swept up `أ` or `ؤ` would demand that «متأسفانه» and «مؤثر» be
    // misspelt to make a test pass, and the ARB holds both today.
    for (final String correct in <String>[
      // The ezafe written the way this application now writes it: a plain ه.
      'متأسفانه انجام این کار ممکن نشد',
      'نرخ مؤثر',
      'لطفاً دوباره تلاش کنید',
      'ذخیره نسخه PDF',
      'آماده',
      'مسئول',
      'شماره فاکتور',
      '۱۴۰۵/۰۶/۰۲',
      '۲٬۱۱۷٬۵۰۰ تومان',
      '۸٫۵٪',
    ]) {
      expect(
        _scan(correct),
        isEmpty,
        reason: '«$correct» is correct Persian and must not be flagged',
      );
    }
  });

  test('the ban would catch a real slip', () {
    // Each pair is the same word twice: Arabic spelling, then Persian.
    const Map<String, String> slips = <String, String>{
      'كتاب': 'کتاب',
      'مشتري': 'مشتری',
      'فاطمة': 'فاطمه',
      'إسم': 'اسم',
      'شماره ١٢٣': 'شماره ۱۲۳',
      'فاكتورــ': 'فاکتور',
      'جزء': 'جزء',
      // Both ways of writing the ezafe mark, so neither can come back: the
      // combining form and the precomposed letter render identically wrong.
      'مشاهدهٔ همه': 'مشاهده همه',
      'مشاهدۀ همه': 'مشاهده همه',
    };

    slips.forEach((String arabic, String persian) {
      expect(_scan(arabic), isNotEmpty, reason: '«$arabic» must be caught');
      if (arabic != persian) {
        expect(
          _scan(persian),
          isEmpty,
          reason: '«$persian» is the correction and must pass',
        );
      }
    });
  });
}

/// One Arabic-only rune found in a string, and what belongs there instead.
class _ArabicOnly {
  const _ArabicOnly(this.rune, this.instead);

  final int rune;

  /// The Persian character that belongs there, or null where nothing does.
  final String? instead;

  String describe() {
    final String hex = rune.toRadixString(16).toUpperCase().padLeft(4, '0');
    final String replacement = instead == null
        ? 'has no place in Persian and should be deleted'
        : 'should be «$instead»';
    return '«${String.fromCharCode(rune)}» U+$hex $replacement';
  }

  @override
  String toString() => describe();
}

/// The Arabic-only runes, mapped to the Persian character that belongs instead.
///
/// **Deliberately not a range.** The Arabic block holds Persian's whole
/// alphabet, its digits, its comma, its question mark and its percent, decimal
/// and thousands signs; banning the block would ban the language. Only the
/// look-alikes are listed, one at a time, each with its replacement, so a
/// failure tells the reader what to type rather than that something is wrong.
const Map<int, String?> _arabicOnly = <int, String?>{
  0x0621: null, // ARABIC LETTER HAMZA, standing alone
  0x0654: null, // COMBINING HAMZA ABOVE — the ezafe mark; see the class doc
  0x06C0: 'ه', // HEH WITH YEH ABOVE — the precomposed ezafe, same problem
  0x0625: 'ا', // ALEF WITH HAMZA BELOW
  0x0629: 'ه', // TEH MARBUTA
  0x0640: null, // TATWEEL — a stretch, not a letter
  0x0643: 'ک', // ARABIC KAF
  0x0649: 'ی', // ALEF MAKSURA
  0x064A: 'ی', // ARABIC YEH
  0x0660: '۰',
  0x0661: '۱',
  0x0662: '۲',
  0x0663: '۳',
  0x0664: '۴',
  0x0665: '۵',
  0x0666: '۶',
  0x0667: '۷',
  0x0668: '۸',
  0x0669: '۹',
};

List<_ArabicOnly> _scan(String text) {
  final List<_ArabicOnly> found = <_ArabicOnly>[];
  for (final int rune in text.runes) {
    if (!_arabicOnly.containsKey(rune)) continue;
    found.add(_ArabicOnly(rune, _arabicOnly[rune]));
  }
  return found;
}

/// [line] with any comment removed, leaving only what the compiler sees.
///
/// The same shape as `no_hardcoded_strings_test.dart`'s, and for the same
/// reason: a doc comment describing what the normalizer folds has to be able to
/// name the character it folds.
String _stripComments(String line) {
  final String trimmed = line.trimLeft();
  if (trimmed.startsWith('///') ||
      trimmed.startsWith('//') ||
      trimmed.startsWith('*') ||
      trimmed.startsWith('/*')) {
    return '';
  }
  final int commentStart = line.indexOf('//');
  return commentStart == -1 ? line : line.substring(0, commentStart);
}
