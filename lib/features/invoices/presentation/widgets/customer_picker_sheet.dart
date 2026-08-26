import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/jalali_display.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/load_more_footer.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../data/models/customer.dart';
import '../../application/invoice_customer_picker.dart';

/// Chooses the customer an invoice is for.
///
/// Returns the chosen [Customer], or null if dismissed.
///
/// **The search behind it is the repository's**, which is the normalization
/// -insensitive one (D-025, D-029): «علي» is found by typing «علی». Filtering a
/// loaded list here would be a second normalizer, and D-029 exists because two
/// normalizers diverge silently — the query stops matching rows the writer
/// folded differently, and nothing raises.
///
/// **No "create a customer" action, unlike the product picker's free-text
/// line.** `invoices.customer_id` is a non-null foreign key: an invoice
/// genuinely cannot proceed without a customer record, so the empty state says
/// where to make one rather than offering a route that would lose the
/// half-typed invoice.
Future<Customer?> showCustomerPickerSheet(BuildContext context) {
  return showModalBottomSheet<Customer>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => const _CustomerPickerSheet(),
  );
}

class _CustomerPickerSheet extends ConsumerWidget {
  const _CustomerPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<Customer>> customers = ref.watch(
      invoiceCustomerPickerListProvider,
    );

    return FractionallySizedBox(
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
                      strings.invoiceCustomerPickerTitle,
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
                hintText: strings.invoiceCustomerPickerSearchHint,
                onChanged: (String term) => ref
                    .read(invoiceCustomerPickerQueryProvider.notifier)
                    .search(term),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: customers.when(
                loading: () => SkeletonList(
                  rowBuilder: (BuildContext context) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Skeleton(height: AppSpacing.xl),
                  ),
                ),
                error: (Object error, StackTrace stack) => AsyncErrorView(
                  error: error,
                  stackTrace: stack,
                  scope: 'invoice-customer-picker',
                ),
                data: (List<Customer> items) =>
                    _Results(strings: strings, customers: items),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.strings, required this.customers});

  final AppStrings strings;
  final List<Customer> customers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (customers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: strings.invoiceCustomerPickerEmptyTitle,
        body: strings.invoiceCustomerPickerEmptyBody,
      );
    }

    final bool hasMore = ref
        .watch(invoiceCustomerPickerQueryProvider)
        .hasMoreAfter(customers.length);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: customers.length + (hasMore ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index == customers.length) {
          return LoadMoreFooter(
            label: strings.actionLoadMore,
            onPressed: () => ref
                .read(invoiceCustomerPickerQueryProvider.notifier)
                .loadMore(),
          );
        }

        final Customer customer = customers[index];
        final String? mobile = customer.mobile;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(customer.fullName),
          // Company where there is one, mobile otherwise: two people with the
          // same name is the ordinary case a picker has to disambiguate, and
          // either of these does it. The mobile is bidi-isolated, because a
          // bare `09...` inside RTL text visually scrambles (§9).
          subtitle: customer.companyName != null
              ? Text(customer.companyName!)
              : mobile != null
              ? Text(formatMobileForDisplay(mobile))
              : null,
          onTap: () => Navigator.of(context).pop(customer),
        );
      },
    );
  }
}
