import 'persian_text.dart';

/// Iranian mobile number normalization and validation.
///
/// One canonical stored form -- `09xxxxxxxxx` -- reached from every way a user
/// might write the same number. Storing what was typed instead would mean the
/// same customer entered twice from two devices looks like two customers, and
/// no lookup by number could be relied on.

/// The stored form: `09` followed by nine digits.
///
/// Iranian mobile prefixes are all `09xx` (`091x`/`093x` MCI, `090x`/`0902x`
/// Irancell, `092x` RighTel and so on). The operator ranges are not enumerated
/// here on purpose: they change as ranges are allocated, and an app that
/// rejects a freshly issued number is worse than one that accepts a typo.
final RegExp _canonicalMobile = RegExp(r'^09\d{9}$');

/// Normalizes an Iranian mobile number to `09xxxxxxxxx`, or returns `null` if
/// it is not a valid one.
///
/// Accepts, with any mix of Persian, Arabic-Indic and Latin digits, and with
/// spaces, hyphens, dots or parentheses anywhere:
///
/// * `09123456789`   -- the canonical local form
/// * `9123456789`    -- the leading zero dropped, as when copied from a form
/// * `+989123456789` -- international, the form most contact apps export
/// * `00989123456789`-- international with the ITU prefix instead of `+`
/// * `989123456789`  -- the country code with neither prefix
///
/// Returns `null` for anything else. An invalid number is an ordinary form
/// state with a Persian message, not an exception (this field is optional).
String? normalizeIranianMobile(String input) {
  final digits = _digitsOnly(input);
  if (digits.isEmpty) return null;

  final national = _stripCountryCode(digits);
  if (national == null) return null;

  // A number given without its leading zero is unambiguous: every Iranian
  // mobile has one, and a national number never legitimately starts with 9
  // otherwise.
  final canonical = national.startsWith('9') ? '0$national' : national;

  return _canonicalMobile.hasMatch(canonical) ? canonical : null;
}

/// Whether [input] is a usable Iranian mobile number.
bool isValidIranianMobile(String input) =>
    normalizeIranianMobile(input) != null;

/// Removes the country code in whichever of its three forms is present.
///
/// Returns `null` where the input claims to be international but the remainder
/// is not a plausible national number -- a foreign number, most likely, which
/// must be rejected rather than silently reinterpreted as Iranian.
String? _stripCountryCode(String digits) {
  // `0098...` -- the ITU international prefix.
  if (digits.startsWith('0098')) {
    return digits.substring(4);
  }
  // `98...` -- covers `+98` too, since `+` is not a digit and is already gone.
  //
  // Guarded by length: `9821...` (a Tehran landline written internationally)
  // and a genuine mobile `98...` are told apart by what follows, and a local
  // number can never be twelve digits long.
  if (digits.startsWith('98') && digits.length == 12) {
    return digits.substring(2);
  }
  return digits;
}

/// Every digit in [input], folded to ASCII, with everything else discarded.
///
/// Discarding rather than rejecting is deliberate: `+98 912 345 6789` and
/// `0912-345-6789` are the same number written by two people, and refusing one
/// of them teaches the user to fight the field.
String _digitsOnly(String input) {
  final normalized = normalizePersianDigits(input);
  final out = StringBuffer();
  for (final rune in normalized.runes) {
    if (rune >= 0x30 && rune <= 0x39) {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}
