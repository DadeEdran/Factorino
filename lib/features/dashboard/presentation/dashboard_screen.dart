import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/jalali_display.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/localization/month_names.dart';
import '../../../core/money/money.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/router/destinations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_table.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/count_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../data/models/invoice_list_item.dart';
import '../../invoices/presentation/invoices_screen.dart';
import '../../settings/presentation/widgets/seller_identity_prompt.dart';
import '../application/dashboard_providers.dart';
import '../domain/dashboard_summary.dart';

/// The dashboard.
///
/// **Real aggregates, computed in SQL, over Jalali periods** — the three things
/// this screen is obliged to get right:
///
/// * Every figure comes from the database (§15). There is no seeded sample and
///   no placeholder; a dashboard with invented numbers is the exact thing §15
///   prohibits, and it is convincing in a way an empty screen is not.
/// * "این ماه" is the current **Jalali** month (D-006). The boundaries are
///   resolved in the Jalali calendar and only then converted to instants, and
///   the caption on the tile names the month so the user can see which one the
///   app meant.
/// * Nothing is summed or counted in Dart (§13). `SUM` and `COUNT` run in
///   SQLite; the repository never hands this screen a list to fold.
///
/// The figures arrive as **one** [DashboardSummary] rather than as four
/// providers, so the page cannot show a sales total from before a write beside
/// a count from after it.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final AsyncValue<DashboardSummary> summary = ref.watch(
      dashboardSummaryProvider,
    );

    return PageBody(
      title: strings.dashboardTitle,
      // **In the title row, which costs no height** (§10). A card offering the
      // day view would sit above the tiles the page exists to show, and the
      // rule about that has already been rediscovered three times on three
      // different cards.
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: strings.dashboardDailySales,
          onPressed: () => context.go(AppRoutes.dailySales),
        ),
      ],
      // **Above the summary rather than inside it** (D-102), and that placement
      // is the point rather than a detail. `_DashboardBody` is not what a
      // first-time user sees — `data.isEmpty` gives them the empty state, and
      // they are exactly who this prompt exists for. Putting it inside the body
      // would have shown it to everyone except the person it is for.
      //
      // It is also outside `summary.when`, so a slow or failed aggregate query
      // cannot take the prompt with it: the two answer different questions and
      // neither should wait on the other.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SellerIdentityPrompt(),
          Expanded(child: _body(context, ref, strings, summary)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
    AsyncValue<DashboardSummary> summary,
  ) {
    return summary.when(
      loading: () => const _DashboardSkeleton(),
      error: (Object error, StackTrace stack) => AsyncErrorView(
        error: error,
        stackTrace: stack,
        scope: 'dashboard',
        onRetry: () => ref.invalidate(dashboardSummaryProvider),
      ),
      data: (DashboardSummary data) => data.isEmpty
          ? EmptyState(
              icon: Icons.insights_outlined,
              title: strings.emptyDashboardTitle,
              body: strings.emptyDashboardBody,
            )
          : _DashboardBody(summary: data, strings: strings),
    );
  }
}

/// Which of the three nested Jalali periods the sales figure covers.
///
/// **A selector rather than three tiles side by side** (D-119). The three were
/// one figure at three zoom levels and they were shown together so they could
/// be compared — but they are nested rather than additive, they took the whole
/// first row of the grid on every tier, and on a phone that is the entire first
/// screen spent on one question asked three ways. One tile, and the period is
/// chosen.
enum _Period { week, month, year }

class _DashboardBody extends StatefulWidget {
  const _DashboardBody({required this.summary, required this.strings});

  final DashboardSummary summary;
  final AppStrings strings;

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  /// The month, because it is the period a business reads its own trading in —
  /// and because it is the one the invoice count beside it counts.
  _Period _period = _Period.month;

  DashboardSummary get summary => widget.summary;
  AppStrings get strings => widget.strings;

  @override
  Widget build(BuildContext context) {
    final LayoutTier tier = context.tier;

    // The Jalali month the period figures cover, named rather than implied.
    // "این ماه" alone asks the user to trust that the app and they mean the
    // same month, and the two calendars' boundaries never coincide (D-006).
    final List<String> monthNames = jalaliMonthNames(strings);
    final String periodLabel = formatJalaliMonthYear(
      summary.period.start,
      monthNames: monthNames,
    );
    // A week is the one period whose name does not say which days it covers, so
    // its caption names both ends. `lastJalaliDayOf` rather than the range's own
    // `end`, which is exclusive and would name the following Saturday — a day
    // outside the figure, on the label that says what the figure covers.
    final ({String from, String to}) weekDays = formatJalaliDayRangeParts(
      summary.week,
      monthNames: monthNames,
    );
    final String weekLabel = strings.invoiceFilterPeriodCustomRange(
      weekDays.from,
      weekDays.to,
    );
    final String yearLabel = formatJalaliYear(summary.year.start);

    final AmountSize amountSize = tier.isMobile
        ? AmountSize.medium
        : AmountSize.large;

    // The selected period's figure, its title and the caption that says which
    // days it covers, resolved together so the three cannot come apart.
    // Destructured, so the figure and the two labels are three names rather
    // than three positions.
    final (
      Money sales,
      String salesLabel,
      String salesCaption,
    ) = switch (_period) {
      _Period.week => (
        summary.salesThisWeek,
        strings.dashboardSalesThisWeek,
        weekLabel,
      ),
      _Period.month => (
        summary.salesThisPeriod,
        strings.dashboardSalesThisMonth,
        periodLabel,
      ),
      _Period.year => (
        summary.salesThisYear,
        strings.dashboardSalesThisYear,
        yearLabel,
      ),
    };

    return ListView(
      children: <Widget>[
        // Above the grid and not inside a tile: it governs the first tile, and
        // a control that changes what a card says belongs beside the card
        // rather than in it. It costs one row of chips, which is what the two
        // tiles it replaced cost several times over.
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_Period>(
            segments: <ButtonSegment<_Period>>[
              ButtonSegment<_Period>(
                value: _Period.week,
                label: Text(strings.dashboardPeriodWeek),
              ),
              ButtonSegment<_Period>(
                value: _Period.month,
                label: Text(strings.dashboardPeriodMonth),
              ),
              ButtonSegment<_Period>(
                value: _Period.year,
                label: Text(strings.dashboardPeriodYear),
              ),
            ],
            selected: <_Period>{_period},
            // No icons, and for D-108's measured reason: three Persian words
            // divided across a 320-pixel row have no room to spend on 18 px of
            // glyph and 8 px of gap, and what breaks is the word.
            showSelectedIcon: false,
            onSelectionChanged: (Set<_Period> selection) =>
                setState(() => _period = selection.first),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TileGrid(
          // Four tiles now that the sales figure is one tile rather than three,
          // so the desktop row is full rather than ragged.
          columns: switch (tier) {
            LayoutTier.mobile => 1,
            LayoutTier.tablet => 2,
            LayoutTier.desktop => 4,
          },
          tiles: <Widget>[
            StatTile(
              label: salesLabel,
              caption: salesCaption,
              value: AmountText(sales, size: amountSize),
            ),
            StatTile(
              label: strings.dashboardInvoiceCount,
              caption: periodLabel,
              value: CountText(
                value: summary.issuedCountThisPeriod,
                size: amountSize,
              ),
            ),
            StatTile(
              label: strings.dashboardOutstanding,
              caption: strings.dashboardOutstandingCaption,
              value: AmountText(summary.outstanding, size: amountSize),
            ),
            StatTile(
              label: strings.dashboardCustomerCount,
              value: CountText(value: summary.customerCount, size: amountSize),
            ),
          ],
        ),
        if (summary.invoiceCount > 0) ...<Widget>[
          const SizedBox(height: AppSpacing.xxl),
          _RecentInvoices(strings: strings, tier: tier),
        ],
      ],
    );
  }
}

/// The handful of most recent invoices, in the same row widgets the invoice
/// list uses.
///
/// Reusing [InvoiceCard] and [InvoiceTableRow] rather than writing a compact
/// variant: an invoice that looks one way here and another way one tap along is
/// two designs to keep in step, and the difference is exactly where a status
/// badge or an amount format quietly diverges.
///
/// Not virtualized, and it does not need to be — the query asks for
/// [kRecentInvoiceCount] rows and that is the number built. The list this is a
/// preview of is the one that pages.
class _RecentInvoices extends ConsumerWidget {
  const _RecentInvoices({required this.strings, required this.tier});

  final AppStrings strings;
  final LayoutTier tier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<InvoiceListItem>> recent = ref.watch(
      recentInvoicesProvider,
    );
    final DateTime now = ref.watch(nowProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          title: strings.dashboardRecentInvoices,
          trailing: TextButton(
            onPressed: () => context.go(AppDestination.invoices.path),
            child: Text(strings.actionViewAll),
          ),
        ),
        recent.when(
          loading: () => const SizedBox.shrink(),
          error: (Object error, StackTrace stack) => AsyncErrorView(
            error: error,
            stackTrace: stack,
            scope: 'dashboard',
          ),
          data: (List<InvoiceListItem> items) => tier.usesTables
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
                ),
        ),
      ],
    );
  }
}

/// Tiles shaped like the ones that are coming, not a spinner over an empty
/// page (§10).
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return TileGrid(
      columns: switch (context.tier) {
        LayoutTier.mobile => 1,
        LayoutTier.tablet => 2,
        LayoutTier.desktop => 3,
      },
      // Six, matching the six that arrive. A skeleton short of the real thing
      // is a page that jumps when the data lands.
      tiles: const <Widget>[
        StatTileSkeleton(),
        StatTileSkeleton(),
        StatTileSkeleton(),
        StatTileSkeleton(),
        StatTileSkeleton(),
        StatTileSkeleton(),
      ],
    );
  }
}
