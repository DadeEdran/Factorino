import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/jalali_display.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/localization/month_names.dart';
import '../../../core/money/money.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/router/destinations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/record_field.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/customer_snapshot.dart';
import '../../../data/models/invoice_detail.dart';
import '../../../data/models/invoice_status.dart';
import '../application/invoices_providers.dart';
import '../domain/invoice_number_label.dart';
import '../domain/invoice_party_view.dart';
import '../domain/invoice_status_view.dart';
import '../domain/invoice_summary_figures.dart';
import 'widgets/invoice_cancel_action.dart';
import 'widgets/invoice_issue_action.dart';
import 'widgets/invoice_document_lines.dart';
import 'widgets/invoice_payments_section.dart';
import 'widgets/invoice_totals_summary.dart';

/// One invoice as the document it is.
///
/// **The first read site for everything schema v4 stored** (D-055, D-056). A
/// line is laid out from its own columns — gross, discount, share of the
/// invoice discount, net, tax, total — and the summary starts from a stored
/// `grossTotal`. Nothing on this screen multiplies, rounds or adds; where a
/// pre-v4 figure was never recorded the screen says «ثبت‌نشده» and says, once,
/// that the payable amount is unaffected.
///
/// **The party is `InvoiceDetail.party`, never `detail.customer`** (D-052), and
/// this screen is where the difference between the two finally has to be
/// visible. `party` is what the document states: the snapshot taken at issue, or
/// the live record read through where there is none. `customer` is the record as
/// it stands today — the mobile number to reach them on, and where «رفتن به
/// پروندهٔ مشتری» leads. When the two have come apart, [InvoicePartyProvenance]
/// decides which of four sentences the screen owes the user, so a name that is
/// no longer the customer's reads as history rather than as stale data.
///
/// **Cancellation is the correction path, and this page is where it lives**
/// (§6, D-061). It is an item in the title row's menu, never an edit: an issued
/// invoice is corrected by being cancelled and reissued, and the confirmation
/// says what that does *and does not* do — the number stays spent (D-013), the
/// record stays, and any payment already recorded stays with it. A cancelled
/// invoice that carries payments says so on the page afterwards too, in two
/// places: the balance is not a claim any more, and the paid figure is money
/// that really was received.
///
/// **Nothing here is logged.** Like the customer detail screen, this page holds
/// a whole party — name, company, کد ملی, کد اقتصادی, address — beside a column
/// of amounts, which makes it the likeliest place for an innocuous debug line to
/// violate §7. It makes no log call at all; the only line the page can produce
/// comes from [AsyncErrorView], which logs a provider failure and carries no
/// value.
class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({required this.invoiceId, super.key});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final AsyncValue<InvoiceDetail?> detail = ref.watch(
      invoiceDetailProvider(invoiceId),
    );

    void back() => context.go(AppDestination.invoices.path);

    Widget frame({required String title, required Widget child}) => PageBody(
      title: title,
      onBack: back,
      backTooltip: strings.invoiceBackTooltip,
      child: child,
    );

    return detail.when(
      // The section name while the invoice loads, because the invoice's own
      // number is precisely what is not known yet. It resolves in a frame from
      // a local database; inventing a placeholder number would not, and an
      // invoice number is the last thing that should ever appear speculatively.
      loading: () =>
          frame(title: strings.invoicesTitle, child: const _DetailSkeleton()),
      error: (Object error, StackTrace stack) => frame(
        title: strings.invoicesTitle,
        child: AsyncErrorView(
          error: error,
          stackTrace: stack,
          scope: 'invoice-detail',
          onRetry: () => ref.invalidate(invoiceDetailProvider(invoiceId)),
        ),
      ),
      data: (InvoiceDetail? view) {
        if (view == null) {
          // A stale deep link, or the invoice was deleted while the page was
          // opening. Saying so beats rendering an empty document, which reads
          // as an invoice with nothing on it rather than as no invoice.
          return frame(
            title: strings.invoicesTitle,
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: strings.invoiceDetailNotFoundTitle,
              body: strings.invoiceDetailNotFoundBody,
              action: FilledButton(
                onPressed: back,
                child: Text(strings.invoiceDetailBackToList),
              ),
            ),
          );
        }

        return PageBody(
          title: strings.invoiceDetailTitle(
            invoiceNumberLabel(view.invoice, strings),
          ),
          onBack: back,
          backTooltip: strings.invoiceBackTooltip,
          // The primary action, in the slot a phone puts one (§10). The
          // payments card carries the same action on the wider tiers and omits
          // it here, so the two are never on screen together.
          //
          // **A draft's primary action is issuing it, and that slot was empty
          // until 2026-09-02.** `acceptsPayments` is false for a draft, so the
          // phone showed no floating action at all — and since issuing lived
          // only on the editor screen, a saved draft had no way forward
          // anywhere on this page. The user who reported it read the whole
          // screen as broken, which it effectively was. The two states are
          // mutually exclusive by construction: `isEditable` and
          // `acceptsPayments` cannot both be true.
          floatingAction: switch (context.tier.isMobile) {
            true when view.invoice.isEditable => FloatingActionButton.extended(
              onPressed: () => issueInvoice(context, ref, view, strings),
              icon: const Icon(Icons.check),
              label: Text(strings.invoiceIssueAction),
            ),
            // Nothing owed: the action moves into the payments card, which
            // says why. See `InvoicePaymentsSection`.
            true when view.invoice.acceptsPayments && !view.isFullyPaid =>
              FloatingActionButton.extended(
                onPressed: () => recordPayment(context, ref, view, strings),
                icon: const Icon(Icons.add),
                label: Text(strings.invoiceDetailRecordPayment),
              ),
            _ => null,
          },
          actions: <Widget>[
            _StatusChip(
              detail: view,
              strings: strings,
              now: ref.watch(nowProvider),
            ),
            // In the title row rather than in a card of its own, and that is
            // the §10 layout rule rather than a preference: a card here would
            // be the fourth thing added above the lines on this family of
            // screens, after the customer record card (D-044), the party card
            // (b) and the payments card (c). See [InvoiceCancelAction].
            InvoiceCancelAction(detail: view, strings: strings),
          ],
          child: _DetailBody(detail: view, strings: strings),
        );
      },
    );
  }
}

/// The status, beside the title rather than inside the body.
///
/// It is the one fact about an invoice that is not on the document — a printed
/// invoice does not say whether it has been paid — so it belongs to the page
/// rather than to the paper.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.detail,
    required this.strings,
    required this.now,
  });

  final InvoiceDetail detail;
  final AppStrings strings;

  /// Read from the clock provider by the screen, so the overdue derivation
  /// answers against one instant (D-041).
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final InvoiceStatusView view = invoiceStatusViewOf(
      detail.invoice,
      now: now,
    );
    return StatusBadge(status: view, label: invoiceStatusLabel(view, strings));
  }
}

/// The document, laid out for the tier.
///
/// Desktop puts the party and the summary in a panel beside the lines, on the
/// customer detail screen's shape (D-044) and for the same reason: the lines are
/// a table that needs the width, and the party is label-and-value pairs read
/// down a column. Mobile and tablet are one column, slivers rather than a
/// `ListView` of children so a hundred-line invoice stays virtualized (§13).
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.strings});

  final InvoiceDetail detail;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final LayoutTier tier = context.tier;

    final Widget party = _PartyCard(detail: detail, strings: strings);
    final Widget dates = _DatesCard(detail: detail, strings: strings);
    final Widget summary = _Summary(detail: detail, strings: strings);
    // Directly under the figures it commits to, and absent on the phone, where
    // the floating action carries it instead.
    final Widget issue = InvoiceIssueButton(detail: detail, strings: strings);
    final Widget notes = _NotesCard(detail: detail, strings: strings);
    final Widget payments = InvoicePaymentsSection(
      detail: detail,
      strings: strings,
    );

    final Widget lines = detail.items.isEmpty
        ? _NoLines(strings: strings)
        : InvoiceDocumentLines(
            invoice: detail.invoice,
            items: detail.items,
            strings: strings,
            tier: tier,
          );

    if (tier.usesTables) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ListView(
              children: <Widget>[
                SectionHeader(title: strings.invoiceDetailLinesSection),
                lines,
                const SizedBox(height: AppSpacing.xxl),
                notes,
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          SizedBox(
            width: AppLayout.detailPanelWidth,
            child: ListView(
              children: <Widget>[
                summary,
                issue,
                const SizedBox(height: AppSpacing.lg),
                // Directly under the figures they move. A payment recorded here
                // changes «مانده» one card up, and putting the two a scroll
                // apart would make that look like the page had not updated.
                payments,
                const SizedBox(height: AppSpacing.lg),
                party,
                const SizedBox(height: AppSpacing.lg),
                dates,
              ],
            ),
          ),
        ],
      );
    }

    // **Summary, then lines, then the party.** Two decisions, and the second was
    // made by writing the test rather than by taste.
    //
    // The summary is first because someone opening a stored invoice is nearly
    // always checking one figure — what it came to, and what is still owed — and
    // putting anything above it means scrolling past the document to reach its
    // answer on every visit.
    //
    // The party and the payments sit **below** the lines, which is the reverse
    // of a printed invoice and the same conclusion D-044 reached about the
    // customer record card. Neither has an upper bound on its height — a party
    // card is five fields, up to three notices and a contact block; a payments
    // card is one row per payment — so above the lines they push them
    // arbitrarily far down the one screen whose purpose is to show them.
    // **Measured on a 400 x 800 phone rather than argued**: with the party above
    // them the first line was off the bottom entirely, and the payments card
    // costs 182 pixels even with nothing in it. The order here is the one the
    // desktop tier reads in: the document in the main column, who and when and
    // what has been paid beside it.
    //
    // On a phone the record action moves to the floating slot instead, so it
    // stays reachable without scrolling past the lines to find it.
    return ListView(
      children: <Widget>[
        summary,
        issue,
        const SizedBox(height: AppSpacing.xxl),
        SectionHeader(title: strings.invoiceDetailLinesSection),
        lines,
        const SizedBox(height: AppSpacing.xxl),
        payments,
        const SizedBox(height: AppSpacing.lg),
        party,
        const SizedBox(height: AppSpacing.lg),
        dates,
        const SizedBox(height: AppSpacing.lg),
        notes,
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// What the document says about who was billed — and, where they differ, what
/// the customer's record says now.
///
/// **Every field here comes from [InvoiceDetail.party]** except the mobile
/// number, which is deliberately not part of the snapshot: contact detail rather
/// than document content, so an invoice reprinted next year reaches the number
/// the customer has now (D-052). It is labelled as contact, under its own
/// heading, so the two are not read as one block of party details of which one
/// happens to be live.
///
/// D-030 applies here as it does on the customer screen: a کد ملی is displayed
/// and nothing calls it verified. No tick, no badge, no affirmative word. A user
/// shown "verified" stops checking, which is exactly when a transposed digit
/// that happens to checksum survives onto a tax document.
class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.detail, required this.strings});

  final InvoiceDetail detail;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final CustomerSnapshot party = detail.party;
    final InvoicePartyProvenance provenance = partyProvenanceOf(detail);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(title: strings.invoiceDetailPartySection),
          RecordField(
            label: strings.customerFieldFullName,
            value: party.fullName,
            strings: strings,
          ),
          RecordField(
            label: strings.customerFieldCompany,
            value: party.companyName,
            strings: strings,
          ),
          RecordField(
            label: strings.customerFieldNationalId,
            value: party.nationalId == null
                ? null
                : formatIdentifierForDisplay(party.nationalId!),
            isIdentifier: true,
            strings: strings,
          ),
          RecordField(
            label: strings.customerFieldEconomicId,
            value: party.economicId == null
                ? null
                : formatIdentifierForDisplay(party.economicId!),
            isIdentifier: true,
            strings: strings,
          ),
          RecordField(
            label: strings.customerFieldAddress,
            value: party.address,
            strings: strings,
            isLast: true,
          ),
          _PartyNotice(
            detail: detail,
            provenance: provenance,
            strings: strings,
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: strings.invoiceDetailContactSection),
          RecordField(
            label: strings.customerFieldMobile,
            value: detail.customer.mobile == null
                ? null
                : formatMobileForDisplay(detail.customer.mobile!),
            isIdentifier: true,
            strings: strings,
            isLast: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              // Leads to the **live** record, which is the whole point of
              // keeping `detail.customer` distinct from `detail.party`: a
              // snapshot is not a row and has nowhere to lead.
              onPressed: () =>
                  context.go(AppRoutes.customerDetailFor(detail.customer.id)),
              child: Text(strings.invoiceDetailGoToCustomer),
            ),
          ),
        ],
      ),
    );
  }
}

/// The sentence the screen owes the user about the name above it, if any.
///
/// Four cases, four sentences, and **one of them is silence** — the ordinary
/// case, where the document and the record still agree, gets no notice at all. A
/// panel that explained itself on every invoice would train the user to skip the
/// explanation on the one invoice where it matters.
///
/// The soft-deleted case is orthogonal and stacks: a customer can be both
/// renamed and deleted, and the two facts are separately actionable — one is
/// about which name is right, the other about why they are not in the list.
class _PartyNotice extends StatelessWidget {
  const _PartyNotice({
    required this.detail,
    required this.provenance,
    required this.strings,
  });

  final InvoiceDetail detail;
  final InvoicePartyProvenance provenance;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final List<String> notices = <String>[
      switch (provenance) {
        InvoicePartyProvenance.snapshotMatchesRecord => '',
        InvoicePartyProvenance.snapshotDivergedFromRecord =>
          strings.invoiceDetailPartyDiverged,
        InvoicePartyProvenance.draftFollowsRecord =>
          strings.invoiceDetailPartyDraft,
        InvoicePartyProvenance.issuedWithoutSnapshot =>
          strings.invoiceDetailPartyNoSnapshot,
      },
      if (provenance == InvoicePartyProvenance.snapshotDivergedFromRecord)
        strings.invoiceDetailPartyRecordNow(detail.customer.fullName),
      if (detail.customerIsDeleted) strings.invoiceDetailCustomerDeleted,
    ]..removeWhere((String line) => line.isEmpty);

    if (notices.isEmpty) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final String line in notices)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                line,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// When it was issued, and when it is due.
class _DatesCard extends StatelessWidget {
  const _DatesCard({required this.detail, required this.strings});

  final InvoiceDetail detail;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RecordField(
            label: strings.invoiceDetailIssueDate,
            // Jalali, from a UTC instant, through the one formatter (D-005,
            // D-006). The stored value is never a localized string.
            value: formatJalaliDateLong(
              detail.invoice.issueDate,
              monthNames: jalaliMonthNames(strings),
            ),
            strings: strings,
          ),
          RecordField(
            label: strings.invoiceDetailDueDate,
            // «بدون سررسید» rather than «ثبت نشده»: an invoice with no due date
            // is not one whose due date went unrecorded, it is one that has
            // none, and it can never be overdue.
            value: detail.invoice.dueDate == null
                ? strings.invoiceDetailNoDueDate
                : formatJalaliDateLong(
                    detail.invoice.dueDate!,
                    monthNames: jalaliMonthNames(strings),
                  ),
            strings: strings,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

/// The reconciliation, and what is still owed on it.
///
/// The summary panel is the same widget the invoice form renders, taking the
/// same view model — `ofStored` here rather than `ofCalculation` (D-056) — so
/// the figures a user agreed to on the form are laid out identically on the
/// document, and the wording for an unrecorded gross lives in exactly one place.
///
/// **Paid and outstanding sit beneath it, not inside it.** They are not part of
/// the invoice's reconciliation: the four terms above them are frozen at issue,
/// and these two move every time a payment is recorded. Putting them in the same
/// equation would invite a reader to subtract one from another that it does not
/// belong to.
class _Summary extends StatelessWidget {
  const _Summary({required this.detail, required this.strings});

  final InvoiceDetail detail;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InvoiceTotalsSummary(
          totals: InvoiceSummaryFigures.ofStored(detail.invoice),
          strings: strings,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _PaymentRow(
                label: strings.invoiceDetailPaidLabel,
                amount: detail.amountPaid,
                strings: strings,
              ),
              const SizedBox(height: AppSpacing.sm),
              _PaymentRow(
                label: strings.invoiceDetailDueLabel,
                amount: detail.amountDue,
                strings: strings,
              ),
              // An overpayment is invisible in the remaining balance by design
              // -- it clamps at zero, because an invoice cannot owe money -- so
              // it is said rather than left to be inferred from a total that
              // stopped moving.
              if (detail.isOverpaid) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  strings.invoiceDetailOverpaidNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              // **«مانده» is still shown on a cancelled invoice, and explained
              // rather than hidden** (D-061). The figure is real -- it is what
              // was never paid -- but on a void document it reads as money the
              // customer still owes, which is the one thing a cancellation
              // means it is not. Removing the row instead would leave the page
              // silently missing a number it shows on every other invoice.
              if (detail.invoice.status == InvoiceStatus.cancelled) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  strings.invoiceDetailCancelledDueNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.amount,
    required this.strings,
  });

  final String label;
  final Money amount;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        AmountText(
          amount,
          unitLabel: strings.unitToman,
          size: AmountSize.small,
        ),
      ],
    );
  }
}

/// The invoice's note, where it has one. Absent entirely where it does not —
/// unlike a party field, a missing note is not a gap in the record, so an
/// empty card saying «ثبت نشده» would be a card about nothing.
class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.detail, required this.strings});

  final InvoiceDetail detail;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final String? notes = detail.invoice.notes;
    if (notes == null || notes.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(title: strings.invoiceDetailNotesSection),
          Text(notes, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// A saved invoice with no lines.
///
/// Rare and reachable, and the one case where a gross of zero is a real figure
/// rather than a missing one — which is why the v4 column is nullable at all
/// (D-056). So the section says the invoice has no lines and the summary above
/// prints its zeros honestly.
class _NoLines extends StatelessWidget {
  const _NoLines({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      child: Text(
        strings.invoiceDetailNoLines,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A placeholder shaped like the page it stands in for, so nothing jumps when
/// the invoice lands (§10).
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Skeleton(
                width: AppSkeleton.captionWidth,
                height: AppSkeleton.lineHeight,
              ),
              SizedBox(height: AppSpacing.sm),
              Skeleton(
                width: AppSkeleton.titleWidth,
                height: AppSkeleton.titleHeight,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (int i = 0; i < 3; i++) ...<Widget>[
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Skeleton(
                  width: AppSkeleton.titleWidth,
                  height: AppSkeleton.lineHeight,
                ),
                SizedBox(height: AppSpacing.sm),
                Skeleton(
                  width: AppSkeleton.captionWidth,
                  height: AppSkeleton.lineHeight,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
