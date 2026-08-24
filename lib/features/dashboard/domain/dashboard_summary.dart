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
    required this.period,
    required this.salesThisPeriod,
    required this.issuedCountThisPeriod,
    required this.outstanding,
    required this.customerCount,
    required this.invoiceCount,
  });

  /// The **Jalali** month the two period figures cover (D-006), carried so the
  /// caption on screen names the same month the query used rather than one the
  /// screen resolves separately.
  final InstantRange period;

  /// Invoices *issued* in [period] — drafts and cancellations excluded
  /// (D-039).
  final Money salesThisPeriod;

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
