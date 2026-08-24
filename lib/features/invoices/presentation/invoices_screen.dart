import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/jalali_display.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/list_query.dart';
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
import '../domain/invoice_status_view.dart';

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
/// **Rows are not tappable, and there is no create button.** Neither the
/// invoice detail screen nor the invoice form exists yet — they are Phases 5
/// and 4 — and `/invoices/:id` stays unregistered until the screen it opens
/// exists (D-021, one level down). An affordance leading nowhere is worse than
/// its absence.
class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final LayoutTier tier = context.tier;
    final ListQuery query = ref.watch(invoiceListQueryProvider);
    final AsyncValue<List<InvoiceListItem>> invoices = ref.watch(
      invoiceListProvider,
    );

    return PageBody(
      title: strings.invoicesTitle,
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
        // One empty state rather than two: this list has no search yet, so
        // "nothing matched" is not a state it can be in.
        data: (List<InvoiceListItem> items) => items.isEmpty
            ? EmptyState(
                icon: Icons.receipt_long_outlined,
                title: strings.emptyInvoicesTitle,
                body: strings.emptyInvoicesBody,
              )
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
  final ListQuery query;
  final LayoutTier tier;
  final AppStrings strings;
  final DateTime now;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final bool hasMore = query.hasMoreAfter(items.length);
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
List<TableColumnSpec> invoiceColumns(AppStrings strings) => <TableColumnSpec>[
  TableColumnSpec(label: strings.tableColumnNumber, flex: 2),
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
    super.key,
  });

  final InvoiceListItem item;
  final AppStrings strings;

  /// Read from the clock provider by the screen, not by this widget, so every
  /// row on the page ages against the same instant.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final InvoiceStatusView view = invoiceStatusViewOf(item.invoice, now: now);
    final TextStyle muted = AppTypography.identifier.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFamily: AppTypography.fontFamily,
    );

    return AppTableRow(
      columns: invoiceColumns(strings),
      cells: <Widget>[
        Text(
          // Bidi-isolated: `INV-1405-0001` mixes a Latin prefix with digits and
          // hyphens, and without the isolate that run resolves against whatever
          // happens to sit beside it (§9).
          isolate(item.invoice.number),
          overflow: TextOverflow.ellipsis,
          style: muted,
        ),
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
    super.key,
  });

  final InvoiceListItem item;
  final AppStrings strings;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final InvoiceStatusView view = invoiceStatusViewOf(item.invoice, now: now);
    final TextStyle muted = AppTypography.identifier.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFamily: AppTypography.fontFamily,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.customerName,
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
              Text(isolate(item.invoice.number), style: muted),
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
