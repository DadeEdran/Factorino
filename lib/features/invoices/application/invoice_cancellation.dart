import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/security/app_log.dart';
import '../../../data/models/invoice.dart';
import '../../../data/providers.dart';

part 'invoice_cancellation.g.dart';

/// The one write cancellation needs, and nothing else.
///
/// **The screen never touches a repository** (§3). Like `InvoicePayments` this
/// is deliberately thin: `cancel` is a status write the repository performs
/// inside its own transaction, and `invoiceDetailProvider` is a live query — so
/// the badge, the payments card and the summary all follow the row on their
/// own. There is no state to hold here and nothing to invalidate.
///
/// **It returns a bool rather than throwing** (§7). A failed write is a
/// friendly Persian line on the screen, never a stack trace or a raw exception
/// string; the detail goes through [AppLog] and carries no amount, no name and
/// no identifier.
///
/// **`InvoiceNotCancellable` is not a special case here**, on the precedent
/// `InvoicePayments` set for `PaymentNotAccepted`. The repository is the
/// authority on which invoices may be cancelled — a draft is withdrawn by
/// deleting it, and an invoice already cancelled has nothing left to cancel.
/// The screen omits the action for both, so a user cannot reach the refusal
/// through the UI; a deep link, a second window or a future sync path can, and
/// when they do the write fails cleanly rather than being prevented by a widget
/// that happened to be on screen.
@riverpod
class InvoiceCancellation extends _$InvoiceCancellation {
  @override
  void build(String invoiceId) {}

  /// Cancels this invoice. Returns whether it was written.
  ///
  /// **Nothing here touches the payments recorded against it** (D-061). That is
  /// the ruling, not an omission: the money did change hands, and a cancelled
  /// document is a statement about the claim rather than about the cash.
  Future<bool> cancel() async {
    // The write has to outlive the widget that started it (D-045): the dialog
    // that authorized it is already gone by the time this runs.
    final link = ref.keepAlive();
    try {
      await ref.read(invoiceRepositoryProvider).cancel(invoiceId);
      return true;
    } on Object catch (error, stackTrace) {
      AppLog.error(
        () => 'cancelling an invoice failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'invoice-cancellation',
      );
      return false;
    } finally {
      link.close();
    }
  }

  /// Issues this invoice, which must be a draft. Returns the issued invoice, or
  /// null if the write failed.
  ///
  /// **This is the other half of a workflow that had only one.** Issuing lived
  /// exclusively on the *editor* screen, at the moment of creation, and
  /// `InvoiceEditor` is keyed by the instant it was opened and always creates a
  /// new invoice — so there was no path from a **saved draft** to an issued
  /// one. A user who saved a draft meaning to issue it later had made a
  /// document that could never become an invoice, and every downstream action
  /// (recording a payment, cancelling) is correctly unavailable on a draft, so
  /// the whole page looked inert. Reported from the phone, 2026-09-02.
  ///
  /// Returns the invoice rather than a bool, because the caller has to tell the
  /// user the number that was just allocated — which is the one fact about
  /// issuing that did not exist a moment ago.
  Future<Invoice?> issue() async {
    final link = ref.keepAlive();
    try {
      return await ref.read(invoiceRepositoryProvider).issue(invoiceId);
    } on Object catch (error, stackTrace) {
      AppLog.error(
        () => 'issuing an invoice failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'invoice-cancellation',
      );
      return null;
    } finally {
      link.close();
    }
  }

  /// Soft-deletes this invoice, which must be a draft. Returns whether it was
  /// written.
  ///
  /// **The other way a document is withdrawn**, and the one this file's own
  /// header has described since Phase 5 (d) without anything calling it: a
  /// draft is not cancelled, it is deleted, because cancellation marks a
  /// document somebody has seen and a draft is one nobody has. §6 makes only
  /// drafts deletable and the repository enforces it — `softDeleteDraft` throws
  /// `InvoiceNotEditable` for anything else — so this stays a thin pass-through
  /// for the same reason [cancel] does.
  ///
  /// **Soft**, like every delete in this schema (§6). The row keeps its
  /// `deleted_at` so a future sync can propagate the deletion; a hard delete
  /// cannot be told to another device.
  Future<bool> deleteDraft() async {
    // Outlives the widget for the same reason as `cancel`: the confirmation
    // dialog is gone, and on success so is the whole screen.
    final link = ref.keepAlive();
    try {
      await ref.read(invoiceRepositoryProvider).softDeleteDraft(invoiceId);
      return true;
    } on Object catch (error, stackTrace) {
      AppLog.error(
        () => 'deleting a draft invoice failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'invoice-cancellation',
      );
      return false;
    } finally {
      link.close();
    }
  }
}
