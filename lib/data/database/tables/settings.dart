import 'package:drift/drift.dart';

import '../../models/app_theme_mode.dart';
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

  /// How many days after issue an invoice is due, by default (D-052).
  ///
  /// A payment term is a property of the business, not of the application. It
  /// was a 30-day constant in `features/invoices/domain/` until v3, which is
  /// correct for most Iranian businesses and wrong for every one that bills on
  /// 45 or 60 days -- and wrong invisibly, because a due date thirty days out
  /// looks deliberate.
  ///
  /// The literal `30` here rather than `kDefaultPaymentTermDays`, for the
  /// reason `withLength(max:)` cannot take a constant either: `drift_dev` reads
  /// this argument from the source expression, and what it does with a named
  /// constant is not something to find out from a shipped default.
  /// `field_limits_test.dart` asserts the generated default equals the
  /// constant, which is the same trade the length limits make.
  IntColumn get paymentTermDays => integer().withDefault(const Constant(30))();

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

  // ------------------------------------------------ the seller (v5, D-077)
  //
  // The business the invoice is issued BY. Until v5 this table held no
  // business identity at all, so the printed document carried a خریدار block
  // and nothing opposite it -- and an invoice that does not say who issued it
  // is not one the user can hand to a customer (D-076).
  //
  // **All four are nullable and stay nullable.** Every database that exists
  // today has none of them and there is no honest value to invent for a
  // business the application has never been told about, so the migration
  // writes nothing and the document omits the block until the user fills it
  // in. A `withDefault` here would put a fabricated seller on a
  // customer-facing document, which is the one thing this phase must not do.
  //
  // The literals rather than `SellerLimits.*`, for the reason every other
  // length in this file carries one: `drift_dev` reads the argument from the
  // source expression and generates a column with **no length constraint at
  // all** for anything that is not an integer literal. `field_limits_test.dart`
  // asks each column where it actually bites.

  /// The business name, as it appears on the document. The identifying field:
  /// the form requires it as soon as any other seller field is filled, and the
  /// document prints no block without it (D-077).
  TextColumn get sellerName => text().withLength(max: 160).nullable()();

  /// کد اقتصادی of the issuing business. Optional -- plenty of the businesses
  /// this application is for do not have one.
  TextColumn get sellerEconomicId => text().withLength(max: 20).nullable()();

  TextColumn get sellerAddress => text().withLength(max: 500).nullable()();

  /// Kept as typed, deliberately not normalized to the `09xxxxxxxxx` mobile
  /// shape §9 defines for a customer: a seller's published number is as often
  /// a landline with an area code, and rewriting it would be the application
  /// overruling the user about their own letterhead.
  TextColumn get sellerPhone => text().withLength(max: 20).nullable()();

  // ------------------------------------------------ appearance (v6, D-087)

  /// Which of the two designed themes to show, as the [AppThemeMode] index.
  ///
  /// **In this table rather than in a device-local store**, which is the one
  /// question this column had to answer. It is a preference rather than
  /// business data, and the obvious home for it is somewhere per-device — but
  /// this application has no per-device store, and adding one would mean a new
  /// dependency, a second place settings live, and a second thing the backup
  /// does not carry. The settings row already exists, is already read as a
  /// live query by the screen that edits it, and already travels with a
  /// backup. See D-087.
  ///
  /// The literal `0` rather than `AppThemeMode.system.index`, for the reason
  /// every other default in this file carries one: `drift_dev` reads this
  /// argument from the **source expression**. `settings_theme_test.dart`
  /// asserts the generated default is `AppThemeMode.system`.
  IntColumn get themeMode =>
      intEnum<AppThemeMode>().withDefault(const Constant(0))();
}
