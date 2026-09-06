import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/number_display.dart';
import '../../../../core/formatting/number_input.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/localization/money_display.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/editor_sheet.dart';
import '../../../../data/models/field_limits.dart';
import '../../../../data/models/money_display_unit.dart';
import '../../application/invoice_editor.dart';
import '../../domain/invoice_editor_state.dart';
import '../../domain/invoice_warning_message.dart';

/// Identifies the invoice-level discount control.
///
/// The sheet lists one control per line beneath this one, and every one of them
/// carries the same two Persian words — «مبلغ» and «درصد» — because they are the
/// same question at different scopes. Matching on the label therefore cannot say
/// *which* control is meant, and the list is long enough to be virtualized, so
/// counting them does not work either: a test that entered a figure into "the
/// third field" would be entering it into whichever field happened to be built.
/// Named keys are how a test says which line it means, and how it scrolls to it.
const Key kInvoiceDiscountInvoiceKey = Key('invoice-discount.invoice');

/// Identifies one line's discount control. See [kInvoiceDiscountInvoiceKey].
Key invoiceDiscountLineKey(int index) =>
    ValueKey<String>('invoice-discount.line.$index');

/// How a discount was expressed. Both are kept (§4 step 2): the percentage as
/// entered and the amount it resolves to.
enum _Mode { amount, percent }

/// Discounting, as a step of its own (D-098).
///
/// ## Why this is a screen and not a field
///
/// Discounts used to be entered in two unrelated places: a per-line one inside
/// the sheet that adds a line, and the invoice-level one among the optional
/// fields under «مشخصات فاکتور». Neither placement was wrong on its own terms
/// and together they were incoherent — the same question, asked in two forms,
/// on two screens, one of them mixed into the act of adding a product.
///
/// D-097 took the per-line discount out of the add-a-line sheet and the form
/// was better for it, but that left the capability gone rather than moved. This
/// is where it moves to: **one place that answers "what is coming off this
/// invoice", at both levels, after the lines are entered.** Discounting is a
/// decision about a finished list, not a property of each thing as it is added.
///
/// ## The three things it has to do
///
/// 1. **Take an amount or a percentage, at either level.** §4 step 2 is
///    unchanged — a percentage is resolved to an amount by the engine and both
///    are kept — this is only where it is typed.
/// 2. **Show what the discount does to the total before it is committed.** The
///    footer states the payable figure as it stands and as it would be, so the
///    user agrees to a number rather than to an intention.
/// 3. **State a clamped input** (D-027). A discount larger than what it applies
///    to is almost always a typo, and the engine has reported it as data since
///    Phase 4 with nowhere to say it that the user was looking at. This screen
///    is that place: the warnings appear **while typing**, before anything is
///    applied, and they are **pinned beside the commit action** rather than
///    left in the scroll — see the note on `action` below for why that turned
///    out to matter.
///
/// ## Nothing here calculates
///
/// The preview is `InvoiceEditorState.copyWith(...)`, whose constructor runs
/// `calculateInvoice` — the one calculator (§4, D-046). This widget assembles
/// entries and reads `totals`; it never adds two amounts together.
/// `single_calculation_path_test.dart` fails the build if that stops being
/// true.
Future<void> showInvoiceDiscountSheet(
  BuildContext context,
  WidgetRef ref,
  DateTime openedAt,
) async {
  final InvoiceEditorState? state = ref
      .read(invoiceEditorProvider(openedAt))
      .value;
  if (state == null || state.lines.isEmpty) return;

  final _Result? result = await showModalBottomSheet<_Result>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _InvoiceDiscountSheet(base: state),
  );
  if (result == null) return;

  ref
      .read(invoiceEditorProvider(openedAt).notifier)
      .applyDiscounts(
        lines: result.lines,
        discount: result.discount,
        discountPercentBp: result.discountPercentBp,
      );
}

/// What the sheet hands back: the whole arrangement, already assembled.
///
/// The lines are the full replacement list rather than a diff, so what is
/// applied is exactly the state the footer previewed.
class _Result {
  const _Result({
    required this.lines,
    required this.discount,
    required this.discountPercentBp,
  });

  final List<InvoiceLineEntry> lines;
  final Money discount;
  final int? discountPercentBp;
}

class _InvoiceDiscountSheet extends StatefulWidget {
  const _InvoiceDiscountSheet({required this.base});

  /// The invoice as it stands. Never mutated: the sheet previews against a copy
  /// and the real state moves once, on apply.
  final InvoiceEditorState base;

  @override
  State<_InvoiceDiscountSheet> createState() => _InvoiceDiscountSheetState();
}

class _InvoiceDiscountSheetState extends State<_InvoiceDiscountSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late _Mode _invoiceMode;
  late final TextEditingController _invoice;

  late final List<_Mode> _lineModes;
  late final List<TextEditingController> _lineFields;

  @override
  void initState() {
    super.initState();

    final InvoiceEditorState base = widget.base;

    _invoiceMode = base.discountPercentBp == null
        ? _Mode.amount
        : _Mode.percent;
    _invoice = TextEditingController(
      text: base.discountPercentBp != null
          ? _percentText(base.discountPercentBp!)
          : _amountText(kDisplayUnit, base.discount),
    );

    _lineModes = <_Mode>[
      for (final InvoiceLineEntry line in base.lines)
        line.discountPercentBp == null ? _Mode.amount : _Mode.percent,
    ];
    _lineFields = <TextEditingController>[
      for (final InvoiceLineEntry line in base.lines)
        TextEditingController(
          text: line.discountPercentBp != null
              ? _percentText(line.discountPercentBp!)
              : _amountText(kDisplayUnit, line.discount),
        ),
    ];
  }

  @override
  void dispose() {
    _invoice.dispose();
    for (final TextEditingController controller in _lineFields) {
      controller.dispose();
    }
    super.dispose();
  }

  /// The lines as the fields currently describe them.
  ///
  /// Parsed **leniently**: an unparseable field previews as no discount rather
  /// than freezing the footer, because the preview updates on every keystroke
  /// and a half-typed number is the ordinary state of a field being filled in.
  /// [_submit] is where the same values are validated strictly, and the two use
  /// the same parsers so they cannot disagree about what a number is.
  List<InvoiceLineEntry> get _draftLines => <InvoiceLineEntry>[
    for (int i = 0; i < widget.base.lines.length; i++)
      _applied(widget.base.lines[i], _lineModes[i], _lineFields[i].text),
  ];

  InvoiceLineEntry _applied(InvoiceLineEntry line, _Mode mode, String text) {
    final String value = text.trim();
    if (value.isEmpty) {
      return line.copyWith(discount: Money.zero, clearDiscountPercent: true);
    }
    if (mode == _Mode.percent) {
      final int? bp = tryParseScaledInput(value, scale: 100);
      return line.copyWith(
        discount: Money.zero,
        discountPercentBp: bp,
        clearDiscountPercent: bp == null,
      );
    }
    final int? entered = tryParseIntInput(value);
    return line.copyWith(
      discount: entered == null ? Money.zero : kDisplayUnit.moneyOf(entered),
      clearDiscountPercent: true,
    );
  }

  Money get _draftInvoiceDiscount {
    if (_invoiceMode == _Mode.percent) return Money.zero;
    final int? entered = tryParseIntInput(_invoice.text.trim());
    return entered == null ? Money.zero : kDisplayUnit.moneyOf(entered);
  }

  int? get _draftInvoicePercent {
    if (_invoiceMode == _Mode.amount) return null;
    return tryParseScaledInput(_invoice.text.trim(), scale: 100);
  }

  /// The invoice as it would be. **The engine's answer, not this widget's.**
  InvoiceEditorState get _preview => widget.base.copyWith(
    lines: _draftLines,
    discount: _draftInvoiceDiscount,
    discountPercentBp: _draftInvoicePercent,
    clearDiscountPercent: _draftInvoicePercent == null,
  );

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _Result(
        lines: _draftLines,
        discount: _draftInvoiceDiscount,
        discountPercentBp: _draftInvoicePercent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final InvoiceEditorState preview = _preview;

    return EditorSheet(
      title: strings.invoiceDiscountTitle,
      closeTooltip: strings.actionCancel,
      formKey: _formKey,
      // **The warnings are pinned with the action, not left in the scroll.**
      // They were under the line controls at first and the test could not find
      // them — because on a phone they were below the fold, which means the
      // user could not find them either. A warning the person committing does
      // not see is not a warning; it is a record of one.
      //
      // This is D-062's rule reaching one step further. That primitive exists
      // so a commit action cannot scroll away from the person committing; the
      // sentence explaining why the figure they are committing to is not the
      // figure they typed belongs on the same side of that line.
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (preview.hasWarnings) ...<Widget>[
            _Warnings(state: preview, strings: strings),
            const SizedBox(height: AppSpacing.md),
          ],
          FilledButton(
            onPressed: _submit,
            child: Text(strings.invoiceDiscountApply),
          ),
        ],
      ),
      children: <Widget>[
        _Preview(base: widget.base, preview: preview, strings: strings),
        const SizedBox(height: AppSpacing.xl),
        _SectionLabel(strings.invoiceFieldDiscount),
        const SizedBox(height: AppSpacing.sm),
        _DiscountControl(
          key: kInvoiceDiscountInvoiceKey,
          strings: strings,
          mode: _invoiceMode,
          controller: _invoice,
          onModeChanged: (_Mode mode) => setState(() {
            _invoiceMode = mode;
            // The two are alternatives, not two views of one number: `10` means
            // ten Toman in one mode and ten percent in the other, and carrying
            // the text across would silently change what the user entered.
            _invoice.clear();
          }),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionLabel(strings.invoiceDiscountLinesSection),
        const SizedBox(height: AppSpacing.sm),
        for (int i = 0; i < widget.base.lines.length; i++) ...<Widget>[
          _LineDiscount(
            key: invoiceDiscountLineKey(i),
            strings: strings,
            // 1-based, because no invoice has a line zero — the same numbering
            // the clamp warnings quote.
            number: i + 1,
            line: widget.base.lines[i],
            mode: _lineModes[i],
            controller: _lineFields[i],
            onModeChanged: (_Mode mode) => setState(() {
              _lineModes[i] = mode;
              _lineFields[i].clear();
            }),
            onChanged: (_) => setState(() {}),
          ),
          if (i != widget.base.lines.length - 1)
            const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

/// What the discount does to the payable figure, before it is applied.
///
/// **Two figures and the difference between them.** The one the invoice comes
/// to now, and the one it would come to — because "apply a discount" is an
/// intention and the thing a user agrees to is a number. The saving is stated
/// rather than left to be worked out, on the one screen where working it out is
/// what the user came to avoid.
///
/// Every figure is read off a `CalculatedInvoice`; the difference is [Money]'s
/// own subtraction of two engine outputs, not arithmetic over the inputs.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.base,
    required this.preview,
    required this.strings,
  });

  final InvoiceEditorState base;
  final InvoiceEditorState preview;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Money now = base.totals.grandTotal;
    final Money after = preview.totals.grandTotal;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Row(
            label: strings.invoiceDiscountPayableNow,
            amount: now,
            strings: strings,
          ),
          const SizedBox(height: AppSpacing.sm),
          _Row(
            label: strings.invoiceSummaryDiscount,
            amount: preview.totals.totalDiscount,
            strings: strings,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(
              height: AppBorders.hairline,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          Text(
            strings.invoiceDiscountPayableAfter,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          AmountText(after, size: AmountSize.medium),
          // Only where the two differ. A «۰ تومان» saving on an untouched sheet
          // is a row about nothing, and it would be the first thing the user
          // reads every time they open this.
          if (now != after) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              strings.invoiceDiscountChange(
                formatGroupedPersian(kDisplayUnit.amountOf(now - after)),
                moneyUnitLabel(kDisplayUnit, strings),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.amount,
    required this.strings,
  });

  final String label;
  final Money amount;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        AmountText(amount, size: AmountSize.small),
      ],
    );
  }
}

/// One line, and what is coming off it.
class _LineDiscount extends StatelessWidget {
  const _LineDiscount({
    required this.strings,
    super.key,
    required this.number,
    required this.line,
    required this.mode,
    required this.controller,
    required this.onModeChanged,
    required this.onChanged,
  });

  final AppStrings strings;
  final int number;
  final InvoiceLineEntry line;
  final _Mode mode;
  final TextEditingController controller;
  final ValueChanged<_Mode> onModeChanged;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          strings.invoiceDiscountLineHeading(
            formatGroupedPersian(number),
            line.title,
          ),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xxs),
        // What the line is worth, so the user can see what a discount on it is
        // being measured against — which is exactly what a clamp warning is
        // about, stated before it fires rather than after.
        Text(
          strings.invoiceLineLabelQuantity(
            formatQuantityMilli(line.quantityMilli),
            line.unit,
            formatGroupedPersian(kDisplayUnit.amountOf(line.unitPrice)),
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DiscountControl(
          strings: strings,
          mode: mode,
          controller: controller,
          onModeChanged: onModeChanged,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// The mode switch and the field, which are the same pair at both levels.
///
/// One widget for both, so an invoice discount and a line discount cannot come
/// to accept different things — they are the same question at two scopes.
class _DiscountControl extends StatelessWidget {
  const _DiscountControl({
    required this.strings,
    super.key,
    required this.mode,
    required this.controller,
    required this.onModeChanged,
    required this.onChanged,
  });

  final AppStrings strings;
  final _Mode mode;
  final TextEditingController controller;
  final ValueChanged<_Mode> onModeChanged;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final MoneyDisplayUnit unit = kDisplayUnit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SegmentedButton<_Mode>(
          segments: <ButtonSegment<_Mode>>[
            ButtonSegment<_Mode>(
              value: _Mode.amount,
              label: Text(strings.invoiceLineDiscountModeAmount),
            ),
            ButtonSegment<_Mode>(
              value: _Mode.percent,
              label: Text(strings.invoiceLineDiscountModePercent),
            ),
          ],
          selected: <_Mode>{mode},
          onSelectionChanged: (Set<_Mode> selection) =>
              onModeChanged(selection.first),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: controller,
          label: mode == _Mode.amount
              ? strings.invoiceLineDiscountModeAmount
              : strings.invoiceLineDiscountModePercent,
          maxLength: AmountLimits.tomanDigits,
          suffixText: mode == _Mode.amount
              ? moneyUnitLabel(unit, strings)
              : kPersianPercentSign,
          helperText: strings.fieldOptional,
          keyboardType: TextInputType.numberWithOptions(
            decimal: mode == _Mode.percent,
          ),
          // Grouped in the amount mode only: a percentage is short by nature
          // and takes a decimal separator.
          groupDigits: mode == _Mode.amount,
          // Every keystroke, because the footer is a live preview: a figure the
          // user has typed but not "committed" would leave the payable amount
          // describing an invoice that is no longer the one on screen.
          onChanged: onChanged,
          validator: (String? value) => mode == _Mode.amount
              ? _validateAmount(value, strings, unit)
              : _validatePercent(value, strings),
        ),
      ],
    );
  }
}

/// D-027's warnings, rendered through their one message function.
///
/// Styled as a notice and not an error: the totals are correct and the invoice
/// is usable. What is questionable is the input, and only the user can settle
/// it.
class _Warnings extends StatelessWidget {
  const _Warnings({required this.state, required this.strings});

  final InvoiceEditorState state;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> messages = invoiceWarningMessages(
      state.warnings,
      strings,
      unit: kDisplayUnit,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.info_outline,
                size: AppIconSize.sm,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  strings.invoiceWarningsTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final String message in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(message, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
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

/// An optional amount in the chosen unit. The ceiling rejects rather than
/// truncates (D-002).
String? _validateAmount(
  String? value,
  AppStrings strings,
  MoneyDisplayUnit unit,
) {
  final String text = value?.trim() ?? '';
  if (text.isEmpty) return null;

  final int? entered = tryParseIntInput(text);
  if (entered == null || entered < 0) return strings.validationAmountInvalid;
  if (entered > unit.maxEnterableValue) return strings.validationAmountTooLarge;
  return null;
}

/// An optional percentage, in basis points — which is what two decimal places
/// of a percent *is*: `9.5` at `scale: 100` is `950`, exactly, no rounding.
String? _validatePercent(String? value, AppStrings strings) {
  final String text = value?.trim() ?? '';
  if (text.isEmpty) return null;

  final int? bp = tryParseScaledInput(text, scale: 100);
  if (bp == null || bp < 0 || bp > 10000) {
    return strings.validationPercentInvalid;
  }
  return null;
}

/// An amount in the chosen unit, grouped, as an editable field holds it.
///
/// Grouped since D-118: the field regroups on every keystroke and
/// `normalizeNumericInput` has always discarded the separator, so what the user
/// edits is readable and what the parser receives is unchanged.
String _amountText(MoneyDisplayUnit unit, Money amount) =>
    amount == Money.zero ? '' : formatGroupedPersian(unit.amountOf(amount));

/// Basis points as a percent string: `950` becomes `9.5`.
String _percentText(int basisPoints) {
  final int whole = basisPoints ~/ 100;
  final int fraction = basisPoints % 100;
  if (fraction == 0) return '$whole';
  return '$whole.${fraction.toString().padLeft(2, '0').replaceFirst(RegExp(r'0+$'), '')}';
}
