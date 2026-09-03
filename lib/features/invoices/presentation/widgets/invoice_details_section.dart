import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/number_display.dart';
import '../../../../core/formatting/number_input.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/jalali_date_picker.dart';
import '../../../../data/models/customer.dart';
import '../../../../data/models/field_limits.dart';
import '../../../customers/application/customers_providers.dart';
import '../../application/invoice_editor.dart';
import '../../domain/invoice_editor_state.dart';
import 'customer_picker_sheet.dart';

/// The invoice-level fields: customer, dates, whole-invoice discount, tax rate
/// and notes.
///
/// Everything that is a property of the document rather than of a line. It
/// **computes nothing** — the discount it collects is allocated across the
/// lines by the engine (§4 step 4) and the tax rate it collects is the middle
/// step of the resolution chain, both inside `InvoiceEditorState`.
///
/// **The invoice-level discount is no longer here** (D-098). It moved to
/// [showInvoiceDiscountSheet], beside the per-line discounts, because the two
/// answer one question — what is coming off this invoice — and were being asked
/// in two forms on two screens. What is left is the tax rate, whose
/// mode-plus-value control exists for the reason D-026 gives: an explicit `0`
/// is not the same as inheriting the settings default.
class InvoiceDetailsSection extends ConsumerStatefulWidget {
  const InvoiceDetailsSection({
    required this.openedAt,
    this.collapsible = false,
    this.showCustomer = true,
    super.key,
  });

  /// The editor's family key. Held by the screen and passed down.
  final DateTime openedAt;

  /// Whether the whole section folds behind its heading.
  ///
  /// **True on a phone, and measured rather than assumed.** These fields fill
  /// the first viewport of a 393 x 804 device, which put the buttons that add a
  /// line **400 logical pixels down** — so the first thing a user wants to do on
  /// an invoice form, say what is being billed, was below the fold, and so was
  /// every line after the first. Collapsed, the add-line buttons sit inside the
  /// first screen.
  ///
  /// The heading keeps showing the customer while collapsed, because the
  /// customer is the one field here the invoice cannot be saved without: a fold
  /// that hid a required field would make the «مشتری را انتخاب کنید» notice
  /// point at something the user cannot see.
  final bool collapsible;

  /// Whether the customer picker is one of these fields.
  ///
  /// **False on the phone, where it is pinned above instead** (D-096). The
  /// customer is not an invoice *detail* in the sense the rest of this section
  /// is — a date, a discount, a rate and a note are things an invoice may or
  /// may not carry, and the customer is the one field without which there is no
  /// invoice at all. Folding it behind a heading, alongside four optional
  /// fields, is what made picking one feel like an advanced step.
  ///
  /// The two wider tiers keep it here: they lay the fields out beside the lines
  /// rather than under them, so nothing is folded and nothing is buried.
  final bool showCustomer;

  @override
  ConsumerState<InvoiceDetailsSection> createState() =>
      _InvoiceDetailsSectionState();
}

enum _TaxMode { inherit, custom }

class _InvoiceDetailsSectionState extends ConsumerState<InvoiceDetailsSection> {
  final TextEditingController _taxRate = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  _TaxMode _taxMode = _TaxMode.inherit;

  /// **Collapsed to begin with**, where the section collapses at all.
  ///
  /// Measured on the phone rather than decided in the abstract: expanded, the
  /// buttons that add a line sit 400 logical pixels down on a 393 x 804 device
  /// and the first line is a scroll away; collapsed they are inside the first
  /// screen, and so is every line after it. The customer — the one field here
  /// that a save cannot do without — stays visible in the heading either way,
  /// which is what makes starting collapsed safe rather than merely shorter.
  bool _expanded = false;

  @override
  void dispose() {
    _taxRate.dispose();
    _notes.dispose();
    super.dispose();
  }

  InvoiceEditor get _editor =>
      ref.read(invoiceEditorProvider(widget.openedAt).notifier);

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final AsyncValue<InvoiceEditorState> editor = ref.watch(
      invoiceEditorProvider(widget.openedAt),
    );

    return editor.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      // The screen owns the error surface for the settings read behind this.
      error: (Object error, StackTrace stack) => const SizedBox.shrink(),
      data: (InvoiceEditorState state) => _fields(context, strings, state),
    );
  }

  Widget _fields(
    BuildContext context,
    AppStrings strings,
    InvoiceEditorState state,
  ) {
    final bool showFields = !widget.collapsible || _expanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.collapsible)
          _DetailsHeader(
            strings: strings,
            expanded: _expanded,
            // Null once the picker is pinned above: the heading showed the
            // customer only because the fold would otherwise have hidden the
            // one field a save cannot do without, and that is no longer true.
            customerId: widget.showCustomer ? state.customerId : null,
            showCustomer: widget.showCustomer,
            onTap: () => setState(() => _expanded = !_expanded),
          )
        else
          SectionHeader(title: strings.invoiceDetailsTitle),
        if (showFields) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          if (widget.showCustomer) ...<Widget>[
            InvoiceCustomerField(
              strings: strings,
              customerId: state.customerId,
              onPick: () => pickInvoiceCustomer(context, _editor),
              onClear: () => _editor.selectCustomer(null),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          JalaliDateField(
            label: strings.invoiceFieldIssueDate,
            value: state.issueDate,
            onPick: () => _pickIssueDate(context, state),
          ),
          const SizedBox(height: AppSpacing.lg),
          JalaliDateField(
            label: strings.invoiceFieldDueDate,
            value: state.dueDate,
            emptyLabel: strings.invoiceFieldDueDateCleared,
            onPick: () => _pickDueDate(context, state),
            onClear: () => _editor.setDueDate(null),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            strings.invoiceFieldTax,
            style: Theme.of(context).textTheme.labelLarge,
          ),
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
            onSelectionChanged: (Set<_TaxMode> selection) {
              setState(() {
                _taxMode = selection.first;
                if (_taxMode == _TaxMode.inherit) _taxRate.clear();
              });
              // Back to inherit is `null`, which is a different invoice from
              // `0` (D-026) — so it is sent, not merely displayed.
              if (_taxMode == _TaxMode.inherit) _editor.setTaxRate(null);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (_taxMode == _TaxMode.custom)
            AppTextField(
              controller: _taxRate,
              label: strings.invoiceLineTaxCustom,
              maxLength: AmountLimits.tomanDigits,
              suffixText: kPersianPercentSign,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _applyTaxRate,
            )
          else
            // Which default is in force, from settings — the terminating step of
            // the chain (§4 step 6). Named rather than left implicit, for the
            // same reason the line sheet names it.
            Text(
              strings.invoiceLineTaxInheritedNote(
                formatPercentFromBasisPoints(state.settings.defaultTaxRateBp),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            controller: _notes,
            label: strings.invoiceFieldNotes,
            maxLength: InvoiceLimits.notes,
            helperText: strings.fieldOptional,
            maxLines: 3,
            onChanged: _editor.setNotes,
          ),
        ],
      ],
    );
  }

  void _applyTaxRate(String text) {
    final String trimmed = text.trim();
    // Empty in custom mode is not yet a rate. It is deliberately **not** sent
    // as `null`: that would mean inherit, and the user has said it should not.
    if (trimmed.isEmpty) return;

    final int? bp = tryParseScaledInput(trimmed, scale: 100);
    if (bp == null || bp < 0 || bp > 10000) return;
    _editor.setTaxRate(bp);
  }

  Future<void> _pickIssueDate(
    BuildContext context,
    InvoiceEditorState state,
  ) async {
    final DateTime? picked = await showJalaliDatePicker(
      context,
      initial: state.issueDate,
    );
    if (picked != null) _editor.setIssueDate(picked);
  }

  Future<void> _pickDueDate(
    BuildContext context,
    InvoiceEditorState state,
  ) async {
    final DateTime? picked = await showJalaliDatePicker(
      context,
      initial: state.dueDate ?? state.issueDate,
      // A document cannot be due before it was issued. Enforced in the picker
      // rather than as a validation message afterwards: the days are simply not
      // selectable, which is a rule the user meets before breaking it.
      firstAllowed: state.issueDate,
    );
    if (picked != null) _editor.setDueDate(picked);
  }
}

/// The customer, as a tappable field rather than a dropdown.
///
/// A dropdown over thousands of customers is unusable and would have to load
/// them all; the picker sheet searches at the query level instead (§13).
/// Opens the customer picker and records what it returns.
///
/// **Top-level, because two placements call it** (D-096): the field inside
/// [InvoiceDetailsSection] on the wider tiers, and the pinned header on the
/// phone. One function rather than two closures, so the two entry points cannot
/// come to select a customer differently.
Future<void> pickInvoiceCustomer(
  BuildContext context,
  InvoiceEditor editor,
) async {
  final Customer? customer = await showCustomerPickerSheet(context);
  if (customer != null) editor.selectCustomer(customer.id);
}

/// The customer picker.
///
/// **Public, because the phone pins it above the scroll** (D-096) while the
/// wider tiers keep it inside [InvoiceDetailsSection]. One widget either way, so
/// the two placements cannot come to look or behave differently.
class InvoiceCustomerField extends ConsumerWidget {
  const InvoiceCustomerField({
    required this.strings,
    required this.customerId,
    required this.onPick,
    required this.onClear,
    super.key,
  });

  final AppStrings strings;
  final String? customerId;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? id = customerId;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: strings.invoiceFieldCustomer,
          suffixIcon: id == null
              ? const Icon(Icons.person_search_outlined)
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: strings.actionCancel,
                  onPressed: onClear,
                ),
        ),
        child: id == null
            ? Text(strings.invoiceFieldCustomerEmpty)
            : _CustomerName(id: id),
      ),
    );
  }
}

/// The chosen customer's name, resolved by id.
///
/// A read of one row rather than a name carried in the editor state, and that
/// is deliberate: the state holds `customerId` because that is what the invoice
/// stores, and duplicating the name into it would create a second copy that
/// goes stale the moment the customer is renamed. **Whether an issued invoice
/// should keep the name as it was is a separate question, answered in D-051 —
/// it is a schema change and not this widget's to make.**
class _CustomerName extends ConsumerWidget {
  const _CustomerName({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `customerByIdProvider`, the one the customer detail screen uses — not a
    // second read path built for this field.
    final AsyncValue<Customer?> customer = ref.watch(customerByIdProvider(id));

    return customer.when(
      loading: () => const SizedBox(height: AppSpacing.lg),
      error: (Object error, StackTrace stack) => const SizedBox.shrink(),
      data: (Customer? value) => Text(value?.fullName ?? ''),
    );
  }
}

/// The section heading when it folds.
///
/// **It states the customer, collapsed or not.** Everything else in this
/// section has a working default — the dates are filled, the discount and the
/// tax and the notes are optional — but an invoice cannot be saved without a
/// customer, and a fold that hid the one required field would leave the
/// «مشتری را انتخاب کنید» notice under the buttons pointing at nothing on
/// screen.
///
/// The whole row is the target, not the chevron alone: a header that is
/// obviously a control but tappable only on a 20-pixel glyph is a control the
/// user misses twice before finding it. Same shape as the customer detail
/// screen's record card, deliberately — two disclosure headers that behaved
/// differently would be worse than one shared idiom.
class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({
    required this.strings,
    required this.expanded,
    required this.customerId,
    required this.showCustomer,
    required this.onTap,
  });

  final AppStrings strings;
  final bool expanded;
  final String? customerId;

  /// Whether this section owns the customer at all. When false the heading says
  /// what the section holds rather than who the invoice is for, because the
  /// answer to the second question is pinned above it.
  final bool showCustomer;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? id = customerId;

    return Tooltip(
      message: strings.invoiceDetailsToggle,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      strings.invoiceDetailsTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    if (!showCustomer)
                      Text(
                        strings.invoiceDetailsCollapsedSummary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else if (id == null)
                      Text(
                        strings.invoiceDetailsCollapsedNoCustomer,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      DefaultTextStyle.merge(
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        // The same read the field itself uses, so the heading
                        // and the field cannot disagree about who this invoice
                        // is for.
                        child: _CustomerName(id: id),
                      ),
                  ],
                ),
              ),
              // A chevron is vertical disclosure, and vertical does not mirror
              // in RTL (§9).
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: AppIconSize.lg,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
