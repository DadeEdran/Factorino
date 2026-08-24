import 'package:flutter/material.dart';

import '../responsive/breakpoints.dart';
import '../theme/app_dimensions.dart';

/// The frame every destination's content sits in: a page title, then the body,
/// with the margins and the measure the tier calls for.
///
/// Two things it exists to hold in one place:
///
/// * **Page margins scale with the tier.** 16 on a phone, where every pixel of
///   width is content; 48 on a desktop, where a full-bleed layout looks like a
///   web page from 2009.
/// * **The content column stops widening.** Past roughly 1240 px a line of text
///   is uncomfortable to track back from, and a table stretched across a 27-inch
///   monitor puts the amount so far from the customer name that the eye loses
///   the row. So the column centres instead of stretching — which is the
///   difference §10 draws between a desktop layout and a stretched mobile one.
class PageBody extends StatelessWidget {
  const PageBody({
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
    this.floatingAction,
    this.onBack,
    this.backTooltip,
    super.key,
  });

  final String title;
  final Widget child;

  /// Shown as a leading arrow before the title, for a page reached *into*
  /// rather than switched to.
  ///
  /// A destination does not get one — the navigation shell is how those are
  /// reached. A detail page does: it was opened by tapping a row, and the only
  /// other way back would be to tap the destination in the rail again, which is
  /// not an affordance anybody looks for.
  final VoidCallback? onBack;

  /// Persian, from the localization layer, because a tooltip is user-facing
  /// text like any other (§1).
  final String? backTooltip;

  /// Page-level actions, shown beside the title. Used on tiers with the width
  /// for them; mobile puts its primary action in [floatingAction] instead.
  final List<Widget> actions;

  /// The primary action on mobile, floated over the content.
  ///
  /// It lives here rather than on the shell's `Scaffold` because it belongs to
  /// the destination, not to the application: the dashboard has none, and a
  /// button that changed meaning as the user switched tabs would be worse than
  /// no button. Floating over the list rather than sitting above it keeps it
  /// thumb-reachable on a phone, which is the whole reason mobile uses one.
  final Widget? floatingAction;

  @override
  Widget build(BuildContext context) {
    final LayoutTier tier = context.tier;
    final ThemeData theme = Theme.of(context);

    final double horizontal = switch (tier) {
      LayoutTier.mobile => AppSpacing.lg,
      LayoutTier.tablet => AppSpacing.xl,
      LayoutTier.desktop => AppSpacing.xxxl,
    };

    final Widget content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            tier.isMobile ? AppSpacing.lg : AppSpacing.xl,
            horizontal,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (onBack != null) ...<Widget>[
                    IconButton(
                      onPressed: onBack,
                      tooltip: backTooltip,
                      // `Icons.arrow_back` carries `matchTextDirection: true`,
                      // so it points right in this RTL app without any
                      // mirroring here. A directional navigation icon is
                      // exactly the kind §9 says *should* mirror -- unlike the
                      // object icons in the navigation rail, which must not.
                      icon: const Icon(Icons.arrow_back, size: AppIconSize.lg),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                  ...actions,
                ],
              ),
              SizedBox(height: tier.isMobile ? AppSpacing.lg : AppSpacing.xl),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );

    if (floatingAction == null) return content;

    return Stack(
      children: <Widget>[
        content,
        PositionedDirectional(
          end: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: floatingAction!,
        ),
      ],
    );
  }
}
