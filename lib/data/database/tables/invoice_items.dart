import 'package:drift/drift.dart';

import 'invoices.dart';
import 'products.dart';
import 'sync_columns.dart';

/// The lines of an invoice.
///
/// **This table looks redundant on purpose** (D-004). Title, unit and unit
/// price are copies taken at creation time, not references resolved at read
/// time. If a product's price changes next month, every invoice already issued
/// must still show and total exactly what it showed when issued -- joining to
/// the live `products` row would silently rewrite financial history.
@TableIndex(name: 'idx_invoice_items_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_invoice_items_invoice', columns: {#invoiceId})
@DataClassName('InvoiceItemRow')
class InvoiceItems extends Table with SyncColumns {
  /// Cascades: an invoice item must never outlive its invoice. Invoice
  /// deletion itself is a soft delete; the cascade covers hard cleanup only
  ///.
  TextColumn get invoiceId =>
      text().references(Invoices, #id, onDelete: KeyAction.cascade)();

  /// Nullable: a line may be typed freehand without a catalogue entry. Kept
  /// only for traceability -- it is never used to resolve price or title.
  TextColumn get productId => text().references(Products, #id).nullable()();

  /// Ordering within the invoice, so lines render as the user arranged them.
  IntColumn get position => integer().withDefault(const Constant(0))();

  // ---- snapshots (D-004) --------------------------------------------------
  TextColumn get titleSnapshot => text().withLength(min: 1, max: 200)();

  TextColumn get unitSnapshot => text().withLength(min: 1, max: 30)();

  IntColumn get unitPriceRial => integer()();

  /// Quantity scaled by 1000 (§4): `1.5` is stored as `1500`. Integer, so a
  /// fractional kilogram or hour never introduces floating point into the
  /// money path.
  IntColumn get quantityMilli => integer()();

  /// Absolute Rial. A percentage entered by the user is resolved to an amount
  /// at entry time and **both** are stored (§4 step 2).
  IntColumn get discountRial => integer().withDefault(const Constant(0))();

  IntColumn get discountPercentBp => integer().nullable()();

  /// The tax rate that actually applied, resolved at creation time in the
  /// order item -> invoice -> settings default, and snapshotted here so a
  /// later settings change cannot alter an issued invoice (§4 step 6).
  IntColumn get resolvedTaxRateBp => integer()();

  // ---- computed line amounts ---------------------------------------------
  IntColumn get lineNetRial => integer().withDefault(const Constant(0))();

  IntColumn get lineTaxRial => integer().withDefault(const Constant(0))();

  IntColumn get lineTotalRial => integer().withDefault(const Constant(0))();
}
