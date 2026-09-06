import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/number_display.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/localization/money_display.dart';
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
  const InvoiceLinesSection({
    required this.openedAt,
    this.showAddActions = true,
    super.key,
  });

  /// Whether the two add-a-line buttons sit at the foot of this section.
  ///
  /// **False on the phone, where they are pinned above the scroll** (D-096).
  /// Known issue 30 was three attempts at keeping this control reachable —
  /// folding the details (D-054), withdrawing «صدور» from the bar (D-086), and
  /// putting the lines first (D-093) — and each moved it somewhere better while
  /// leaving it in the scroll. Pinning it ends the question: it cannot scroll
  /// away from anywhere, on an invoice of any length.
  final bool showAddActions;

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
      data: (InvoiceEditorState state) => _Lines(
        openedAt: openedAt,
        state: state,
        strings: strings,
        showAddActions: showAddActions,
      ),
    );
  }
}

class _Lines extends ConsumerWidget {
  const _Lines({
    required this.openedAt,
    required this.state,
    required this.strings,
    required this.showAddActions,
  });

  final DateTime openedAt;
  final InvoiceEditorState state;
  final AppStrings strings;
  final bool showAddActions;

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
        if (showAddActions) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          InvoiceAddLineActions(
            strings: strings,
            onAddFromCatalogue: () =>
                addInvoiceLineFromCatalogue(context, ref, openedAt),
            onAddCustom: () => addCustomInvoiceLine(context, ref, openedAt),
          ),
        ],
        if (state.hasWarnings) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          _Warnings(state: state, strings: strings),
        ],
      ],
    );
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
}

/// Picks a catalogue entry, then opens the line editor for its quantity.
///
/// **Top-level, because two placements call it** (D-096): the buttons at the
/// foot of [InvoiceLinesSection] on the wider tiers, and the pinned header on
/// the phone. One function rather than two closures, so the two entry points
/// cannot come to add a line differently.
///
/// Two steps rather than one, and since D-097 the second step asks one
/// question: how many. Title, unit and price are the catalogue's, copied in as
/// a snapshot (D-004) and not offered for editing here — a price typed over the
/// product's own is a figure that matches no record anybody can look up.
Future<void> addInvoiceLineFromCatalogue(
  BuildContext context,
  WidgetRef ref,
  DateTime openedAt,
) async {
  final Product? product = await showProductPickerSheet(context);
  if (product == null || !context.mounted) return;

  final InvoiceLineEntry? line = await showInvoiceLineEditorSheet(
    context,
    product: product,
    resolvedTaxRateBp: _inheritedRateBp(ref, openedAt),
  );
  if (line == null) return;
  ref.read(invoiceEditorProvider(openedAt).notifier).addLine(line);
}

/// Opens the line editor with nothing filled in: the free line.
///
/// **The one route that still collects everything**, and it has to. There is no
/// product record behind a free line, so a title and a price typed here are not
/// duplicating anything — they are the only statement of what is being billed.
/// For a workshop billing one-off jobs this is the ordinary case, not a
/// fallback (D-097).
Future<void> addCustomInvoiceLine(
  BuildContext context,
  WidgetRef ref,
  DateTime openedAt,
) async {
  final InvoiceLineEntry? line = await showInvoiceLineEditorSheet(
    context,
    resolvedTaxRateBp: _inheritedRateBp(ref, openedAt),
  );
  if (line == null) return;
  ref.read(invoiceEditorProvider(openedAt).notifier).addLine(line);
}

/// What a **new** line would inherit.
///
/// Taken from an existing calculated line where there is one, because that is
/// the engine's own answer for this invoice under these settings. With no lines
/// yet there is nothing calculated to read, and this may not resolve the chain
/// itself — so it says nothing rather than guessing, and the sheet omits the
/// note.
int? _inheritedRateBp(WidgetRef ref, DateTime openedAt) {
  final InvoiceEditorState? state = ref
      .read(invoiceEditorProvider(openedAt))
      .value;
  final List<CalculatedLine> lines =
      state?.totals.lines ?? const <CalculatedLine>[];
  return lines.isEmpty ? null : lines.first.resolvedTaxRateBp;
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
              AmountText(calculated.total, size: AmountSize.small),
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
    // **The two money columns are fixed-width and leading-aligned**, like every
    // other money column in the application (D-037). (b) gave them `flex: 2`
    // and `alignEnd: true`, which was a deviation on both counts and went
    // unnoticed while this table had a whole page to itself. Composing it into
    // the screen in (d) narrowed the column and the amounts overflowed their
    // cells by 58 logical pixels — an invoice line total clipped, which is the
    // one thing a table of money may never do. A flexed money column is a
    // column whose width depends on the window, so the amount that fits today
    // clips at another size; `alignEnd` in RTL puts the figure against the
    // wrong edge and breaks the vertical alignment of a column of them.
    final List<TableColumnSpec> columns = <TableColumnSpec>[
      TableColumnSpec.flexible(
        label: strings.invoiceLineColumnDescription,
        flex: 3,
        minWidth: AppLayout.tableMinTextWidth,
      ),
      TableColumnSpec.flexible(
        label: strings.invoiceLineColumnQuantity,
        flex: 2,
        minWidth: AppLayout.tableMinValueWidth,
      ),
      TableColumnSpec.fixed(
        label: strings.invoiceLineColumnUnitPrice,
        width: AppLayout.tablePriceWidth,
      ),
      TableColumnSpec.fixed(
        label: strings.invoiceLineColumnTotal,
        width: AppLayout.tablePriceWidth,
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
              AmountText(state.lines[index].unitPrice, size: AmountSize.small),
              AmountText(
                state.totals.lines[index].total,
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

/// The two ways to add a line.
///
/// **Public, because the phone pins it above the scroll** (D-096) while the
/// wider tiers keep it at the foot of [InvoiceLinesSection]. One widget either
/// way, so the two placements cannot drift apart.
class InvoiceAddLineActions extends StatelessWidget {
  const InvoiceAddLineActions({
    required this.strings,
    required this.onAddFromCatalogue,
    required this.onAddCustom,
    super.key,
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
