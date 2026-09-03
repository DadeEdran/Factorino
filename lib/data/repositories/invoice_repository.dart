import '../../core/date/jalali_period.dart';
import '../../core/money/invoice_calculator.dart';
import '../models/customer_totals.dart';
import '../models/invoice.dart';
import '../models/invoice_detail.dart';
import '../models/invoice_draft.dart';
import '../models/invoice_filter.dart';
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

  /// One customer's invoices, newest first, **paged**.
  ///
  /// The page reaches SQL like every other list's does (§13, D-038). It used to
  /// cap at a flat 1000 rows with no way to ask for more, which was known issue
  /// 16: invisible below a few hundred invoices and a growing query cost above
  /// it, on a screen a long-standing customer is exactly the person to open.
  Stream<List<Invoice>> watchForCustomer(
    String customerId, {
    int limit = 100,
    int offset = 0,
  });

  /// The invoice list, with each invoice's customer name resolved in the same
  /// query (D-040).
  ///
  /// The list screen needs a name, and [Invoice] carries only a customer id.
  /// Resolving those one at a time from the presentation layer would be an N+1
  /// read issued from a widget — invisible at ten invoices and ruinous at five
  /// thousand, which is the class of defect the project spec is written
  /// against. One join, one query, one stream.
  /// [filter] narrows the population **in SQL** — status, customer and a
  /// Jalali period, all as `WHERE` clauses on the same statement that already
  /// carries the ordering, the soft-delete filter and the `LIMIT`.
  ///
  /// Filtering a loaded page in Dart would be the same defect as paging in
  /// Dart, one step later: the limit would then apply to the rows *before*
  /// narrowing, so a filter matching three invoices out of ten thousand would
  /// return whichever of them happened to fall in the first page, and the
  /// screen would report "no results" for data that is right there.
  Stream<List<InvoiceListItem>> watchList({
    InvoiceFilter filter = InvoiceFilter.none,
    int limit = 100,
    int offset = 0,
  });

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

  /// What one customer has been billed and what they still owe, live.
  ///
  /// Both figures in **one** statement — see [CustomerTotals] for why they may
  /// not be two — and computed in SQL over every invoice that customer has,
  /// not over the page of them the detail screen happens to be showing.
  Stream<CustomerTotals> watchCustomerTotals(String customerId);

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

  /// Cancels an issued invoice. The number is **not** released: an issued
  /// number is spent, and a gap in the sequence is far better than two
  /// documents sharing one identity (D-013).
  ///
  /// Throws [InvoiceNotCancellable] for a draft — which is withdrawn with
  /// [softDelete] instead — and for an invoice that is already cancelled.
  ///
  /// **Payments already recorded are left exactly where they are** (D-061).
  /// The money did change hands, and a cancelled document is a statement about
  /// the claim, not about the cash. `cancelled` is set by hand and never
  /// derived, so the status does not move back afterwards
  /// either; a payment may still be *deleted* off a cancelled invoice, because
  /// a mis-entered receipt is a fault in the money record and the money record
  /// must be correctable whether or not the document still stands.
  Future<Invoice> cancel(String id);

  /// Soft-deletes a **draft or cancelled** invoice, and the payments recorded
  /// against it. Throws [InvoiceNotDeletable] for anything else.
  ///
  /// **Cancellation is the gate, not the alternative** (D-105). §6 keeps an
  /// issued document from disappearing silently, and this keeps a mistake from
  /// being permanent; both hold because the only route from `unpaid` to gone
  /// runs through [cancel], which is the accounting act the rule is really
  /// about. A draft needs no such act because nobody has seen it.
  ///
  /// **The payments go with it**, unlike cancellation, which deliberately
  /// leaves them (D-061). The two are not in tension: cancelling says the claim
  /// is void while the cash record stands, and deleting says the whole document
  /// was never a real transaction — a test invoice, a mis-entry — so a payment
  /// recorded against it is a mis-entry too. Every aggregate in this repository
  /// reaches payments through a correlated subquery from a live invoice row, so
  /// leaving them alive would change no figure today; they are deleted because
  /// a row whose parent is gone is one a later phase would surface.
  ///
  /// The invoice **number is not released** (D-013): a gap in the sequence is
  /// far better than two documents sharing one identity.
  Future<void> softDelete(String id);
}

/// Raised when an edit is attempted on an invoice that is no longer a draft.
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
      'may be edited.';
}

/// Raised when deletion is attempted on an invoice that has not been cancelled.
///
/// **The third refusal, and separate from the other two for the reason they are
/// separate from each other** (D-105): each one leaves the user with a
/// different next step, and an exception that cannot say which would leave the
/// UI unable to name it. This one's answer is *cancel it first* — the deletion
/// is not being refused, only its order.
class InvoiceNotDeletable implements Exception {
  const InvoiceNotDeletable(this.invoiceId, this.status);

  final String invoiceId;
  final InvoiceStatus status;

  @override
  String toString() =>
      'InvoiceNotDeletable: invoice $invoiceId is ${status.name}; only a draft '
      'or a cancelled invoice may be deleted, so cancel it first (D-105).';
}

/// Raised when cancellation is attempted on an invoice that has nothing to
/// cancel: a draft, or one that is already cancelled.
///
/// The mirror of [InvoiceNotEditable], and a separate type because it is the
/// opposite refusal — that one guards the *edit* path against issued invoices,
/// this one guards the *correction* path against invoices that were never
/// issued. Collapsing them into one exception would leave the UI unable to say
/// which of two contradictory things the user should do instead.
class InvoiceNotCancellable implements Exception {
  const InvoiceNotCancellable(this.invoiceId, this.status);

  final String invoiceId;
  final InvoiceStatus status;

  @override
  String toString() =>
      'InvoiceNotCancellable: invoice $invoiceId is ${status.name}; only an '
      'issued invoice may be cancelled (D-061).';
}
