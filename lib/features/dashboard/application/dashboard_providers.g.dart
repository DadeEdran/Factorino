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

String _$dashboardSummaryHash() => r'8823619600380625ab521e9348cca1a01872b57d';

/// The five underlying live queries, private because nothing outside the
/// summary should read one on its own — a screen that watched a single figure
/// would reintroduce exactly the "tiles from different moments" problem
/// [DashboardSummary] exists to prevent.

@ProviderFor(_monthlySalesRial)
final _monthlySalesRialProvider = _MonthlySalesRialFamily._();

/// The five underlying live queries, private because nothing outside the
/// summary should read one on its own — a screen that watched a single figure
/// would reintroduce exactly the "tiles from different moments" problem
/// [DashboardSummary] exists to prevent.

final class _MonthlySalesRialProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// The five underlying live queries, private because nothing outside the
  /// summary should read one on its own — a screen that watched a single figure
  /// would reintroduce exactly the "tiles from different moments" problem
  /// [DashboardSummary] exists to prevent.
  _MonthlySalesRialProvider._({
    required _MonthlySalesRialFamily super.from,
    required InstantRange super.argument,
  }) : super(
         retry: null,
         name: r'_monthlySalesRialProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_monthlySalesRialHash();

  @override
  String toString() {
    return r'_monthlySalesRialProvider'
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
    return _monthlySalesRial(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is _MonthlySalesRialProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_monthlySalesRialHash() => r'be17cf9656fd4ab427d9c1986f12a799710b82c3';

/// The five underlying live queries, private because nothing outside the
/// summary should read one on its own — a screen that watched a single figure
/// would reintroduce exactly the "tiles from different moments" problem
/// [DashboardSummary] exists to prevent.

final class _MonthlySalesRialFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, InstantRange> {
  _MonthlySalesRialFamily._()
: super(
        retry: null,
        name: r'_monthlySalesRialProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The five underlying live queries, private because nothing outside the
  /// summary should read one on its own — a screen that watched a single figure
  /// would reintroduce exactly the "tiles from different moments" problem
  /// [DashboardSummary] exists to prevent.

  _MonthlySalesRialProvider call(InstantRange period) =>
      _MonthlySalesRialProvider._(argument: period, from: this);

  @override
  String toString() => r'_monthlySalesRialProvider';
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
