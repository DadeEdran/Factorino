import '../models/customer.dart';

/// The customer boundary.
///
/// **This file must not import drift, and neither may any other interface in
/// `data/repositories/`.** That is what makes the project spec's "repositories
/// expose domain models, never Drift-generated row classes" a checkable
/// property rather than a convention: a signature cannot mention a type its
/// library has no access to. `domain_boundary_test.dart` fails the build if an
/// import appears. Implementations live in `repositories/drift/`.
abstract interface class CustomerRepository {
  /// All customers, newest first, as a live query.
  ///
  /// Soft-deleted rows are never included -- every read goes through
  /// `selectAlive` (D-003).
  Stream<List<Customer>> watchAll({int limit = 100, int offset = 0});

  /// Customers matching [term], normalization-insensitive (§9, D-025).
  ///
  /// The term is folded by the same `searchKey` that produced the stored
  /// `search_name`, so a customer saved as `علي` is found by typing `علی`.
  /// An empty or whitespace-only term returns the same as [watchAll].
  Stream<List<Customer>> watchSearch(
    String term, {
    int limit = 100,
    int offset = 0,
  });

  /// The same search, resolved once rather than watched.
  Future<List<Customer>> search(String term, {int limit = 100, int offset = 0});

  Future<Customer?> findById(String id);

  Future<int> count();

  /// Creates a customer and returns it as stored.
  ///
  /// The repository normalizes the mobile number and writes `search_name`; a
  /// caller cannot forget either, because a caller cannot do either.
  Future<Customer> create(CustomerDraft draft);

  /// Replaces the editable fields of [id].
  ///
  /// **Rewrites `search_name` from the new name.** An update that changed a
  /// name without it would leave the index matching the old spelling and not
  /// the new one -- silently, and for as long as the row exists.
  Future<Customer> update(String id, CustomerDraft draft);

  /// Soft-deletes [id] (D-003). Never a hard delete: a customer referenced by
  /// an invoice must survive, and a hard delete cannot be propagated to
  /// another device.
  Future<void> softDelete(String id);
}
