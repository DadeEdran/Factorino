import 'package:flutter/material.dart';

import '../../../../core/formatting/jalali_display.dart';
import '../../../../core/formatting/number_display.dart';
import '../../../../core/localization/month_names.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../data/backup/backup_service.dart';

/// The confirmation before a restore overwrites everything.
///
/// Returns true if the user confirmed.
///
/// **The first sentence says that data is replaced and not merged**, and it is
/// first because it is the sentence that prevents the loss. D-069 records this
/// as a copy requirement carrying the weight of a data-loss guard: "restore"
/// implies *addition* to most people, so a user who expects a merge and
/// receives a replacement loses everything entered since the backup was taken
/// and has no reason to expect it.
///
/// **It describes the file rather than the app's promises.** The counts and the
/// date come from a [BackupSummary] that has already been read out of the
/// container — the backup was opened, its password accepted, its version
/// checked and its counts verified before this dialog appeared. So the numbers
/// on screen are the file's, not a hope about it, and a user who cannot
/// recognise them can still back out.
Future<bool> showBackupRestoreConfirmDialog(
  BuildContext context, {
  required BackupSummary summary,
}) async {
  final AppStrings strings = AppStrings.of(context);
  final ThemeData theme = Theme.of(context);

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(strings.backupImportConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            strings.backupImportConfirmReplaces,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            strings.backupImportConfirmLoses,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            strings.backupImportConfirmContents(
              formatGroupedPersian(summary.rowCounts['customers'] ?? 0),
              formatGroupedPersian(summary.rowCounts['invoices'] ?? 0),
              formatGroupedPersian(summary.rowCounts['payments'] ?? 0),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            strings.backupImportConfirmDate(
              formatJalaliDateLong(
                summary.createdAt,
                monthNames: jalaliMonthNames(strings),
              ),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.actionCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(strings.backupImportConfirmAction),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
