import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/date/jalali_instant.dart';
import '../../../../core/date/jalali_period.dart';
import '../../../../core/formatting/jalali_display.dart';
import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/editor_sheet.dart';
import '../../../../core/widgets/jalali_date_picker.dart';
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

    final List<(String, InstantRange?)> presets = _periodOptions(strings, now);

    // **A period that is none of the presets is a custom one**, derived rather
    // than stored: the filter carries an `InstantRange` and nothing else, and a
    // second flag saying which control produced it would be a fact about the
    // UI kept in the query — the two would disagree the first time a preset
    // range happened to equal a hand-picked one, which for «این ماه» picked day
    // by day is not hypothetical.
    final bool isCustom =
        filter.period != null &&
        !presets.any(
          ((String, InstantRange?) option) => option.$2 == filter.period,
        );

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
            for (final (String label, InstantRange? range) in presets)
              ChoiceChip(
                label: Text(label),
                selected: filter.period == range,
                onSelected: (bool selected) {
                  if (!selected) return;
                  apply(filter.withPeriod(range));
                },
              ),
            // **The custom range, beside the presets rather than instead of
            // them** (D-111). The presets answer what a billing application is
            // usually asked and stay one tap; this answers the rest, and the
            // owner asked for it after the presets had shipped, which is the
            // evidence the header's «a later phase's problem» was waiting for.
            //
            // It is a `ChoiceChip` like its neighbours so the five options read
            // as one set of mutually exclusive answers to «بازهٔ زمانی» — a
            // separate control below them would suggest a range could be
            // combined with «این ماه», which the filter cannot express.
            ChoiceChip(
              avatar: const Icon(Icons.event_outlined, size: AppIconSize.sm),
              // Once chosen the chip **states the range** rather than repeating
              // the invitation, so a user returning to the sheet can read what
              // the list is showing without opening two calendars to find out.
              label: Text(
                isCustom
                    ? strings.invoiceFilterPeriodCustomRange(
                        formatJalaliDate(filter.period!.start),
                        // The stored end is **exclusive** (`InstantRange` is
                        // half-open, so periods tile the timeline), and the
                        // user picked an inclusive last day. Showing the stored
                        // instant would name the day *after* the one they
                        // chose — off by one, on the label that says what they
                        // are looking at. `core/date/` answers which day that
                        // is; a widget does no calendar arithmetic (§3).
                        formatJalaliDate(lastJalaliDayOf(filter.period!)),
                      )
                    : strings.invoiceFilterPeriodCustom,
              ),
              selected: isCustom,
              // Not `onSelected`: a `ChoiceChip` reports being *deselected*
              // too, and there is nothing to do with that here — the way out of
              // a custom range is «همهٔ تاریخ‌ها» beside it. Tapping this one
              // always means "choose a range", including when it is already
              // selected and the user wants a different one.
              onSelected: (bool _) => _pickCustomRange(strings, filter),
            ),
          ],
        ),
      ],
    );
  }

  /// Two calendars in turn: the first day, then the last.
  ///
  /// **Two sequential picks rather than a range calendar**, because the picker
  /// this application already has answers "which day" correctly — Jalali
  /// months, a Saturday week start, Persian digits — and a second grid that
  /// tracked two selections would be a second implementation of all of that
  /// (§2's question, and D-072's rule about a guard that agrees with what it
  /// watches, applied to a widget).
  ///
  /// **The end is inclusive to the user and exclusive in the range.** A user
  /// picking ۱ to ۳۱ means the whole of the 31st; `jalaliDay(last).end` is the
  /// instant the next day begins, which is exactly the half-open upper bound
  /// [InstantRange] is documented to want. Passing the picked instant straight
  /// through would drop the last day of every range the user ever chose.
  Future<void> _pickCustomRange(
    AppStrings strings,
    InvoiceFilter filter,
  ) async {
    final DateTime now = ref.read(nowProvider);
    final InstantRange? current = filter.period;

    final DateTime? first = await showJalaliDatePicker(
      context,
      initial: current?.start ?? now,
      title: strings.invoiceFilterPeriodCustomFrom,
    );
    if (first == null || !mounted) return;

    final DateTime? last = await showJalaliDatePicker(
      context,
      // The same day, not `now`: a user who picked a day last Ordibehesht is
      // choosing the other end of *that*, and opening the second calendar on
      // today's month would make them navigate back to where they just were.
      initial: first,
      // Days before the start are shown but not selectable, so an empty range
      // — which `InstantRange` refuses by throwing — cannot be expressed.
      firstAllowed: first,
      title: strings.invoiceFilterPeriodCustomTo,
    );
    if (last == null || !mounted) return;

    ref
        .read(invoiceListQueryProvider.notifier)
        .filter(
          filter.withPeriod(InstantRange(first, jalaliDay(jalaliAt(last)).end)),
        );
  }

  /// The presets, resolved through `core/date/` against one instant.
  ///
  /// **Presets first, because «این ماه» and «ماه گذشته» are what a user
  /// actually asks a billing application** and a pair of calendars to fill in
  /// is four taps to express the same question. That reasoning stands; what it
  /// did not license was the sentence that used to follow it, that a custom
  /// range "is a later phase's problem, not a gap here". It was a gap, the
  /// owner found it in use, and `_pickCustomRange` sits beside these now
  /// (D-111).
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
