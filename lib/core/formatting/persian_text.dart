/// Persian text normalization: the one place in the application where the
/// several ways of writing the same Persian word are folded into one.
///
/// Pure Dart. **Nothing in this directory may import Flutter** -- `dart:ui`,
/// `package:flutter/*` or `package:flutter_test/*`. The money
/// engine's transitive import guard follows project-relative imports, so a
/// Flutter import added here would fail that test the moment anything in
/// `core/money/` reaches for a formatter.
///
/// The fold **tables** below name every character by code point and Unicode
/// name rather than by glyph. Several of the pairs are visually identical in
/// most fonts -- Arabic Yeh and Farsi Yeh differ only in their dots, and only
/// in some positions -- so a table written in glyphs would be one no reviewer
/// could check. Worked examples in prose still use the actual words, because
/// that is the part a reader needs to recognise.
library;

/// U+200C ZERO WIDTH NON-JOINER. Persian uses it inside compound words
/// (`می‌رود`, `کتاب‌ها`), and users type it inconsistently or not at all.
const int kZwnj = 0x200C;

/// ASCII `0`, the target every digit set folds to before parsing.
const int _asciiZero = 0x30;

/// U+06F0 EXTENDED ARABIC-INDIC DIGIT ZERO -- the Persian digit set.
const int _persianZero = 0x06F0;

/// U+0660 ARABIC-INDIC DIGIT ZERO -- the Arabic digit set. Iranian users type
/// both, often from different keyboards on the same device (§9).
const int _arabicIndicZero = 0x0660;

/// Letters that fold to a single Persian spelling.
///
/// Confined to characters that are the *same letter* written differently, not
/// to letters that merely look similar. Hamza-bearing forms that are distinct
/// Persian letters -- U+0626 ARABIC LETTER YEH WITH HAMZA ABOVE, as in
/// `رئیس` -- are deliberately absent: folding those would merge words that
/// Persian spells differently on purpose.
const Map<int, int> _letterFolds = <int, int>{
  // The two the contract names explicitly (§9).
  0x064A: 0x06CC, // ARABIC LETTER YEH            -> FARSI YEH
  0x0643: 0x06A9, // ARABIC LETTER KAF            -> KEHEH
  // Alef Maksura: the same yeh again, from a third keyboard layout.
  0x0649: 0x06CC, // ARABIC LETTER ALEF MAKSURA   -> FARSI YEH
  // Teh Marbuta appears in borrowed names (Fatemeh) that Persian writes with
  // a plain Heh.
  0x0629: 0x0647, // ARABIC LETTER TEH MARBUTA    -> HEH
  0x06C0: 0x0647, // HEH WITH YEH ABOVE           -> HEH
  // Alef with any hamza or madda: typed with and without the mark by the same
  // user for the same name.
  0x0622: 0x0627, // ALEF WITH MADDA ABOVE        -> ALEF
  0x0623: 0x0627, // ALEF WITH HAMZA ABOVE        -> ALEF
  0x0625: 0x0627, // ALEF WITH HAMZA BELOW        -> ALEF
  0x0671: 0x0627, // ALEF WASLA                   -> ALEF
};

/// Characters that carry no meaning for matching and are dropped outright.
///
/// Diacritics are optional in written Persian and are almost never typed, so a
/// name stored with them would be unfindable. The bidi and joining controls
/// are invisible: a user cannot see that their query contains one, which makes
/// a mismatch caused by it impossible for them to diagnose.
bool _isDroppedForMatching(int rune) {
  return (rune >= 0x064B && rune <= 0x065F) || // ARABIC diacritics (harakat)
      rune == 0x0670 || // SUPERSCRIPT ALEF
      rune == 0x0640 || // TATWEEL (kashida) -- decorative elongation
      rune == 0x061C || // ARABIC LETTER MARK
      (rune >= 0x200B && rune <= 0x200F) || // ZWSP, ZWNJ, ZWJ, LRM, RLM
      (rune >= 0x202A && rune <= 0x202E) || // bidi embedding/override
      (rune >= 0x2066 && rune <= 0x2069) || // bidi isolates
      rune == 0xFEFF; // BOM / zero-width no-break space
}

/// Folds Persian (`۰-۹`) and Arabic-Indic (`٠-٩`) digits to ASCII `0-9`.
///
/// **Every numeric input passes through this before parsing** (§9). Users type
/// the three digit sets interchangeably, frequently mixed inside one field.
/// Everything else in the string is left exactly as it was.
String normalizePersianDigits(String input) {
  if (input.isEmpty) return input;

  final out = StringBuffer();
  for (final rune in input.runes) {
    out.writeCharCode(_asciiDigitOf(rune) ?? rune);
  }
  return out.toString();
}

/// Renders ASCII digits as Persian digits, for display only (§9).
///
/// The inverse of [normalizePersianDigits]. Digit rendering lives here rather
/// than in the font: the Farsi-digit variants of Vazirmatn were deliberately
/// not bundled, so that this decision stays in code where it is reviewable and
/// testable (D-022).
String toPersianDigits(String input) {
  if (input.isEmpty) return input;

  final out = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= _asciiZero && rune <= _asciiZero + 9) {
      out.writeCharCode(_persianZero + (rune - _asciiZero));
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

/// Drops everything that is not a digit, in any of the three sets.
///
/// The **character-class** half of the project spec's field-level limits, for the
/// fields where one is meaningful: کد ملی and کد اقتصادی are digits and nothing
/// else, so a field that accepts letters into them accepts a value the checksum
/// will then call invalid without saying why.
///
/// Digits are kept **as typed** rather than folded to ASCII. A form field
/// filters what the user is allowed to enter; it does not get to rewrite what
/// they see while they are still typing it — a cursor that jumps because the
/// text under it changed length is a worse failure than the one being
/// prevented. Folding happens at parse time, in [normalizePersianDigits],
/// exactly as it does for every other numeric input.
///
/// Lives here rather than beside the widget that uses it because this is the
/// only directory permitted to name a digit code point
/// (`single_normalizer_path_test.dart`) — and because the alternative, a second
/// definition of "what counts as a digit", is precisely the drift D-029 exists
/// to prevent.
String keepDigitsOnly(String input) {
  if (input.isEmpty) return input;

  final out = StringBuffer();
  for (final rune in input.runes) {
    if (_asciiDigitOf(rune) != null) out.writeCharCode(rune);
  }
  return out.toString();
}

/// Folds Arabic letter forms to their Persian spelling, leaving spacing,
/// ZWNJ and digits untouched.
///
/// Use this when a *displayable* string still needs a canonical spelling.
/// For matching, use [searchKey], which folds considerably harder.
String normalizePersianLetters(String input) {
  if (input.isEmpty) return input;

  final out = StringBuffer();
  for (final rune in input.runes) {
    out.writeCharCode(_letterFolds[rune] ?? rune);
  }
  return out.toString();
}

/// **The** normalizer for search: the single function that produces the value
/// stored in a `search_name` column and the single function that produces the
/// term queried against it (D-025).
///
/// Both sides must call this. Two call sites that normalize "almost the same
/// way" produce an index that silently stops matching -- no error, no crash,
/// just a customer the user cannot find. `single_normalizer_path_test.dart`
/// fails the build if anything in `lib/` reaches for `searchName` without
/// going through here, or open-codes a fold of its own.
///
/// The result is an opaque **key, not a display string**: it is stripped of
/// spacing and case and must never be shown to the user or treated as their
/// text. It is deliberately more aggressive than [normalizePersianLetters]:
///
/// * digits fold to ASCII, so a name stored with Persian digits is found by
///   typing Latin ones and vice versa;
/// * Arabic letter forms fold to Persian, so `علي` is found by typing `علی`
///   (§9's stated requirement);
/// * diacritics, tatweel and invisible bidi controls are dropped;
/// * **ZWNJ and all whitespace are removed entirely**, so `علی‌رضا`, `علی رضا`
///   and `علیرضا` all reduce to the same key. Persian compounds are written
///   all three ways by the same person, and a substring search over a
///   space-free key still matches each individual word;
/// * Latin text is lowercased.
String searchKey(String input) {
  if (input.isEmpty) return input;

  final out = StringBuffer();
  for (final rune in input.runes) {
    if (_isDroppedForMatching(rune)) continue;

    final digit = _asciiDigitOf(rune);
    if (digit != null) {
      out.writeCharCode(digit);
      continue;
    }

    final folded = _letterFolds[rune] ?? rune;
    if (_isWhitespace(folded)) continue;

    out.writeCharCode(folded);
  }

  // Lowercasing last: it is a whole-string operation in Dart, and applying it
  // to the folded result keeps it away from the Arabic ranges entirely.
  return out.toString().toLowerCase();
}

/// The separator between fields inside a composite search key.
///
/// A customer is searchable by name *and* company, so `search_name` holds both.
/// They need a boundary, or `احمد` + `دلتا` would concatenate into a key
/// containing `دد` and match a term that appears in neither field. This
/// character works because [searchKey] can never produce it: a search term is
/// folded by the same function, so a term containing it is impossible, and a
/// `LIKE` match therefore cannot span the boundary.
const String kSearchFieldSeparator = '|';

/// The composite key for a record with more than one searchable field.
///
/// Here rather than in the repositories so that both call sites cannot compose
/// it differently -- the same reason [searchKey] itself is one function. Null
/// and blank fields are dropped, so adding a company name later changes the key
/// only by appending.
String searchKeyOf(Iterable<String?> fields) {
  final keys = <String>[];
  for (final field in fields) {
    if (field == null) continue;
    final key = searchKey(field);
    if (key.isEmpty) continue;
    keys.add(key);
  }
  return keys.join(kSearchFieldSeparator);
}

/// The ASCII digit a rune represents, across all three digit sets, or `null`.
int? _asciiDigitOf(int rune) {
  if (rune >= _persianZero && rune <= _persianZero + 9) {
    return _asciiZero + (rune - _persianZero);
  }
  if (rune >= _arabicIndicZero && rune <= _arabicIndicZero + 9) {
    return _asciiZero + (rune - _arabicIndicZero);
  }
  if (rune >= _asciiZero && rune <= _asciiZero + 9) {
    return rune;
  }
  return null;
}

/// Whitespace, including the Unicode separators a paste can carry in.
bool _isWhitespace(int rune) {
  return rune == 0x20 || // SPACE
      (rune >= 0x09 && rune <= 0x0D) || // tab, LF, VT, FF, CR
      rune == 0x85 || // NEL
      rune == 0xA0 || // NO-BREAK SPACE
      (rune >= 0x2000 && rune <= 0x200A) || // EN QUAD .. HAIR SPACE
      rune == 0x2028 || // LINE SEPARATOR
      rune == 0x2029 || // PARAGRAPH SEPARATOR
      rune == 0x202F || // NARROW NO-BREAK SPACE
      rune == 0x205F || // MEDIUM MATHEMATICAL SPACE
      rune == 0x3000; // IDEOGRAPHIC SPACE
}
