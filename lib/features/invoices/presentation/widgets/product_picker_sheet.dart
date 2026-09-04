import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/load_more_footer.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../data/models/product.dart';
import '../../application/invoice_product_picker.dart';

/// Chooses a catalogue entry for an invoice line.
///
/// Returns the chosen [Product], or null if the sheet was dismissed. **It
/// returns the product and nothing else** — building the line from it is the
/// caller's job, in one place, so there is exactly one site that performs the
/// copy D-004 requires. A picker that returned a half-built line would be a
/// second such site, and the two would eventually disagree about what a
/// snapshot contains.
///
/// The list is the same live, paginated query the products screen uses, over
/// its own window (see `InvoiceProductPickerQuery`).
Future<Product?> showProductPickerSheet(BuildContext context) {
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => const _ProductPickerSheet(),
  );
}

class _ProductPickerSheet extends ConsumerWidget {
  const _ProductPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<Product>> products = ref.watch(
      invoiceProductPickerListProvider,
    );

    return FractionallySizedBox(
      // Tall enough to show a useful number of rows without covering the form
      // completely: the user is choosing a line for an invoice they can still
      // see the top of, which is what keeps the sheet feeling like a step in
      // the task rather than a different screen.
      heightFactor: 0.85,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      strings.invoiceProductPickerTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: strings.actionCancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SearchField(
                hintText: strings.invoiceProductPickerSearchHint,
                onChanged: (String term) => ref
                    .read(invoiceProductPickerQueryProvider.notifier)
                    .search(term),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: products.when(
                loading: () => SkeletonList(
                  rowBuilder: (BuildContext context) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Skeleton(height: AppSpacing.xl),
                  ),
                ),
                error: (Object error, StackTrace stack) => AsyncErrorView(
                  error: error,
                  stackTrace: stack,
                  scope: 'invoice-product-picker',
                ),
                data: (List<Product> items) =>
                    _Results(strings: strings, products: items),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.strings, required this.products});

  final AppStrings strings;
  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (products.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: strings.invoiceProductPickerEmptyTitle,
        // No "create a product" action. Leaving a half-typed invoice to go and
        // create a catalogue entry loses the invoice; the free-text line is
        // the route that keeps the user where they are (D-021's reasoning).
        body: strings.invoiceProductPickerEmptyBody,
      );
    }

    final bool hasMore = ref
        .watch(invoiceProductPickerQueryProvider)
        .hasMoreAfter(products.length);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: products.length + (hasMore ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index == products.length) {
          return LoadMoreFooter(
            label: strings.actionLoadMore,
            onPressed: () =>
                ref.read(invoiceProductPickerQueryProvider.notifier).loadMore(),
          );
        }

        final Product product = products[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(product.name),
          subtitle: Text(product.unit),
          // The catalogue price, as it stands right now. Choosing this row
          // copies it (D-004); it is not a live reference from that moment on,
          // which is why the invoice keeps its own figure.
          trailing: AmountText(product.price, size: AmountSize.small),
          onTap: () => Navigator.of(context).pop(product),
        );
      },
    );
  }
}
