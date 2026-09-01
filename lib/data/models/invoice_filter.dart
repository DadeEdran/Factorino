import '../../core/date/jalali_period.dart';
import 'invoice_status.dart';

/// What subset of the invoices a list is asking for.
///
/// **One value rather than three parameters**, for the reason `ListQuery`
/// already gives about paging (D-038): a screen that held status, customer and
/// period as three independent pieces of state would issue three queries while
/// the user changed one filter, and would show a list belonging to none of the
/// three states in between.
///
/// **Every field here is applied in SQL**, never by filtering a loaded page in
/// Dart. That is the whole point of the type: it exists to be
/// handed to the repository, not to be used as a predicate over a list.
///
/// **The period is an [InstantRange], not a month number**, because the
/// calendar decision belongs in `core/date/` and nowhere else (D-006). A caller
/// picks «این ماه» and `jalaliMonthOf` turns that into two UTC instants; the
/// query only compares. A Gregorian month boundary reaching here would be a bug
/// rather than a simplification, and it cannot, because there is no way to
/// express one.
class InvoiceFilter {
  const InvoiceFilter({
    this.statuses = const <InvoiceStatus>{},
    this.customerId,
    this.period,
  });

  /// The statuses to include. **Empty means every status**, not none — the
  /// unfiltered list is the default and has to be the cheapest thing to say.
  ///
  /// These are the five **stored** statuses. `overdue` is deliberately absent:
  /// it is derived at display time from the due date against one instant
  /// (D-041), and a SQL predicate for it would be a second implementation of a
  /// rule `invoiceStatusViewOf` already owns — the kind of duplication that
  /// ends with a badge and a filter disagreeing about the same invoice.
  /// Nothing becomes unreachable: an overdue invoice is `unpaid` or
  /// `partiallyPaid` and appears under those.
  final Set<InvoiceStatus> statuses;

  /// One customer, by id. The **id**, never the name: a name is not unique and
  /// is not what the foreign key holds.
  final String? customerId;

  /// A half-open range of instants, computed in the Jalali calendar.
  final InstantRange? period;

  bool get isActive =>
      statuses.isNotEmpty || customerId != null || period != null;

  /// How many of the three are set — for the badge on the filter control, so a
  /// user who has narrowed the list can see that they have.
  int get activeCount =>
      (statuses.isEmpty ? 0 : 1) +
      (customerId == null ? 0 : 1) +
      (period == null ? 0 : 1);

  InvoiceFilter withStatuses(Set<InvoiceStatus> value) =>
      InvoiceFilter(statuses: value, customerId: customerId, period: period);

  /// Passing null clears it, which is why this cannot be a copy-with taking
  /// optional named parameters: `copyWith(customerId: null)` cannot be told
  /// apart from `copyWith()`, and clearing a filter is the operation a user
  /// performs most.
  InvoiceFilter withCustomer(String? value) =>
      InvoiceFilter(statuses: statuses, customerId: value, period: period);

  InvoiceFilter withPeriod(InstantRange? value) =>
      InvoiceFilter(statuses: statuses, customerId: customerId, period: value);

  static const InvoiceFilter none = InvoiceFilter();

  @override
  bool operator ==(Object other) =>
      other is InvoiceFilter &&
      other.customerId == customerId &&
      other.period == period &&
      _sameStatuses(other.statuses);

  bool _sameStatuses(Set<InvoiceStatus> other) {
    if (other.length != statuses.length) return false;
    for (final InvoiceStatus status in statuses) {
      if (!other.contains(status)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    customerId,
    period,
    // Order-independent, because a `Set` has none and two filters built by
    // tapping the same chips in a different order are the same filter.
    statuses.fold<int>(0, (int acc, InvoiceStatus s) => acc ^ s.index.hashCode),
  );

  @override
  String toString() =>
      'InvoiceFilter(statuses: ${statuses.length}, '
      'customer: ${customerId == null ? 'any' : 'one'}, '
      'period: ${period == null ? 'any' : 'set'})';
}
