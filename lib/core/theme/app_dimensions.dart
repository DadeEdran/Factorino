/// Spacing, radius, border and elevation tokens.
///
/// **The only file allowed to name a size, radius or spacing value.** Anywhere
/// else, a bare number inside `EdgeInsets`, `BorderRadius`, `SizedBox` or
/// `fontSize` fails `theme_tokens_only_test.dart`.
///
/// The point is not tidiness. Scattered literals drift — `12` here, `14` three
/// screens later — and the result is a layout that is subtly irregular in a way
/// nobody can point at but everybody feels. A closed set of steps makes
/// irregularity impossible rather than merely discouraged.
library;

/// A 4-point spacing scale.
///
/// Four is small enough to express tight relationships and large enough that
/// the steps stay visibly distinct; every value below is a multiple of it, so
/// anything laid out with these tokens lands on a common rhythm.
abstract final class AppSpacing {
  /// 2 — hairline separation, effectively only for icon/text nudges.
  static const double xxs = 2;

  /// 4 — inside a chip or a badge.
  static const double xs = 4;

  /// 8 — between tightly related items: a label and its value.
  static const double sm = 8;

  /// 12 — inside compact controls; the vertical rhythm of a dense table row.
  static const double md = 12;

  /// 16 — the default. Card padding, list-item padding, gap between fields.
  static const double lg = 16;

  /// 24 — between groups: sections of a form, cards in a grid.
  static const double xl = 24;

  /// 32 — between major regions of a page.
  static const double xxl = 32;

  /// 48 — page margins on desktop, and the breathing room around an empty
  /// state, which needs to feel deliberate rather than unfinished.
  static const double xxxl = 48;
}

/// Corner radii.
///
/// Restrained on purpose: heavily rounded corners read as consumer-playful, and
/// this is a tool someone uses to produce tax documents.
abstract final class AppRadius {
  /// 6 — badges, chips, small inputs.
  static const double sm = 6;

  /// 10 — buttons and text fields.
  static const double md = 10;

  /// 14 — cards and panels.
  static const double lg = 14;

  /// 20 — dialogs and bottom sheets.
  static const double xl = 20;

  /// Fully round: avatars, and the only place a pill shape is used.
  static const double full = 999;
}

/// Border widths. Borders carry the structure in this design; shadows are a
/// last resort (§10).
abstract final class AppBorders {
  static const double hairline = 1;

  /// The focus ring, and the leading edge of a selected navigation item.
  static const double emphasis = 2;
}

/// Elevation, used sparingly.
///
/// Only two levels are real: flat, and "floating above the page" for menus and
/// dialogs, where a shadow is the only cue that separates layers. Cards use a
/// border and a surface step instead, which stays legible in dark mode where
/// shadows are nearly invisible.
abstract final class AppElevation {
  static const double none = 0;
  static const double raised = 1;
  static const double overlay = 8;
}

/// Icon sizes, tied to the type scale so an icon never out-weighs its label.
abstract final class AppIconSize {
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;

  /// The illustration in an empty state.
  static const double xxl = 56;
}

/// Motion. Subtle and fast (§10) — and the platform's reduced-motion setting is
/// respected by using these through the standard implicit-animation widgets,
/// which already honour it.
abstract final class AppDuration {
  /// Button and hover feedback: fast enough to feel like a response rather
  /// than an animation.
  static const Duration fast = Duration(milliseconds: 120);

  /// Page and panel transitions.
  static const Duration medium = Duration(milliseconds: 220);
}

/// Layout constants that are not spacing.
abstract final class AppLayout {
  /// Text stops being comfortable to read past roughly this width, so content
  /// columns are capped rather than stretched across a 27-inch monitor.
  static const double maxContentWidth = 1240;

  /// The reading width of a single column of prose or a form.
  static const double maxFormWidth = 560;

  /// Minimum touch target, per platform guidance.
  static const double minTouchTarget = 48;

  /// The width of the desktop navigation rail when it shows labels.
  static const double navigationRailWidth = 232;

  /// The width of the tablet rail, where labels sit beneath their icons.
  ///
  /// Wide enough for the longest destination -- محصولات و خدمات -- to wrap onto
  /// two lines rather than overflow. Measured against that label rather than
  /// chosen: it is the one that decides this number, and a rail sized for the
  /// short labels clips it silently at exactly one breakpoint, which is the
  /// kind of defect that ships.
  static const double navigationRailCompactWidth = 104;

  /// The measure a wrapped rail label is given inside
  /// [navigationRailCompactWidth], leaving the rail its own side padding.
  static const double navigationRailLabelWidth = 88;
}
