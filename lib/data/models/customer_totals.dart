import '../../core/money/money.dart';

/// What one customer has been billed and what they still owe.
///
/// Both figures come from **one** SQL statement over that customer's invoices
/// (§13), never by folding the invoice list in Dart. The list on the screen is
/// paged and the totals are not, so a total computed from the rows on screen
/// would quietly mean "of the twenty invoices we happen to have loaded" while
/// reading as "of this customer".
///
/// One value rather than two, for the reason `DashboardSummary` is one value:
/// two figures a user reads side by side and expects to reconcile must belong
/// to the same moment. Two streams settle at two instants, and in between the
/// screen shows a pair that never was.
class CustomerTotals {
  const CustomerTotals({required this.billed, required this.outstanding});

  /// The sum of `grandTotal` over invoices **issued** to this customer.
  ///
  /// Drafts and cancellations are excluded, exactly as they are on the
  /// dashboard (D-039): a draft is not yet a claim on anyone, so counting it
  /// here would make a customer's history grow while the user was still typing
  /// an invoice they had not issued. The caption on screen says so, because a
  /// figure the user cannot reconcile against the list beneath it is a figure
  /// they learn to distrust.
  final Money billed;

  /// `grandTotal − payments received`, over invoices that are still a claim on
  /// this customer — `unpaid` and `partiallyPaid`.
  ///
  /// Not `billed` minus something: a paid invoice contributes to [billed] and
  /// nothing to this, and an invoice half-paid contributes its remainder. The
  /// two answer different questions and neither is derivable from the other.
  final Money outstanding;

  /// Whether this customer has any issued history at all.
  ///
  /// Both figures, because a customer whose only invoice was cancelled has
  /// been billed nothing and owes nothing, and saying "no history" of them is
  /// truer than showing two zeroes as though they were measurements.
  bool get isEmpty => billed.rial == 0 && outstanding.rial == 0;

  @override
  bool operator ==(Object other) =>
      other is CustomerTotals &&
      other.billed == billed &&
      other.outstanding == outstanding;

  @override
  int get hashCode => Object.hash(billed, outstanding);
}
