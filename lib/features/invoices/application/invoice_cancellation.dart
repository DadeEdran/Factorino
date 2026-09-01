import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/security/app_log.dart';
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
}
