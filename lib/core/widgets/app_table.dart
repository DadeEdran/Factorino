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
  const TableColumnSpec({
    required this.label,
    this.flex = 1,
    this.width,
    this.alignEnd = false,
  });

  /// The Persian heading, from the localization layer.
  final String label;

  /// Share of the remaining width. Ignored when [width] is set.
  final int flex;

  /// A fixed width, for a column whose content has a known size — a status
  /// badge, a date.
  final double? width;

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
