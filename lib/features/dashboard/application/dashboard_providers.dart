import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/date/jalali_period.dart';
import '../../../core/money/money.dart';
import '../../../core/utils/clock.dart';
import '../../../data/models/invoice_list_item.dart';
import '../../../data/providers.dart';
import '../domain/dashboard_summary.dart';

part 'dashboard_providers.g.dart';

/// How many invoices the dashboard's recent list shows.
///
/// Short on purpose. The dashboard answers "how are things", and the invoice
/// destination answers "show me the invoices"; a dashboard that tries to be
/// both ends up being neither, and the list underneath the tiles is a glance,
/// not a workspace.
const int kRecentInvoiceCount = 5;

/// The reporting period the dashboard covers: the current **Jalali** month.
///
/// the project spec and D-006. "فروش این ماه" means the Jalali month, and the
/// only correct way to get there is to resolve the Jalali month first and then
/// convert its boundaries to instants — which is exactly what `jalaliMonthOf`
/// does and what this provider is for. A Gregorian month applied here produces
/// a figure that matches nothing the user recognises, without looking wrong.
@riverpod
InstantRange dashboardPeriod(Ref ref) => jalaliMonthOf(ref.watch(nowProvider));

/// The Jalali **week** — شنبه to جمعه, not the last seven days.
///
/// A rolling seven-day window would be a different question, and a defensible
/// one, but not the one «این هفته» asks: a user comparing Wednesday to Tuesday
/// expects the figure to have grown by Wednesday's sales, not to have also
/// dropped last Wednesday's off the back.
@riverpod
InstantRange dashboardWeek(Ref ref) => jalaliWeekOf(ref.watch(nowProvider));

/// The Jalali **year** — Farvardin 1 to Farvardin 1, the user's business and
/// tax year (D-006). A Gregorian year here would be wrong by roughly three
/// months, and would look right for nine of them.
@riverpod
InstantRange dashboardYear(Ref ref) => jalaliYearOf(ref.watch(nowProvider));

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
@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref) async {
  final InstantRange week = ref.watch(dashboardWeekProvider);
  final InstantRange period = ref.watch(dashboardPeriodProvider);
  final InstantRange year = ref.watch(dashboardYearProvider);

  final int weekSalesRial = await ref.watch(
    _issuedSalesRialProvider(week).future,
  );
  final int salesRial = await ref.watch(
    _issuedSalesRialProvider(period).future,
  );
  final int yearSalesRial = await ref.watch(
    _issuedSalesRialProvider(year).future,
  );
  final int issuedCount = await ref.watch(
    _monthlyIssuedCountProvider(period).future,
  );
  final int outstandingRial = await ref.watch(_outstandingRialProvider.future);
  final int customerCount = await ref.watch(_customerCountProvider.future);
  final int invoiceCount = await ref.watch(_invoiceCountProvider.future);

  return DashboardSummary(
    week: week,
    period: period,
    year: year,
    salesThisWeek: Money.rial(weekSalesRial),
    salesThisPeriod: Money.rial(salesRial),
    salesThisYear: Money.rial(yearSalesRial),
    issuedCountThisPeriod: issuedCount,
    outstanding: Money.rial(outstandingRial),
    customerCount: customerCount,
    invoiceCount: invoiceCount,
  );
}

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
@riverpod
Stream<int> _issuedSalesRial(Ref ref, InstantRange period) =>
    ref.watch(invoiceRepositoryProvider).watchTotalIssuedRial(period);

@riverpod
Stream<int> _monthlyIssuedCount(Ref ref, InstantRange period) =>
    ref.watch(invoiceRepositoryProvider).watchIssuedCountInPeriod(period);

@riverpod
Stream<int> _outstandingRial(Ref ref) =>
    ref.watch(invoiceRepositoryProvider).watchOutstandingRial();

@riverpod
Stream<int> _customerCount(Ref ref) =>
    ref.watch(customerRepositoryProvider).watchCount();

@riverpod
Stream<int> _invoiceCount(Ref ref) =>
    ref.watch(invoiceRepositoryProvider).watchCount();

/// The handful of most recent invoices, with their customer names resolved by
/// the same query (D-040).
///
/// Its own provider rather than a field on the summary: it is a list with its
/// own shape and its own skeleton, and folding a list into a summary of scalars
/// would make the summary a grab-bag.
@riverpod
Stream<List<InvoiceListItem>> recentInvoices(Ref ref) {
  return ref
.watch(invoiceRepositoryProvider)
.watchList(limit: kRecentInvoiceCount);
}
