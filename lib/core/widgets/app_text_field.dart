import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../formatting/jalali_display.dart';
import '../formatting/persian_text.dart';
import '../localization/generated/app_strings.dart';
import '../theme/app_typography.dart';

/// Every text field in the application.
///
/// **`maxLength` is required, and that is the whole point.** the project spec
/// asks for field-level limits on customer and product free-text fields; the
/// schema has carried them since increment (a) and the forms carried none, so
/// an over-long value was accepted by the form and rejected by drift with an
/// `InvalidDataException` that `describeFailure` reports as the generic
/// «خطایی رخ داد» — the user told that something went wrong, and not which
/// field or why (D-042).
///
/// A required parameter is what makes the fix structural rather than a habit: a
/// new field cannot be added without a limit, because it will not compile.
/// `field_limit_path_test.dart` closes the other half by failing the build if a
/// form reaches for a raw `TextFormField`, or passes a bare number where a
/// shared constant belongs — the limit must be a `*Limits.` reference, so the
/// form and the column cannot name different values.
///
/// Three things it holds so no form has to:
///
/// * **A length validator, in drift's own unit.** `maxLength` stops the *user*
///   at the limit, counting grapheme clusters; drift's
///   `GeneratedColumn.checkTextLength` counts `String.length`, UTF-16 code
///   units. For Persian those agree except where combining marks are involved,
///   and a name carrying diacritics could therefore pass the field and still be
///   refused by the column. The validator closes that gap in exactly the unit
///   the column measures, and says which field and what the limit is.
/// * **A character class where one is meaningful** ([digitsOnly]). کد ملی and
///   کد اقتصادی are digits; a field that accepts letters into them accepts a
///   value the checksum then calls invalid without explaining itself.
/// * **A counter, but only near the limit.** A permanent «۰/۲۰۰۰» under every
///   field is decoration, and §10 removes what does not aid comprehension. A
///   field that silently stops accepting input is worse, though — so the
///   counter appears once the limit is close enough to be the reason.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    required this.maxLength,
    this.helperText,
    this.hintText,
    this.suffixText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.maxLines = 1,
    this.digitsOnly = false,
    this.obscureText = false,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;

  /// The Persian label, from the localization layer.
  final String label;

  /// The column's limit, as a `*Limits.` constant — never a bare number. See
  /// `lib/data/models/field_limits.dart` for why the schema cannot reference
  /// the same constant and what stands in for that.
  final int maxLength;

  final String? helperText;
  final String? hintText;
  final String? suffixText;

  /// The field's own rule — required, a checksum, a mobile format. Run after
  /// the length check, which is the constraint that would otherwise reach the
  /// database.
  final FormFieldValidator<String>? validator;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final int maxLines;

  /// Restricts input to digits, in whichever of the three sets the user types
  /// (§9). Digits are kept as typed and folded at parse time, never rewritten
  /// under the cursor.
  final bool digitsOnly;

  /// Hides what is typed — the backup password, and nothing else so far.
  ///
  /// Kept on the shared field rather than met with a raw `TextFormField`,
  /// because `field_limit_path_test.dart` forbids the raw form and it is right
  /// to: a password field that skipped this class would also skip the length
  /// validator and the Persian counter, and would be the precedent for the
  /// next field that skipped them.
  final bool obscureText;

  /// Fires on every keystroke.
  ///
  /// For a field whose value feeds a **live preview** — the invoice discount
  /// beside a running total — where waiting for submit would leave the figures
  /// describing an invoice that is no longer the one on screen. A field that
  /// only writes on save should leave this null and read the controller.
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChange);

  /// Whether focusing this field should select what is already in it.
  ///
  /// **Numeric fields only, and derived from the keyboard rather than from a
  /// flag at nine call sites.** A number is replaced far more often than it is
  /// edited in place: changing a quantity from ۱ to ۳ is one keystroke of
  /// intent, and without this it is clear-then-type. Prose is the opposite —
  /// tapping into a note or an address is nearly always to put the caret
  /// somewhere, and selecting it all would arm a keystroke to destroy it.
  ///
  /// **Not `digitsOnly`**, which was the obvious marker and is the wrong one:
  /// the quantity field — the field the behaviour was actually reported
  /// against — deliberately sets it false so it can accept the Persian decimal
  /// separator, and so does a discount field in percent mode.
  bool get _selectsAllOnFocus {
    final TextInputType? type = widget.keyboardType;
    if (type == null) return false;
    // `numberWithOptions(...)` shares its index with `TextInputType.number`,
    // so this covers the decimal and signed variants too.
    return type.index == TextInputType.number.index ||
        type.index == TextInputType.phone.index;
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus || !_selectsAllOnFocus) return;
    final String text = widget.controller.text;
    if (text.isEmpty) return;

    // **After the frame**, because the framework sets its own selection while
    // it is installing focus — assigning here directly is overwritten on a real
    // device and survives only in a widget test, which is the worst of both.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus) return;
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _focusNode
..removeListener(_onFocusChange)
..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      obscureText: widget.obscureText,
      inputFormatters: widget.digitsOnly
          ? const <TextInputFormatter>[_DigitsOnlyFormatter()]
: null,
      onChanged: widget.onChanged,
      buildCounter: _buildCounter,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        hintText: widget.hintText,
        suffixText: widget.suffixText,
      ),
      validator: (String? value) {
        final String text = value ?? '';
        // Measured the way `GeneratedColumn.checkTextLength` measures, so this
        // fires exactly when the column would have refused the value -- never
        // earlier, and never a character later.
        if (text.length > widget.maxLength) {
          return strings.validationTooLong(
            toPersianDigits('${widget.maxLength}'),
          );
        }
        return widget.validator?.call(value);
      },
    );
  }

  /// Nothing until the limit is in sight, and nothing at all on a field whose
  /// limit *is* its format.
  ///
  /// A ten-digit کد ملی stops at ten because that is what a کد ملی is; a
  /// counter there would be counting something the user is not worried about.
  /// A two-thousand-character note is different: reaching that limit is a
  /// surprise, and a field that just stops accepting keystrokes with no
  /// explanation is the failure this whole widget exists to avoid, one level
  /// down.
  Widget? _buildCounter(
    BuildContext context, {
    required int currentLength,
    required int? maxLength,
    required bool isFocused,
  }) {
    final int? limit = maxLength;
    if (limit == null || limit < _counterMinimumLimit) return null;
    if (currentLength <= limit - _counterLeadCharacters) return null;

    final ThemeData theme = Theme.of(context);
    return Text(
      // Isolated: a `current/max` run is digits around a neutral slash, and
      // dropped bare into RTL text the pair can resolve the wrong way round
      // -- so a field at 1990 of 2000 would read as 2000 of 1990 (§9).
      isolate(toPersianDigits('$currentLength/$limit')),
      style: AppTypography.caption.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontFamily: AppTypography.fontFamily,
      ),
    );
  }
}

/// Shortest limit that gets a counter at all. Below this the limit is the
/// field's format rather than a ceiling the user might bump into.
const int _counterMinimumLimit = 40;

/// How close to the limit the counter appears.
const int _counterLeadCharacters = 20;

/// Keeps only digits, in any of the three sets (§9).
///
/// The filtering itself is [keepDigitsOnly] in `core/formatting/`, which is the
/// only directory allowed to know what a digit is (D-029). This class is the
/// Flutter adapter and nothing else.
class _DigitsOnlyFormatter extends TextInputFormatter {
  const _DigitsOnlyFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = newValue.text;
    final String filtered = keepDigitsOnly(text);
    if (filtered == text) return newValue;

    // The caret has to move by however many characters were dropped in front
    // of it, or typing a letter in the middle of a number jumps the cursor to
    // somewhere the user did not put it.
    final int caret = newValue.selection.end.clamp(0, text.length);
    final int caretInFiltered = keepDigitsOnly(text.substring(0, caret)).length;

    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: caretInFiltered),
    );
  }
}
