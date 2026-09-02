import 'font_glyph_safety.dart';

/// A string that has crossed the view-model boundary and is fit to print.
///
/// ## Why this is a type and not a function
///
/// The screen layer and the document layer want *different* strings from the
/// same data, and the difference is invisible. `formatIdentifierForDisplay`
/// returns a کد ملی wrapped in U+2068/U+2069 because §9 requires bidi isolation
/// **on screen**, where it is correct and necessary. Passed to the PDF
/// renderer, the same string prints **nine of its ten digits**: Vazirmatn has
/// no glyph for either isolate and the shaper drops the last character of a run
/// containing one (D-070 finding 1). The loss is silent and the result is
/// plausible — a national ID nobody can tell is wrong by looking at it, on a
/// document a customer reconciles by hand.
///
/// A `stripControls(...)` helper would fix that only where somebody remembered
/// to call it. A type fixes it at the only door: [SafeText] accepts nothing
/// else, so a raw `String` from the screen layer cannot reach the renderer at
/// all.
///
/// ## What it removes, and what it deliberately keeps
///
/// The removal set is **derived from the bundled font** — every rune whose
/// glyph is empty, because those draw a different letter entirely (D-073) —
/// **minus the join-breakers**, which are the two characters in that set that
/// mean something to Persian:
///
/// | kept | why |
/// |---|---|
/// | U+200C ZWNJ | «پیش‌نویس» is not «پیشنویس». [SafeText] cuts the run here. |
/// | U+200B ZWSP | a break opportunity that also breaks the join. Same. |
///
/// Everything else in the set is directional formatting the document has no
/// use for: LRM, RLM, the embedding and override controls, ZWJ, and NUL.
///
/// **That two-character exception cannot be derived from the font**, and is the
/// one hardcoded list here. It is a fact about Unicode semantics — which
/// characters mean "do not join" — not about which glyphs happen to be empty,
/// and no amount of reading `loca` will produce it.
///
/// The bidi isolates are added on top of the derived set, because in Vazirmatn
/// they are a **different** fault: U+2068 and U+2069 are absent from the `cmap`
/// entirely rather than empty in it, so a font-derived set never mentions them.
/// They are the ones that eat a character, and they are the ones the screen
/// layer actually produces.
final class DocumentText {
  const DocumentText._(this.value);

  /// The text as the renderer will receive it.
  ///
  /// Reading this is fine. Joining two of them into one string is the mistake
  /// [DocumentText] exists to make hard — see the note on rule 2 below.
  final String value;

  /// Whether anything is left to draw.
  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;

  /// Renders [toString] useless for interpolation, on purpose.
  ///
  /// **D-070's contract rule 2: the label and the value are separate widgets,
  /// never concatenated into one string.** That rule is what makes finding 2
  /// disappear instead of needing a remedy — every field measured in probe 3
  /// renders correctly bare, and scrambles only when it shares one run with its
  /// own Persian label. `'تلفن: ' + number` is the whole bug.
  ///
  /// `'$label: $value'` is the shape that mistake takes in Dart, and it is one
  /// keystroke away at every call site. Returning a wrapper rather than the
  /// text means that if somebody writes it, the page shows
  /// `DocumentText(...)` — wrong immediately and in the proof, rather than
  /// wrong subtly and only for values containing a `+` or a space.
  @override
  String toString() => 'DocumentText(${value.length} chars)';

  @override
  bool operator ==(Object other) =>
      other is DocumentText && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Turns screen-layer strings into printable ones.
///
/// Holds the font's derived unsafe set, so the strip list moves when the
/// bundled font moves.
final class DocumentTextBoundary {
  DocumentTextBoundary(this.safety);

  final FontGlyphSafety safety;

  /// The two members of the font's unsafe set that carry meaning in Persian
  /// and are therefore cut rather than deleted. See the class doc above for
  /// why this cannot be derived.
  // normalizer-exempt: this is not a normalizer and must not become one.
  // `searchKey` folds these away so that «علي» finds «علی» -- it is answering
  // "are these the same name?". This set answers "which characters must the
  // renderer be told to cut rather than delete?", and the two sets are
  // deliberately different: the normalizer drops the ZWNJ, and a document that
  // dropped it would print «پیشنویس».
  static const Set<int> joinBreakers = <int>{
    // normalizer-exempt: cut by the renderer, never folded away; see above.
    0x200C, // ZERO WIDTH NON-JOINER
    0x200B, // ZERO WIDTH SPACE
  };

  /// Directional controls Vazirmatn does not map at all, so a font-derived
  /// set cannot see them. These are D-070 finding 1's characters: the ones the
  /// screen layer produces and the shaper truncates a run for.
  // normalizer-exempt: see joinBreakers above. These are removed because
  // Vazirmatn has no glyph for them and the shaper eats a character of any run
  // containing one (D-070 finding 1), not because they are equivalent to
  // anything.
  static const Set<int> unmappedDirectionalControls = <int>{
    // normalizer-exempt: removed because the font cannot draw it, not
    // because it is equivalent to anything; see above.
    0x061C, // ARABIC LETTER MARK
    0x2066, // LEFT-TO-RIGHT ISOLATE
    0x2067, // RIGHT-TO-LEFT ISOLATE
    0x2068, // FIRST STRONG ISOLATE   -- `isolate()` writes this
    0x2069, // POP DIRECTIONAL ISOLATE -- and this
  };

  late final Set<int> _removed = <int>{
    ...safety.unsafeRunes.where((int r) => !joinBreakers.contains(r)),
    ...unmappedDirectionalControls,
  };

  /// Every rune this boundary deletes. Exposed so a guard can assert over it
  /// rather than restating it.
  Set<int> get removedRunes => Set<int>.unmodifiable(_removed);

  /// [raw] with the controls removed and nothing else changed.
  DocumentText call(String raw) {
    if (!raw.runes.any(_removed.contains)) return DocumentText._(raw);
    return DocumentText._(
      String.fromCharCodes(raw.runes.where((int r) => !_removed.contains(r))),
    );
  }

  /// Whether [raw] would lose anything crossing the boundary. For guards and
  /// for diagnostics that must not quote the text itself.
  bool wouldStrip(String raw) => raw.runes.any(_removed.contains);
}
