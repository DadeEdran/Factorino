import 'package:flutter/material.dart';

import '../localization/generated/app_strings.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

/// One stored field, read down a column: a quiet label with its value beneath.
///
/// **An empty field is shown as «ثبت نشده», not hidden**, and that is the whole
/// reason this is a component rather than two `Text`s at each call site. A
/// record that silently omits what is missing looks complete, and the user has
/// no way to tell "no company" from "we do not display companies" — which
/// matters most when the missing field is the one an invoice needs. Three
/// screens rendering that absence three ways is how a product ends up with a
/// blank in one panel, a dash in another and a placeholder in the third, none of
/// which a user can tell apart from a bug.
///
/// **Stacked rather than side by side, at every tier.** A Persian label and a
/// left-to-right identifier on one line put two directions in one row, and the
/// value's position then depends on the label's length; stacked, every value
/// starts at the same edge and a column of them can be scanned. It is also what
/// fits: these panels are narrow
/// (`AppLayout.detailPanelWidth`), and a Persian label beside an address on one
/// row is the shape that overflowed the settings screen by 132 pixels.
///
/// Shared by the customer detail screen, which shows a customer's record, and
/// the invoice detail screen, which shows the party a **document** states
/// (D-052). Those are different facts and the same shape, which is exactly what
/// a design-system component is for.
class RecordField extends StatelessWidget {
  const RecordField({
    required this.label,
    required this.value,
    required this.strings,
    this.isIdentifier = false,
    this.isLast = false,
    super.key,
  });

  /// Persian, from the localization layer.
  final String label;

  /// Null or empty renders as «ثبت نشده», never as blank space.
  final String? value;

  final AppStrings strings;

  /// Renders in the identifier style — tabular, and not the body face — so a
  /// کد ملی or a phone number is legible as a number rather than as prose.
  ///
  /// The caller passes the value already isolated, through
  /// `formatIdentifierForDisplay` or `formatMobileForDisplay`: the bidi rule
  /// belongs with the formatter that knows what kind of run it is (§9).
  final bool isIdentifier;

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool recorded = value != null && value!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: AppTypography.fontFamily,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          if (!recorded)
            Text(
              strings.fieldNotRecorded,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else if (isIdentifier)
            Text(
              value!,
              style: AppTypography.identifier.copyWith(
                color: theme.colorScheme.onSurface,
                fontFamily: AppTypography.fontFamily,
              ),
            )
          else
            Text(value!, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
