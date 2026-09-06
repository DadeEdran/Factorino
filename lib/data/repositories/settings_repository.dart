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

  /// Records that the first-run tutorial has been seen (D-122).
  ///
  /// **Idempotent, and once means once**: an implementation must not move an
  /// instant that is already set. The tutorial can be reopened from settings
  /// any number of times, and each of those ends by calling this — if it
  /// overwrote, the column would stop meaning "when this user was first
  /// oriented" and start meaning "when they last browsed the help".
  Future<void> markTutorialSeen(DateTime at);
}
