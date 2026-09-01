import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';

/// The designed empty state every list gets: an icon, a
/// Persian explanation, and room around it.
///
/// An empty list with nothing in it reads as a broken screen. This one reads as
/// a screen that is working and has nothing to show yet — which is a different
/// message, and the one that is true.
///
/// The icon is drawn on its own quiet container rather than floating: a bare
/// outline glyph in the middle of a large empty area looks like a placeholder
/// somebody forgot to replace.
///
/// Both strings come from the localization layer; this widget holds none of its
/// own (§1).
///
/// **It scrolls rather than overflows when the space is short.** An empty state
/// is normally given a whole page and never comes close to its limit, so this
/// looked unnecessary until a sheet was asked for one with the soft keyboard up:
/// the customer picker's «مشتری‌ای پیدا نشد» had 238 logical pixels to work with
/// on a 400 x 800 phone and needed 262, and it overflowed by 24 — with a
/// yellow-and-black band across the exact moment a user is typing a search that
/// matches nothing (found by the keyboard sweep, D-062).
///
/// Clipping was the wrong fix: the thing that would be cut off is the sentence
/// explaining the state, and an empty state whose explanation is missing is the
/// blank screen this widget exists to prevent. So it scrolls, which costs
/// nothing on a page that has the room and keeps every word reachable on one
/// that does not.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  /// The call to action §10 asks for. Optional because a state can be empty
  /// with nothing useful to offer yet.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxFormWidth),
        // `shrinkWrap` by nature: the column is `MainAxisSize.min`, so on a
        // roomy page this measures exactly as it did before and does not
        // scroll. It only engages where the space is genuinely too small.
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: AppIconSize.xxl,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (action != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xl),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
