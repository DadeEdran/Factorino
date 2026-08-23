import 'persian_text.dart';

/// Parsing numbers the way users actually type them.
///
/// the project spec: *"Every numeric input passes through a normalizer before
/// parsing."* This is the boundary that does it. Nothing above this layer may
/// call `int.parse` on a string that came from a text field -- a Persian `۵`
/// reaches `int.parse` as a `FormatException`, and a thousands separator the
/// user typed themselves reaches it the same way.
///
/// Everything here returns `null` for input it cannot parse rather than
/// throwing. Invalid input in a form field is an ordinary state the UI shows a
/// Persian message for, not an exceptional one.

/// Grouping characters a user may type or paste inside a number, all
/// discarded. Named by code point for the same reason the fold tables in
/// `persian_text.dart` are: several of them are invisible in source, and a
/// literal containing a thin space is a literal no reviewer can check.
const Set<int> _groupingCharacters = <int>{
  0x2C, // COMMA
  0x20, // SPACE
  0xA0, // NO-BREAK SPACE           -- common in pasted spreadsheet values
  0x2009, // THIN SPACE
  0x202F, // NARROW NO-BREAK SPACE
  0x5F, // LOW LINE (underscore)
  0x066C, // ARABIC THOUSANDS SEPARATOR -- the Persian keyboard's grouping mark
  0x060C, // ARABIC COMMA
};

/// Decimal separators, all normalized to `.` before parsing.
const Set<int> _decimalSeparators = <int>{
  0x2E, // FULL STOP
  0x066B, // ARABIC DECIMAL SEPARATOR -- the Persian keyboard's decimal point
};

/// Folds digits to ASCII and strips grouping characters, leaving a string that
/// [int.tryParse] can accept.
///
/// Also normalizes a leading `+`/`-` and the Unicode minus U+2212, which is
/// what a paste from a spreadsheet often carries.
String normalizeNumericInput(String input) {
  final digits = normalizePersianDigits(input).trim();

  final out = StringBuffer();
  for (final rune in digits.runes) {
    if (_groupingCharacters.contains(rune)) continue;
    if (rune == 0x2212) {
      out.write('-'); // MINUS SIGN -> HYPHEN-MINUS
      continue;
    }
    if (_decimalSeparators.contains(rune)) {
      out.write('.');
      continue;
    }
    out.writeCharCode(rune);
  }
  return out.toString();
}

/// Parses a whole number from user input, or `null` if it is not one.
///
/// A value with a fractional part is rejected rather than truncated: silently
/// dropping the fraction of a price is exactly the class of quiet arithmetic
/// error §4 exists to prevent. Use [tryParseScaledInput] where fractions are
/// meaningful.
int? tryParseIntInput(String input) {
  final normalized = normalizeNumericInput(input);
  if (normalized.isEmpty) return null;
  return int.tryParse(normalized);
}

/// Parses a possibly-fractional number and returns it as an integer scaled by
/// [scale], or `null` if it cannot be parsed exactly.
///
/// This is how a quantity reaches the database: `quantity_milli` is the entered
/// quantity times 1000, so `1.5` kg is `1500` (D-002). The parse is done on the
/// digits themselves rather than through `double` -- routing a quantity through
/// binary floating point to get an integer back would reintroduce, at the input
/// boundary, precisely the representation error the money path is built to
/// avoid.
///
/// More fractional digits than [scale] can represent is an error, not a
/// rounding opportunity: `1.2345` at `scale: 1000` returns `null` so the UI can
/// say so, rather than quietly billing for `1.234`.
int? tryParseScaledInput(String input, {required int scale}) {
  if (!_isPowerOfTen(scale)) {
    throw ArgumentError.value(
      scale,
      'scale',
      'must be a positive power of ten',
    );
  }

  final normalized = normalizeNumericInput(input);
  if (normalized.isEmpty) return null;

  var body = normalized;
  var negative = false;
  if (body.startsWith('-')) {
    negative = true;
    body = body.substring(1);
  } else if (body.startsWith('+')) {
    body = body.substring(1);
  }
  if (body.isEmpty) return null;

  final parts = body.split('.');
  if (parts.length > 2) return null;

  final wholePart = parts[0].isEmpty ? '0' : parts[0];
  final fractionPart = parts.length == 2 ? parts[1] : '';

  if (!_isAllAsciiDigits(wholePart)) return null;
  if (fractionPart.isNotEmpty && !_isAllAsciiDigits(fractionPart)) return null;

  // How many fractional digits `scale` can carry: 1000 -> 3.
  var scaleDigits = 0;
  for (var s = scale; s > 1; s ~/= 10) {
    scaleDigits++;
  }
  if (fractionPart.length > scaleDigits) return null;

  final padded = fractionPart.padRight(scaleDigits, '0');
  final whole = int.tryParse(wholePart);
  final fraction = padded.isEmpty ? 0 : int.tryParse(padded);
  if (whole == null || fraction == null) return null;

  final value = whole * scale + fraction;
  return negative ? -value : value;
}

/// Whether [value] is 1, 10, 100, ... The scale has to be a power of ten for
/// "digits after the point" to mean anything.
bool _isPowerOfTen(int value) {
  if (value < 1) return false;
  var remaining = value;
  while (remaining % 10 == 0) {
    remaining ~/= 10;
  }
  return remaining == 1;
}

bool _isAllAsciiDigits(String value) {
  if (value.isEmpty) return false;
  for (final rune in value.runes) {
    if (rune < 0x30 || rune > 0x39) return false;
  }
  return true;
}
