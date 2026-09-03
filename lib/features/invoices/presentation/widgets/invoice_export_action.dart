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
/// ## The message offers to open what was saved (D-091)
///
/// A save dialog on Android ends with the file somewhere in the user's own
/// storage and the application back in front of them, having said only that it
/// worked. Whether it *did* work — whether the page is right, whether the
/// Persian shaped, whether the totals read — is a question the user has no way
/// to answer without leaving and finding the file by hand. So the confirmation
/// carries the action, on the one occasion it is certain to be wanted.
///
/// **One action, not two**, and the no-seller case keeps the settings one:
/// that message exists to be acted on, and a snackbar has room for a single
/// action. The two never collide, because a document with no seller block is
/// exactly the one the user should be fixing rather than opening.
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

  switch (outcome) {
    case InvoiceExportCancelled():
      return;
    case InvoiceExportFailed():
      messenger.showSnackBar(
        SnackBar(content: Text(strings.invoiceDocumentExportFailed)),
      );
    case InvoiceExportSaved(
      hadSeller: final bool hadSeller,
      file: final DeliveredFile file,
    ):
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            hadSeller
                ? strings.invoiceDocumentExportSaved
                : strings.invoiceDocumentExportNoSeller,
          ),
          action: hadSeller
              ? SnackBarAction(
                  label: strings.invoiceDocumentExportOpenAction,
                  onPressed: () async {
                    final bool opened = await controller.openSaved(file);
                    // Said rather than left silent: a tap that does nothing
                    // reads as the application being broken, and "no viewer
                    // installed" is a state a real phone is in.
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        SnackBar(
                          content: Text(
                            strings.invoiceDocumentExportOpenFailed,
                          ),
                        ),
                      );
                    }
                  },
                )
              : SnackBarAction(
                  label: strings.invoiceDocumentExportGoToSettings,
                  onPressed: () => context.go(AppDestination.settings.path),
                ),
        ),
      );
  }
}
