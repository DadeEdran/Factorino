import '../../../core/date/jalali_period.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/invoice.dart';
import '../../../data/models/invoice_status.dart';

/// The one place a stored [InvoiceStatus] becomes a displayed
/// [InvoiceStatusView].
///
/// **Nothing here recomputes whether an invoice is paid.** `paid` and
/// `partiallyPaid` are derived from payments *in the repository*, inside the
/// same transaction as the payment write, and persisted. This
/// function maps that stored answer through unchanged. A second, independent
/// determination made at display time is how a badge comes to contradict the
/// payments listed underneath it — and the version the user believes is the one
/// on screen.
///
/// It could not do otherwise even if someone wanted it to: the list model it is
/// used with carries no payment information at all. The single value this adds
/// is [InvoiceStatusView.overdue], which is *not* a stored status and must not
/// be — a stored `overdue` would be wrong the moment the clock passed midnight
/// and nothing wrote to the row.
InvoiceStatusView invoiceStatusViewOf(
  Invoice invoice, {
  required DateTime now,
}) {
  return switch (invoice.status) {
    // Set by hand, never derived, and never aged: a cancelled invoice past its
    // due date is not overdue, it is cancelled, and a paid one is paid.
    InvoiceStatus.draft ||
    InvoiceStatus.paid ||
    InvoiceStatus.cancelled => invoiceStatusViewOfStored(invoice.status),

    // Still owed. These are the only two an overdue date can apply to.
    InvoiceStatus.unpaid || InvoiceStatus.partiallyPaid =>
      isOverdue(invoice, now: now)
          ? InvoiceStatusView.overdue
: invoiceStatusViewOfStored(invoice.status),
  };
}

/// The view a **stored** status maps to, with the overdue rule not applied.
///
/// For surfaces that label statuses rather than invoices — the filter chips in
/// Phase 5 (e), which offer the five stored statuses and deliberately not
/// «سررسید گذشته» (see [InvoiceFilter.statuses]). There is no invoice to age
/// and no clock to age it against.
///
/// [invoiceStatusViewOf] routes through this rather than repeating the five
/// cases, so a status added to the enum has exactly one place to be mapped and
/// the compiler names it.
InvoiceStatusView invoiceStatusViewOfStored(InvoiceStatus status) {
  return switch (status) {
    InvoiceStatus.draft => InvoiceStatusView.draft,
    InvoiceStatus.unpaid => InvoiceStatusView.unpaid,
    InvoiceStatus.partiallyPaid => InvoiceStatusView.partiallyPaid,
    InvoiceStatus.paid => InvoiceStatusView.paid,
    InvoiceStatus.cancelled => InvoiceStatusView.cancelled,
  };
}

/// Whether an invoice that still owes money is past its due date.
///
/// **The comparison is on whole Jalali days, not on instants.** An invoice due
/// today is not overdue until today is over: comparing `now.isAfter(dueDate)`
/// would mark an invoice due at midnight-Tehran as overdue for the whole of the
/// day it is actually due, which is a red badge on a document nobody is late
/// on. The end of the due date's Jalali day is the first instant at which it
/// genuinely is late, and `jalaliDayOf` computes that boundary in the same
/// calendar and the same offset every other date in this application uses
/// (D-006, D-028).
///
/// An invoice with no due date is never overdue — there is nothing to be late
/// against.
bool isOverdue(Invoice invoice, {required DateTime now}) {
  final DateTime? due = invoice.dueDate;
  if (due == null) return false;
  return !now.toUtc().isBefore(jalaliDayOf(due).end);
}

/// The Persian label for a displayed status.
///
/// Resolved from the localization layer, so this file holds no string of its
/// own (§1) and [StatusBadge] keeps holding none either.
String invoiceStatusLabel(InvoiceStatusView view, AppStrings strings) {
  return switch (view) {
    InvoiceStatusView.draft => strings.statusDraft,
    InvoiceStatusView.unpaid => strings.statusUnpaid,
    InvoiceStatusView.partiallyPaid => strings.statusPartiallyPaid,
    InvoiceStatusView.paid => strings.statusPaid,
    InvoiceStatusView.cancelled => strings.statusCancelled,
    InvoiceStatusView.overdue => strings.statusOverdue,
  };
}
