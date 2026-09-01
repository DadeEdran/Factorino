import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/security/app_log.dart';
import '../../../data/models/payment.dart';
import '../../../data/providers.dart';

part 'invoice_payments.g.dart';

/// The two payment writes, and nothing else.
///
/// **The screen never touches a repository** (§3). This is the whole of the
/// widget-facing surface for recording and removing a payment, and it is
/// deliberately thin: the derived status is recomputed inside the repository's
/// own transaction (§6), so there is no state to keep here and nothing to
/// invalidate — `invoiceDetailProvider` is a live query and the recomputed row
/// arrives on its own.
///
/// **Both methods return a bool rather than throwing** (§7). A failed write is
/// a friendly Persian message on the screen, never a stack trace or a raw
/// exception string in front of the user; the detail goes through [AppLog] and
/// carries no amount, no name and no identifier.
///
/// **`PaymentNotAccepted` is not treated as a special case here**, and that is
/// deliberate. The repository is the authority on which invoices may take a
/// payment (D-013's shape, applied to payments): a draft is not yet a claim on
/// anyone and a cancelled invoice is not one any more. The screen hides the
/// control for both and explains why, so a user cannot reach the refusal
/// through the UI — but a deep link, a second window or a future sync path can,
/// and when they do the write fails cleanly rather than being prevented by a
/// widget that happened to be on screen.
@riverpod
class InvoicePayments extends _$InvoicePayments {
  @override
  void build(String invoiceId) {}

  /// Records [draft] against this invoice. Returns whether it was written.
  Future<bool> record(PaymentDraft draft) async {
    // The write has to outlive the widget that started it (D-045): the sheet
    // that produced the draft is already gone by the time this runs.
    final link = ref.keepAlive();
    try {
      await ref.read(paymentRepositoryProvider).record(invoiceId, draft);
      return true;
    } on Object catch (error, stackTrace) {
      AppLog.error(
        () => 'recording a payment failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'invoice-payments',
      );
      return false;
    } finally {
      link.close();
    }
  }

  /// Soft-deletes [paymentId] and lets the repository move the status back.
  Future<bool> delete(String paymentId) async {
    final link = ref.keepAlive();
    try {
      await ref.read(paymentRepositoryProvider).softDelete(paymentId);
      return true;
    } on Object catch (error, stackTrace) {
      AppLog.error(
        () => 'deleting a payment failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'invoice-payments',
      );
      return false;
    } finally {
      link.close();
    }
  }
}
