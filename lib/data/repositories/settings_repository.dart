import '../models/app_settings.dart';

/// The single settings row.
///
/// Always present: it is seeded when the database is created, so nothing here
/// returns null and no caller has to handle "configuration missing".
abstract interface class SettingsRepository {
  Future<AppSettings> read();

  Stream<AppSettings> watch();

  /// Persists [settings].
  ///
  /// Changing `defaultTaxRateBp` must not alter existing invoices -- it cannot,
  /// because every item snapshots the rate that applied to it (§4, D-026).
  Future<AppSettings> write(AppSettings settings);

  /// Records that a backup completed, for the reminder in settings (§8).
  Future<void> markBackedUp(DateTime at);
}
