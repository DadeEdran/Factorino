import 'app_theme_mode.dart';
import 'money_display_unit.dart';
import 'seller_identity.dart';

/// The single row of application configuration.
///
/// Seeded when the database is created, so no read path anywhere has to handle
/// "configuration missing".
class AppSettings {
  const AppSettings({
    required this.defaultTaxRateBp,
    required this.roundingUnitRial,
    required this.invoiceNumberPrefix,
    this.paymentTermDays = kDefaultPaymentTermDays,
    this.seller = SellerIdentity.none,
    this.themeMode = AppThemeMode.system,
    this.displayUnit = MoneyDisplayUnit.toman,
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

  /// How many days after issue an invoice is due, by default (D-052).
  ///
  /// Configurable for the same reason the VAT rate is: a payment term is a
  /// property of the business. It was a constant in the invoice feature until
  /// schema v3, which is right for most Iranian businesses and quietly wrong
  /// for every one that bills on 45 or 60 days — quietly, because a due date
  /// thirty days out looks deliberate.
  ///
  /// Only ever the column's default today; the settings screen is read-only.
  /// **When it becomes editable, the form must bound it** — a negative term
  /// would produce an invoice due before it was issued, and this type is not
  /// the place to hide that behind a clamp.
  final int paymentTermDays;

  /// The business the invoice is issued **by** (schema v5, D-077).
  ///
  /// **Never null, often empty**, and the difference matters. Every database in
  /// existence carries [SellerIdentity.none] after the migration, because there
  /// was nothing to migrate from and nothing honest to invent — so an empty
  /// identity is the ordinary starting state rather than an error, and no read
  /// path has to handle a missing one.
  ///
  /// It is a value object rather than four nullable fields here for a reason
  /// that is easy to miss: `copyWith` on a nullable field cannot express *clear
  /// it*. Emptying the name in the form would otherwise write the old name
  /// straight back, and the user would find out on the next document they
  /// printed. See [SellerIdentity].
  final SellerIdentity seller;

  /// Which of the two designed themes to show (schema v6, D-087).
  ///
  /// **Never null**, and [AppThemeMode.system] is a choice rather than the
  /// absence of one: both themes are designed (§10), so following the device
  /// is a first-class result. That is why the column is a non-nullable enum
  /// index rather than a nullable one — "never chose" and "chose to follow the
  /// device" are the same fact, and a nullable column would invite a later
  /// reader to treat them as two.
  final AppThemeMode themeMode;

  /// Which unit amounts are shown and entered in (schema v8).
  ///
  /// **Display only, and storage is untouched**: every amount in the database
  /// is integer Rial and stays that way (§4, D-002). Choosing ریال changes what
  /// the user reads on a card, types into a field and sees printed on the
  /// document — never the number underneath it, and never a figure on an
  /// invoice already issued.
  final MoneyDisplayUnit displayUnit;

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
    int? paymentTermDays,
    SellerIdentity? seller,
    AppThemeMode? themeMode,
    MoneyDisplayUnit? displayUnit,
    String? devicePrefix,
    DateTime? lastBackupAt,
  }) {
    return AppSettings(
      defaultTaxRateBp: defaultTaxRateBp ?? this.defaultTaxRateBp,
      roundingUnitRial: roundingUnitRial ?? this.roundingUnitRial,
      invoiceNumberPrefix: invoiceNumberPrefix ?? this.invoiceNumberPrefix,
      paymentTermDays: paymentTermDays ?? this.paymentTermDays,
      // Replaced whole, which is what makes clearing a seller field
      // expressible at all -- `??` on four nullable strings could not say
      // "this one is now empty" (D-077).
      seller: seller ?? this.seller,
      themeMode: themeMode ?? this.themeMode,
      displayUnit: displayUnit ?? this.displayUnit,
      devicePrefix: devicePrefix ?? this.devicePrefix,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    );
  }

  @override
  String toString() => 'AppSettings(prefix: $invoiceNumberPrefix)';
}

/// The payment term a database starts life with: thirty days.
///
/// This is the **seed default**, not the term in force — that is
/// [AppSettings.paymentTermDays], read from the settings row. It is named here
/// because it has two consumers that must agree: the `withDefault` on
/// `settings.payment_term_days`, which cannot reference it (`drift_dev` reads
/// that argument from the source expression, the same trap `withLength(max:)`
/// carries), and any code that needs a term before settings have been read.
/// `field_limits_test.dart` asserts the generated column default equals this.
const int kDefaultPaymentTermDays = 30;
