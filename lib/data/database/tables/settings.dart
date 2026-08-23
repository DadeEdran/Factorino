import 'package:drift/drift.dart';

import 'sync_columns.dart';

/// Single-row application configuration.
///
/// Carries the sync columns like every other table even though it is one row:
/// settings are user data, they will need to reach a second device, and a
/// table without them would be the one exception someone has to remember
/// (D-011).
@DataClassName('SettingsRow')
class Settings extends Table with SyncColumns {
  @override
  String get tableName => 'settings';

  /// Enforces the single row at the schema level. Constant DDL, not an
  /// interpolated query -- D-018 governs the latter.
  @override
  List<String> get customConstraints => const <String>['CHECK (singleton = 1)'];

  IntColumn get singleton => integer().withDefault(const Constant(1))();

  /// Default VAT rate in basis points, e.g. 10% = 1000. Configurable, never
  /// hardcoded, and changing it must not alter existing invoices -- which is
  /// why the resolved rate is snapshotted onto each item (§4).
  IntColumn get defaultTaxRateBp =>
      integer().withDefault(const Constant(1000))();

  /// Round the grand total to the nearest N Rial. `0` disables it (§4).
  IntColumn get roundingUnitRial => integer().withDefault(const Constant(0))();

  /// The `{prefix}` in `{prefix}-{jalaliYear}-{sequence:0000}` (D-013).
  TextColumn get invoiceNumberPrefix =>
      text().withLength(min: 1, max: 12).withDefault(const Constant('INV'))();

  /// Reserved for the multi-device numbering collision that cloud sync will
  /// introduce (D-013). Unused in Phase 1 and deliberately present: once two
  /// devices allocate numbers independently, the prefix is what keeps them
  /// apart, and adding the column then would mean migrating live data.
  TextColumn get devicePrefix => text().withLength(max: 8).nullable()();

  /// Epoch milliseconds of the last successful export. Drives the backup
  /// reminder -- an offline-only financial app whose user has
  /// never made a backup is one lost phone away from losing the business.
  IntColumn get lastBackupAt => integer().nullable()();
}
