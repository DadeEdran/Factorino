import 'package:drift/drift.dart';

import '../../../core/date/jalali_instant.dart';
import '../../../core/date/jalali_period.dart';
import '../../../core/money/invoice_calculator.dart';
import '../../../core/money/money.dart';
import '../../database/app_database.dart';
import '../../database/soft_delete.dart';
import '../../database/tables/sync_columns.dart';
import '../../models/app_settings.dart';
import '../../models/customer.dart';
import '../../models/customer_snapshot.dart';
import '../../models/customer_totals.dart';
import '../../models/invoice.dart';
import '../../models/invoice_detail.dart';
import '../../models/invoice_draft.dart';
import '../../models/invoice_list_item.dart';
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
/// * **Number allocation happens on issue, inside its transaction** (D-013,
///   D-048). A draft carries no number at all, because allocating one at
///   creation meant an abandoned draft consumed a number permanently. Reading
///   the maximum sequence and writing the row must not be separable, or two
///   invoices issued in the same instant take the same number and the unique
///   index turns that into a failed save.
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
  Stream<List<InvoiceListItem>> watchList({int limit = 100, int offset = 0}) {
    // One join, not one query per row. `_aliveQuery` already carries the
    // ordering, the soft-delete filter and the LIMIT, and `join` keeps all
    // three -- drift copies them onto the joined statement -- so the paging
    // still reaches SQL exactly as it does for the plain list.
    //
    // The customers side is deliberately **not** filtered by `deleted_at`. A
    // customer referenced by an invoice is soft-deleted only, never removed
    // (D-003), and the Persian copy on the delete dialog promises the invoices
    // survive untouched. Filtering here would drop those invoices out of the
    // list entirely the moment their customer was deleted -- making that
    // promise false, silently, and only for the users who took it at its word.
    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _aliveQuery(limit: limit, offset: offset).join(
          <Join<HasResultSet, dynamic>>[
            innerJoin(
              _db.customers,
              _db.customers.id.equalsExp(_db.invoices.customerId),
            ),
          ],
        );

    return query.watch().map(
      (List<TypedResult> rows) => rows
.map(
            (TypedResult row) => InvoiceListItem(
              invoice: invoiceFromRow(row.readTable(_db.invoices)),
              // The **live** name. The document's name, when it differs, is
              // the snapshot on the invoice itself, and `InvoiceListItem`
              // applies that rule rather than this query (D-052).
              liveCustomerName: row.readTable(_db.customers).fullName,
            ),
          )
.toList(),
    );
  }

  @override
  Future<Invoice?> findById(String id) async {
    final row = await _findRow(id);
    return row == null ? null : invoiceFromRow(row);
  }

  @override
  Future<int> count() => _db.countAlive(_db.invoices).getSingle();

  @override
  Stream<int> watchCount() => _db.countAlive(_db.invoices).watchSingle();

  @override
  Stream<int> watchIssuedCountInPeriod(InstantRange period) {
    final Expression<int> counter = _db.invoices.id.count();
    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _db.selectOnlyAlive(_db.invoices)
..addColumns(<Expression<Object>>[counter])
..where(_issuedInPeriod(period));

    // Counted in SQL, over exactly the population `totalIssuedRial` sums, so
    // the two tiles that sit beside each other describe the same documents.
    return query.watchSingle().map((TypedResult row) => row.read(counter) ?? 0);
  }

  @override
  Stream<int> watchOutstandingRial() {
    // What is still owed, in one statement:
    //
    //   SELECT SUM(grand_total_rial
    //              - COALESCE((SELECT SUM(amount_rial) FROM payments
    //                          WHERE deleted_at IS NULL
    //                            AND invoice_id = invoices.id), 0))
    //   FROM invoices
    //   WHERE deleted_at IS NULL AND status IN (unpaid, partiallyPaid)
    //
    // A correlated subquery rather than a join to payments, because joining
    // would multiply each invoice's grand total by its number of payment rows
    // -- a defect invisible until an invoice takes its second instalment, and
    // one that then overstates the figure the user trusts most.
    //
    // One statement rather than two streams subtracted in Dart: two streams
    // settle at different moments, and in between the tile would show a number
    // belonging to neither state.
    final Expression<int> paidOnThisInvoice = subqueryExpression<int>(
      _db.selectOnlyAlive(_db.payments)
..addColumns(<Expression<Object>>[_db.payments.amountRial.sum()])
..where(_db.payments.invoiceId.equalsExp(_db.invoices.id)),
    );
    final Expression<int> owed =
        (_db.invoices.grandTotalRial -
                coalesce<int>(<Expression<int>>[
                  paidOnThisInvoice,
                  const Constant<int>(0),
                ]))
.sum();

    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _db.selectOnlyAlive(_db.invoices)
..addColumns(<Expression<Object>>[owed])
..where(_db.invoices.status.isInValues(kOutstandingInvoiceStatuses));

    return query.watchSingle().map((TypedResult row) => row.read(owed) ?? 0);
  }

  @override
  Stream<CustomerTotals> watchCustomerTotals(String customerId) {
    // Two aggregates over two different populations, in one statement:
    //
    //   SELECT SUM(grand_total_rial) FILTER (WHERE status IN (issued)),
    //          SUM(grand_total_rial - COALESCE((SELECT SUM(amount_rial)
    //                                           FROM payments
    //                                           WHERE deleted_at IS NULL
    //                                             AND invoice_id = invoices.id),
    //                                          0))
    //            FILTER (WHERE status IN (unpaid, partiallyPaid))
    //   FROM invoices
    //   WHERE deleted_at IS NULL AND customer_id = ?
    //
    // `FILTER` rather than two queries, because the two figures sit beside each
    // other on screen and a user reads them together: settled at two instants
    // they would occasionally show a pair that never existed. SQLite has
    // supported it since 3.30 and this application ships 3.53.
    //
    // The correlated subquery is the same one `watchOutstandingRial` uses, and
    // for the same reason: joining to payments would multiply an invoice's
    // grand total by its number of payment rows, which is invisible until an
    // invoice takes its second instalment and then overstates what is owed.
    final Expression<int> paidOnThisInvoice = subqueryExpression<int>(
      _db.selectOnlyAlive(_db.payments)
..addColumns(<Expression<Object>>[_db.payments.amountRial.sum()])
..where(_db.payments.invoiceId.equalsExp(_db.invoices.id)),
    );

    // Issued only (D-039). A draft is not yet a claim on anyone, so a
    // customer's billed history must not climb while the user is still typing.
    final Expression<int> billed = _db.invoices.grandTotalRial.sum(
      filter: _db.invoices.status.isInValues(kIssuedInvoiceStatuses),
    );
    final Expression<int> outstanding =
        (_db.invoices.grandTotalRial -
                coalesce<int>(<Expression<int>>[
                  paidOnThisInvoice,
                  const Constant<int>(0),
                ]))
.sum(
              filter: _db.invoices.status.isInValues(
                kOutstandingInvoiceStatuses,
              ),
            );

    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _db.selectOnlyAlive(_db.invoices)
..addColumns(<Expression<Object>>[billed, outstanding])
..where(_db.invoices.customerId.equals(customerId));

    return query.watchSingle().map(
      (TypedResult row) => CustomerTotals(
        // A customer with no invoices produces one row of nulls rather than no
        // row, so the zero is a real answer and not a missing one.
        billed: Money.rial(row.read(billed) ?? 0),
        outstanding: Money.rial(row.read(outstanding) ?? 0),
      ),
    );
  }

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
    final Expression<int> total = _db.invoices.grandTotalRial.sum();

    // Aggregated in SQL rather than by summing rows in Dart (§13).
    final TypedResult row = await _issuedTotalQuery(period, total).getSingle();
    return row.read(total) ?? 0;
  }

  @override
  Stream<int> watchTotalIssuedRial(InstantRange period) {
    final Expression<int> total = _db.invoices.grandTotalRial.sum();
    // Built by the same helper as the one-shot read above, so the live figure
    // and the resolved one cannot come to answer differently.
    return _issuedTotalQuery(
      period,
      total,
    ).watchSingle().map((TypedResult row) => row.read(total) ?? 0);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _issuedTotalQuery(
    InstantRange period,
    Expression<int> total,
  ) {
    return _db.selectOnlyAlive(_db.invoices)
..addColumns(<Expression<Object>>[total])
..where(_issuedInPeriod(period));
  }

  /// Issued inside [period] -- drafts and cancellations excluded (D-039).
  ///
  /// The range arrives already computed in the Jalali calendar (D-006); this
  /// only applies it, half-open exactly as it is defined.
  Expression<bool> _issuedInPeriod(InstantRange period) {
    return _db.invoices.status.isInValues(kIssuedInvoiceStatuses) &
        _db.invoices.issueDate.isBiggerOrEqualValue(period.startMillis) &
        _db.invoices.issueDate.isSmallerThanValue(period.endMillis);
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

      // A draft gets **no** number (D-048). Allocating one here meant that a
      // user who opened the form and changed their mind consumed a number
      // permanently -- the unique index covers soft-deleted rows, so the gap
      // could never be reclaimed. Anything created already issued still takes
      // its number here, because it is a document from the moment it exists.
      final InvoiceNumber? number = status == InvoiceStatus.draft
          ? null
: await _allocateNumber(draft.issueDate, settings);

      // An invoice created already issued is a document from the moment it
      // exists, so it takes its party snapshot here for the same reason it
      // takes its number here (D-052). A draft takes neither.
      final CustomerSnapshot? snapshot = status == InvoiceStatus.draft
          ? null
: CustomerSnapshot.of(await _requireCustomer(draft.customerId));

      final row = await _db
.into(_db.invoices)
.insertReturning(
            InvoicesCompanion.insert(
              number: Value(number?.formatted),
              numberYear: Value(number?.year),
              numberSequence: Value(number?.sequence),
              customerId: draft.customerId,
              customerNameSnapshot: Value(snapshot?.fullName),
              customerCompanySnapshot: Value(snapshot?.companyName),
              customerNationalIdSnapshot: Value(snapshot?.nationalId),
              customerEconomicIdSnapshot: Value(snapshot?.economicId),
              customerAddressSnapshot: Value(snapshot?.address),
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

  /// Issuing is where a number is allocated (D-048).
  ///
  /// Allocation and the status change are one transaction for the reason
  /// D-013 gives: reading `MAX(number_sequence)` and writing the row must not
  /// be separable, or two invoices issued in the same instant take the same
  /// number. The year is the **Jalali** year of the invoice's own issue date,
  /// not of today — issuing a document dated before Nowruz must not put it in
  /// the new year's sequence.
  @override
  Future<Invoice> issue(String id) {
    return _db.transaction(() async {
      final existing = await _requireEditable(id);
      final settings = await _settings.read();

      // The party is frozen here, in the same transaction as the number and
      // for the same reason: this is the instant the invoice stops being a
      // form and becomes a document (D-052). Read now rather than at draft
      // creation, so a draft written before a customer's name was corrected
      // is issued with the correction.
      //
      // Deliberately re-read inside the transaction rather than taken from
      // anything the caller passed, so the snapshot is of the row as it stands
      // at issue and cannot be supplied.
      final CustomerSnapshot snapshot = CustomerSnapshot.of(
        await _requireCustomer(existing.customerId),
      );

      // A draft written before schema v2 already carries a number, because v1
      // allocated one at creation. Keep it: that number is spent either way
      // (D-013), and re-issuing it under a different identity would be worse
      // than the gap the old behaviour left behind.
      final InvoiceNumber? number = existing.number != null
          ? null
: await _allocateNumber(
              instantFromMillis(existing.issueDate),
              settings,
            );

      await (_db.update(_db.invoices)..where((r) => r.id.equals(id))).write(
        InvoicesCompanion(
          number: number == null
              ? const Value<String?>.absent()
: Value<String?>(number.formatted),
          numberYear: number == null
              ? const Value<int?>.absent()
: Value<int?>(number.year),
          numberSequence: number == null
              ? const Value<int?>.absent()
: Value<int?>(number.sequence),
          customerNameSnapshot: Value<String?>(snapshot.fullName),
          customerCompanySnapshot: Value<String?>(snapshot.companyName),
          customerNationalIdSnapshot: Value<String?>(snapshot.nationalId),
          customerEconomicIdSnapshot: Value<String?>(snapshot.economicId),
          customerAddressSnapshot: Value<String?>(snapshot.address),
          status: const Value(InvoiceStatus.unpaid),
          updatedAt: Value(nowMillis()),
        ),
      );

      final row = await _findRow(id);
      if (row == null) throw StateError('invoice $id disappeared');
      return invoiceFromRow(row);
    });
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

    // soft-delete-exempt: an invoice's customer is part of the document. §6
    // guarantees a referenced customer is soft-deleted only, and the delete
    // dialog tells the user in Persian that their invoices survive untouched.
    // Filtering on deleted_at here made an invoice unopenable the moment its
    // customer was deleted -- the promise broken silently, and only for the
    // users who took the app at its word.
    final customerRow = await (_db.select(
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

  /// The customer row an invoice references, for the party snapshot (D-052).
  ///
  /// soft-delete-exempt: an invoice's customer is part of the document, and §6
  /// guarantees a referenced customer is soft-deleted only, never removed. An
  /// invoice that could not be issued because its customer had been deleted
  /// would break the promise the delete dialog makes in Persian — and would do
  /// it at the worst moment, with the invoice already written.
  ///
  /// The foreign key makes the row's absence impossible rather than unlikely,
  /// so a missing one is a broken invariant and is raised as such.
  Future<Customer> _requireCustomer(String customerId) async {
    // soft-delete-exempt: see above -- an invoice's customer is part of the
    // document, and §6 guarantees the row is never hard-deleted (D-003).
    final CustomerRow? row = await (_db.select(
      _db.customers,
    )..where((r) => r.id.equals(customerId))).getSingleOrNull();
    if (row == null) {
      throw StateError('no customer with id $customerId');
    }
    return customerFromRow(row);
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
        // A draft has no sequence (D-048), so the null needs a defined
        // position rather than SQLite's default. `NULLS FIRST` under DESC puts
        // it above the numbered invoices of the same date, which is what it
        // is: nothing was issued after it that day, because it has not been
        // issued at all.
        (row) => OrderingTerm.desc(row.numberSequence, nulls: NullsOrder.first),
        // Two numberless drafts on one date tie on both keys above, and an
        // unspecified order there is a list that reshuffles between reads.
        (row) => OrderingTerm.desc(row.createdAt),
        // `created_at` is milliseconds, and two drafts can be written inside
        // one. The id is unique by construction (D-001), so ending on it makes
        // the order *total* rather than merely usually-defined -- arbitrary
        // between two such drafts, but the same arbitrary answer every read.
        (row) => OrderingTerm.desc(row.id),
      ])
..limit(limit, offset: offset);
  }

  List<Invoice> _mapRows(List<InvoiceRow> rows) =>
      rows.map(invoiceFromRow).toList();
}
