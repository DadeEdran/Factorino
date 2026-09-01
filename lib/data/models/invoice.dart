import '../../core/money/money.dart';
import 'customer.dart';
import 'customer_snapshot.dart';
import 'invoice_status.dart';

/// An invoice header, without its lines.
///
/// **The totals here are snapshots, not derived values** (D-004). They are what
/// the money engine produced when the invoice was created, stored so that a
/// historical document keeps the numbers it was issued with. Nothing may
/// recompute them on read -- the PDF layer least of all (§12).
class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.numberYear,
    required this.numberSequence,
    required this.customerId,
    required this.issueDate,
    required this.status,
    required this.discount,
    required this.grossTotal,
    required this.subtotal,
    required this.totalDiscount,
    required this.totalTax,
    required this.roundingAdjustment,
    required this.grandTotal,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.discountPercentBp,
    this.taxRateBp,
    this.notes,
    this.customerSnapshot,
  });

  final String id;

  /// `{prefix}-{jalaliYear}-{sequence:0000}`, e.g. `INV-1405-0001` (D-013).
  ///
  /// **Null while the invoice is a draft** (D-048): a number is allocated by
  /// `InvoiceRepository.issue`, not at creation, so that abandoning a draft
  /// does not consume one permanently. Anything rendering this must say so in
  /// Persian rather than showing an empty cell — [hasNumber] is the check, and
  /// `invoiceNumberLabel` is the one place the wording lives.
  final String? number;

  /// The Jalali year and sequence the number was allocated from, kept apart
  /// from the formatted string so allocation never has to parse one back.
  ///
  /// Null exactly when [number] is.
  final int? numberYear;
  final int? numberSequence;

  /// Whether this invoice has been given its permanent identity yet.
  ///
  /// A draft created before v2 of the schema may still carry a number — the
  /// migration does not take back numbers already spent — so this is a
  /// question about the row, never about the status (D-048).
  bool get hasNumber => number != null;

  final String customerId;

  /// The customer **as this document states them**, frozen at issue (D-052).
  ///
  /// Null on a draft, which is not yet a document and should pick up a
  /// correction to the customer's details; and null on every invoice issued
  /// before schema v3, which has no snapshot and never will. Both cases read
  /// through to the live customer record — see [party], which is the only
  /// place that fallback is written.
  final CustomerSnapshot? customerSnapshot;

  /// The party to print, given the live customer record.
  ///
  /// **The one place the fallback lives.** An invoice with a snapshot shows the
  /// snapshot; one without shows [live], which is exactly the behaviour it had
  /// before v3 — a pre-v3 invoice loses nothing and gains no fabricated
  /// history. A second site applying this rule would eventually apply it
  /// differently, so every read path routes here.
  CustomerSnapshot party(Customer live) =>
      customerSnapshot ?? CustomerSnapshot.of(live);

  /// The party's name alone, for a list that has resolved the name and not the
  /// record. Same rule as [party], applied to the one field a row shows.
  String partyName(String liveFullName) =>
      customerSnapshot?.fullName ?? liveFullName;

  /// UTC (D-005). Reporting periods over this field are **Jalali** month and
  /// year boundaries converted to instants (D-006).
  final DateTime issueDate;
  final DateTime? dueDate;

  final InvoiceStatus status;

  /// The invoice-level discount actually applied, after clamping (D-027).
  final Money discount;
  final int? discountPercentBp;

  /// Invoice-level tax rate override. `null` means "inherit"; `0` is a real
  /// rate meaning zero percent, never "unset" (D-026).
  final int? taxRateBp;

  final String? notes;

  /// `Sigma lineGross` — the first term of the printed summary (D-055).
  ///
  /// **Null where the figure is genuinely unknown**, which is an invoice
  /// written before schema v4 whose stored numbers the backfill could not
  /// reconcile to the Rial. Every invoice written since carries it. Nothing may
  /// substitute a zero: a gross of zero beside a real grand total is a document
  /// that contradicts itself, where an admission is only a document that is
  /// incomplete. [InvoiceSummaryFigures] is where the absence is handled and
  /// `invoiceGrossLabel` is where the Persian for it lives, on
  /// `invoiceNumberLabel`'s precedent.
  final Money? grossTotal;

  /// Whether the printed summary can be assembled from stored figures alone.
  bool get hasStoredGross => grossTotal != null;

  final Money subtotal;

  /// The discount **actually given**, never the amount as entered (D-027).
  final Money totalDiscount;

  final Money totalTax;
  final Money roundingAdjustment;
  final Money grandTotal;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Only a draft may be edited or deleted. An issued invoice is corrected by
  /// cancellation, never by a silent edit.
  bool get isEditable => status == InvoiceStatus.draft;

  /// Whether payments may still be recorded against it.
  bool get acceptsPayments =>
      status != InvoiceStatus.draft && status != InvoiceStatus.cancelled;

  /// Whether cancellation is the correction path available to it (D-061).
  ///
  /// The same two exclusions as [acceptsPayments], reached from the other
  /// direction and kept separate on purpose. A **draft** is withdrawn by
  /// deleting it — it has no number, nobody has seen it, and there is nothing
  /// to correct — so offering both would present two ways out of one state and
  /// spend a number that was never allocated. An **already cancelled** invoice
  /// has nothing left to cancel, and a second cancellation would be a write
  /// that changes no fact while bumping `updatedAt` into a sync-pending row.
  bool get isCancellable =>
      status != InvoiceStatus.draft && status != InvoiceStatus.cancelled;

  @override
  bool operator ==(Object other) =>
      other is Invoice && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);

  @override
  String toString() => 'Invoice($id, $number)';
}
