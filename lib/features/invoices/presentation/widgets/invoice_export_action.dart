import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/router/destinations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../data/backup/backup_file_gateway.dart';
import '../../../../data/models/invoice_detail.dart';
import '../../application/invoice_document_controller.dart';

/// Saving the invoice as a PDF: the control, and what happens afterwards.
///
/// ## A visible button, not a menu item (D-094)
///
/// It was a `PopupMenuItem` in the title row's overflow menu, put there in
/// Phase 7 (d) on the §10 rule that a control which must be reachable without
/// scrolling belongs where it costs no vertical space. The rule is right and
/// the conclusion was wrong: **the menu costs no space and no discoverability
/// either, because nobody opened it.** Testers handed the application did not
/// find how to produce a PDF at all, which is a complete failure of the one
/// feature Phase 7 exists for.
///
/// So it is a named button, in the document's own header row, where it costs
/// one line that is already there for the dates. Not in the title row beside
/// the status badge: at 328 logical pixels that row is already the subject of
/// known issue 26, and another 48-pixel control in it would take the invoice
/// number's remaining width and crush it.
///
/// **The menu item is gone rather than kept alongside.** Two ways to do one
/// thing is how a user comes to wonder whether they differ.
class InvoiceExportButton extends ConsumerWidget {
  const InvoiceExportButton({
    required this.detail,
    required this.strings,
    super.key,
  });

  final InvoiceDetail detail;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.tonalIcon(
      onPressed: () => exportInvoiceDocument(context, ref, detail, strings),
      icon: const Icon(Icons.picture_as_pdf_outlined, size: AppIconSize.md),
      label: Text(strings.invoiceDocumentExportAction),
    );
  }
}

/// Renders the document, hands it to the save dialog, and reports the result.
///
/// **The empty-seller notice fires here, and only here** — the other half of
/// D-077's obligation, the settings screen being the half for the user who goes
/// looking. Three properties it has to have, all of them rulings rather than
/// taste:
///
/// * **It never blocks.** Not a dialog, not a confirmation, not a reason to
///   refuse. D-077 ruled that an empty seller blocks nothing, and a modal
///   asking the user to approve their own document would be exactly the refusal
///   that ruling rejected.
/// * **It comes after the save, not before.** Before, it would be a
///   confirmation in everything but name. After, it reports what the file the
///   user now holds actually contains.
/// * **It says what happened and offers the fix.** A notice with no way to act
///   on it is a standing warning, and those get ignored.
///
/// It is silent on a cancelled export, because nothing was produced and there
/// is nothing to report about it.
///
/// ## It opens what was saved, and the message says so (D-091, D-100)
///
/// A save dialog on Android ends with the file somewhere in the user's own
/// storage and the application back in front of them, having said only that it
/// worked. Whether the page is *right* — the Persian shaped, the totals
/// readable — is a question they cannot answer without leaving and finding the
/// file by hand.
///
/// **So it opens straight away, with no second tap** (D-100). Saving is a
/// deliberate act aimed at a destination the user picked, and looking at what
/// was just produced is that same intent continuing rather than a new one. The
/// toast's «باز کردن» action remains for the case where the automatic attempt
/// found nothing to open with, so a device without a PDF viewer is told rather
/// than left in silence.
///
/// **The exception is the missing seller**, which keeps the behaviour D-077
/// specified: that message exists to be acted on and carries the «تنظیمات»
/// action that acts on it, and launching a viewer over it would bury the one
/// sentence worth reading. A document that does not name its issuer is one the
/// user should be fixing, not admiring.
///
/// ## Why there is no notification
///
/// A notification was considered for this and **rejected** (D-100). The save is
/// a foreground action the user just tapped and is watching; it completes in
/// well under a second. Notifications are for things that happen while nobody
/// is looking, and one for this would arrive over a screen already showing the
/// result. It would also cost `flutter_local_notifications`, a channel, an
/// icon, and the `POST_NOTIFICATIONS` runtime permission on Android 13+ —
/// a permission prompt, for a message the user can already see. The project spec
/// asks whether a dependency is needed and §7 warns against packages that
/// request permissions a feature does not need; this is both.

Future<void> exportInvoiceDocument(
  BuildContext context,
  WidgetRef ref,
  InvoiceDetail detail,
  AppStrings strings,
) async {
  final InvoiceDocumentController controller = ref.read(
    invoiceDocumentControllerProvider.notifier,
  );

  final InvoiceExportOutcome outcome = await controller.export(
    detail: detail,
    strings: strings,
  );

  if (!context.mounted) return;
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  // **Whatever is showing goes first** (D-101). An export leaves the
  // application twice — the save dialog, then the viewer — and a second export
  // started before the first message has aged out would queue behind it, so the
  // user would read the outcome of the export before last. A confirmation about
  // a superseded action is worse than none.
  messenger.hideCurrentSnackBar();

  switch (outcome) {
    case InvoiceExportCancelled():
      return;
    case InvoiceExportFailed():
      messenger.showSnackBar(
        SnackBar(content: Text(strings.invoiceDocumentExportFailed)),
      );
    case InvoiceExportSaved(
      hadSeller: final bool hadSeller,
      opened: final bool opened,
      file: final DeliveredFile file,
    ):
      // **The message describes what happened, not what was attempted.** Three
      // outcomes, and each says the true one: the file was saved and is open;
      // it was saved and nothing here could open it; or it was saved without a
      // seller block, which is the one the user should act on first.
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch ((hadSeller, opened)) {
            (false, _) => strings.invoiceDocumentExportNoSeller,
            (true, true) => strings.invoiceDocumentExportSavedAndOpened,
            (true, false) => strings.invoiceDocumentExportSaved,
          }),
          action: switch ((hadSeller, opened)) {
            // D-077's obligation, unchanged: the fix, one tap away.
            (false, _) => SnackBarAction(
              label: strings.invoiceDocumentExportGoToSettings,
              onPressed: () => context.go(AppDestination.settings.path),
            ),
            // Already open. Offering to open it again would be an action that
            // does nothing visible.
            (true, true) => null,
            // The automatic attempt found nothing to open with. The action is
            // kept as a manual retry rather than removed, because "no viewer"
            // and "the viewer was busy" look identical from here, and a user
            // who installs one wants the file without saving it twice.
            (true, false) => SnackBarAction(
              label: strings.invoiceDocumentExportOpenAction,
              onPressed: () async {
                final bool retried = await controller.openSaved(file);
                // Said rather than left silent: a tap that does nothing reads
                // as the application being broken, and "no viewer installed"
                // is a state a real phone is in.
                if (!retried && context.mounted) {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(
                      content: Text(strings.invoiceDocumentExportOpenFailed),
                    ),
                  );
                }
              },
            ),
          },
        ),
      );
  }
}
