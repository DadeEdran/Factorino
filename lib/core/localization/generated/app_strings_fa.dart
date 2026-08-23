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
  String get errorGenericTitle => 'خطایی رخ داد';

  @override
  String get errorGenericBody =>
      'متأسفانه انجام این کار ممکن نشد. لطفاً دوباره تلاش کنید.';
}
