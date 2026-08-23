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
  TextColumn get number => text().withLength(min: 1, max: 40)();

  /// The Jalali year and sequence the number was allocated from, stored
  /// separately so allocation is `MAX(number_sequence) WHERE number_year = ?`
  /// inside a transaction, rather than parsing formatted strings.
  IntColumn get numberYear => integer()();

  IntColumn get numberSequence => integer()();

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
