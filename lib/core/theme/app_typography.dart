import 'package:flutter/material.dart';

/// The type scale.
///
/// **The only file allowed to name a font size or weight.**
///
/// ## Vazirmatn, three weights
///
/// 400 for body, 500 for section titles and emphasis, 700 for page titles and
/// money (D-022). Three is enough to build a hierarchy and few enough that the
/// hierarchy stays legible; a fourth weight would mostly create decisions
/// rather than distinctions.
///
/// ## The fallback family
///
/// Vazirmatn covers Persian and Latin but has no emoji, and on Windows its
/// Latin digits sit slightly differently from the system UI font in mixed
/// contexts. The fallback list is per-platform rather than a single family,
/// because the right answer differs: Segoe UI Emoji on Windows, Noto on
/// Android, Apple Color Emoji elsewhere.
///
/// ## Line height
///
/// Persian sets taller than Latin — the script has deep descenders and stacked
/// diacritics, and Vazirmatn is drawn generously. Every style here uses a
/// larger line height than the Latin equivalent would; at 1.2 the descenders of
/// one line touch the ascenders of the next, which is the single most common
/// way Persian typography is got wrong in an app built to Latin defaults.
abstract final class AppTypography {
  static const String fontFamily = 'Vazirmatn';

  /// Emoji and any glyph Vazirmatn lacks. Ordered by platform likelihood; the
  /// engine takes the first family that has the glyph and ignores the rest.
  static const List<String> fontFamilyFallback = <String>[
    'Segoe UI Emoji', // Windows
    'Noto Color Emoji', // Android, most Linux
    'Apple Color Emoji', // macOS, iOS
    'Segoe UI', // Windows Latin fallback
    'Roboto', // Android Latin fallback
  ];

  /// Digits that line up in a column.
  ///
  /// Without `tnum`, digit glyphs have proportional widths and a column of
  /// amounts in a table jitters left and right by a few pixels per row — which
  /// is exactly the kind of thing that makes a financial table feel unreliable
  /// without the reader being able to say why.
  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  // ---- page and section structure ----------------------------------------

  /// The page title. One per screen.
  static const TextStyle pageTitle = TextStyle(
    fontSize: 24,
    height: 1.45,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  /// A group heading inside a page: a card's title, a settings section.
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );

  /// The default. Everything that is prose.
  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.65,
    fontWeight: FontWeight.w400,
  );

  /// Body text that needs to stand out from the body around it — a customer's
  /// name in a list row, a field's value next to its label.
  static const TextStyle bodyStrong = TextStyle(
    fontSize: 15,
    height: 1.65,
    fontWeight: FontWeight.w500,
  );

  /// Secondary information: a date under a title, a hint under a field.
  /// A text field's label, and only that.
  ///
  /// **The one style in this scale with no line-height multiplier**, and the
  /// reason is Persian. Every other style here sets a generous `height` because
  /// the script needs the leading (see the note above). A `TextField` label is
  /// the opposite case: Material paints the floating label into a gap cut in
  /// the field's border, and it clips that gap to the label's reported line
  /// box. Give the label a 1.65 line box and the glyphs sit high inside it, the
  /// clip lands below their tops, and every ascender and every dot above a
  /// letter is sliced off -- legibly enough to read, wrongly enough to look
  /// broken. Leaving `height` unset uses Vazirmatn's own ascent and descent,
  /// which contain the glyphs exactly.
  ///
  /// Found by screenshotting the running form, like the two defects in
  /// increment (e); no test would have caught it.
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    height: 1.6,
    fontWeight: FontWeight.w400,
  );

  /// Field labels, table headers, badge text. Small, medium weight, and given
  /// a little tracking so it does not read as shrunken body text.
  static const TextStyle label = TextStyle(
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  // ---- money -------------------------------------------------------------

  /// **The prominent financial numeral style** (§10).
  ///
  /// The largest, heaviest thing on the surface it appears on, because §10
  /// requires the amount to be the most salient element on a card and because
  /// it is genuinely what the user came to read. Tight tracking keeps a long
  /// Rial figure from sprawling, and tabular figures keep it aligned.
  ///
  /// Note it carries no colour: money is rendered in the strongest neutral, not
  /// in the accent. Colour in this app means status, and an amount that was
  /// also accent-coloured would be competing with the badge beside it.
  static const TextStyle amountLarge = TextStyle(
    fontSize: 28,
    height: 1.35,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    fontFeatures: _tabular,
  );

  /// The amount on a list card — still the dominant element in its row.
  static const TextStyle amountMedium = TextStyle(
    fontSize: 19,
    height: 1.4,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    fontFeatures: _tabular,
  );

  /// An amount inside a dense table row or a secondary total.
  static const TextStyle amountSmall = TextStyle(
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  /// The unit label that always accompanies an amount (§9: never a bare
  /// number). Deliberately quiet — it is a constant, so it should not be read
  /// again on every row.
  static const TextStyle amountUnit = TextStyle(
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// Identifiers that must not be mistaken for prose or for money: invoice
  /// numbers, national IDs, phone numbers. Tabular so they align in a column.
  static const TextStyle identifier = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    fontFeatures: _tabular,
  );

  /// Assembles the Material text theme from the scale above.
  ///
  /// The mapping is deliberate rather than mechanical: Material's slots are
  /// what third-party and framework widgets read, so each one is pointed at the
  /// token that means the same thing here.
  static TextTheme textTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      displayLarge: amountLarge.copyWith(color: onSurface),
      displayMedium: amountMedium.copyWith(color: onSurface),
      displaySmall: amountSmall.copyWith(color: onSurface),
      headlineMedium: pageTitle.copyWith(color: onSurface),
      headlineSmall: pageTitle.copyWith(color: onSurface),
      titleLarge: pageTitle.copyWith(color: onSurface),
      titleMedium: sectionTitle.copyWith(color: onSurface),
      titleSmall: bodyStrong.copyWith(color: onSurface),
      bodyLarge: body.copyWith(color: onSurface),
      bodyMedium: body.copyWith(color: onSurface),
      bodySmall: caption.copyWith(color: onSurfaceVariant),
      labelLarge: bodyStrong.copyWith(color: onSurface),
      labelMedium: label.copyWith(color: onSurfaceVariant),
      labelSmall: label.copyWith(color: onSurfaceVariant),
    );
  }
}
