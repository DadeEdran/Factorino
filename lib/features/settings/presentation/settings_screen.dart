import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/number_display.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../data/models/app_settings.dart';
import '../application/settings_providers.dart';

/// The settings screen.
///
/// **Read-only in this increment, and reading real values.** The settings row
/// is seeded when the database is created, so these are the figures the invoice
/// engine is actually using — not placeholders. Editing controls land with the
/// settings feature work; showing the true configuration in the meantime is
/// honest, whereas a form that looked editable and discarded input would not
/// be (§15).
///
/// It is also the one screen in this increment with real content, which makes
/// it the place the type scale and the card treatment can be judged against
/// something other than an empty state.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);

    return PageBody(
      title: strings.settingsTitle,
      child: settings.when(
        // Errors never surface raw (§7): a friendly Persian message, and the
        // exception goes to the log wrapper, not to the user.
        error: (Object error, StackTrace stack) => EmptyState(
          icon: Icons.error_outline,
          title: strings.errorGenericTitle,
          body: strings.errorGenericBody,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        data: (AppSettings value) =>
            _SettingsContent(settings: value, strings: strings),
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({required this.settings, required this.strings});

  final AppSettings settings;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        SectionHeader(title: strings.settingsInvoicingSection),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              _SettingRow(
                label: strings.settingsDefaultTaxRate,
                value: formatPercentFromBasisPoints(settings.defaultTaxRateBp),
                hint: strings.settingsDefaultTaxRateHint,
              ),
              const _RowDivider(),
              _SettingRow(
                label: strings.settingsInvoicePrefix,
                value: settings.invoiceNumberPrefix,
              ),
              const _RowDivider(),
              _SettingRow(
                label: strings.settingsRoundingUnit,
                value: settings.roundingUnitRial == 0
                    ? formatGroupedPersian(0)
                    : formatGroupedPersian(settings.roundingUnitRial),
                trailingLabel: strings.unitRial,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: strings.settingsBackupSection),
        AppCard(
          padding: EdgeInsets.zero,
          child: _SettingRow(
            label: strings.settingsLastBackup,
            value: settings.lastBackupAt == null
                ? strings.settingsLastBackupNever
                : formatGroupedPersian(
                    settings.lastBackupAt!.millisecondsSinceEpoch,
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

/// One label/value pair.
///
/// The value is the emphasised half — it is what the user came to read — and
/// the optional hint sits beneath in the muted caption style, so an explanation
/// never competes with the setting it explains.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    this.hint,
    this.trailingLabel,
  });

  final String label;
  final String value;
  final String? hint;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: theme.textTheme.bodyLarge),
                if (hint != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    hint!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(value, style: theme.textTheme.displaySmall),
              if (trailingLabel != null) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  trailingLabel!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Divider(
        height: AppBorders.hairline,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}
