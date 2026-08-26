import '../../../core/formatting/jalali_display.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../data/models/invoice.dart';

/// What to show where an invoice number goes.
///
/// A draft has no number (D-048), so every place that renders one has to say
/// so. This is the single place that decides how — three widgets rendering the
/// same absence three ways is how a product ends up with an empty cell in one
/// layout, a dash in another and a placeholder in the third, none of which the
/// user can tell apart from a bug.
///
/// It also owns the bidi rule, which differs between the two cases and is easy
/// to get wrong by symmetry. A real number is isolated: `INV-1405-0001` mixes a
/// Latin prefix, digits and hyphens, and that run resolves against whatever
/// sits beside it in RTL (§9). The Persian placeholder is ordinary RTL prose
/// and must **not** be isolated — there is nothing to protect, and wrapping it
/// would only add invisible control characters to a string that tests and
/// screen readers both have to handle.
String invoiceNumberLabel(Invoice invoice, AppStrings strings) {
  final String? number = invoice.number;
  return number == null ? strings.invoiceNumberPending : isolate(number);
}
