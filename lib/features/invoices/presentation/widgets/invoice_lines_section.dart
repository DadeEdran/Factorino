import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/number_display.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/money/invoice_calculator.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_table.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../data/models/product.dart';
import '../../application/invoice_editor.dart';
import '../../domain/invoice_editor_state.dart';
import '../../domain/invoice_warning_message.dart';
import 'invoice_line_editor_sheet.dart';
import 'product_picker_sheet.dart';

/// The lines of the invoice being edited, and the two ways to add one.
///
/// **Every figure on this widget comes from [InvoiceEditorState.totals].** The
/// entry at index `i` and the calculated line at index `i` describe the same
/// row — the engine returns one `CalculatedLine` per input line, in order — so
/// the row shows what the user typed beside what §4 made of it. Nothing here
/// multiplies a quantity by a price; `single_calculation_path_test.dart` fails
/// the build if it ever tries.
///
/// The distinction that row rendering has to get right: a line shows the
/// discount **actually applied**, `CalculatedLine.discount`, not the one
/// entered. Where the two differ the engine has already raised a warning, and
/// [_Warnings] states both figures. Printing the requested amount beside a
/// total that does not include it is how a document stops reconciling.
class InvoiceLinesSection extends ConsumerWidget {
  const InvoiceLinesSection({required this.openedAt, super.key});

  /// The editor's family key. Held by the screen and passed down — never a
  /// fresh `DateTime.now()`, which would address a new, empty editor on every
  /// frame and discard the invoice as it is typed.
  final DateTime openedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final AsyncValue<InvoiceEditorState> editor = ref.watch(
      invoiceEditorProvider(openedAt),
    );

    return editor.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      // The editor's only failure is the settings read behind it; the screen
      // owns that error surface, so this stays quiet rather than showing a
      // second one.
      error: (Object error, StackTrace stack) => const SizedBox.shrink(),
      data: (InvoiceEditorState state) =>
          _Lines(openedAt: openedAt, state: state, strings: strings),
    );
  }
}

class _Lines extends ConsumerWidget {
  const _Lines({
    required this.openedAt,
    required this.state,
    required this.strings,
  });

  final DateTime openedAt;
  final InvoiceEditorState state;
  final AppStrings strings;

  InvoiceEditor _editor(WidgetRef ref) =>
      ref.read(invoiceEditorProvider(openedAt).notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LayoutTier tier = context.tier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(title: strings.invoiceLinesTitle),
        const SizedBox(height: AppSpacing.md),
        if (state.lines.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: strings.invoiceLinesEmptyTitle,
            body: strings.invoiceLinesEmptyBody,
          )
        else if (tier.isDesktop)
          _LinesTable(
            state: state,
            strings: strings,
            onEdit: (int index) => _edit(context, ref, index),
            onRemove: (int index) => _editor(ref).removeLine(index),
            onMove: (int from, int to) => _editor(ref).moveLine(from, to),
          )
        else
          _LinesCards(
            state: state,
            strings: strings,
            onEdit: (int index) => _edit(context, ref, index),
            onRemove: (int index) => _editor(ref).removeLine(index),
            onMove: (int from, int to) => _editor(ref).moveLine(from, to),
          ),
        const SizedBox(height: AppSpacing.md),
        _AddActions(
          strings: strings,
          onAddFromCatalogue: () => _addFromCatalogue(context, ref),
          onAddCustom: () => _addCustom(context, ref),
        ),
        if (state.hasWarnings) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          _Warnings(state: state, strings: strings),
        ],
      ],
    );
  }

  /// Picks a catalogue entry, then opens the line editor pre-filled from it.
  ///
  /// Two steps rather than one because the copy is not the end of it: a picked
  /// product still needs a quantity, and it may need a discount or a rate. The
  /// sheet is where the user sees what was copied and can change it before the
  /// line exists — which is the honest reading of "the price is a snapshot".
  Future<void> _addFromCatalogue(BuildContext context, WidgetRef ref) async {
    final Product? product = await showProductPickerSheet(context);
    if (product == null || !context.mounted) return;

    final InvoiceLineEntry? line = await showInvoiceLineEditorSheet(
      context,
      product: product,
      resolvedTaxRateBp: _inheritedRateBp,
    );
    if (line != null) _editor(ref).addLine(line);
  }

  Future<void> _addCustom(BuildContext context, WidgetRef ref) async {
    final InvoiceLineEntry? line = await showInvoiceLineEditorSheet(
      context,
      resolvedTaxRateBp: _inheritedRateBp,
    );
    if (line != null) _editor(ref).addLine(line);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, int index) async {
    if (index < 0 || index >= state.lines.length) return;

    final InvoiceLineEntry? line = await showInvoiceLineEditorSheet(
      context,
      existing: state.lines[index],
      // This line's own resolved rate, which is what "inherit" means for it
      // specifically — the invoice rate if one is set, the settings default
      // otherwise (§4 step 6).
      resolvedTaxRateBp: state.totals.lines[index].resolvedTaxRateBp,
    );
    if (line != null) _editor(ref).replaceLine(index, line);
  }

  /// What a **new** line would inherit.
  ///
  /// Taken from an existing calculated line where there is one, because that is
  /// the engine's own answer for this invoice under these settings. With no
  /// lines yet there is nothing calculated to read, and this widget may not
  /// resolve the chain itself — so it says nothing rather than guessing, and
  /// the sheet omits the note.
  int? get _inheritedRateBp => state.totals.lines.isEmpty
      ? null
      : state.totals.lines.first.resolvedTaxRateBp;
}

/// Cards on mobile and tablet: a squeezed table is not a table (§10).
class _LinesCards extends StatelessWidget {
  const _LinesCards({
    required this.state,
    required this.strings,
    required this.onEdit,
    required this.onRemove,
    required this.onMove,
  });

  final InvoiceEditorState state;
  final AppStrings strings;
  final void Function(int index) onEdit;
  final void Function(int index) onRemove;
  final void Function(int from, int to) onMove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int index = 0; index < state.lines.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _LineCard(
              index: index,
              entry: state.lines[index],
              calculated: state.totals.lines[index],
              strings: strings,
              lineCount: state.lines.length,
              onEdit: () => onEdit(index),
              onRemove: () => onRemove(index),
              onMove: onMove,
            ),
          ),
      ],
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.index,
    required this.entry,
    required this.calculated,
    required this.strings,
    required this.lineCount,
    required this.onEdit,
    required this.onRemove,
    required this.onMove,
  });

  final int index;
  final InvoiceLineEntry entry;
  final CalculatedLine calculated;
  final AppStrings strings;
  final int lineCount;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final void Function(int from, int to) onMove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(entry.title, style: theme.textTheme.titleMedium),
              ),
              // The line total, which is the figure the user is checking.
              AmountText(
                calculated.total,
                unitLabel: strings.unitToman,
                size: AmountSize.small,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings.invoiceLineLabelQuantity(
              formatQuantityMilli(entry.quantityMilli),
              entry.unit,
              formatGroupedPersian(entry.unitPrice.toman),
            ),
            style: theme.textTheme.bodySmall,
          ),
          for (final String detail in _details(strings, calculated))
            Text(detail, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          _RowActions(
            index: index,
            lineCount: lineCount,
            strings: strings,
            onRemove: onRemove,
            onMove: onMove,
          ),
        ],
      ),
    );
  }
}

/// A real table on desktop (§10), with the same figures.
class _LinesTable extends StatelessWidget {
  const _LinesTable({
    required this.state,
    required this.strings,
    required this.onEdit,
    required this.onRemove,
    required this.onMove,
  });

  final InvoiceEditorState state;
  final AppStrings strings;
  final void Function(int index) onEdit;
  final void Function(int index) onRemove;
  final void Function(int from, int to) onMove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<TableColumnSpec> columns = <TableColumnSpec>[
      TableColumnSpec(label: strings.invoiceLineColumnDescription, flex: 4),
      TableColumnSpec(label: strings.invoiceLineColumnQuantity, flex: 2),
      TableColumnSpec(
        label: strings.invoiceLineColumnUnitPrice,
        flex: 2,
        alignEnd: true,
      ),
      TableColumnSpec(
        label: strings.invoiceLineColumnTotal,
        flex: 2,
        alignEnd: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTableHeader(columns: columns, trailingWidth: _trailingWidth),
        for (int index = 0; index < state.lines.length; index++)
          AppTableRow(
            columns: columns,
            onTap: () => onEdit(index),
            trailingWidth: _trailingWidth,
            trailing: _RowActions(
              index: index,
              lineCount: state.lines.length,
              strings: strings,
              onRemove: () => onRemove(index),
              onMove: onMove,
            ),
            cells: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(state.lines[index].title),
                  for (final String detail in _details(
                    strings,
                    state.totals.lines[index],
                  ))
                    Text(detail, style: theme.textTheme.bodySmall),
                ],
              ),
              Text(
                '${formatQuantityMilli(state.lines[index].quantityMilli)} '
                '${state.lines[index].unit}',
              ),
              AmountText(
                state.lines[index].unitPrice,
                unitLabel: strings.unitToman,
                size: AmountSize.small,
              ),
              AmountText(
                state.totals.lines[index].total,
                unitLabel: strings.unitToman,
                size: AmountSize.small,
              ),
            ],
          ),
      ],
    );
  }

  /// Room for three icon buttons — remove and the two reorder controls.
  static const double _trailingWidth = 144;
}

/// Remove, and reorder by one step in each direction.
///
/// Buttons rather than drag-to-reorder: this list sits inside the invoice
/// form's own scroll view, where a long-press drag competes with the scroll
/// gesture, and on desktop there is no drag affordance at all. Two taps that
/// always work beat one gesture that sometimes does. `moveLine` already exists
/// for exactly this; `invoice_items.position` is what it ends up in.
class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.index,
    required this.lineCount,
    required this.strings,
    required this.onRemove,
    required this.onMove,
  });

  final int index;
  final int lineCount;
  final AppStrings strings;
  final VoidCallback onRemove;
  final void Function(int from, int to) onMove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.arrow_upward),
          tooltip: strings.invoiceLineActionMoveUp,
          // Disabled rather than hidden at the ends: a control that vanishes
          // shifts the two beside it under the user's finger.
          onPressed: index == 0 ? null : () => onMove(index, index - 1),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_downward),
          tooltip: strings.invoiceLineActionMoveDown,
          onPressed: index == lineCount - 1
              ? null
              : () => onMove(index, index + 1),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: strings.invoiceLineActionRemove,
          onPressed: onRemove,
        ),
      ],
    );
  }
}

class _AddActions extends StatelessWidget {
  const _AddActions({
    required this.strings,
    required this.onAddFromCatalogue,
    required this.onAddCustom,
  });

  final AppStrings strings;
  final VoidCallback onAddFromCatalogue;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    // Both routes in are visible at once. The free-text line is not a fallback
    // discovered after the picker disappoints — for a workshop billing one-off
    // jobs it is the ordinary case.
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: onAddFromCatalogue,
          icon: const Icon(Icons.inventory_2_outlined),
          label: Text(strings.invoiceLineAddFromCatalogue),
        ),
        OutlinedButton.icon(
          onPressed: onAddCustom,
          icon: const Icon(Icons.edit_outlined),
          label: Text(strings.invoiceLineAddCustom),
        ),
      ],
    );
  }
}

/// D-027's warnings, rendered through their one message function.
///
/// Deliberately styled as a notice and not an error: the totals are correct and
/// the invoice is usable. What is questionable is the input, and only the user
/// can settle it.
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
              // Expanded, because the heading is a Persian sentence and the
              // narrowest tier is 320dp wide: unwrapped it overflows the row.
              // Found by a widget test at the phone size, which is the whole
              // reason the harness pins a size (§10).
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

/// The secondary figures on a row: the discount actually applied, and the rate
/// that actually applied. Both read off the calculated line, never re-derived.
///
/// Omitted when zero. A row saying «تخفیف ۰ تومان» on every line is noise that
/// makes the rows carrying a real discount harder to find.
List<String> _details(AppStrings strings, CalculatedLine calculated) {
  return <String>[
    if (calculated.discount.rial != 0)
      strings.invoiceLineLabelDiscount(
        formatGroupedPersian(calculated.discount.toman),
      ),
    if (calculated.resolvedTaxRateBp != 0)
      strings.invoiceLineLabelTax(
        formatPercentFromBasisPoints(calculated.resolvedTaxRateBp),
      ),
  ];
}
