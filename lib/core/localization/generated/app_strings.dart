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
