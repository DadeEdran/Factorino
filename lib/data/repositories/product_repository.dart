import '../models/product.dart';

/// The product and service catalogue boundary.
///
/// Like every interface in this directory, it must not import drift -- see the
/// note on `CustomerRepository`.
abstract interface class ProductRepository {
  Stream<List<Product>> watchAll({int limit = 100, int offset = 0});

  /// Normalization-insensitive search over the catalogue (§9, D-025), folded
  /// by the same `searchKey` that wrote `search_name`.
  Stream<List<Product>> watchSearch(
    String term, {
    int limit = 100,
    int offset = 0,
  });

  Future<List<Product>> search(String term, {int limit = 100, int offset = 0});

  Future<Product?> findById(String id);

  Future<int> count();

  /// The number of catalogue entries, as a **live** query — see the note on
  /// `CustomerRepository.watchCount`.
  Stream<int> watchCount();

  Future<Product> create(ProductDraft draft);

  /// Replaces the editable fields of [id], **rewriting `search_name`** from the
  /// new name.
  ///
  /// Changing a price here does not touch any invoice: lines snapshot their
  /// price at creation time (D-004). That is the point of the redundancy.
  Future<Product> update(String id, ProductDraft draft);

  /// Soft delete only (D-003) -- a product referenced by an invoice line must
  /// survive it.
  Future<void> softDelete(String id);
}
