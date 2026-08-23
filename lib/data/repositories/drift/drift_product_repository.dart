import 'package:drift/drift.dart';

import '../../../core/formatting/persian_text.dart';
import '../../database/app_database.dart';
import '../../database/soft_delete.dart';
import '../../database/tables/sync_columns.dart';
import '../../models/product.dart';
import '../product_repository.dart';
import 'mappers.dart';

/// Drift-backed [ProductRepository].
///
/// Same two rules as the customer repository: `search_name` is written through
/// the one normalizer on create *and* update, and every read goes through
/// `selectAlive`.
class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Product>> watchAll({int limit = 100, int offset = 0}) {
    return _aliveQuery(limit: limit, offset: offset).watch().map(_mapRows);
  }

  @override
  Stream<List<Product>> watchSearch(
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
  Future<List<Product>> search(String term, {int limit = 100, int offset = 0}) {
    return watchSearch(term, limit: limit, offset: offset).first;
  }

  @override
  Future<Product?> findById(String id) async {
    final row = await (_db.selectAlive(
      _db.products,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    return row == null ? null : productFromRow(row);
  }

  @override
  Future<int> count() => _db.countAlive(_db.products).getSingle();

  @override
  Future<Product> create(ProductDraft draft) async {
    final row = await _db
        .into(_db.products)
        .insertReturning(
          ProductsCompanion.insert(
            name: draft.name.trim(),
            type: draft.type,
            priceRial: draft.price.rial,
            unit: draft.unit.trim(),
            description: Value(_trimToNull(draft.description)),
            searchName: Value(searchKeyOf(<String?>[draft.name])),
          ),
        );
    return productFromRow(row);
  }

  @override
  Future<Product> update(String id, ProductDraft draft) async {
    final updated =
        await (_db.update(_db.products)..where((r) => r.id.equals(id))).write(
          ProductsCompanion(
            name: Value(draft.name.trim()),
            type: Value(draft.type),
            priceRial: Value(draft.price.rial),
            unit: Value(draft.unit.trim()),
            description: Value(_trimToNull(draft.description)),
            // Rewritten from the new name, in the same statement.
            searchName: Value(searchKeyOf(<String?>[draft.name])),
            updatedAt: Value(nowMillis()),
          ),
        );

    if (updated == 0) {
      throw StateError('no product with id $id');
    }
    final product = await findById(id);
    if (product == null) {
      throw StateError('product $id disappeared during update');
    }
    return product;
  }

  @override
  Future<void> softDelete(String id) async {
    await (_db.update(_db.products)..where((r) => r.id.equals(id))).write(
      ProductsCompanion(
        deletedAt: Value(nowMillis()),
        updatedAt: Value(nowMillis()),
      ),
    );
  }

  SimpleSelectStatement<$ProductsTable, ProductRow> _aliveQuery({
    required int limit,
    required int offset,
  }) {
    return _db.selectAlive(_db.products)
      ..orderBy(<OrderClauseGenerator<$ProductsTable>>[
        (row) => OrderingTerm.desc(row.createdAt),
      ])
      ..limit(limit, offset: offset);
  }

  List<Product> _mapRows(List<ProductRow> rows) =>
      rows.map(productFromRow).toList();

  String? _trimToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
