import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/number_display.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../data/models/invoice_detail.dart';
import '../../application/invoice_cancellation.dart';

/// The document's own actions, in the page's title row.
///
/// **A menu rather than a card, and that is the interesting part.** Every
/// obvious home for a cancel button is a block of content: an actions card at
/// the foot of the page, a button under the summary, a bar above the lines. All
/// of them add height, and the payments card in (c) was the *third* time a card
/// added to this family of screens pushed the first invoice line off a 400 × 800
/// phone — after the customer record card (D-044) and the party card (b). The
/// rule that finding earned is now written into the project spec, and this is the
/// first widget it applies to: the title row already exists, costs no vertical
/// space at any tier, and is where the customer and product screens already put
/// exactly this pair of actions.
///
/// **A menu of one item is deliberate.** The alternative — a bare icon in the
/// title row — would put an irreversible, destructive action behind a glyph
/// nobody can name. A menu item is a Persian sentence fragment the user reads
/// before they commit to anything, and it is the slot the rest of the document's
/// actions (a draft's deletion, the Phase 7 export) will join.
///
/// **The page stays where it is afterwards**, unlike the customer screen's
/// delete, which leaves for the list. A cancelled invoice is still a document,
/// still numbered and still the thing the user was looking at — and the state
/// they have just created is precisely the one that needs explaining, so hiding
/// it behind a navigation would undo half the point of the increment.
///
/// **Absent, not disabled, where it does not apply.** `Invoice.isCancellable`
/// is false for a draft and for an invoice already cancelled; the repository
/// refuses both (`InvoiceNotCancellable`), and a disabled control that never
/// explains itself is the affordance-leading-nowhere D-021 rules out. What a
/// draft *should* offer instead is deletion, which is not this increment's —
/// so the menu itself disappears rather than offering the wrong way out.
class InvoiceCancelAction extends ConsumerWidget {
  const InvoiceCancelAction({
    required this.detail,
    required this.strings,
    super.key,
  });

  final InvoiceDetail detail;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!detail.invoice.isCancellable) return const SizedBox.shrink();

    return PopupMenuButton<_InvoiceAction>(
      tooltip: strings.actionMore,
      icon: const Icon(Icons.more_vert, size: AppIconSize.md),
      onSelected: (_InvoiceAction action) => switch (action) {
        _InvoiceAction.cancel => _cancel(context, ref),
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_InvoiceAction>>[
        PopupMenuItem<_InvoiceAction>(
          value: _InvoiceAction.cancel,
          child: Text(strings.invoiceCancelAction),
        ),
      ],
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await _confirm(context);
    if (!confirmed || !context.mounted) return;

    final bool cancelled = await ref
.read(invoiceCancellationProvider(detail.invoice.id).notifier)
.cancel();
    if (!context.mounted) return;

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          cancelled
              ? strings.invoiceCancelSuccess
: strings.invoiceCancelFailed,
        ),
      ),
    );
  }

  /// Says what cancelling does **and does not** do, before it is done.
  ///
  /// Two sentences, and the second is conditional. The first is true of every
  /// invoice: the document is kept and marked, the number stays spent (D-013),
  /// and editing is still not the way back (§6). The second is shown **only
  /// where the invoice actually carries payments** — D-060's rule, because a
  /// warning printed on every cancellation is one nobody reads on the
  /// cancellation where it matters.
  ///
  /// The paid figure is named rather than described. "Payments are kept" is a
  /// policy; «۵٬۰۰۰٬۰۰۰ تومان … بازگردانده نمی‌شود» is the amount the user is
  /// about to leave sitting on a void document, which is the thing they would
  /// otherwise query afterwards.
  Future<bool> _confirm(BuildContext context) async {
    final bool hasPayments = detail.payments.isNotEmpty;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.invoiceCancelTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(strings.invoiceCancelBody),
            if (hasPayments) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                strings.invoiceCancelPaymentsNote(
                  formatGroupedPersian(detail.amountPaid.toman),
                ),
              ),
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
            child: Text(strings.invoiceCancelAction),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

enum _InvoiceAction { cancel }
