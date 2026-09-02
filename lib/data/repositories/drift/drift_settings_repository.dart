import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../database/soft_delete.dart';
import '../../database/tables/sync_columns.dart';
import '../../models/app_settings.dart';
import '../../models/seller_identity.dart';
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
    // Blanks fold to null once, here, on the way in. A field the user cleared
    // by deleting its text arrives as `''`, and a stored `''` would print as a
    // labelled empty line on the document -- which reads as data that failed
    // to print rather than as data that was never given (D-077).
    final SellerIdentity seller = settings.seller.normalized();

    await _db
        .update(_db.settings)
        .write(
          SettingsCompanion(
            defaultTaxRateBp: Value(settings.defaultTaxRateBp),
            roundingUnitRial: Value(settings.roundingUnitRial),
            invoiceNumberPrefix: Value(settings.invoiceNumberPrefix),
            paymentTermDays: Value(settings.paymentTermDays),
            // `Value`, not `Value.absent`, on all four: clearing the seller is
            // an ordinary edit and has to reach the column as a null.
            sellerName: Value<String?>(seller.name),
            sellerEconomicId: Value<String?>(seller.economicId),
            sellerAddress: Value<String?>(seller.address),
            sellerPhone: Value<String?>(seller.phone),
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
    seller: SellerIdentity(
      name: row.sellerName,
      economicId: row.sellerEconomicId,
      address: row.sellerAddress,
      phone: row.sellerPhone,
    ),
    devicePrefix: row.devicePrefix,
    lastBackupAt: instantFromMillisOrNull(row.lastBackupAt),
  );
}
