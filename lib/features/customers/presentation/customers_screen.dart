import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/jalali_display.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/router/destinations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/list_query.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_table.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/load_more_footer.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/models/customer.dart';
import '../application/customers_providers.dart';
import 'customer_delete_dialog.dart';

/// The customer list.
///
/// **Real data throughout** (§15): every row here is a row in the encrypted
/// database, reached through `CustomerRepository`. There is no seeded sample
/// and no placeholder — an empty list means the user has no customers.
///
/// Three tiers, two layouts (§10). Mobile and tablet get **cards**, because a
/// table squeezed to a phone's width truncates the one field the user is
/// looking for. Desktop gets a **real table**, built from
/// `AppTableHeader`/`AppTableRow` over a `ListView.builder` so it stays
/// virtualized — see the note in `app_table.dart` about why it is not
/// `DataTable`.
class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final LayoutTier tier = context.tier;
    final ListQuery query = ref.watch(customerListQueryProvider);
    final AsyncValue<List<Customer>> customers = ref.watch(
      customerListProvider,
    );

    return PageBody(
      title: strings.customersTitle,
      actions: <Widget>[
        if (!tier.isMobile)
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.customerCreate),
            icon: const Icon(Icons.add, size: AppIconSize.md),
            label: Text(strings.customerAdd),
          ),
      ],
      floatingAction: tier.isMobile
          ? FloatingActionButton.extended(
              onPressed: () => context.go(AppRoutes.customerCreate),
              icon: const Icon(Icons.add),
              label: Text(strings.customerAdd),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SearchField(
            hintText: strings.customersSearchHint,
            clearTooltip: strings.actionClear,
            onChanged: (String term) =>
                ref.read(customerListQueryProvider.notifier).search(term),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: customers.when(
              // A skeleton shaped like the rows that are coming, not a spinner
              // in the middle of an empty page (§10).
              loading: () => SkeletonList(
                rowBuilder: (BuildContext context) =>
                    _CustomerSkeletonRow(tier: tier),
              ),
              error: (Object error, StackTrace stack) => AsyncErrorView(
                error: error,
                stackTrace: stack,
                scope: 'customers',
                onRetry: () => ref.invalidate(customerListProvider),
              ),
              data: (List<Customer> items) => _CustomerList(
                customers: items,
                query: query,
                tier: tier,
                strings: strings,
                onLoadMore: () =>
                    ref.read(customerListQueryProvider.notifier).loadMore(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerList extends StatelessWidget {
  const _CustomerList({
    required this.customers,
    required this.query,
    required this.tier,
    required this.strings,
    required this.onLoadMore,
  });

  final List<Customer> customers;
  final ListQuery query;
  final LayoutTier tier;
  final AppStrings strings;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      // Two different empty states, because they mean different things. "You
      // have no customers" invites the user to add one; "nothing matched
      // 'خسرو'" would be actively wrong there, and offering a create button
      // in response to a failed search is worse still.
      return query.isSearching
          ? EmptyState(
              icon: Icons.search_off,
              title: strings.searchNoResultsTitle,
              body: strings.searchNoResultsBody,
            )
          : EmptyState(
              icon: Icons.people_outline,
              title: strings.emptyCustomersTitle,
              body: strings.emptyCustomersBody,
              action: FilledButton.icon(
                onPressed: () => context.go(AppRoutes.customerCreate),
                icon: const Icon(Icons.add, size: AppIconSize.md),
                label: Text(strings.customerAdd),
              ),
            );
    }

    final bool hasMore = query.hasMoreAfter(customers.length);
    // One extra item for the load-more footer, so it scrolls with the list
    // rather than pinning to the bottom of the screen.
    final int itemCount = customers.length + (hasMore ? 1 : 0);

    if (tier.usesTables) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTableHeader(
            columns: _columns(strings),
            trailingWidth: AppLayout.tableActionsWidth,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: itemCount,
              itemBuilder: (BuildContext context, int index) {
                if (index >= customers.length) {
                  return LoadMoreFooter(
                    label: strings.actionLoadMore,
                    onPressed: onLoadMore,
                  );
                }
                return _CustomerTableRow(
                  customer: customers[index],
                  strings: strings,
                );
              },
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      // Clearance for the floating action button, which would otherwise cover
      // the last row -- and the last row is exactly the one a user scrolls all
      // the way down to reach.
      padding: tier.isMobile
          ? const EdgeInsets.only(bottom: AppLayout.floatingActionClearance)
          : EdgeInsets.zero,
      itemCount: itemCount,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) {
        if (index >= customers.length) {
          return LoadMoreFooter(
            label: strings.actionLoadMore,
            onPressed: onLoadMore,
          );
        }
        return _CustomerCard(customer: customers[index], strings: strings);
      },
    );
  }
}

List<TableColumnSpec> _columns(AppStrings strings) => <TableColumnSpec>[
  TableColumnSpec(label: strings.tableColumnName, flex: 3),
  TableColumnSpec(label: strings.tableColumnCompany, flex: 2),
  TableColumnSpec(label: strings.tableColumnMobile, flex: 2),
];

/// A customer as a card: mobile and tablet.
///
/// The name is the anchor and carries the emphasis; the company and the number
/// sit under it in the muted caption style. There is no colour here at all —
/// colour means status in this design (D-033), and a customer has no status.
class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.strings});

  final Customer customer;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      // The record, not the form. Tapping a row asks "who is this and what is
      // my history with them"; editing is a deliberate act and stays behind
      // the row's menu.
      onTap: () => context.go(AppRoutes.customerDetailFor(customer.id)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(customer.fullName, style: theme.textTheme.titleSmall),
                if (customer.companyName != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    customer.companyName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  customer.mobile == null
                      ? strings.customerNoMobile
                      : formatMobileForDisplay(customer.mobile!),
                  style: AppTypography.identifier.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          _CustomerActions(customer: customer, strings: strings),
        ],
      ),
    );
  }
}

/// A customer as a table row: desktop.
class _CustomerTableRow extends StatelessWidget {
  const _CustomerTableRow({required this.customer, required this.strings});

  final Customer customer;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return AppTableRow(
      columns: _columns(strings),
      onTap: () => context.go(AppRoutes.customerDetailFor(customer.id)),
      trailingWidth: AppLayout.tableActionsWidth,
      trailing: _CustomerActions(customer: customer, strings: strings),
      cells: <Widget>[
        Text(
          customer.fullName,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge,
        ),
        Text(
          customer.companyName ?? '',
          overflow: TextOverflow.ellipsis,
          style: muted,
        ),
        Text(
          customer.mobile == null
              ? strings.customerNoMobile
              : formatMobileForDisplay(customer.mobile!),
          overflow: TextOverflow.ellipsis,
          style: AppTypography.identifier.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFamily: AppTypography.fontFamily,
          ),
        ),
      ],
    );
  }
}

/// Edit and delete, in a menu rather than as two always-visible buttons.
///
/// Delete is destructive and sits behind one more tap on purpose; it is also
/// the row's least common action, and two icons per row on a list of thousands
/// is visual noise that competes with the names.
class _CustomerActions extends ConsumerWidget {
  const _CustomerActions({required this.customer, required this.strings});

  final Customer customer;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_RowAction>(
      tooltip: strings.actionMore,
      icon: const Icon(Icons.more_vert, size: AppIconSize.md),
      onSelected: (_RowAction action) => switch (action) {
        _RowAction.edit => context.go(AppRoutes.customerEditFor(customer.id)),
        _RowAction.delete => confirmAndDeleteCustomer(
          context,
          ref,
          customer.id,
        ),
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_RowAction>>[
        PopupMenuItem<_RowAction>(
          value: _RowAction.edit,
          child: Text(strings.actionEdit),
        ),
        PopupMenuItem<_RowAction>(
          value: _RowAction.delete,
          child: Text(strings.actionDelete),
        ),
      ],
    );
  }
}

enum _RowAction { edit, delete }

/// A placeholder shaped like the row it stands in for, so the layout does not
/// jump when the data lands.
class _CustomerSkeletonRow extends StatelessWidget {
  const _CustomerSkeletonRow({required this.tier});

  final LayoutTier tier;

  @override
  Widget build(BuildContext context) {
    if (tier.usesTables) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: const <Widget>[
            Expanded(flex: 3, child: Skeleton(height: AppSkeleton.lineHeight)),
            SizedBox(width: AppSpacing.md),
            Expanded(flex: 2, child: Skeleton(height: AppSkeleton.lineHeight)),
            SizedBox(width: AppSpacing.md),
            Expanded(flex: 2, child: Skeleton(height: AppSkeleton.lineHeight)),
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
        ],
      ),
    );
  }
}
