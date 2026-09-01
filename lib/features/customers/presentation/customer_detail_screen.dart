import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/jalali_display.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/router/destinations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_table.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/record_field.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../data/models/customer.dart';
import '../../invoices/presentation/invoices_screen.dart';
import '../application/customers_providers.dart';
import '../domain/customer_detail_view.dart';
import 'customer_delete_dialog.dart';

/// One customer: their record, what they have been billed, and their invoices.
///
/// The only screen in the product that answers *"what is my history with this
/// customer"*, which is why it exists at all — the edit form already shows
/// every field, so a detail page that only repeated the record would be a page
/// that duplicates a form (§15).
///
/// Four things it is obliged to get right:
///
/// * **The totals are SQL aggregates over every invoice this customer has**,
///   not a fold over the rows on screen (§13). The list is capped; the totals
///   are not, and a figure computed from the visible rows would quietly mean
///   "of the ones we loaded" while reading as "of this customer".
/// * **Identifiers go through the bidi-isolating formatters** (§9). A کد ملی
///   dropped bare into Persian text can reorder, and the same number then reads
///   differently here than on the card the user is copying from.
/// * **D-030 holds here too.** This screen *displays* a stored national ID, and
///   a passing checksum was never an identity — so there is no tick, no badge,
///   and no affirmative word anywhere near the value. A user shown "verified"
///   stops checking, which is exactly when a transposed digit that happens to
///   checksum survives onto a tax document.
/// * **Invoice rows lead to the invoice.** They were inert until Phase 5 (b),
///   because `/invoices/:id` was unregistered and an affordance leading nowhere
///   is worse than its absence (D-021, one level down); the row and the route
///   became real in the same change. `InvoiceCard` and `InvoiceTableRow` carry
///   the navigation themselves, so this screen and the invoice list cannot come
///   to disagree about where a row goes.
///
/// **Nothing here is logged.** This is the first screen that shows a customer's
/// whole record in one place — name, company, mobile, national ID, economic ID,
/// address, notes — which makes it the likeliest place for an innocuous debug
/// line to violate §7. `logging_path_test.dart` scans every `AppLog` call in
/// `lib/` for those accessors by name and fails the build on one; this file
/// makes no log call at all, and the only line the page can produce comes from
/// [AsyncErrorView], which logs a provider failure once and carries no value.
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({required this.customerId, super.key});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final AsyncValue<CustomerDetailView?> detail = ref.watch(
      customerDetailProvider(customerId),
    );

    void back() => context.go(AppDestination.customers.path);

    return detail.when(
      // The section name while the record is loading, because the customer's
      // own name is precisely what is not known yet. It resolves in a frame
      // from a local database; inventing a placeholder name would not.
      loading: () => PageBody(
        title: strings.customersTitle,
        onBack: back,
        backTooltip: strings.customerBackToList,
        child: const _DetailSkeleton(),
      ),
      error: (Object error, StackTrace stack) => PageBody(
        title: strings.customersTitle,
        onBack: back,
        backTooltip: strings.customerBackToList,
        child: AsyncErrorView(
          error: error,
          stackTrace: stack,
          scope: 'customer-detail',
          onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
        ),
      ),
      data: (CustomerDetailView? view) {
        if (view == null) {
          // A stale deep link, or the customer was deleted while the page was
          // opening. Saying so beats rendering an empty record, which reads as
          // a customer with no details rather than as no customer.
          return PageBody(
            title: strings.customersTitle,
            onBack: back,
            backTooltip: strings.customerBackToList,
            child: EmptyState(
              icon: Icons.person_off_outlined,
              title: strings.customerNotFoundTitle,
              body: strings.customerNotFoundBody,
              action: FilledButton(
                onPressed: back,
                child: Text(strings.customerBackToList),
              ),
            ),
          );
        }

        return PageBody(
          title: view.customer.fullName,
          onBack: back,
          backTooltip: strings.customerBackToList,
          actions: <Widget>[
            _DetailActions(customer: view.customer, strings: strings),
          ],
          child: _DetailBody(view: view, strings: strings),
        );
      },
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.view, required this.strings});

  final CustomerDetailView view;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LayoutTier tier = context.tier;
    final DateTime now = ref.watch(nowProvider);

    final Widget totals = _Totals(view: view, strings: strings, tier: tier);
    final Widget record = _RecordCard(
      customer: view.customer,
      strings: strings,
      // Open on desktop, where it is a panel with room of its own; collapsed
      // on a phone, where it would otherwise push the invoice list off the
      // page -- see the note on [_RecordCard].
      collapsible: !tier.usesTables,
    );

    if (tier.usesTables) {
      // Desktop: the record sits in its own panel and stays put while the
      // invoices scroll (§10's sticky summary panel). Two genuinely different
      // layouts, not one stretched -- the panel is a column of label/value
      // pairs read downwards, and the main column is a five-column table that
      // needs the width.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                totals,
                const SizedBox(height: AppSpacing.xxl),
                SectionHeader(title: strings.customerInvoicesSection),
                Expanded(
                  child: _InvoiceTable(view: view, strings: strings, now: now),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          SizedBox(
            width: AppLayout.detailPanelWidth,
            child: SingleChildScrollView(child: record),
          ),
        ],
      );
    }

    // Mobile and tablet: one column, one scroll. Slivers rather than a
    // `ListView` of children, because the invoice list has to stay virtualized
    // -- a customer with hundreds of invoices would otherwise build every card
    // to show the four that fit (§13, D-037).
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(child: totals),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        SliverToBoxAdapter(child: record),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        SliverToBoxAdapter(
          child: SectionHeader(title: strings.customerInvoicesSection),
        ),
        if (view.invoices.isEmpty)
          SliverToBoxAdapter(child: _NoInvoices(strings: strings))
        else
          SliverList.separated(
            itemCount: view.invoices.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (BuildContext context, int index) => InvoiceCard(
              item: view.invoices[index],
              strings: strings,
              now: now,
              // The name would be the same on every row of this customer's own
              // page, so the invoice number takes the heading instead.
              showCustomer: false,
            ),
          ),
      ],
    );
  }
}

/// The two figures, side by side, from one query.
class _Totals extends StatelessWidget {
  const _Totals({
    required this.view,
    required this.strings,
    required this.tier,
  });

  final CustomerDetailView view;
  final AppStrings strings;
  final LayoutTier tier;

  @override
  Widget build(BuildContext context) {
    final AmountSize size = tier.isMobile
        ? AmountSize.medium
        : AmountSize.large;

    return TileGrid(
      columns: tier.isMobile ? 1 : 2,
      tiles: <Widget>[
        StatTile(
          label: strings.customerTotalBilled,
          // Names exactly which invoices the figure covers, so the user can
          // reconcile it against the list below rather than having to trust
          // it. Drafts and cancellations are excluded (D-039) and a caption
          // that did not say so would make the total look wrong to anyone who
          // added up the rows.
          caption: strings.customerTotalBilledCaption,
          value: AmountText(
            view.totals.billed,
            unitLabel: strings.unitToman,
            size: size,
          ),
        ),
        StatTile(
          label: strings.customerTotalOutstanding,
          caption: strings.customerTotalOutstandingCaption,
          value: AmountText(
            view.totals.outstanding,
            unitLabel: strings.unitToman,
            size: size,
          ),
        ),
      ],
    );
  }
}

/// The stored record.
///
/// The name is absent on purpose: it is the page title, and repeating it here
/// would be the first row of a card sitting under a heading that already says
/// it.
///
/// Empty fields are shown as «ثبت نشده» rather than hidden. A record that
/// silently omits what is missing looks complete, and the user has no way to
/// tell "no company" from "we do not display companies" — which matters when
/// the missing field is the one an invoice needs.
///
/// **[collapsible] on a phone, and collapsed to begin with.** This card's
/// height has no upper bound the layout can be designed around — notes run to
/// two thousand characters — so above the invoice list it can push that list
/// arbitrarily far down the page, on the one screen whose purpose is to show
/// it. Below the list it would be just as unreachable, past however many
/// invoices the customer has. Collapsing is what keeps both answers in reach:
/// the totals and the history are visible on arrival, and the record is one
/// tap. Desktop has the room for a panel and keeps it open.
class _RecordCard extends StatefulWidget {
  const _RecordCard({
    required this.customer,
    required this.strings,
    required this.collapsible,
  });

  final Customer customer;
  final AppStrings strings;
  final bool collapsible;

  @override
  State<_RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<_RecordCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final Customer customer = widget.customer;
    final AppStrings strings = widget.strings;
    final bool showRows = !widget.collapsible || _expanded;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.collapsible)
            _RecordHeader(
              title: strings.customerDetailsSection,
              tooltip: strings.customerDetailsToggle,
              expanded: _expanded,
              onTap: () => setState(() => _expanded = !_expanded),
            )
          else
            SectionHeader(title: strings.customerDetailsSection),
          if (showRows) ..._rows(customer, strings),
        ],
      ),
    );
  }

  List<Widget> _rows(Customer customer, AppStrings strings) {
    return <Widget>[
      RecordField(
        label: strings.customerFieldCompany,
        value: customer.companyName,
        strings: strings,
      ),
      RecordField(
        label: strings.customerFieldMobile,
        // Grouped and isolated: an Iranian mobile is a run of digits inside
        // Persian text, and without the isolate it can reorder against
        // whatever sits beside it (§9).
        value: customer.mobile == null
            ? null
            : formatMobileForDisplay(customer.mobile!),
        isIdentifier: true,
        strings: strings,
      ),
      RecordField(
        label: strings.customerFieldNationalId,
        // D-030: the value, and nothing that calls it verified. No tick,
        // no badge, no affirmative word -- a passing checksum narrows the
        // space of typos and says nothing about whose number it is.
        value: customer.nationalId == null
            ? null
            : formatIdentifierForDisplay(customer.nationalId!),
        isIdentifier: true,
        strings: strings,
      ),
      RecordField(
        label: strings.customerFieldEconomicId,
        value: customer.economicId == null
            ? null
            : formatIdentifierForDisplay(customer.economicId!),
        isIdentifier: true,
        strings: strings,
      ),
      RecordField(
        label: strings.customerFieldAddress,
        value: customer.address,
        strings: strings,
      ),
      RecordField(
        label: strings.customerFieldNotes,
        value: customer.notes,
        strings: strings,
        isLast: true,
      ),
    ];
  }
}

/// The record card's heading when it can be collapsed.
///
/// The whole row is the target, not just the chevron: a header that is
/// obviously a control but only tappable on a 20-pixel glyph is a control the
/// user misses twice before finding it.
class _RecordHeader extends StatelessWidget {
  const _RecordHeader({
    required this.title,
    required this.tooltip,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final String tooltip;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              // Not `arrow_back`'s directional cousin: a chevron pointing down
              // or up is about vertical disclosure, and vertical does not
              // mirror (§9).
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: AppIconSize.lg,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The invoice table, desktop only. Virtualized, like every other list in the
/// application (D-037).
class _InvoiceTable extends StatelessWidget {
  const _InvoiceTable({
    required this.view,
    required this.strings,
    required this.now,
  });

  final CustomerDetailView view;
  final AppStrings strings;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (view.invoices.isEmpty) return _NoInvoices(strings: strings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTableHeader(
          columns: invoiceColumns(strings, includeCustomer: false),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: view.invoices.length,
            itemBuilder: (BuildContext context, int index) => InvoiceTableRow(
              item: view.invoices[index],
              strings: strings,
              now: now,
              showCustomer: false,
            ),
          ),
        ),
      ],
    );
  }
}

/// A customer with no invoices.
///
/// **No call to action**, deliberately. The invoice form is Phase 4; a button
/// here would be the "افزودن فاکتور" that opens nothing, which §15 prohibits
/// and which is worse than the absence it would be covering.
class _NoInvoices extends StatelessWidget {
  const _NoInvoices({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: strings.customerEmptyInvoicesTitle,
      body: strings.customerEmptyInvoicesBody,
    );
  }
}

/// Edit and delete.
///
/// The same menu the list rows carry, so the two places a customer can be acted
/// on behave identically — including the Persian copy on the delete dialog,
/// which is shared rather than duplicated (see [confirmAndDeleteCustomer]).
///
/// A successful delete leaves the page: the record it was showing is gone from
/// every list, and staying on it would present a customer the application no
/// longer has.
class _DetailActions extends ConsumerWidget {
  const _DetailActions({required this.customer, required this.strings});

  final Customer customer;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_DetailAction>(
      tooltip: strings.actionMore,
      icon: const Icon(Icons.more_vert, size: AppIconSize.md),
      onSelected: (_DetailAction action) => switch (action) {
        _DetailAction.edit => context.go(
          AppRoutes.customerEditFor(customer.id),
        ),
        _DetailAction.delete => _delete(context, ref),
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_DetailAction>>[
        PopupMenuItem<_DetailAction>(
          value: _DetailAction.edit,
          child: Text(strings.actionEdit),
        ),
        PopupMenuItem<_DetailAction>(
          value: _DetailAction.delete,
          child: Text(strings.actionDelete),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool deleted = await confirmAndDeleteCustomer(
      context,
      ref,
      customer.id,
    );
    if (!deleted || !context.mounted) return;
    context.go(AppDestination.customers.path);
  }
}

enum _DetailAction { edit, delete }

/// Shaped like the page that is coming, so nothing jumps when it lands (§10).
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final LayoutTier tier = context.tier;

    return ListView(
      children: <Widget>[
        TileGrid(
          columns: tier.isMobile ? 1 : 2,
          tiles: const <Widget>[StatTileSkeleton(), StatTileSkeleton()],
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < 4; i++) ...<Widget>[
                const Skeleton(
                  width: AppSkeleton.captionWidth,
                  height: AppSkeleton.lineHeight,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Skeleton(
                  width: AppSkeleton.titleWidth,
                  height: AppSkeleton.lineHeight,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
