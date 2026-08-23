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
/// 600 and 1024 are the conventional Material breakpoints, kept because they
/// match the hardware rather than because they are conventional: 600 is where a
/// bottom bar stops being reachable with a thumb, and 1024 is where a data
/// table has room for the five columns an invoice list needs
/// (number, customer, date, status, amount) without truncation.
abstract final class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

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
