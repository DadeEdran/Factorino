import 'package:drift/drift.dart';

import 'invoices.dart';
import 'sync_columns.dart';

/// How a payment reached the business.
///
/// Stored as the enum index: never reorder, only append.
enum PaymentMethod { cash, cardTransfer, bankTransfer, cheque, other }

/// Money received against an invoice.
///
/// The sum of these rows is what derives an invoice's `partiallyPaid` / `paid`
/// status, recomputed and persisted on every payment write.
@TableIndex(name: 'idx_payments_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_payments_invoice', columns: {#invoiceId})
@TableIndex(name: 'idx_payments_paid_at', columns: {#paidAt})
class Payments extends Table with SyncColumns {
  TextColumn get invoiceId =>
      text().references(Invoices, #id, onDelete: KeyAction.cascade)();

  /// Integer Rial (D-002).
  IntColumn get amountRial => integer()();

  /// Epoch milliseconds, UTC (D-005).
  IntColumn get paidAt => integer()();

  IntColumn get method => intEnum<PaymentMethod>()();

  TextColumn get note => text().withLength(max: 500).nullable()();
}
