import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/jalali_display.dart';
import '../../../core/formatting/number_display.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/router/destinations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/clock.dart';
import '../../../data/models/invoice_filter.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_table.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/load_more_footer.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/invoice_list_item.dart';
import '../application/invoices_providers.dart';
import '../domain/invoice_number_label.dart';
import '../domain/invoice_query.dart';
import '../domain/invoice_status_view.dart';
import 'widgets/invoice_filter_sheet.dart';

/// The invoice list.
///
/// **Real data throughout** (§15). Every row is a row in the encrypted
/// database, and the customer name beside each one comes from the same query
/// that fetched the invoice (D-040) — never from a lookup issued per row.
///
/// Cards on mobile and tablet, a virtualized table on desktop, exactly as the
/// customer and product lists do (D-037). Not `DataTable`: Material's table
/// builds every row it is handed, which is invisible at fifty invoices and
/// fatal at five thousand.
///
/// **Filtered in SQL as of Phase 5 (e)** — status, customer and a Jalali
/// period, applied by the repository as `WHERE` clauses on the same statement
/// that carries the `LIMIT` (§13). This screen never narrows a loaded list: with
/// the limit applied first, a filter matching three invoices out of ten thousand
/// would return whichever happened to fall in the first page, and the screen
/// would say "no results" about data that is right there.
///
/// **The filter control is in the title row and the active filters are a chip
/// row above the list.** The control costs no vertical space at any tier, which
/// is §10's rule about cards on a page whose purpose is the list beneath them;
/// the chip row exists only when something is filtered, and it exists at all
/// because a narrowed list that does not say it is narrowed is how a user
/// concludes their invoices are gone.
///
/// **Rows are tappable as of Phase 5 (b)**, and that is the same rule read the
/// other way: `/invoices/:id` was unregistered and the rows were inert until the
/// screen they open existed (D-021, one level down), so the affordance and its
/// destination arrived in one change. The test asserting the route's absence
/// came out in that change rather than being left to rot green.
class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final LayoutTier tier = context.tier;
    final InvoiceQuery query = ref.watch(invoiceListQueryProvider);
    final AsyncValue<List<InvoiceListItem>> invoices = ref.watch(
      invoiceListProvider,
    );

    return PageBody(
      title: strings.invoicesTitle,
      actions: <Widget>[
        // In the title row on **every** tier, unlike the create action: it is
        // an icon-and-label button that costs no vertical space, and a list you
        // cannot narrow on a phone is the tier where narrowing matters most.
        _FilterButton(filter: query.filter, strings: strings),
        if (!tier.isMobile) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.invoiceCreate),
            icon: const Icon(Icons.add, size: AppIconSize.md),
            label: Text(strings.invoiceCreateAction),
          ),
        ],
      ],
      floatingAction: tier.isMobile
          ? FloatingActionButton.extended(
              onPressed: () => context.go(AppRoutes.invoiceCreate),
              icon: const Icon(Icons.add),
              label: Text(strings.invoiceCreateAction),
            )
          : null,
      child: invoices.when(
        loading: () => SkeletonList(
          rowBuilder: (BuildContext context) => _InvoiceSkeletonRow(tier: tier),
        ),
        error: (Object error, StackTrace stack) => AsyncErrorView(
          error: error,
          stackTrace: stack,
          scope: 'invoices',
          onRetry: () => ref.invalidate(invoiceListProvider),
        ),
        // **Two empty states, because they are two different facts.** With
        // filters on, "you have no invoices" would be false for a user with
        // four hundred of them, and it would send them looking for lost data
        // instead of at the chips they just tapped.
        data: (List<InvoiceListItem> items) => items.isEmpty
            ? (query.isFiltered
                  ? EmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: strings.emptyInvoicesFilteredTitle,
                      body: strings.emptyInvoicesFilteredBody,
                      // The way out of the state, which is not "make an
                      // invoice" -- the invoices exist, the filter is hiding
                      // them.
                      action: FilledButton(
                        onPressed: () => ref
                            .read(invoiceListQueryProvider.notifier)
                            .clearFilter(),
                        child: Text(strings.invoiceFilterClearAll),
                      ),
                    )
                  : EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: strings.emptyInvoicesTitle,
                      body: strings.emptyInvoicesBody,
                      // The call to action §10 asks for. On mobile the floating
                      // button is already on screen over this state, so a
                      // second button saying the same thing would be one too
                      // many.
                      action: tier.isMobile
                          ? null
                          : FilledButton.icon(
                              onPressed: () =>
                                  context.go(AppRoutes.invoiceCreate),
                              icon: const Icon(Icons.add, size: AppIconSize.md),
                              label: Text(strings.invoiceCreateAction),
                            ),
                    ))
            : _InvoiceList(
                items: items,
                query: query,
                tier: tier,
                strings: strings,
                now: ref.watch(nowProvider),
                onLoadMore: () =>
                    ref.read(invoiceListQueryProvider.notifier).loadMore(),
              ),
      ),
    );
  }
}

/// The way into the filter sheet, with a count when something is set.
///
/// **The count is the important half.** A filter control that looks identical
/// filtered and unfiltered is how a user comes back to this screen tomorrow,
/// finds four invoices where there were four hundred, and concludes the
/// application lost them. The number is Persian-digit formatted like every
/// other number in the app (§9).
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.filter, required this.strings});

  final InvoiceFilter filter;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final String label = filter.isActive
        ? strings.invoiceFilterActiveLabel(
            formatGroupedPersian(filter.activeCount),
          )
        : strings.invoiceFilterAction;

    // Tonal when active, plain when not: the state is legible without reading
    // the label, which is what a control the user is scanning past needs.
    return filter.isActive
        ? FilledButton.tonalIcon(
            onPressed: () => showInvoiceFilterSheet(context),
            icon: const Icon(Icons.filter_alt, size: AppIconSize.md),
            label: Text(label),
          )
        : TextButton.icon(
            onPressed: () => showInvoiceFilterSheet(context),
            icon: const Icon(Icons.filter_alt_outlined, size: AppIconSize.md),
            label: Text(label),
          );
  }
}

class _InvoiceList extends StatelessWidget {
  const _InvoiceList({
    required this.items,
    required this.query,
    required this.tier,
    required this.strings,
    required this.now,
    required this.onLoadMore,
  });

  final List<InvoiceListItem> items;
  final InvoiceQuery query;
  final LayoutTier tier;
  final AppStrings strings;
  final DateTime now;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final bool hasMore = query.window.hasMoreAfter(items.length);
    // One extra item for the footer, so it scrolls with the rows rather than
    // pinning to the bottom of the screen.
    final int itemCount = items.length + (hasMore ? 1 : 0);

    if (tier.usesTables) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTableHeader(columns: invoiceColumns(strings)),
          Expanded(
            child: ListView.builder(
              itemCount: itemCount,
              itemBuilder: (BuildContext context, int index) {
                if (index >= items.length) {
                  return LoadMoreFooter(
                    label: strings.actionLoadMore,
                    onPressed: onLoadMore,
                  );
                }
                return InvoiceTableRow(
                  item: items[index],
                  strings: strings,
                  now: now,
                );
              },
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) {
        if (index >= items.length) {
          return LoadMoreFooter(
            label: strings.actionLoadMore,
            onPressed: onLoadMore,
          );
        }
        return InvoiceCard(item: items[index], strings: strings, now: now);
      },
    );
  }
}

/// The five columns the desktop breakpoint was sized around (§10).
///
/// The amount column is **not** `alignEnd`, and is fixed-width rather than
/// flexed. Both follow from one fact: numbers render left-to-right whatever the
/// surrounding direction, so their units digit sits at their right edge.
/// Pushing them to the trailing edge of an RTL row lines up their *first*
/// digits instead and leaves the units ragged — undoing exactly what the
/// tabular figures in [AppTypography] exist to provide (D-037).
///
/// [includeCustomer] is false on a customer's own page, where the name would be
/// the same on every row — see the note on [InvoiceCard.showCustomer].
List<TableColumnSpec> invoiceColumns(
  AppStrings strings, {
  bool includeCustomer = true,
}) => <TableColumnSpec>[
  TableColumnSpec(label: strings.tableColumnNumber, flex: 2),
  if (includeCustomer)
    TableColumnSpec(label: strings.tableColumnCustomer, flex: 3),
  TableColumnSpec(
    label: strings.tableColumnDate,
    width: AppLayout.tableDateWidth,
  ),
  TableColumnSpec(
    label: strings.tableColumnStatus,
    width: AppLayout.tableStatusWidth,
  ),
  TableColumnSpec(
    label: strings.tableColumnAmount,
    width: AppLayout.tablePriceWidth,
  ),
];

/// An invoice as a table row: desktop, and the dashboard's recent list on a
/// wide window.
class InvoiceTableRow extends StatelessWidget {
  const InvoiceTableRow({
    required this.item,
    required this.strings,
    required this.now,
    this.showCustomer = true,
    super.key,
  });

  final InvoiceListItem item;
  final AppStrings strings;

  /// Read from the clock provider by the screen, not by this widget, so every
  /// row on the page ages against the same instant.
  final DateTime now;

  /// See [InvoiceCard.showCustomer].
  final bool showCustomer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final InvoiceStatusView view = invoiceStatusViewOf(item.invoice, now: now);
    final TextStyle muted = AppTypography.identifier.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFamily: AppTypography.fontFamily,
    );

    return AppTableRow(
      columns: invoiceColumns(strings, includeCustomer: showCustomer),
      onTap: () => context.go(AppRoutes.invoiceDetailFor(item.invoice.id)),
      cells: <Widget>[
        Text(
          // The number, or the Persian copy for a draft that has none yet.
          // `invoiceNumberLabel` owns both the wording and the bidi isolation
          // (D-048).
          invoiceNumberLabel(item.invoice, strings),
          overflow: TextOverflow.ellipsis,
          style: muted,
        ),
        if (showCustomer)
          Text(
            item.customerName,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge,
          ),
        Text(
          formatJalaliDate(item.invoice.issueDate),
          overflow: TextOverflow.ellipsis,
          style: muted,
        ),
        StatusBadge(status: view, label: invoiceStatusLabel(view, strings)),
        AmountText(
          item.invoice.grandTotal,
          unitLabel: strings.unitToman,
          size: AmountSize.small,
        ),
      ],
    );
  }
}

/// An invoice as a card: mobile and tablet.
///
/// The amount carries the emphasis, because it is what the user opened the list
/// to see (§10). It is **not** coloured — colour means status in this design
/// (D-033), and the badge is where the status is said.
class InvoiceCard extends StatelessWidget {
  const InvoiceCard({
    required this.item,
    required this.strings,
    required this.now,
    this.showCustomer = true,
    super.key,
  });

  final InvoiceListItem item;
  final AppStrings strings;
  final DateTime now;

  /// Whether the customer's name is the card's heading.
  ///
  /// False on that customer's own page, where it would be the same name on
  /// every row — twenty repetitions of something the reader already knows,
  /// pushing the invoice number, which is what actually identifies the row,
  /// into second place. §10 removes what does not aid comprehension.
  ///
  /// The card is otherwise unchanged: same shape, same order, same emphasis, so
  /// an invoice still looks like an invoice wherever it is seen. The heading
  /// slot takes the number instead, and the run beneath it keeps the date.
  final bool showCustomer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final InvoiceStatusView view = invoiceStatusViewOf(item.invoice, now: now);
    final TextStyle muted = AppTypography.identifier.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFamily: AppTypography.fontFamily,
    );

    return AppCard(
      onTap: () => context.go(AppRoutes.invoiceDetailFor(item.invoice.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: showCustomer
                    ? Text(
                        item.customerName,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      )
                    : Text(
                        invoiceNumberLabel(item.invoice, strings),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
              ),
              StatusBadge(
                status: view,
                label: invoiceStatusLabel(view, strings),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // A `Wrap`, not a `Row`. The number and the date are both fixed-width
          // runs that must not be truncated -- an ellipsised invoice number is
          // not an invoice number -- and on a 360-pixel phone the pair does not
          // always fit on one line. A Row overflows there, which a widget test
          // catches but a screenshot at one width does not; wrapping onto a
          // second line costs eighteen pixels of height and cannot fail.
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xxs,
            children: <Widget>[
              if (showCustomer)
                Text(invoiceNumberLabel(item.invoice, strings), style: muted),
              Text(formatJalaliDate(item.invoice.issueDate), style: muted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AmountText(item.invoice.grandTotal, unitLabel: strings.unitToman),
        ],
      ),
    );
  }
}

/// A placeholder shaped like the row it stands in for, so the layout does not
/// jump when the data lands.
class _InvoiceSkeletonRow extends StatelessWidget {
  const _InvoiceSkeletonRow({required this.tier});

  final LayoutTier tier;

  @override
  Widget build(BuildContext context) {
    if (tier.usesTables) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: const <Widget>[
            Expanded(flex: 2, child: Skeleton(height: AppSkeleton.lineHeight)),
            SizedBox(width: AppSpacing.md),
            Expanded(flex: 3, child: Skeleton(height: AppSkeleton.lineHeight)),
            SizedBox(width: AppSpacing.md),
            SizedBox(
              width: AppLayout.tableDateWidth,
              child: Skeleton(height: AppSkeleton.lineHeight),
            ),
            SizedBox(width: AppSpacing.md),
            SizedBox(
              width: AppLayout.tableStatusWidth,
              child: Skeleton(height: AppSkeleton.lineHeight),
            ),
            SizedBox(width: AppSpacing.md),
            SizedBox(
              width: AppLayout.tablePriceWidth,
              child: Skeleton(height: AppSkeleton.lineHeight),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Skeleton(
            width: AppSkeleton.titleWidth,
            height: AppSkeleton.lineHeight,
          ),
          SizedBox(height: AppSpacing.sm),
          Skeleton(
            width: AppSkeleton.captionWidth,
            height: AppSkeleton.lineHeight,
          ),
          SizedBox(height: AppSpacing.md),
          Skeleton(
            width: AppSkeleton.captionWidth,
            height: AppSkeleton.lineHeight,
          ),
        ],
      ),
    );
  }
}
