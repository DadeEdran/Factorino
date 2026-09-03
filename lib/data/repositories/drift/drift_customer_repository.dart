import 'package:drift/drift.dart';

import '../../../core/formatting/iranian_phone.dart';
import '../../../core/formatting/persian_text.dart';
import '../../database/app_database.dart';
import '../../database/soft_delete.dart';
import '../../database/tables/sync_columns.dart';
import '../../models/customer.dart';
import '../customer_repository.dart';
import 'mappers.dart';

/// Drift-backed [CustomerRepository].
///
/// Two rules are held here rather than asked of callers:
///
/// * **`search_name` is written through [searchKeyOf] on create *and* on
///   update.** The update path is the one that gets missed: a create that
///   forgot it produces a customer who is never found, which someone notices
///   immediately, while an update that forgets it leaves the index matching
///   the *old* name -- so the customer is still found, by the wrong term, and
///   nothing looks broken (D-025, D-029).
/// * **Every read goes through `selectAlive`** (D-003), so a soft-deleted
///   customer cannot reappear in a list or a search.
class DriftCustomerRepository implements CustomerRepository {
  DriftCustomerRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Customer>> watchAll({int limit = 100, int offset = 0}) {
    return _aliveQuery(limit: limit, offset: offset).watch().map(_mapRows);
  }

  @override
  Stream<List<Customer>> watchSearch(
    String term, {
    int limit = 100,
    int offset = 0,
  }) {
    final key = searchKey(term);
    if (key.isEmpty) return watchAll(limit: limit, offset: offset);

    return (_aliveQuery(
      limit: limit,
      offset: offset,
    )..where((row) => row.searchName.like('%$key%'))).watch().map(_mapRows);
  }

  @override
  Future<List<Customer>> search(
    String term, {
    int limit = 100,
    int offset = 0,
  }) {
    return watchSearch(term, limit: limit, offset: offset).first;
  }

  @override
  Future<Customer?> findById(String id) async {
    final row = await (_db.selectAlive(
      _db.customers,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    return row == null ? null : customerFromRow(row);
  }

  @override
  Future<int> count() => _db.countAlive(_db.customers).getSingle();

  @override
  Stream<int> watchCount() => _db.countAlive(_db.customers).watchSingle();

  @override
  Future<Customer> create(CustomerDraft draft) async {
    final row = await _db
        .into(_db.customers)
        .insertReturning(
          CustomersCompanion.insert(
            fullName: draft.fullName.trim(),
            mobile: Value(_normalizedMobile(draft)),
            companyName: Value(_trimToNull(draft.companyName)),
            address: Value(_trimToNull(draft.address)),
            nationalId: Value(_trimToNull(draft.nationalId)),
            notes: Value(_trimToNull(draft.notes)),
            searchName: Value(_searchNameFor(draft)),
          ),
        );
    return customerFromRow(row);
  }

  @override
  Future<Customer> update(String id, CustomerDraft draft) async {
    final updated =
        await (_db.update(_db.customers)..where((r) => r.id.equals(id))).write(
          CustomersCompanion(
            fullName: Value(draft.fullName.trim()),
            mobile: Value(_normalizedMobile(draft)),
            companyName: Value(_trimToNull(draft.companyName)),
            address: Value(_trimToNull(draft.address)),
            nationalId: Value(_trimToNull(draft.nationalId)),
            notes: Value(_trimToNull(draft.notes)),
            // Rewritten from the new name, in the same statement as the name
            // itself, so the two cannot diverge even for an instant.
            searchName: Value(_searchNameFor(draft)),
            updatedAt: Value(nowMillis()),
          ),
        );

    if (updated == 0) {
      throw StateError('no customer with id $id');
    }
    final customer = await findById(id);
    if (customer == null) {
      throw StateError('customer $id disappeared during update');
    }
    return customer;
  }

  @override
  Future<void> softDelete(String id) async {
    await (_db.update(_db.customers)..where((r) => r.id.equals(id))).write(
      CustomersCompanion(
        deletedAt: Value(nowMillis()),
        updatedAt: Value(nowMillis()),
      ),
    );
  }

  /// Newest first, and always `deleted_at IS NULL`.
  SimpleSelectStatement<$CustomersTable, CustomerRow> _aliveQuery({
    required int limit,
    required int offset,
  }) {
    return _db.selectAlive(_db.customers)
      ..orderBy(<OrderClauseGenerator<$CustomersTable>>[
        (row) => OrderingTerm.desc(row.createdAt),
      ])
      ..limit(limit, offset: offset);
  }

  List<Customer> _mapRows(List<CustomerRow> rows) =>
      rows.map(customerFromRow).toList();

  /// Both searchable fields, folded by the one normalizer (D-029).
  String _searchNameFor(CustomerDraft draft) =>
      searchKeyOf(<String?>[draft.fullName, draft.companyName]);

  /// Stored canonically as `09xxxxxxxxx`, or kept as typed if it is not a
  /// recognisable Iranian mobile.
  ///
  /// Not rejected here: validation belongs at the form boundary, where the user
  /// can be told in Persian. A repository that silently dropped an
  /// unrecognised number would lose data the user deliberately entered -- an
  /// international number for a foreign client, for instance.
  String? _normalizedMobile(CustomerDraft draft) {
    final raw = _trimToNull(draft.mobile);
    if (raw == null) return null;
    return normalizeIranianMobile(raw) ?? raw;
  }

  String? _trimToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
