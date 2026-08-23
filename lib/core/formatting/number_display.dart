/// Rendering numbers for display.
///
/// The counterpart of `number_input.dart`: that file folds what the user types
/// into something parseable, this one turns a stored integer into something
/// readable. Both live here rather than in a widget, because §3 puts formatting
/// decisions outside the presentation layer — and because a separator chosen in
/// one screen and a different one chosen in another is exactly the sort of
/// inconsistency nobody notices until a customer does.
library;

import 'persian_text.dart';

/// U+066C ARABIC THOUSANDS SEPARATOR — the mark Persian actually groups
/// numbers with.
///
/// Not the ASCII comma, and not U+060C ARABIC COMMA either: that one is
/// punctuation for prose. Named here so the choice is reviewable, and because
/// the glyph is easy to mistake for the other two on sight.
///
// l10n-exempt: numeric punctuation, not copy. A separator is a property of how
// Persian writes numbers, not a phrase anyone would translate, and putting it
// in the ARB would invite it to be "corrected" to a comma by someone editing
// text. It belongs with the formatter that uses it.
const String kPersianGroupSeparator = '٬';

/// Groups digits in threes and renders them in Persian digits.
///
/// Grouping happens on the ASCII digits and the conversion runs afterwards,
/// because [toPersianDigits] leaves everything that is not a digit alone — so
/// the separator survives untouched and there is exactly one place that decides
/// what it is.
///
/// Negative values keep a leading ASCII hyphen; bidi isolation for placing that
/// correctly inside RTL text is the widget's job, not the formatter's.
String formatGroupedPersian(int value) {
  return toPersianDigits(formatGroupedAscii(value));
}

/// The same grouping, left in ASCII digits.
///
/// Useful where the digits must stay machine-readable — a copy-to-clipboard
/// action, or a value on its way into a file.
String formatGroupedAscii(int value) {
  final String digits = value.abs().toString();
  final StringBuffer out = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      out.write(kPersianGroupSeparator);
    }
    out.write(digits[i]);
  }

  return value < 0 ? '-$out' : out.toString();
}

/// A basis-point rate as a Persian percentage: `1000` becomes `۱۰٪`.
///
/// Trailing zeros in the fractional part are dropped, so 9% reads `۹٪` rather
/// than `۹٫۰۰٪`, while 8.5% still reads `۸٫۵٪`.
String formatPercentFromBasisPoints(int basisPoints) {
  final int whole = basisPoints ~/ 100;
  final int fraction = basisPoints % 100;

  final String text;
  if (fraction == 0) {
    text = '$whole';
  } else if (fraction % 10 == 0) {
    text = '$whole$kPersianDecimalSeparator${fraction ~/ 10}';
  } else {
    text =
        '$whole$kPersianDecimalSeparator'
        '${fraction.toString().padLeft(2, '0')}';
  }

  return '${toPersianDigits(text)}$kPersianPercentSign';
}

/// U+066B ARABIC DECIMAL SEPARATOR.
// l10n-exempt: numeric punctuation, not copy -- see kPersianGroupSeparator.
const String kPersianDecimalSeparator = '٫';

/// U+066A ARABIC PERCENT SIGN — mirrored correctly in RTL, unlike ASCII `%`.
// l10n-exempt: numeric punctuation, not copy -- see kPersianGroupSeparator.
const String kPersianPercentSign = '٪';

/// A quantity stored in milli-units, for display: `1500` becomes `۱٫۵`.
///
/// Trailing zeros are dropped, so a whole quantity reads `۲` rather than
/// `۲٫۰۰۰` — the scale is a storage detail and should not reach the user.
String formatQuantityMilli(int quantityMilli) {
  final int whole = quantityMilli ~/ 1000;
  final int fraction = quantityMilli.remainder(1000).abs();

  if (fraction == 0) return toPersianDigits('$whole');

  final String trimmed = fraction
.toString()
.padLeft(3, '0')
.replaceFirst(RegExp(r'0+$'), '');

  return toPersianDigits('$whole$kPersianDecimalSeparator$trimmed');
}
