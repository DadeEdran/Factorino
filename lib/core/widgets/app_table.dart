import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

/// One column of an [AppTableHeader] / [AppTableRow] pair.
///
/// The header and every row are laid out from the **same** list of specs, so a
/// column cannot drift out of alignment with its heading. That is the failure a
/// hand-built table always eventually has, and it looks like a data error
/// rather than a layout one.
@immutable
class TableColumnSpec {
  /// A column whose content has a known size — a status badge, a date, an
  /// amount. It always gets exactly [width].
  const TableColumnSpec.fixed({
    required this.label,
    required double this.width,
    this.alignEnd = false,
  }) : flex = 0,
       _minWidth = null;

  /// A column that takes a share of whatever the fixed columns leave.
  ///
  /// **[minWidth] is required, and that is the point of this constructor
  /// existing.** A flexible column is laid out by `Expanded`, which is a
  /// *tight* fit: it is handed the remaining width whether or not that width is
  /// enough, and if the fixed columns have taken everything then "nothing" is
  /// what it is handed — laid out successfully, with no overflow and no error.
  /// The invoice document's description column spent a whole phase at **21.6
  /// logical pixels**, rendering Persian one glyph per row, vertically, and
  /// nothing in 935 tests could see it (D-065).
  ///
  /// So a column cannot say it is flexible without saying how narrow is too
  /// narrow. What the table does when the width is not there is the caller's
  /// decision — drop a column, or stop being a table — but it can no longer be
  /// *nothing*, silently.
  const TableColumnSpec.flexible({
    required this.label,
    // `this._minWidth` on a *named* parameter is spelled `minWidth:` by the
    // caller — Dart strips the underscore for the parameter name. Written this
    // way so the field can stay private behind the [minWidth] getter, which is
    // what resolves a fixed column's minimum to its width.
    required double this._minWidth,
    this.flex = 1,
    this.alignEnd = false,
  }) : width = null;

  /// The Persian heading, from the localization layer.
  final String label;

  /// Share of the remaining width. Zero for a fixed column.
  final int flex;

  /// A fixed width, or null for a flexible column.
  final double? width;

  final double? _minWidth;

  /// The width below which this column must not be laid out. A fixed column's
  /// minimum is its width.
  double get minWidth => width ?? _minWidth!;

  /// Aligns the cell's content to the trailing edge — the *left* edge in this
  /// RTL app.
  ///
  /// **Not what an amount column wants**, which is the trap worth naming here.
  /// Numbers render left-to-right whatever the surrounding direction, so their
  /// units digit is at their right edge; pushing them to the trailing edge
  /// lines up their first digit instead and leaves the column ragged where it
  /// matters. Amounts use the default leading alignment. This flag is for
  /// content that genuinely belongs at the far edge and has a constant width.
  final bool alignEnd;
}

/// The width a table needs before any of its columns is crushed.
///
/// Includes the row's own horizontal padding, so a caller can compare it
/// directly against the width its `LayoutBuilder` reports.
double tableMinimumWidth(
  List<TableColumnSpec> columns, {
  double trailingWidth = 0,
}) {
  double total = AppSpacing.lg * 2 + trailingWidth;
  for (final TableColumnSpec column in columns) {
    // A flexible column's floor is content width; like every fixed money
    // column it also has to pay for the gap to its neighbour, which
    // `AppLayout.tablePriceWidth` accounts for by the same addition.
    total += column.width ?? (column.minWidth + AppSpacing.md);
  }
  return total;
}

/// The header row of a table.
///
/// Deliberately not `DataTable`. Material's table builds every row it is given,
/// so a list of five thousand invoices would build five thousand rows of
/// widgets to show twenty — which is exactly the O(n) UI-thread work §13
/// forbids, and it is invisible until the data grows. A header plus a
/// `ListView.builder` of [AppTableRow]s is a real table that is also
/// virtualized.
class AppTableHeader extends StatelessWidget {
  const AppTableHeader({required this.columns, this.trailingWidth, super.key});

  final List<TableColumnSpec> columns;

  /// Room reserved at the end of the row for per-row actions, matching the
  /// same value on [AppTableRow].
  final double? trailingWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // **The guard, once per table.** The header and its rows are laid out
        // from the same specs at the same width, so checking here checks all of
        // them for the cost of one `LayoutBuilder`.
        //
        // An assertion rather than a fallback, deliberately: only the caller
        // knows which of its columns are recoverable elsewhere, so the
        // primitive's job is to make the failure *loud* instead of silent. A
        // crushed column is not a layout that went slightly wrong — it is text
        // rendered one glyph per row, and it shipped because nothing raised.
        assert(() {
          final double needed = tableMinimumWidth(
            columns,
            trailingWidth: trailingWidth ?? 0,
          );
          if (constraints.maxWidth.isFinite && constraints.maxWidth < needed) {
            throw FlutterError(
              'A table was laid out at ${constraints.maxWidth.toStringAsFixed(1)} '
              'logical pixels; its columns need ${needed.toStringAsFixed(1)}. '
              'Its flexible columns will be handed what is left, which is '
              'nothing, and they will render successfully at no width. Give the '
              'table a narrower column set at this width, or a different '
              'layout -- do not widen the minimums to make this pass (D-065).',
            );
          }
          return true;
        }());
        return _header(theme);
      },
    );
  }

  Widget _header(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          for (final TableColumnSpec column in columns)
            _cell(
              column,
              Text(
                column.label,
                textAlign: column.alignEnd ? TextAlign.end : TextAlign.start,
                style: AppTypography.label.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
            ),
          if (trailingWidth != null) SizedBox(width: trailingWidth),
        ],
      ),
    );
  }
}

/// One row of a table, laid out from the same [columns] as its header.
class AppTableRow extends StatelessWidget {
  const AppTableRow({
    required this.columns,
    required this.cells,
    this.onTap,
    this.trailing,
    this.trailingWidth,
    super.key,
  });

  final List<TableColumnSpec> columns;

  /// One widget per column, in the same order.
  final List<Widget> cells;

  final VoidCallback? onTap;

  /// Per-row actions, in the space [trailingWidth] reserves.
  final Widget? trailing;
  final double? trailingWidth;

  @override
  Widget build(BuildContext context) {
    assert(
      cells.length == columns.length,
      'a row must have exactly one cell per column',
    );
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: AppBorders.hairline,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                for (int i = 0; i < columns.length; i++)
                  _cell(
                    columns[i],
                    Align(
                      alignment: columns[i].alignEnd
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: cells[i],
                    ),
                  ),
                if (trailingWidth != null)
                  SizedBox(
                    width: trailingWidth,
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: trailing,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Places one cell according to its spec. Shared by the header and the rows,
/// which is the whole point of the spec existing.
Widget _cell(TableColumnSpec column, Widget child) {
  final Widget padded = Padding(
    padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
    child: child,
  );
  return column.width != null
      ? SizedBox(width: column.width, child: padded)
      : Expanded(flex: column.flex, child: padded);
}
