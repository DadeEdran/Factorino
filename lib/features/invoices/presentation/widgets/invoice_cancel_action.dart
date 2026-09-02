import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/number_display.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/router/destinations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../data/models/invoice_detail.dart';
import '../../application/invoice_cancellation.dart';
import '../../application/invoice_document_controller.dart';

/// The document's own actions, in the page's title row.
///
/// **A menu rather than a card, and that is the interesting part.** Every
/// obvious home for a cancel button is a block of content: an actions card at
/// the foot of the page, a button under the summary, a bar above the lines. All
/// of them add height, and the payments card in (c) was the *third* time a card
/// added to this family of screens pushed the first invoice line off a 400 × 800
/// phone — after the customer record card (D-044) and the party card (b). The
/// rule that finding earned is now written into the project spec, and this is the
/// first widget it applies to: the title row already exists, costs no vertical
/// space at any tier, and is where the customer and product screens already put
/// exactly this pair of actions.
///
/// **A menu of one item is deliberate.** The alternative — a bare icon in the
/// title row — would put an irreversible, destructive action behind a glyph
/// nobody can name. A menu item is a Persian sentence fragment the user reads
/// before they commit to anything, and it is the slot the rest of the document's
/// actions (a draft's deletion, the Phase 7 export) will join.
///
/// **The page stays where it is afterwards**, unlike the customer screen's
/// delete, which leaves for the list. A cancelled invoice is still a document,
/// still numbered and still the thing the user was looking at — and the state
/// they have just created is precisely the one that needs explaining, so hiding
/// it behind a navigation would undo half the point of the increment.
///
/// **Absent, not disabled, where it does not apply.** `Invoice.isCancellable`
/// is false for a draft and for an invoice already cancelled; the repository
/// refuses both (`InvoiceNotCancellable`), and a disabled control that never
/// explains itself is the affordance-leading-nowhere D-021 rules out. What a
/// draft *should* offer instead is deletion, which is not this increment's —
/// so the menu itself disappears rather than offering the wrong way out.
class InvoiceCancelAction extends ConsumerWidget {
  const InvoiceCancelAction({
    required this.detail,
    required this.strings,
    super.key,
  });

  final InvoiceDetail detail;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // **The export is offered on every invoice, including a draft and a
    // cancelled one**, which is why the menu no longer disappears with
    // cancellability. D-075 settled that a draft prints (marked with its band)
    // and D-061 that a cancelled invoice is still a document; a user who cannot
    // produce a PDF of the thing on their screen would have to ask why.
    final bool cancellable = detail.invoice.isCancellable;
    final bool isDraft = detail.invoice.isEditable;

    return PopupMenuButton<_InvoiceAction>(
      tooltip: strings.actionMore,
      icon: const Icon(Icons.more_vert, size: AppIconSize.md),
      onSelected: (_InvoiceAction action) => switch (action) {
        _InvoiceAction.export => _export(context, ref),
        _InvoiceAction.cancel => _cancel(context, ref),
        _InvoiceAction.deleteDraft => _deleteDraft(context, ref),
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_InvoiceAction>>[
        PopupMenuItem<_InvoiceAction>(
          value: _InvoiceAction.export,
          child: Text(strings.invoiceDocumentExportAction),
        ),
        if (cancellable)
          PopupMenuItem<_InvoiceAction>(
            value: _InvoiceAction.cancel,
            child: Text(strings.invoiceCancelAction),
          ),
        // **The two are mutually exclusive by construction**, since
        // `isCancellable` is false exactly where `isEditable` is true. That is
        // §6's rule rather than a UI choice: a draft is withdrawn by deleting
        // it, an issued invoice by cancelling it, and offering both would be
        // offering two ways out of one state.
        if (isDraft)
          PopupMenuItem<_InvoiceAction>(
            value: _InvoiceAction.deleteDraft,
            child: Text(strings.invoiceDeleteDraftAction),
          ),
      ],
    );
  }

  /// Renders the document and hands it to the save dialog.
  ///
  /// **The empty-seller notice fires here, and only here** — the other half of
  /// D-077's obligation, the settings screen being the half for the user who
  /// goes looking. Three properties it has to have, all of them rulings rather
  /// than taste:
  ///
  /// * **It never blocks.** Not a dialog, not a confirmation, not a reason to
  ///   refuse. D-077 ruled that an empty seller blocks nothing, and a modal
  ///   asking the user to approve their own document would be exactly the
  ///   refusal that ruling rejected.
  /// * **It comes after the save, not before.** Before, it would be a
  ///   confirmation in everything but name. After, it reports what the file the
  ///   user now holds actually contains.
  /// * **It says what happened and offers the fix.** A notice with no way to
  ///   act on it is a standing warning, and those get ignored.
  ///
  /// It is silent on a cancelled export, because nothing was produced and there
  /// is nothing to report about it.
  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final InvoiceExportOutcome outcome = await ref
.read(invoiceDocumentControllerProvider.notifier)
.export(detail: detail, strings: strings);

    if (!context.mounted) return;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    if (messenger == null) return;

    switch (outcome) {
      case InvoiceExportCancelled():
        return;
      case InvoiceExportFailed():
        messenger.showSnackBar(
          SnackBar(content: Text(strings.invoiceDocumentExportFailed)),
        );
      case InvoiceExportSaved(hadSeller: final bool hadSeller):
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              hadSeller
                  ? strings.invoiceDocumentExportSaved
: strings.invoiceDocumentExportNoSeller,
            ),
            action: hadSeller
                ? null
: SnackBarAction(
                    label: strings.invoiceDocumentExportGoToSettings,
                    onPressed: () => context.go(AppDestination.settings.path),
                  ),
          ),
        );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await _confirm(context);
    if (!confirmed || !context.mounted) return;

    final bool cancelled = await ref
.read(invoiceCancellationProvider(detail.invoice.id).notifier)
.cancel();
    if (!context.mounted) return;

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          cancelled
              ? strings.invoiceCancelSuccess
: strings.invoiceCancelFailed,
        ),
      ),
    );
  }

  /// Deletes the draft, after saying what that costs.
  ///
  /// **Known issue 27, and it was a gap rather than a decision.**
  /// `softDeleteDraft` has existed and been tested since Phase 4; nothing ever
  /// called it, so a draft created by mistake could not be removed at all. This
  /// widget's own header has said since Phase 5 (d) that deletion is what a
  /// draft should be offered instead of cancellation — *"which is not this
  /// increment's"* — and then no increment took it.
  ///
  /// **This one leaves the page, unlike cancelling.** A cancelled invoice is
  /// still a document and the state it has just entered is the one that needs
  /// explaining, so that screen stays put. A deleted draft is not a document
  /// and its page no longer has anything to show, so the user goes back to the
  /// list — the same shape the customer screen's delete already uses.
  Future<void> _deleteDraft(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await _confirmDelete(context);
    if (!confirmed || !context.mounted) return;

    final bool deleted = await ref
.read(invoiceCancellationProvider(detail.invoice.id).notifier)
.deleteDraft();
    if (!context.mounted) return;

    // The message is shown either way, but only a success navigates: leaving a
    // failed delete on the page it failed on is what lets the user try again.
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? strings.invoiceDeleteDraftSuccess
: strings.invoiceDeleteDraftFailed,
        ),
      ),
    );
    if (deleted) context.go(AppDestination.invoices.path);
  }

  /// Says what deleting a draft costs, and the two things it does not cost.
  ///
  /// The two facts the user cannot see and would otherwise wonder about
  /// afterwards: **no invoice number was spent** (a draft never allocates one,
  /// D-048) and **nothing reached the customer**. Both are reasons this is safe,
  /// which is what a confirmation should say when the action really is safe —
  /// rather than «مطمئن هستید؟», which teaches people to dismiss dialogs.
  Future<bool> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.invoiceDeleteDraftTitle),
        content: Text(strings.invoiceDeleteDraftBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.invoiceDeleteDraftAction),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Says what cancelling does **and does not** do, before it is done.
  ///
  /// Two sentences, and the second is conditional. The first is true of every
  /// invoice: the document is kept and marked, the number stays spent (D-013),
  /// and editing is still not the way back (§6). The second is shown **only
  /// where the invoice actually carries payments** — D-060's rule, because a
  /// warning printed on every cancellation is one nobody reads on the
  /// cancellation where it matters.
  ///
  /// The paid figure is named rather than described. "Payments are kept" is a
  /// policy; «۵٬۰۰۰٬۰۰۰ تومان … بازگردانده نمی‌شود» is the amount the user is
  /// about to leave sitting on a void document, which is the thing they would
  /// otherwise query afterwards.
  Future<bool> _confirm(BuildContext context) async {
    final bool hasPayments = detail.payments.isNotEmpty;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.invoiceCancelTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(strings.invoiceCancelBody),
            if (hasPayments) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                strings.invoiceCancelPaymentsNote(
                  formatGroupedPersian(detail.amountPaid.toman),
                ),
              ),
            ],
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.invoiceCancelAction),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

enum _InvoiceAction { export, cancel, deleteDraft }
