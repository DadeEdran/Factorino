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

  /// How long a search field waits after the last keystroke before querying.
  ///
  /// Not motion, but it lives here so that every duration in the application
  /// is nameable in one file — the alternative is a literal in one widget and
  /// a different literal in the next, which is precisely the drift the token
  /// rule exists to prevent. 250 ms is below the threshold at which a response
  /// stops feeling immediate, and above the interval between keystrokes in
  /// ordinary typing, so a five-letter name produces one query rather than
  /// five.
  static const Duration inputDebounce = Duration(milliseconds: 250);

  /// How long after a back press on the home destination a second press still
  /// means "leave the application".
  ///
  /// Long enough to read a short Persian sentence and act on it, short enough
  /// that a back press half a minute later is not silently armed. It doubles as
  /// the message's own duration, so the prompt is on screen for exactly the
  /// window it describes.
  static const Duration exitConfirmation = Duration(milliseconds: 2500);

  /// One half-cycle of a skeleton loader's pulse.
  ///
  /// Slow on purpose. A skeleton is on screen while the user waits, and a fast
  /// pulse in the corner of the eye reads as an error indicator rather than as
  /// patience. Long enough to be perceived as breathing, short enough that a
  /// list that never loads still looks alive.
  static const Duration pulse = Duration(milliseconds: 900);
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

  /// Bottom padding a scrolling list needs when a floating action button sits
  /// over it.
  ///
  /// Without it the button covers the last row, and the last row is the one a
  /// user scrolls all the way down to reach. Found by a widget test whose tap
  /// on the load-more control landed on the button instead -- which is the
  /// same thing happening to a user, with no warning printed.
  static const double floatingActionClearance = 88;

  /// Room reserved at the end of a table row for its actions menu, matched by
  /// the header so the columns above and below stay aligned.
  static const double tableActionsWidth = 48;

  /// A table column holding a short fixed label -- a product type. Fixed
  /// rather than flexed so the column does not resize as the rows scroll past
  /// with longer or shorter values in it.
  static const double tableTypeWidth = 80;

  /// A table column holding a unit of measure.
  static const double tableUnitWidth = 96;

  /// The width an `AmountText` needs at each size, at the top of the stress
  /// ladder — 100,000,000 تومان, eleven glyphs with its separators, plus the
  /// unit label beside it (D-057).
  ///
  /// **Measured, not estimated**, by `money_layout_test.dart`, which fails if a
  /// figure ever outgrows the number beside it. Measured under the widget
  /// tests' fallback font, whose glyphs are much wider than Vazirmatn's, so the
  /// shipped layout has margin rather than sitting on the limit.
  ///
  /// **These are the reason a money site cannot be sized by eye.** An amount is
  /// the one thing on a document that may not be clipped, truncated or
  /// ellipsised, and its width depends on a magnitude the layout has no control
  /// over — which is how a panel that fits every figure in the demo database
  /// overflows on every real invoice. A container that cannot give an amount
  /// the width its size needs takes a **smaller size**, not a clipped figure.
  static const double amountWidthSmall = 232;

  /// See [amountWidthSmall].
  static const double amountWidthMedium = 276;

  /// See [amountWidthSmall]. The largest size in the scale needs nearly four
  /// hundred pixels, which is more than [detailPanelWidth] has — so it belongs
  /// on a surface with real width, or inside a [StatTile], whose `FittedBox`
  /// scales rather than clips.
  static const double amountWidthLarge = 376;

  /// A table column holding an amount.
  ///
  /// Fixed rather than flexed, because an amount column is aligned rather than
  /// filled: the figures hug the column's leading edge so their last digits
  /// line up, and a flexed column would leave that alignment floating at a
  /// different place on every window width.
  ///
  /// **Derived rather than chosen**, and that is the fix for how it was wrong.
  /// It read 232 with a comment claiming a ten-digit Toman figure fit — but a
  /// table cell spends `AppSpacing.md` of its width on the gap to the next
  /// column, so the amount only ever had 220 of it, and 100,000,000 تومان
  /// overflowed by 9 pixels. Sizing the column as *the amount's width plus the
  /// gap it does not get to use* is what stops the next person having to
  /// rediscover the difference (D-057).
  static const double tablePriceWidth = amountWidthSmall + AppSpacing.md;

  /// The narrowest **content** a flexible column carrying Persian prose may be
  /// given before the table has to change shape.
  ///
  /// Content, not column: `tableMinimumWidth` adds the `AppSpacing.md` gap a
  /// cell spends on its neighbour, exactly as [tablePriceWidth] adds it to
  /// [amountWidthSmall]. So a prose column's floor and one money column's width
  /// come to the same number, which is the point.
  ///
  /// **Derived, not chosen.** A description is the primary content of a row,
  /// and the project already spends [amountWidthSmall] on each *secondary*
  /// figure beside it (D-037). A primary column narrower than every secondary
  /// column on the same row is wrong on its face, so the floor for prose is the
  /// width of one money column — which also means the two move together if the
  /// money scale is ever retuned, instead of drifting apart the way
  /// [tablePriceWidth] and [amountWidthSmall] once did.
  ///
  /// **What it is for.** A fixed-width money column always gets its width; a
  /// flexible column gets whatever is left, and `Expanded` is a *tight* fit, so
  /// "whatever is left" can be nothing and the layout still succeeds. The
  /// invoice document's description was laid out at 21.6 pixels on every
  /// desktop width, rendering Persian one glyph per row, and no check fired
  /// because there is no overflow. A table that cannot give this much to its
  /// prose column drops a column instead (D-065).
  static const double tableMinTextWidth = amountWidthSmall;

  /// The same floor for a column holding one short measured value — a quantity
  /// and its unit, «۲٫۵ ساعت». Half the prose floor: it holds a number and a
  /// word, never a sentence.
  static const double tableMinValueWidth = amountWidthSmall / 2;

  /// A table column holding a Jalali date.
  ///
  /// Fixed, and wide enough for the zero-padded `۱۴۰۵/۰۶/۰۲` form. Dates are
  /// padded precisely so a column of them aligns, and a flexed column would
  /// undo that at every window width.
  static const double tableDateWidth = 120;

  /// A table column holding a status badge.
  ///
  /// Sized to the longest label -- `سررسید گذشته` -- rather than to the
  /// shortest, so the badge never wraps at exactly one status.
  static const double tableStatusWidth = 112;

  /// The side panel on a desktop detail page — the customer's record beside
  /// their invoices.
  ///
  /// Fixed rather than flexed, and narrow rather than half the page: it holds
  /// label-and-value pairs, which are read down a column rather than across, so
  /// extra width only puts the value further from its label. The main column
  /// keeps the rest, because the invoice table is the part that needs room for
  /// five columns without truncating.
  ///
  /// **It cannot hold an [AmountSize.large] figure**, and the invoice summary
  /// panel found that out the expensive way: 320 leaves 288 inside the card's
  /// padding, and [amountWidthLarge] is 376. The panel's grand total steps down
  /// a size rather than the panel widening, because widening it takes the space
  /// from the table beside it — which is what D-053 already measured and
  /// refused once.
  static const double detailPanelWidth = 320;

  /// The measure a wrapped rail label is given inside
  /// [navigationRailCompactWidth], leaving the rail its own side padding.
  static const double navigationRailLabelWidth = 88;
}

/// Skeleton-loader proportions.
///
/// A skeleton is only useful if it is the shape of the content it replaces --
/// otherwise the layout jumps when the data lands, which is the jarring effect
/// the skeleton existed to prevent. These are the shapes, named once.
abstract final class AppSkeleton {
  /// One line of text. Slightly shorter than the line height it stands for, so
  /// a stack of them reads as text rather than as solid blocks.
  static const double lineHeight = 14;

  /// A title line, whose real length is unknown.
  static const double titleWidth = 168;

  /// A secondary line beneath a title.
  static const double captionWidth = 112;

  /// A page title standing in for itself.
  static const double titleHeight = 20;

  /// One text field, including its label row.
  static const double fieldHeight = 56;
}
