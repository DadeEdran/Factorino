import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'skeleton.dart';

/// One headline figure: a quiet label, the figure itself, and a caption
/// saying what population the figure covers.
///
/// Shared rather than owned by the dashboard, because the customer detail
/// screen asks the same question of one customer that the dashboard asks of
/// the business, and two tiles that looked slightly different would suggest
/// they meant slightly different things.
///
/// **The caption is not decoration.** A number the user
/// cannot reconcile against anything is a number they learn to distrust —
/// "sales" over which month, "outstanding" across which invoices. Each tile
/// here names its own scope, which is the whole difference between a figure and
/// a reassurance.
///
/// **No colour.** The figures are money and counts, and colour in this design
/// means status (D-033). A green sales figure and a red balance would be a
/// judgement the app is not entitled to make: an outstanding balance is not bad
/// news, it is money on its way.
///
/// The [value] is a widget rather than a string so an amount can arrive as
/// `AmountText` — carrying its unit label and Persian digits — while a count
/// arrives as plain text.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.caption,
    super.key,
  });

  /// Persian, from the localization layer.
  final String label;

  final Widget value;

  /// What the figure covers — the Jalali month, or which invoices.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: AppTypography.fontFamily,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Scaled down only if it would not otherwise fit. A tile is a fixed
          // share of the row while the figure inside it is not -- an invoice
          // total has no upper bound the layout can be designed around -- and
          // a clipped or overflowing amount is the one failure mode a money
          // figure must not have. In every ordinary case nothing is scaled and
          // the type scale is exactly as designed.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: value,
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

/// Tiles laid out [columns] to a row.
///
/// Explicit rows rather than a `GridView`: the tiles have unequal natural
/// height, and a grid would force them all to the tallest cell's aspect ratio —
/// which on a phone means tiles of whitespace to accommodate the one with a
/// two-line caption.
class TileGrid extends StatelessWidget {
  const TileGrid({required this.tiles, required this.columns, super.key});

  final List<Widget> tiles;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];

    for (int start = 0; start < tiles.length; start += columns) {
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: AppSpacing.lg));
      }
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int column = 0; column < columns; column++) ...<Widget>[
                if (column > 0) const SizedBox(width: AppSpacing.lg),
                Expanded(
                  // The last row of an uneven grid keeps its empty cells, so a
                  // lone tile stays the width of its neighbours instead of
                  // stretching across the page and reading as more important.
                  child: start + column < tiles.length
                      ? tiles[start + column]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// A tile-shaped placeholder, so the grid does not reflow when the figures
/// land.
class StatTileSkeleton extends StatelessWidget {
  const StatTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Skeleton(
            width: AppSkeleton.captionWidth,
            height: AppSkeleton.lineHeight,
          ),
          SizedBox(height: AppSpacing.sm),
          Skeleton(
            width: AppSkeleton.titleWidth,
            height: AppSkeleton.titleHeight,
          ),
          SizedBox(height: AppSpacing.xs),
          Skeleton(
            width: AppSkeleton.captionWidth,
            height: AppSkeleton.lineHeight,
          ),
        ],
      ),
    );
  }
}
