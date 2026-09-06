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
            themeMode: Value(settings.themeMode),
            // `Value`, not `Value.absent`, on all three: clearing the seller
            // is an ordinary edit and has to reach the column as a null.
            sellerName: Value<String?>(seller.name),
            sellerAddress: Value<String?>(seller.address),
            sellerPhone: Value<String?>(seller.phone),
            devicePrefix: Value(settings.devicePrefix),
            lastBackupAt: Value(millisFromInstantOrNull(settings.lastBackupAt)),
            // `tutorial_seen_at` is deliberately absent from this companion.
            // Nothing the user edits on the settings screen has anything to
            // say about it, and a `Value` here would let a saved tax rate
            // carry a stale flag back into the column — including a null,
            // which would make the tutorial reappear on the next launch
            // (D-122). `markTutorialSeen` is the only writer.
            updatedAt: Value(nowMillis()),
          ),
        );
    return read();
  }

  @override
  Future<void> markTutorialSeen(DateTime at) async {
    // **`where`, not an unconditional write**, which is what makes this
    // idempotent at the database rather than at whichever caller remembered.
    // The «راهنما» entry in settings replays the tutorial, and every replay
    // ends here; without the clause the flag would advance each time and the
    // column would answer a different question from the one it is named for.
    //
    // `updated_at` is bumped, unlike in the migration that introduced the
    // column: this one is a user's own action.
    await (_db.update(
      _db.settings,
    )..where(($SettingsTable t) => t.tutorialSeenAt.isNull())).write(
      SettingsCompanion(
        tutorialSeenAt: Value(millisFromInstant(at)),
        updatedAt: Value(nowMillis()),
      ),
    );
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
    themeMode: row.themeMode,
    seller: SellerIdentity(
      name: row.sellerName,
      address: row.sellerAddress,
      phone: row.sellerPhone,
    ),
    devicePrefix: row.devicePrefix,
    lastBackupAt: instantFromMillisOrNull(row.lastBackupAt),
    tutorialSeenAt: instantFromMillisOrNull(row.tutorialSeenAt),
  );
}
