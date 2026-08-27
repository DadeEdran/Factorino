import 'package:drift/drift.dart';

import '../../models/invoice_status.dart';
import 'customers.dart';
import 'sync_columns.dart';

/// Issued invoices.
///
/// Every monetary column is integer **Rial** (D-002). The totals are stored
/// rather than recomputed on read, so that a historical invoice keeps the
/// numbers it was issued with even if the money engine's inputs change.
@TableIndex(name: 'idx_invoices_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_invoices_issue_date', columns: {#issueDate})
@TableIndex(name: 'idx_invoices_customer', columns: {#customerId})
@TableIndex(name: 'idx_invoices_status', columns: {#status})
@TableIndex(name: 'idx_invoices_number_year', columns: {#numberYear})
@TableIndex(name: 'idx_invoices_number', columns: {#number}, unique: true)
@DataClassName('InvoiceRow')
class Invoices extends Table with SyncColumns {
  /// The full human-facing number, e.g. `INV-1405-0001` (D-013).
  ///
  /// Uniquely indexed **including soft-deleted rows**: a number that has been
  /// issued is spent, and reusing it would produce two different documents
  /// with one identity.
  ///
  /// **Null until the invoice is issued** (D-048). A draft carries no number,
  /// because allocating one at creation meant an abandoned draft consumed a
  /// number permanently — the unique index above covers soft-deleted rows, so
  /// the gap it left could never be reclaimed, and a business whose numbering
  /// has holes has a conversation to have with an auditor.
  ///
  /// Nullable rather than an empty-string sentinel, and that is the whole
  /// mechanism: SQLite treats `''` as equal to `''` in a unique index, so a
  /// second numberless draft would collide, while **NULLs are distinct** in
  /// one. `issue()` is what fills these three columns in.
  TextColumn get number => text().withLength(min: 1, max: 40).nullable()();

  /// The Jalali year and sequence the number was allocated from, stored
  /// separately so allocation is `MAX(number_sequence) WHERE number_year = ?`
  /// inside a transaction, rather than parsing formatted strings.
  ///
  /// Null exactly when [number] is. `MAX` ignores nulls, so an unissued draft
  /// takes no part in allocation without the query having to exclude it.
  IntColumn get numberYear => integer().nullable()();

  IntColumn get numberSequence => integer().nullable()();

  /// No cascade: a customer referenced by an invoice is soft-deleted only,
  /// never hard-deleted (D-003), and SQLite's default `NO ACTION` is what
  /// makes an attempted hard delete fail loudly instead of orphaning rows.
  TextColumn get customerId => text().references(Customers, #id)();

  /// Epoch milliseconds, UTC. Displayed as Jalali; reporting periods are
  /// Jalali month boundaries converted to instants (D-005, D-006).
  IntColumn get issueDate => integer()();

  IntColumn get dueDate => integer().nullable()();

  /// Invoice-level discount as an absolute Rial amount, allocated across items
  /// proportionally by line net with largest-remainder rounding (§4 step 4).
  IntColumn get discountRial => integer().withDefault(const Constant(0))();

  /// If the user entered the discount as a percentage, the entered percentage
  /// in basis points is kept alongside the resolved amount (§4 step 2), so the
  /// document can show what was actually typed.
  IntColumn get discountPercentBp => integer().nullable()();

  /// Invoice-level tax rate in basis points. Null means "fall through to the
  /// default in settings" (§4 step 6).
  IntColumn get taxRateBp => integer().nullable()();

  TextColumn get notes => text().withLength(max: 2000).nullable()();

  // ---- the customer, as the document states them (D-052) -----------------
  //
  // Written by `issue()`, inside the transaction that allocates the number,
  // and **null until then**. A draft is not a document, so it has no party
  // snapshot and resolves the live customer row instead; an issued invoice
  // must keep the party it was issued to, for the same reason `invoice_items`
  // keeps the price it was issued at (D-004).
  //
  // Null on every invoice issued before schema v3, too. There is no honest
  // value to backfill — the migration cannot know what the customer record
  // said on the day the document was printed, and writing today's values in
  // would look like a snapshot while being exactly the live join it replaces.
  // So they stay null and the read path falls back to the live customer, which
  // is the behaviour those invoices already had.
  //
  // The mobile number is deliberately absent: it is contact detail rather than
  // document content, and it keeps resolving live.
  //
  // Every `max:` here equals its counterpart on `customers` — a snapshot
  // column shorter than its source would make a customer with a long address
  // impossible to issue an invoice to. `field_limits_test.dart` asserts the
  // equality rather than leaving it to be noticed.
  TextColumn get customerNameSnapshot =>
      text().withLength(max: 120).nullable()();

  TextColumn get customerCompanySnapshot =>
      text().withLength(max: 160).nullable()();

  /// کد ملی and کد اقتصادی as they stood at issue. These are the fields with
  /// legal weight on an Iranian invoice and the ones a correction changes, so
  /// a snapshot that omitted them would protect the least consequential field
  /// (D-052).
  TextColumn get customerNationalIdSnapshot =>
      text().withLength(max: 10).nullable()();

  TextColumn get customerEconomicIdSnapshot =>
      text().withLength(max: 20).nullable()();

  TextColumn get customerAddressSnapshot =>
      text().withLength(max: 500).nullable()();

  IntColumn get status => intEnum<InvoiceStatus>()();

  // ---- computed totals, snapshotted at issue time ------------------------
  IntColumn get subtotalRial => integer().withDefault(const Constant(0))();

  IntColumn get totalDiscountRial => integer().withDefault(const Constant(0))();

  IntColumn get totalTaxRial => integer().withDefault(const Constant(0))();

  /// The delta applied by optional whole-invoice rounding, kept so the invoice
  /// still reconciles exactly (§4 "Rounding").
  IntColumn get roundingAdjustmentRial =>
      integer().withDefault(const Constant(0))();

  IntColumn get grandTotalRial => integer().withDefault(const Constant(0))();
}
