import '../../../data/models/customer_snapshot.dart';
import '../../../data/models/invoice_detail.dart';

/// Where the party shown on an invoice came from, and whether the screen owes
/// the user a sentence about it (D-052).
///
/// **The distinction this exists to make visible.** `InvoiceDetail.party` is
/// the document's own statement of who was billed: the snapshot taken at issue,
/// or — where there is none — the live customer record read through as a
/// fallback. `InvoiceDetail.customer` is that live record. Most of the time the
/// two agree and there is nothing to say. The cases where they do not are
/// exactly the cases a user would otherwise misread:
///
/// * a customer renamed after the invoice was issued, where the screen shows a
///   name that is no longer the customer's and must say why rather than look
///   stale;
/// * an invoice issued **before** schema v3, which has no snapshot and never
///   will, where the name on screen is today's and the document's own is gone;
/// * a draft, which deliberately follows the live record, because a draft is
///   not a document yet and should pick up a correction.
///
/// **This decides nothing about which name to show.** `Invoice.party` already
/// owns that, in one place, and nothing here may second-guess it. This answers
/// only *what to tell the user about the name they are looking at* — which is a
/// presentation question, which is why it lives in a feature's `domain/` rather
/// than beside the model.
enum InvoicePartyProvenance {
  /// The invoice carries its own snapshot and the live record still agrees with
  /// it. Nothing to disclose: the ordinary case.
  snapshotMatchesRecord,

  /// The invoice carries its own snapshot and the customer's record has since
  /// changed. **The document is right and the screen is showing it** — the
  /// note exists so the difference reads as history rather than as an error.
  snapshotDivergedFromRecord,

  /// A draft, which has no snapshot yet and follows the live record on purpose.
  /// Worth saying, because the same screen shows an issued invoice frozen.
  draftFollowsRecord,

  /// Issued before schema v3. There is no snapshot and there is no honest way
  /// to invent one, so the live record is shown — and the fact that this
  /// document's own statement of the party was never stored is exactly the kind
  /// of gap «ثبت‌نشده» exists to admit elsewhere (D-055).
  issuedWithoutSnapshot,
}

/// Which of the four cases [detail] is in.
///
/// The comparison is over the whole snapshot, not over the name: a corrected
/// کد ملی or a changed address moves a document just as much as a rename does,
/// and D-052 chose those fields precisely because they are the ones a
/// correction touches. [CustomerSnapshot] compares by value, so this is one
/// operator away.
InvoicePartyProvenance partyProvenanceOf(InvoiceDetail detail) {
  final CustomerSnapshot? stored = detail.invoice.customerSnapshot;

  if (stored == null) {
    return detail.invoice.isEditable
        ? InvoicePartyProvenance.draftFollowsRecord
        : InvoicePartyProvenance.issuedWithoutSnapshot;
  }

  return stored == CustomerSnapshot.of(detail.customer)
      ? InvoicePartyProvenance.snapshotMatchesRecord
      : InvoicePartyProvenance.snapshotDivergedFromRecord;
}
