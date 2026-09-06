import 'package:flutter/material.dart';

import '../../../../core/formatting/number_display.dart';
import '../../../../core/formatting/persian_text.dart';
import '../../../../core/formatting/number_input.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/editor_sheet.dart';
import '../../../../data/models/app_settings.dart';
import '../../../../data/models/field_limits.dart';
import '../../application/settings_editor.dart';

/// Edits the three invoicing settings.
///
/// Returns the edited [AppSettings], or null if dismissed. It **builds the
/// value only** — the write is the controller's business.
///
/// **This is a defect fix, not a feature** (D-068). The project spec requires the
/// VAT rate to be configurable and never hardcoded; until this sheet it was
/// hardcoded at whatever the database was seeded with, and a business on a
/// different rate met that on its first invoice with no way round it. The work
/// belonged to no phase, which is exactly how the scope cut would have made it
/// permanent.
///
/// **Every bound is enforced here and reported, never clamped.** `AppSettings`
/// deliberately does not clamp (D-052) — a value that cannot be right is a
/// data-entry error to surface, not a number to quietly adjust, which is D-027's
/// principle applied to an input. The payment term is the one that matters:
/// a negative term produces an invoice due before it was issued, and it looks
/// entirely deliberate on the document.
Future<AppSettings?> showSettingsEditorSheet(
  BuildContext context, {
  required AppSettings settings,
}) {
  return showModalBottomSheet<AppSettings>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _SettingsEditorSheet(settings: settings),
  );
}

class _SettingsEditorSheet extends StatefulWidget {
  const _SettingsEditorSheet({required this.settings});

  final AppSettings settings;

  @override
  State<_SettingsEditorSheet> createState() => _SettingsEditorSheetState();
}

class _SettingsEditorSheetState extends State<_SettingsEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _taxRate;
  late final TextEditingController _prefix;
  late final TextEditingController _paymentTerm;

  @override
  void initState() {
    super.initState();
    // Shown in the unit the user thinks in -- percent -- while the model holds
    // basis points. The conversion happens here and at submit, and nowhere in
    // between, so there is one place to be wrong rather than several.
    _taxRate = TextEditingController(
      text: _percentFieldText(widget.settings.defaultTaxRateBp),
    );
    _prefix = TextEditingController(text: widget.settings.invoiceNumberPrefix);
    _paymentTerm = TextEditingController(
      text: toPersianDigits('${widget.settings.paymentTermDays}'),
    );
  }

  @override
  void dispose() {
    _taxRate.dispose();
    _prefix.dispose();
    _paymentTerm.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    final int? taxRateBp = _readTaxRateBp();
    final int? term = tryParseIntInput(_paymentTerm.text);
    if (taxRateBp == null || term == null) return;

    Navigator.of(context).pop(
      widget.settings.copyWith(
        defaultTaxRateBp: taxRateBp,
        invoiceNumberPrefix: _prefix.text.trim(),
        paymentTermDays: term,
      ),
    );
  }

  /// Percent as typed, in whichever digit set, to basis points.
  ///
  /// `scale: 100` is exactly the percent-to-basis-point conversion, so the
  /// arithmetic goes through the shared normalizing parser rather than through
  /// a `double` multiplication here -- there is no floating point anywhere on
  /// the money path, and a tax rate is on it (§4).
  int? _readTaxRateBp() => tryParseScaledInput(_taxRate.text, scale: 100);

  /// The stored rate as editable text: the display form without its ٪, since
  /// the sign is the field's business and not the value's.
  static String _percentFieldText(int basisPoints) =>
      formatPercentFromBasisPoints(basisPoints)
          .replaceAll(kPersianPercentSign, '');

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return EditorSheet(
      title: strings.settingsEditTitle,
      closeTooltip: strings.actionCancel,
      formKey: _formKey,
      action: FilledButton(onPressed: _submit, child: Text(strings.actionSave)),
      children: <Widget>[
        AppTextField(
          controller: _taxRate,
          label: strings.settingsFieldTaxRate,
          helperText: strings.settingsFieldTaxRateHint,
          maxLength: SettingsFieldLimits.taxRateDigits,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          validator: (String? value) {
            final int? bp = _readTaxRateBp();
            if (bp == null || bp < 0 || bp > SettingsLimits.maxTaxRateBp) {
              return strings.settingsErrorTaxRateRange;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: _prefix,
          label: strings.settingsFieldPrefix,
          helperText: strings.settingsFieldPrefixHint,
          maxLength: SettingsFieldLimits.prefix,
          validator: (String? value) {
            if ((value ?? '').trim().length < SettingsLimits.minPrefixLength) {
              return strings.settingsErrorPrefixEmpty;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: _paymentTerm,
          label: strings.settingsFieldPaymentTerm,
          helperText: strings.settingsFieldPaymentTermHint,
          maxLength: SettingsFieldLimits.paymentTermDigits,
          suffixText: strings.unitDays,
          digitsOnly: true,
          keyboardType: TextInputType.number,
          validator: (String? value) {
            final int? days = tryParseIntInput(value ?? '');
            if (days == null ||
                days < SettingsLimits.minPaymentTermDays ||
                days > SettingsLimits.maxPaymentTermDays) {
              return strings.settingsErrorPaymentTermRange;
            }
            return null;
          },
        ),
      ],
    );
  }
}
