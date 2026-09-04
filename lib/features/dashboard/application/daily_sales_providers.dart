import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/date/jalali_period.dart';
import '../../../data/models/daily_sales.dart';
import '../../../data/models/invoice_filter.dart';
import '../../../data/models/invoice_list_item.dart';
import '../../../data/models/invoice_status.dart';
import '../../../data/providers.dart';

part 'daily_sales_providers.g.dart';

/// Sales per day across [month], for the calendar's marks.
///
/// **One query for the whole visible month.** The alternative the screen shape
/// invites — ask for each day as the grid builds it — is thirty-one statements
/// to paint one calendar, re-issued on every month step; this is a single
/// `GROUP BY` over the month and the grid reads its answers out of the result.
/// See `InvoiceRepository.watchDailySales`.
///
/// Keyed by the month range, so stepping to another month is a new argument to
/// the same family rather than a rebuilt provider, and stepping back lands on a
/// result that is still live.
@riverpod
Stream<DailySales> monthlySalesCalendar(Ref ref, InstantRange month) =>
    ref.watch(invoiceRepositoryProvider).watchDailySales(month);

/// The selected day's own total and count.
///
/// The **same** query as the calendar's, over a one-day range, rather than a
/// second aggregate written for the purpose. Reading the figure out of the
/// month result would be a tempting saving and is wrong at the one moment it
/// matters: the user may step the calendar to another month while a day in the
/// previous one stays selected, and the month result no longer covers it. One
/// method answering both is also the reason the day figure and the dot can
/// never disagree about the same day.
@riverpod
Stream<DailySales> daySales(Ref ref, InstantRange day) =>
    ref.watch(invoiceRepositoryProvider).watchDailySales(day);

/// The invoices issued on the selected day, newest first.
///
/// Filtered **in SQL** by the same half-open range and the same statuses the
/// aggregate uses (D-039), so the list under the figure is the documents the
/// figure is the sum of. A list filtered in Dart would be a second definition
/// of "issued that day" and would eventually disagree with the first.
@riverpod
Stream<List<InvoiceListItem>> dayInvoices(Ref ref, InstantRange day) {
  return ref
      .watch(invoiceRepositoryProvider)
      .watchList(
        filter: InvoiceFilter(
          period: day,
          statuses: kIssuedInvoiceStatuses.toSet(),
        ),
      );
}
