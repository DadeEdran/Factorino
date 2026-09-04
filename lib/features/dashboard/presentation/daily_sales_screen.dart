import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../../core/date/jalali_instant.dart';
import '../../../core/date/jalali_period.dart';
import '../../../core/formatting/jalali_display.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/localization/month_names.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_table.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/count_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/jalali_month_grid.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../data/models/daily_sales.dart';
import '../../../data/models/invoice_list_item.dart';
import '../../invoices/presentation/invoices_screen.dart';
import '../application/daily_sales_providers.dart';

/// «فروش روزانه» — pick a day, see what was sold on it.
///
/// ## What the dot on a day means, and why
///
/// **A day is marked when an invoice was *issued* on it.** Not when a payment
/// was received on it. The choice matters because the two calendars genuinely
/// differ, and picking the wrong one makes the marking mean something other
/// than what the page reports:
///
/// * The figure this screen shows is *sales* — the sum of `grandTotal` over the
///   invoices issued that day — which is the same population as every other
///   sales figure in the application (D-039). If the dot meant "money moved
///   today" a user would tap a marked day and be told nothing was sold on it,
///   which is the marking contradicting the page it is a control for.
/// * One invoice paid in three instalments would light up four days, and three
///   of them would show a sales total of zero. The dot would then be measuring
///   collection activity while the heading measured trade.
/// * Sales on a date is the figure a business reconciles against — it is what
///   the invoice itself is dated, what a tax period is computed from, and what
///   the month and year tiles on the dashboard already mean. A cash-received
///   view is a real and useful second report, and it is a different one; it
///   belongs with گزارش‌ها in Phase 8 rather than as a second meaning quietly
///   folded into this dot.
///
/// The legend under the calendar says this in Persian, so the rule is on the
/// screen and not only in this comment.
///
/// ## One query per visible month
///
/// The grid asks `DailySales.hasSales` thirty-one times and that costs nothing:
/// the whole month arrives as a single grouped aggregate keyed by Iranian civil
/// day (`InvoiceRepository.watchDailySales`), and the map is already in memory
/// when the grid builds. Stepping to another month is one new query, not
/// another thirty-one.
///
/// ## Layout
///
/// The calendar is the control and the day's invoices are the content, so on a
/// phone they stack in that order and on a wide window the calendar sits beside
/// the day's figures with the invoice table at **full width below**. Putting
/// the table beside a 312-wide calendar is exactly the squeeze D-053 measured
/// and rejected: the four columns include two fixed money widths, and there is
/// no window size at which the panel and the table both have the room.
class DailySalesScreen extends ConsumerStatefulWidget {
  const DailySalesScreen({super.key});

  @override
  ConsumerState<DailySalesScreen> createState() => _DailySalesScreenState();
}

class _DailySalesScreenState extends ConsumerState<DailySalesScreen> {
  Jalali? _selected;

  /// The month on screen, which is not the selection: browsing away from the
  /// selected day must not move it, exactly as in the date picker.
  Jalali? _visibleMonth;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    // The clock is read through the provider, so a test can fix "today" and so
    // the screen opens on the user's day rather than on a UTC one.
    final Jalali today = jalaliAt(ref.watch(nowProvider));
    final Jalali selected = _selected ?? today;
    final Jalali visibleMonth =
        _visibleMonth ?? Jalali(selected.year, selected.month, 1);

    final InstantRange day = jalaliDay(selected);
    final InstantRange month = jalaliMonth(
      visibleMonth.year,
      visibleMonth.month,
    );

    return PageBody(
      title: strings.dailySalesTitle,
      onBack: () => Navigator.of(context).maybePop(),
      child: _Body(
        strings: strings,
        selected: selected,
        visibleMonth: visibleMonth,
        day: day,
        month: month,
        onStepMonth: (int delta) => setState(() {
          // Day 1 every time, because month arithmetic on day 31 lands outside
          // a 30-day month and `shamsi_date` would throw rather than clamp.
          final Jalali moved = visibleMonth.addMonths(delta);
          _visibleMonth = Jalali(moved.year, moved.month, 1);
        }),
        onPick: (Jalali picked) => setState(() {
          _selected = picked;
          _visibleMonth = Jalali(picked.year, picked.month, 1);
        }),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.strings,
    required this.selected,
    required this.visibleMonth,
    required this.day,
    required this.month,
    required this.onStepMonth,
    required this.onPick,
  });

  final AppStrings strings;
  final Jalali selected;
  final Jalali visibleMonth;
  final InstantRange day;
  final InstantRange month;
  final ValueChanged<int> onStepMonth;
  final ValueChanged<Jalali> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LayoutTier tier = context.tier;
    final AsyncValue<DailySales> calendar = ref.watch(
      monthlySalesCalendarProvider(month),
    );
    final AsyncValue<DailySales> dayTotals = ref.watch(daySalesProvider(day));

    final Widget calendarPane = _CalendarPane(
      strings: strings,
      selected: selected,
      visibleMonth: visibleMonth,
      calendar: calendar,
      onStepMonth: onStepMonth,
      onPick: onPick,
    );

    final Widget figures = _DayFigures(
      strings: strings,
      selected: selected,
      totals: dayTotals,
      tier: tier,
    );

    return ListView(
      children: <Widget>[
        if (tier.isMobile) ...<Widget>[
          calendarPane,
          const SizedBox(height: AppSpacing.lg),
          figures,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: kJalaliCalendarWidth, child: calendarPane),
              const SizedBox(width: AppSpacing.xl),
              Expanded(child: figures),
            ],
          ),
        const SizedBox(height: AppSpacing.xxl),
        _DayInvoices(strings: strings, day: day, tier: tier),
      ],
    );
  }
}

class _CalendarPane extends StatelessWidget {
  const _CalendarPane({
    required this.strings,
    required this.selected,
    required this.visibleMonth,
    required this.calendar,
    required this.onStepMonth,
    required this.onPick,
  });

  final AppStrings strings;
  final Jalali selected;
  final Jalali visibleMonth;
  final AsyncValue<DailySales> calendar;
  final ValueChanged<int> onStepMonth;
  final ValueChanged<Jalali> onPick;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // While the month's aggregate is loading or has failed, the grid still
    // draws and is still usable — it simply carries no dots. A calendar that
    // waited for its marks would make picking a day depend on a query the day
    // does not need.
    final DailySales? marks = calendar.asData?.value;

    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          JalaliMonthHeader(
            month: visibleMonth,
            monthNames: jalaliMonthNames(strings),
            strings: strings,
            onStep: onStepMonth,
          ),
          const SizedBox(height: AppSpacing.sm),
          JalaliWeekdayHeadings(strings: strings),
          const SizedBox(height: AppSpacing.xs),
          JalaliMonthGrid(
            month: visibleMonth,
            selected: selected,
            onPick: onPick,
            isMarked: marks?.hasSales,
            markedSemanticLabel: strings.dailySalesMarkedDay,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.dailySalesLegend,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayFigures extends StatelessWidget {
  const _DayFigures({
    required this.strings,
    required this.selected,
    required this.totals,
    required this.tier,
  });

  final AppStrings strings;
  final Jalali selected;
  final AsyncValue<DailySales> totals;
  final LayoutTier tier;

  @override
  Widget build(BuildContext context) {
    // The day the figures are for, named rather than implied — the same rule
    // the dashboard's month caption follows (D-006). The selection is visible
    // on the calendar, but the figure has to carry its own scope: read on its
    // own it is otherwise a number with no period attached.
    final String dayLabel = formatJalaliDateLong(
      startOfJalaliDayUtc(selected),
      monthNames: jalaliMonthNames(strings),
    );
    final AmountSize amountSize = tier.isMobile
        ? AmountSize.medium
        : AmountSize.large;

    return totals.when(
      loading: () => TileGrid(
        columns: tier.isMobile ? 1 : 2,
        tiles: const <Widget>[StatTileSkeleton(), StatTileSkeleton()],
      ),
      error: (Object error, StackTrace stack) =>
          AsyncErrorView(error: error, stackTrace: stack, scope: 'daily-sales'),
      data: (DailySales sales) {
        final DaySales figures = sales.on(selected);
        return TileGrid(
          columns: tier.isMobile ? 1 : 2,
          tiles: <Widget>[
            StatTile(
              label: strings.dailySalesDayTotal,
              caption: dayLabel,
              value: AmountText(
                figures.total,
                unitLabel: strings.unitToman,
                size: amountSize,
              ),
            ),
            StatTile(
              label: strings.dashboardInvoiceCount,
              caption: dayLabel,
              value: CountText(value: figures.invoiceCount, size: amountSize),
            ),
          ],
        );
      },
    );
  }
}

class _DayInvoices extends ConsumerWidget {
  const _DayInvoices({
    required this.strings,
    required this.day,
    required this.tier,
  });

  final AppStrings strings;
  final InstantRange day;
  final LayoutTier tier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<InvoiceListItem>> invoices = ref.watch(
      dayInvoicesProvider(day),
    );
    final DateTime now = ref.watch(nowProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(title: strings.dailySalesInvoicesSection),
        invoices.when(
          loading: () => SkeletonList(
            // Inside the page's own ListView, so it must size to its rows.
            shrinkWrap: true,
            rowCount: 3,
            rowBuilder: (BuildContext context) =>
                InvoiceSkeletonRow(tier: tier),
          ),
          error: (Object error, StackTrace stack) => AsyncErrorView(
            error: error,
            stackTrace: stack,
            scope: 'daily-sales',
          ),
          data: (List<InvoiceListItem> items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.event_busy_outlined,
                title: strings.dailySalesEmptyTitle,
                body: strings.dailySalesEmptyBody,
              );
            }
            // The same rows the invoice list draws, for the reason the
            // dashboard reuses them: an invoice that looks one way here and
            // another way one tap along is two designs to keep in step.
            return tier.usesTables
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AppTableHeader(columns: invoiceColumns(strings)),
                      for (final InvoiceListItem item in items)
                        InvoiceTableRow(item: item, strings: strings, now: now),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final InvoiceListItem item in items) ...<Widget>[
                        InvoiceCard(item: item, strings: strings, now: now),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  );
          },
        ),
      ],
    );
  }
}
