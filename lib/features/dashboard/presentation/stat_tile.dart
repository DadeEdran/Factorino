import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/skeleton.dart';

/// One dashboard figure: a quiet label, the figure itself, and a caption
/// saying what population the figure covers.
///
/// **The caption is not decoration.** A number on a dashboard that the user
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
