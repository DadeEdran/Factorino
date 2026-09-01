import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/editor_sheet.dart';
import '../../../../data/models/field_limits.dart';

/// Asks for the password that keys a backup file.
///
/// Returns the password, or null if dismissed. **It only collects the value** —
/// the write is the controller's business, like every other sheet here.
///
/// **[confirming] is the difference between the two flows.** Taking a backup
/// asks twice, because a mistyped password produces a file that cannot ever be
/// opened and nothing would reveal it until the day it mattered. Restoring asks
/// once: the password either opens the file or it does not, and the answer
/// comes back in a second.
///
/// **The warning is not softened, and it is shown before the fields rather than
/// under them.** the project spec requires the UI to state that losing the
/// password loses the backup; there is no recovery path and nobody who can
/// help, so the copy says exactly that. Placing it first means it is read as a
/// condition of the task rather than as small print under a button.
///
/// **The password is never normalized.** §9 makes digit normalization mandatory
/// for numeric input, and applying that reflex here would be a defect: it
/// shrinks the keyspace and ties the stored key to a formatting rule that could
/// later change — a user's own backup would then refuse the password they
/// typed. `backup_passphrase_characters_test.dart` pins ۱۲۳ and 123 as
/// different passwords.
Future<String?> showBackupPasswordSheet(
  BuildContext context, {
  required bool confirming,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) =>
        _BackupPasswordSheet(confirming: confirming),
  );
}

/// Short enough not to be a barrier, long enough that the warning above it is
/// not immediately undone by "1234".
const int kMinBackupPasswordLength = 8;

class _BackupPasswordSheet extends StatefulWidget {
  const _BackupPasswordSheet({required this.confirming});

  final bool confirming;

  @override
  State<_BackupPasswordSheet> createState() => _BackupPasswordSheetState();
}

class _BackupPasswordSheetState extends State<_BackupPasswordSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _repeat = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    // `.text` exactly as typed -- not trimmed. A trailing space is part of the
    // password, and trimming it here would key the file with something other
    // than what the user believes they chose.
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);

    return EditorSheet(
      title: widget.confirming
          ? strings.backupPasswordTitle
: strings.backupImportPasswordTitle,
      closeTooltip: strings.actionCancel,
      formKey: _formKey,
      action: FilledButton(onPressed: _submit, child: Text(strings.actionSave)),
      children: <Widget>[
        if (widget.confirming) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    strings.backupPasswordWarning,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        AppTextField(
          controller: _password,
          label: strings.backupPasswordField,
          maxLength: SettingsFieldLimits.password,
          obscureText: true,
          autofocus: true,
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return strings.backupPasswordEmpty;
            }
            if (widget.confirming && value.length < kMinBackupPasswordLength) {
              return strings.backupPasswordTooShort;
            }
            return null;
          },
        ),
        if (widget.confirming) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _repeat,
            label: strings.backupPasswordRepeatField,
            maxLength: SettingsFieldLimits.password,
            obscureText: true,
            validator: (String? value) {
              if (value != _password.text) {
                return strings.backupPasswordMismatch;
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}
