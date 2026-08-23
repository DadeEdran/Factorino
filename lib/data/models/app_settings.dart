/// The single row of application configuration.
///
/// Seeded when the database is created, so no read path anywhere has to handle
/// "configuration missing".
class AppSettings {
  const AppSettings({
    required this.defaultTaxRateBp,
    required this.roundingUnitRial,
    required this.invoiceNumberPrefix,
    this.devicePrefix,
    this.lastBackupAt,
  });

  /// Default VAT rate in basis points, e.g. 10% = `1000`. Configurable, never
  /// hardcoded (§4). Changing it must not alter existing invoices, which is
  /// why the resolved rate is snapshotted onto every item.
  ///
  /// Non-nullable, because it is the last step of the tax resolution chain and
  /// the chain has to terminate (D-026).
  final int defaultTaxRateBp;

  /// Round the grand total to the nearest N Rial. `0` disables it (§4).
  final int roundingUnitRial;

  /// The `{prefix}` in `{prefix}-{jalaliYear}-{sequence:0000}` (D-013).
  final String invoiceNumberPrefix;

  /// Reserved for the multi-device numbering collision cloud sync will
  /// introduce (D-013). Unused in Phase 1.
  final String? devicePrefix;

  /// When the user last exported a backup. Drives the reminder in settings --
  /// an offline-only financial app whose user has never made a backup is one
  /// lost phone away from losing the business (§8).
  final DateTime? lastBackupAt;

  AppSettings copyWith({
    int? defaultTaxRateBp,
    int? roundingUnitRial,
    String? invoiceNumberPrefix,
    String? devicePrefix,
    DateTime? lastBackupAt,
  }) {
    return AppSettings(
      defaultTaxRateBp: defaultTaxRateBp ?? this.defaultTaxRateBp,
      roundingUnitRial: roundingUnitRial ?? this.roundingUnitRial,
      invoiceNumberPrefix: invoiceNumberPrefix ?? this.invoiceNumberPrefix,
      devicePrefix: devicePrefix ?? this.devicePrefix,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    );
  }

  @override
  String toString() => 'AppSettings(prefix: $invoiceNumberPrefix)';
}
