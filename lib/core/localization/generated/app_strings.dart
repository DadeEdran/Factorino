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

  /// Navigation destination: the product and service catalogue. Deliberately SHORTER than productsTitle, which is the page's own heading and still names both halves. A navigation label is read at a glance in a bar five items wide, and «محصولات و خدمات» was the one label that wrapped to a second line on a phone; the screen it opens says what it holds.
  ///
  /// In fa, this message translates to:
  /// **'محصولات'**
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

  /// The week segment of the dashboard's period selector (D-119). One word, because the three segments share a row and the tile beneath them already says «فروش این هفته» in full.
  ///
  /// In fa, this message translates to:
  /// **'هفته'**
  String get dashboardPeriodWeek;

  /// The month segment of the dashboard's period selector. The default: a month is the period an Iranian business reads its own trading in.
  ///
  /// In fa, this message translates to:
  /// **'ماه'**
  String get dashboardPeriodMonth;

  /// The year segment of the dashboard's period selector. The Jalali year, Farvardin to Farvardin (D-006), which is the user's business and tax year.
  ///
  /// In fa, this message translates to:
  /// **'سال'**
  String get dashboardPeriodYear;

  /// Dashboard tile. 'This week' is the JALALI week, شنبه to جمعه (D-006) -- not the last seven days, and not a Monday-start week. The caption beneath it names the two dates, because a week is the one period a user cannot reconstruct from its name.
  ///
  /// In fa, this message translates to:
  /// **'فروش این هفته'**
  String get dashboardSalesThisWeek;

  /// Dashboard tile. The JALALI year, Farvardin to Farvardin -- the user's business and tax year. A Gregorian year here would be wrong by about three months and would look right for nine of them.
  ///
  /// In fa, this message translates to:
  /// **'فروش امسال'**
  String get dashboardSalesThisYear;

  /// Title-row action on the dashboard, opening the day view. In the title row rather than as a card, because section 10 forbids adding height above the content a page exists to show.
  ///
  /// In fa, this message translates to:
  /// **'فروش روزانه'**
  String get dashboardDailySales;

  /// No description provided for @dashboardRecentInvoices.
  ///
  /// In fa, this message translates to:
  /// **'فاکتورهای اخیر'**
  String get dashboardRecentInvoices;

  /// The day view: pick a day on a Jalali calendar and see what was sold that day.
  ///
  /// In fa, this message translates to:
  /// **'فروش روزانه'**
  String get dailySalesTitle;

  /// The selected day's sales total. The same population as every other sales figure -- issued invoices only, drafts and cancellations excluded (D-039).
  ///
  /// In fa, this message translates to:
  /// **'فروش این روز'**
  String get dailySalesDayTotal;

  /// No description provided for @dailySalesInvoicesSection.
  ///
  /// In fa, this message translates to:
  /// **'فاکتورهای این روز'**
  String get dailySalesInvoicesSection;

  /// What a marked calendar day announces to a screen reader. The dot itself announces nothing, so without this the marking is visual-only.
  ///
  /// In fa, this message translates to:
  /// **'دارای فروش'**
  String get dailySalesMarkedDay;

  /// Explains the dot under a calendar day. It says 'invoice issued' rather than 'sales' because that is exactly what the dot means: a payment received on a day does not mark it, since the day view answers what was SOLD that day, not what was collected.
  ///
  /// In fa, this message translates to:
  /// **'روزهایی که فاکتور صادر شده با نقطه مشخص شده‌اند.'**
  String get dailySalesLegend;

  /// No description provided for @dailySalesEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'در این روز فاکتوری صادر نشده است'**
  String get dailySalesEmptyTitle;

  /// No description provided for @dailySalesEmptyBody.
  ///
  /// In fa, this message translates to:
  /// **'روز دیگری را از تقویم انتخاب کنید. روزهای دارای فروش با نقطه مشخص شده‌اند.'**
  String get dailySalesEmptyBody;

  /// No description provided for @emptyDashboardTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز اطلاعاتی برای نمایش نیست'**
  String get emptyDashboardTitle;

  /// No description provided for @emptyDashboardBody.
  ///
  /// In fa, this message translates to:
  /// **'با ساختن اولین فاکتور، خلاصه فروش و مانده دریافتنی همین‌جا نمایش داده می‌شود.'**
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
  /// **'اولین فاکتور خود را بسازید تا همراه با وضعیت پرداختش در این فهرست نمایش داده شود.'**
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
  /// **'پیشوند شماره فاکتور'**
  String get settingsInvoicePrefix;

  /// No description provided for @settingsRoundingUnit.
  ///
  /// In fa, this message translates to:
  /// **'رند کردن مبلغ نهایی'**
  String get settingsRoundingUnit;

  /// No description provided for @settingsPaymentTerm.
  ///
  /// In fa, this message translates to:
  /// **'مهلت پرداخت پیش‌فرض'**
  String get settingsPaymentTerm;

  /// No description provided for @settingsPaymentTermHint.
  ///
  /// In fa, this message translates to:
  /// **'سررسید فاکتور تازه به‌صورت پیش‌فرض این تعداد روز پس از تاریخ صدور تعیین می‌شود.'**
  String get settingsPaymentTermHint;

  /// No description provided for @unitDays.
  ///
  /// In fa, this message translates to:
  /// **'روز'**
  String get unitDays;

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

  /// Section heading for the user own business details on the settings screen (schema v5, D-077). These are printed as the seller block of the invoice. Named «مشخصات فروشنده» rather than «کسب و کار من» so the heading uses the same word the document does: the user should be able to see which part of the printed page this section fills in.
  ///
  /// In fa, this message translates to:
  /// **'مشخصات فروشنده'**
  String get settingsSellerSection;

  /// Shown as the value of a seller row that has not been filled in. Deliberately the same admission wording the invoice uses for an unrecorded figure: it says the value was never given, rather than leaving a blank that reads as data which failed to load.
  ///
  /// In fa, this message translates to:
  /// **'ثبت نشده'**
  String get settingsSellerEmpty;

  /// The one sentence that makes an empty seller impossible to be surprised by (D-077). Shown under the seller section whenever no business name is stored. It states the consequence -- the block is omitted from the printed invoice -- rather than nagging: an empty seller does not block issuing or printing, it is the user document and their call, so the only obligation is that they were told. Carries a ZWNJ twice, so it exercises the D-073 atom on a real screen string.
  ///
  /// In fa, this message translates to:
  /// **'تا زمانی که نام کسب‌وکار را وارد نکنید، بخش «فروشنده» روی فاکتور چاپ نمی‌شود.'**
  String get settingsSellerConsequence;

  /// No description provided for @settingsSellerEditTitle.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش مشخصات فروشنده'**
  String get settingsSellerEditTitle;

  /// Tooltip on the edit control in the seller section header. Deliberately the full phrase rather than the bare edit the invoicing section uses: with two edit controls on one screen, a tooltip that does not say which section it opens is no help at all.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش مشخصات فروشنده'**
  String get settingsSellerEditTooltip;

  /// The seller business name. The identifying field of the block: the document prints no seller block without it, and the form requires it as soon as any other seller field is filled.
  ///
  /// In fa, this message translates to:
  /// **'نام کسب‌وکار'**
  String get settingsSellerFieldName;

  /// No description provided for @settingsSellerFieldNameHint.
  ///
  /// In fa, this message translates to:
  /// **'همان‌گونه که باید روی فاکتور چاپ شود.'**
  String get settingsSellerFieldNameHint;

  /// No description provided for @settingsSellerFieldAddress.
  ///
  /// In fa, this message translates to:
  /// **'نشانی'**
  String get settingsSellerFieldAddress;

  /// The seller telephone. Deliberately a different label from the customer mobile field: a business published number is as often a landline with an area code, and it is stored as typed rather than normalized to the 09xxxxxxxxx mobile shape.
  ///
  /// In fa, this message translates to:
  /// **'تلفن'**
  String get settingsSellerFieldPhone;

  /// Says the number is kept exactly as typed. Worth saying because the customer mobile field does normalize, so a user who has met that field would reasonably expect this one to as well.
  ///
  /// In fa, this message translates to:
  /// **'همان‌گونه که وارد می‌کنید ذخیره و چاپ می‌شود.'**
  String get settingsSellerFieldPhoneHint;

  /// Validation error when a seller field is filled but the name is not. Reported, never clamped (D-027): a seller block carrying an economic ID and no name is a fragment rather than an identification. The second sentence is what stops the rule becoming a trap -- it says how to get OUT of the section, because a user who wants no seller block at all must be able to empty it.
  ///
  /// In fa, this message translates to:
  /// **'برای چاپ مشخصات فروشنده، نام کسب‌وکار لازم است. برای حذف کامل این بخش، همه فیلدها را خالی بگذارید.'**
  String get settingsErrorSellerNameRequired;

  /// No description provided for @settingsSellerSaved.
  ///
  /// In fa, this message translates to:
  /// **'مشخصات فروشنده ذخیره شد.'**
  String get settingsSellerSaved;

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
  /// **'مشاهده همه'**
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
  /// **'تخفیف سطر {line}: {requested} {unit} وارد شده بود، اما این سطر بیش از {applied} {unit} ارزش ندارد و تنها همین مبلغ کسر شد.'**
  String invoiceWarningLineDiscountClamped(
    String line,
    String requested,
    String applied,
    String unit,
  );

  /// D-027: the invoice-level discount exceeded the subtotal and was capped. This one MUST be capped -- it is part of the reconciliation invariant and an uncapped one produces a negative grand total, which is never a valid document -- but the user is still told, with both figures.
  ///
  /// In fa, this message translates to:
  /// **'تخفیف کل فاکتور: {requested} {unit} وارد شده بود، اما جمع فاکتور بیش از {applied} {unit} نیست و تنها همین مبلغ کسر شد.'**
  String invoiceWarningInvoiceDiscountClamped(
    String requested,
    String applied,
    String unit,
  );

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

  /// No description provided for @invoiceDetailsToggle.
  ///
  /// In fa, this message translates to:
  /// **'نمایش یا پنهان کردن مشخصات فاکتور'**
  String get invoiceDetailsToggle;

  /// No description provided for @invoiceDetailsCollapsedNoCustomer.
  ///
  /// In fa, this message translates to:
  /// **'مشتری انتخاب نشده'**
  String get invoiceDetailsCollapsedNoCustomer;

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

  /// No description provided for @invoiceCreateTitle.
  ///
  /// In fa, this message translates to:
  /// **'فاکتور جدید'**
  String get invoiceCreateTitle;

  /// No description provided for @invoiceCreateAction.
  ///
  /// In fa, this message translates to:
  /// **'فاکتور جدید'**
  String get invoiceCreateAction;

  /// No description provided for @invoiceSummaryTitle.
  ///
  /// In fa, this message translates to:
  /// **'جمع‌بندی'**
  String get invoiceSummaryTitle;

  /// No description provided for @invoiceSummaryGross.
  ///
  /// In fa, this message translates to:
  /// **'جمع سطرها'**
  String get invoiceSummaryGross;

  /// No description provided for @invoiceSummaryDiscount.
  ///
  /// In fa, this message translates to:
  /// **'کسر تخفیف'**
  String get invoiceSummaryDiscount;

  /// No description provided for @invoiceSummaryTax.
  ///
  /// In fa, this message translates to:
  /// **'مالیات بر ارزش افزوده'**
  String get invoiceSummaryTax;

  /// No description provided for @invoiceSummaryRounding.
  ///
  /// In fa, this message translates to:
  /// **'رند کردن'**
  String get invoiceSummaryRounding;

  /// No description provided for @invoiceSummaryGrandTotal.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ قابل پرداخت'**
  String get invoiceSummaryGrandTotal;

  /// No description provided for @invoiceSummaryEmpty.
  ///
  /// In fa, this message translates to:
  /// **'با افزودن سطر، مبلغ فاکتور همین‌جا محاسبه می‌شود.'**
  String get invoiceSummaryEmpty;

  /// Stands where a monetary figure would be, on an invoice issued before schema v4 whose stored numbers the backfill could not reconcile to the Rial (D-055). Deliberately NOT «۰ تومان»: zero is a figure a document prints, and a gross of zero beside a real grand total is a document contradicting itself, where an admission is only one that is incomplete. Deliberately not blank, on «بدون شماره»'s principle: an empty cell reads as data that failed to load. «ثبت‌نشده» states a fact about the record -- it was never written down -- rather than claiming uncertainty about the world, which «نامشخص» would. Short enough for a fixed-width table cell on the line table as well as the summary panel.
  ///
  /// In fa, this message translates to:
  /// **'ثبت‌نشده'**
  String get invoiceFigureUnrecorded;

  /// Shown beneath the summary when the gross is unrecorded. Says the two things the user needs: which figure is missing, and that the amount they care about is unaffected. Without the second sentence «ثبت‌نشده» beside a payable amount reads as a fault in the invoice rather than a gap in what was stored about it.
  ///
  /// In fa, this message translates to:
  /// **'جمع سطرهای این فاکتور هنگام صدور ثبت نشده است. مبلغ قابل پرداخت آن درست و بدون تغییر است.'**
  String get invoiceSummaryGrossUnrecordedNote;

  /// No description provided for @invoiceActionSaveDraftHint.
  ///
  /// In fa, this message translates to:
  /// **'قابل ویرایش می‌ماند و شماره نمی‌گیرد.'**
  String get invoiceActionSaveDraftHint;

  /// No description provided for @invoiceIssueConfirmTitle.
  ///
  /// In fa, this message translates to:
  /// **'این فاکتور صادر شود؟'**
  String get invoiceIssueConfirmTitle;

  /// No description provided for @invoiceIssueConfirmBody.
  ///
  /// In fa, this message translates to:
  /// **'با صدور، فاکتور شماره رسمی خود را می‌گیرد و دیگر قابل ویرایش نخواهد بود. برای اصلاح آن باید فاکتور را باطل کنید و فاکتور تازه‌ای صادر کنید.'**
  String get invoiceIssueConfirmBody;

  /// No description provided for @invoiceIssueConfirmAction.
  ///
  /// In fa, this message translates to:
  /// **'صدور و ثبت نهایی'**
  String get invoiceIssueConfirmAction;

  /// No description provided for @invoiceDiscardTitle.
  ///
  /// In fa, this message translates to:
  /// **'این فاکتور رها شود؟'**
  String get invoiceDiscardTitle;

  /// No description provided for @invoiceDiscardBody.
  ///
  /// In fa, this message translates to:
  /// **'این فاکتور هنوز ذخیره نشده است. اگر خارج شوید، آنچه وارد کرده‌اید از بین می‌رود.'**
  String get invoiceDiscardBody;

  /// No description provided for @invoiceDiscardAction.
  ///
  /// In fa, this message translates to:
  /// **'رها کردن'**
  String get invoiceDiscardAction;

  /// No description provided for @invoiceDiscardKeepAction.
  ///
  /// In fa, this message translates to:
  /// **'ادامه ویرایش'**
  String get invoiceDiscardKeepAction;

  /// No description provided for @invoiceBackTooltip.
  ///
  /// In fa, this message translates to:
  /// **'بازگشت به فهرست فاکتورها'**
  String get invoiceBackTooltip;

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

  /// Page title for one invoice. The placeholder arrives from invoiceNumberLabel, already bidi-isolated for a real number and already the Persian «بدون شماره» for a draft, so this string never has to know which it got.
  ///
  /// In fa, this message translates to:
  /// **'فاکتور {number}'**
  String invoiceDetailTitle(String number);

  /// A stale deep link, or the invoice was deleted while the page was opening. Said rather than rendered as an empty document, which would read as an invoice with nothing on it.
  ///
  /// In fa, this message translates to:
  /// **'این فاکتور پیدا نشد'**
  String get invoiceDetailNotFoundTitle;

  /// No description provided for @invoiceDetailNotFoundBody.
  ///
  /// In fa, this message translates to:
  /// **'ممکن است حذف شده باشد. به فهرست فاکتورها برگردید.'**
  String get invoiceDetailNotFoundBody;

  /// No description provided for @invoiceDetailBackToList.
  ///
  /// In fa, this message translates to:
  /// **'فهرست فاکتورها'**
  String get invoiceDetailBackToList;

  /// Heading over the party as the DOCUMENT states them -- Invoice.party, never the live customer row (D-052). «طرف حساب» rather than «مشتری» because this is the party named on the document, which after a rename is not the same thing as the customer record.
  ///
  /// In fa, this message translates to:
  /// **'طرف حساب'**
  String get invoiceDetailPartySection;

  /// The customer record has changed since the invoice was issued, so the screen is showing the snapshot and the customer list shows something else. Without this the snapshot reads as stale data rather than as the document's own statement (D-052).
  ///
  /// In fa, this message translates to:
  /// **'نام یا مشخصات این مشتری پس از صدور فاکتور تغییر کرده است. آنچه در بالا آمده همان چیزی است که روی این سند ثبت شده و تغییر نمی‌کند.'**
  String get invoiceDetailPartyDiverged;

  /// The live record's current name, shown beside the diverged notice so the user can find the customer in the list. Named as the record, not as a correction -- neither one is wrong.
  ///
  /// In fa, this message translates to:
  /// **'در پرونده مشتری: {name}'**
  String invoiceDetailPartyRecordNow(String name);

  /// A draft has no snapshot on purpose: it is not a document yet and should pick up a correction (D-052). Says both halves -- what is true now, and what changes at issue.
  ///
  /// In fa, this message translates to:
  /// **'این فاکتور هنوز صادر نشده است، بنابراین مشخصات بالا از پرونده فعلی مشتری خوانده می‌شود و با اصلاح آن پرونده تغییر می‌کند. با صدور فاکتور، این مشخصات ثبت و ثابت می‌شوند.'**
  String get invoiceDetailPartyDraft;

  /// An invoice issued before schema v3 has no party snapshot and never will (D-052 refuses to fabricate one). The same admission «ثبت‌نشده» makes for a missing figure, applied to the party -- with the reassurance that the money is unaffected, for the reason invoiceSummaryGrossUnrecordedNote carries one.
  ///
  /// In fa, this message translates to:
  /// **'مشخصات طرف حساب این فاکتور هنگام صدور ثبت نشده است، بنابراین آنچه در بالا آمده از پرونده فعلی مشتری خوانده می‌شود. مبالغ فاکتور از این موضوع اثر نمی‌گیرند.'**
  String get invoiceDetailPartyNoSnapshot;

  /// The customer row is soft-deleted. Restates the promise the delete dialog made, at the moment the user would otherwise wonder whether the invoice is broken.
  ///
  /// In fa, this message translates to:
  /// **'این مشتری از فهرست مشتریان حذف شده است. فاکتورهای او دست‌نخورده باقی می‌مانند.'**
  String get invoiceDetailCustomerDeleted;

  /// Leads to the LIVE customer record, which is what detail.customer is for -- never to the snapshot, which is not a row and has nowhere to lead.
  ///
  /// In fa, this message translates to:
  /// **'رفتن به پرونده مشتری'**
  String get invoiceDetailGoToCustomer;

  /// The mobile number, which is deliberately not part of the party snapshot: contact detail, not document content, and it should resolve live so a reprint next year reaches the number the customer has now (D-052).
  ///
  /// In fa, this message translates to:
  /// **'تماس'**
  String get invoiceDetailContactSection;

  /// No description provided for @invoiceDetailIssueDate.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ صدور'**
  String get invoiceDetailIssueDate;

  /// No description provided for @invoiceDetailDueDate.
  ///
  /// In fa, this message translates to:
  /// **'سررسید'**
  String get invoiceDetailDueDate;

  /// An invoice with no due date is never overdue -- there is nothing to be late against. Said rather than left blank, on «بدون شماره»'s principle.
  ///
  /// In fa, this message translates to:
  /// **'بدون سررسید'**
  String get invoiceDetailNoDueDate;

  /// No description provided for @invoiceDetailNotesSection.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت'**
  String get invoiceDetailNotesSection;

  /// No description provided for @invoiceDetailLinesSection.
  ///
  /// In fa, this message translates to:
  /// **'سطرهای فاکتور'**
  String get invoiceDetailLinesSection;

  /// A saved invoice with no lines. Rare but reachable, and it is the one case where a gross of zero is a real figure rather than a missing one (D-056).
  ///
  /// In fa, this message translates to:
  /// **'این فاکتور سطری ندارد.'**
  String get invoiceDetailNoLines;

  /// No description provided for @invoiceDetailPaidLabel.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت‌شده'**
  String get invoiceDetailPaidLabel;

  /// No description provided for @invoiceDetailDueLabel.
  ///
  /// In fa, this message translates to:
  /// **'مانده'**
  String get invoiceDetailDueLabel;

  /// An overpayment is invisible in the remaining balance by design -- it clamps at zero, because an invoice cannot owe money. Surfaced rather than hidden: it is usually a data-entry error.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ پرداختی از مبلغ فاکتور بیشتر است.'**
  String get invoiceDetailOverpaidNote;

  /// unitPrice x quantity, before any discount (section 4 step 1) -- the column an Iranian invoice prints as مبلغ کل. Stored since schema v4 and NEVER recomputed at a read site (D-055); null on a pre-v4 row the backfill refused, where the cell says «ثبت‌نشده».
  ///
  /// In fa, this message translates to:
  /// **'مبلغ کل'**
  String get invoiceLineColumnGross;

  /// This line's share of the invoice-level discount, allocated by largest remainder (section 4 step 4) and stored since v4. Without it the line's net cannot be explained on the document -- it is already net of this amount and the summary deducts the same discount again.
  ///
  /// In fa, this message translates to:
  /// **'سهم تخفیف فاکتور {amount}'**
  String invoiceLineLabelInvoiceDiscountShare(String amount);

  /// The line after both deductions, before tax -- مبلغ پس از تخفیف on the printed line.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ پس از تخفیف {amount}'**
  String invoiceLineLabelNet(String amount);

  /// The line's gross on a card, where there are no columns to put it in. The stored figure (D-055) -- never unitPrice x quantity worked out at the read site. Bare grouped numerals, matching the other detail lines on the same card, whose unit is carried by the amount above them.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ کل {amount}'**
  String invoiceLineLabelGross(String amount);

  /// The line's unit price as a detail line rather than a column, for the document table shape that gave that column up to keep the description readable (D-065). Worded like invoiceLineLabelGross, because it is the same kind of statement about the same kind of figure.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ واحد {amount}'**
  String invoiceLineLabelUnitPrice(String amount);

  /// The resolved rate AND the tax it came to, on a stored document line. The editor's invoiceLineLabelTax shows the rate alone, which is right on a form where the amount is a row away and about to change; on a document the amount is what the customer reconciles.
  ///
  /// In fa, this message translates to:
  /// **'مالیات {rate}: {amount}'**
  String invoiceLineLabelTaxAmount(String rate, String amount);

  /// The bare label, for the case where the share itself was never recorded and invoiceLineLabelUnrecorded has to name which figure is missing. Kept apart from invoiceLineLabelInvoiceDiscountShare so the two cannot drift into naming the same figure differently.
  ///
  /// In fa, this message translates to:
  /// **'سهم تخفیف فاکتور'**
  String get invoiceDetailInvoiceDiscountShareLabel;

  /// A line-level figure that was never recorded (D-055). Keeps the label so the user can see WHICH figure is missing, instead of a row that quietly has one fewer fact on it than its neighbours.
  ///
  /// In fa, this message translates to:
  /// **'{label} ثبت‌نشده'**
  String invoiceLineLabelUnrecorded(String label);

  /// No description provided for @paymentMethodCash.
  ///
  /// In fa, this message translates to:
  /// **'نقدی'**
  String get paymentMethodCash;

  /// The everyday Iranian card-to-card transfer. Named as people name it, not as a bank would.
  ///
  /// In fa, this message translates to:
  /// **'کارت به کارت'**
  String get paymentMethodCardTransfer;

  /// No description provided for @paymentMethodBankTransfer.
  ///
  /// In fa, this message translates to:
  /// **'انتقال بانکی'**
  String get paymentMethodBankTransfer;

  /// No description provided for @paymentMethodCheque.
  ///
  /// In fa, this message translates to:
  /// **'چک'**
  String get paymentMethodCheque;

  /// No description provided for @paymentMethodOther.
  ///
  /// In fa, this message translates to:
  /// **'سایر'**
  String get paymentMethodOther;

  /// No description provided for @invoiceDetailPaymentsSection.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت‌ها'**
  String get invoiceDetailPaymentsSection;

  /// The designed empty state for the payments list. States the fact rather than leaving a blank region that reads as a section that failed to load.
  ///
  /// In fa, this message translates to:
  /// **'هنوز پرداختی برای این فاکتور ثبت نشده است.'**
  String get invoiceDetailPaymentsEmpty;

  /// No description provided for @invoiceDetailRecordPayment.
  ///
  /// In fa, this message translates to:
  /// **'ثبت پرداخت'**
  String get invoiceDetailRecordPayment;

  /// Why the record button is absent on a draft, said rather than left to be guessed. The repository refuses this too (PaymentNotAccepted) -- the screen does not enforce the rule, it explains it.
  ///
  /// In fa, this message translates to:
  /// **'برای ثبت پرداخت، ابتدا فاکتور را صادر کنید. پیش‌نویس هنوز مطالبه‌ای از کسی نیست.'**
  String get invoiceDetailPaymentsUnavailableDraft;

  /// Explains the refusal rather than only stating it, and names the way forward: the correction path is a replacement invoice, so a payment received against a cancelled document belongs on that one. Deleting a payment from a cancelled invoice stays allowed — see paymentDeleteBodyCancelled.
  ///
  /// In fa, this message translates to:
  /// **'این فاکتور باطل شده است و دیگر مطالبه‌ای از کسی نیست، بنابراین پرداخت تازه‌ای برای آن ثبت نمی‌شود. اگر مبلغی دریافت کرده‌اید، آن را روی فاکتور جایگزین ثبت کنید.'**
  String get invoiceDetailPaymentsUnavailableCancelled;

  /// No description provided for @paymentCreateTitle.
  ///
  /// In fa, this message translates to:
  /// **'ثبت پرداخت'**
  String get paymentCreateTitle;

  /// No description provided for @paymentFieldAmount.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ پرداختی'**
  String get paymentFieldAmount;

  /// No description provided for @paymentFieldDate.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ پرداخت'**
  String get paymentFieldDate;

  /// No description provided for @paymentFieldMethod.
  ///
  /// In fa, this message translates to:
  /// **'روش پرداخت'**
  String get paymentFieldMethod;

  /// No description provided for @paymentFieldNote.
  ///
  /// In fa, this message translates to:
  /// **'توضیح'**
  String get paymentFieldNote;

  /// No description provided for @paymentFieldNoteHint.
  ///
  /// In fa, this message translates to:
  /// **'شماره چک، مرجع تراکنش، یا هر یادداشت دیگر'**
  String get paymentFieldNoteHint;

  /// What is still owed, shown under the amount field so the common case -- paying off the rest -- needs no arithmetic from the user. It is InvoiceDetail.amountDue, read, never recomputed here. The unit is a placeholder rather than a word in the sentence because the user chooses it (D-117).
  ///
  /// In fa, this message translates to:
  /// **'مانده: {amount} {unit}'**
  String paymentAmountRemainingHelper(String amount, String unit);

  /// Fills the amount field with the outstanding balance. A convenience over the figure above it, not a second source for it.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت کامل مانده'**
  String get paymentAmountFillRemaining;

  /// A warning, not a refusal. Overpayment is a real thing that happens and the repository accepts it; it is usually a data-entry error, so it is said before the write rather than discovered on the invoice afterwards.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ واردشده از مانده بیشتر است و به عنوان اضافه‌پرداخت ثبت می‌شود.'**
  String get paymentAmountExceedsDue;

  /// The repository refuses a zero or negative payment (PaymentNotAccepted). Caught at the field so the user is told where the problem is instead of meeting a failed save.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ باید بزرگ‌تر از صفر باشد.'**
  String get validationAmountPositive;

  /// No description provided for @paymentDeleteTitle.
  ///
  /// In fa, this message translates to:
  /// **'این پرداخت حذف شود؟'**
  String get paymentDeleteTitle;

  /// Names the amount being removed and its direct consequence. The status change is stated separately, because it only applies to some invoices. The unit is a placeholder because the user chooses it (D-117).
  ///
  /// In fa, this message translates to:
  /// **'{amount} {unit} از پرداخت‌های این فاکتور حذف می‌شود و مانده به همان اندازه افزایش می‌یابد.'**
  String paymentDeleteBody(String amount, String unit);

  /// Shown only when removing this payment actually moves the invoice out of paid. Deleting a payment recomputes the derived status in the same transaction (section 6), and a badge that changed without warning would look like a fault.
  ///
  /// In fa, this message translates to:
  /// **'با این کار وضعیت فاکتور از «پرداخت شده» خارج می‌شود.'**
  String get paymentDeleteStatusWarning;

  /// No description provided for @paymentDeleteAction.
  ///
  /// In fa, this message translates to:
  /// **'حذف پرداخت'**
  String get paymentDeleteAction;

  /// No description provided for @paymentDeleteFailed.
  ///
  /// In fa, this message translates to:
  /// **'حذف این پرداخت ممکن نشد.'**
  String get paymentDeleteFailed;

  /// No description provided for @paymentSaveFailed.
  ///
  /// In fa, this message translates to:
  /// **'ثبت این پرداخت ممکن نشد.'**
  String get paymentSaveFailed;

  /// The menu item and the confirming button, deliberately the same words. Distinct from actionCancel, which is a dialog's «انصراف» and means the opposite here.
  ///
  /// In fa, this message translates to:
  /// **'ابطال فاکتور'**
  String get invoiceCancelAction;

  /// No description provided for @invoiceCancelTitle.
  ///
  /// In fa, this message translates to:
  /// **'این فاکتور باطل شود؟'**
  String get invoiceCancelTitle;

  /// Cancellation is the correction path, so the copy states what it does and what it does not do before the user commits: the record stays, the number stays spent (D-013), and editing is still not the way back. A confirmation that only asks «are you sure» is one people learn to dismiss.
  ///
  /// In fa, this message translates to:
  /// **'فاکتور حذف نمی‌شود؛ در سوابق می‌ماند و «باطل شده» علامت می‌خورد. شماره آن آزاد نمی‌شود و به هیچ فاکتور دیگری داده نمی‌شود. ابطال برگشت‌پذیر نیست و فاکتور پس از آن قابل ویرایش نیست؛ برای اصلاح، فاکتور تازه‌ای صادر کنید.'**
  String get invoiceCancelBody;

  /// Shown only when the invoice actually carries payments (D-060's rule). Cancelling never touches the payments table (D-061), and a user cancelling a part-paid invoice must be told that before committing, not discover it afterwards. The unit is a placeholder because the user chooses it (D-117).
  ///
  /// In fa, this message translates to:
  /// **'{amount} {unit} پرداختی که تاکنون ثبت شده حذف نمی‌شود و بازگردانده نمی‌شود. ابطال، فاکتور را باطل می‌کند نه پولی را که دریافت شده است.'**
  String invoiceCancelPaymentsNote(String amount, String unit);

  /// Shown on every cancellation dialog. Closes the discoverability half of D-105: deletion is offered only after cancellation, so a user looking for a way to clear a mistaken or test invoice would otherwise see only the cancel action and conclude the document is permanent -- which is what was reported from the phone. This is the one place they are standing when the answer is relevant.
  ///
  /// In fa, this message translates to:
  /// **'پس از ابطال، می‌توانید این فاکتور را به‌کلی حذف کنید.'**
  String get invoiceCancelThenDeleteNote;

  /// Restates the half of the outcome that is easiest to doubt afterwards. Where there are no payments the sentence is still true and still harmless.
  ///
  /// In fa, this message translates to:
  /// **'فاکتور باطل شد. پرداخت‌های ثبت‌شده دست‌نخورده ماند.'**
  String get invoiceCancelSuccess;

  /// No description provided for @invoiceCancelFailed.
  ///
  /// In fa, this message translates to:
  /// **'ابطال این فاکتور ممکن نشد.'**
  String get invoiceCancelFailed;

  /// Opens the filter sheet. In the page title row, where it costs no vertical space at any tier (section 10's unbounded-card rule).
  ///
  /// In fa, this message translates to:
  /// **'فیلترها'**
  String get invoiceFilterAction;

  /// No description provided for @invoiceFilterTitle.
  ///
  /// In fa, this message translates to:
  /// **'فیلتر فاکتورها'**
  String get invoiceFilterTitle;

  /// Says what the button does rather than repeating the sheet's title. The filter is already live as the user taps; this dismisses the sheet.
  ///
  /// In fa, this message translates to:
  /// **'نمایش نتایج'**
  String get invoiceFilterApply;

  /// No description provided for @invoiceFilterClearAll.
  ///
  /// In fa, this message translates to:
  /// **'پاک کردن همه'**
  String get invoiceFilterClearAll;

  /// No description provided for @invoiceFilterStatusSection.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت'**
  String get invoiceFilterStatusSection;

  /// No description provided for @invoiceFilterCustomerSection.
  ///
  /// In fa, this message translates to:
  /// **'مشتری'**
  String get invoiceFilterCustomerSection;

  /// No description provided for @invoiceFilterPeriodSection.
  ///
  /// In fa, this message translates to:
  /// **'بازه زمانی'**
  String get invoiceFilterPeriodSection;

  /// No description provided for @invoiceFilterCustomerAny.
  ///
  /// In fa, this message translates to:
  /// **'همه مشتریان'**
  String get invoiceFilterCustomerAny;

  /// No description provided for @invoiceFilterCustomerChoose.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب مشتری'**
  String get invoiceFilterCustomerChoose;

  /// No description provided for @invoiceFilterPeriodAny.
  ///
  /// In fa, this message translates to:
  /// **'همه تاریخ‌ها'**
  String get invoiceFilterPeriodAny;

  /// The current JALALI month, not the Gregorian one (section 5, D-006). «فروش این ماه» on the dashboard means the same thing.
  ///
  /// In fa, this message translates to:
  /// **'این ماه'**
  String get invoiceFilterPeriodThisMonth;

  /// No description provided for @invoiceFilterPeriodLastMonth.
  ///
  /// In fa, this message translates to:
  /// **'ماه گذشته'**
  String get invoiceFilterPeriodLastMonth;

  /// The current Jalali year.
  ///
  /// In fa, this message translates to:
  /// **'امسال'**
  String get invoiceFilterPeriodThisYear;

  /// Opens two Jalali calendars in turn, for a start day and an end day. The presets answer the questions a billing application is usually asked; this answers the rest, and it is a Jalali calendar rather than a Gregorian one for the reason section 5 gives about every other date in this application.
  ///
  /// In fa, this message translates to:
  /// **'بازه دلخواه'**
  String get invoiceFilterPeriodCustom;

  /// The chosen custom range, on the chip, replacing «بازه دلخواه» once it is set. Both ends arrive already formatted by formatJalaliDate, which bidi-isolates each so the slashes cannot reorder; the word between them is copy and lives here.
  ///
  /// In fa, this message translates to:
  /// **'{from} تا {to}'**
  String invoiceFilterPeriodCustomRange(String from, String to);

  /// The heading of the first of the two calendars. Two identical dialogs headed «انتخاب تاریخ» give the user no way to tell which end of the range they are on.
  ///
  /// In fa, this message translates to:
  /// **'از تاریخ'**
  String get invoiceFilterPeriodCustomFrom;

  /// The heading of the second calendar. Days before the chosen start are shown but not selectable, so an empty range cannot be expressed.
  ///
  /// In fa, this message translates to:
  /// **'تا تاریخ'**
  String get invoiceFilterPeriodCustomTo;

  /// The badge on the filter control. A user who has narrowed the list must be able to see that they have, or an empty list reads as lost data.
  ///
  /// In fa, this message translates to:
  /// **'{count} فیلتر فعال'**
  String invoiceFilterActiveLabel(String count);

  /// A distinct state from «هنوز فاکتوری ثبت نشده». Telling a user with 400 invoices that they have none would be false, and would send them looking for lost data.
  ///
  /// In fa, this message translates to:
  /// **'فاکتوری با این فیلترها پیدا نشد'**
  String get emptyInvoicesFilteredTitle;

  /// No description provided for @emptyInvoicesFilteredBody.
  ///
  /// In fa, this message translates to:
  /// **'هیچ فاکتوری با فیلترهای انتخاب‌شده مطابقت ندارد. فیلترها را تغییر دهید یا پاک کنید.'**
  String get emptyInvoicesFilteredBody;

  /// The remaining balance is still shown, because hiding a figure is worse than explaining it — but on a void document it would otherwise read as money still owed.
  ///
  /// In fa, this message translates to:
  /// **'این فاکتور باطل شده است؛ مانده‌ی آن مطالبه‌ای از مشتری نیست.'**
  String get invoiceDetailCancelledDueNote;

  /// Shown on a cancelled invoice that carries payments (D-061). A void document showing a paid amount with no explanation reads as a fault in the software rather than as a fact about the record.
  ///
  /// In fa, this message translates to:
  /// **'این فاکتور باطل شده است، اما پرداخت‌های زیر واقعاً دریافت شده‌اند و در سوابق می‌مانند. ابطال، پرداختی را حذف یا بازنمی‌گرداند.'**
  String get invoiceDetailCancelledPaymentsNote;

  /// The cancelled invoice's version of paymentDeleteBody. «مانده افزایش می‌یابد» is false there — nothing is owed on a void document — and the fact worth stating instead is that correcting the money record does not resurrect the invoice (D-061). The unit is a placeholder because the user chooses it (D-117).
  ///
  /// In fa, this message translates to:
  /// **'{amount} {unit} از پرداخت‌های این فاکتور حذف می‌شود. فاکتور باطل شده است و باطل می‌ماند؛ این کار فقط سابقه پرداخت را اصلاح می‌کند.'**
  String paymentDeleteBodyCancelled(String amount, String unit);

  /// No description provided for @settingsEditTitle.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش تنظیمات فاکتور'**
  String get settingsEditTitle;

  /// No description provided for @settingsEditTooltip.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش'**
  String get settingsEditTooltip;

  /// No description provided for @settingsFieldTaxRate.
  ///
  /// In fa, this message translates to:
  /// **'نرخ مالیات بر ارزش افزوده'**
  String get settingsFieldTaxRate;

  /// States the property that makes the field safe to change at all: every invoice item snapshots the rate that applied to it (D-026).
  ///
  /// In fa, this message translates to:
  /// **'به درصد. تغییر آن روی فاکتورهای قبلی اثری ندارد.'**
  String get settingsFieldTaxRateHint;

  /// No description provided for @settingsFieldPrefix.
  ///
  /// In fa, this message translates to:
  /// **'پیشوند شماره فاکتور'**
  String get settingsFieldPrefix;

  /// No description provided for @settingsFieldPrefixHint.
  ///
  /// In fa, this message translates to:
  /// **'مثلاً INV در INV-۱۴۰۵-۰۰۰۱. شماره‌های صادرشده تغییر نمی‌کنند.'**
  String get settingsFieldPrefixHint;

  /// No description provided for @settingsFieldPaymentTerm.
  ///
  /// In fa, this message translates to:
  /// **'مهلت پرداخت پیش‌فرض'**
  String get settingsFieldPaymentTerm;

  /// No description provided for @settingsFieldPaymentTermHint.
  ///
  /// In fa, this message translates to:
  /// **'تعداد روز پس از صدور فاکتور.'**
  String get settingsFieldPaymentTermHint;

  /// No description provided for @settingsErrorTaxRateRange.
  ///
  /// In fa, this message translates to:
  /// **'نرخ مالیات باید بین ۰ تا ۱۰۰ درصد باشد.'**
  String get settingsErrorTaxRateRange;

  /// A negative term would produce an invoice due before it was issued (known issue 6). AppSettings deliberately does not clamp, so the form must refuse.
  ///
  /// In fa, this message translates to:
  /// **'مهلت پرداخت باید بین ۰ تا ۷۳۰ روز باشد.'**
  String get settingsErrorPaymentTermRange;

  /// No description provided for @settingsErrorPrefixEmpty.
  ///
  /// In fa, this message translates to:
  /// **'پیشوند نمی‌تواند خالی باشد.'**
  String get settingsErrorPrefixEmpty;

  /// No description provided for @settingsSaved.
  ///
  /// In fa, this message translates to:
  /// **'تنظیمات ذخیره شد.'**
  String get settingsSaved;

  /// No description provided for @backupExportAction.
  ///
  /// In fa, this message translates to:
  /// **'تهیه پشتیبان'**
  String get backupExportAction;

  /// No description provided for @backupImportAction.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی از پشتیبان'**
  String get backupImportAction;

  /// No description provided for @backupPasswordTitle.
  ///
  /// In fa, this message translates to:
  /// **'گذرواژه فایل پشتیبان'**
  String get backupPasswordTitle;

  /// No description provided for @backupPasswordField.
  ///
  /// In fa, this message translates to:
  /// **'گذرواژه'**
  String get backupPasswordField;

  /// No description provided for @backupPasswordRepeatField.
  ///
  /// In fa, this message translates to:
  /// **'تکرار گذرواژه'**
  String get backupPasswordRepeatField;

  /// the project spec requires this to be stated plainly in Persian. There is no recovery path and nobody who can help, so the copy says so rather than softening it. CORRECTED 2026-09-02, D-079 -- THE OLD WARNING HERE WAS WRONG. It said that two more lines of Persian would push the save button under the keyboard, reading the 16 logical pixels between the button and the keyboard as slack that copy growth could eat. It is not slack: it is AppSpacing.lg, the padding EditorSheet puts under its action inside a SafeArea, and every sheet in the application reports exactly the same 16.0 for that reason. Growing this string CANNOT move the button, because EditorSheet caps the field area and scrolls it while the action stays pinned -- that is what the primitive is for (D-062). What growing it actually costs is that the warning starts needing a scroll to read, which matters because section 8 wants it read BEFORE the password is chosen, not found afterwards. So keep it short for legibility, not for layout. Both keyboard guards now assert the clearance against AppSpacing.lg itself, so a change to the primitive fails a test rather than being rediscovered on a phone.
  ///
  /// In fa, this message translates to:
  /// **'این گذرواژه در هیچ کجا ذخیره نمی‌شود. اگر آن را فراموش کنید، هیچ راهی برای باز کردن فایل پشتیبان وجود ندارد و اطلاعات آن برای همیشه از دست می‌رود.'**
  String get backupPasswordWarning;

  /// No description provided for @backupPasswordEmpty.
  ///
  /// In fa, this message translates to:
  /// **'گذرواژه را وارد کنید.'**
  String get backupPasswordEmpty;

  /// No description provided for @backupPasswordMismatch.
  ///
  /// In fa, this message translates to:
  /// **'دو گذرواژه یکسان نیستند.'**
  String get backupPasswordMismatch;

  /// No description provided for @backupPasswordTooShort.
  ///
  /// In fa, this message translates to:
  /// **'گذرواژه باید دست‌کم ۸ نویسه باشد.'**
  String get backupPasswordTooShort;

  /// No description provided for @backupExportInProgress.
  ///
  /// In fa, this message translates to:
  /// **'در حال تهیه پشتیبان…'**
  String get backupExportInProgress;

  /// No description provided for @backupExportDone.
  ///
  /// In fa, this message translates to:
  /// **'فایل پشتیبان ذخیره شد.'**
  String get backupExportDone;

  /// No description provided for @backupImportPasswordTitle.
  ///
  /// In fa, this message translates to:
  /// **'گذرواژه این فایل پشتیبان'**
  String get backupImportPasswordTitle;

  /// No description provided for @backupImportInProgress.
  ///
  /// In fa, this message translates to:
  /// **'در حال بازیابی…'**
  String get backupImportInProgress;

  /// No description provided for @backupImportDone.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی انجام شد.'**
  String get backupImportDone;

  /// No description provided for @backupImportConfirmTitle.
  ///
  /// In fa, this message translates to:
  /// **'جایگزینی همه اطلاعات'**
  String get backupImportConfirmTitle;

  /// The replace-not-merge sentence, required by D-069 as a data-loss guard: a user who expects a merge loses everything entered since the backup and has no reason to expect it, because «restore» implies addition to most people.
  ///
  /// In fa, this message translates to:
  /// **'با بازیابی، همه اطلاعات فعلی این دستگاه حذف و با محتوای فایل پشتیبان جایگزین می‌شود. اطلاعات دو مجموعه با هم ادغام نمی‌شوند.'**
  String get backupImportConfirmReplaces;

  /// No description provided for @backupImportConfirmLoses.
  ///
  /// In fa, this message translates to:
  /// **'هر چیزی که پس از تهیه این پشتیبان ثبت کرده‌اید از بین می‌رود.'**
  String get backupImportConfirmLoses;

  /// No description provided for @backupImportConfirmContents.
  ///
  /// In fa, this message translates to:
  /// **'محتوای فایل: {customers} مشتری، {invoices} فاکتور، {payments} پرداخت.'**
  String backupImportConfirmContents(
    String customers,
    String invoices,
    String payments,
  );

  /// No description provided for @backupImportConfirmDate.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ تهیه: {date}'**
  String backupImportConfirmDate(String date);

  /// No description provided for @backupImportConfirmAction.
  ///
  /// In fa, this message translates to:
  /// **'جایگزین کن'**
  String get backupImportConfirmAction;

  /// Export failed. The file is deleted on any failure, so there is never a half-written backup to explain away.
  ///
  /// In fa, this message translates to:
  /// **'تهیه پشتیبان انجام نشد'**
  String get errorBackupExportFailedTitle;

  /// No description provided for @errorBackupExportFailedBody.
  ///
  /// In fa, this message translates to:
  /// **'فایل پشتیبان ساخته نشد. لطفاً دوباره تلاش کنید.'**
  String get errorBackupExportFailedBody;

  /// Covers a wrong password, a corrupted file and a tampered file together, because SQLCipher cannot tell them apart -- so the copy names both plausible remedies instead of guessing one (D-069).
  ///
  /// In fa, this message translates to:
  /// **'فایل پشتیبان باز نشد'**
  String get errorBackupCannotOpenTitle;

  /// No description provided for @errorBackupCannotOpenBody.
  ///
  /// In fa, this message translates to:
  /// **'گذرواژه نادرست است یا فایل آسیب دیده. گذرواژه را دوباره وارد کنید یا فایل دیگری انتخاب کنید. اطلاعات فعلی شما دست‌نخورده است.'**
  String get errorBackupCannotOpenBody;

  /// No description provided for @errorBackupNotABackupTitle.
  ///
  /// In fa, this message translates to:
  /// **'این فایل پشتیبان فاکتورینو نیست'**
  String get errorBackupNotABackupTitle;

  /// No description provided for @errorBackupNotABackupBody.
  ///
  /// In fa, this message translates to:
  /// **'فایل باز شد اما محتوای آن یک پشتیبان فاکتورینو نیست. فایل دیگری انتخاب کنید. اطلاعات فعلی شما دست‌نخورده است.'**
  String get errorBackupNotABackupBody;

  /// Refused rather than attempted: this build has no migration step for a shape it has never seen. The copy says what to do -- update the app -- rather than only that it failed.
  ///
  /// In fa, this message translates to:
  /// **'این پشتیبان با نسخه جدیدتری ساخته شده است'**
  String get errorBackupFromNewerVersionTitle;

  /// No description provided for @errorBackupFromNewerVersionBody.
  ///
  /// In fa, this message translates to:
  /// **'برای بازیابی این فایل، ابتدا برنامه را به‌روز کنید. اطلاعات فعلی شما دست‌نخورده است.'**
  String get errorBackupFromNewerVersionBody;

  /// No description provided for @errorBackupCountMismatchTitle.
  ///
  /// In fa, this message translates to:
  /// **'فایل پشتیبان ناقص است'**
  String get errorBackupCountMismatchTitle;

  /// No description provided for @errorBackupCountMismatchBody.
  ///
  /// In fa, this message translates to:
  /// **'تعداد رکوردهای داخل فایل با آنچه در آن ثبت شده هم‌خوانی ندارد، بنابراین بازیابی انجام نشد. اطلاعات فعلی شما دست‌نخورده است.'**
  String get errorBackupCountMismatchBody;

  /// The replace-all transaction rolled back. The body leads with the reassurance because it is the one thing the user most needs to know and the one thing they cannot check for themselves.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی انجام نشد'**
  String get errorBackupRestoreFailedTitle;

  /// No description provided for @errorBackupRestoreFailedBody.
  ///
  /// In fa, this message translates to:
  /// **'هیچ تغییری در اطلاعات شما ایجاد نشد و همه‌چیز مانند قبل است. لطفاً دوباره تلاش کنید.'**
  String get errorBackupRestoreFailedBody;

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

  /// The heading of the printed invoice. «فاکتور فروش» is the conventional name of this document in Iran; the in-app title is «فاکتور {number}», which names one invoice rather than the kind of document, and a page held on its own has to say what it is.
  ///
  /// In fa, this message translates to:
  /// **'فاکتور فروش'**
  String get invoiceDocumentTitle;

  /// Printed as a filled band across the top of a draft. The requirement is that somebody HOLDING the page knows it is not final without reading it closely (owner, D-075), so it is set large and reversed out of a solid fill rather than as a line of prose. Keep it short for that reason -- it has to be legible at arm's length. Why a draft is dangerous unmarked: it has no invoice number and its totals can still change, so the customer would hold a document that later disagrees with the invoice, under a number they never saw. Note it carries a ZWNJ, so it exercises the D-073 atom on the largest type on the page.
  ///
  /// In fa, this message translates to:
  /// **'پیش‌نویس — سند نهایی نیست'**
  String get invoiceDocumentDraftBanner;

  /// Printed as a filled band across the top of a cancelled invoice, in the same slot and with the same weight as the draft band. A cancelled document in someone's hands is the one that causes real trouble -- it looks exactly like a valid claim, carries a real invoice number, and may already have been sent -- so it is marked as unmissably as a draft is. Never both: the two statuses are mutually exclusive, and a draft has no cancellation and a cancelled invoice was never a draft. Says «اعتبار ندارد» rather than «لغو شد» because the reader needs to know what the paper in their hand IS, not what happened to it.
  ///
  /// In fa, this message translates to:
  /// **'باطل شده — این فاکتور اعتبار ندارد'**
  String get invoiceDocumentCancelledBanner;

  /// Labels the payment status printed under the payable total: پرداخت شده / پرداخت جزئی / پرداخت نشده, reusing the same strings the screen shows. Placed at the grand total because that is where the eye lands and where 'have I paid this?' is answered. NOT printed on a draft (there is no payment status worth printing on a document that is not yet a claim) and NOT on a cancelled invoice, where «پرداخت نشده» beside the void band would read as a demand to pay it. The overdue state is deliberately never printed: it depends on the day the page is read, and a document is read later than it is made.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت پرداخت'**
  String get invoiceDocumentStatusLabel;

  /// The amount actually received, printed under the payable total but ONLY on an overpaid invoice. It is what makes the اضافه‌پرداخت row below it checkable with a pencil: paid minus the payable total is the excess, and a reader told they overpaid without being told what was received cannot reconcile the claim. Ordinary invoices still print no payment amounts -- the document states what is owed, and a receipt is a different document.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت‌شده'**
  String get invoiceDocumentPaidLabel;

  /// How much more was received than the invoice asked for, printed under the payable total. The screen says an overpayment happened (invoiceDetailOverpaidNote); a document a customer keeps has to say by how much, because the reader cannot open the app to find out. Printed on every status, cancelled included: money received is a fact about what happened, and a void document that silently omits it is the one place the omission matters most.
  ///
  /// In fa, this message translates to:
  /// **'اضافه‌پرداخت'**
  String get invoiceDocumentOverpaidLabel;

  /// Labels the invoice number in the printed header. Deliberately the full «شماره فاکتور» rather than «شماره»: on a page with no other numbered field the short form reads as a form field, and this is the reference the customer quotes when they pay.
  ///
  /// In fa, this message translates to:
  /// **'شماره فاکتور'**
  String get invoiceDocumentNumberLabel;

  /// Heads the party block on the printed invoice. Deliberately NOT the in-app «طرف حساب», which is right on screen where the same record can be read either way. On the document there is one role and «خریدار» is what an Iranian invoice calls it.
  ///
  /// In fa, this message translates to:
  /// **'خریدار'**
  String get invoiceDocumentBuyerHeading;

  /// One factual line under the party block, printed ONLY for an invoice issued before the party snapshot existed (D-052, schema v3), where the document's own statement of the buyer was never stored. It is not an apology and not a warning: it says where the details came from, which is true and is what a reader would otherwise assume wrongly. The other three provenance cases print nothing -- see D-075. Keep it to one sentence; a document that explains itself at length reads as unreliable.
  ///
  /// In fa, this message translates to:
  /// **'مشخصات خریدار از پرونده فعلی مشتری خوانده شده است.'**
  String get invoiceDocumentPartyFromRecord;

  /// The row-number column of the printed lines table. Conventional on an Iranian invoice, and the column a customer points at when they query one line. Narrow: it holds at most three Persian digits.
  ///
  /// In fa, this message translates to:
  /// **'ردیف'**
  String get invoiceDocumentColumnRow;

  /// Heads the seller block on the printed invoice, opposite the buyer block (D-077). A conventional Iranian sales invoice names both parties, and until schema v5 this application could not: the settings row held no business identity at all, so the document carried one block and nothing beside it. The block is printed only when the user has given a business name, and omitted entirely otherwise -- never as a heading over blanks, which reads as a document that failed to print.
  ///
  /// In fa, this message translates to:
  /// **'فروشنده'**
  String get invoiceDocumentSellerHeading;

  /// Labels the seller telephone in the printed block. Its own entry rather than the customer mobile label, because a business published number is as often a landline. The value is drawn as a separate widget from this label and never concatenated with it -- D-070 measured that shape coming out with its digit groups reversed.
  ///
  /// In fa, this message translates to:
  /// **'تلفن'**
  String get invoiceDocumentSellerPhoneLabel;

  /// Shown in the payments card when the invoice is fully paid. It replaces the floating record-payment action, which is hidden once nothing is owed -- the floating slot is for the page's primary action and on a settled invoice recording more money is an exception, not the main thing to do. The sentence exists because hiding a control without saying why is how a page comes to look broken (the same mistake a draft's inert page made). It must keep naming the way in: money genuinely arriving twice is a fact the record has to be able to hold, so an overpayment stays recordable rather than being refused.
  ///
  /// In fa, this message translates to:
  /// **'این فاکتور تسویه شده است. اگر مبلغی دوباره دریافت شد، می‌توانید آن را همین‌جا به‌عنوان اضافه‌پرداخت ثبت کنید.'**
  String get invoiceDetailPaymentsSettled;

  /// Issues a saved draft, from the invoice detail screen. Short, because it is a floating action label on a phone. The confirmation it opens reuses invoiceIssueConfirmTitle/Body/Action, which the editor already had -- the consequences are identical wherever issuing is started from, and two different explanations of one irreversible act is how they drift apart.
  ///
  /// In fa, this message translates to:
  /// **'صدور فاکتور'**
  String get invoiceIssueAction;

  /// Reopens a saved draft in the invoice editor (known issue 29). Only a draft is editable -- section 6 -- so this never appears on an issued invoice, where the correction path is cancellation instead. Says 'edit the draft' rather than 'edit the invoice' for the same reason the delete item does: what is being changed is explicitly not yet an invoice.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش پیش‌نویس'**
  String get invoiceEditDraftAction;

  /// Deletes a draft invoice. Offered only on a draft, in the title row menu beside the export. Says 'delete the draft' rather than 'delete the invoice' because what is being removed is explicitly not yet an invoice -- it has no number and nobody has seen it, which is the whole reason deleting it is allowed where cancelling an issued one is not (section 6).
  ///
  /// In fa, this message translates to:
  /// **'حذف پیش‌نویس'**
  String get invoiceDeleteDraftAction;

  /// The confirmation dialog title. A question, because the action is irreversible from the user's point of view.
  ///
  /// In fa, this message translates to:
  /// **'حذف این پیش‌نویس؟'**
  String get invoiceDeleteDraftTitle;

  /// Says what deleting does and what it costs, the way the cancellation dialog does rather than decaying into 'are you sure?'. Two facts the user cannot see and would otherwise ask about afterwards: no invoice number was spent (a draft never allocates one, D-048) and nothing reached the customer. The deletion is a soft delete in the schema, but that is a sync concern and not something the user can act on, so the copy says 'cannot be brought back' -- which is true of every route they have.
  ///
  /// In fa, this message translates to:
  /// **'این پیش‌نویس از فهرست حذف می‌شود و برگرداندن آن ممکن نیست. چون هنوز صادر نشده، هیچ شماره‌ای مصرف نشده و چیزی برای مشتری ارسال نشده است.'**
  String get invoiceDeleteDraftBody;

  /// No description provided for @invoiceDeleteDraftSuccess.
  ///
  /// In fa, this message translates to:
  /// **'پیش‌نویس حذف شد.'**
  String get invoiceDeleteDraftSuccess;

  /// Friendly Persian, no exception text and no identifier (section 7).
  ///
  /// In fa, this message translates to:
  /// **'حذف پیش‌نویس انجام نشد. دوباره تلاش کنید.'**
  String get invoiceDeleteDraftFailed;

  /// Deletes a cancelled invoice outright (D-105). Says 'delete the invoice' rather than 'delete the draft' because this one is a real numbered document that was issued and then cancelled. Offered only on a cancelled invoice; an issued one must be cancelled first, and a draft gets invoiceDeleteDraftAction instead.
  ///
  /// In fa, this message translates to:
  /// **'حذف فاکتور'**
  String get invoiceDeleteAction;

  /// The confirmation dialog title. A question, because the action cannot be undone from the user's point of view.
  ///
  /// In fa, this message translates to:
  /// **'حذف این فاکتور؟'**
  String get invoiceDeleteTitle;

  /// Says what deleting costs and the one thing it does not change, the way the cancellation dialog does rather than decaying into 'are you sure?'. The fact the user cannot see and would otherwise ask about afterwards is that the invoice number stays spent (D-013): the sequence keeps a gap rather than reusing the identity on a later document. The deletion is a soft delete in the schema, but that is a sync concern the user cannot act on, so the copy says it cannot be brought back -- which is true of every route they have.
  ///
  /// In fa, this message translates to:
  /// **'این فاکتور و سطرهای آن از فهرست‌ها و جمع‌ها حذف می‌شود و برگرداندن آن ممکن نیست. شماره‌ای که به این فاکتور داده شده آزاد نمی‌شود و دوباره به فاکتور دیگری داده نخواهد شد.'**
  String get invoiceDeleteBody;

  /// Shown only where the cancelled invoice actually carries payments, on D-060's rule that a warning printed on every deletion is one nobody reads on the deletion where it matters. It states the difference from cancellation explicitly (D-061 keeps payments, D-105 does not) because a user who has just read the cancellation dialog has been told the opposite and would otherwise carry that expectation into this one. The count arrives already in Persian digits.
  ///
  /// In fa, this message translates to:
  /// **'{count} پرداخت ثبت‌شده روی این فاکتور همراه آن حذف می‌شود. ابطال پرداخت‌ها را نگه می‌دارد، اما حذف نگه نمی‌دارد.'**
  String invoiceDeletePaymentsNote(String count);

  /// No description provided for @invoiceDeleteSuccess.
  ///
  /// In fa, this message translates to:
  /// **'فاکتور حذف شد.'**
  String get invoiceDeleteSuccess;

  /// No description provided for @invoiceDeleteFailed.
  ///
  /// In fa, this message translates to:
  /// **'حذف این فاکتور ممکن نشد.'**
  String get invoiceDeleteFailed;

  /// The menu item on the invoice detail screen that generates the PDF and offers it to the user to save. In the title row menu beside cancellation, per the project spec: an actions card here would be the fourth block added above the invoice lines on this family of screens. Says 'save a PDF copy' rather than 'print' -- nothing is sent to a printer, a file is written where the user chooses.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره نسخه PDF'**
  String get invoiceDocumentExportAction;

  /// Saved, and the automatic open found nothing to open it with -- a phone with no PDF viewer is a real phone. Says which of the two happened rather than reporting only the save, because the user is looking at the application rather than at a document and needs to know why. Carries the «باز کردن» action as a manual retry.
  ///
  /// In fa, this message translates to:
  /// **'فایل فاکتور ذخیره شد، ولی برنامه‌ای برای باز کردن آن پیدا نشد.'**
  String get invoiceDocumentExportSaved;

  /// A failed generation or save. Friendly Persian with no stack trace, no file path and no exception text, per section 7. Says what to do next rather than what went wrong internally, because the internal reason is never something the user can act on.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره فایل فاکتور انجام نشد. دوباره تلاش کنید.'**
  String get invoiceDocumentExportFailed;

  /// The other half of D-077's obligation, rewritten after the owner read it as a broken save (D-101). Three things in order, and the order is the point: **the file saved** (first, plainly, because that is what the user is anxious about), **why the seller block is missing** (their business name is not entered), and **why the document did not open** (so the settings action is not read as a repair for the save). The previous wording said only that the invoice had been saved without a seller section, which left «تنظیمات» looking like a fix for something that had gone wrong.
  ///
  /// In fa, this message translates to:
  /// **'فایل فاکتور ذخیره شد. چون نام کسب‌وکارتان وارد نشده، بخش «فروشنده» روی آن چاپ نشد و فایل باز نشد.'**
  String get invoiceDocumentExportNoSeller;

  /// The action beside the no-seller notice. «تکمیل مشخصات» rather than the bare section name «تنظیمات» (D-101): a button labelled with a destination reads as 'something is wrong, go here', while one labelled with a task says what is incomplete. The message above it has already said which details.
  ///
  /// In fa, this message translates to:
  /// **'تکمیل مشخصات'**
  String get invoiceDocumentExportGoToSettings;

  /// A Jalali date with the time of day beside it, for the invoice header and the printed document. The Persian comma and the word for 'at' live here rather than in a formatter, because they are copy: a translator changes the order and the separator by editing this line. The two placeholders arrive already formatted -- the date from formatJalaliDateLong and the time from formatJalaliTime, which is bidi-isolated so the colon cannot reorder it.
  ///
  /// In fa, this message translates to:
  /// **'{date}، ساعت {time}'**
  String dateAtTime(String date, String time);

  /// An amount and its currency unit as one string, for the few places a figure is a read-only value in a row rather than an AmountText -- the fixed price on an existing invoice line. AmountText remains the way money is drawn everywhere it is drawn as money; this exists so those places still obey section 9's rule that a unit label is always shown, never a bare number.
  ///
  /// In fa, this message translates to:
  /// **'{amount} {unit}'**
  String amountWithUnit(String amount, String unit);

  /// Shown on an existing invoice line, where the quantity is the only editable field (D-090). It says what is fixed and, crucially, names both ways to change it -- edit the product record for a price that is really different, or delete the line and add a free one for a genuine one-off. A note that only refused would leave the user with no route at all.
  ///
  /// In fa, this message translates to:
  /// **'عنوان، قیمت، تخفیف و مالیات این سطر ثابت است. برای تغییر قیمت، محصول را در فهرست محصولات ویرایش کنید؛ برای مبلغی موردی، این سطر را حذف کنید و سطر آزاد تازه‌ای بیفزایید.'**
  String get invoiceLineFixedNote;

  /// The first back press on the dashboard says this; a second one within the same window leaves the application (D-095). An instruction rather than a question, because there is no control to answer it with -- the answer is the next press.
  ///
  /// In fa, this message translates to:
  /// **'برای خروج، دوباره بازگشت را بزنید.'**
  String get exitConfirmPrompt;

  /// The settings section holding the light/dark choice. Named for what it governs rather than 'theme', which is a word from the implementation.
  ///
  /// In fa, this message translates to:
  /// **'نمایش'**
  String get settingsAppearanceSection;

  /// The label above the three-way light/dark control.
  ///
  /// In fa, this message translates to:
  /// **'پوسته روشن و تیره'**
  String get settingsThemeMode;

  /// Explains the third option, which is the only one whose effect is not visible from its own name. Both themes are designed rather than one being an inversion of the other, so following the device is a real choice and not a fallback.
  ///
  /// In fa, this message translates to:
  /// **'با انتخاب «سیستم»، برنامه از تنظیم دستگاه پیروی می‌کند.'**
  String get settingsThemeModeHint;

  /// No description provided for @settingsThemeModeSystem.
  ///
  /// In fa, this message translates to:
  /// **'سیستم'**
  String get settingsThemeModeSystem;

  /// No description provided for @settingsThemeModeLight.
  ///
  /// In fa, this message translates to:
  /// **'روشن'**
  String get settingsThemeModeLight;

  /// No description provided for @settingsThemeModeDark.
  ///
  /// In fa, this message translates to:
  /// **'تیره'**
  String get settingsThemeModeDark;

  /// The action beside the 'file saved' message, which opens the PDF that was just written with whatever reads PDFs on the device (D-091). Offered only where the document is complete -- an invoice saved without a seller block keeps the settings action instead, because that is the one the user should act on first.
  ///
  /// In fa, this message translates to:
  /// **'باز کردن'**
  String get invoiceDocumentExportOpenAction;

  /// A device with nothing that reads PDFs is a real device, so this is a fact rather than an error. It repeats that the file was saved, because the user's worry on seeing a failure message is that the save failed too.
  ///
  /// In fa, this message translates to:
  /// **'برنامه‌ای برای باز کردن فایل PDF پیدا نشد. فایل ذخیره شده است.'**
  String get invoiceDocumentExportOpenFailed;

  /// The subtitle of the collapsed invoice-details heading on the phone, once the customer picker has moved out of that section and been pinned above the scroll (D-096). It lists what is actually behind the fold, so the heading answers 'what is in here' rather than repeating the customer -- which it used to show only because the fold would otherwise have hidden the one field a save cannot do without, and which is no longer true.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ، تخفیف، مالیات و یادداشت'**
  String get invoiceDetailsCollapsedSummary;

  /// The button beside 'issue' and 'save draft' on the invoice form that opens the discount screen (D-098). One word, because it sits between two longer labels in a pinned bar on a phone.
  ///
  /// In fa, this message translates to:
  /// **'تخفیف'**
  String get invoiceDiscountAction;

  /// The discount screen's own heading. Names the whole invoice rather than a line, because the screen covers both levels.
  ///
  /// In fa, this message translates to:
  /// **'تخفیف فاکتور'**
  String get invoiceDiscountTitle;

  /// Commits everything entered on the discount screen at once. Says 'apply' rather than 'save', because nothing is written to the database here -- the invoice is still a form.
  ///
  /// In fa, this message translates to:
  /// **'اعمال تخفیف'**
  String get invoiceDiscountApply;

  /// Heading over the per-line discount controls.
  ///
  /// In fa, this message translates to:
  /// **'تخفیف هر سطر'**
  String get invoiceDiscountLinesSection;

  /// The payable figure as the invoice stands, before anything on this screen is applied. Half of the before-and-after the screen exists to show: applying a discount is an intention, and what the user agrees to is a number.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ فعلی'**
  String get invoiceDiscountPayableNow;

  /// The payable figure this screen's entries would produce. Updates on every keystroke.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ پس از تخفیف'**
  String get invoiceDiscountPayableAfter;

  /// The difference between the two figures, stated rather than left to be worked out -- on the one screen where working it out is what the user came to avoid. Shown only when the two actually differ, so an untouched sheet does not open with a row about nothing. The unit is a placeholder because the user chooses it (D-117).
  ///
  /// In fa, this message translates to:
  /// **'{amount} {unit} کمتر از مبلغ فعلی'**
  String invoiceDiscountChange(String amount, String unit);

  /// Names one line on the discount screen: its position and its title. The number is 1-based and matches the numbering the clamp warnings quote, so a warning about 'line 3' points at the control headed 'line 3'.
  ///
  /// In fa, this message translates to:
  /// **'سطر {number}، {title}'**
  String invoiceDiscountLineHeading(String number, String title);

  /// The ordinary, everything-worked outcome (D-100). **It leads with the opening, not the saving**, so the three export messages differ in their first words rather than in a negation particle buried mid-sentence -- the owner tested the previous build, met the no-seller message instead, and read a working save as a failure (D-101). No action beside it: offering to open a document that is already open is an action that does nothing visible.
  ///
  /// In fa, this message translates to:
  /// **'فاکتور در برنامه PDF باز شد؛ فایل هم ذخیره شد.'**
  String get invoiceDocumentExportSavedAndOpened;

  /// The dashboard prompt shown while the seller name is empty (D-102). Addressed as a task the user has not done yet, not as a warning: an empty seller is the ordinary starting state of every database, not an error.
  ///
  /// In fa, this message translates to:
  /// **'مشخصات کسب‌وکارتان را وارد کنید'**
  String get sellerPromptTitle;

  /// Both consequences, because the second is what actually confused someone: the owner met the no-seller export message, saw it send them to settings, and read a working save as a failure (D-101). Saying here what will happen later is what stops that sequence from being a surprise. Deliberately not a threat -- an empty seller still blocks nothing (D-077), and neither sentence says it does.
  ///
  /// In fa, this message translates to:
  /// **'تا وقتی نام کسب‌وکارتان را وارد نکنید، بخش «فروشنده» روی فاکتور چاپ نمی‌شود — و فایل PDF پس از ذخیره خودبه‌خود باز نمی‌شود.'**
  String get sellerPromptBody;

  /// Opens the seller sheet straight from the dashboard, so the fix is one tap from the prompt rather than a navigation to settings and a second control there. **The same words as the export message's action, deliberately**: the user may meet either first, and two labels for one destination would read as two different repairs.
  ///
  /// In fa, this message translates to:
  /// **'تکمیل مشخصات'**
  String get sellerPromptAction;
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
