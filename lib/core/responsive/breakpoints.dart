import 'package:flutter/widgets.dart';

/// The three layout tiers.
///
/// Tiers, not pixel checks scattered through the codebase. A widget asks which
/// tier it is in and gets an answer from one place, so "what counts as a
/// tablet" is a decision made once and changeable once.
enum LayoutTier {
  /// Phones. Touch-first, single column, bottom navigation. Lists are **cards**
  /// — a table squeezed to 380 logical pixels is a table nobody can read.
  mobile,

  /// Large phones in landscape and tablets. Higher density, a navigation rail
  /// instead of a bottom bar, and two panes where a screen has a natural
  /// master/detail split.
  tablet,

  /// Windows, web, and tablets in landscape. Multi-column, real data tables,
  /// an extended rail with labels, and a content column that stops widening
  /// past a readable measure.
  desktop;

  bool get isMobile => this == LayoutTier.mobile;
  bool get isTablet => this == LayoutTier.tablet;
  bool get isDesktop => this == LayoutTier.desktop;

  /// True where a real data table is appropriate. Mobile gets cards.
  bool get usesTables => this == LayoutTier.desktop;

  /// True where navigation is a rail rather than a bottom bar.
  bool get usesRail => this != LayoutTier.mobile;
}

/// Where the tiers change.
///
/// 600 is the conventional Material breakpoint and is kept because it matches
/// the hardware rather than because it is conventional: it is where a bottom
/// bar stops being reachable with a thumb.
///
/// **1312 is measured, and it replaced 1024, which was wrong.** The old value
/// carried the claim that 1024 "is where a data table has room for the five
/// columns an invoice list needs without truncation". It is not, and nothing
/// had ever checked: at a 1024-wide window the invoice table is laid out at
/// **695** logical pixels and its columns need **880**. The window is not the
/// width the table gets — the rail, the page padding and, on
/// `/customers/:id`, a side panel all come out of it first.
///
/// **What that cost.** Between 1024 and ~1300 the dashboard, the invoice list,
/// the customer list and the customer detail screen all laid a table out
/// narrower than its columns. In a debug build `AppTableHeader`'s D-065 guard
/// throws and the user sees a red `ErrorWidget` — which is how this was found,
/// by the owner dragging a Windows window and watching it break in the middle
/// and nowhere else. **In a release build that guard is compiled out**, and the
/// same widths would instead have shipped the silent version: Persian rendered
/// one glyph per row, which is the exact defect D-065 exists to prevent.
///
/// **The number is measured, not chosen.** At a desktop breakpoint of 1280 one
/// screen still fails the sweep; at 1304 every screen is clean at every width.
/// 1312 is the next multiple of 16 above the measured boundary.
/// `width_sweep_test.dart` is what measures it, and it fails if this number is
/// lowered.
///
/// **The deeper fix is not this**, and is recorded in D-081: the choice between
/// a table and cards should be made from the width the table will actually be
/// given, not from the width of the window. That is a `LayoutBuilder` at ten
/// call sites, and it is the right shape — this number is correct for the
/// layouts that exist today and will need re-measuring if any of them changes
/// how much width it takes before the table.
abstract final class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1312;

  static LayoutTier tierFor(double width) {
    if (width >= desktop) return LayoutTier.desktop;
    if (width >= tablet) return LayoutTier.tablet;
    return LayoutTier.mobile;
  }
}

/// Reads the current tier.
///
/// An extension on `BuildContext` rather than a `MediaQuery.of` call at every
/// site: this rebuilds only on size changes, and it keeps the breakpoint
/// numbers out of the widgets entirely (§10).
extension LayoutTierContext on BuildContext {
  LayoutTier get tier => Breakpoints.tierFor(MediaQuery.sizeOf(this).width);
}
