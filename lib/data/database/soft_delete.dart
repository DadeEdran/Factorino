import 'package:drift/drift.dart';

/// The name of the soft-delete column, as it appears in SQL.
///
/// Looked up by name rather than through a typed getter because drift
/// generates a separate table class per table with no common supertype; going
/// through `columnsByName` is what lets one helper serve all six tables
/// instead of six near-identical helpers nobody keeps in step.
const String kDeletedAtColumn = 'deleted_at';

/// Raised when a table that should support soft deletion does not.
///
/// This is a programming error, not a runtime condition: it means a table was
/// declared without `SyncColumns`, and every read of it would silently include
/// deleted rows.
class MissingSoftDeleteColumn implements Exception {
  const MissingSoftDeleteColumn(this.tableName);

  final String tableName;

  @override
  String toString() =>
      'MissingSoftDeleteColumn: "$tableName" has no $kDeletedAtColumn column. '
      'Every user-data table must mix in SyncColumns (D-003, D-011).';
}

/// `deleted_at IS NULL`, expressed once.
///
/// the project spec: *"Provide a single query helper so this cannot be forgotten
/// per-call-site."* This is that helper. A repository that forgets it does not
/// return slightly stale data -- it returns records the user deleted, which for
/// invoices and customers is worse than an error.
Expression<bool> aliveFilter(ResultSetImplementation<dynamic, dynamic> table) {
  final column = table.columnsByName[kDeletedAtColumn];
  if (column == null) {
    throw MissingSoftDeleteColumn(table.entityName);
  }
  return column.isNull();
}

/// The inverse: only rows that have been soft-deleted.
///
/// Needed by exactly two things -- a future restore/undo affordance and the
/// sync layer, which must ship tombstones. Both are deliberate; ordinary reads
/// use [aliveFilter].
Expression<bool> deletedFilter(
  ResultSetImplementation<dynamic, dynamic> table,
) {
  final column = table.columnsByName[kDeletedAtColumn];
  if (column == null) {
    throw MissingSoftDeleteColumn(table.entityName);
  }
  return column.isNotNull();
}

/// Selects the rows of [table] that have not been soft-deleted.
///
/// Prefer this over `select(table)` everywhere. `soft_delete_usage_test.dart`
/// fails the build if a repository reaches for the raw form.
extension AliveQueries on DatabaseConnectionUser {
  SimpleSelectStatement<T, R> selectAlive<T extends Table, R>(
    TableInfo<T, R> table,
  ) {
    return select(table)..where((_) => aliveFilter(table));
  }

  /// Counts non-deleted rows without materialising them, so dashboard tiles
  /// stay SQL aggregates rather than Dart loops over full tables (§13).
  Selectable<int> countAlive<T extends Table, R>(TableInfo<T, R> table) {
    final counter = countAll(filter: aliveFilter(table));
    return (selectOnly(
      table,
    )..addColumns([counter])).map((row) => row.read(counter)!);
  }
}
