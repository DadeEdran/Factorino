import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';

/// A placeholder block, shaped like the content that will replace it.
///
/// the project spec: *"Prefer skeleton loaders over full-screen spinners."* The
/// reason is not decoration. A spinner says "something is happening"; a
/// skeleton says "a list of rows is coming, and here is how many and how wide"
/// — so the page does not jump when the data lands, and the user starts
/// reading the layout before there is anything in it.
///
/// **Reduced motion is respected** (§10). When the platform asks for it, the
/// block is drawn flat rather than pulsing. This is not a nicety: a pulsing
/// rectangle is exactly the kind of repeating animation the setting exists to
/// suppress, and Flutter does not suppress a hand-rolled controller for us.
class Skeleton extends StatefulWidget {
  const Skeleton({
    required this.height,
    this.width,
    this.radius = AppRadius.sm,
    super.key,
  });

  /// Null fills the available width — for a text line whose real length is not
  /// known until the data arrives.
  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: AppDuration.pulse,
    vsync: this,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Read here rather than in initState: the setting can change while the app
    // is running, and a controller left repeating after the user turned motion
    // off is the bug this whole branch exists to avoid.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = _restingOpacity;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  /// Where the pulse sits when it is not moving: the midpoint, so a static
  /// skeleton reads the same weight as an animated one averaged over time.
  static const double _restingOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return FadeTransition(
      // A narrow opacity range. A skeleton that fades close to invisible reads
      // as a rendering fault; this one stays clearly present and merely
      // breathes.
      opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// A column of skeleton rows shaped like the list they stand in for.
///
/// [rowBuilder] draws one row, so each list supplies a skeleton with its own
/// proportions: a customer row and an invoice row do not look alike, and a
/// generic grey bar would make the layout jump when the real rows arrive.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    required this.rowBuilder,
    this.rowCount = 6,
    this.spacing = AppSpacing.md,
    this.shrinkWrap = false,
    super.key,
  });

  final WidgetBuilder rowBuilder;

  /// Enough rows to fill a phone screen without implying a count. Six is short
  /// enough that a list which turns out to be empty does not feel like a loss.
  final int rowCount;

  final double spacing;

  /// Whether to size to the rows rather than to the space offered.
  ///
  /// Needed wherever this sits **inside** another scrollable — a section part
  /// way down a page rather than the page's whole body. An unbounded viewport
  /// nested in an unbounded viewport is a layout error rather than a squeeze,
  /// so this is a correctness switch, not a preference.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // The skeleton is not interactive and scrolling it does nothing useful.
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: shrinkWrap,
      itemCount: rowCount,
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: spacing),
      itemBuilder: (BuildContext context, int index) => rowBuilder(context),
    );
  }
}
