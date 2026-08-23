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
    super.key,
  });

  final String title;
  final Widget child;

  /// Page-level actions, shown beside the title.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final LayoutTier tier = context.tier;
    final ThemeData theme = Theme.of(context);

    final double horizontal = switch (tier) {
      LayoutTier.mobile => AppSpacing.lg,
      LayoutTier.tablet => AppSpacing.xl,
      LayoutTier.desktop => AppSpacing.xxxl,
    };

    return Center(
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
  }
}
