import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_strings_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppStrings
/// returned by `AppStrings.of(context)`.
///
/// Applications need to include `AppStrings.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_strings.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppStrings.localizationsDelegates,
///   supportedLocales: AppStrings.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppStrings.supportedLocales
/// property.
abstract class AppStrings {
  AppStrings(String locale)
: localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fa')];

  /// The application name, shown in the window title and the app bar.
  ///
  /// In fa, this message translates to:
  /// **'فاکتورینو'**
  String get appTitle;

  /// Navigation destination: the dashboard.
  ///
  /// In fa, this message translates to:
  /// **'داشبورد'**
  String get navDashboard;

  /// Navigation destination: the invoice list.
  ///
  /// In fa, this message translates to:
  /// **'فاکتورها'**
  String get navInvoices;

  /// Navigation destination: the customer list.
  ///
  /// In fa, this message translates to:
  /// **'مشتریان'**
  String get navCustomers;

  /// Navigation destination: the product and service catalogue.
  ///
  /// In fa, this message translates to:
  /// **'محصولات و خدمات'**
  String get navProducts;

  /// Navigation destination: application settings.
  ///
  /// In fa, this message translates to:
  /// **'تنظیمات'**
  String get navSettings;

  /// Invoice status: draft. Editable; not yet a claim on anyone.
  ///
  /// In fa, this message translates to:
  /// **'پیش‌نویس'**
  String get statusDraft;

  /// Invoice status: issued and unpaid.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت نشده'**
  String get statusUnpaid;

  /// Invoice status: some but not all of the total has been paid.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت جزئی'**
  String get statusPartiallyPaid;

  /// Invoice status: fully paid.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت شده'**
  String get statusPaid;

  /// Invoice status: cancelled. An issued invoice is corrected by cancellation, never by a silent edit.
  ///
  /// In fa, this message translates to:
  /// **'لغو شده'**
  String get statusCancelled;

  /// Invoice status: unpaid and past its due date. Derived at display time from the due date, not stored.
  ///
  /// In fa, this message translates to:
  /// **'سررسید گذشته'**
  String get statusOverdue;

  /// The primary display currency unit. Amounts are never shown as a bare number.
  ///
  /// In fa, this message translates to:
  /// **'تومان'**
  String get unitToman;

  /// The storage currency unit, shown where Rial precision matters.
  ///
  /// In fa, this message translates to:
  /// **'ریال'**
  String get unitRial;

  /// No description provided for @dashboardTitle.
  ///
  /// In fa, this message translates to:
  /// **'داشبورد'**
  String get dashboardTitle;

  /// Dashboard tile. 'This month' means the current JALALI month (D-006), never the Gregorian one.
  ///
  /// In fa, this message translates to:
  /// **'فروش این ماه'**
  String get dashboardSalesThisMonth;

  /// Dashboard tile: the total still owed across unpaid invoices.
  ///
  /// In fa, this message translates to:
  /// **'مانده دریافتنی'**
  String get dashboardOutstanding;

  /// Dashboard tile: number of invoices issued in the current Jalali month.
  ///
  /// In fa, this message translates to:
  /// **'فاکتورهای این ماه'**
  String get dashboardInvoiceCount;

  /// Dashboard tile: number of customers on record.
  ///
  /// In fa, this message translates to:
  /// **'مشتریان'**
  String get dashboardCustomerCount;

  /// No description provided for @dashboardRecentInvoices.
  ///
  /// In fa, this message translates to:
  /// **'فاکتورهای اخیر'**
  String get dashboardRecentInvoices;

  /// No description provided for @emptyDashboardTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز اطلاعاتی برای نمایش نیست'**
  String get emptyDashboardTitle;

  /// No description provided for @emptyDashboardBody.
  ///
  /// In fa, this message translates to:
  /// **'با ساختن اولین فاکتور، خلاصهٔ فروش و مانده دریافتنی همین‌جا نمایش داده می‌شود.'**
  String get emptyDashboardBody;

  /// No description provided for @invoicesTitle.
  ///
  /// In fa, this message translates to:
  /// **'فاکتورها'**
  String get invoicesTitle;

  /// No description provided for @emptyInvoicesTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز فاکتوری ثبت نشده است'**
  String get emptyInvoicesTitle;

  /// No description provided for @emptyInvoicesBody.
  ///
  /// In fa, this message translates to:
  /// **'فاکتورهای شما پس از ثبت، همراه با وضعیت پرداخت در این فهرست نمایش داده می‌شوند.'**
  String get emptyInvoicesBody;

  /// No description provided for @customersTitle.
  ///
  /// In fa, this message translates to:
  /// **'مشتریان'**
  String get customersTitle;

  /// No description provided for @emptyCustomersTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز مشتری‌ای ثبت نشده است'**
  String get emptyCustomersTitle;

  /// No description provided for @emptyCustomersBody.
  ///
  /// In fa, this message translates to:
  /// **'مشتریانی که برایشان فاکتور صادر می‌کنید در این فهرست نگهداری می‌شوند.'**
  String get emptyCustomersBody;

  /// No description provided for @productsTitle.
  ///
  /// In fa, this message translates to:
  /// **'محصولات و خدمات'**
  String get productsTitle;

  /// No description provided for @emptyProductsTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز محصول یا خدمتی ثبت نشده است'**
  String get emptyProductsTitle;

  /// No description provided for @emptyProductsBody.
  ///
  /// In fa, this message translates to:
  /// **'کالاها و خدماتی که می‌فروشید را اینجا نگه دارید تا ساختن فاکتور سریع‌تر شود.'**
  String get emptyProductsBody;

  /// No description provided for @settingsTitle.
  ///
  /// In fa, this message translates to:
  /// **'تنظیمات'**
  String get settingsTitle;

  /// No description provided for @settingsInvoicingSection.
  ///
  /// In fa, this message translates to:
  /// **'فاکتور'**
  String get settingsInvoicingSection;

  /// Settings field. Configurable, never hardcoded; changing it must not alter existing invoices.
  ///
  /// In fa, this message translates to:
  /// **'نرخ مالیات بر ارزش افزوده'**
  String get settingsDefaultTaxRate;

  /// No description provided for @settingsDefaultTaxRateHint.
  ///
  /// In fa, this message translates to:
  /// **'تغییر این نرخ روی فاکتورهای صادرشده اثری ندارد.'**
  String get settingsDefaultTaxRateHint;

  /// No description provided for @settingsInvoicePrefix.
  ///
  /// In fa, this message translates to:
  /// **'پیشوند شمارهٔ فاکتور'**
  String get settingsInvoicePrefix;

  /// No description provided for @settingsRoundingUnit.
  ///
  /// In fa, this message translates to:
  /// **'رند کردن مبلغ نهایی'**
  String get settingsRoundingUnit;

  /// No description provided for @settingsBackupSection.
  ///
  /// In fa, this message translates to:
  /// **'پشتیبان‌گیری'**
  String get settingsBackupSection;

  /// Row label for when the last backup was taken. Distinct from the section heading above it, which names the section rather than the row.
  ///
  /// In fa, this message translates to:
  /// **'آخرین پشتیبان‌گیری'**
  String get settingsLastBackup;

  /// No description provided for @settingsLastBackupNever.
  ///
  /// In fa, this message translates to:
  /// **'تا کنون پشتیبانی تهیه نشده است'**
  String get settingsLastBackupNever;

  /// No description provided for @tableColumnNumber.
  ///
  /// In fa, this message translates to:
  /// **'شماره'**
  String get tableColumnNumber;

  /// No description provided for @tableColumnCustomer.
  ///
  /// In fa, this message translates to:
  /// **'مشتری'**
  String get tableColumnCustomer;

  /// No description provided for @tableColumnDate.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ'**
  String get tableColumnDate;

  /// No description provided for @tableColumnStatus.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت'**
  String get tableColumnStatus;

  /// No description provided for @tableColumnAmount.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ'**
  String get tableColumnAmount;

  /// No description provided for @actionAdd.
  ///
  /// In fa, this message translates to:
  /// **'افزودن'**
  String get actionAdd;

  /// No description provided for @actionSave.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In fa, this message translates to:
  /// **'انصراف'**
  String get actionCancel;

  /// No description provided for @actionSearch.
  ///
  /// In fa, this message translates to:
  /// **'جستجو'**
  String get actionSearch;

  /// No description provided for @actionRetry.
  ///
  /// In fa, this message translates to:
  /// **'تلاش دوباره'**
  String get actionRetry;

  /// Shown when an entered national ID passes the checksum. D-030 REQUIRES that this states only that the FORMAT is valid: it must never say the ID is confirmed, correct, or verified. The checksum maps two distinct numbers onto the same check digit, so a passing value is not a verified identity.
  ///
  /// In fa, this message translates to:
  /// **'فرمت کد ملی معتبر است'**
  String get nationalIdFormatValid;

  /// Shown when an entered national ID fails the checksum. A failing value is genuinely invalid and may be called so plainly (D-030).
  ///
  /// In fa, this message translates to:
  /// **'کد ملی نامعتبر است'**
  String get nationalIdInvalid;

  /// Friendly Persian error title. A stack trace, SQL statement, file path or raw exception string must never reach the user.
  ///
  /// In fa, this message translates to:
  /// **'خطایی رخ داد'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericBody.
  ///
  /// In fa, this message translates to:
  /// **'متأسفانه انجام این کار ممکن نشد. لطفاً دوباره تلاش کنید.'**
  String get errorGenericBody;
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  Future<AppStrings> load(Locale locale) {
    return SynchronousFuture<AppStrings>(lookupAppStrings(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

AppStrings lookupAppStrings(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fa':
      return AppStringsFa();
  }

  throw FlutterError(
    'AppStrings.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
