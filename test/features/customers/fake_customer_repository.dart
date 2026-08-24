import 'dart:async';

import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/repositories/customer_repository.dart';

/// A [CustomerRepository] that answers from a list.
///
/// Implements the interface rather than mocking it, so this file would stop
/// compiling if the contract underneath it moved — which is the notification a
/// test should get when that happens, instead of a green run against a
/// signature nobody has any more.
///
/// Shared by the list and detail suites. Two fakes for one interface is how the
/// two suites come to disagree about what the repository does, and the one that
/// is wrong is whichever nobody looked at last.
class FakeCustomerRepository implements CustomerRepository {
  FakeCustomerRepository(this._all) : _pending = false, _failure = null;

  /// A query that never answers, for the loading state.
  FakeCustomerRepository.pending()
    : _all = const <Customer>[],
      _pending = true,
      _failure = null;

  FakeCustomerRepository.failing(this._failure)
    : _all = const <Customer>[],
      _pending = false;

  final List<Customer> _all;
  final bool _pending;
  final Object? _failure;

  /// What the last query actually asked the database for. This is the
  /// assertion that paging reaches SQL rather than stopping in Dart.
  int? lastLimit;
  String? lastSearchTerm;

  /// Ids passed to [softDelete], so a test can assert the delete happened
  /// rather than only that the dialog closed.
  final List<String> deleted = <String>[];

  @override
  Stream<List<Customer>> watchAll({int limit = 100, int offset = 0}) {
    lastLimit = limit;
    lastSearchTerm = null;
    return _emit(_all.skip(offset).take(limit).toList());
  }

  @override
  Stream<List<Customer>> watchSearch(
    String term, {
    int limit = 100,
    int offset = 0,
  }) {
    lastLimit = limit;
    lastSearchTerm = term;
    final List<Customer> matched = _all
        .where((Customer c) => c.fullName.contains(term))
        .skip(offset)
        .take(limit)
        .toList();
    return _emit(matched);
  }

  Stream<List<Customer>> _emit(List<Customer> value) {
    if (_failure != null) {
      return Stream<List<Customer>>.error(_failure);
    }
    if (_pending) {
      // Never emits and never closes, so the provider stays in its loading
      // state for as long as the test wants to look at it.
      return StreamController<List<Customer>>().stream;
    }
    return Stream<List<Customer>>.value(value);
  }

  @override
  Future<List<Customer>> search(
    String term, {
    int limit = 100,
    int offset = 0,
  }) => watchSearch(term, limit: limit, offset: offset).first;

  @override
  Future<Customer?> findById(String id) {
    if (_failure != null) return Future<Customer?>.error(_failure);
    // The same never-answering behaviour the streams have, so the detail
    // screen's loading state can be looked at.
    if (_pending) return Completer<Customer?>().future;

    final Iterable<Customer> found = _all.where((Customer c) => c.id == id);
    return Future<Customer?>.value(found.isEmpty ? null : found.first);
  }

  @override
  Future<int> count() async => _all.length;

  @override
  Stream<int> watchCount() => Stream<int>.value(_all.length);

  @override
  Future<Customer> create(CustomerDraft draft) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Future<Customer> update(String id, CustomerDraft draft) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Future<void> softDelete(String id) async => deleted.add(id);
}
