import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:io';

import '../../../core/errors/failure_message.dart';
import '../../../core/formatting/jalali_display.dart';
import '../../../core/formatting/number_display.dart';
import '../../../core/localization/month_names.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../data/backup/backup_file_gateway.dart';
import '../../../data/backup/backup_service.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/models/app_theme_mode.dart';
import '../../../data/models/seller_identity.dart';
import '../application/backup_controller.dart';
import '../application/settings_editor.dart';
import '../application/settings_providers.dart';
import 'widgets/backup_password_sheet.dart';
import 'widgets/backup_restore_confirm_dialog.dart';
import 'widgets/seller_editor_sheet.dart';
import 'widgets/settings_editor_sheet.dart';

/// The settings screen: the invoicing configuration, and backup.
///
/// **Editable since Phase 6 (d), and that is a defect fix rather than a
/// feature** (D-068). The project spec requires the VAT rate to be configurable
/// and never hardcoded; it was hardcoded at whatever the database happened to
/// be seeded with, and a business on a different rate met that on its first
/// invoice with no recourse. The work belonged to no phase in the plan, which
/// is exactly how the scope cut would have made it permanent.
///
/// **Changing the rate cannot alter an existing invoice**, because every item
/// snapshots the rate that applied to it (§4, D-026). That property is what
/// makes this screen safe to open at all, and the field says so in Persian.
///
/// **Backup lives here too**, per §8: export, restore, and the date of the last
/// one — an offline-only financial application whose user has never taken a
/// backup is one lost phone away from losing the business.
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

class _SettingsContent extends ConsumerStatefulWidget {
  const _SettingsContent({required this.settings, required this.strings});

  final AppSettings settings;
  final AppStrings strings;

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  /// True while an export or a restore is running.
  ///
  /// Both actions are disabled together, because they touch the same database:
  /// a restore begun while an export is half-written would be reading a file
  /// nobody has finished producing.
  bool _busy = false;

  AppSettings get settings => widget.settings;
  AppStrings get strings => widget.strings;

  Future<void> _edit() async {
    final AppSettings? edited = await showSettingsEditorSheet(
      context,
      settings: settings,
    );
    if (edited == null || !mounted) return;

    final bool saved = await ref
.read(settingsEditorProvider.notifier)
.save(edited);
    if (!mounted) return;
    _say(saved ? strings.settingsSaved : strings.errorGenericBody);
  }

  /// Edits the seller — the business the invoice is issued by (D-077).
  ///
  /// Separate from [_edit] because the two sheets edit different things and
  /// each section offers its own control; the write goes through the same
  /// controller, because there is one settings row and one place that writes
  /// it.
  Future<void> _editSeller() async {
    // **The same function the dashboard prompt calls** (D-102). Two entry
    // points, one write path, so they cannot come to save a seller differently.
    final bool? saved = await editSellerIdentity(context, ref, settings);
    if (saved == null || !mounted) return;
    _say(saved ? strings.settingsSellerSaved : strings.errorGenericBody);
  }

  /// Writes the light/dark choice (D-087).
  ///
  /// **No confirmation message on success**, unlike every other write on this
  /// screen. The others change a number the user cannot see the effect of; this
  /// one repaints the application under their finger, which is a more
  /// convincing report than a sentence about it. A failure still speaks, because
  /// then nothing visible happened at all.
  Future<void> _setThemeMode(AppThemeMode mode) async {
    if (mode == settings.themeMode) return;

    final bool saved = await ref
.read(settingsEditorProvider.notifier)
.save(settings.copyWith(themeMode: mode));
    if (!mounted || saved) return;
    _say(strings.errorGenericBody);
  }

  Future<void> _export() async {
    final String? password = await showBackupPasswordSheet(
      context,
      confirming: true,
    );
    if (password == null || !mounted) return;

    setState(() => _busy = true);
    _say(strings.backupExportInProgress);
    final BackupOutcome outcome = await ref
.read(backupControllerProvider.notifier)
.export(passphrase: password, suggestedName: _suggestedName());
    if (!mounted) return;
    setState(() => _busy = false);

    switch (outcome) {
      case BackupSucceeded():
        _say(strings.backupExportDone);
      // Backing out of a save dialog is an ordinary thing to do, and saying
      // nothing is the right amount to say about it.
      case BackupCancelled():
        break;
      case BackupFailed(error: final Object error):
        _sayFailure(error);
    }
  }

  Future<void> _restore() async {
    final File? file = await ref
.read(backupControllerProvider.notifier)
.pickFile();
    if (file == null || !mounted) return;

    final String? password = await showBackupPasswordSheet(
      context,
      confirming: false,
    );
    if (password == null || !mounted) return;

    setState(() => _busy = true);
    // Read the file BEFORE asking for confirmation, so the dialog describes a
    // backup already proved readable rather than one hoped to be. Every
    // refusal a restore can raise happens here, with live data untouched.
    final BackupOutcome inspected = await ref
.read(backupControllerProvider.notifier)
.inspect(file: file, passphrase: password);
    if (!mounted) return;
    setState(() => _busy = false);

    if (inspected case BackupFailed(error: final Object error)) {
      _sayFailure(error);
      return;
    }

    final BackupSummary summary = (inspected as BackupSucceeded).summary;
    final bool confirmed = await showBackupRestoreConfirmDialog(
      context,
      summary: summary,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    _say(strings.backupImportInProgress);
    final BackupOutcome restored = await ref
.read(backupControllerProvider.notifier)
.restore(file: file, passphrase: password);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (restored) {
      case BackupSucceeded():
        _say(strings.backupImportDone);
      case BackupCancelled():
        break;
      case BackupFailed(error: final Object error):
        _sayFailure(error);
    }
  }

  /// `factorino-1405-06-10.factorino`.
  ///
  /// Jalali, because the user's calendar is Jalali: a filename they cannot date
  /// at a glance is one they cannot choose between six months from now.
  String _suggestedName() =>
      'factorino-${formatJalaliDateForFileName(DateTime.now())}'
      '.$kBackupFileExtension';

  void _say(String message) {
    ScaffoldMessenger.of(context)
.showSnackBar(SnackBar(content: Text(message)));
  }

  void _sayFailure(Object error) {
    // The only way an error reaches the screen (§7): never a stack trace, a
    // file path or a raw exception string.
    final FailureMessage message = describeFailure(error, strings);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${message.title} — ${message.body}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SellerIdentity seller = settings.seller;

    return ListView(
      children: <Widget>[
        // **First on the screen, and deliberately** (D-077). Every database in
        // existence reaches v5 with this section empty, because there was
        // nothing to migrate from and nothing honest to invent — so this is
        // the one section of this screen every existing user has something to
        // do in, and the printed invoice is missing half its identity until
        // they do it.
        SectionHeader(
          title: strings.settingsSellerSection,
          trailing: IconButton(
            onPressed: _busy ? null : _editSeller,
            icon: const Icon(Icons.edit_outlined),
            tooltip: strings.settingsSellerEditTooltip,
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              _SettingRow(
                label: strings.settingsSellerFieldName,
                value: seller.name ?? strings.settingsSellerEmpty,
                // **The sentence that makes an empty seller impossible to be
                // surprised by.** An empty seller blocks nothing — not
                // issuing, not printing; it is the user's document and their
                // call — so the whole of the obligation is that they were
                // told, in the place they can act on it, before they print.
                // Hung off the name row rather than the section because the
                // name is what gates the block: fill it and the sentence goes
                // away, which is the feedback that makes it a prompt rather
                // than a standing notice.
                hint: seller.isPrintable
                    ? null
: strings.settingsSellerConsequence,
              ),
              const _RowDivider(),
              _SettingRow(
                label: strings.settingsSellerFieldEconomicId,
                value: seller.economicId ?? strings.settingsSellerEmpty,
              ),
              const _RowDivider(),
              _SettingRow(
                label: strings.settingsSellerFieldPhone,
                value: seller.phone ?? strings.settingsSellerEmpty,
              ),
              const _RowDivider(),
              _SettingRow(
                label: strings.settingsSellerFieldAddress,
                value: seller.address ?? strings.settingsSellerEmpty,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: strings.settingsInvoicingSection,
          // In the header rather than as a row in the card, and rather than a
          // floating action: the card's height is already the data's, and
          // the project spec is explicit that a control which must be reachable
          // without scrolling belongs where it costs no height at all.
          trailing: IconButton(
            onPressed: _busy ? null : _edit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: strings.settingsEditTooltip,
          ),
        ),
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
        SectionHeader(title: strings.settingsAppearanceSection),
        AppCard(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.settingsThemeMode,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  strings.settingsThemeModeHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // **A segmented control, not a switch**, because there are
                // three states and only two of them are a choice between light
                // and dark. A switch would have to represent "follow the
                // device" as one of its two positions, which is how a user
                // ends up unable to say what the application is currently
                // doing. See D-087.
                //
                // Full width so the three Persian labels get equal room; the
                // longest is «سیستم» and none of them wrap.
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AppThemeMode>(
                    segments: <ButtonSegment<AppThemeMode>>[
                      ButtonSegment<AppThemeMode>(
                        value: AppThemeMode.system,
                        label: Text(strings.settingsThemeModeSystem),
                        icon: const Icon(Icons.brightness_auto_outlined),
                      ),
                      ButtonSegment<AppThemeMode>(
                        value: AppThemeMode.light,
                        label: Text(strings.settingsThemeModeLight),
                        icon: const Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment<AppThemeMode>(
                        value: AppThemeMode.dark,
                        label: Text(strings.settingsThemeModeDark),
                        icon: const Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: <AppThemeMode>{settings.themeMode},
                    showSelectedIcon: false,
                    onSelectionChanged: _busy
                        ? null
: (Set<AppThemeMode> selection) =>
                              _setThemeMode(selection.first),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: strings.settingsBackupSection),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              _SettingRow(
                label: strings.settingsLastBackup,
                // Known issue 6's first half, closed. This row would have
                // rendered an epoch number -- 1,756,000,000,000 in Persian
                // digits -- the moment `lastBackupAt` stopped being null,
                // which until this increment it never did.
                value: settings.lastBackupAt == null
                    ? strings.settingsLastBackupNever
: formatJalaliDateLong(
                        settings.lastBackupAt!,
                        monthNames: jalaliMonthNames(strings),
                      ),
              ),
              const _RowDivider(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _export,
                        icon: const Icon(Icons.save_alt_outlined),
                        label: Text(strings.backupExportAction),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _restore,
                        icon: const Icon(Icons.settings_backup_restore),
                        label: Text(strings.backupImportAction),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
