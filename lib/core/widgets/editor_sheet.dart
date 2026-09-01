import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';

/// The frame every editing bottom sheet sits in: a title, the fields, and a
/// primary action that does not scroll.
///
/// **This is [FormScaffold]'s rule, applied to sheets, and it exists because
/// stating a rule in one file does not make it a rule.** `FormScaffold` has
/// said since Phase 2 that a save button below seven fields is one the user has
/// to go looking for, and that with the keyboard up it is off screen entirely.
/// The invoice line sheet independently arrived at the same shape. The payment
/// sheet in Phase 5 (c) did not — it put everything, the button included, in one
/// `SingleChildScrollView` — and on the Redmi the soft keyboard took **254.9 of
/// 803.6** logical pixels, leaving «ذخیره» about **70 pixels below the fold** the
/// moment the sheet opened (known issue 21, D-062). Nothing on the desktop tier
/// and nothing in a widget test has a keyboard, so nothing caught it.
///
/// So the shape is a primitive rather than a habit. A sheet built through this
/// class cannot put its commit action inside the scroll view, because it does
/// not get to say where the action goes.
///
/// **The reasoning is D-053's, unchanged:** the thing being agreed to must not
/// scroll away from the person agreeing to it. There it split the invoice
/// summary — the breakdown scrolls with the fields it explains, the grand total
/// and its actions stay pinned. Here it splits the sheet the same way.
///
/// **The height is a cap, not a fixed fraction.** A sheet of three fields
/// should hug its content on a desktop window rather than stand 90% tall with a
/// gap above the button; a sheet of ten should stop growing and scroll. So the
/// column is `mainAxisSize: min` under a [BoxConstraints.maxHeight], and the
/// fields are the part that gives.
///
/// **`viewInsets` padding goes inside the cap**, so the keyboard eats the
/// fields' room rather than the action's: the action lands exactly on top of the
/// keyboard instead of behind it.
///
/// Not used by the **picker** sheets, and deliberately. A picker commits by
/// tapping a row, so its list *is* its action — there is no second control to
/// pin, and its search field is already outside the scrolling region. Forcing
/// this frame onto them would add a button that duplicates the list.
class EditorSheet extends StatelessWidget {
  const EditorSheet({
    required this.title,
    required this.closeTooltip,
    required this.children,
    required this.action,
    this.formKey,
    this.heightFactor = 0.9,
    super.key,
  });

  final String title;

  /// Persian, from the localization layer, because a tooltip is user-facing
  /// text like any other (§1). Passed in rather than taken from
  /// `MaterialLocalizations` so the sheets keep saying what they already said.
  final String closeTooltip;

  /// The fields. Laid out by this class into the scrolling region, so a caller
  /// cannot accidentally put the commit action among them.
  final List<Widget> children;

  /// The primary action, pinned beneath the fields and above the keyboard.
  final Widget action;

  /// Supplied by the caller because validation has to reach the fields, and the
  /// `Form` therefore has to sit above the list this class builds.
  final GlobalKey<FormState>? formKey;

  /// The **maximum** share of the screen the sheet may take before its fields
  /// start scrolling.
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Widget list = ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: children,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * heightFactor,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: closeTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Loose rather than tight: the fields take what they need up to the
            // cap, and only then start scrolling.
            Flexible(
              child: formKey == null ? list : Form(key: formKey, child: list),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: action,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
