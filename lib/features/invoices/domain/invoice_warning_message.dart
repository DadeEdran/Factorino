import '../../../core/formatting/number_display.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/money/invoice_calculator.dart';
import '../../../core/money/money.dart';

/// The one place an [InvoiceWarning] becomes something a user reads.
///
/// D-027 gave the engine a way to report a clamped discount as **data** — the
/// kind, the line, and both amounts — and deliberately gave it no message,
/// because user-facing text is Persian and `core/money/` may not reach the
/// localization layer. This is the other end of that: the first and only
/// consumer of `CalculatedInvoice.warnings`.
///
/// **Both figures are always stated.** A message saying "some discount was
/// ignored" tells the user that something is wrong and not which line or by how
/// much, which leaves them to find it by arithmetic — on the one screen where
/// arithmetic is what they were trying to avoid. Requested and applied are
/// named separately, so the difference is readable rather than derivable.
///
/// Amounts are rendered in **Toman** with Persian digits and grouping, matching
/// every other figure on the screen: a warning quoting Rial beside a summary
/// quoting Toman would look like a tenfold error in the app's favour.
String invoiceWarningMessage(
  InvoiceWarning warning,
  AppStrings strings, {

  /// The line's position as the user sees it — 1-based, because
  /// `warning.lineIndex` counts from zero and no invoice has a line zero.
  required int Function(int index) lineNumberOf,
}) {
  final String requested = _toman(warning.requested);
  final String applied = _toman(warning.applied);

  return switch (warning.kind) {
    InvoiceWarningKind.lineDiscountClamped =>
      strings.invoiceWarningLineDiscountClamped(
        formatGroupedPersian(lineNumberOf(warning.lineIndex!)),
        requested,
        applied,
      ),
    InvoiceWarningKind.invoiceDiscountClamped =>
      strings.invoiceWarningInvoiceDiscountClamped(requested, applied),
  };
}

/// Every warning, in the order the engine reported them — line warnings in
/// document order, the invoice-level one last.
List<String> invoiceWarningMessages(
  List<InvoiceWarning> warnings,
  AppStrings strings, {
  int Function(int index)? lineNumberOf,
}) {
  return <String>[
    for (final InvoiceWarning warning in warnings)
      invoiceWarningMessage(
        warning,
        strings,
        lineNumberOf: lineNumberOf ?? (int index) => index + 1,
      ),
  ];
}

/// Toman, grouped, in Persian digits — the display unit everything else on the
/// screen uses (§9). The conversion is [Money]'s, not this file's.
String _toman(Money amount) => formatGroupedPersian(amount.toman);
