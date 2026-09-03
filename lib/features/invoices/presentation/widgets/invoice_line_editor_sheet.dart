import 'package:flutter/material.dart';

import '../../../../core/formatting/number_display.dart';
import '../../../../core/formatting/number_input.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/editor_sheet.dart';
import '../../../../data/models/field_limits.dart';
import '../../../../data/models/product.dart';
import '../../domain/invoice_editor_state.dart';

/// How the user expressed a discount. Both are kept (§4 step 2): the percentage
/// as entered and the amount it resolves to.
enum _DiscountMode { amount, percent }

/// Whether the line carries its own tax rate or takes the invoice's.
///
/// This is the whole reason D-026 exists as a decision. It is a **three**-state
/// field flattened into a mode and a value: inherit, an explicit rate, and an
/// explicit rate that happens to be zero. The last two are different documents.
/// If "inherit" and "zero" shared one control state, a line the user marked
/// tax-exempt would silently take the default VAT rate — a wrong total on a tax
/// document that looks right to everyone except the tax authority.
enum _TaxMode { inherit, custom }

/// Creates or edits one invoice line.
///
/// Returns the [InvoiceLineEntry] the user built, or null if dismissed. It
/// **only builds the value** — adding, replacing or discarding it is the
/// caller's business, through `InvoiceEditor`'s intents.
///
/// [product] pre-fills the form from a catalogue entry, copying title, unit and
/// price in as snapshots (D-004) and keeping the id for traceability only. From
/// that moment the line is independent: editing the price here changes this
/// invoice and not the catalogue, and editing the catalogue tomorrow changes
/// neither.
///
/// **Nothing here calculates.** The figures the user sees while editing come
/// from `InvoiceEditorState.totals` on the screen behind; this sheet produces
/// typed input and hands it over. `single_calculation_path_test.dart` fails the
/// build if that ever stops being true.
///
/// ## Adding a line and editing one are different jobs (D-090)
///
/// **On an existing line, the quantity is the only editable field.** Title,
/// unit, unit price, discount and tax rate are shown as the line states them
/// and cannot be typed into.
///
/// The reason is not that editing them is hard, it is that it is the wrong
/// place. A price on an invoice line is a **snapshot of the catalogue** at the
/// moment the line was added (D-004), and the whole value of a snapshot is
/// that one can say where it came from. A price changed here comes from
/// nowhere: it matches no product record, no other invoice, and nothing the
/// user can look up six months later when a customer queries it. Changing what
/// something costs belongs in the product record, which is the one place a
/// price is a fact rather than a keystroke — and a genuinely one-off amount is
/// what «سطر آزاد» is for, on a new line.
///
/// So the sheet keeps both jobs and narrows one of them. Adding a line — with
/// [product] or freehand — is unchanged and collects everything. Reopening a
/// line collects the quantity, which is the field that legitimately changes
/// after the fact: three of something instead of two is the same agreement at
/// a different size, and it is what a user actually reopens a line to do.
///
/// A line that is wrong in any other way is removed and added again, which is
/// two taps and leaves nothing behind that claims to be a snapshot of
/// something it is not.
Future<InvoiceLineEntry?> showInvoiceLineEditorSheet(
  BuildContext context, {
  InvoiceLineEntry? existing,
  Product? product,
  int? resolvedTaxRateBp,
}) {
  return showModalBottomSheet<InvoiceLineEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _InvoiceLineEditorSheet(
      existing: existing,
      product: product,
      resolvedTaxRateBp: resolvedTaxRateBp,
    ),
  );
}

class _InvoiceLineEditorSheet extends StatefulWidget {
  const _InvoiceLineEditorSheet({
    this.existing,
    this.product,
    this.resolvedTaxRateBp,
  });

  final InvoiceLineEntry? existing;
  final Product? product;

  /// What the engine resolved for this line, so "inherit" can say which rate it
  /// inherits rather than being an unknown quantity. Read from
  /// `CalculatedLine.resolvedTaxRateBp` by the caller — this sheet does not
  /// resolve it, because resolution is §4 step 6 and belongs to the engine.
  final int? resolvedTaxRateBp;

  @override
  State<_InvoiceLineEditorSheet> createState() =>
      _InvoiceLineEditorSheetState();
}

class _InvoiceLineEditorSheetState extends State<_InvoiceLineEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _unit;
  late final TextEditingController _unitPrice;
  late final TextEditingController _quantity;
  late final TextEditingController _discount;
  late final TextEditingController _taxRate;

  late _DiscountMode _discountMode;
  late _TaxMode _taxMode;

  /// Carried across from the source, never re-derived. Null for a freehand
  /// line. Traceability only — it is never a pricing reference (D-004).
  String? _productId;

  @override
  void initState() {
    super.initState();

    final InvoiceLineEntry? existing = widget.existing;
    final Product? product = widget.product;

    // The snapshot copy (D-004), performed once, here. A product picked into a
    // line contributes three values and an id, and from this moment on the
    // catalogue row is not consulted again.
    _title = TextEditingController(
      text: existing?.title ?? product?.name ?? '',
    );
    _unit = TextEditingController(text: existing?.unit ?? product?.unit ?? '');
    _unitPrice = TextEditingController(
      text: _tomanText(existing?.unitPrice ?? product?.price),
    );
    _quantity = TextEditingController(
      // A new line starts at one, which is what it almost always is. Zero is a
      // legitimate value the engine handles, but it is not a sensible default:
      // a line the user has not touched should read as one unit, not as a line
      // worth nothing.
      text: _quantityText(existing?.quantityMilli ?? 1000),
    );
    _productId = existing?.productId ?? product?.id;

    final int? percent = existing?.discountPercentBp;
    _discountMode = percent == null
        ? _DiscountMode.amount
        : _DiscountMode.percent;
    _discount = TextEditingController(
      text: percent != null
          ? _percentText(percent)
          : _tomanText(
              existing == null || existing.discount == Money.zero
                  ? null
                  : existing.discount,
            ),
    );

    final int? lineTax = existing?.taxRateBp;
    _taxMode = lineTax == null ? _TaxMode.inherit : _TaxMode.custom;
    _taxRate = TextEditingController(
      text: lineTax == null ? '' : _percentText(lineTax),
    );
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _title,
      _unit,
      _unitPrice,
      _quantity,
      _discount,
      _taxRate,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return EditorSheet(
      title: widget.existing == null
          ? strings.invoiceLineCreateTitle
          : strings.invoiceLineEditTitle,
      closeTooltip: strings.actionCancel,
      formKey: _formKey,
      // This sheet already pinned its action, independently, before there was
      // a primitive for it. Going through [EditorSheet] changes nothing it did
      // -- it stops the shape being a habit that the next sheet can miss, which
      // is exactly what the payment sheet did in (c) (known issue 21, D-062).
      action: FilledButton(onPressed: _submit, child: Text(strings.actionSave)),
      children: widget.existing == null
          ? _composeFields(context, strings)
          : _quantityOnlyFields(context, strings),
    );
  }

  /// A new line: everything is collected, exactly as it always was.
  List<Widget> _composeFields(BuildContext context, AppStrings strings) {
    final ThemeData theme = Theme.of(context);

    return <Widget>[
      AppTextField(
        controller: _title,
        label: strings.invoiceLineFieldTitle,
        maxLength: InvoiceLimits.lineTitle,
        autofocus: widget.product == null,
        textInputAction: TextInputAction.next,
        validator: _requiredField(strings),
      ),
      const SizedBox(height: AppSpacing.lg),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: _quantityField(strings)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppTextField(
              controller: _unit,
              label: strings.productFieldUnit,
              maxLength: InvoiceLimits.lineUnit,
              hintText: strings.productFieldUnitHint,
              textInputAction: TextInputAction.next,
              validator: _requiredField(strings),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        controller: _unitPrice,
        label: strings.invoiceLineFieldUnitPrice,
        maxLength: AmountLimits.tomanDigits,
        suffixText: strings.unitToman,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        textInputAction: TextInputAction.next,
        digitsOnly: true,
        validator: (String? value) =>
            _validateAmount(value, strings, required: true),
      ),
      const SizedBox(height: AppSpacing.xl),
      _SectionLabel(strings.invoiceLineDiscountSection),
      const SizedBox(height: AppSpacing.sm),
      SegmentedButton<_DiscountMode>(
        segments: <ButtonSegment<_DiscountMode>>[
          ButtonSegment<_DiscountMode>(
            value: _DiscountMode.amount,
            label: Text(strings.invoiceLineDiscountModeAmount),
          ),
          ButtonSegment<_DiscountMode>(
            value: _DiscountMode.percent,
            label: Text(strings.invoiceLineDiscountModePercent),
          ),
        ],
        selected: <_DiscountMode>{_discountMode},
        onSelectionChanged: (Set<_DiscountMode> selection) => setState(() {
          _discountMode = selection.first;
          // The two are alternatives, not two views of one
          // number: `10` means ten Toman in one mode and ten
          // percent in the other. Carrying the text across
          // would silently change what the user entered.
          _discount.clear();
        }),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        controller: _discount,
        label: _discountMode == _DiscountMode.amount
            ? strings.invoiceLineDiscountModeAmount
            : strings.invoiceLineDiscountModePercent,
        maxLength: AmountLimits.tomanDigits,
        suffixText: _discountMode == _DiscountMode.amount
            ? strings.unitToman
            : kPersianPercentSign,
        helperText: strings.fieldOptional,
        keyboardType: TextInputType.numberWithOptions(
          decimal: _discountMode == _DiscountMode.percent,
        ),
        digitsOnly: _discountMode == _DiscountMode.amount,
        validator: (String? value) => _discountMode == _DiscountMode.amount
            ? _validateAmount(value, strings, required: false)
            : _validatePercent(value, strings, required: false),
      ),
      const SizedBox(height: AppSpacing.xl),
      _SectionLabel(strings.invoiceLineTaxSection),
      const SizedBox(height: AppSpacing.sm),
      SegmentedButton<_TaxMode>(
        segments: <ButtonSegment<_TaxMode>>[
          ButtonSegment<_TaxMode>(
            value: _TaxMode.inherit,
            label: Text(strings.invoiceLineTaxInherit),
          ),
          ButtonSegment<_TaxMode>(
            value: _TaxMode.custom,
            label: Text(strings.invoiceLineTaxCustom),
          ),
        ],
        selected: <_TaxMode>{_taxMode},
        onSelectionChanged: (Set<_TaxMode> selection) =>
            setState(() => _taxMode = selection.first),
      ),
      const SizedBox(height: AppSpacing.md),
      if (_taxMode == _TaxMode.custom)
        AppTextField(
          controller: _taxRate,
          label: strings.invoiceLineTaxCustom,
          maxLength: AmountLimits.tomanDigits,
          suffixText: kPersianPercentSign,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // Required in this mode, and `0` passes: an explicit
          // zero is the entire point of the mode (D-026).
          validator: (String? value) =>
              _validatePercent(value, strings, required: true),
        )
      else if (widget.resolvedTaxRateBp != null)
        // "Default" is only reassuring if it says which default.
        // The figure is the engine's, read off the calculated
        // line -- this widget resolves nothing.
        Text(
          strings.invoiceLineTaxInheritedNote(
            formatPercentFromBasisPoints(widget.resolvedTaxRateBp!),
          ),
          style: theme.textTheme.bodySmall,
        ),
    ];
  }

  /// An existing line: the quantity, and the rest as the line states it.
  ///
  /// **The controllers still hold every value**, untouched since [initState],
  /// so [_submit] builds the same entry it always did -- the line comes back
  /// with its title, unit, price, discount and rate exactly as they went in.
  /// Not collecting a field and not carrying it are different things, and only
  /// the first is intended here.
  ///
  /// The fields that are gone are not disabled inputs either. A greyed-out text
  /// field is an invitation the screen then refuses (D-021's rule, one level
  /// down); a stated value with a sentence explaining it is the same
  /// information without the invitation.
  List<Widget> _quantityOnlyFields(BuildContext context, AppStrings strings) {
    final InvoiceLineEntry existing = widget.existing!;
    final ThemeData theme = Theme.of(context);

    final int? discountPercent = existing.discountPercentBp;
    final bool hasDiscount =
        discountPercent != null || existing.discount != Money.zero;

    return <Widget>[
      // The title identifies the line rather than labelling a field, so it
      // takes a heading weight and carries no label of its own.
      Text(existing.title, style: theme.textTheme.titleMedium),
      const SizedBox(height: AppSpacing.lg),
      _quantityField(strings),
      const SizedBox(height: AppSpacing.xl),
      _FixedValue(label: strings.productFieldUnit, value: existing.unit),
      _FixedValue(
        label: strings.invoiceLineFieldUnitPrice,
        value: strings.amountWithUnit(
          formatGroupedPersian(existing.unitPrice.toman),
          strings.unitToman,
        ),
      ),
      if (hasDiscount)
        _FixedValue(
          label: strings.invoiceLineDiscountSection,
          value: discountPercent != null
              ? formatPercentFromBasisPoints(discountPercent)
              : strings.amountWithUnit(
                  formatGroupedPersian(existing.discount.toman),
                  strings.unitToman,
                ),
        ),
      _FixedValue(
        label: strings.invoiceLineTaxSection,
        value: switch ((existing.taxRateBp, widget.resolvedTaxRateBp)) {
          (final int rate, _) => formatPercentFromBasisPoints(rate),
          // Inheriting: say which rate it inherits, exactly as the compose
          // form does, rather than printing the word "default" on its own.
          (null, final int resolved) => strings.invoiceLineTaxInheritedNote(
            formatPercentFromBasisPoints(resolved),
          ),
          (null, null) => strings.invoiceLineTaxInherit,
        },
        isLast: true,
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        strings.invoiceLineFixedNote,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }

  /// The one field both shapes share.
  ///
  /// Autofocused when it is the only field, which is the state the user opened
  /// the sheet to change; on a new line the title comes first and takes it.
  Widget _quantityField(AppStrings strings) {
    return AppTextField(
      controller: _quantity,
      label: strings.invoiceLineFieldQuantity,
      // A quantity has no column length -- it is stored as
      // an integer -- but the field still needs a bound,
      // and this one is far past any real quantity.
      maxLength: AmountLimits.tomanDigits,
      helperText: strings.invoiceLineFieldQuantityHelper,
      autofocus: widget.existing != null,
      // NOT digitsOnly: the decimal separator is
      // meaningful here (section 4 allows three places), and a
      // formatter that ate it would make a fractional
      // quantity impossible to type rather than merely
      // invalid.
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      validator: (String? value) => _validateQuantity(value, strings),
    );
  }

  /// Builds the entry and returns it.
  ///
  /// Every value is parsed **here**, at the field boundary, so
  /// [InvoiceLineEntry] receives typed values only and nothing downstream has
  /// to wonder whether a figure is trustworthy.
  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Safe after validation: each validator above refuses exactly what its
    // parser returns null for.
    final int quantityMilli = tryParseScaledInput(
      _quantity.text.trim(),
      scale: 1000,
    )!;
    final Money unitPrice = Money.toman(tryParseIntInput(_unitPrice.text)!);

    final String discountText = _discount.text.trim();
    final bool hasDiscount = discountText.isNotEmpty;
    final bool isPercent = _discountMode == _DiscountMode.percent;

    Navigator.of(context).pop(
      InvoiceLineEntry(
        title: _title.text.trim(),
        unit: _unit.text.trim(),
        unitPrice: unitPrice,
        quantityMilli: quantityMilli,
        productId: _productId,
        // Exactly one of the two is ever set. A stale percentage left beside an
        // amount would win in the engine over the amount the user just typed
        // (§4 step 2) — the same reason `setDiscountAmount` clears it.
        discount: hasDiscount && !isPercent
            ? Money.toman(tryParseIntInput(discountText)!)
            : Money.zero,
        discountPercentBp: hasDiscount && isPercent
            ? tryParseScaledInput(discountText, scale: 100)
            : null,
        // The three-state field collapses here, and only here: inherit is null,
        // and an explicit rate is its value, zero included (D-026).
        taxRateBp: _taxMode == _TaxMode.custom
            ? tryParseScaledInput(_taxRate.text.trim(), scale: 100)
            : null,
      ),
    );
  }

  FormFieldValidator<String> _requiredField(AppStrings strings) =>
      (String? value) => (value == null || value.trim().isEmpty)
      ? strings.validationRequired
      : null;

  /// Rejects a fourth decimal place rather than truncating it.
  ///
  /// `tryParseScaledInput` returns null both for "not a number" and for "more
  /// precision than milli can hold", and those deserve different messages: the
  /// second is a rule the user could not have known, and telling them
  /// «نادرست» would leave them retyping the same thing. Distinguished by
  /// re-parsing at a finer scale — if it parses there and not here, precision
  /// is what is wrong.
  String? _validateQuantity(String? value, AppStrings strings) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return strings.validationRequired;

    final int? milli = tryParseScaledInput(text, scale: 1000);
    if (milli != null) {
      return milli < 0 ? strings.validationQuantityInvalid : null;
    }

    final bool parsesWithMorePrecision =
        tryParseScaledInput(text, scale: 1000000) != null;
    return parsesWithMorePrecision
        ? strings.validationQuantityTooPrecise
        : strings.validationQuantityInvalid;
  }

  String? _validateAmount(
    String? value,
    AppStrings strings, {
    required bool required,
  }) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return required ? strings.validationRequired : null;

    final int? toman = tryParseIntInput(text);
    if (toman == null || toman < 0) return strings.validationAmountInvalid;
    // The ceiling rejects rather than truncates (D-002); said here, while the
    // field is still in front of the user, rather than as an error on save.
    if (toman > kMaxAmountRial ~/ 10) return strings.validationAmountTooLarge;
    return null;
  }

  /// A percentage in basis points, which is what two decimal places of a
  /// percent *is*: `9.5` at `scale: 100` is `950`, exactly, with no rounding.
  String? _validatePercent(
    String? value,
    AppStrings strings, {
    required bool required,
  }) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return required ? strings.validationRequired : null;

    final int? bp = tryParseScaledInput(text, scale: 100);
    if (bp == null || bp < 0 || bp > 10000) {
      return strings.validationPercentInvalid;
    }
    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }
}

/// A value the line already carries, stated rather than offered for editing.
///
/// Shaped like the read-only rows the customer and invoice detail screens use --
/// a muted label with the value beneath it -- rather than like a disabled text
/// field, because it is not a field the user is being kept out of. It is what
/// the line says.
class _FixedValue extends StatelessWidget {
  const _FixedValue({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Toman as plain ASCII digits for a text field. **Not** the grouped Persian
/// display form: this is a value the user edits and the field re-parses, and
/// grouping separators in an editable field are characters they have to delete.
String _tomanText(Money? amount) => amount == null ? '' : '${amount.toman}';

/// `1500` becomes `1.5` and `2000` becomes `2` — trailing zeros trimmed,
/// because a quantity field pre-filled with `1.000` invites the user to wonder
/// whether the app means one or one thousand.
///
/// **Deliberately not `formatQuantityMilli`**, which is the *display* form:
/// Persian digits and a Persian decimal separator. This is the *editable* form.
/// The two differ because a field's text is re-parsed on submit, and pre-filling
/// it with characters the parser has to fold back is how a value the user never
/// touched can come out different from the one that went in.
String _quantityText(int quantityMilli) =>
    _scaledText(quantityMilli, digits: 3);

/// Basis points as a percent string, on the same rule: `950` becomes `9.5`.
String _percentText(int basisPoints) => _scaledText(basisPoints, digits: 2);

String _scaledText(int scaled, {required int digits}) {
  final int scale = digits == 2 ? 100 : 1000;
  final int whole = scaled ~/ scale;
  final int fraction = scaled % scale;
  if (fraction == 0) return '$whole';

  final String padded = fraction.toString().padLeft(digits, '0');
  final String trimmed = padded.replaceFirst(RegExp(r'0+$'), '');
  return '$whole.$trimmed';
}
