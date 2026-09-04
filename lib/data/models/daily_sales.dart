import 'package:shamsi_date/shamsi_date.dart';

import '../../core/date/jalali_instant.dart';
import '../../core/date/jalali_period.dart';
import '../../core/money/money.dart';

/// What was sold on one Iranian civil day.
///
/// [total] is the sum of `grandTotal` over the invoices **issued** that day —
/// the same population every other sales figure in the application covers
/// (D-039) — so a day read off the calendar and the month tile on the dashboard
/// are figures of the same kind, and the days of a month add up to it.
class DaySales {
  const DaySales({required this.total, required this.invoiceCount});

  final Money total;

  /// How many documents [total] is the sum of.
  final int invoiceCount;

  static const DaySales none = DaySales(total: Money.zero, invoiceCount: 0);
}

/// Sales per day across a range, from **one** query.
///
/// **Why this type exists at all.** A month calendar has to mark which days had
/// sales, and the obvious shape — ask the repository for each day in turn — is
/// thirty-one queries to paint one grid, re-issued every time the user steps a
/// month. This is a single grouped aggregate instead: `GROUP BY` the Iranian
/// civil day, one row per day that has anything, and the grid reads its answers
/// out of the map.
///
/// **Sparse on purpose.** Only days with issued invoices are rows, because that
/// is what the `GROUP BY` returns and because it is also the question the
/// calendar asks: a day absent from the map had no sales. [on] answers for any
/// day, so no caller has to know which days are present.
///
/// Keyed by [dayIndexAtMillis]'s index rather than by `Jalali`, because the key
/// has to be the thing the query grouped on. Converting each row to a Jalali
/// date in Dart and keying on that would work right up until `Jalali`'s equality
/// or hash behaved differently from the integer SQLite grouped by, and the
/// symptom would be a day that has sales and no dot.
class DailySales {
  const DailySales({
    required this.range,
    required this.offset,
    required this.byDayIndex,
  });

  /// The range the query covered. A day outside it is *unknown* rather than
  /// "no sales", so a caller must not read [on] for one — which is why the
  /// range travels with the result instead of being remembered separately.
  final InstantRange range;

  /// The offset the day boundaries were resolved in, carried so [on] cannot
  /// answer against a different one than the query grouped on.
  final Duration offset;

  /// The grouped rows, keyed by day index. Read through [on] rather than
  /// directly: an absent key means "no sales", and every call site would
  /// otherwise have to remember that.
  final Map<int, DaySales> byDayIndex;

  /// What was sold on [day]. Never null: a day with no invoices sold nothing,
  /// and [DaySales.none] is the true answer rather than a missing one.
  DaySales on(Jalali day) => byDayIndex[_indexOf(day)] ?? DaySales.none;

  /// Whether [day] had any sales — what the calendar marks.
  bool hasSales(Jalali day) => on(day).invoiceCount > 0;

  /// How many days in the range had sales at all.
  int get activeDayCount => byDayIndex.length;

  /// The sum across the whole range.
  ///
  /// The same figure the period tile for that range shows, which the repository
  /// test asserts against `totalIssuedRial` — so the calendar and the dashboard
  /// cannot come to disagree about the same month. Folding a map of at most
  /// thirty-one entries is not the Dart aggregation §13 forbids: the summing
  /// over rows already happened in SQL, and this adds up its output.
  Money get total => Money.rial(
    byDayIndex.values.fold<int>(0, (int sum, DaySales d) => sum + d.total.rial),
  );

  int _indexOf(Jalali day) => dayIndexAtMillis(
    startOfJalaliDayUtc(day, offset: offset).millisecondsSinceEpoch,
    offset: offset,
  );
}
