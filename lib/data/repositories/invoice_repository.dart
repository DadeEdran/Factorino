import '../../core/date/jalali_period.dart';
import '../../core/money/invoice_calculator.dart';
import '../models/invoice.dart';
import '../models/invoice_detail.dart';
import '../models/invoice_draft.dart';
import '../models/invoice_status.dart';

/// What an invoice creation produced.
///
/// Carries the money engine's [warnings] alongside the stored invoice, so a
/// clamped discount reaches the UI from the write path too and not only from a
/// live preview (D-027). The invoice is already persisted when this is
/// returned: a warning is an observation about the input, never a failure.
class InvoiceCreationResult {
  const InvoiceCreationResult({required this.invoice, required this.warnings});

  final Invoice invoice;
  final List<InvoiceWarning> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
}

/// The invoice boundary. Must not import drift -- see `CustomerRepository`.
abstract interface class InvoiceRepository {
  Stream<List<Invoice>> watchAll({int limit = 100, int offset = 0});

  /// Invoices whose issue date falls inside [period].
  ///
  /// [period] comes from `core/date/`, where periods are computed in the
  /// **Jalali** calendar and converted to instants (D-006). Passing a range
  /// rather than a month number is what keeps the calendar decision in one
  /// place instead of in every query.
  Stream<List<Invoice>> watchInPeriod(
    InstantRange period, {
    int limit = 100,
    int offset = 0,
  });

  Stream<List<Invoice>> watchForCustomer(String customerId);

  Future<Invoice?> findById(String id);

  /// The header, customer, lines and payments in one read.
  Future<InvoiceDetail?> findDetail(String id);

  Stream<InvoiceDetail?> watchDetail(String id);

  Future<int> count();

  /// The sum of `grandTotal` over invoices issued in [period], excluding
  /// cancelled ones, computed **in SQL** (§13).
  Future<int> totalIssuedRial(InstantRange period);

  /// Creates an invoice, its lines, and its number, in one transaction.
  ///
  /// The repository owns everything derived: it resolves the tax rate chain
  /// against settings, runs the money engine, allocates the next sequence for
  /// the draft's Jalali year, and writes the computed totals as snapshots
  /// (D-004). A caller cannot supply a total, so a total can never disagree
  /// with its lines.
  Future<InvoiceCreationResult> create(
    InvoiceDraft draft, {
    InvoiceStatus status = InvoiceStatus.draft,
  });

  /// Replaces a **draft** invoice and its lines, recomputing and reallocating
  /// nothing but the totals.
  ///
  /// Throws [InvoiceNotEditable] for any other status: an issued invoice is
  /// corrected by cancellation, never by a silent edit.
  Future<InvoiceCreationResult> updateDraft(String id, InvoiceDraft draft);

  /// Moves a draft to `unpaid`, fixing its number as issued.
  Future<Invoice> issue(String id);

  /// Cancels an invoice. The number is **not** released: an issued number is
  /// spent, and a gap in the sequence is far better than two documents
  /// sharing one identity (D-013).
  Future<Invoice> cancel(String id);

  /// Soft-deletes a **draft** invoice. Throws [InvoiceNotEditable] otherwise.
  Future<void> softDeleteDraft(String id);
}

/// Raised when an edit or delete is attempted on an invoice that is no longer
/// a draft.
///
/// A domain rule, not a database constraint, so it is expressed as a domain
/// exception. The UI maps it to a Persian message; it never surfaces raw (§7).
class InvoiceNotEditable implements Exception {
  const InvoiceNotEditable(this.invoiceId, this.status);

  final String invoiceId;
  final InvoiceStatus status;

  @override
  String toString() =>
      'InvoiceNotEditable: invoice $invoiceId is ${status.name}; only a draft '
      'may be edited or deleted.';
}
