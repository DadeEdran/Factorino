import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/number_display.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/router/destinations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../data/models/invoice_detail.dart';
import '../../application/invoice_cancellation.dart';

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
/// **A menu rather than bare icons is deliberate**, and was so when it held a
/// single item. The alternative — an icon in the title row — would put an
/// irreversible, destructive action behind a glyph nobody can name. A menu item
/// is a Persian sentence fragment the user reads before they commit to
/// anything, and it is the slot every one of the document's remaining actions
/// has joined.
///
/// **The PDF export is no longer among them** (D-094). It was, and nobody
/// found it: a menu is the right home for an action the user arrives already
/// looking for — cancelling, deleting — and the wrong home for the one the
/// whole of Phase 7 exists to offer. It is a named button in the document's
/// header row now; see [InvoiceExportButton]. What is left here is what belongs
/// behind a menu: the two irreversible ones, and editing a draft.
///
/// **Cancelling stays on the page; deleting leaves it.** A cancelled invoice is
/// still a document, still numbered and still the thing the user was looking at
/// — and the state they have just created is precisely the one that needs
/// explaining, so hiding it behind a navigation would undo half the point. A
/// deleted one has nothing left to show, so that path returns to the list, the
/// same shape the customer screen's delete already uses.
///
/// **Absent, not disabled, where it does not apply.** `Invoice.isCancellable`
/// is false for a draft and for an invoice already cancelled; the repository
/// refuses both (`InvoiceNotCancellable`), and a disabled control that never
/// explains itself is the affordance-leading-nowhere D-021 rules out.
///
/// **Deletion sits beside it, on exactly the states cancellation is not offered
/// in** (D-105). A draft deletes because nobody has seen it; a *cancelled*
/// invoice deletes because the accounting act §6 insists on has already
/// happened and is on record. Everything between the two shows «لغو فاکتور» and
/// nothing else — which is the ordering, not a refusal, and the cancellation
/// dialog says so in one line rather than leaving the user to conclude that a
/// mistaken invoice is permanent. That conclusion is what was reported from the
/// phone, and it is the half of D-105 that lives in copy rather than in code.
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
    final bool cancellable = detail.invoice.isCancellable;
    final bool isDraft = detail.invoice.isEditable;
    final bool deletable = detail.invoice.isDeletable;

    // **Absent entirely when it would be empty.** With the export gone
    // (D-094), a cancelled invoice has nothing behind this button: it cannot be
    // cancelled again and it is not a draft. An overflow menu that opens onto
    // nothing is the affordance-leading-nowhere D-021 rules out, and it used to
    // be impossible only because one item was always there.
    // `isDeletable` covers `isEditable`, so this is empty only for an issued
    // invoice that is somehow neither — which no status produces today, and
    // which would still be right to render as nothing if one ever did.
    if (!cancellable && !deletable) return const SizedBox.shrink();

    return PopupMenuButton<_InvoiceAction>(
      tooltip: strings.actionMore,
      icon: const Icon(Icons.more_vert, size: AppIconSize.md),
      onSelected: (_InvoiceAction action) => switch (action) {
        _InvoiceAction.cancel => _cancel(context, ref),
        _InvoiceAction.delete => _delete(context, ref),
        _InvoiceAction.editDraft => context.go(
          AppRoutes.invoiceEditFor(detail.invoice.id),
        ),
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_InvoiceAction>>[
        if (cancellable)
          PopupMenuItem<_InvoiceAction>(
            value: _InvoiceAction.cancel,
            child: Text(strings.invoiceCancelAction),
          ),
        // **Cancelling and deleting are never both offered**, since
        // `isCancellable` and `isDeletable` partition the statuses between
        // them. That is D-105's gate rather than a UI choice: an issued invoice
        // has exactly one way out, and it is the one that leaves a record.
        //
        // Editing comes before deleting: correcting a typo is the ordinary
        // reason to open this menu on a draft, and destroying it is the
        // exception. Editing stays draft-only -- §6 makes only a draft
        // editable, and an issued invoice is corrected by cancellation.
        if (isDraft)
          PopupMenuItem<_InvoiceAction>(
            value: _InvoiceAction.editDraft,
            child: Text(strings.invoiceEditDraftAction),
          ),
        // Two labels for one action, because they name two different things:
        // «حذف پیش‌نویس» removes something that was never a document, and
        // «حذف فاکتور» removes a numbered one that was issued and then
        // cancelled. A single label would have to be wrong about one of them.
        if (deletable)
          PopupMenuItem<_InvoiceAction>(
            value: _InvoiceAction.delete,
            child: Text(
              isDraft
                  ? strings.invoiceDeleteDraftAction
: strings.invoiceDeleteAction,
            ),
          ),
      ],
    );
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

  /// Deletes the invoice, after saying what that costs.
  ///
  /// **This one leaves the page, unlike cancelling.** A cancelled invoice is
  /// still a document and the state it has just entered is the one that needs
  /// explaining, so that screen stays put. A *deleted* one has nothing left to
  /// show, so the user goes back to the list — the same shape the customer
  /// screen's delete already uses.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool isDraft = detail.invoice.isEditable;
    final bool confirmed = await _confirmDelete(context, isDraft: isDraft);
    if (!confirmed || !context.mounted) return;

    final bool deleted = await ref
.read(invoiceCancellationProvider(detail.invoice.id).notifier)
.delete();
    if (!context.mounted) return;

    // The message is shown either way, but only a success navigates: leaving a
    // failed delete on the page it failed on is what lets the user try again.
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(switch ((deleted, isDraft)) {
          (true, true) => strings.invoiceDeleteDraftSuccess,
          (true, false) => strings.invoiceDeleteSuccess,
          (false, true) => strings.invoiceDeleteDraftFailed,
          (false, false) => strings.invoiceDeleteFailed,
        }),
      ),
    );
    if (deleted) context.go(AppDestination.invoices.path);
  }

  /// Says what deleting costs, in the terms that apply to *this* document.
  ///
  /// **Two dialogs, because the reassuring facts are opposites.** Deleting a
  /// draft is safe and the copy says why: no invoice number was spent (a draft
  /// never allocates one, D-048) and nothing reached the customer. Deleting a
  /// cancelled invoice is not safe in that sense at all — a number *was* spent
  /// and stays spent (D-013), and any payments recorded against it go with the
  /// document, which is precisely where cancellation behaves the other way
  /// (D-061). A user who has just read the cancellation dialog has been told
  /// payments are kept, so this one contradicts it explicitly rather than
  /// leaving the earlier sentence standing.
  ///
  /// The payments line is shown **only where there are payments**, on D-060's
  /// rule: a warning printed on every deletion is one nobody reads on the
  /// deletion where it matters. Neither dialog says «مطمئن هستید؟», which
  /// teaches people to dismiss dialogs.
  Future<bool> _confirmDelete(
    BuildContext context, {
    required bool isDraft,
  }) async {
    final int payments = detail.payments.length;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          isDraft
              ? strings.invoiceDeleteDraftTitle
: strings.invoiceDeleteTitle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isDraft
                  ? strings.invoiceDeleteDraftBody
: strings.invoiceDeleteBody,
            ),
            if (payments > 0) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                strings.invoiceDeletePaymentsNote(
                  formatGroupedPersian(payments),
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
            child: Text(
              isDraft
                  ? strings.invoiceDeleteDraftAction
: strings.invoiceDeleteAction,
            ),
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
            // **The half of D-105 that lives in copy.** Deletion is offered
            // only after cancellation, so without this line a user looking for
            // a way to clear a mistaken or test invoice sees one action, takes
            // it, and has no reason to look again — which is how "anything I
            // create is permanent" was reached on a build that already deleted
            // drafts. Unconditional, because it is true of every cancellation
            // and it answers the question this dialog raises.
            const SizedBox(height: AppSpacing.md),
            Text(strings.invoiceCancelThenDeleteNote),
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

enum _InvoiceAction { cancel, editDraft, delete }
