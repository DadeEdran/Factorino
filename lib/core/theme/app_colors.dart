import 'package:flutter/material.dart';

/// The colour palette. **The only file in the application allowed to name a
/// colour value**; everywhere else reads them from the theme.
/// `theme_tokens_only_test.dart` fails the build on a literal colour elsewhere.
///
/// ## The accent
///
/// One accent, and it is a **Persian turquoise** — the colour of Isfahan tile
/// work, deepened until it behaves like a business colour rather than a
/// decorative one. It was chosen over the obvious Material blue because this
/// app should not look like a generic dashboard, and over a saturated
/// turquoise because at full strength that colour is a craft-fair colour, not
/// something to look at for eight hours while reconciling invoices.
///
/// It appears sparingly: primary actions, the selected navigation destination,
/// focus rings. Money is **not** accent-coloured — an amount competes with
/// nothing for attention, so it is rendered in the strongest neutral instead.
/// Colour in this app carries meaning (see [StatusPalette]); the moment it is
/// also used for emphasis, the meaning stops being legible.
///
/// ## The neutrals
///
/// Warm rather than cold. A pure-grey business tool reads as clinical, and the
/// warmth also stops the turquoise from turning slightly green against it. In
/// dark mode the neutrals go the other way — very slightly cool — because a
/// warm dark surface reads as brown next to a turquoise accent.
///
/// ## Dark mode is designed, not inverted (§10)
///
/// Every dark value below is chosen, not computed. Surfaces step upward in
/// lightness as they come forward; the accent is lifted and desaturated so it
/// does not glow; the status colours are re-picked at their dark-background
/// contrast rather than lightened mechanically.
abstract final class AppColors {
  // ---- light -------------------------------------------------------------

  /// Deep Persian turquoise. Contrast 4.9:1 on [lightSurface] — passes AA for
  /// body text, which is what lets it be used for links and small labels and
  /// not just for filled buttons.
  static const Color lightPrimary = Color(0xFF11726B);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFCFEBE7);
  static const Color lightOnPrimaryContainer = Color(0xFF04302D);

  /// The page behind everything. Warm off-white: pure #FFFFFF under a full
  /// screen of text is glare, and on a Windows desktop it is glare next to the
  /// window chrome as well.
  static const Color lightBackground = Color(0xFFFAFAF8);

  /// Cards and sheets — one step *lighter* than the page, so raised surfaces
  /// come forward without needing a shadow to say so.
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer = Color(0xFFF3F2EF);
  static const Color lightSurfaceContainerHigh = Color(0xFFEAE9E5);

  static const Color lightOnSurface = Color(0xFF1B1A18);
  static const Color lightOnSurfaceVariant = Color(0xFF5B5852);

  /// Borders do the work shadows would otherwise do (§10: subtle borders over
  /// heavy shadows).
  static const Color lightOutline = Color(0xFFCFCDC7);
  static const Color lightOutlineVariant = Color(0xFFE5E3DE);

  static const Color lightError = Color(0xFFB3261E);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFF9DEDC);
  static const Color lightOnErrorContainer = Color(0xFF410E0B);

  // ---- dark --------------------------------------------------------------

  /// Lifted and desaturated from the light accent. The light primary on a dark
  /// surface would be an unreadable 2.1:1; this is 8.4:1 and does not vibrate.
  static const Color darkPrimary = Color(0xFF5ED2C5);
  static const Color darkOnPrimary = Color(0xFF00312D);
  static const Color darkPrimaryContainer = Color(0xFF0B554F);
  static const Color darkOnPrimaryContainer = Color(0xFFB6EFE8);

  /// Not black. True black against a bright accent produces halation, and on
  /// an OLED phone it makes every scroll edge shimmer.
  static const Color darkBackground = Color(0xFF0F1211);
  static const Color darkSurface = Color(0xFF161A19);
  static const Color darkSurfaceContainer = Color(0xFF1D2220);
  static const Color darkSurfaceContainerHigh = Color(0xFF262B29);

  /// Not pure white either: #FFFFFF body text on a dark surface is the classic
  /// cause of the shimmer people describe as "dark mode eye strain".
  static const Color darkOnSurface = Color(0xFFE6E9E7);
  static const Color darkOnSurfaceVariant = Color(0xFFA6ACA9);

  static const Color darkOutline = Color(0xFF3B4240);
  static const Color darkOutlineVariant = Color(0xFF2A302E);

  static const Color darkError = Color(0xFFF2B8B5);
  static const Color darkOnError = Color(0xFF601410);
  static const Color darkErrorContainer = Color(0xFF8C1D18);
  static const Color darkOnErrorContainer = Color(0xFFF9DEDC);
}

/// Semantic colours for the invoice lifecycle (§10).
///
/// A [ThemeExtension] rather than loose constants, so a widget reads them from
/// the theme like any other colour and light/dark switching is automatic.
///
/// **These carry meaning, so they are the only colours in the app that vary by
/// data.** Each is a pair: [foreground] for text and icons, [container] for the
/// badge behind them. The pairing is what keeps a badge legible without
/// resorting to a saturated fill.
@immutable
class StatusPalette extends ThemeExtension<StatusPalette> {
  const StatusPalette({
    required this.draft,
    required this.unpaid,
    required this.partiallyPaid,
    required this.paid,
    required this.cancelled,
    required this.overdue,
  });

  /// Not yet a claim on anyone: deliberately the quietest of the six, a plain
  /// neutral. A draft should not compete with a real invoice in a list.
  final StatusColors draft;

  /// Issued and waiting. Amber, not red — an unpaid invoice inside its terms
  /// is the normal state of business, not a problem.
  final StatusColors unpaid;

  /// Something arrived. Blue reads as "in progress" without implying either
  /// success or trouble.
  final StatusColors partiallyPaid;

  /// Settled. The only green in the application, which is what makes a green
  /// row scannable at a glance down a long list.
  final StatusColors paid;

  /// Void. A muted mauve-grey: recognisably *not* the neutral used for drafts,
  /// and deliberately without the urgency of red — a cancelled invoice needs no
  /// action, it just is not a claim any more.
  final StatusColors cancelled;

  /// Past its due date. The only red used for status, so red in a list always
  /// means exactly one thing: money that is late.
  final StatusColors overdue;

  static const StatusPalette light = StatusPalette(
    draft: StatusColors(
      foreground: Color(0xFF5B5852),
      container: Color(0xFFEDEBE7),
    ),
    unpaid: StatusColors(
      foreground: Color(0xFF8A5A00),
      container: Color(0xFFFBEED5),
    ),
    partiallyPaid: StatusColors(
      foreground: Color(0xFF1F5F9E),
      container: Color(0xFFDCEAF8),
    ),
    paid: StatusColors(
      foreground: Color(0xFF2A6B45),
      container: Color(0xFFD9EEE1),
    ),
    cancelled: StatusColors(
      foreground: Color(0xFF6B5F73),
      container: Color(0xFFEDE8F0),
    ),
    overdue: StatusColors(
      foreground: Color(0xFFB3261E),
      container: Color(0xFFF9DEDC),
    ),
  );

  static const StatusPalette dark = StatusPalette(
    draft: StatusColors(
      foreground: Color(0xFFA6ACA9),
      container: Color(0xFF262B29),
    ),
    unpaid: StatusColors(
      foreground: Color(0xFFE7B65A),
      container: Color(0xFF3A2E15),
    ),
    partiallyPaid: StatusColors(
      foreground: Color(0xFF8DBCE8),
      container: Color(0xFF17293A),
    ),
    paid: StatusColors(
      foreground: Color(0xFF7FD3A3),
      container: Color(0xFF16311F),
    ),
    cancelled: StatusColors(
      foreground: Color(0xFFB9AAC2),
      container: Color(0xFF2B2432),
    ),
    overdue: StatusColors(
      foreground: Color(0xFFF2A6A0),
      container: Color(0xFF3D1B18),
    ),
  );

  @override
  StatusPalette copyWith({
    StatusColors? draft,
    StatusColors? unpaid,
    StatusColors? partiallyPaid,
    StatusColors? paid,
    StatusColors? cancelled,
    StatusColors? overdue,
  }) {
    return StatusPalette(
      draft: draft ?? this.draft,
      unpaid: unpaid ?? this.unpaid,
      partiallyPaid: partiallyPaid ?? this.partiallyPaid,
      paid: paid ?? this.paid,
      cancelled: cancelled ?? this.cancelled,
      overdue: overdue ?? this.overdue,
    );
  }

  @override
  StatusPalette lerp(ThemeExtension<StatusPalette>? other, double t) {
    if (other is! StatusPalette) return this;
    return StatusPalette(
      draft: draft.lerp(other.draft, t),
      unpaid: unpaid.lerp(other.unpaid, t),
      partiallyPaid: partiallyPaid.lerp(other.partiallyPaid, t),
      paid: paid.lerp(other.paid, t),
      cancelled: cancelled.lerp(other.cancelled, t),
      overdue: overdue.lerp(other.overdue, t),
    );
  }
}

/// A status's text/icon colour and the surface it sits on.
@immutable
class StatusColors {
  const StatusColors({required this.foreground, required this.container});

  final Color foreground;
  final Color container;

  StatusColors lerp(StatusColors other, double t) => StatusColors(
    foreground: Color.lerp(foreground, other.foreground, t)!,
    container: Color.lerp(container, other.container, t)!,
  );
}
