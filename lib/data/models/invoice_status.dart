/// Lifecycle of an invoice.
///
/// `partiallyPaid` and `paid` are **derived** from the sum of payments against
/// the invoice's grand total, recomputed on every payment write and persisted
/// so lists can be queried without joining. `draft` and `cancelled` are set by
/// hand and are never derived.
///
/// Only `draft` invoices are editable or deletable. An issued invoice is
/// corrected by cancellation, never by a silent edit.
///
/// Stored as the enum index: never reorder, only append.
enum InvoiceStatus { draft, unpaid, partiallyPaid, paid, cancelled }

/// The statuses that describe a document actually issued to a customer.
///
/// A **positive** list rather than "not draft and not cancelled". The two read
/// the same today and fail differently tomorrow: if a status is ever appended
/// to the enum, a negation silently folds it into every revenue figure, while
/// this list silently leaves it out. Of the two silent outcomes, an
/// understated total that someone questions beats an overstated one nobody
/// does.
const List<InvoiceStatus> kIssuedInvoiceStatuses = <InvoiceStatus>[
  InvoiceStatus.unpaid,
  InvoiceStatus.partiallyPaid,
  InvoiceStatus.paid,
];

/// The statuses that still represent money owed.
///
/// `paid` is absent because nothing is outstanding on it, and `draft` and
/// `cancelled` because neither is a claim on anyone.
const List<InvoiceStatus> kOutstandingInvoiceStatuses = <InvoiceStatus>[
  InvoiceStatus.unpaid,
  InvoiceStatus.partiallyPaid,
];
