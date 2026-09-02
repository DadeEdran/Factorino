import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../data/models/invoice.dart';
import '../../../../data/models/invoice_detail.dart';
import '../../application/invoice_cancellation.dart';
import '../../domain/invoice_number_label.dart';

/// Issuing a **saved draft**, from the invoice detail screen.
///
/// **The gap this closes.** Issuing lived only on the editor screen, at the
/// moment of creation: `InvoiceEditor` is keyed by the instant it was opened
/// and always creates a new invoice, so nothing anywhere led from a saved draft
/// to an issued one. A draft was a dead end, and because every downstream
/// action — recording a payment, cancelling — is correctly unavailable on a
/// draft, the whole detail page read as broken rather than as incomplete.
/// Reported from a phone, 2026-09-02.
///
/// **The confirmation is the editor's, verbatim.** Issuing allocates a number
/// that is spent permanently even if the invoice is later cancelled (D-013) and
/// it ends editability (§6). Those consequences do not depend on where issuing
/// was started from, and two separately-worded explanations of one irreversible
/// act is how they drift apart.
Future<void> issueInvoice(
  BuildContext context,
  WidgetRef ref,
  InvoiceDetail detail,
  AppStrings strings,
) async {
  final bool confirmed = await _confirm(context, detail, strings);
  if (!confirmed || !context.mounted) return;

  final Invoice? issued = await ref
      .read(invoiceCancellationProvider(detail.invoice.id).notifier)
      .issue();
  if (!context.mounted) return;

  // **Names the number**, because it is the one fact that did not exist a
  // moment ago and the thing the user will quote to their customer.
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(
        issued == null
            ? strings.invoiceSaveFailed
            : strings.invoiceIssueSuccess(invoiceNumberLabel(issued, strings)),
      ),
    ),
  );
}

/// Says what issuing costs, before it is done.
///
/// Neither consequence is visible from the button and both are irreversible:
/// the number is spent permanently, and the document stops being editable. The
/// amount is shown because it is what the user is committing to.
Future<bool> _confirm(
  BuildContext context,
  InvoiceDetail detail,
  AppStrings strings,
) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(strings.invoiceIssueConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.invoiceIssueConfirmBody),
          const SizedBox(height: AppSpacing.md),
          AmountText(detail.invoice.grandTotal, unitLabel: strings.unitToman),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(strings.invoiceIssueConfirmAction),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// The wider tiers' entry point.
///
/// **Mirrors how recording a payment is offered** (D-060): the phone puts the
/// primary action in the floating slot, and the wider tiers put it inline, so
/// the two are never on screen together. A draft has no payments card to hang
/// this off, so it sits under the summary — where the editor's own issue button
/// sits, which is where a user who has just been in the editor will look.
class InvoiceIssueButton extends ConsumerWidget {
  const InvoiceIssueButton({
    required this.detail,
    required this.strings,
    super.key,
  });

  final InvoiceDetail detail;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Absent where it does not apply, never disabled (D-021), and absent on the
    // phone because the floating action already carries it.
    if (!detail.invoice.isEditable || context.tier.isMobile) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: FilledButton.icon(
        onPressed: () => issueInvoice(context, ref, detail, strings),
        icon: const Icon(Icons.check),
        label: Text(strings.invoiceIssueAction),
      ),
    );
  }
}
