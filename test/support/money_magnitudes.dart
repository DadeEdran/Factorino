/// The ladder of amounts every layout check runs over (D-057).
///
/// **Named here so a check cannot quietly exercise a friendlier one.** Phase 4
/// closed on a device pass reporting zero layout errors, and a summary panel
/// that overflows on every invoice above a million Toman went through it — the
/// pass ran on a phone, and the amounts it exercised were whatever the flow
/// happened to produce. A panel that fits at 100,000 and breaks at 1,000,000 is
/// a defect that hides behind small test data, and small test data is what a dev
/// database always holds.
///
/// The top rung is a **ceiling to design against**, not a prediction.
/// `kMaxAmountRial` is far above it; the point is that every fixed-width money
/// site states the magnitude it holds and is tested at it, so its width is a
/// decision somebody made rather than one the demo data made for them.
library;

/// Toman, ascending. Each rung is a real invoice somebody in this market issues:
///
/// * `100,000` — a small invoice; the rung everything already passed.
/// * `1,000,000` — where the desktop summary panel first overflowed.
/// * `10,000,000` — an ordinary invoice for a workshop or a contractor.
/// * `100,000,000` — a large project invoice, and a plausible lifetime total
///   for one customer on the customer detail screen.
const List<int> kMoneyStressToman = <int>[100000, 1000000, 10000000, 100000000];

/// The same ladder in the unit everything is stored in (§4).
const List<int> kMoneyStressRial = <int>[
  1000000,
  10000000,
  100000000,
  1000000000,
];

/// The widest rung — what a fixed-width money container has to hold.
const int kMoneyStressCeilingToman = 100000000;

/// The widest rung, in Rial.
const int kMoneyStressCeilingRial = 1000000000;
