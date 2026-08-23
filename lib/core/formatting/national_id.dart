import 'persian_text.dart';

/// Iranian national ID (کد ملی) normalization and checksum validation
///.
///
/// **The field is optional.** An empty value is valid and means "not given";
/// only a value that was actually entered is checked. That distinction is the
/// whole contract here: a validator that rejects blanks would make every
/// customer record require an identifier the user may not have, and one that
/// accepts anything non-empty would store transposed digits that surface as a
/// rejected tax filing months later.

/// A national ID is exactly ten digits.
const int kNationalIdLength = 10;

/// Strips formatting and folds digits to ASCII, or returns `null` if what is
/// left is not ten digits.
///
/// Accepts the hyphenated and spaced forms people write on paper
/// (`0079-5432-11`), and any mix of Persian, Arabic-Indic and Latin digits.
/// Leading zeros are significant and preserved -- which is why this is stored
/// as text, not as an integer.
String? normalizeNationalId(String input) {
  final normalized = normalizePersianDigits(input);
  final out = StringBuffer();
  for (final rune in normalized.runes) {
    if (rune >= 0x30 && rune <= 0x39) {
      out.writeCharCode(rune);
    } else if (rune != 0x2D && rune != 0x20 && rune != 0x5F) {
      // Anything that is neither a digit nor an accepted separator means this
      // is not a national ID at all -- a letter, say -- rather than a
      // formatted one.
      return null;
    }
  }

  final digits = out.toString();
  return digits.length == kNationalIdLength ? digits : null;
}

/// Whether [input] is a structurally valid national ID.
///
/// Validates the official checksum: the first nine digits are weighted 10 down
/// to 2, summed, and reduced modulo 11. A remainder below 2 must equal the
/// check digit; otherwise the check digit must be `11 − remainder`.
///
/// Ten repetitions of one digit (`0000000000`, `1111111111`, ...) are rejected
/// even though several of them satisfy the checksum arithmetic. They are not
/// issued, and they are exactly what gets typed when someone wants to get past
/// a required field.
///
/// **What this does not catch.** The rule maps two remainders onto the same
/// check digit -- `r = 1` and `r = 10` both yield `1` -- so an error that moves
/// the weighted sum between them passes. `0079542311` and `0079542131` are both
/// accepted, and both would be by any correct implementation of the official
/// algorithm. A checksum narrows the space of typos; it does not close it, and
/// the UI must not present a passing value as a verified identity.
bool isValidNationalId(String input) {
  final digits = normalizeNationalId(input);
  if (digits == null) return false;

  if (_isAllSameDigit(digits)) return false;

  var sum = 0;
  for (var i = 0; i < 9; i++) {
    sum += _digitAt(digits, i) * (kNationalIdLength - i);
  }

  final remainder = sum % 11;
  final check = _digitAt(digits, 9);

  return remainder < 2 ? check == remainder : check == 11 - remainder;
}

/// The optional-field rule, in one place: blank is fine, present must be valid.
///
/// Returns `true` for `null`, an empty string, or whitespace. The caller stores
/// [normalizeNationalId]'s output, which is `null` for a blank.
bool isValidOptionalNationalId(String? input) {
  if (input == null || input.trim().isEmpty) return true;
  return isValidNationalId(input);
}

int _digitAt(String digits, int index) =>
    digits.codeUnitAt(index) - 0x30; // '0'

bool _isAllSameDigit(String digits) {
  final first = digits.codeUnitAt(0);
  for (var i = 1; i < digits.length; i++) {
    if (digits.codeUnitAt(i) != first) return false;
  }
  return true;
}
