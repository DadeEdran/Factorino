import '../../../core/date/jalali_period.dart';
import '../../../core/money/money.dart';

/// Every figure the dashboard shows, from one moment.
///
/// Deliberately one value rather than five providers the screen assembles.
/// Five independent aggregates settle at five different instants, and a
/// dashboard whose tiles belong to different moments is a set of numbers that
/// do not add up — the sales figure from before the invoice was issued sitting
/// beside the count from after it. Here they are read together and rendered
/// together, so the page is either wholly before a write or wholly after it.
///
/// It also gives the page one loading state and one error state, which is why
/// there is one skeleton rather than four tiles pulsing out of step.
class DashboardSummary {
  const DashboardSummary({
    required this.week,
    required this.period,
    required this.year,
    required this.salesThisWeek,
    required this.salesThisPeriod,
    required this.salesThisYear,
    required this.issuedCountThisPeriod,
    required this.outstanding,
    required this.customerCount,
    required this.invoiceCount,
  });

  /// The **Jalali** week the week figure covers: شنبه to جمعه (D-006), not the
  /// seven days ending today and not a Monday-start week.
  final InstantRange week;

  /// The **Jalali** month the two period figures cover (D-006), carried so the
  /// caption on screen names the same month the query used rather than one the
  /// screen resolves separately.
  final InstantRange period;

  /// The **Jalali** year — the user's business and tax year, Farvardin to
  /// Farvardin.
  final InstantRange year;

  /// Invoices *issued* in [week] — the same population as [salesThisPeriod],
  /// over a shorter range.
  ///
  /// **The three sales figures are nested, not additive.** This week is inside
  /// this month is inside this year, so the tiles are three answers to "how
  /// much have I sold" at three zoom levels rather than three parts of a total.
  /// Each names its own period on its caption for exactly that reason: without
  /// it a reader could reasonably try to add them.
  final Money salesThisWeek;

  /// Invoices *issued* in [period] — drafts and cancellations excluded
  /// (D-039).
  final Money salesThisPeriod;

  /// Invoices *issued* in [year].
  final Money salesThisYear;

  /// How many documents [salesThisPeriod] is the sum of. The same population,
  /// so the two tiles reconcile.
  final int issuedCountThisPeriod;

  /// Still owed across every invoice that is still a claim on someone,
  /// regardless of period — money owed from two months ago is still owed.
  final Money outstanding;

  final int customerCount;

  /// Not shown as a tile: it is how the page knows whether there is anything
  /// to show at all.
  final int invoiceCount;

  /// Whether the user has genuinely nothing yet.
  ///
  /// Both counts, not just invoices. A user who has entered twenty customers
  /// and no invoices has done real work, and meeting them with "nothing to
  /// show yet" would be both wrong and discouraging — the customer tile has
  /// something true to say.
  bool get isEmpty => invoiceCount == 0 && customerCount == 0;
}
