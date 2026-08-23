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
