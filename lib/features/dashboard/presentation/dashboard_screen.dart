import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/jalali_display.dart';
import '../../../core/formatting/number_display.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/localization/month_names.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/router/destinations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_table.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../data/models/invoice_list_item.dart';
import '../../invoices/presentation/invoices_screen.dart';
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
      child: summary.when(
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
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.summary, required this.strings});

  final DashboardSummary summary;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final LayoutTier tier = context.tier;

    // The Jalali month the period figures cover, named rather than implied.
    // "این ماه" alone asks the user to trust that the app and they mean the
    // same month, and the two calendars' boundaries never coincide (D-006).
    final String periodLabel = formatJalaliMonthYear(
      summary.period.start,
      monthNames: jalaliMonthNames(strings),
    );

    final AmountSize amountSize = tier.isMobile
        ? AmountSize.medium
        : AmountSize.large;

    return ListView(
      children: <Widget>[
        TileGrid(
          columns: switch (tier) {
            LayoutTier.mobile => 1,
            LayoutTier.tablet => 2,
            LayoutTier.desktop => 4,
          },
          tiles: <Widget>[
            StatTile(
              label: strings.dashboardSalesThisMonth,
              caption: periodLabel,
              value: AmountText(
                summary.salesThisPeriod,
                unitLabel: strings.unitToman,
                size: amountSize,
              ),
            ),
            StatTile(
              label: strings.dashboardInvoiceCount,
              caption: periodLabel,
              value: _CountText(
                value: summary.issuedCountThisPeriod,
                size: amountSize,
              ),
            ),
            StatTile(
              label: strings.dashboardOutstanding,
              caption: strings.dashboardOutstandingCaption,
              value: AmountText(
                summary.outstanding,
                unitLabel: strings.unitToman,
                size: amountSize,
              ),
            ),
            StatTile(
              label: strings.dashboardCustomerCount,
              value: _CountText(value: summary.customerCount, size: amountSize),
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

/// A count, in the same numeral style as an amount but with no unit.
///
/// No unit label, deliberately. §9's "never a bare number" is about money,
/// where the difference between Rial and Toman is a factor of ten; a count of
/// invoices under a tile labelled "فاکتورهای صادرشده" has no such ambiguity,
/// and repeating the noun would be noise.
class _CountText extends StatelessWidget {
  const _CountText({required this.value, required this.size});

  final int value;
  final AmountSize size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle style = switch (size) {
      AmountSize.large => AppTypography.amountLarge,
      AmountSize.medium => AppTypography.amountMedium,
      AmountSize.small => AppTypography.amountSmall,
    };

    return Text(
      formatGroupedPersian(value),
      style: style.copyWith(
        color: theme.colorScheme.onSurface,
        fontFamily: AppTypography.fontFamily,
      ),
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
        LayoutTier.desktop => 4,
      },
      tiles: const <Widget>[
        StatTileSkeleton(),
        StatTileSkeleton(),
        StatTileSkeleton(),
        StatTileSkeleton(),
      ],
    );
  }
}
