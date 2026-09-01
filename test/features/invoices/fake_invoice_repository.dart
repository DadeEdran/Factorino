import 'dart:async';

import 'package:factorino/core/date/jalali_period.dart';
import 'package:factorino/core/money/invoice_calculator.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/customer_totals.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_detail.dart';
import 'package:factorino/data/models/invoice_draft.dart';
import 'package:factorino/data/models/invoice_list_item.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/repositories/invoice_repository.dart';

/// An [InvoiceRepository] that answers from a list.
///
/// Implements the interface rather than mocking it, so this file stops
/// compiling if the contract underneath it moves — which is the notification a
/// test should get when that happens, instead of a green run against a
/// signature nobody has any more.
class FakeInvoiceRepository implements InvoiceRepository {
  FakeInvoiceRepository(
    this._items, {
    this.outstandingRial = 0,
    this.issuedTotalRial = 0,
    this.issuedCount = 0,
    this.customerTotals = const CustomerTotals(
      billed: Money.zero,
      outstanding: Money.zero,
    ),
  }) : _pending = false,
       _failure = null;

  /// A query that never answers, for the loading state.
  FakeInvoiceRepository.pending()
    : _items = const <InvoiceListItem>[],
      outstandingRial = 0,
      issuedTotalRial = 0,
      issuedCount = 0,
      customerTotals = const CustomerTotals(
        billed: Money.zero,
        outstanding: Money.zero,
      ),
      _pending = true,
      _failure = null;

  FakeInvoiceRepository.failing(this._failure)
    : _items = const <InvoiceListItem>[],
      outstandingRial = 0,
      issuedTotalRial = 0,
      issuedCount = 0,
      customerTotals = const CustomerTotals(
        billed: Money.zero,
        outstanding: Money.zero,
      ),
      _pending = false;

  final List<InvoiceListItem> _items;
  final bool _pending;
  final Object? _failure;

  final int outstandingRial;
  final int issuedTotalRial;
  final int issuedCount;
  final CustomerTotals customerTotals;

  /// What the last list query actually asked for. This is the assertion that
  /// paging reaches the database rather than stopping in Dart (D-038).
  int? lastLimit;

  /// The period the last aggregate was asked for, so a test can assert the
  /// dashboard resolved a **Jalali** month rather than a Gregorian one.
  InstantRange? lastPeriod;

  /// Which customer the last totals query was scoped to -- the assertion that a
  /// customer's page asks about *that* customer rather than about the business.
  String? lastCustomerTotalsId;

  @override
  Stream<List<InvoiceListItem>> watchList({int limit = 100, int offset = 0}) {
    lastLimit = limit;
    return _emit(_items.skip(offset).take(limit).toList());
  }

  @override
  Stream<List<Invoice>> watchAll({int limit = 100, int offset = 0}) {
    return _emit(_invoices.take(limit).toList());
  }

  @override
  Stream<List<Invoice>> watchInPeriod(
    InstantRange period, {
    int limit = 100,
    int offset = 0,
  }) {
    lastPeriod = period;
    return _emit(_invoices.take(limit).toList());
  }

  @override
  Stream<List<Invoice>> watchForCustomer(String customerId) => _emit(_invoices);

  @override
  Stream<int> watchCount() => _emit(_items.length);

  @override
  Stream<int> watchIssuedCountInPeriod(InstantRange period) {
    lastPeriod = period;
    return _emit(issuedCount);
  }

  @override
  Stream<int> watchOutstandingRial() => _emit(outstandingRial);

  @override
  Stream<CustomerTotals> watchCustomerTotals(String customerId) {
    lastCustomerTotalsId = customerId;
    return _emit(customerTotals);
  }

  @override
  Stream<int> watchTotalIssuedRial(InstantRange period) {
    lastPeriod = period;
    return _emit(issuedTotalRial);
  }

  @override
  Future<int> totalIssuedRial(InstantRange period) async {
    lastPeriod = period;
    return issuedTotalRial;
  }

  @override
  Future<int> count() async => _items.length;

  @override
  Future<Invoice?> findById(String id) async {
    final Iterable<Invoice> found = _invoices.where(
      (Invoice invoice) => invoice.id == id,
    );
    return found.isEmpty ? null : found.first;
  }

  List<Invoice> get _invoices =>
      _items.map((InvoiceListItem item) => item.invoice).toList();

  Stream<T> _emit<T>(T value) {
    if (_failure != null) return Stream<T>.error(_failure);
    if (_pending) {
      // Never emits and never closes, so the provider stays in its loading
      // state for as long as the test wants to look at it.
      return StreamController<T>().stream;
    }
    return Stream<T>.value(value);
  }

  /// What [watchDetail] and [findDetail] answer with, keyed by invoice id.
  ///
  /// Assigned rather than passed to the constructor, because most tests here
  /// never open one invoice and the list fixtures would all have to grow a
  /// parameter they ignore. An id with no entry answers **null**, which is the
  /// stale-deep-link case the detail screen has to handle and would otherwise
  /// need a second fake to reach.
  final Map<String, InvoiceDetail> details = <String, InvoiceDetail>{};

  @override
  Future<InvoiceDetail?> findDetail(String id) async => details[id];

  @override
  Stream<InvoiceDetail?> watchDetail(String id) => _emit(details[id]);

  // ---- not exercised by these tests --------------------------------------

  /// Whether a write should fail, for the screen's «ذخیره ممکن نشد» path.
  bool failWrites = false;

  /// Every draft handed to [create], in order.
  ///
  /// Recorded rather than asserted here, because what matters at the screen is
  /// **what it sent** — a screen that writes a different invoice from the one
  /// it previewed is the defect, and `invoice_preview_matches_write_test.dart`
  /// pins the other half against the real database.
  final List<InvoiceDraft> createdDrafts = <InvoiceDraft>[];

  /// The ids passed to [issue], in order. Empty is the assertion that matters
  /// when a confirmation was declined.
  final List<String> issuedIds = <String>[];

  @override
  Future<InvoiceCreationResult> create(
    InvoiceDraft draft, {
    InvoiceStatus status = InvoiceStatus.draft,
  }) async {
    if (failWrites) throw StateError('write refused by the fake');
    createdDrafts.add(draft);
    return InvoiceCreationResult(
      invoice: _invoice(status: status),
      // The engine's warnings reach the screen from the live preview, not from
      // the write result, so there is nothing to synthesize here.
      warnings: const <InvoiceWarning>[],
    );
  }

  @override
  Future<InvoiceCreationResult> updateDraft(String id, InvoiceDraft draft) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Future<Invoice> issue(String id) async {
    if (failWrites) throw StateError('write refused by the fake');
    issuedIds.add(id);
    return _invoice(status: InvoiceStatus.unpaid, number: issuedNumber);
  }

  /// The number [issue] hands back. Fixed rather than allocated: allocation is
  /// the repository's own concern and has its own tests against the real
  /// database (D-013, D-048).
  static const String issuedNumber = 'INV-1405-0001';

  Invoice _invoice({required InvoiceStatus status, String? number}) {
    final DateTime now = DateTime.utc(2026, 8, 24, 12);
    return Invoice(
      id: 'invoice-1',
      number: number,
      numberYear: number == null ? null : 1405,
      numberSequence: number == null ? null : 1,
      customerId: 'customer-1',
      issueDate: now,
      status: status,
      discount: Money.zero,
      grossTotal: Money.zero,
      subtotal: Money.zero,
      totalDiscount: Money.zero,
      totalTax: Money.zero,
      roundingAdjustment: Money.zero,
      grandTotal: Money.zero,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Invoice> cancel(String id) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Future<void> softDeleteDraft(String id) =>
      throw UnimplementedError('not exercised by these tests');
}
