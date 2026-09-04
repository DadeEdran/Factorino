// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_sales_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sales per day across [month], for the calendar's marks.
///
/// **One query for the whole visible month.** The alternative the screen shape
/// invites — ask for each day as the grid builds it — is thirty-one statements
/// to paint one calendar, re-issued on every month step; this is a single
/// `GROUP BY` over the month and the grid reads its answers out of the result.
/// See `InvoiceRepository.watchDailySales`.
///
/// Keyed by the month range, so stepping to another month is a new argument to
/// the same family rather than a rebuilt provider, and stepping back lands on a
/// result that is still live.

@ProviderFor(monthlySalesCalendar)
final monthlySalesCalendarProvider = MonthlySalesCalendarFamily._();

/// Sales per day across [month], for the calendar's marks.
///
/// **One query for the whole visible month.** The alternative the screen shape
/// invites — ask for each day as the grid builds it — is thirty-one statements
/// to paint one calendar, re-issued on every month step; this is a single
/// `GROUP BY` over the month and the grid reads its answers out of the result.
/// See `InvoiceRepository.watchDailySales`.
///
/// Keyed by the month range, so stepping to another month is a new argument to
/// the same family rather than a rebuilt provider, and stepping back lands on a
/// result that is still live.

final class MonthlySalesCalendarProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailySales>,
          DailySales,
          Stream<DailySales>
        >
    with $FutureModifier<DailySales>, $StreamProvider<DailySales> {
  /// Sales per day across [month], for the calendar's marks.
  ///
  /// **One query for the whole visible month.** The alternative the screen shape
  /// invites — ask for each day as the grid builds it — is thirty-one statements
  /// to paint one calendar, re-issued on every month step; this is a single
  /// `GROUP BY` over the month and the grid reads its answers out of the result.
  /// See `InvoiceRepository.watchDailySales`.
  ///
  /// Keyed by the month range, so stepping to another month is a new argument to
  /// the same family rather than a rebuilt provider, and stepping back lands on a
  /// result that is still live.
  MonthlySalesCalendarProvider._({
    required MonthlySalesCalendarFamily super.from,
    required InstantRange super.argument,
  }) : super(
         retry: null,
         name: r'monthlySalesCalendarProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthlySalesCalendarHash();

  @override
  String toString() {
    return r'monthlySalesCalendarProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<DailySales> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DailySales> create(Ref ref) {
    final argument = this.argument as InstantRange;
    return monthlySalesCalendar(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlySalesCalendarProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthlySalesCalendarHash() =>
    r'c56098b1b0a0877eba58d254642baac6409565b8';

/// Sales per day across [month], for the calendar's marks.
///
/// **One query for the whole visible month.** The alternative the screen shape
/// invites — ask for each day as the grid builds it — is thirty-one statements
/// to paint one calendar, re-issued on every month step; this is a single
/// `GROUP BY` over the month and the grid reads its answers out of the result.
/// See `InvoiceRepository.watchDailySales`.
///
/// Keyed by the month range, so stepping to another month is a new argument to
/// the same family rather than a rebuilt provider, and stepping back lands on a
/// result that is still live.

final class MonthlySalesCalendarFamily extends $Family
    with $FunctionalFamilyOverride<Stream<DailySales>, InstantRange> {
  MonthlySalesCalendarFamily._()
    : super(
        retry: null,
        name: r'monthlySalesCalendarProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Sales per day across [month], for the calendar's marks.
  ///
  /// **One query for the whole visible month.** The alternative the screen shape
  /// invites — ask for each day as the grid builds it — is thirty-one statements
  /// to paint one calendar, re-issued on every month step; this is a single
  /// `GROUP BY` over the month and the grid reads its answers out of the result.
  /// See `InvoiceRepository.watchDailySales`.
  ///
  /// Keyed by the month range, so stepping to another month is a new argument to
  /// the same family rather than a rebuilt provider, and stepping back lands on a
  /// result that is still live.

  MonthlySalesCalendarProvider call(InstantRange month) =>
      MonthlySalesCalendarProvider._(argument: month, from: this);

  @override
  String toString() => r'monthlySalesCalendarProvider';
}

/// The selected day's own total and count.
///
/// The **same** query as the calendar's, over a one-day range, rather than a
/// second aggregate written for the purpose. Reading the figure out of the
/// month result would be a tempting saving and is wrong at the one moment it
/// matters: the user may step the calendar to another month while a day in the
/// previous one stays selected, and the month result no longer covers it. One
/// method answering both is also the reason the day figure and the dot can
/// never disagree about the same day.

@ProviderFor(daySales)
final daySalesProvider = DaySalesFamily._();

/// The selected day's own total and count.
///
/// The **same** query as the calendar's, over a one-day range, rather than a
/// second aggregate written for the purpose. Reading the figure out of the
/// month result would be a tempting saving and is wrong at the one moment it
/// matters: the user may step the calendar to another month while a day in the
/// previous one stays selected, and the month result no longer covers it. One
/// method answering both is also the reason the day figure and the dot can
/// never disagree about the same day.

final class DaySalesProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailySales>,
          DailySales,
          Stream<DailySales>
        >
    with $FutureModifier<DailySales>, $StreamProvider<DailySales> {
  /// The selected day's own total and count.
  ///
  /// The **same** query as the calendar's, over a one-day range, rather than a
  /// second aggregate written for the purpose. Reading the figure out of the
  /// month result would be a tempting saving and is wrong at the one moment it
  /// matters: the user may step the calendar to another month while a day in the
  /// previous one stays selected, and the month result no longer covers it. One
  /// method answering both is also the reason the day figure and the dot can
  /// never disagree about the same day.
  DaySalesProvider._({
    required DaySalesFamily super.from,
    required InstantRange super.argument,
  }) : super(
         retry: null,
         name: r'daySalesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$daySalesHash();

  @override
  String toString() {
    return r'daySalesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<DailySales> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DailySales> create(Ref ref) {
    final argument = this.argument as InstantRange;
    return daySales(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DaySalesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$daySalesHash() => r'4bffeebfd302de0de88b4a07812bb5a8550bde3f';

/// The selected day's own total and count.
///
/// The **same** query as the calendar's, over a one-day range, rather than a
/// second aggregate written for the purpose. Reading the figure out of the
/// month result would be a tempting saving and is wrong at the one moment it
/// matters: the user may step the calendar to another month while a day in the
/// previous one stays selected, and the month result no longer covers it. One
/// method answering both is also the reason the day figure and the dot can
/// never disagree about the same day.

final class DaySalesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<DailySales>, InstantRange> {
  DaySalesFamily._()
    : super(
        retry: null,
        name: r'daySalesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The selected day's own total and count.
  ///
  /// The **same** query as the calendar's, over a one-day range, rather than a
  /// second aggregate written for the purpose. Reading the figure out of the
  /// month result would be a tempting saving and is wrong at the one moment it
  /// matters: the user may step the calendar to another month while a day in the
  /// previous one stays selected, and the month result no longer covers it. One
  /// method answering both is also the reason the day figure and the dot can
  /// never disagree about the same day.

  DaySalesProvider call(InstantRange day) =>
      DaySalesProvider._(argument: day, from: this);

  @override
  String toString() => r'daySalesProvider';
}

/// The invoices issued on the selected day, newest first.
///
/// Filtered **in SQL** by the same half-open range and the same statuses the
/// aggregate uses (D-039), so the list under the figure is the documents the
/// figure is the sum of. A list filtered in Dart would be a second definition
/// of "issued that day" and would eventually disagree with the first.

@ProviderFor(dayInvoices)
final dayInvoicesProvider = DayInvoicesFamily._();

/// The invoices issued on the selected day, newest first.
///
/// Filtered **in SQL** by the same half-open range and the same statuses the
/// aggregate uses (D-039), so the list under the figure is the documents the
/// figure is the sum of. A list filtered in Dart would be a second definition
/// of "issued that day" and would eventually disagree with the first.

final class DayInvoicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InvoiceListItem>>,
          List<InvoiceListItem>,
          Stream<List<InvoiceListItem>>
        >
    with
        $FutureModifier<List<InvoiceListItem>>,
        $StreamProvider<List<InvoiceListItem>> {
  /// The invoices issued on the selected day, newest first.
  ///
  /// Filtered **in SQL** by the same half-open range and the same statuses the
  /// aggregate uses (D-039), so the list under the figure is the documents the
  /// figure is the sum of. A list filtered in Dart would be a second definition
  /// of "issued that day" and would eventually disagree with the first.
  DayInvoicesProvider._({
    required DayInvoicesFamily super.from,
    required InstantRange super.argument,
  }) : super(
         retry: null,
         name: r'dayInvoicesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dayInvoicesHash();

  @override
  String toString() {
    return r'dayInvoicesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<InvoiceListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<InvoiceListItem>> create(Ref ref) {
    final argument = this.argument as InstantRange;
    return dayInvoices(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DayInvoicesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dayInvoicesHash() => r'1bd246e9780247601794c68a66479dd44bdc4f83';

/// The invoices issued on the selected day, newest first.
///
/// Filtered **in SQL** by the same half-open range and the same statuses the
/// aggregate uses (D-039), so the list under the figure is the documents the
/// figure is the sum of. A list filtered in Dart would be a second definition
/// of "issued that day" and would eventually disagree with the first.

final class DayInvoicesFamily extends $Family
    with
        $FunctionalFamilyOverride<Stream<List<InvoiceListItem>>, InstantRange> {
  DayInvoicesFamily._()
    : super(
        retry: null,
        name: r'dayInvoicesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The invoices issued on the selected day, newest first.
  ///
  /// Filtered **in SQL** by the same half-open range and the same statuses the
  /// aggregate uses (D-039), so the list under the figure is the documents the
  /// figure is the sum of. A list filtered in Dart would be a second definition
  /// of "issued that day" and would eventually disagree with the first.

  DayInvoicesProvider call(InstantRange day) =>
      DayInvoicesProvider._(argument: day, from: this);

  @override
  String toString() => r'dayInvoicesProvider';
}
