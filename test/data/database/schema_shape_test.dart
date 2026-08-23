import 'package:drift/drift.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/soft_delete.dart';
import 'package:flutter_test/flutter_test.dart';

/// D-011: every user-data table carries the same six sync columns, from the
/// first schema rather than retrofitted later.
///
/// This is checked mechanically because the cost of getting it wrong is paid
/// much later and by the user: a table that reaches production without
/// `deleted_at` or `updated_at` needs a migration of live financial data to
/// fix, and one without `id` as a UUID collides silently once two devices
/// sync. Reading the table definitions and trusting they all match is exactly
/// the kind of check that passes right up until someone adds the seventh table.
void main() {
  // Constructed without a connection: only the column metadata is inspected,
  // and no query is ever executed.
  final AppDatabase db = AppDatabase(_UnusedExecutor());

  const expectedTables = <String>{
    'customers',
    'products',
    'invoices',
    'invoice_items',
    'payments',
    'settings',
  };

  test('the database holds exactly the six specified tables', () {
    expect(
      db.allTables.map((t) => t.actualTableName).toSet(),
      expectedTables,
      reason: 'a new table needs a decision entry and a review of §6',
    );
  });

  group('every table', () {
    for (final table in db.allTables) {
      final name = table.actualTableName;
      final columns = table.columnsByName;

      test('$name carries the D-011 sync columns', () {
        for (final required in <String>[
          'id',
          'created_at',
          'updated_at',
          kDeletedAtColumn,
          'sync_status',
          'last_synced_at',
        ]) {
          expect(
            columns.keys,
            contains(required),
            reason: '$name is missing $required -- mix in SyncColumns',
          );
        }
      });

      test('$name keys on a text UUID, never an integer', () {
        final primaryKey = table.$primaryKey;
        expect(primaryKey.map((c) => c.name), <String>[
          'id',
        ], reason: '$name must key on id alone (D-001)');
        expect(
          columns['id']!.type,
          DriftSqlType.string,
          reason: 'an AUTOINCREMENT integer key collides across devices',
        );
      });

      test('$name stores timestamps as integers', () {
        // Epoch milliseconds UTC (D-005). A stored localized Persian date
        // string cannot be compared, sorted or ranged.
        for (final column in <String>['created_at', 'updated_at']) {
          expect(columns[column]!.type, DriftSqlType.int, reason: column);
        }
      });

      test('$name allows deleted_at to be null', () {
        // Null is the "alive" state the soft-delete helper filters on.
        expect(columns[kDeletedAtColumn]!.$nullable, isTrue);
      });
    }
  });

  test('every monetary and rate column is an integer', () {
    // D-002: no floating point anywhere in the money path. A `real` column
    // here would let a rounding error reach the database, where it becomes an
    // invoice whose lines do not sum to its total.
    final suffixes = <String>['_rial', '_bp', '_milli'];
    var checked = 0;

    for (final table in db.allTables) {
      for (final column in table.columnsByName.values) {
        if (suffixes.any(column.name.endsWith)) {
          checked++;
          expect(
            column.type,
            DriftSqlType.int,
            reason: '${table.actualTableName}.${column.name} must be integer',
          );
        }
      }
    }

    expect(checked, greaterThan(15), reason: 'money columns were not found');
  });
}

/// Never used: [AppDatabase] is only asked about its schema here.
class _UnusedExecutor extends QueryExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('the schema-shape test must not execute queries');
}
