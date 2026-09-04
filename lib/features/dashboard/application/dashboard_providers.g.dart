// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The reporting period the dashboard covers: the current **Jalali** month.
///
/// the project spec and D-006. "فروش این ماه" means the Jalali month, and the
/// only correct way to get there is to resolve the Jalali month first and then
/// convert its boundaries to instants — which is exactly what `jalaliMonthOf`
/// does and what this provider is for. A Gregorian month applied here produces
/// a figure that matches nothing the user recognises, without looking wrong.

@ProviderFor(dashboardPeriod)
final dashboardPeriodProvider = DashboardPeriodProvider._();

/// The reporting period the dashboard covers: the current **Jalali** month.
///
/// the project spec and D-006. "فروش این ماه" means the Jalali month, and the
/// only correct way to get there is to resolve the Jalali month first and then
/// convert its boundaries to instants — which is exactly what `jalaliMonthOf`
/// does and what this provider is for. A Gregorian month applied here produces
/// a figure that matches nothing the user recognises, without looking wrong.

final class DashboardPeriodProvider
    extends $FunctionalProvider<InstantRange, InstantRange, InstantRange>
    with $Provider<InstantRange> {
  /// The reporting period the dashboard covers: the current **Jalali** month.
  ///
  /// the project spec and D-006. "فروش این ماه" means the Jalali month, and the
  /// only correct way to get there is to resolve the Jalali month first and then
  /// convert its boundaries to instants — which is exactly what `jalaliMonthOf`
  /// does and what this provider is for. A Gregorian month applied here produces
  /// a figure that matches nothing the user recognises, without looking wrong.
  DashboardPeriodProvider._()
: super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardPeriodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardPeriodHash();

  @$internal
  @override
  $ProviderElement<InstantRange> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InstantRange create(Ref ref) {
    return dashboardPeriod(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InstantRange value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InstantRange>(value),
    );
  }
}

String _$dashboardPeriodHash() => r'befd2419d7bd2d697156f88ce8a51f1ef756ed10';

/// The Jalali **week** — شنبه to جمعه, not the last seven days.
///
/// A rolling seven-day window would be a different question, and a defensible
/// one, but not the one «این هفته» asks: a user comparing Wednesday to Tuesday
/// expects the figure to have grown by Wednesday's sales, not to have also
/// dropped last Wednesday's off the back.

@ProviderFor(dashboardWeek)
final dashboardWeekProvider = DashboardWeekProvider._();

/// The Jalali **week** — شنبه to جمعه, not the last seven days.
///
/// A rolling seven-day window would be a different question, and a defensible
/// one, but not the one «این هفته» asks: a user comparing Wednesday to Tuesday
/// expects the figure to have grown by Wednesday's sales, not to have also
/// dropped last Wednesday's off the back.

final class DashboardWeekProvider
    extends $FunctionalProvider<InstantRange, InstantRange, InstantRange>
    with $Provider<InstantRange> {
  /// The Jalali **week** — شنبه to جمعه, not the last seven days.
  ///
  /// A rolling seven-day window would be a different question, and a defensible
  /// one, but not the one «این هفته» asks: a user comparing Wednesday to Tuesday
  /// expects the figure to have grown by Wednesday's sales, not to have also
  /// dropped last Wednesday's off the back.
  DashboardWeekProvider._()
: super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardWeekProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardWeekHash();

  @$internal
  @override
  $ProviderElement<InstantRange> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InstantRange create(Ref ref) {
    return dashboardWeek(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InstantRange value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InstantRange>(value),
    );
  }
}

String _$dashboardWeekHash() => r'40305aa036dfde1c69670516464a5368501b495c';

/// The Jalali **year** — Farvardin 1 to Farvardin 1, the user's business and
/// tax year (D-006). A Gregorian year here would be wrong by roughly three
/// months, and would look right for nine of them.

@ProviderFor(dashboardYear)
final dashboardYearProvider = DashboardYearProvider._();

/// The Jalali **year** — Farvardin 1 to Farvardin 1, the user's business and
/// tax year (D-006). A Gregorian year here would be wrong by roughly three
/// months, and would look right for nine of them.

final class DashboardYearProvider
    extends $FunctionalProvider<InstantRange, InstantRange, InstantRange>
    with $Provider<InstantRange> {
  /// The Jalali **year** — Farvardin 1 to Farvardin 1, the user's business and
  /// tax year (D-006). A Gregorian year here would be wrong by roughly three
  /// months, and would look right for nine of them.
  DashboardYearProvider._()
: super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardYearProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardYearHash();

  @$internal
  @override
  $ProviderElement<InstantRange> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InstantRange create(Ref ref) {
    return dashboardYear(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InstantRange value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InstantRange>(value),
    );
  }
}

String _$dashboardYearHash() => r'f2288f9c52cdaecc14f05133e495b84409e8f773';

/// Every dashboard figure, read together (see [DashboardSummary]).
///
/// Each `ref.watch(...future)` below is a **live** query underneath: the four
/// repository streams re-emit on any write that could change them, and this
/// provider re-runs when they do, so no tile can be left showing a number that
/// was true a minute ago. Watching a `Future` per figure would have exactly
/// that failure and would look identical on a freshly-opened screen.
///
/// Every one of these is an SQL aggregate (§13). None of them loads rows into
/// Dart to count or sum them.

@ProviderFor(dashboardSummary)
final dashboardSummaryProvider = DashboardSummaryProvider._();

/// Every dashboard figure, read together (see [DashboardSummary]).
///
/// Each `ref.watch(...future)` below is a **live** query underneath: the four
/// repository streams re-emit on any write that could change them, and this
/// provider re-runs when they do, so no tile can be left showing a number that
/// was true a minute ago. Watching a `Future` per figure would have exactly
/// that failure and would look identical on a freshly-opened screen.
///
/// Every one of these is an SQL aggregate (§13). None of them loads rows into
/// Dart to count or sum them.

final class DashboardSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<DashboardSummary>,
          DashboardSummary,
          FutureOr<DashboardSummary>
        >
    with $FutureModifier<DashboardSummary>, $FutureProvider<DashboardSummary> {
  /// Every dashboard figure, read together (see [DashboardSummary]).
  ///
  /// Each `ref.watch(...future)` below is a **live** query underneath: the four
  /// repository streams re-emit on any write that could change them, and this
  /// provider re-runs when they do, so no tile can be left showing a number that
  /// was true a minute ago. Watching a `Future` per figure would have exactly
  /// that failure and would look identical on a freshly-opened screen.
  ///
  /// Every one of these is an SQL aggregate (§13). None of them loads rows into
  /// Dart to count or sum them.
  DashboardSummaryProvider._()
: super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardSummaryHash();

  @$internal
  @override
  $FutureProviderElement<DashboardSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DashboardSummary> create(Ref ref) {
    return dashboardSummary(ref);
  }
}

String _$dashboardSummaryHash() => r'900cb165055ce03e5dac70eb7b2e31d20ae34116';

/// The underlying live queries, private because nothing outside the summary
/// should read one on its own — a screen that watched a single figure would
/// reintroduce exactly the "tiles from different moments" problem
/// [DashboardSummary] exists to prevent.
///
/// **One family for all three sales figures, not three providers.** Week, month
/// and year differ only in the range, and the family caches per range, so the
/// three tiles run the same query against three arguments. Writing a
/// `_weeklySales` beside a `_monthlySales` would be the same statement three
/// times, and three places for the D-039 population to drift apart.

@ProviderFor(_issuedSalesRial)
final _issuedSalesRialProvider = _IssuedSalesRialFamily._();

/// The underlying live queries, private because nothing outside the summary
/// should read one on its own — a screen that watched a single figure would
/// reintroduce exactly the "tiles from different moments" problem
/// [DashboardSummary] exists to prevent.
///
/// **One family for all three sales figures, not three providers.** Week, month
/// and year differ only in the range, and the family caches per range, so the
/// three tiles run the same query against three arguments. Writing a
/// `_weeklySales` beside a `_monthlySales` would be the same statement three
/// times, and three places for the D-039 population to drift apart.

final class _IssuedSalesRialProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// The underlying live queries, private because nothing outside the summary
  /// should read one on its own — a screen that watched a single figure would
  /// reintroduce exactly the "tiles from different moments" problem
  /// [DashboardSummary] exists to prevent.
  ///
  /// **One family for all three sales figures, not three providers.** Week, month
  /// and year differ only in the range, and the family caches per range, so the
  /// three tiles run the same query against three arguments. Writing a
  /// `_weeklySales` beside a `_monthlySales` would be the same statement three
  /// times, and three places for the D-039 population to drift apart.
  _IssuedSalesRialProvider._({
    required _IssuedSalesRialFamily super.from,
    required InstantRange super.argument,
  }) : super(
         retry: null,
         name: r'_issuedSalesRialProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_issuedSalesRialHash();

  @override
  String toString() {
    return r'_issuedSalesRialProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as InstantRange;
    return _issuedSalesRial(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is _IssuedSalesRialProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_issuedSalesRialHash() => r'171885599da3565b9f9a913b1fb57d3d9ab725fa';

/// The underlying live queries, private because nothing outside the summary
/// should read one on its own — a screen that watched a single figure would
/// reintroduce exactly the "tiles from different moments" problem
/// [DashboardSummary] exists to prevent.
///
/// **One family for all three sales figures, not three providers.** Week, month
/// and year differ only in the range, and the family caches per range, so the
/// three tiles run the same query against three arguments. Writing a
/// `_weeklySales` beside a `_monthlySales` would be the same statement three
/// times, and three places for the D-039 population to drift apart.

final class _IssuedSalesRialFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, InstantRange> {
  _IssuedSalesRialFamily._()
: super(
        retry: null,
        name: r'_issuedSalesRialProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The underlying live queries, private because nothing outside the summary
  /// should read one on its own — a screen that watched a single figure would
  /// reintroduce exactly the "tiles from different moments" problem
  /// [DashboardSummary] exists to prevent.
  ///
  /// **One family for all three sales figures, not three providers.** Week, month
  /// and year differ only in the range, and the family caches per range, so the
  /// three tiles run the same query against three arguments. Writing a
  /// `_weeklySales` beside a `_monthlySales` would be the same statement three
  /// times, and three places for the D-039 population to drift apart.

  _IssuedSalesRialProvider call(InstantRange period) =>
      _IssuedSalesRialProvider._(argument: period, from: this);

  @override
  String toString() => r'_issuedSalesRialProvider';
}

@ProviderFor(_monthlyIssuedCount)
final _monthlyIssuedCountProvider = _MonthlyIssuedCountFamily._();

final class _MonthlyIssuedCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  _MonthlyIssuedCountProvider._({
    required _MonthlyIssuedCountFamily super.from,
    required InstantRange super.argument,
  }) : super(
         retry: null,
         name: r'_monthlyIssuedCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_monthlyIssuedCountHash();

  @override
  String toString() {
    return r'_monthlyIssuedCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as InstantRange;
    return _monthlyIssuedCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is _MonthlyIssuedCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_monthlyIssuedCountHash() =>
    r'37a139dc0a0901119d1eaa51708fb6b7d73ee4f0';

final class _MonthlyIssuedCountFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, InstantRange> {
  _MonthlyIssuedCountFamily._()
: super(
        retry: null,
        name: r'_monthlyIssuedCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _MonthlyIssuedCountProvider call(InstantRange period) =>
      _MonthlyIssuedCountProvider._(argument: period, from: this);

  @override
  String toString() => r'_monthlyIssuedCountProvider';
}

@ProviderFor(_outstandingRial)
final _outstandingRialProvider = _OutstandingRialProvider._();

final class _OutstandingRialProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  _OutstandingRialProvider._()
: super(
        from: null,
        argument: null,
        retry: null,
        name: r'_outstandingRialProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_outstandingRialHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return _outstandingRial(ref);
  }
}

String _$_outstandingRialHash() => r'a8766d6365752d2f535af734a25a7845b954e624';

@ProviderFor(_customerCount)
final _customerCountProvider = _CustomerCountProvider._();

final class _CustomerCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  _CustomerCountProvider._()
: super(
        from: null,
        argument: null,
        retry: null,
        name: r'_customerCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_customerCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return _customerCount(ref);
  }
}

String _$_customerCountHash() => r'c6f2c3a90250a1aaf64a68ba4865f0f2e004f417';

@ProviderFor(_invoiceCount)
final _invoiceCountProvider = _InvoiceCountProvider._();

final class _InvoiceCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  _InvoiceCountProvider._()
: super(
        from: null,
        argument: null,
        retry: null,
        name: r'_invoiceCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_invoiceCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return _invoiceCount(ref);
  }
}

String _$_invoiceCountHash() => r'bd62cdf808f4f059c7cff75d128de3865135da76';

/// The handful of most recent invoices, with their customer names resolved by
/// the same query (D-040).
///
/// Its own provider rather than a field on the summary: it is a list with its
/// own shape and its own skeleton, and folding a list into a summary of scalars
/// would make the summary a grab-bag.

@ProviderFor(recentInvoices)
final recentInvoicesProvider = RecentInvoicesProvider._();

/// The handful of most recent invoices, with their customer names resolved by
/// the same query (D-040).
///
/// Its own provider rather than a field on the summary: it is a list with its
/// own shape and its own skeleton, and folding a list into a summary of scalars
/// would make the summary a grab-bag.

final class RecentInvoicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InvoiceListItem>>,
          List<InvoiceListItem>,
          Stream<List<InvoiceListItem>>
        >
    with
        $FutureModifier<List<InvoiceListItem>>,
        $StreamProvider<List<InvoiceListItem>> {
  /// The handful of most recent invoices, with their customer names resolved by
  /// the same query (D-040).
  ///
  /// Its own provider rather than a field on the summary: it is a list with its
  /// own shape and its own skeleton, and folding a list into a summary of scalars
  /// would make the summary a grab-bag.
  RecentInvoicesProvider._()
: super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentInvoicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentInvoicesHash();

  @$internal
  @override
  $StreamProviderElement<List<InvoiceListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<InvoiceListItem>> create(Ref ref) {
    return recentInvoices(ref);
  }
}

String _$recentInvoicesHash() => r'd0dcc7d403aa2009dc4625db60358ee9c984168a';
