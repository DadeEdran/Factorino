import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../database/soft_delete.dart';
import '../../database/tables/sync_columns.dart';
import '../../models/invoice_status.dart';
import '../../models/payment.dart';
import '../payment_repository.dart';
import 'mappers.dart';

/// Drift-backed [PaymentRepository].
///
/// **The payment and the status it implies are written together or not at
/// all.** Both writes happen inside one transaction, so there is no instant at
/// which a fully-paid invoice reads as unpaid, and no crash that can leave one
/// permanently. The project spec requires the derived status to be recomputed on
/// every payment write; doing it in a second, separate call would satisfy the
/// letter of that and still ship the bug.
class DriftPaymentRepository implements PaymentRepository {
  DriftPaymentRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Payment>> watchForInvoice(String invoiceId) {
    return _aliveQuery(invoiceId)
.watch()
.map((rows) => rows.map(paymentFromRow).toList());
  }

  @override
  Future<List<Payment>> findForInvoice(String invoiceId) async {
    final rows = await _aliveQuery(invoiceId).get();
    return rows.map(paymentFromRow).toList();
  }

  @override
  Future<int> totalPaidRial(String invoiceId) => _totalPaidRial(invoiceId);

  @override
  Future<PaymentResult> record(String invoiceId, PaymentDraft draft) {
    return _db.transaction(() async {
      final invoice = await _requireRow(invoiceId);

      if (invoice.status == InvoiceStatus.draft) {
        throw PaymentNotAccepted(
          invoiceId,
          'a draft is not yet a claim on anyone; issue it first',
        );
      }
      if (invoice.status == InvoiceStatus.cancelled) {
        throw PaymentNotAccepted(
          invoiceId,
          'a cancelled invoice is no longer a claim on anyone',
        );
      }
      if (draft.amount.isZero || draft.amount.isNegative) {
        throw PaymentNotAccepted(
          invoiceId,
          'a payment must be a positive amount',
        );
      }

      final row = await _db
.into(_db.payments)
.insertReturning(
            PaymentsCompanion.insert(
              invoiceId: invoiceId,
              amountRial: draft.amount.rial,
              paidAt: millisFromInstant(draft.paidAt),
              method: draft.method,
              note: Value(draft.note),
            ),
          );

      // Same transaction as the insert above. This is the whole point of the
      // class.
      final updated = await _recomputeStatus(invoiceId);

      return PaymentResult(
        invoice: invoiceFromRow(updated),
        payment: paymentFromRow(row),
      );
    });
  }

  @override
  Future<PaymentResult> softDelete(String paymentId) {
    return _db.transaction(() async {
      final payment = await (_db.selectAlive(
        _db.payments,
      )..where((r) => r.id.equals(paymentId))).getSingleOrNull();
      if (payment == null) {
        throw StateError('no payment with id $paymentId');
      }

      await (_db.update(
        _db.payments,
      )..where((r) => r.id.equals(paymentId))).write(
        PaymentsCompanion(
          deletedAt: Value(nowMillis()),
          updatedAt: Value(nowMillis()),
        ),
      );

      // An unrecorded payment moves the status back exactly as a recorded one
      // moves it forward. Leaving it would strand a `paid` badge on an invoice
      // with nothing paid against it.
      final updated = await _recomputeStatus(payment.invoiceId);

      return PaymentResult(invoice: invoiceFromRow(updated), payment: null);
    });
  }

  /// Recomputes and persists the derived status from the payments on record.
  ///
  /// `draft` and `cancelled` are set by hand and are never derived
  ///, so an invoice in either state is left exactly as it is.
  Future<InvoiceRow> _recomputeStatus(String invoiceId) async {
    final invoice = await _requireRow(invoiceId);

    if (invoice.status == InvoiceStatus.draft ||
        invoice.status == InvoiceStatus.cancelled) {
      return invoice;
    }

    final paid = await _totalPaidRial(invoiceId);
    final InvoiceStatus derived;
    if (paid >= invoice.grandTotalRial && invoice.grandTotalRial > 0) {
      derived = InvoiceStatus.paid;
    } else if (paid > 0) {
      derived = InvoiceStatus.partiallyPaid;
    } else {
      derived = InvoiceStatus.unpaid;
    }

    if (derived == invoice.status) return invoice;

    await (_db.update(
      _db.invoices,
    )..where((r) => r.id.equals(invoiceId))).write(
      InvoicesCompanion(status: Value(derived), updatedAt: Value(nowMillis())),
    );

    return _requireRow(invoiceId);
  }

  /// Summed in SQL rather than by folding rows in Dart (§13).
  Future<int> _totalPaidRial(String invoiceId) async {
    final total = _db.payments.amountRial.sum();
    final query = _db.selectOnlyAlive(_db.payments)
..addColumns(<Expression<Object>>[total])
..where(_db.payments.invoiceId.equals(invoiceId));

    final row = await query.getSingle();
    return row.read(total) ?? 0;
  }

  Future<InvoiceRow> _requireRow(String invoiceId) async {
    final row = await (_db.selectAlive(
      _db.invoices,
    )..where((r) => r.id.equals(invoiceId))).getSingleOrNull();
    if (row == null) throw StateError('no invoice with id $invoiceId');
    return row;
  }

  SimpleSelectStatement<$PaymentsTable, PaymentRow> _aliveQuery(
    String invoiceId,
  ) {
    return _db.selectAlive(_db.payments)
..where((r) => r.invoiceId.equals(invoiceId))
..orderBy(<OrderClauseGenerator<$PaymentsTable>>[
        (r) => OrderingTerm.desc(r.paidAt),
      ]);
  }
}
