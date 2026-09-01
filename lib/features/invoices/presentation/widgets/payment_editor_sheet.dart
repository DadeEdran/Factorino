import 'package:flutter/material.dart';

import '../../../../core/date/jalali_period.dart';
import '../../../../core/formatting/number_display.dart';
import '../../../../core/formatting/number_input.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/jalali_date_picker.dart';
import '../../../../data/models/field_limits.dart';
import '../../../../data/models/payment.dart';
import '../../../../data/models/payment_method.dart';
import '../../domain/payment_method_label.dart';

/// Records one payment against an invoice.
///
/// Returns the [PaymentDraft] the user built, or null if dismissed. Like the
/// invoice line sheet, it **only builds the value** — writing it is the
/// caller's business, through the payments controller, so the sheet has no
/// repository, no error state and nothing to undo.
///
/// **It calculates nothing.** [amountDue] arrives already computed, from
/// `InvoiceDetail.amountDue`, and is used for two things: to say what is still
/// owed under the amount field, and to fill that field on request. Working the
/// balance out here would be a second answer to a question the aggregate has
/// already answered, and the two would eventually disagree in favour of
/// whichever one the user happened to be looking at.
///
/// **An overpayment is warned about, never refused.** The repository accepts
/// one — an invoice cannot owe a negative amount, so it clamps and reports —
/// and paying over the balance genuinely happens. It is also usually a
/// data-entry error, so the sheet says so **before** the write rather than
/// leaving it to be discovered on the invoice afterwards (D-027's principle,
/// applied to an input rather than to a calculation).
Future<PaymentDraft?> showPaymentEditorSheet(
  BuildContext context, {
  required Money amountDue,
  required DateTime today,
}) {
  return showModalBottomSheet<PaymentDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) =>
        _PaymentEditorSheet(amountDue: amountDue, today: today),
  );
}

class _PaymentEditorSheet extends StatefulWidget {
  const _PaymentEditorSheet({required this.amountDue, required this.today});

  /// What is still owed, from `InvoiceDetail.amountDue`. Read, never derived.
  final Money amountDue;

  /// The clock, read once by the screen and passed down (D-041), so the date
  /// this sheet defaults to is the same instant the page was built against.
  final DateTime today;

  @override
  State<_PaymentEditorSheet> createState() => _PaymentEditorSheetState();
}

class _PaymentEditorSheetState extends State<_PaymentEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _amount;
  late final TextEditingController _note;

  late DateTime _paidAt;

  /// Cash first, because it is the commonest and a default that is usually
  /// right costs one tap less than a default that is never right.
  PaymentMethod _method = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController();
    _note = TextEditingController();
    // Today, in the same Jalali day the rest of the page is reckoning in
    // (D-006, D-028): a payment is nearly always being recorded on the day it
    // happened, and the picker is one tap away when it was not.
    _paidAt = jalaliDayOf(widget.today).start;
    _amount.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amount
      ..removeListener(_onAmountChanged)
      ..dispose();
    _note.dispose();
    super.dispose();
  }

  /// Only to re-render the overpayment warning. The figure itself is never
  /// computed here — this compares what was typed against a balance that
  /// arrived already worked out.
  void _onAmountChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final int? typedToman = tryParseIntInput(_amount.text.trim());
    final bool overpaying =
        typedToman != null && Money.toman(typedToman) > widget.amountDue;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        strings.paymentCreateTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: strings.actionCancel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _amount,
                  label: strings.paymentFieldAmount,
                  maxLength: AmountLimits.tomanDigits,
                  suffixText: strings.unitToman,
                  autofocus: true,
                  digitsOnly: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  // The balance, named rather than implied, so the commonest
                  // payment -- settling the rest -- needs no arithmetic from
                  // the user.
                  helperText: strings.paymentAmountRemainingHelper(
                    formatGroupedPersian(widget.amountDue.toman),
                  ),
                  validator: (String? value) => _validateAmount(value, strings),
                ),
                if (widget.amountDue.rial > 0) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () =>
                          _amount.text = '${widget.amountDue.toman}',
                      child: Text(strings.paymentAmountFillRemaining),
                    ),
                  ),
                ],
                if (overpaying) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    strings.paymentAmountExceedsDue,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                JalaliDateField(
                  label: strings.paymentFieldDate,
                  value: _paidAt,
                  onPick: _pickDate,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  strings.paymentFieldMethod,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                // A `Wrap` of choices rather than a `SegmentedButton`: five
                // methods do not fit across a phone in one row, and the
                // Persian labels are not the same length. Wrapping costs a
                // line of height and cannot clip.
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final PaymentMethod method in PaymentMethod.values)
                      ChoiceChip(
                        label: Text(paymentMethodLabel(method, strings)),
                        selected: _method == method,
                        onSelected: (bool selected) {
                          if (selected) setState(() => _method = method);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _note,
                  label: strings.paymentFieldNote,
                  maxLength: PaymentLimits.note,
                  hintText: strings.paymentFieldNoteHint,
                  helperText: strings.fieldOptional,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.xl),
                // «ذخیره», as the invoice line sheet's submit says, rather
                // than repeating the sheet's own title: a button and the
                // heading above it saying the same three words reads as two
                // controls to a reader scanning for one.
                FilledButton(
                  onPressed: _submit,
                  child: Text(strings.actionSave),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showJalaliDatePicker(
      context,
      initial: _paidAt,
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Safe after validation: the validator refuses exactly what the parser
    // returns null for, and refuses zero besides.
    final Money amount = Money.toman(tryParseIntInput(_amount.text.trim())!);
    final String note = _note.text.trim();

    Navigator.of(context).pop(
      PaymentDraft(
        amount: amount,
        // Already a UTC instant at local midnight in Tehran (D-005, D-028);
        // the picker returns one and the default was built from one.
        paidAt: _paidAt,
        method: _method,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  /// Zero and negative are refused **here as well as** in the repository.
  ///
  /// Not a duplicated rule: the repository's `PaymentNotAccepted` is the
  /// authority and stays, because a deep link or a future sync path never comes
  /// through this sheet. This is the same rule stated at the field, so the user
  /// is told where the problem is instead of meeting a save that failed for
  /// reasons the screen then has to explain.
  String? _validateAmount(String? value, AppStrings strings) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return strings.validationRequired;

    final int? toman = tryParseIntInput(text);
    if (toman == null) return strings.validationAmountInvalid;
    if (toman <= 0) return strings.validationAmountPositive;
    // The ceiling rejects rather than truncates (D-002), said while the field
    // is still in front of the user rather than as an error on save.
    if (toman > kMaxAmountRial ~/ 10) return strings.validationAmountTooLarge;
    return null;
  }
}
