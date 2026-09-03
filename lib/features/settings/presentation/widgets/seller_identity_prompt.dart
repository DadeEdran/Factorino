import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/app_settings.dart';
import '../../application/settings_providers.dart';
import 'seller_editor_sheet.dart';

/// Asks for the business name on the dashboard, while there is none (D-102).
///
/// ## Why it exists, and why on this screen
///
/// **An empty seller is the default state of every database.** D-077 backfills
/// nothing and invents nothing, deliberately — there is no honest value for a
/// business the application has never been told about. So *every* first-time
/// user has one, and until this the only place that said so was the settings
/// screen, which covers the user who goes looking and nobody else.
///
/// The result was the sequence D-101 records: a user saved their first PDF, met
/// an explanation instead of a document, and read a working save as a failure.
/// **The requirement was being discovered at the moment it was already too
/// late** — the one moment the user wanted a document rather than a form.
///
/// The dashboard is where it moves to, and the reasons are specific rather than
/// "somewhere earlier":
///
/// * it is the **first screen every user sees**, on the first launch and every
///   launch after;
/// * it costs **no step in any flow** — nothing is interrupted, nothing is
///   gated, and a user who is not ready simply scrolls past;
/// * it **disappears by being satisfied**, not by being dismissed. There is no
///   close button, and that is the design: a prompt that can be waved away is
///   one that gets waved away and then forgotten, which is how the application
///   would arrive back at exactly the state this exists to prevent.
///
/// ## It is a prompt, not a gate — D-077 stands
///
/// **An empty seller still blocks nothing.** Not issuing, not printing, not
/// saving. This widget has no power to refuse anything and does not try: it
/// states a consequence and offers the fix beside it. That was D-077's ruling
/// and this does not reopen it — the finding was that the ruling was right and
/// the *timing* was wrong.
///
/// ## Two considered placements, rejected
///
/// **An onboarding step.** This application has no first-run flow at all, and
/// building one to carry a single optional field is a larger change than the
/// problem justifies — and a wizard shown once is the easiest thing in an
/// application to click through without reading.
///
/// **The invoice form.** That is the screen four separate decisions have been
/// spent decluttering (D-054, D-086, D-093, D-096). A settings prompt on it
/// would undo part of that for a message with nothing to do with the invoice
/// being written.
///
/// ## Nothing while the answer is unknown
///
/// It renders nothing while the settings row is loading or has failed, rather
/// than assuming the seller is empty. A prompt that flashed on every cold start
/// before the read landed would be the application telling a user with a
/// perfectly good business name to enter one.
class SellerIdentityPrompt extends ConsumerWidget {
  const SellerIdentityPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings? settings = ref.watch(appSettingsProvider).value;
    if (settings == null || settings.seller.isPrintable) {
      return const SizedBox.shrink();
    }

    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(strings.sellerPromptTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              strings.sellerPromptBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonal(
                // The seller sheet itself, not a trip to the settings screen
                // and a second control there. The fix is one tap from the
                // sentence that asked for it.
                onPressed: () => _edit(context, ref, settings, strings),
                child: Text(strings.sellerPromptAction),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the sheet through the one shared write path, and reports.
  ///
  /// The prompt does not have to hide itself afterwards: `appSettingsProvider`
  /// is a live query, so a saved name rebuilds this widget into a
  /// `SizedBox.shrink`. It disappears because the thing it asked for happened,
  /// which is the whole design.
  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    AppStrings strings,
  ) async {
    final bool? saved = await editSellerIdentity(context, ref, settings);
    // Null is a dismissal, and saying nothing about it is the right amount to
    // say — the prompt is still there, which is report enough.
    if (saved == null || !context.mounted) return;

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          saved ? strings.settingsSellerSaved : strings.errorGenericBody,
        ),
      ),
    );
  }
}
