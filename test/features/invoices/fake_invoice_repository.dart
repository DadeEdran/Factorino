import 'dart:async';

import 'package:factorino/core/date/jalali_period.dart';
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
  }) : _pending = false,
       _failure = null;

  /// A query that never answers, for the loading state.
  FakeInvoiceRepository.pending()
    : _items = const <InvoiceListItem>[],
      outstandingRial = 0,
      issuedTotalRial = 0,
      issuedCount = 0,
      _pending = true,
      _failure = null;

  FakeInvoiceRepository.failing(this._failure)
    : _items = const <InvoiceListItem>[],
      outstandingRial = 0,
      issuedTotalRial = 0,
      issuedCount = 0,
      _pending = false;

  final List<InvoiceListItem> _items;
  final bool _pending;
  final Object? _failure;

  final int outstandingRial;
  final int issuedTotalRial;
  final int issuedCount;

  /// What the last list query actually asked for. This is the assertion that
  /// paging reaches the database rather than stopping in Dart (D-038).
  int? lastLimit;

  /// The period the last aggregate was asked for, so a test can assert the
  /// dashboard resolved a **Jalali** month rather than a Gregorian one.
  InstantRange? lastPeriod;

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

  // ---- not exercised by these tests --------------------------------------

  @override
  Future<InvoiceDetail?> findDetail(String id) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Stream<InvoiceDetail?> watchDetail(String id) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Future<InvoiceCreationResult> create(
    InvoiceDraft draft, {
    InvoiceStatus status = InvoiceStatus.draft,
  }) => throw UnimplementedError('not exercised by these tests');

  @override
  Future<InvoiceCreationResult> updateDraft(String id, InvoiceDraft draft) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Future<Invoice> issue(String id) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Future<Invoice> cancel(String id) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Future<void> softDeleteDraft(String id) =>
      throw UnimplementedError('not exercised by these tests');
}
