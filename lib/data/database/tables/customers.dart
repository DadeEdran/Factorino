import 'package:drift/drift.dart';

import 'sync_columns.dart';

/// People and businesses invoices are issued to.
///
/// Holds third-party personal identifiers (national ID, economic ID, phone
/// numbers), which is a large part of why the database is encrypted at rest
/// and why none of these fields may ever be logged.
@TableIndex(name: 'idx_customers_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_customers_search_name', columns: {#searchName})
@DataClassName('CustomerRow')
class Customers extends Table with SyncColumns {
  /// Length limits are enforced at the schema boundary as well as in the UI,
  /// because the UI is not the only writer -- import (Phase 6) is another.
  ///
  /// **Every `max:` below must equal the matching constant in
  /// `data/models/field_limits.dart`, which is what the forms use.** They
  /// cannot reference it directly: `drift_dev` reads this argument with
  /// `readIntLiteral`, which returns `null` for anything but an integer
  /// literal, so a constant here would generate a column with *no* length
  /// constraint at all -- silently. `test/data/database/field_limits_test.dart`
  /// asks each generated column where it actually starts rejecting values and
  /// fails if the two disagree.
  TextColumn get fullName => text().withLength(min: 1, max: 120)();

  /// Iranian mobile, normalized to `09xxxxxxxxx` before storage (§9). Stored
  /// as text: it is an identifier, not a quantity, and leading zeros matter.
  TextColumn get mobile => text().withLength(max: 20).nullable()();

  TextColumn get companyName => text().withLength(max: 160).nullable()();

  TextColumn get address => text().withLength(max: 500).nullable()();

  /// کد ملی — optional, and checksum-validated at the boundary when present.
  TextColumn get nationalId => text().withLength(max: 10).nullable()();

  TextColumn get notes => text().withLength(max: 2000).nullable()();

  /// [fullName] and [companyName] run through the Persian text normalizer,
  /// so that a customer saved as "علي" is found by typing "علی" (§9).
  ///
  /// Denormalized deliberately: normalizing at query time would defeat the
  /// index and force a full scan. Written by the repository layer, which is
  /// the only writer, so it cannot drift out of sync with [fullName].
  TextColumn get searchName =>
      text().withLength(max: 300).withDefault(const Constant(''))();
}
