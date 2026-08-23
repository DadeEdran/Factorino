import 'package:drift/drift.dart';

import '../../../core/date/jalali_instant.dart';
import '../../../core/date/jalali_period.dart';
import '../../../core/money/invoice_calculator.dart';
import '../../database/app_database.dart';
import '../../database/soft_delete.dart';
import '../../database/tables/sync_columns.dart';
import '../../models/app_settings.dart';
import '../../models/invoice.dart';
import '../../models/invoice_detail.dart';
import '../../models/invoice_draft.dart';
import '../../models/invoice_number.dart';
import '../../models/invoice_status.dart';
import '../invoice_repository.dart';
import '../settings_repository.dart';
import 'mappers.dart';

/// Drift-backed [InvoiceRepository].
///
/// This is where the three things that must not be got wrong live:
///
/// * **Totals come from the money engine, never from the caller.** The draft
///   carries what the user chose; every derived figure is computed here and
///   stored as a snapshot (D-004), so a stored total can never disagree with
///   its lines.
/// * **Number allocation happens inside the write transaction** (D-013).
///   Reading the maximum sequence and inserting the row must not be separable,
///   or two invoices created in the same instant take the same number and the
///   unique index turns that into a failed save.
/// * **Only a draft may be edited or deleted**, enforced here
///   rather than in the UI, because the UI is not the only future writer.
class DriftInvoiceRepository implements InvoiceRepository {
  DriftInvoiceRepository(this._db, this._settings);

  final AppDatabase _db;
  final SettingsRepository _settings;

  // ---- reads --------------------------------------------------------------

  @override
  Stream<List<Invoice>> watchAll({int limit = 100, int offset = 0}) {
    return _aliveQuery(limit: limit, offset: offset).watch().map(_mapRows);
  }

  @override
  Stream<List<Invoice>> watchInPeriod(
    InstantRange period, {
    int limit = 100,
    int offset = 0,
  }) {
    // The range arrives already computed in the Jalali calendar (D-006); this
    // query only applies it. Half-open, exactly as the range is defined.
    return (_aliveQuery(limit: limit, offset: offset)..where(
          (row) =>
              row.issueDate.isBiggerOrEqualValue(period.startMillis) &
              row.issueDate.isSmallerThanValue(period.endMillis),
        ))
.watch()
.map(_mapRows);
  }

  @override
  Stream<List<Invoice>> watchForCustomer(String customerId) {
    return (_aliveQuery(
      limit: 1000,
      offset: 0,
    )..where((row) => row.customerId.equals(customerId))).watch().map(_mapRows);
  }

  @override
  Future<Invoice?> findById(String id) async {
    final row = await _findRow(id);
    return row == null ? null : invoiceFromRow(row);
  }

  @override
  Future<int> count() => _db.countAlive(_db.invoices).getSingle();

  @override
  Future<InvoiceDetail?> findDetail(String id) => _detail(id);

  @override
  Stream<InvoiceDetail?> watchDetail(String id) {
    // Rebuilt whenever any of the three tables changes, so a recorded payment
    // updates the detail view without the screen having to know why.
    return _db
.selectAlive(_db.invoices)
.watch()
.asyncMap((_) => _detail(id))
.distinct((a, b) => identical(a, b));
  }

  @override
  Future<int> totalIssuedRial(InstantRange period) async {
    final total = _db.invoices.grandTotalRial.sum();
    final query = _db.selectOnlyAlive(_db.invoices)
..addColumns(<Expression<Object>>[total])
..where(
        _db.invoices.status.equalsValue(InvoiceStatus.cancelled).not() &
            _db.invoices.issueDate.isBiggerOrEqualValue(period.startMillis) &
            _db.invoices.issueDate.isSmallerThanValue(period.endMillis),
      );

    // Aggregated in SQL rather than by summing rows in Dart (§13).
    final row = await query.getSingle();
    return row.read(total) ?? 0;
  }

  // ---- writes -------------------------------------------------------------

  @override
  Future<InvoiceCreationResult> create(
    InvoiceDraft draft, {
    InvoiceStatus status = InvoiceStatus.draft,
  }) {
    return _db.transaction(() async {
      final settings = await _settings.read();
      final calculated = _calculate(draft, settings);
      final number = await _allocateNumber(draft.issueDate, settings);

      final row = await _db
.into(_db.invoices)
.insertReturning(
            InvoicesCompanion.insert(
              number: number.formatted,
              numberYear: number.year,
              numberSequence: number.sequence,
              customerId: draft.customerId,
              issueDate: millisFromInstant(draft.issueDate),
              status: status,
              dueDate: Value(millisFromInstantOrNull(draft.dueDate)),
              discountRial: Value(calculated.invoiceDiscount.rial),
              discountPercentBp: Value(draft.discountPercentBp),
              taxRateBp: Value(draft.taxRateBp),
              notes: Value(draft.notes),
              subtotalRial: Value(calculated.subtotal.rial),
              totalDiscountRial: Value(calculated.totalDiscount.rial),
              totalTaxRial: Value(calculated.totalTax.rial),
              roundingAdjustmentRial: Value(calculated.roundingAdjustment.rial),
              grandTotalRial: Value(calculated.grandTotal.rial),
            ),
          );

      await _writeItems(row.id, draft, calculated);

      return InvoiceCreationResult(
        invoice: invoiceFromRow(row),
        warnings: calculated.warnings,
      );
    });
  }

  @override
  Future<InvoiceCreationResult> updateDraft(String id, InvoiceDraft draft) {
    return _db.transaction(() async {
      final existing = await _requireEditable(id);
      final settings = await _settings.read();
      final calculated = _calculate(draft, settings);

      await (_db.update(_db.invoices)..where((r) => r.id.equals(id))).write(
        InvoicesCompanion(
          customerId: Value(draft.customerId),
          issueDate: Value(millisFromInstant(draft.issueDate)),
          dueDate: Value(millisFromInstantOrNull(draft.dueDate)),
          discountRial: Value(calculated.invoiceDiscount.rial),
          discountPercentBp: Value(draft.discountPercentBp),
          taxRateBp: Value(draft.taxRateBp),
          notes: Value(draft.notes),
          subtotalRial: Value(calculated.subtotal.rial),
          totalDiscountRial: Value(calculated.totalDiscount.rial),
          totalTaxRial: Value(calculated.totalTax.rial),
          roundingAdjustmentRial: Value(calculated.roundingAdjustment.rial),
          grandTotalRial: Value(calculated.grandTotal.rial),
          updatedAt: Value(nowMillis()),
        ),
      );

      // The old lines are soft-deleted rather than removed (D-003): a hard
      // delete cannot be propagated to another device, so the replaced line
      // would resurrect on the next sync. The number is untouched -- it was
      // allocated at creation and stays with the invoice.
      await (_db.update(
        _db.invoiceItems,
      )..where((r) => r.invoiceId.equals(id) & r.deletedAt.isNull())).write(
        InvoiceItemsCompanion(
          deletedAt: Value(nowMillis()),
          updatedAt: Value(nowMillis()),
        ),
      );

      await _writeItems(id, draft, calculated);

      final updated = await _findRow(id);
      return InvoiceCreationResult(
        invoice: invoiceFromRow(updated ?? existing),
        warnings: calculated.warnings,
      );
    });
  }

  @override
  Future<Invoice> issue(String id) async {
    await _requireEditable(id);
    return _setStatus(id, InvoiceStatus.unpaid);
  }

  @override
  Future<Invoice> cancel(String id) => _setStatus(id, InvoiceStatus.cancelled);

  @override
  Future<void> softDeleteDraft(String id) async {
    await _requireEditable(id);
    await (_db.update(_db.invoices)..where((r) => r.id.equals(id))).write(
      InvoicesCompanion(
        deletedAt: Value(nowMillis()),
        updatedAt: Value(nowMillis()),
      ),
    );
  }

  // ---- internals ----------------------------------------------------------

  /// Runs the §4 engine over a draft, with the settings default terminating
  /// the tax resolution chain (D-026).
  CalculatedInvoice _calculate(InvoiceDraft draft, AppSettings settings) {
    return calculateInvoice(
      InvoiceInput(
        lines: draft.items
.map(
              (item) => InvoiceLineInput(
                unitPrice: item.unitPrice,
                quantityMilli: item.quantityMilli,
                discount: item.discount,
                discountPercentBp: item.discountPercentBp,
                taxRateBp: item.taxRateBp,
              ),
            )
.toList(),
        defaultTaxRateBp: settings.defaultTaxRateBp,
        discount: draft.discount,
        discountPercentBp: draft.discountPercentBp,
        taxRateBp: draft.taxRateBp,
        roundingUnitRial: settings.roundingUnitRial,
      ),
    );
  }

  /// Allocates the next sequence for the draft's **Jalali** year (D-013).
  ///
  /// Called only from inside a transaction. The maximum deliberately includes
  /// soft-deleted invoices: an issued number is spent, and a gap in the
  /// sequence is a far better outcome than two documents sharing one identity.
  Future<InvoiceNumber> _allocateNumber(
    DateTime issueDate,
    AppSettings settings,
  ) async {
    final year = jalaliAt(issueDate).year;
    final highest = _db.invoices.numberSequence.max();

    // soft-delete-exempt: a spent number stays spent. Excluding deleted rows
    // here would reissue the number of a deleted invoice (D-013).
    final query = _db.selectOnly(_db.invoices)
..addColumns(<Expression<Object>>[highest])
..where(_db.invoices.numberYear.equals(year));

    final row = await query.getSingle();
    final next = (row.read(highest) ?? 0) + 1;

    return InvoiceNumber(
      prefix: settings.invoiceNumberPrefix,
      year: year,
      sequence: next,
    );
  }

  Future<void> _writeItems(
    String invoiceId,
    InvoiceDraft draft,
    CalculatedInvoice calculated,
  ) async {
    for (var i = 0; i < draft.items.length; i++) {
      final item = draft.items[i];
      final line = calculated.lines[i];

      await _db
.into(_db.invoiceItems)
.insert(
            InvoiceItemsCompanion.insert(
              invoiceId: invoiceId,
              titleSnapshot: item.title,
              unitSnapshot: item.unit,
              unitPriceRial: item.unitPrice.rial,
              quantityMilli: item.quantityMilli,
              resolvedTaxRateBp: line.resolvedTaxRateBp,
              productId: Value(item.productId),
              position: Value(i),
              // The effective discount, not the entered one (D-027).
              discountRial: Value(line.discount.rial),
              discountPercentBp: Value(item.discountPercentBp),
              lineNetRial: Value(line.netAfterInvoiceDiscount.rial),
              lineTaxRial: Value(line.tax.rial),
              lineTotalRial: Value(line.total.rial),
            ),
          );
    }
  }

  Future<InvoiceDetail?> _detail(String id) async {
    final invoiceRow = await _findRow(id);
    if (invoiceRow == null) return null;

    final customerRow = await (_db.selectAlive(
      _db.customers,
    )..where((r) => r.id.equals(invoiceRow.customerId))).getSingleOrNull();
    if (customerRow == null) return null;

    final itemRows =
        await (_db.selectAlive(_db.invoiceItems)
..where((r) => r.invoiceId.equals(id))
..orderBy(<OrderClauseGenerator<$InvoiceItemsTable>>[
                (r) => OrderingTerm.asc(r.position),
              ]))
.get();

    final paymentRows =
        await (_db.selectAlive(_db.payments)
..where((r) => r.invoiceId.equals(id))
..orderBy(<OrderClauseGenerator<$PaymentsTable>>[
                (r) => OrderingTerm.desc(r.paidAt),
              ]))
.get();

    return InvoiceDetail(
      invoice: invoiceFromRow(invoiceRow),
      customer: customerFromRow(customerRow),
      items: itemRows.map(invoiceItemFromRow).toList(),
      payments: paymentRows.map(paymentFromRow).toList(),
    );
  }

  Future<InvoiceRow?> _findRow(String id) {
    return (_db.selectAlive(
      _db.invoices,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  /// Returns the row only if it is still a draft, and throws otherwise.
  Future<InvoiceRow> _requireEditable(String id) async {
    final row = await _findRow(id);
    if (row == null) throw StateError('no invoice with id $id');
    if (row.status != InvoiceStatus.draft) {
      throw InvoiceNotEditable(id, row.status);
    }
    return row;
  }

  Future<Invoice> _setStatus(String id, InvoiceStatus status) async {
    final updated =
        await (_db.update(_db.invoices)..where((r) => r.id.equals(id))).write(
          InvoicesCompanion(
            status: Value(status),
            updatedAt: Value(nowMillis()),
          ),
        );
    if (updated == 0) throw StateError('no invoice with id $id');

    final row = await _findRow(id);
    if (row == null) throw StateError('invoice $id disappeared');
    return invoiceFromRow(row);
  }

  SimpleSelectStatement<$InvoicesTable, InvoiceRow> _aliveQuery({
    required int limit,
    required int offset,
  }) {
    return _db.selectAlive(_db.invoices)
..orderBy(<OrderClauseGenerator<$InvoicesTable>>[
        (row) => OrderingTerm.desc(row.issueDate),
        (row) => OrderingTerm.desc(row.numberSequence),
      ])
..limit(limit, offset: offset);
  }

  List<Invoice> _mapRows(List<InvoiceRow> rows) =>
      rows.map(invoiceFromRow).toList();
}
