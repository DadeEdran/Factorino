// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_strings.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppStringsFa extends AppStrings {
  AppStringsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'فاکتورینو';

  @override
  String get navDashboard => 'داشبورد';

  @override
  String get navInvoices => 'فاکتورها';

  @override
  String get navCustomers => 'مشتریان';

  @override
  String get navProducts => 'محصولات و خدمات';

  @override
  String get navSettings => 'تنظیمات';

  @override
  String get statusDraft => 'پیش‌نویس';

  @override
  String get statusUnpaid => 'پرداخت نشده';

  @override
  String get statusPartiallyPaid => 'پرداخت جزئی';

  @override
  String get statusPaid => 'پرداخت شده';

  @override
  String get statusCancelled => 'لغو شده';

  @override
  String get statusOverdue => 'سررسید گذشته';

  @override
  String get unitToman => 'تومان';

  @override
  String get unitRial => 'ریال';

  @override
  String get dashboardTitle => 'داشبورد';

  @override
  String get dashboardSalesThisMonth => 'فروش این ماه';

  @override
  String get dashboardOutstanding => 'مانده دریافتنی';

  @override
  String get dashboardInvoiceCount => 'فاکتورهای این ماه';

  @override
  String get dashboardCustomerCount => 'مشتریان';

  @override
  String get dashboardRecentInvoices => 'فاکتورهای اخیر';

  @override
  String get emptyDashboardTitle => 'هنوز اطلاعاتی برای نمایش نیست';

  @override
  String get emptyDashboardBody =>
      'با ساختن اولین فاکتور، خلاصهٔ فروش و مانده دریافتنی همین‌جا نمایش داده می‌شود.';

  @override
  String get invoicesTitle => 'فاکتورها';

  @override
  String get emptyInvoicesTitle => 'هنوز فاکتوری ثبت نشده است';

  @override
  String get emptyInvoicesBody =>
      'فاکتورهای شما پس از ثبت، همراه با وضعیت پرداخت در این فهرست نمایش داده می‌شوند.';

  @override
  String get customersTitle => 'مشتریان';

  @override
  String get emptyCustomersTitle => 'هنوز مشتری‌ای ثبت نشده است';

  @override
  String get emptyCustomersBody =>
      'مشتریانی که برایشان فاکتور صادر می‌کنید در این فهرست نگهداری می‌شوند.';

  @override
  String get productsTitle => 'محصولات و خدمات';

  @override
  String get emptyProductsTitle => 'هنوز محصول یا خدمتی ثبت نشده است';

  @override
  String get emptyProductsBody =>
      'کالاها و خدماتی که می‌فروشید را اینجا نگه دارید تا ساختن فاکتور سریع‌تر شود.';

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get settingsInvoicingSection => 'فاکتور';

  @override
  String get settingsDefaultTaxRate => 'نرخ مالیات بر ارزش افزوده';

  @override
  String get settingsDefaultTaxRateHint =>
      'تغییر این نرخ روی فاکتورهای صادرشده اثری ندارد.';

  @override
  String get settingsInvoicePrefix => 'پیشوند شمارهٔ فاکتور';

  @override
  String get settingsRoundingUnit => 'رند کردن مبلغ نهایی';

  @override
  String get settingsBackupSection => 'پشتیبان‌گیری';

  @override
  String get settingsLastBackup => 'آخرین پشتیبان‌گیری';

  @override
  String get settingsLastBackupNever => 'تا کنون پشتیبانی تهیه نشده است';

  @override
  String get tableColumnNumber => 'شماره';

  @override
  String get tableColumnCustomer => 'مشتری';

  @override
  String get tableColumnDate => 'تاریخ';

  @override
  String get tableColumnStatus => 'وضعیت';

  @override
  String get tableColumnAmount => 'مبلغ';

  @override
  String get actionAdd => 'افزودن';

  @override
  String get actionSave => 'ذخیره';

  @override
  String get actionCancel => 'انصراف';

  @override
  String get actionSearch => 'جستجو';

  @override
  String get actionRetry => 'تلاش دوباره';

  @override
  String get nationalIdFormatValid => 'فرمت کد ملی معتبر است';

  @override
  String get nationalIdInvalid => 'کد ملی نامعتبر است';

  @override
  String get monthFarvardin => 'فروردین';

  @override
  String get monthOrdibehesht => 'اردیبهشت';

  @override
  String get monthKhordad => 'خرداد';

  @override
  String get monthTir => 'تیر';

  @override
  String get monthMordad => 'مرداد';

  @override
  String get monthShahrivar => 'شهریور';

  @override
  String get monthMehr => 'مهر';

  @override
  String get monthAban => 'آبان';

  @override
  String get monthAzar => 'آذر';

  @override
  String get monthDey => 'دی';

  @override
  String get monthBahman => 'بهمن';

  @override
  String get monthEsfand => 'اسفند';

  @override
  String get actionEdit => 'ویرایش';

  @override
  String get actionDelete => 'حذف';

  @override
  String get actionClear => 'پاک کردن';

  @override
  String get actionLoadMore => 'نمایش بیشتر';

  @override
  String get actionMore => 'گزینه‌های بیشتر';

  @override
  String get searchNoResultsTitle => 'نتیجه‌ای یافت نشد';

  @override
  String get searchNoResultsBody =>
      'عبارت دیگری را امتحان کنید یا جستجو را پاک کنید.';

  @override
  String get fieldOptional => 'اختیاری';

  @override
  String get validationRequired => 'پر کردن این فیلد الزامی است';

  @override
  String get validationMobileInvalid => 'شماره موبایل معتبر نیست';

  @override
  String get validationAmountInvalid => 'مبلغ معتبر نیست';

  @override
  String get validationAmountTooLarge => 'مبلغ واردشده بیش از حد مجاز است';

  @override
  String get customersSearchHint => 'جستجوی نام یا شرکت';

  @override
  String get customerAdd => 'افزودن مشتری';

  @override
  String get customerCreateTitle => 'مشتری جدید';

  @override
  String get customerEditTitle => 'ویرایش مشتری';

  @override
  String get customerFieldFullName => 'نام و نام خانوادگی';

  @override
  String get customerFieldCompany => 'نام شرکت';

  @override
  String get customerFieldMobile => 'شماره موبایل';

  @override
  String get customerFieldAddress => 'نشانی';

  @override
  String get customerFieldNationalId => 'کد ملی';

  @override
  String get customerFieldEconomicId => 'کد اقتصادی';

  @override
  String get customerFieldNotes => 'یادداشت';

  @override
  String get customerNoMobile => 'شماره‌ای ثبت نشده';

  @override
  String get customerDeleteTitle => 'این مشتری حذف شود؟';

  @override
  String get customerDeleteBody =>
      'مشتری از فهرست برداشته می‌شود، اما فاکتورهایی که پیش‌تر برای او صادر شده دست‌نخورده باقی می‌مانند و مبالغ آن‌ها تغییر نمی‌کند.';

  @override
  String get customerDeleted => 'مشتری حذف شد';

  @override
  String get customerSaved => 'مشتری ذخیره شد';

  @override
  String get productsSearchHint => 'جستجوی محصول یا خدمت';

  @override
  String get productAdd => 'افزودن محصول یا خدمت';

  @override
  String get productCreateTitle => 'محصول یا خدمت جدید';

  @override
  String get productEditTitle => 'ویرایش محصول یا خدمت';

  @override
  String get productFieldName => 'نام';

  @override
  String get productFieldType => 'نوع';

  @override
  String get productFieldPrice => 'قیمت';

  @override
  String get productFieldUnit => 'واحد';

  @override
  String get productFieldUnitHint => 'عدد، کیلوگرم، ساعت، متر';

  @override
  String get productFieldDescription => 'توضیحات';

  @override
  String get productTypeProduct => 'کالا';

  @override
  String get productTypeService => 'خدمت';

  @override
  String get productDeleteTitle => 'این مورد حذف شود؟';

  @override
  String get productDeleteBody =>
      'این مورد از فهرست برداشته می‌شود، اما فاکتورهایی که آن را دربر دارند با همان نام و قیمت زمان صدور حفظ می‌شوند.';

  @override
  String get productDeleted => 'حذف شد';

  @override
  String get productSaved => 'ذخیره شد';

  @override
  String get tableColumnName => 'نام';

  @override
  String get tableColumnMobile => 'موبایل';

  @override
  String get tableColumnCompany => 'شرکت';

  @override
  String get tableColumnType => 'نوع';

  @override
  String get tableColumnUnit => 'واحد';

  @override
  String get tableColumnPrice => 'قیمت';

  @override
  String get errorInvoiceNotEditableTitle => 'این فاکتور قابل ویرایش نیست';

  @override
  String get errorInvoiceNotEditableBody =>
      'فقط پیش‌نویس‌ها را می‌توان تغییر داد. فاکتور صادرشده را باید لغو کرد.';

  @override
  String get errorPaymentNotAcceptedTitle => 'ثبت پرداخت ممکن نیست';

  @override
  String get errorPaymentNotAcceptedBody =>
      'برای این فاکتور در وضعیت فعلی نمی‌توان پرداخت ثبت کرد.';

  @override
  String get errorGenericTitle => 'خطایی رخ داد';

  @override
  String get errorGenericBody =>
      'متأسفانه انجام این کار ممکن نشد. لطفاً دوباره تلاش کنید.';
}
