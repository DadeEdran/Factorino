import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';

/// The surface everything sits on.
///
/// A border and a surface step, never a shadow (§10). The reason is dark mode:
/// a shadow-based hierarchy is nearly invisible on a dark surface, so a design
/// that leans on elevation looks correct in light mode and flat in dark. A
/// border works identically in both.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.background,
    this.border,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// A surface other than the default.
  ///
  /// **For meaning, never for decoration.** The only thing that sets it is a
  /// semantic status colour from [StatusPalette] on a block that reports what
  /// the status *is* -- what has been paid, and what is still owed (D-093). A
  /// card tinted because it looked nice would take the one signal colour
  /// carries in this application and spend it on emphasis, which
  /// `app_colors.dart` is explicit about not doing.
  ///
  /// The `container` half of a [StatusColors] pair is designed to sit under
  /// ordinary body text, so nothing inside has to be restyled to stay legible.
  final Color? background;

  /// Overrides the hairline outline, so a tinted card's edge belongs to its
  /// own colour rather than being a grey line around a coloured field.
  final Color? border;

  /// When set, the card becomes a target with the platform's own press
  /// feedback, clipped to the card's radius.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: background ?? scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: border ?? scheme.outlineVariant,
              width: AppBorders.hairline,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A page-level section heading with optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          ?trailing,
        ],
      ),
    );
  }
}
