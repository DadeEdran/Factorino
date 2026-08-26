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

  /// Dashboard tile: how many invoices were issued in the period named by the caption beneath it. It counts exactly the invoices dashboardSalesThisMonth sums -- drafts and cancellations excluded (D-039) -- so the two tiles reconcile. The title says 'issued' rather than 'this month' because the caption already carries the month.
  ///
  /// In fa, this message translates to:
  /// **'فاکتورهای صادرشده'**
  String get dashboardInvoiceCount;

  /// Caption under the outstanding-balance tile, naming which invoices it covers. Without it the figure is a number the user cannot reconcile against anything.
  ///
  /// In fa, this message translates to:
  /// **'فاکتورهای پرداخت‌نشده و پرداخت جزئی'**
  String get dashboardOutstandingCaption;

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

  /// Stands where an invoice number would be, for a draft that does not have one yet (D-048). A number is allocated on issue, so that abandoning a draft does not consume one permanently. Deliberately short: it occupies a fixed-width table column, and it is also the heading of a card. Deliberately NOT a repeat of statusDraft -- the status badge sits beside it in all three layouts and already says the invoice is a draft, so this says only the thing the badge does not. Deliberately not blank: an empty cell reads as data that failed to load.
  ///
  /// In fa, this message translates to:
  /// **'بدون شماره'**
  String get invoiceNumberPending;

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

  /// Jalali month 1. The twelve month names are handed to core/formatting/jalali_display.dart, which holds no Persian of its own (D-034).
  ///
  /// In fa, this message translates to:
  /// **'فروردین'**
  String get monthFarvardin;

  /// No description provided for @monthOrdibehesht.
  ///
  /// In fa, this message translates to:
  /// **'اردیبهشت'**
  String get monthOrdibehesht;

  /// No description provided for @monthKhordad.
  ///
  /// In fa, this message translates to:
  /// **'خرداد'**
  String get monthKhordad;

  /// No description provided for @monthTir.
  ///
  /// In fa, this message translates to:
  /// **'تیر'**
  String get monthTir;

  /// No description provided for @monthMordad.
  ///
  /// In fa, this message translates to:
  /// **'مرداد'**
  String get monthMordad;

  /// No description provided for @monthShahrivar.
  ///
  /// In fa, this message translates to:
  /// **'شهریور'**
  String get monthShahrivar;

  /// No description provided for @monthMehr.
  ///
  /// In fa, this message translates to:
  /// **'مهر'**
  String get monthMehr;

  /// No description provided for @monthAban.
  ///
  /// In fa, this message translates to:
  /// **'آبان'**
  String get monthAban;

  /// No description provided for @monthAzar.
  ///
  /// In fa, this message translates to:
  /// **'آذر'**
  String get monthAzar;

  /// No description provided for @monthDey.
  ///
  /// In fa, this message translates to:
  /// **'دی'**
  String get monthDey;

  /// No description provided for @monthBahman.
  ///
  /// In fa, this message translates to:
  /// **'بهمن'**
  String get monthBahman;

  /// No description provided for @monthEsfand.
  ///
  /// In fa, this message translates to:
  /// **'اسفند'**
  String get monthEsfand;

  /// No description provided for @actionEdit.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In fa, this message translates to:
  /// **'حذف'**
  String get actionDelete;

  /// No description provided for @actionClear.
  ///
  /// In fa, this message translates to:
  /// **'پاک کردن'**
  String get actionClear;

  /// Loads the next page. Lists are paginated at the query level, so this widens the window the database is asked for rather than filtering something already loaded.
  ///
  /// In fa, this message translates to:
  /// **'نمایش بیشتر'**
  String get actionLoadMore;

  /// Opens the full list behind a short preview of it -- the dashboard's recent-invoices section.
  ///
  /// In fa, this message translates to:
  /// **'مشاهدهٔ همه'**
  String get actionViewAll;

  /// Tooltip for a row's overflow menu.
  ///
  /// In fa, this message translates to:
  /// **'گزینه‌های بیشتر'**
  String get actionMore;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In fa, this message translates to:
  /// **'نتیجه‌ای یافت نشد'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsBody.
  ///
  /// In fa, this message translates to:
  /// **'عبارت دیگری را امتحان کنید یا جستجو را پاک کنید.'**
  String get searchNoResultsBody;

  /// Helper text marking a form field as not required.
  ///
  /// In fa, this message translates to:
  /// **'اختیاری'**
  String get fieldOptional;

  /// No description provided for @validationRequired.
  ///
  /// In fa, this message translates to:
  /// **'پر کردن این فیلد الزامی است'**
  String get validationRequired;

  /// No description provided for @validationMobileInvalid.
  ///
  /// In fa, this message translates to:
  /// **'شماره موبایل معتبر نیست'**
  String get validationMobileInvalid;

  /// No description provided for @validationAmountInvalid.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ معتبر نیست'**
  String get validationAmountInvalid;

  /// The money engine rejects values above kMaxAmountRial rather than truncating them (D-002).
  ///
  /// In fa, this message translates to:
  /// **'مبلغ واردشده بیش از حد مجاز است'**
  String get validationAmountTooLarge;

  /// Shown when a field's value is longer than its column allows. Names the limit rather than only refusing, because the point of the field-level limits is that the user is told which field and why -- the failure this replaces was a generic error with neither. The count arrives already rendered in Persian digits by core/formatting, so digit rendering stays in one place (D-022).
  ///
  /// In fa, this message translates to:
  /// **'حداکثر {max} نویسه مجاز است'**
  String validationTooLong(String max);

  /// Search covers the customer name and the company name, which are the two fields search_name is built from (D-025).
  ///
  /// In fa, this message translates to:
  /// **'جستجوی نام یا شرکت'**
  String get customersSearchHint;

  /// No description provided for @customerAdd.
  ///
  /// In fa, this message translates to:
  /// **'افزودن مشتری'**
  String get customerAdd;

  /// No description provided for @customerCreateTitle.
  ///
  /// In fa, this message translates to:
  /// **'مشتری جدید'**
  String get customerCreateTitle;

  /// No description provided for @customerEditTitle.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش مشتری'**
  String get customerEditTitle;

  /// No description provided for @customerFieldFullName.
  ///
  /// In fa, this message translates to:
  /// **'نام و نام خانوادگی'**
  String get customerFieldFullName;

  /// No description provided for @customerFieldCompany.
  ///
  /// In fa, this message translates to:
  /// **'نام شرکت'**
  String get customerFieldCompany;

  /// No description provided for @customerFieldMobile.
  ///
  /// In fa, this message translates to:
  /// **'شماره موبایل'**
  String get customerFieldMobile;

  /// No description provided for @customerFieldAddress.
  ///
  /// In fa, this message translates to:
  /// **'نشانی'**
  String get customerFieldAddress;

  /// No description provided for @customerFieldNationalId.
  ///
  /// In fa, this message translates to:
  /// **'کد ملی'**
  String get customerFieldNationalId;

  /// No description provided for @customerFieldEconomicId.
  ///
  /// In fa, this message translates to:
  /// **'کد اقتصادی'**
  String get customerFieldEconomicId;

  /// No description provided for @customerFieldNotes.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت'**
  String get customerFieldNotes;

  /// No description provided for @customerNoMobile.
  ///
  /// In fa, this message translates to:
  /// **'شماره‌ای ثبت نشده'**
  String get customerNoMobile;

  /// No description provided for @customerDeleteTitle.
  ///
  /// In fa, this message translates to:
  /// **'این مشتری حذف شود؟'**
  String get customerDeleteTitle;

  /// the project spec requires the UI to explain soft deletion in Persian rather than failing opaquely. A customer referenced by an invoice is never hard-deleted, and the invoices keep their snapshotted figures (D-004).
  ///
  /// In fa, this message translates to:
  /// **'مشتری از فهرست برداشته می‌شود، اما فاکتورهایی که پیش‌تر برای او صادر شده دست‌نخورده باقی می‌مانند و مبالغ آن‌ها تغییر نمی‌کند.'**
  String get customerDeleteBody;

  /// No description provided for @customerDeleted.
  ///
  /// In fa, this message translates to:
  /// **'مشتری حذف شد'**
  String get customerDeleted;

  /// No description provided for @customerSaved.
  ///
  /// In fa, this message translates to:
  /// **'مشتری ذخیره شد'**
  String get customerSaved;

  /// Heading over the customer's stored record on the detail screen.
  ///
  /// In fa, this message translates to:
  /// **'مشخصات'**
  String get customerDetailsSection;

  /// Tooltip on the control that expands or collapses the customer's record on a phone, where it is collapsed by default so it cannot push the invoice list down the page.
  ///
  /// In fa, this message translates to:
  /// **'نمایش یا پنهان کردن مشخصات'**
  String get customerDetailsToggle;

  /// Heading over the list of invoices issued to this customer.
  ///
  /// In fa, this message translates to:
  /// **'فاکتورهای این مشتری'**
  String get customerInvoicesSection;

  /// Detail-screen tile: the sum of grand totals over invoices ISSUED to this customer. Drafts and cancellations are excluded (D-039), which is what the caption underneath says -- a figure the user cannot reconcile against the list beneath it is one they learn to distrust.
  ///
  /// In fa, this message translates to:
  /// **'مجموع فاکتورهای صادرشده'**
  String get customerTotalBilled;

  /// Caption under customerTotalBilled, naming exactly which invoices it covers.
  ///
  /// In fa, this message translates to:
  /// **'به‌جز پیش‌نویس‌ها و فاکتورهای لغوشده'**
  String get customerTotalBilledCaption;

  /// Detail-screen tile: what this customer still owes -- grand total less payments received, over invoices that are unpaid or partially paid. Its own key rather than a shared one with the dashboard tile, because the two cover different populations and a later wording change should not have to be right for both.
  ///
  /// In fa, this message translates to:
  /// **'مانده دریافتنی'**
  String get customerTotalOutstanding;

  /// No description provided for @customerTotalOutstandingCaption.
  ///
  /// In fa, this message translates to:
  /// **'فاکتورهای پرداخت‌نشده و پرداخت جزئی'**
  String get customerTotalOutstandingCaption;

  /// No description provided for @customerEmptyInvoicesTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز فاکتوری برای این مشتری صادر نشده است'**
  String get customerEmptyInvoicesTitle;

  /// Empty state for a customer with no invoices. Offers no create action: the invoice form is Phase 4, and an affordance leading nowhere is worse than its absence (D-021, one level down).
  ///
  /// In fa, this message translates to:
  /// **'فاکتورهایی که برای این مشتری صادر کنید، همراه با وضعیت پرداختشان اینجا نمایش داده می‌شوند.'**
  String get customerEmptyInvoicesBody;

  /// Shown when a customer id in the URL does not resolve -- a stale deep link, or a customer deleted while the page was opening.
  ///
  /// In fa, this message translates to:
  /// **'این مشتری پیدا نشد'**
  String get customerNotFoundTitle;

  /// No description provided for @customerNotFoundBody.
  ///
  /// In fa, this message translates to:
  /// **'ممکن است حذف شده باشد. به فهرست مشتریان برگردید.'**
  String get customerNotFoundBody;

  /// No description provided for @customerBackToList.
  ///
  /// In fa, this message translates to:
  /// **'فهرست مشتریان'**
  String get customerBackToList;

  /// Placeholder for a record field the user has not filled in. Shown rather than hiding the row, so the detail screen says what is missing instead of quietly looking complete -- the user can then decide whether to add it.
  ///
  /// In fa, this message translates to:
  /// **'ثبت نشده'**
  String get fieldNotRecorded;

  /// No description provided for @productsSearchHint.
  ///
  /// In fa, this message translates to:
  /// **'جستجوی محصول یا خدمت'**
  String get productsSearchHint;

  /// No description provided for @productAdd.
  ///
  /// In fa, this message translates to:
  /// **'افزودن محصول یا خدمت'**
  String get productAdd;

  /// No description provided for @productCreateTitle.
  ///
  /// In fa, this message translates to:
  /// **'محصول یا خدمت جدید'**
  String get productCreateTitle;

  /// No description provided for @productEditTitle.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش محصول یا خدمت'**
  String get productEditTitle;

  /// No description provided for @productFieldName.
  ///
  /// In fa, this message translates to:
  /// **'نام'**
  String get productFieldName;

  /// No description provided for @productFieldType.
  ///
  /// In fa, this message translates to:
  /// **'نوع'**
  String get productFieldType;

  /// No description provided for @productFieldPrice.
  ///
  /// In fa, this message translates to:
  /// **'قیمت'**
  String get productFieldPrice;

  /// No description provided for @productFieldUnit.
  ///
  /// In fa, this message translates to:
  /// **'واحد'**
  String get productFieldUnit;

  /// Examples of units. Free text, because the set of units a workshop uses is not something the app should fix.
  ///
  /// In fa, this message translates to:
  /// **'عدد، کیلوگرم، ساعت، متر'**
  String get productFieldUnitHint;

  /// No description provided for @productFieldDescription.
  ///
  /// In fa, this message translates to:
  /// **'توضیحات'**
  String get productFieldDescription;

  /// No description provided for @productTypeProduct.
  ///
  /// In fa, this message translates to:
  /// **'کالا'**
  String get productTypeProduct;

  /// No description provided for @productTypeService.
  ///
  /// In fa, this message translates to:
  /// **'خدمت'**
  String get productTypeService;

  /// No description provided for @productDeleteTitle.
  ///
  /// In fa, this message translates to:
  /// **'این مورد حذف شود؟'**
  String get productDeleteTitle;

  /// Explains the snapshot rule (D-004) where it matters: deleting a product changes no invoice, because each invoice kept its own copy of the title, unit and price.
  ///
  /// In fa, this message translates to:
  /// **'این مورد از فهرست برداشته می‌شود، اما فاکتورهایی که آن را دربر دارند با همان نام و قیمت زمان صدور حفظ می‌شوند.'**
  String get productDeleteBody;

  /// No description provided for @productDeleted.
  ///
  /// In fa, this message translates to:
  /// **'حذف شد'**
  String get productDeleted;

  /// No description provided for @productSaved.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره شد'**
  String get productSaved;

  /// No description provided for @tableColumnName.
  ///
  /// In fa, this message translates to:
  /// **'نام'**
  String get tableColumnName;

  /// No description provided for @tableColumnMobile.
  ///
  /// In fa, this message translates to:
  /// **'موبایل'**
  String get tableColumnMobile;

  /// No description provided for @tableColumnCompany.
  ///
  /// In fa, this message translates to:
  /// **'شرکت'**
  String get tableColumnCompany;

  /// No description provided for @tableColumnType.
  ///
  /// In fa, this message translates to:
  /// **'نوع'**
  String get tableColumnType;

  /// No description provided for @tableColumnUnit.
  ///
  /// In fa, this message translates to:
  /// **'واحد'**
  String get tableColumnUnit;

  /// No description provided for @tableColumnPrice.
  ///
  /// In fa, this message translates to:
  /// **'قیمت'**
  String get tableColumnPrice;

  /// D-027: a line discount larger than the line was capped. States BOTH figures -- what was entered and what was actually deducted -- because a message that only said some discount was ignored leaves the user unable to tell which line or by how much. Almost always a data-entry slip, so it is surfaced as a question rather than absorbed.
  ///
  /// In fa, this message translates to:
  /// **'تخفیف سطر {line}: {requested} تومان وارد شده بود، اما این سطر بیش از {applied} تومان ارزش ندارد و تنها همین مبلغ کسر شد.'**
  String invoiceWarningLineDiscountClamped(
    String line,
    String requested,
    String applied,
  );

  /// D-027: the invoice-level discount exceeded the subtotal and was capped. This one MUST be capped -- it is part of the reconciliation invariant and an uncapped one produces a negative grand total, which is never a valid document -- but the user is still told, with both figures.
  ///
  /// In fa, this message translates to:
  /// **'تخفیف کل فاکتور: {requested} تومان وارد شده بود، اما جمع فاکتور بیش از {applied} تومان نیست و تنها همین مبلغ کسر شد.'**
  String invoiceWarningInvoiceDiscountClamped(String requested, String applied);

  /// Heading over the clamped-input warnings. Deliberately not an error: the totals are correct and the invoice is usable; what is questionable is the input.
  ///
  /// In fa, this message translates to:
  /// **'این مقادیر را بررسی کنید'**
  String get invoiceWarningsTitle;

  /// No description provided for @datePickerTitle.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب تاریخ'**
  String get datePickerTitle;

  /// Jumps the calendar to the current Jalali day. Today is the date a user wants most often and the hardest one to navigate back to after browsing.
  ///
  /// In fa, this message translates to:
  /// **'امروز'**
  String get datePickerToday;

  /// No description provided for @datePickerPreviousMonth.
  ///
  /// In fa, this message translates to:
  /// **'ماه قبل'**
  String get datePickerPreviousMonth;

  /// No description provided for @datePickerNextMonth.
  ///
  /// In fa, this message translates to:
  /// **'ماه بعد'**
  String get datePickerNextMonth;

  /// Single-letter weekday heading for Saturday, which is the FIRST day of the Iranian week -- a calendar grid starting on Sunday or Monday is wrong here, not merely unfamiliar.
  ///
  /// In fa, this message translates to:
  /// **'ش'**
  String get weekdayShanbeShort;

  /// No description provided for @weekdayYekshanbeShort.
  ///
  /// In fa, this message translates to:
  /// **'ی'**
  String get weekdayYekshanbeShort;

  /// No description provided for @weekdayDoshanbeShort.
  ///
  /// In fa, this message translates to:
  /// **'د'**
  String get weekdayDoshanbeShort;

  /// No description provided for @weekdaySeshanbeShort.
  ///
  /// In fa, this message translates to:
  /// **'س'**
  String get weekdaySeshanbeShort;

  /// No description provided for @weekdayChaharshanbeShort.
  ///
  /// In fa, this message translates to:
  /// **'چ'**
  String get weekdayChaharshanbeShort;

  /// No description provided for @weekdayPanjshanbeShort.
  ///
  /// In fa, this message translates to:
  /// **'پ'**
  String get weekdayPanjshanbeShort;

  /// Friday, the Iranian weekend day. Rendered in the accent colour in the calendar grid the way a weekend is elsewhere.
  ///
  /// In fa, this message translates to:
  /// **'ج'**
  String get weekdayJomeShort;

  /// Heading over the invoice-level fields -- customer, dates, discount, tax, notes -- as distinct from the line items.
  ///
  /// In fa, this message translates to:
  /// **'مشخصات فاکتور'**
  String get invoiceDetailsTitle;

  /// No description provided for @invoiceFieldCustomer.
  ///
  /// In fa, this message translates to:
  /// **'مشتری'**
  String get invoiceFieldCustomer;

  /// The customer field before one is chosen. An invoice cannot be written without a customer -- customer_id is a non-null foreign key -- so this is an instruction, not a placeholder.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب مشتری'**
  String get invoiceFieldCustomerEmpty;

  /// No description provided for @invoiceFieldIssueDate.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ صدور'**
  String get invoiceFieldIssueDate;

  /// No description provided for @invoiceFieldDueDate.
  ///
  /// In fa, this message translates to:
  /// **'سررسید'**
  String get invoiceFieldDueDate;

  /// No description provided for @invoiceFieldDueDateCleared.
  ///
  /// In fa, this message translates to:
  /// **'بدون سررسید'**
  String get invoiceFieldDueDateCleared;

  /// The invoice-level discount, allocated across the lines by the engine before tax (section 4 step 4). Named 'whole invoice' to distinguish it from the per-line discount.
  ///
  /// In fa, this message translates to:
  /// **'تخفیف کل فاکتور'**
  String get invoiceFieldDiscount;

  /// No description provided for @invoiceFieldTax.
  ///
  /// In fa, this message translates to:
  /// **'مالیات فاکتور'**
  String get invoiceFieldTax;

  /// No description provided for @invoiceFieldNotes.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت'**
  String get invoiceFieldNotes;

  /// No description provided for @invoiceCustomerPickerTitle.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب مشتری'**
  String get invoiceCustomerPickerTitle;

  /// The search behind this is the normalization-insensitive one (D-025, D-029): a customer saved as علي is found by typing علی.
  ///
  /// In fa, this message translates to:
  /// **'جست‌وجو در مشتریان'**
  String get invoiceCustomerPickerSearchHint;

  /// No description provided for @invoiceCustomerPickerEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'مشتری‌ای یافت نشد'**
  String get invoiceCustomerPickerEmptyTitle;

  /// Unlike the product picker, there is no free-text fallback: customer_id is a non-null foreign key, so an invoice genuinely cannot proceed without a customer record.
  ///
  /// In fa, this message translates to:
  /// **'برای صدور فاکتور ابتدا باید مشتری را در بخش مشتریان ثبت کنید.'**
  String get invoiceCustomerPickerEmptyBody;

  /// Saves without allocating a number (D-048). Named 'draft' so the user knows this is not yet a document.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره پیش‌نویس'**
  String get invoiceActionSaveDraft;

  /// Saves and issues: this is the moment a number is allocated and the invoice becomes a document.
  ///
  /// In fa, this message translates to:
  /// **'صدور فاکتور'**
  String get invoiceActionIssue;

  /// No description provided for @invoiceSaveDraftSuccess.
  ///
  /// In fa, this message translates to:
  /// **'پیش‌نویس ذخیره شد.'**
  String get invoiceSaveDraftSuccess;

  /// Confirms the issue and names the allocated number, because the number is the thing the user needs to know and cannot predict.
  ///
  /// In fa, this message translates to:
  /// **'فاکتور {number} صادر شد.'**
  String invoiceIssueSuccess(String number);

  /// A write failure, in friendly Persian. A raw exception, stack trace or SQL statement must never reach the user (section 7).
  ///
  /// In fa, this message translates to:
  /// **'ذخیره فاکتور ممکن نشد. لطفاً دوباره تلاش کنید.'**
  String get invoiceSaveFailed;

  /// No description provided for @invoiceIncompleteCustomer.
  ///
  /// In fa, this message translates to:
  /// **'برای ذخیره، مشتری را انتخاب کنید.'**
  String get invoiceIncompleteCustomer;

  /// No description provided for @invoiceIncompleteLines.
  ///
  /// In fa, this message translates to:
  /// **'برای ذخیره، دست‌کم یک سطر اضافه کنید.'**
  String get invoiceIncompleteLines;

  /// Heading over the invoice's line items in the create/edit form.
  ///
  /// In fa, this message translates to:
  /// **'سطرهای فاکتور'**
  String get invoiceLinesTitle;

  /// No description provided for @invoiceLinesEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز سطری اضافه نشده است'**
  String get invoiceLinesEmptyTitle;

  /// Empty state for an invoice with no lines yet. Names both routes in, because the free-text line is not discoverable from the catalogue button alone.
  ///
  /// In fa, this message translates to:
  /// **'یک کالا یا خدمت از فهرست انتخاب کنید، یا سطری دلخواه بنویسید.'**
  String get invoiceLinesEmptyBody;

  /// Opens the product picker. Says 'from the list' rather than 'product', because the catalogue holds services too.
  ///
  /// In fa, this message translates to:
  /// **'افزودن از فهرست'**
  String get invoiceLineAddFromCatalogue;

  /// Adds a line typed by hand, for work that is not in the catalogue.
  ///
  /// In fa, this message translates to:
  /// **'سطر دلخواه'**
  String get invoiceLineAddCustom;

  /// No description provided for @invoiceLineEditTitle.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش سطر'**
  String get invoiceLineEditTitle;

  /// No description provided for @invoiceLineCreateTitle.
  ///
  /// In fa, this message translates to:
  /// **'سطر جدید'**
  String get invoiceLineCreateTitle;

  /// The line's title snapshot. 'شرح' (description of the work) rather than 'نام', because a line describes a job as often as it names a thing.
  ///
  /// In fa, this message translates to:
  /// **'شرح'**
  String get invoiceLineFieldTitle;

  /// No description provided for @invoiceLineFieldQuantity.
  ///
  /// In fa, this message translates to:
  /// **'تعداد'**
  String get invoiceLineFieldQuantity;

  /// quantity_milli holds three decimal places (section 4). Stated up front, because the alternative is the user discovering it through a rejection.
  ///
  /// In fa, this message translates to:
  /// **'تا سه رقم اعشار'**
  String get invoiceLineFieldQuantityHelper;

  /// No description provided for @invoiceLineFieldUnitPrice.
  ///
  /// In fa, this message translates to:
  /// **'قیمت واحد'**
  String get invoiceLineFieldUnitPrice;

  /// No description provided for @invoiceLineDiscountSection.
  ///
  /// In fa, this message translates to:
  /// **'تخفیف سطر'**
  String get invoiceLineDiscountSection;

  /// No description provided for @invoiceLineDiscountModeAmount.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ'**
  String get invoiceLineDiscountModeAmount;

  /// No description provided for @invoiceLineDiscountModePercent.
  ///
  /// In fa, this message translates to:
  /// **'درصد'**
  String get invoiceLineDiscountModePercent;

  /// No description provided for @invoiceLineTaxSection.
  ///
  /// In fa, this message translates to:
  /// **'مالیات سطر'**
  String get invoiceLineTaxSection;

  /// The line inherits the invoice's rate, which in turn falls back to the settings default (section 4 step 6). Distinct from an explicit zero, which is a real rate -- see D-026.
  ///
  /// In fa, this message translates to:
  /// **'پیش‌فرض فاکتور'**
  String get invoiceLineTaxInherit;

  /// An explicit per-line rate. Selecting it and entering 0 marks the line tax-exempt, which is NOT the same as inheriting (D-026).
  ///
  /// In fa, this message translates to:
  /// **'نرخ دلخواه'**
  String get invoiceLineTaxCustom;

  /// Shows which rate the engine actually resolved for a line set to inherit, so 'default' is not an unknown quantity. The figure comes from CalculatedLine.resolvedTaxRateBp -- the widget does not resolve it. The placeholder arrives already carrying the percent sign, from formatPercentFromBasisPoints.
  ///
  /// In fa, this message translates to:
  /// **'نرخ مؤثر: {rate}'**
  String invoiceLineTaxInheritedNote(String rate);

  /// The line's quantity, unit and unit price on one row beneath its title. Multiplication sign rather than the word, because it reads the same in Persian and keeps the row short.
  ///
  /// In fa, this message translates to:
  /// **'{quantity} {unit} × {price}'**
  String invoiceLineLabelQuantity(String quantity, String unit, String price);

  /// The discount ACTUALLY applied to a line, from CalculatedLine.discount -- never the amount as entered (section 4 step 9).
  ///
  /// In fa, this message translates to:
  /// **'تخفیف {amount}'**
  String invoiceLineLabelDiscount(String amount);

  /// The resolved tax rate on a line. The placeholder arrives already carrying the percent sign, from formatPercentFromBasisPoints. Shown only when the rate is non-zero.
  ///
  /// In fa, this message translates to:
  /// **'مالیات {rate}'**
  String invoiceLineLabelTax(String rate);

  /// No description provided for @invoiceLineActionEdit.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش سطر'**
  String get invoiceLineActionEdit;

  /// No description provided for @invoiceLineActionRemove.
  ///
  /// In fa, this message translates to:
  /// **'حذف سطر'**
  String get invoiceLineActionRemove;

  /// No description provided for @invoiceLineActionMoveUp.
  ///
  /// In fa, this message translates to:
  /// **'انتقال به بالا'**
  String get invoiceLineActionMoveUp;

  /// No description provided for @invoiceLineActionMoveDown.
  ///
  /// In fa, this message translates to:
  /// **'انتقال به پایین'**
  String get invoiceLineActionMoveDown;

  /// No description provided for @invoiceLineColumnDescription.
  ///
  /// In fa, this message translates to:
  /// **'شرح'**
  String get invoiceLineColumnDescription;

  /// No description provided for @invoiceLineColumnQuantity.
  ///
  /// In fa, this message translates to:
  /// **'تعداد'**
  String get invoiceLineColumnQuantity;

  /// No description provided for @invoiceLineColumnUnitPrice.
  ///
  /// In fa, this message translates to:
  /// **'قیمت واحد'**
  String get invoiceLineColumnUnitPrice;

  /// No description provided for @invoiceLineColumnTotal.
  ///
  /// In fa, this message translates to:
  /// **'جمع سطر'**
  String get invoiceLineColumnTotal;

  /// No description provided for @invoiceProductPickerTitle.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب کالا یا خدمت'**
  String get invoiceProductPickerTitle;

  /// No description provided for @invoiceProductPickerSearchHint.
  ///
  /// In fa, this message translates to:
  /// **'جست‌وجو در کالاها و خدمات'**
  String get invoiceProductPickerSearchHint;

  /// No description provided for @invoiceProductPickerEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'کالا یا خدمتی یافت نشد'**
  String get invoiceProductPickerEmptyTitle;

  /// Shown when the catalogue search returns nothing. Offers the free-text line rather than sending the user to create a product mid-invoice.
  ///
  /// In fa, this message translates to:
  /// **'می‌توانید به جای آن سطری دلخواه بنویسید.'**
  String get invoiceProductPickerEmptyBody;

  /// No description provided for @validationQuantityInvalid.
  ///
  /// In fa, this message translates to:
  /// **'تعداد را درست وارد کنید.'**
  String get validationQuantityInvalid;

  /// quantity_milli cannot hold a fourth decimal place, and section 4 requires refusing rather than truncating -- billing 1.234 for an entered 1.2345 is exactly the silent arithmetic error the money rules exist to prevent.
  ///
  /// In fa, this message translates to:
  /// **'تعداد حداکثر سه رقم اعشار می‌پذیرد.'**
  String get validationQuantityTooPrecise;

  /// No description provided for @validationPercentInvalid.
  ///
  /// In fa, this message translates to:
  /// **'درصد را بین ۰ تا ۱۰۰ وارد کنید.'**
  String get validationPercentInvalid;

  /// No description provided for @errorInvoiceNotEditableTitle.
  ///
  /// In fa, this message translates to:
  /// **'این فاکتور قابل ویرایش نیست'**
  String get errorInvoiceNotEditableTitle;

  /// the project spec: only draft invoices are editable; an issued invoice is corrected by cancellation, never by a silent edit.
  ///
  /// In fa, this message translates to:
  /// **'فقط پیش‌نویس‌ها را می‌توان تغییر داد. فاکتور صادرشده را باید لغو کرد.'**
  String get errorInvoiceNotEditableBody;

  /// No description provided for @errorPaymentNotAcceptedTitle.
  ///
  /// In fa, this message translates to:
  /// **'ثبت پرداخت ممکن نیست'**
  String get errorPaymentNotAcceptedTitle;

  /// No description provided for @errorPaymentNotAcceptedBody.
  ///
  /// In fa, this message translates to:
  /// **'برای این فاکتور در وضعیت فعلی نمی‌توان پرداخت ثبت کرد.'**
  String get errorPaymentNotAcceptedBody;

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
