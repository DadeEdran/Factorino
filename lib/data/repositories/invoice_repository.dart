import '../../core/date/jalali_period.dart';
import '../../core/money/invoice_calculator.dart';
import '../models/invoice.dart';
import '../models/invoice_detail.dart';
import '../models/invoice_draft.dart';
import '../models/invoice_list_item.dart';
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

  /// The invoice list, with each invoice's customer name resolved in the same
  /// query (D-040).
  ///
  /// The list screen needs a name, and [Invoice] carries only a customer id.
  /// Resolving those one at a time from the presentation layer would be an N+1
  /// read issued from a widget — invisible at ten invoices and ruinous at five
  /// thousand, which is the class of defect the project spec is written
  /// against. One join, one query, one stream.
  Stream<List<InvoiceListItem>> watchList({int limit = 100, int offset = 0});

  /// The number of invoices on record, as a **live** query — see the note on
  /// `CustomerRepository.watchCount`.
  Stream<int> watchCount();

  /// The number of invoices **issued** inside [period], live.
  ///
  /// Counts exactly the population [totalIssuedRial] sums, so the two dashboard
  /// tiles that sit beside each other describe the same set of documents. A
  /// count over one population next to a total over another is a pair of
  /// numbers the user cannot reconcile, and reconciling is the only thing a
  /// dashboard is for.
  Stream<int> watchIssuedCountInPeriod(InstantRange period);

  /// What is still owed across every invoice that is still a claim on someone,
  /// live.
  ///
  /// The sum of `grandTotal − payments received` over invoices in `unpaid` and
  /// `partiallyPaid`, computed **in SQL** as a single joined aggregate.
  /// Deliberately one query rather than two subtracted in Dart: two independent
  /// streams settle at different moments, and the tile would show a figure that
  /// belongs to neither state for as long as it took the second to arrive.
  Stream<int> watchOutstandingRial();

  Future<Invoice?> findById(String id);

  /// The header, customer, lines and payments in one read.
  Future<InvoiceDetail?> findDetail(String id);

  Stream<InvoiceDetail?> watchDetail(String id);

  Future<int> count();

  /// The sum of `grandTotal` over invoices **issued** in [period], computed
  /// **in SQL** (§13).
  ///
  /// "Issued" excludes drafts as well as cancelled invoices (D-039). A draft is
  /// not yet a claim on anyone — the payment path already refuses to take money
  /// against one — so counting it as revenue makes a sales figure move while
  /// the user is merely typing.
  Future<int> totalIssuedRial(InstantRange period);

  /// The same sum, as a live query, for a dashboard tile that must not go
  /// stale on the next write.
  Stream<int> watchTotalIssuedRial(InstantRange period);

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
