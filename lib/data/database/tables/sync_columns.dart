import 'package:drift/drift.dart';

import '../../../core/utils/uuid.dart';

/// Where a row stands relative to the (future) cloud.
///
/// Stored as the **enum index**, so these values must never be reordered and
/// new ones may only be appended. Unused in Phase 1 but present from the first
/// schema, because adding it later would mean migrating live user data
/// (D-011).
enum SyncStatus {
  /// Created on this device and never sent anywhere.
  local,

  /// Changed locally, awaiting upload.
  pending,

  /// Matches the server as of [SyncColumns.lastSyncedAt].
  synced,

  /// Diverged from the server; needs resolution.
  conflict,
}

/// The six columns every user-data table carries (D-011).
///
/// A mixin rather than a copied block, so a table physically cannot be
/// declared without them -- `schema_shape_test.dart` checks that every table in
/// the database has all six.
mixin SyncColumns on Table {
  /// UUID v4, never `AUTOINCREMENT`: integer keys allocated independently on
  /// two devices collide the moment those devices sync (D-001).
  TextColumn get id => text().clientDefault(uuidV4)();

  /// Epoch milliseconds, UTC (D-005). Never a localized date string.
  IntColumn get createdAt => integer().clientDefault(nowMillis)();

  /// Bumped on every write. Repositories own this; it is not automatic.
  IntColumn get updatedAt => integer().clientDefault(nowMillis)();

  /// Soft delete (D-003). A hard delete cannot be propagated to another
  /// device, which would resurrect the row on the next sync. Every read must
  /// filter this -- see `soft_delete.dart`, the single place that expresses it.
  IntColumn get deletedAt => integer().nullable()();

  IntColumn get syncStatus =>
      intEnum<SyncStatus>().withDefault(const Constant(0))();

  IntColumn get lastSyncedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The current instant as UTC epoch milliseconds.
int nowMillis() => DateTime.now().toUtc().millisecondsSinceEpoch;
