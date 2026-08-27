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
              const _RowDivider(),
              _SettingRow(
                label: strings.settingsPaymentTerm,
                value: formatGroupedPersian(settings.paymentTermDays),
                hint: strings.settingsPaymentTermHint,
                trailingLabel: strings.unitDays,
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

    // A `Wrap`, not a `Row`, and for a measured reason. The value is rendered
    // in the prominent figure style, and one of these rows carries a
    // *sentence* there rather than a figure -- «هنوز پشتیبان تهیه نشده است»,
    // when no backup has been taken. In a `Row` that group is the
    // non-flexible child, so it takes its natural width first and the label
    // beside it is squeezed to nothing: measured at 132 logical pixels of
    // horizontal overflow at phone width, which is a row of content the user
    // cannot see.
    //
    // The wrap costs nothing while both halves fit -- `spaceBetween` places
    // them exactly where the row did -- and drops the value onto its own line
    // when they do not. The label is bounded to the available width so that it
    // wraps rather than becoming the overflowing child in turn.
    //
    // Found by `settings_screen_test.dart`, which is the first test this
    // screen has had; the defect predates the payment-term row.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Flexible(
                      child: Text(value, style: theme.textTheme.displaySmall),
                    ),
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
              ),
            ],
          );
        },
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
