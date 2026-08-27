import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../database/soft_delete.dart';
import '../../database/tables/sync_columns.dart';
import '../../models/app_settings.dart';
import '../settings_repository.dart';
import 'mappers.dart';

/// Drift-backed [SettingsRepository].
///
/// The row is seeded in `onCreate` and kept single by a `CHECK (singleton = 1)`
/// constraint, so every read here can use `getSingle` rather than handling a
/// missing-configuration case that cannot occur.
class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<AppSettings> read() async => _fromRow(await _query().getSingle());

  @override
  Stream<AppSettings> watch() => _query().watch().map((rows) {
    return _fromRow(rows.single);
  });

  @override
  Future<AppSettings> write(AppSettings settings) async {
    await _db
        .update(_db.settings)
        .write(
          SettingsCompanion(
            defaultTaxRateBp: Value(settings.defaultTaxRateBp),
            roundingUnitRial: Value(settings.roundingUnitRial),
            invoiceNumberPrefix: Value(settings.invoiceNumberPrefix),
            paymentTermDays: Value(settings.paymentTermDays),
            devicePrefix: Value(settings.devicePrefix),
            lastBackupAt: Value(millisFromInstantOrNull(settings.lastBackupAt)),
            updatedAt: Value(nowMillis()),
          ),
        );
    return read();
  }

  @override
  Future<void> markBackedUp(DateTime at) async {
    await _db
        .update(_db.settings)
        .write(
          SettingsCompanion(
            lastBackupAt: Value(millisFromInstant(at)),
            updatedAt: Value(nowMillis()),
          ),
        );
  }

  SimpleSelectStatement<$SettingsTable, SettingsRow> _query() =>
      _db.selectAlive(_db.settings);

  AppSettings _fromRow(SettingsRow row) => AppSettings(
    defaultTaxRateBp: row.defaultTaxRateBp,
    roundingUnitRial: row.roundingUnitRial,
    invoiceNumberPrefix: row.invoiceNumberPrefix,
    paymentTermDays: row.paymentTermDays,
    devicePrefix: row.devicePrefix,
    lastBackupAt: instantFromMillisOrNull(row.lastBackupAt),
  );
}
