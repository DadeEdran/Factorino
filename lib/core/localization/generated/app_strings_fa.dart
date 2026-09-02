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
  String get dashboardInvoiceCount => 'فاکتورهای صادرشده';

  @override
  String get dashboardOutstandingCaption =>
      'فاکتورهای پرداخت‌نشده و پرداخت جزئی';

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
  String get invoiceNumberPending => 'بدون شماره';

  @override
  String get emptyInvoicesTitle => 'هنوز فاکتوری ثبت نشده است';

  @override
  String get emptyInvoicesBody =>
      'اولین فاکتور خود را بسازید تا همراه با وضعیت پرداختش در این فهرست نمایش داده شود.';

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
  String get settingsPaymentTerm => 'مهلت پرداخت پیش‌فرض';

  @override
  String get settingsPaymentTermHint =>
      'سررسید فاکتور تازه به‌صورت پیش‌فرض این تعداد روز پس از تاریخ صدور تعیین می‌شود.';

  @override
  String get unitDays => 'روز';

  @override
  String get settingsBackupSection => 'پشتیبان‌گیری';

  @override
  String get settingsLastBackup => 'آخرین پشتیبان‌گیری';

  @override
  String get settingsLastBackupNever => 'تا کنون پشتیبانی تهیه نشده است';

  @override
  String get settingsSellerSection => 'مشخصات فروشنده';

  @override
  String get settingsSellerEmpty => 'ثبت نشده';

  @override
  String get settingsSellerConsequence =>
      'تا زمانی که نام کسب‌وکار را وارد نکنید، بخش «فروشنده» روی فاکتور چاپ نمی‌شود.';

  @override
  String get settingsSellerEditTitle => 'ویرایش مشخصات فروشنده';

  @override
  String get settingsSellerEditTooltip => 'ویرایش مشخصات فروشنده';

  @override
  String get settingsSellerFieldName => 'نام کسب‌وکار';

  @override
  String get settingsSellerFieldNameHint =>
      'همان‌گونه که باید روی فاکتور چاپ شود.';

  @override
  String get settingsSellerFieldEconomicId => 'کد اقتصادی';

  @override
  String get settingsSellerFieldAddress => 'نشانی';

  @override
  String get settingsSellerFieldPhone => 'تلفن';

  @override
  String get settingsSellerFieldPhoneHint =>
      'همان‌گونه که وارد می‌کنید ذخیره و چاپ می‌شود.';

  @override
  String get settingsErrorSellerNameRequired =>
      'برای چاپ مشخصات فروشنده، نام کسب‌وکار لازم است. برای حذف کامل این بخش، همهٔ فیلدها را خالی بگذارید.';

  @override
  String get settingsSellerSaved => 'مشخصات فروشنده ذخیره شد.';

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
  String get actionViewAll => 'مشاهدهٔ همه';

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
  String validationTooLong(String max) {
    return 'حداکثر $max نویسه مجاز است';
  }

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
  String get customerDetailsSection => 'مشخصات';

  @override
  String get customerDetailsToggle => 'نمایش یا پنهان کردن مشخصات';

  @override
  String get customerInvoicesSection => 'فاکتورهای این مشتری';

  @override
  String get customerTotalBilled => 'مجموع فاکتورهای صادرشده';

  @override
  String get customerTotalBilledCaption =>
      'به‌جز پیش‌نویس‌ها و فاکتورهای لغوشده';

  @override
  String get customerTotalOutstanding => 'مانده دریافتنی';

  @override
  String get customerTotalOutstandingCaption =>
      'فاکتورهای پرداخت‌نشده و پرداخت جزئی';

  @override
  String get customerEmptyInvoicesTitle =>
      'هنوز فاکتوری برای این مشتری صادر نشده است';

  @override
  String get customerEmptyInvoicesBody =>
      'فاکتورهایی که برای این مشتری صادر کنید، همراه با وضعیت پرداختشان اینجا نمایش داده می‌شوند.';

  @override
  String get customerNotFoundTitle => 'این مشتری پیدا نشد';

  @override
  String get customerNotFoundBody =>
      'ممکن است حذف شده باشد. به فهرست مشتریان برگردید.';

  @override
  String get customerBackToList => 'فهرست مشتریان';

  @override
  String get fieldNotRecorded => 'ثبت نشده';

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
  String invoiceWarningLineDiscountClamped(
    String line,
    String requested,
    String applied,
  ) {
    return 'تخفیف سطر $line: $requested تومان وارد شده بود، اما این سطر بیش از $applied تومان ارزش ندارد و تنها همین مبلغ کسر شد.';
  }

  @override
  String invoiceWarningInvoiceDiscountClamped(
    String requested,
    String applied,
  ) {
    return 'تخفیف کل فاکتور: $requested تومان وارد شده بود، اما جمع فاکتور بیش از $applied تومان نیست و تنها همین مبلغ کسر شد.';
  }

  @override
  String get invoiceWarningsTitle => 'این مقادیر را بررسی کنید';

  @override
  String get datePickerTitle => 'انتخاب تاریخ';

  @override
  String get datePickerToday => 'امروز';

  @override
  String get datePickerPreviousMonth => 'ماه قبل';

  @override
  String get datePickerNextMonth => 'ماه بعد';

  @override
  String get weekdayShanbeShort => 'ش';

  @override
  String get weekdayYekshanbeShort => 'ی';

  @override
  String get weekdayDoshanbeShort => 'د';

  @override
  String get weekdaySeshanbeShort => 'س';

  @override
  String get weekdayChaharshanbeShort => 'چ';

  @override
  String get weekdayPanjshanbeShort => 'پ';

  @override
  String get weekdayJomeShort => 'ج';

  @override
  String get invoiceDetailsTitle => 'مشخصات فاکتور';

  @override
  String get invoiceDetailsToggle => 'نمایش یا پنهان کردن مشخصات فاکتور';

  @override
  String get invoiceDetailsCollapsedNoCustomer => 'مشتری انتخاب نشده';

  @override
  String get invoiceFieldCustomer => 'مشتری';

  @override
  String get invoiceFieldCustomerEmpty => 'انتخاب مشتری';

  @override
  String get invoiceFieldIssueDate => 'تاریخ صدور';

  @override
  String get invoiceFieldDueDate => 'سررسید';

  @override
  String get invoiceFieldDueDateCleared => 'بدون سررسید';

  @override
  String get invoiceFieldDiscount => 'تخفیف کل فاکتور';

  @override
  String get invoiceFieldTax => 'مالیات فاکتور';

  @override
  String get invoiceFieldNotes => 'یادداشت';

  @override
  String get invoiceCustomerPickerTitle => 'انتخاب مشتری';

  @override
  String get invoiceCustomerPickerSearchHint => 'جست‌وجو در مشتریان';

  @override
  String get invoiceCustomerPickerEmptyTitle => 'مشتری‌ای یافت نشد';

  @override
  String get invoiceCustomerPickerEmptyBody =>
      'برای صدور فاکتور ابتدا باید مشتری را در بخش مشتریان ثبت کنید.';

  @override
  String get invoiceActionSaveDraft => 'ذخیره پیش‌نویس';

  @override
  String get invoiceActionIssue => 'صدور فاکتور';

  @override
  String get invoiceSaveDraftSuccess => 'پیش‌نویس ذخیره شد.';

  @override
  String invoiceIssueSuccess(String number) {
    return 'فاکتور $number صادر شد.';
  }

  @override
  String get invoiceSaveFailed =>
      'ذخیره فاکتور ممکن نشد. لطفاً دوباره تلاش کنید.';

  @override
  String get invoiceIncompleteCustomer => 'برای ذخیره، مشتری را انتخاب کنید.';

  @override
  String get invoiceIncompleteLines => 'برای ذخیره، دست‌کم یک سطر اضافه کنید.';

  @override
  String get invoiceCreateTitle => 'فاکتور جدید';

  @override
  String get invoiceCreateAction => 'فاکتور جدید';

  @override
  String get invoiceSummaryTitle => 'جمع‌بندی';

  @override
  String get invoiceSummaryGross => 'جمع سطرها';

  @override
  String get invoiceSummaryDiscount => 'کسر تخفیف';

  @override
  String get invoiceSummaryTax => 'مالیات بر ارزش افزوده';

  @override
  String get invoiceSummaryRounding => 'رند کردن';

  @override
  String get invoiceSummaryGrandTotal => 'مبلغ قابل پرداخت';

  @override
  String get invoiceSummaryEmpty =>
      'با افزودن سطر، مبلغ فاکتور همین‌جا محاسبه می‌شود.';

  @override
  String get invoiceFigureUnrecorded => 'ثبت‌نشده';

  @override
  String get invoiceSummaryGrossUnrecordedNote =>
      'جمع سطرهای این فاکتور هنگام صدور ثبت نشده است. مبلغ قابل پرداخت آن درست و بدون تغییر است.';

  @override
  String get invoiceActionSaveDraftHint =>
      'قابل ویرایش می‌ماند و شماره نمی‌گیرد.';

  @override
  String get invoiceIssueConfirmTitle => 'این فاکتور صادر شود؟';

  @override
  String get invoiceIssueConfirmBody =>
      'با صدور، فاکتور شمارهٔ رسمی خود را می‌گیرد و دیگر قابل ویرایش نخواهد بود. برای اصلاح آن باید فاکتور را باطل کنید و فاکتور تازه‌ای صادر کنید.';

  @override
  String get invoiceIssueConfirmAction => 'صدور و ثبت نهایی';

  @override
  String get invoiceDiscardTitle => 'این فاکتور رها شود؟';

  @override
  String get invoiceDiscardBody =>
      'این فاکتور هنوز ذخیره نشده است. اگر خارج شوید، آنچه وارد کرده‌اید از بین می‌رود.';

  @override
  String get invoiceDiscardAction => 'رها کردن';

  @override
  String get invoiceDiscardKeepAction => 'ادامهٔ ویرایش';

  @override
  String get invoiceBackTooltip => 'بازگشت به فهرست فاکتورها';

  @override
  String get invoiceLinesTitle => 'سطرهای فاکتور';

  @override
  String get invoiceLinesEmptyTitle => 'هنوز سطری اضافه نشده است';

  @override
  String get invoiceLinesEmptyBody =>
      'یک کالا یا خدمت از فهرست انتخاب کنید، یا سطری دلخواه بنویسید.';

  @override
  String get invoiceLineAddFromCatalogue => 'افزودن از فهرست';

  @override
  String get invoiceLineAddCustom => 'سطر دلخواه';

  @override
  String get invoiceLineEditTitle => 'ویرایش سطر';

  @override
  String get invoiceLineCreateTitle => 'سطر جدید';

  @override
  String get invoiceLineFieldTitle => 'شرح';

  @override
  String get invoiceLineFieldQuantity => 'تعداد';

  @override
  String get invoiceLineFieldQuantityHelper => 'تا سه رقم اعشار';

  @override
  String get invoiceLineFieldUnitPrice => 'قیمت واحد';

  @override
  String get invoiceLineDiscountSection => 'تخفیف سطر';

  @override
  String get invoiceLineDiscountModeAmount => 'مبلغ';

  @override
  String get invoiceLineDiscountModePercent => 'درصد';

  @override
  String get invoiceLineTaxSection => 'مالیات سطر';

  @override
  String get invoiceLineTaxInherit => 'پیش‌فرض فاکتور';

  @override
  String get invoiceLineTaxCustom => 'نرخ دلخواه';

  @override
  String invoiceLineTaxInheritedNote(String rate) {
    return 'نرخ مؤثر: $rate';
  }

  @override
  String invoiceLineLabelQuantity(String quantity, String unit, String price) {
    return '$quantity $unit × $price';
  }

  @override
  String invoiceLineLabelDiscount(String amount) {
    return 'تخفیف $amount';
  }

  @override
  String invoiceLineLabelTax(String rate) {
    return 'مالیات $rate';
  }

  @override
  String get invoiceLineActionEdit => 'ویرایش سطر';

  @override
  String get invoiceLineActionRemove => 'حذف سطر';

  @override
  String get invoiceLineActionMoveUp => 'انتقال به بالا';

  @override
  String get invoiceLineActionMoveDown => 'انتقال به پایین';

  @override
  String get invoiceLineColumnDescription => 'شرح';

  @override
  String get invoiceLineColumnQuantity => 'تعداد';

  @override
  String get invoiceLineColumnUnitPrice => 'قیمت واحد';

  @override
  String get invoiceLineColumnTotal => 'جمع سطر';

  @override
  String get invoiceProductPickerTitle => 'انتخاب کالا یا خدمت';

  @override
  String get invoiceProductPickerSearchHint => 'جست‌وجو در کالاها و خدمات';

  @override
  String get invoiceProductPickerEmptyTitle => 'کالا یا خدمتی یافت نشد';

  @override
  String get invoiceProductPickerEmptyBody =>
      'می‌توانید به جای آن سطری دلخواه بنویسید.';

  @override
  String get validationQuantityInvalid => 'تعداد را درست وارد کنید.';

  @override
  String get validationQuantityTooPrecise =>
      'تعداد حداکثر سه رقم اعشار می‌پذیرد.';

  @override
  String get validationPercentInvalid => 'درصد را بین ۰ تا ۱۰۰ وارد کنید.';

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
  String invoiceDetailTitle(String number) {
    return 'فاکتور $number';
  }

  @override
  String get invoiceDetailNotFoundTitle => 'این فاکتور پیدا نشد';

  @override
  String get invoiceDetailNotFoundBody =>
      'ممکن است حذف شده باشد. به فهرست فاکتورها برگردید.';

  @override
  String get invoiceDetailBackToList => 'فهرست فاکتورها';

  @override
  String get invoiceDetailPartySection => 'طرف حساب';

  @override
  String get invoiceDetailPartyDiverged =>
      'نام یا مشخصات این مشتری پس از صدور فاکتور تغییر کرده است. آنچه در بالا آمده همان چیزی است که روی این سند ثبت شده و تغییر نمی‌کند.';

  @override
  String invoiceDetailPartyRecordNow(String name) {
    return 'در پروندهٔ مشتری: $name';
  }

  @override
  String get invoiceDetailPartyDraft =>
      'این فاکتور هنوز صادر نشده است، بنابراین مشخصات بالا از پروندهٔ فعلی مشتری خوانده می‌شود و با اصلاح آن پرونده تغییر می‌کند. با صدور فاکتور، این مشخصات ثبت و ثابت می‌شوند.';

  @override
  String get invoiceDetailPartyNoSnapshot =>
      'مشخصات طرف حساب این فاکتور هنگام صدور ثبت نشده است، بنابراین آنچه در بالا آمده از پروندهٔ فعلی مشتری خوانده می‌شود. مبالغ فاکتور از این موضوع اثر نمی‌گیرند.';

  @override
  String get invoiceDetailCustomerDeleted =>
      'این مشتری از فهرست مشتریان حذف شده است. فاکتورهای او دست‌نخورده باقی می‌مانند.';

  @override
  String get invoiceDetailGoToCustomer => 'رفتن به پروندهٔ مشتری';

  @override
  String get invoiceDetailContactSection => 'تماس';

  @override
  String get invoiceDetailIssueDate => 'تاریخ صدور';

  @override
  String get invoiceDetailDueDate => 'سررسید';

  @override
  String get invoiceDetailNoDueDate => 'بدون سررسید';

  @override
  String get invoiceDetailNotesSection => 'یادداشت';

  @override
  String get invoiceDetailLinesSection => 'سطرهای فاکتور';

  @override
  String get invoiceDetailNoLines => 'این فاکتور سطری ندارد.';

  @override
  String get invoiceDetailPaidLabel => 'پرداخت‌شده';

  @override
  String get invoiceDetailDueLabel => 'مانده';

  @override
  String get invoiceDetailOverpaidNote =>
      'مبلغ پرداختی از مبلغ فاکتور بیشتر است.';

  @override
  String get invoiceLineColumnGross => 'مبلغ کل';

  @override
  String invoiceLineLabelInvoiceDiscountShare(String amount) {
    return 'سهم تخفیف فاکتور $amount';
  }

  @override
  String invoiceLineLabelNet(String amount) {
    return 'مبلغ پس از تخفیف $amount';
  }

  @override
  String invoiceLineLabelGross(String amount) {
    return 'مبلغ کل $amount';
  }

  @override
  String invoiceLineLabelUnitPrice(String amount) {
    return 'مبلغ واحد $amount';
  }

  @override
  String invoiceLineLabelTaxAmount(String rate, String amount) {
    return 'مالیات $rate: $amount';
  }

  @override
  String get invoiceDetailInvoiceDiscountShareLabel => 'سهم تخفیف فاکتور';

  @override
  String invoiceLineLabelUnrecorded(String label) {
    return '$label ثبت‌نشده';
  }

  @override
  String get paymentMethodCash => 'نقدی';

  @override
  String get paymentMethodCardTransfer => 'کارت به کارت';

  @override
  String get paymentMethodBankTransfer => 'انتقال بانکی';

  @override
  String get paymentMethodCheque => 'چک';

  @override
  String get paymentMethodOther => 'سایر';

  @override
  String get invoiceDetailPaymentsSection => 'پرداخت‌ها';

  @override
  String get invoiceDetailPaymentsEmpty =>
      'هنوز پرداختی برای این فاکتور ثبت نشده است.';

  @override
  String get invoiceDetailRecordPayment => 'ثبت پرداخت';

  @override
  String get invoiceDetailPaymentsUnavailableDraft =>
      'برای ثبت پرداخت، ابتدا فاکتور را صادر کنید. پیش‌نویس هنوز مطالبه‌ای از کسی نیست.';

  @override
  String get invoiceDetailPaymentsUnavailableCancelled =>
      'این فاکتور باطل شده است و دیگر مطالبه‌ای از کسی نیست، بنابراین پرداخت تازه‌ای برای آن ثبت نمی‌شود. اگر مبلغی دریافت کرده‌اید، آن را روی فاکتور جایگزین ثبت کنید.';

  @override
  String get paymentCreateTitle => 'ثبت پرداخت';

  @override
  String get paymentFieldAmount => 'مبلغ پرداختی';

  @override
  String get paymentFieldDate => 'تاریخ پرداخت';

  @override
  String get paymentFieldMethod => 'روش پرداخت';

  @override
  String get paymentFieldNote => 'توضیح';

  @override
  String get paymentFieldNoteHint =>
      'شمارهٔ چک، مرجع تراکنش، یا هر یادداشت دیگر';

  @override
  String paymentAmountRemainingHelper(String amount) {
    return 'مانده: $amount تومان';
  }

  @override
  String get paymentAmountFillRemaining => 'پرداخت کامل مانده';

  @override
  String get paymentAmountExceedsDue =>
      'مبلغ واردشده از مانده بیشتر است و به عنوان اضافه‌پرداخت ثبت می‌شود.';

  @override
  String get validationAmountPositive => 'مبلغ باید بزرگ‌تر از صفر باشد.';

  @override
  String get paymentDeleteTitle => 'این پرداخت حذف شود؟';

  @override
  String paymentDeleteBody(String amount) {
    return '$amount تومان از پرداخت‌های این فاکتور حذف می‌شود و مانده به همان اندازه افزایش می‌یابد.';
  }

  @override
  String get paymentDeleteStatusWarning =>
      'با این کار وضعیت فاکتور از «پرداخت شده» خارج می‌شود.';

  @override
  String get paymentDeleteAction => 'حذف پرداخت';

  @override
  String get paymentDeleteFailed => 'حذف این پرداخت ممکن نشد.';

  @override
  String get paymentSaveFailed => 'ثبت این پرداخت ممکن نشد.';

  @override
  String get invoiceCancelAction => 'ابطال فاکتور';

  @override
  String get invoiceCancelTitle => 'این فاکتور باطل شود؟';

  @override
  String get invoiceCancelBody =>
      'فاکتور حذف نمی‌شود؛ در سوابق می‌ماند و «باطل شده» علامت می‌خورد. شمارهٔ آن آزاد نمی‌شود و به هیچ فاکتور دیگری داده نمی‌شود. ابطال برگشت‌پذیر نیست و فاکتور پس از آن قابل ویرایش نیست؛ برای اصلاح، فاکتور تازه‌ای صادر کنید.';

  @override
  String invoiceCancelPaymentsNote(String amount) {
    return '$amount تومان پرداختی که تاکنون ثبت شده حذف نمی‌شود و بازگردانده نمی‌شود. ابطال، فاکتور را باطل می‌کند نه پولی را که دریافت شده است.';
  }

  @override
  String get invoiceCancelSuccess =>
      'فاکتور باطل شد. پرداخت‌های ثبت‌شده دست‌نخورده ماند.';

  @override
  String get invoiceCancelFailed => 'ابطال این فاکتور ممکن نشد.';

  @override
  String get invoiceFilterAction => 'فیلترها';

  @override
  String get invoiceFilterTitle => 'فیلتر فاکتورها';

  @override
  String get invoiceFilterApply => 'نمایش نتایج';

  @override
  String get invoiceFilterClearAll => 'پاک کردن همه';

  @override
  String get invoiceFilterStatusSection => 'وضعیت';

  @override
  String get invoiceFilterCustomerSection => 'مشتری';

  @override
  String get invoiceFilterPeriodSection => 'بازهٔ زمانی';

  @override
  String get invoiceFilterCustomerAny => 'همهٔ مشتریان';

  @override
  String get invoiceFilterCustomerChoose => 'انتخاب مشتری';

  @override
  String get invoiceFilterPeriodAny => 'همهٔ تاریخ‌ها';

  @override
  String get invoiceFilterPeriodThisMonth => 'این ماه';

  @override
  String get invoiceFilterPeriodLastMonth => 'ماه گذشته';

  @override
  String get invoiceFilterPeriodThisYear => 'امسال';

  @override
  String invoiceFilterActiveLabel(String count) {
    return '$count فیلتر فعال';
  }

  @override
  String get emptyInvoicesFilteredTitle => 'فاکتوری با این فیلترها پیدا نشد';

  @override
  String get emptyInvoicesFilteredBody =>
      'هیچ فاکتوری با فیلترهای انتخاب‌شده مطابقت ندارد. فیلترها را تغییر دهید یا پاک کنید.';

  @override
  String get invoiceDetailCancelledDueNote =>
      'این فاکتور باطل شده است؛ مانده‌ی آن مطالبه‌ای از مشتری نیست.';

  @override
  String get invoiceDetailCancelledPaymentsNote =>
      'این فاکتور باطل شده است، اما پرداخت‌های زیر واقعاً دریافت شده‌اند و در سوابق می‌مانند. ابطال، پرداختی را حذف یا بازنمی‌گرداند.';

  @override
  String paymentDeleteBodyCancelled(String amount) {
    return '$amount تومان از پرداخت‌های این فاکتور حذف می‌شود. فاکتور باطل شده است و باطل می‌ماند؛ این کار فقط سابقهٔ پرداخت را اصلاح می‌کند.';
  }

  @override
  String get settingsEditTitle => 'ویرایش تنظیمات فاکتور';

  @override
  String get settingsEditTooltip => 'ویرایش';

  @override
  String get settingsFieldTaxRate => 'نرخ مالیات بر ارزش افزوده';

  @override
  String get settingsFieldTaxRateHint =>
      'به درصد. تغییر آن روی فاکتورهای قبلی اثری ندارد.';

  @override
  String get settingsFieldPrefix => 'پیشوند شمارهٔ فاکتور';

  @override
  String get settingsFieldPrefixHint =>
      'مثلاً INV در INV-۱۴۰۵-۰۰۰۱. شماره‌های صادرشده تغییر نمی‌کنند.';

  @override
  String get settingsFieldPaymentTerm => 'مهلت پرداخت پیش‌فرض';

  @override
  String get settingsFieldPaymentTermHint => 'تعداد روز پس از صدور فاکتور.';

  @override
  String get settingsErrorTaxRateRange =>
      'نرخ مالیات باید بین ۰ تا ۱۰۰ درصد باشد.';

  @override
  String get settingsErrorPaymentTermRange =>
      'مهلت پرداخت باید بین ۰ تا ۷۳۰ روز باشد.';

  @override
  String get settingsErrorPrefixEmpty => 'پیشوند نمی‌تواند خالی باشد.';

  @override
  String get settingsSaved => 'تنظیمات ذخیره شد.';

  @override
  String get backupExportAction => 'تهیهٔ پشتیبان';

  @override
  String get backupImportAction => 'بازیابی از پشتیبان';

  @override
  String get backupPasswordTitle => 'گذرواژهٔ فایل پشتیبان';

  @override
  String get backupPasswordField => 'گذرواژه';

  @override
  String get backupPasswordRepeatField => 'تکرار گذرواژه';

  @override
  String get backupPasswordWarning =>
      'این گذرواژه در هیچ کجا ذخیره نمی‌شود. اگر آن را فراموش کنید، هیچ راهی برای باز کردن فایل پشتیبان وجود ندارد و اطلاعات آن برای همیشه از دست می‌رود.';

  @override
  String get backupPasswordEmpty => 'گذرواژه را وارد کنید.';

  @override
  String get backupPasswordMismatch => 'دو گذرواژه یکسان نیستند.';

  @override
  String get backupPasswordTooShort => 'گذرواژه باید دست‌کم ۸ نویسه باشد.';

  @override
  String get backupExportInProgress => 'در حال تهیهٔ پشتیبان…';

  @override
  String get backupExportDone => 'فایل پشتیبان ذخیره شد.';

  @override
  String get backupImportPasswordTitle => 'گذرواژهٔ این فایل پشتیبان';

  @override
  String get backupImportInProgress => 'در حال بازیابی…';

  @override
  String get backupImportDone => 'بازیابی انجام شد.';

  @override
  String get backupImportConfirmTitle => 'جایگزینی همهٔ اطلاعات';

  @override
  String get backupImportConfirmReplaces =>
      'با بازیابی، همهٔ اطلاعات فعلی این دستگاه حذف و با محتوای فایل پشتیبان جایگزین می‌شود. اطلاعات دو مجموعه با هم ادغام نمی‌شوند.';

  @override
  String get backupImportConfirmLoses =>
      'هر چیزی که پس از تهیهٔ این پشتیبان ثبت کرده‌اید از بین می‌رود.';

  @override
  String backupImportConfirmContents(
    String customers,
    String invoices,
    String payments,
  ) {
    return 'محتوای فایل: $customers مشتری، $invoices فاکتور، $payments پرداخت.';
  }

  @override
  String backupImportConfirmDate(String date) {
    return 'تاریخ تهیه: $date';
  }

  @override
  String get backupImportConfirmAction => 'جایگزین کن';

  @override
  String get errorBackupExportFailedTitle => 'تهیهٔ پشتیبان انجام نشد';

  @override
  String get errorBackupExportFailedBody =>
      'فایل پشتیبان ساخته نشد. لطفاً دوباره تلاش کنید.';

  @override
  String get errorBackupCannotOpenTitle => 'فایل پشتیبان باز نشد';

  @override
  String get errorBackupCannotOpenBody =>
      'گذرواژه نادرست است یا فایل آسیب دیده. گذرواژه را دوباره وارد کنید یا فایل دیگری انتخاب کنید. اطلاعات فعلی شما دست‌نخورده است.';

  @override
  String get errorBackupNotABackupTitle => 'این فایل پشتیبان فاکتورینو نیست';

  @override
  String get errorBackupNotABackupBody =>
      'فایل باز شد اما محتوای آن یک پشتیبان فاکتورینو نیست. فایل دیگری انتخاب کنید. اطلاعات فعلی شما دست‌نخورده است.';

  @override
  String get errorBackupFromNewerVersionTitle =>
      'این پشتیبان با نسخهٔ جدیدتری ساخته شده است';

  @override
  String get errorBackupFromNewerVersionBody =>
      'برای بازیابی این فایل، ابتدا برنامه را به‌روز کنید. اطلاعات فعلی شما دست‌نخورده است.';

  @override
  String get errorBackupCountMismatchTitle => 'فایل پشتیبان ناقص است';

  @override
  String get errorBackupCountMismatchBody =>
      'تعداد رکوردهای داخل فایل با آنچه در آن ثبت شده هم‌خوانی ندارد، بنابراین بازیابی انجام نشد. اطلاعات فعلی شما دست‌نخورده است.';

  @override
  String get errorBackupRestoreFailedTitle => 'بازیابی انجام نشد';

  @override
  String get errorBackupRestoreFailedBody =>
      'هیچ تغییری در اطلاعات شما ایجاد نشد و همه‌چیز مانند قبل است. لطفاً دوباره تلاش کنید.';

  @override
  String get errorGenericTitle => 'خطایی رخ داد';

  @override
  String get errorGenericBody =>
      'متأسفانه انجام این کار ممکن نشد. لطفاً دوباره تلاش کنید.';

  @override
  String get invoiceDocumentTitle => 'فاکتور فروش';

  @override
  String get invoiceDocumentDraftBanner => 'پیش‌نویس — سند نهایی نیست';

  @override
  String get invoiceDocumentNumberLabel => 'شماره فاکتور';

  @override
  String get invoiceDocumentBuyerHeading => 'خریدار';

  @override
  String get invoiceDocumentPartyFromRecord =>
      'مشخصات خریدار از پروندهٔ فعلی مشتری خوانده شده است.';

  @override
  String get invoiceDocumentColumnRow => 'ردیف';

  @override
  String get invoiceDocumentSellerHeading => 'فروشنده';

  @override
  String get invoiceDocumentSellerPhoneLabel => 'تلفن';

  @override
  String get invoiceDeleteDraftAction => 'حذف پیش‌نویس';

  @override
  String get invoiceDeleteDraftTitle => 'حذف این پیش‌نویس؟';

  @override
  String get invoiceDeleteDraftBody =>
      'این پیش‌نویس از فهرست حذف می‌شود و برگرداندن آن ممکن نیست. چون هنوز صادر نشده، هیچ شماره‌ای مصرف نشده و چیزی برای مشتری ارسال نشده است.';

  @override
  String get invoiceDeleteDraftSuccess => 'پیش‌نویس حذف شد.';

  @override
  String get invoiceDeleteDraftFailed =>
      'حذف پیش‌نویس انجام نشد. دوباره تلاش کنید.';

  @override
  String get invoiceDocumentExportAction => 'ذخیرهٔ نسخهٔ PDF';

  @override
  String get invoiceDocumentExportSaved => 'فایل فاکتور ذخیره شد.';

  @override
  String get invoiceDocumentExportFailed =>
      'ذخیرهٔ فایل فاکتور انجام نشد. دوباره تلاش کنید.';

  @override
  String get invoiceDocumentExportNoSeller =>
      'این فاکتور بدون بخش «فروشنده» ذخیره شد.';

  @override
  String get invoiceDocumentExportGoToSettings => 'تنظیمات';
}
