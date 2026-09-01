import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/date/jalali_period.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/editor_sheet.dart';
import '../../../../data/models/customer.dart';
import '../../../../data/models/invoice_filter.dart';
import '../../../../data/models/invoice_status.dart';
import '../../application/invoices_providers.dart';
import '../../domain/invoice_status_view.dart';
import 'customer_picker_sheet.dart';

/// Narrows the invoice list: status, customer, Jalali period.
///
/// **The sheet edits nothing and computes nothing.** It builds an
/// [InvoiceFilter] and hands it to `InvoiceListQuery`, which passes it to the
/// repository, which turns it into `WHERE` clauses. No widget on this path ever
/// filters a list in Dart — that would apply the page limit before the
/// predicate and report "no results" for data sitting behind the first page
/// (§13, and the repository test that pins it).
///
/// **Applied live, dismissed by a button.** Each tap updates the list behind
/// the sheet immediately, so the user sees what the filter does while choosing
/// it rather than after committing. «نمایش نتایج» therefore only closes the
/// sheet — which is why it says that rather than «اعمال», a word that would
/// imply nothing had happened yet.
///
/// **The period options are Jalali** (§5, D-006). «این ماه» is the current
/// *Jalali* month resolved through `jalaliMonthOf` against the one clock
/// instant the app reads (D-041); a Gregorian boundary here would be a bug, and
/// the type makes it impossible to express — [InvoiceFilter.period] is an
/// `InstantRange`, and only `core/date/` builds one.
///
/// **The customer is chosen through the picker the invoice form already uses.**
/// A second list of customers would be a second place for the search
/// normalization (D-029) and the soft-delete rule to be got wrong.
Future<void> showInvoiceFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => const _InvoiceFilterSheet(),
  );
}

class _InvoiceFilterSheet extends ConsumerStatefulWidget {
  const _InvoiceFilterSheet();

  @override
  ConsumerState<_InvoiceFilterSheet> createState() =>
      _InvoiceFilterSheetState();
}

class _InvoiceFilterSheetState extends ConsumerState<_InvoiceFilterSheet> {
  /// The chosen customer's **name**, held only so the sheet can show it.
  ///
  /// The filter itself carries the id (a name is not unique and is not what the
  /// foreign key holds). Keeping the name here rather than resolving it from
  /// the id on every build avoids a read issued from a widget for something the
  /// picker already handed over.
  String? _customerName;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final InvoiceFilter filter = ref.watch(
      invoiceListQueryProvider.select((query) => query.filter),
    );
    final DateTime now = ref.watch(nowProvider);

    void apply(InvoiceFilter value) =>
        ref.read(invoiceListQueryProvider.notifier).filter(value);

    return EditorSheet(
      title: strings.invoiceFilterTitle,
      closeTooltip: strings.actionCancel,
      action: FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(strings.invoiceFilterApply),
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                strings.invoiceFilterStatusSection,
                style: theme.textTheme.labelLarge,
              ),
            ),
            // Only where there is something to clear. A control that is always
            // there but usually inert is one the user stops reading.
            if (filter.isActive)
              TextButton(
                onPressed: () {
                  setState(() => _customerName = null);
                  ref.read(invoiceListQueryProvider.notifier).clearFilter();
                },
                child: Text(strings.invoiceFilterClearAll),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // A `Wrap` of chips rather than a `SegmentedButton`, on the payment
        // method's precedent: five Persian labels of unequal length do not fit
        // across a phone in one row, and wrapping costs a line and cannot clip.
        //
        // **The five stored statuses only.** «سررسید گذشته» is derived at
        // display time from the due date (D-041) and is deliberately not a
        // filter: a SQL predicate for it would be a second implementation of a
        // rule `invoiceStatusViewOf` owns, and an overdue invoice is reachable
        // under «پرداخت نشده» or «پرداخت جزئی» regardless.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final InvoiceStatus status in InvoiceStatus.values)
              FilterChip(
                label: Text(
                  invoiceStatusLabel(
                    invoiceStatusViewOfStored(status),
                    strings,
                  ),
                ),
                selected: filter.statuses.contains(status),
                onSelected: (bool selected) {
                  final Set<InvoiceStatus> next = <InvoiceStatus>{
                    ...filter.statuses,
                  };
                  if (selected) {
                    next.add(status);
                  } else {
                    next.remove(status);
                  }
                  apply(filter.withStatuses(next));
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        Text(
          strings.invoiceFilterCustomerSection,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              ChoiceChip(
                label: Text(strings.invoiceFilterCustomerAny),
                selected: filter.customerId == null,
                onSelected: (bool selected) {
                  if (!selected) return;
                  setState(() => _customerName = null);
                  apply(filter.withCustomer(null));
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.person_search, size: AppIconSize.sm),
                label: Text(
                  _customerName ?? strings.invoiceFilterCustomerChoose,
                ),
                onPressed: () async {
                  final Customer? picked = await showCustomerPickerSheet(
                    context,
                  );
                  if (picked == null || !context.mounted) return;
                  setState(() => _customerName = picked.fullName);
                  apply(filter.withCustomer(picked.id));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        Text(
          strings.invoiceFilterPeriodSection,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final (String label, InstantRange? range) in _periodOptions(
              strings,
              now,
            ))
              ChoiceChip(
                label: Text(label),
                selected: filter.period == range,
                onSelected: (bool selected) {
                  if (!selected) return;
                  apply(filter.withPeriod(range));
                },
              ),
          ],
        ),
      ],
    );
  }

  /// The presets, resolved through `core/date/` against one instant.
  ///
  /// Presets rather than a date-range picker, deliberately: «این ماه» and
  /// «ماه گذشته» are what a user actually asks a billing application, and a
  /// pair of Jalali calendars to fill in is four taps to express the same
  /// question. A custom range is a later phase's problem, not a gap here.
  List<(String, InstantRange?)> _periodOptions(
    AppStrings strings,
    DateTime now,
  ) {
    // **No calendar arithmetic here.** «ماه گذشته» is `jalaliMonthShifted(-1)`,
    // which shifts the Jalali *month number* and lets `core/date/` resolve the
    // boundaries -- Jalali months are 31, 30 or 29 days depending on where in
    // the year they fall, so subtracting a fixed span is wrong in a way that
    // only surfaces some months (§5, D-006).
    return <(String, InstantRange?)>[
      (strings.invoiceFilterPeriodAny, null),
      (strings.invoiceFilterPeriodThisMonth, jalaliMonthOf(now)),
      (strings.invoiceFilterPeriodLastMonth, jalaliMonthShifted(now, -1)),
      (strings.invoiceFilterPeriodThisYear, jalaliYearOf(now)),
    ];
  }
}
