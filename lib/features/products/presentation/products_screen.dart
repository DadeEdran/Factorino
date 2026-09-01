import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_strings.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/router/destinations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/list_query.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_table.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/load_more_footer.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_type.dart';
import '../application/products_providers.dart';

/// The product and service catalogue.
///
/// Structurally the customer list's twin — same skeleton, same two empty
/// states, same query-level paging — with one difference that matters: **these
/// rows carry money**, so the price goes through `AmountText` and arrives with
/// its unit label attached (§9). A bare number on a price list is ambiguous by
/// a factor of ten in a country that quotes in Toman and stores in Rial.
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final LayoutTier tier = context.tier;
    final ListQuery query = ref.watch(productListQueryProvider);
    final AsyncValue<List<Product>> products = ref.watch(productListProvider);

    return PageBody(
      title: strings.productsTitle,
      actions: <Widget>[
        if (!tier.isMobile)
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.productCreate),
            icon: const Icon(Icons.add, size: AppIconSize.md),
            label: Text(strings.productAdd),
          ),
      ],
      floatingAction: tier.isMobile
          ? FloatingActionButton.extended(
              onPressed: () => context.go(AppRoutes.productCreate),
              icon: const Icon(Icons.add),
              label: Text(strings.productAdd),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SearchField(
            hintText: strings.productsSearchHint,
            clearTooltip: strings.actionClear,
            onChanged: (String term) =>
                ref.read(productListQueryProvider.notifier).search(term),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: products.when(
              loading: () => SkeletonList(
                rowBuilder: (BuildContext context) =>
                    _ProductSkeletonRow(tier: tier),
              ),
              error: (Object error, StackTrace stack) => AsyncErrorView(
                error: error,
                stackTrace: stack,
                scope: 'products',
                onRetry: () => ref.invalidate(productListProvider),
              ),
              data: (List<Product> items) => _ProductList(
                products: items,
                query: query,
                tier: tier,
                strings: strings,
                onLoadMore: () =>
                    ref.read(productListQueryProvider.notifier).loadMore(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({
    required this.products,
    required this.query,
    required this.tier,
    required this.strings,
    required this.onLoadMore,
  });

  final List<Product> products;
  final ListQuery query;
  final LayoutTier tier;
  final AppStrings strings;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return query.isSearching
          ? EmptyState(
              icon: Icons.search_off,
              title: strings.searchNoResultsTitle,
              body: strings.searchNoResultsBody,
            )
          : EmptyState(
              icon: Icons.inventory_2_outlined,
              title: strings.emptyProductsTitle,
              body: strings.emptyProductsBody,
              action: FilledButton.icon(
                onPressed: () => context.go(AppRoutes.productCreate),
                icon: const Icon(Icons.add, size: AppIconSize.md),
                label: Text(strings.productAdd),
              ),
            );
    }

    final bool hasMore = query.hasMoreAfter(products.length);
    final int itemCount = products.length + (hasMore ? 1 : 0);

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
                if (index >= products.length) {
                  return LoadMoreFooter(
                    label: strings.actionLoadMore,
                    onPressed: onLoadMore,
                  );
                }
                return _ProductTableRow(
                  product: products[index],
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
        if (index >= products.length) {
          return LoadMoreFooter(
            label: strings.actionLoadMore,
            onPressed: onLoadMore,
          );
        }
        return _ProductCard(product: products[index], strings: strings);
      },
    );
  }
}

List<TableColumnSpec> _columns(AppStrings strings) => <TableColumnSpec>[
  TableColumnSpec.flexible(
    label: strings.tableColumnName,
    flex: 4,
    minWidth: AppLayout.tableMinTextWidth,
  ),
  TableColumnSpec.fixed(
    label: strings.tableColumnType,
    width: AppLayout.tableTypeWidth,
  ),
  TableColumnSpec.fixed(
    label: strings.tableColumnUnit,
    width: AppLayout.tableUnitWidth,
  ),
  // **Not** `alignEnd`. In RTL, `end` is the left edge, and an amount pushed
  // there lines its figures up by their *first* digit -- so ۳۸٬۰۰۰ and
  // ۴٬۵۰۰٬۰۰۰ start together and end in different places, which is exactly the
  // ragged column tabular numerals (D-033) exist to prevent. Leading
  // alignment in RTL puts the digits' right edge -- the units digit -- on a
  // common line, and that is what makes a column of money scannable.
  // Caught by looking at the running build, not by any test.
  TableColumnSpec.fixed(
    label: strings.tableColumnPrice,
    width: AppLayout.tablePriceWidth,
  ),
];

String _typeLabel(ProductType type, AppStrings strings) => switch (type) {
  ProductType.product => strings.productTypeProduct,
  ProductType.service => strings.productTypeService,
};

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.strings});

  final Product product;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      onTap: () => context.go(AppRoutes.productEditFor(product.id)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(product.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${_typeLabel(product.type, strings)} · ${product.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // The most salient element on the card (§10). Prominence comes
                // from the type scale, not from colour -- colour is reserved
                // for status, and a product has none (D-033).
                AmountText(
                  product.price,
                  unitLabel: strings.unitToman,
                  size: AmountSize.medium,
                ),
              ],
            ),
          ),
          _ProductActions(product: product, strings: strings),
        ],
      ),
    );
  }
}

class _ProductTableRow extends StatelessWidget {
  const _ProductTableRow({required this.product, required this.strings});

  final Product product;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return AppTableRow(
      columns: _columns(strings),
      onTap: () => context.go(AppRoutes.productEditFor(product.id)),
      trailingWidth: AppLayout.tableActionsWidth,
      trailing: _ProductActions(product: product, strings: strings),
      cells: <Widget>[
        Text(
          product.name,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge,
        ),
        Text(_typeLabel(product.type, strings), style: muted),
        Text(product.unit, overflow: TextOverflow.ellipsis, style: muted),
        AmountText(
          product.price,
          unitLabel: strings.unitToman,
          size: AmountSize.small,
        ),
      ],
    );
  }
}

class _ProductActions extends ConsumerWidget {
  const _ProductActions({required this.product, required this.strings});

  final Product product;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_RowAction>(
      tooltip: strings.actionMore,
      icon: const Icon(Icons.more_vert, size: AppIconSize.md),
      onSelected: (_RowAction action) => switch (action) {
        _RowAction.edit => context.go(AppRoutes.productEditFor(product.id)),
        _RowAction.delete => _confirmDelete(context, ref),
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(strings.productDeleteTitle),
            // The copy states the snapshot rule (D-004) in the one place the
            // user has a reason to doubt it: deleting a product cannot change
            // an invoice, because the invoice kept its own copy of the title,
            // unit and price at the moment it was issued.
            content: Text(strings.productDeleteBody),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.actionDelete),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !context.mounted) return;

    final bool deleted = await ref
        .read(productEditorProvider.notifier)
        .delete(product.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted ? strings.productDeleted : strings.errorGenericBody,
        ),
      ),
    );
  }
}

enum _RowAction { edit, delete }

class _ProductSkeletonRow extends StatelessWidget {
  const _ProductSkeletonRow({required this.tier});

  final LayoutTier tier;

  @override
  Widget build(BuildContext context) {
    if (tier.usesTables) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: const <Widget>[
            Expanded(flex: 4, child: Skeleton(height: AppSkeleton.lineHeight)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Skeleton(height: AppSkeleton.lineHeight)),
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
