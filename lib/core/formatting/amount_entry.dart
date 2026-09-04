/// Grouping an amount **while it is being typed** (§9).
///
/// `number_display.dart` groups a stored integer for display and
/// `number_input.dart` folds what the user typed back into something
/// parseable. This file is the third case those two leave open: the text in a
/// field that is halfway through being edited, which has to be readable *and*
/// still parseable by the same parser, with the caret left where the user put
/// it.
///
/// Iranian amounts are long — a modest invoice line is seven digits — and an
/// ungrouped run of them cannot be checked at a glance. The field therefore
/// shows the same shape the rest of the application shows: Persian digits
/// grouped in threes with [kPersianGroupSeparator].
///
/// **No second parser comes out of this.** The grouped text is fed to the
/// existing [normalizeNumericInput], which already discards U+066C and folds
/// Persian digits — so what the field holds is what the parser has always
/// accepted, and there is still exactly one path from a keystroke to an
/// integer.
library;

import 'number_display.dart';
import 'persian_text.dart';

/// The text an amount field should hold, and where the caret belongs in it.
class AmountEntryText {
  const AmountEntryText({required this.text, required this.caret});

  final String text;

  /// A UTF-16 offset into [text], never past its end.
  final int caret;
}

/// Regroups [input] as an amount, keeping the caret on the same digit.
///
/// [caret] is the offset the caret sat at in [input]; the returned caret is the
/// offset in the returned text that has the **same number of digits before
/// it**. That is the whole trick: separators move as digits are added, so
/// anchoring on the character offset would drift by one every three digits and
/// send the caret to the wrong side of a separator.
///
/// [maxDigits] bounds the digits accepted, since a grouped field cannot use the
/// character limit its column carries — the separators are characters the
/// column will never see.
AmountEntryText groupAmountEntry(
  String input, {
  required int caret,
  required int maxDigits,
}) {
  final int safeCaret = caret < 0 || caret > input.length
      ? input.length
      : caret;

  String digits = normalizePersianDigits(keepDigitsOnly(input));
  int digitsBefore = normalizePersianDigits(
    keepDigitsOnly(input.substring(0, safeCaret)),
  ).length;

  // Leading zeros go, or a pasted `0300` reads as ۰٬۳۰۰ — a figure that is not
  // wrong so much as unreadable. The last digit is never stripped, so a field
  // holding a deliberate `۰` keeps it.
  int leading = 0;
  while (leading < digits.length - 1 && digits.codeUnitAt(leading) == 0x30) {
    leading++;
  }
  digits = digits.substring(leading);
  digitsBefore = (digitsBefore - leading).clamp(0, digits.length);

  if (digits.length > maxDigits) {
    digits = digits.substring(0, maxDigits);
    digitsBefore = digitsBefore.clamp(0, digits.length);
  }

  final StringBuffer out = StringBuffer();
  int caretOut = 0;
  int seen = 0;
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      out.write(kPersianGroupSeparator);
    }
    out.write(digits[i]);
    seen++;
    if (seen == digitsBefore) caretOut = out.length;
  }

  // `toPersianDigits` substitutes one code unit for one code unit and leaves
  // the separator alone, so the offset computed above survives it.
  return AmountEntryText(
    text: toPersianDigits(out.toString()),
    caret: caretOut,
  );
}
