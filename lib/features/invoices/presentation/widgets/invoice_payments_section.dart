import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/jalali_display.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/formatting/number_display.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/invoice_detail.dart';
import '../../../../data/models/invoice_status.dart';
import '../../../../data/models/payment.dart';
import '../../application/invoice_payments.dart';
import '../../domain/payment_method_label.dart';
import 'payment_editor_sheet.dart';

/// The payments recorded against one invoice, and the two things a user does
/// with them.
///
/// **The status is never touched here.** Recording or removing a payment
/// recomputes the invoice's derived status inside the repository's own
/// transaction (§6), and `invoiceDetailProvider` is a live query — so the badge
/// at the top of the page changes because the row changed, not because this
/// widget told it to. A second, independent determination made at display time
/// is how a badge comes to contradict the payments listed underneath it.
///
/// **Where a payment cannot be recorded, the reason is said rather than the
/// control merely being absent.** A draft is not yet a claim on anyone and a
/// cancelled invoice is not one any more (`Invoice.acceptsPayments`), and both
/// are states a user can arrive in without knowing what changed. The repository
/// refuses these too — the screen explains the rule, it does not enforce it.
class InvoicePaymentsSection extends ConsumerWidget {
  const InvoicePaymentsSection({
    required this.detail,
    required this.strings,
    super.key,
  });

  final InvoiceDetail detail;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool acceptsPayments = detail.invoice.acceptsPayments;
    // **The button is absent on a phone because the floating one is already
    // there**, exactly as the invoice list omits its empty-state button on
    // mobile: a second control saying the same thing is one too many (§10). On
    // the wider tiers there is no floating action, and this is the only way in.
    final bool showInlineAction = acceptsPayments && !context.tier.isMobile;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(title: strings.invoiceDetailPaymentsSection),
          if (detail.payments.isEmpty)
            Text(
              strings.invoiceDetailPaymentsEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final Payment payment in detail.payments)
              _PaymentRow(
                detail: detail,
                payment: payment,
                strings: strings,
                // Last one on the list gets no divider under it.
                isLast: payment == detail.payments.last,
              ),
          const SizedBox(height: AppSpacing.md),
          if (showInlineAction)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                onPressed: () => recordPayment(context, ref, detail, strings),
                icon: const Icon(Icons.add, size: AppIconSize.md),
                label: Text(strings.invoiceDetailRecordPayment),
              ),
            )
          else if (!acceptsPayments)
            Text(
              detail.invoice.status == InvoiceStatus.draft
                  ? strings.invoiceDetailPaymentsUnavailableDraft
                  : strings.invoiceDetailPaymentsUnavailableCancelled,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens the sheet and writes what it produces.
///
/// **Top-level because it has two callers on two different tiers**: the button
/// inside the card on tablet and desktop, and the screen's floating action on a
/// phone. One function rather than two identical closures, so the two entry
/// points cannot come to record a payment differently.
Future<void> recordPayment(
  BuildContext context,
  WidgetRef ref,
  InvoiceDetail detail,
  AppStrings strings,
) async {
  final PaymentDraft? draft = await showPaymentEditorSheet(
    context,
    // Already computed by the aggregate. Passing it rather than letting the
    // sheet work it out is what keeps one answer to "what is still owed".
    amountDue: detail.amountDue,
    today: ref.read(nowProvider),
  );
  if (draft == null || !context.mounted) return;

  final bool written = await ref
      .read(invoicePaymentsProvider(detail.invoice.id).notifier)
      .record(draft);

  if (!written && context.mounted) {
    _sayItFailed(context, strings.paymentSaveFailed);
  }
}

/// One recorded payment: what, when, how, and the note if there is one.
class _PaymentRow extends ConsumerWidget {
  const _PaymentRow({
    required this.detail,
    required this.payment,
    required this.strings,
    required this.isLast,
  });

  final InvoiceDetail detail;
  final Payment payment;
  final AppStrings strings;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // A `Wrap`, not a `Row`: the date and the method are two
                    // runs that must not be truncated, and on a narrow card the
                    // pair does not always fit on one line.
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xxs,
                      children: <Widget>[
                        Text(
                          formatJalaliDate(payment.paidAt),
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          paymentMethodLabel(payment.method, strings),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (payment.note case final String note
                        when note.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(note, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AmountText(
                payment.amount,
                unitLabel: strings.unitToman,
                size: AmountSize.small,
              ),
              IconButton(
                onPressed: () => _confirmAndDelete(context, ref),
                tooltip: strings.paymentDeleteAction,
                icon: const Icon(Icons.delete_outline, size: AppIconSize.md),
              ),
            ],
          ),
          if (!isLast)
            Divider(
              height: AppSpacing.md,
              color: theme.colorScheme.outlineVariant,
            ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    // **Whether the status moves is decided before the dialog is shown, from
    // the row's own numbers, and only to word the warning.** The status itself
    // is recomputed by the repository inside the delete's transaction (§6) --
    // this is a claim about what the user is about to cause, not a second
    // derivation of it.
    final bool leavesPaid =
        detail.invoice.status == InvoiceStatus.paid &&
        detail.amountPaid - payment.amount < detail.invoice.grandTotal;

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(strings.paymentDeleteTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.paymentDeleteBody(
                    formatGroupedPersian(payment.amount.toman),
                  ),
                ),
                // Only where it is true. A warning shown on every deletion is a
                // warning nobody reads on the one that matters.
                if (leavesPaid) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(strings.paymentDeleteStatusWarning),
                ],
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.paymentDeleteAction),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !context.mounted) return;

    final bool deleted = await ref
        .read(invoicePaymentsProvider(detail.invoice.id).notifier)
        .delete(payment.id);

    if (!deleted && context.mounted) {
      _sayItFailed(context, strings.paymentDeleteFailed);
    }
  }
}

/// A failed write is a friendly Persian line, never an exception (§7).
void _sayItFailed(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(message)));
}
