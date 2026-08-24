import 'package:flutter/material.dart';

import '../responsive/breakpoints.dart';
import '../theme/app_dimensions.dart';
import 'skeleton.dart';

/// The frame every form sits in: a title, the fields, and a fixed action bar.
///
/// Two decisions worth stating, because both are the opposite of the easy one:
///
/// **The actions do not scroll.** A save button that sits below seven fields is
/// a save button the user has to go looking for, and on a phone with the
/// keyboard up it is off screen entirely. Pinning it to the bottom means the
/// primary action is always where it was last time.
///
/// **The column is capped at a form measure, not a page measure.** A text field
/// stretched across a desktop window is harder to fill in than a narrow one:
/// the label is a screen away from the value, and the eye loses the row.
/// [AppLayout.maxFormWidth] is the reading width of a single column.
class FormScaffold extends StatelessWidget {
  const FormScaffold({
    required this.title,
    required this.child,
    required this.saveLabel,
    required this.cancelLabel,
    required this.onCancel,
    required this.onSave,
    super.key,
  });

  final String title;
  final Widget child;

  final String saveLabel;
  final String cancelLabel;

  final VoidCallback onCancel;

  /// Null disables the button — which is how a save in flight is shown, so a
  /// double tap cannot produce two customers.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LayoutTier tier = context.tier;

    final double horizontal = switch (tier) {
      LayoutTier.mobile => AppSpacing.lg,
      LayoutTier.tablet => AppSpacing.xl,
      LayoutTier.desktop => AppSpacing.xxxl,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxFormWidth),
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
              Text(title, style: theme.textTheme.titleLarge),
              SizedBox(height: tier.isMobile ? AppSpacing.lg : AppSpacing.xl),
              Expanded(child: child),
              const _ActionBarDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(onPressed: onCancel, child: Text(cancelLabel)),
                    const SizedBox(width: AppSpacing.md),
                    FilledButton(onPressed: onSave, child: Text(saveLabel)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBarDivider extends StatelessWidget {
  const _ActionBarDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: AppBorders.hairline,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

/// The form's own skeleton, for the moment an edit form is fetching its row.
///
/// Shaped like the fields it replaces, for the same reason a list skeleton is
/// shaped like its rows: the page must not jump when the values arrive.
class FormLoadingScaffold extends StatelessWidget {
  const FormLoadingScaffold({this.fieldCount = 5, super.key});

  final int fieldCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Skeleton(
            width: AppSkeleton.titleWidth,
            height: AppSkeleton.titleHeight,
          ),
          const SizedBox(height: AppSpacing.xl),
          for (int i = 0; i < fieldCount; i++) ...<Widget>[
            const Skeleton(
              height: AppSkeleton.fieldHeight,
              radius: AppRadius.md,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}
