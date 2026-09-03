import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

/// The six states an invoice can be shown in.
///
/// A presentation concept, not the stored enum: `overdue` is **derived at
/// display time** from an unpaid invoice's due date and is never a stored
/// status (the project spec lists five stored statuses). Keeping it out of the
/// database is deliberate — a stored `overdue` would be wrong the moment the
/// clock passed midnight and nothing wrote to the row.
enum InvoiceStatusView {
  draft,
  unpaid,
  partiallyPaid,
  paid,
  cancelled,
  overdue,
}

/// The palette entry a status view resolves to.
///
/// Extracted from [StatusBadge] so a screen can carry a status's colour into
/// something that is not a badge -- the invoice detail screen tints the blocks
/// that report payment state with it (D-093) -- **without a second mapping**.
/// Two switch statements over six values is how a page comes to show an amber
/// badge over a green panel.
StatusColors statusColorsOf(InvoiceStatusView status, StatusPalette palette) =>
    switch (status) {
      InvoiceStatusView.draft => palette.draft,
      InvoiceStatusView.unpaid => palette.unpaid,
      InvoiceStatusView.partiallyPaid => palette.partiallyPaid,
      InvoiceStatusView.paid => palette.paid,
      InvoiceStatusView.cancelled => palette.cancelled,
      InvoiceStatusView.overdue => palette.overdue,
    };

/// A status badge: coloured text on its own quiet container.
///
/// Colour here **means** something (§10), which is why the badge is the only
/// coloured element in a list row. If amounts, names and badges were all
/// coloured, none of them would read as a signal.
///
/// The label is passed in rather than resolved here, so this widget holds no
/// string of its own (§1).
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, required this.label, super.key});

  final InvoiceStatusView status;

  /// The Persian label, from the localization layer.
  final String label;

  @override
  Widget build(BuildContext context) {
    final StatusPalette palette = Theme.of(context).extension<StatusPalette>()!;
    final StatusColors colors = statusColorsOf(status, palette);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: colors.foreground,
          fontFamily: AppTypography.fontFamily,
        ),
      ),
    );
  }
}
