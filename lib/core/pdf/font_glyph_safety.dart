import 'dart:typed_data';

/// Which runes are unsafe to hand to the PDF renderer, **derived from the
/// bundled font** rather than listed (D-073).
///
/// ## The fault this exists to contain
///
/// `TtfParser.readGlyph(i)` in `package:pdf` computes the glyph's start as
/// `glyfTableOffset + glyphOffsets[i]` and parses an outline there. It never
/// checks whether the glyph is empty — whether `glyphOffsets[i]` equals
/// `glyphOffsets[i + 1]`. For a zero-length glyph that start address is where
/// the **next** glyph begins, so the reader returns *that* glyph's outline
/// under this glyph's index.
///
/// In Vazirmatn the consequences are:
///
/// | rune | its glyph | what actually draws |
/// |---|---|---|
/// | U+200C ZWNJ | 322, empty | glyph 323 — `à` |
/// | U+200D ZWJ | 320, empty | glyph 321 — `₪` |
/// | U+200E LRM | 319, empty | glyph 321 — `₪` |
/// | U+200F RLM | 318, empty | glyph 321 — `₪` |
///
/// The advance width stays zero, so the wrong letter is drawn *on top of* its
/// neighbours without disturbing the layout — no overflow, no error, and a
/// result that looks like a word.
///
/// ## Why this is derived and not a constant
///
/// A list of four characters is right for exactly one font. Vazirmatn can be
/// updated, a second family can be bundled for a second weight, and either
/// would silently move the set — a constant would then be wrong in the
/// direction that renders a wrong letter rather than the direction that fails
/// a test. So the set is computed by reading `loca` and `cmap` out of the font
/// bytes the application actually ships, at the moment it ships them.
///
/// ## Why this parses the font itself rather than reusing the package's parser
///
/// This is a guard against `package:pdf`'s own reading of the font. Deriving it
/// *from* that reading would make the guard agree with the thing it is
/// watching by construction — D-072's "a guard that cannot fail". The
/// cross-check runs the other way instead: `font_glyph_safety_test.dart`
/// compares this set against `package:pdf`'s `TtfParser` over the runes the
/// application actually renders, so a disagreement between the two parsers is
/// itself a failure.
///
/// This file is **pure Dart with no Flutter import**, for the same reason
/// `core/money/` is: the question it answers is about bytes, and keeping it
/// callable from a plain `dart run` is what lets `tool/render_document_text.dart`
/// exercise the real production code when a page has to be looked at.
///
/// Only the four tables that answer the question are read: `head` for the
/// `loca` format, `maxp` for the glyph count, `loca` for the lengths, and
/// `cmap` for the rune mapping.
class FontGlyphSafety {
  FontGlyphSafety._(
    this._glyphOfRune,
    this._glyphLengths,
    this.unitsPerEm,
    this.descender,
  );

  /// The font's design grid, from `head`.
  final int unitsPerEm;

  /// The font's descender in design units, from `hhea`. Negative.
  final int descender;

  /// The descender as a fraction of the em, which is the units a text style
  /// expresses its size in. Negative.
  ///
  /// Needed because a `WidgetSpan` is positioned by its **box**, while the text
  /// around it is positioned by its **baseline**: dropping the box by the
  /// descent is what puts the two on the same line. Read from the font rather
  /// than tuned by eye, for the same reason the unsafe set is derived rather
  /// than listed.
  double get descentEm => descender / unitsPerEm;

  /// Every rune the font maps, to the glyph it selects.
  final Map<int, int> _glyphOfRune;

  /// `_glyphLengths[g]` is the byte length of glyph `g`'s own outline. Zero
  /// means the glyph has no outline of its own — the dangerous case.
  final List<int> _glyphLengths;

  /// Reads [fontBytes] and derives the mapping.
  ///
  /// Throws [FormatException] on a font this cannot answer for — a CFF-outline
  /// font has no `glyf`/`loca` and the analysis below does not apply to it.
  /// Failing loudly is deliberate: a safety set that silently came back empty
  /// would report every string clean.
  factory FontGlyphSafety.parse(Uint8List fontBytes) {
    final ByteData bytes = ByteData.view(
      fontBytes.buffer,
      fontBytes.offsetInBytes,
      fontBytes.lengthInBytes,
    );
    final Map<String, int> tables = _tableDirectory(bytes);

    for (final String required in <String>[
      'head',
      'maxp',
      'loca',
      'cmap',
      'hhea',
    ]) {
      if (!tables.containsKey(required)) {
        throw FormatException(
          'the font has no "$required" table, so its empty glyphs cannot be '
          'identified; see FontGlyphSafety',
        );
      }
    }

    final int indexToLocFormat = bytes.getInt16(tables['head']! + 50);
    final int numGlyphs = bytes.getUint16(tables['maxp']! + 4);
    final List<int> offsets = _locaOffsets(
      bytes,
      tables['loca']!,
      numGlyphs,
      indexToLocFormat,
    );

    final List<int> lengths = List<int>.generate(
      numGlyphs,
      (int g) => offsets[g + 1] - offsets[g],
      growable: false,
    );

    return FontGlyphSafety._(
      _cmap(bytes, tables['cmap']!),
      lengths,
      bytes.getUint16(tables['head']! + 18),
      bytes.getInt16(tables['hhea']! + 12),
    );
  }

  /// The runes that would draw the wrong glyph, in ascending order.
  ///
  /// Whitespace is excluded, and the exclusion is not a convenience: the
  /// renderer never hands a whitespace rune to the font at all. `RichText`
  /// splits every span on `\n` and then on `RegExp(r'\s')`, and advances the
  /// pen by a space width for the empty pieces — so a space's glyph is never
  /// read, empty or not. `TtfWriter` additionally special-cases `char == 32`
  /// and substitutes a genuinely empty glyph for it.
  ///
  /// That exclusion is also the reason this fault survived so long: U+0020 has
  /// an empty glyph in most fonts, and it renders correctly, which makes
  /// "empty glyphs are fine, look at spaces" a natural and wrong conclusion.
  Iterable<int> get unsafeRunes => _unsafeRunes;

  late final List<int> _unsafeRunes = () {
    final List<int> found = <int>[];
    _glyphOfRune.forEach((int rune, int glyph) {
      if (_isNeverDrawn(rune)) return;
      if (glyph >= _glyphLengths.length) return;
      if (_glyphLengths[glyph] == 0) found.add(rune);
    });
    found.sort();
    return List<int>.unmodifiable(found);
  }();

  late final Set<int> _unsafeSet = Set<int>.unmodifiable(_unsafeRunes);

  /// Whether [rune] would draw a glyph that is not its own.
  bool isUnsafe(int rune) => _unsafeSet.contains(rune);

  /// Whether any rune of [text] is unsafe. The question the guard asks.
  bool hasUnsafeRune(String text) => text.runes.any(isUnsafe);

  /// The glyph [rune] selects, or `null` where the font does not map it.
  ///
  /// An unmapped rune is a **different** fault — the renderer falls back to
  /// `.notdef`, which is itself empty and therefore also draws the wrong glyph
  /// — but it is not one this class can fix by cutting the run, so it is
  /// reported separately rather than folded in here.
  int? glyphOf(int rune) => _glyphOfRune[rune];

  /// The byte length of glyph [glyph]'s own outline; `0` means it has none.
  int glyphLength(int glyph) =>
      glyph >= 0 && glyph < _glyphLengths.length ? _glyphLengths[glyph] : 0;

  int get glyphCount => _glyphLengths.length;

  /// Runes the renderer resolves before any glyph lookup happens.
  static bool _isNeverDrawn(int rune) =>
      rune < 0x10000 && _whitespace.hasMatch(String.fromCharCode(rune));

  /// Dart's `\s`, which is what `RichText` splits words on.
  static final RegExp _whitespace = RegExp(r'\s');

  static Map<String, int> _tableDirectory(ByteData bytes) {
    final int numTables = bytes.getUint16(4);
    final Map<String, int> tables = <String, int>{};
    for (int i = 0; i < numTables; i++) {
      final int record = 12 + i * 16;
      final String tag = String.fromCharCodes(<int>[
        bytes.getUint8(record),
        bytes.getUint8(record + 1),
        bytes.getUint8(record + 2),
        bytes.getUint8(record + 3),
      ]);
      tables[tag] = bytes.getUint32(record + 8);
    }
    return tables;
  }

  static List<int> _locaOffsets(
    ByteData bytes,
    int loca,
    int numGlyphs,
    int indexToLocFormat,
  ) {
    return List<int>.generate(
      numGlyphs + 1,
      (int i) => indexToLocFormat == 0
          ? bytes.getUint16(loca + i * 2) * 2
          : bytes.getUint32(loca + i * 4),
      growable: false,
    );
  }

  /// The Unicode character map, preferring a format 12 subtable over format 4.
  ///
  /// Both are parsed and merged, format 12 last, because a font may map a rune
  /// in one and not the other and the renderer will find it in either.
  static Map<int, int> _cmap(ByteData bytes, int cmap) {
    final int numSubtables = bytes.getUint16(cmap + 2);
    final Map<int, int> merged = <int, int>{};
    final List<int> format12 = <int>[];
    final List<int> format4 = <int>[];

    for (int i = 0; i < numSubtables; i++) {
      final int record = cmap + 4 + i * 8;
      final int platform = bytes.getUint16(record);
      final int encoding = bytes.getUint16(record + 2);
      final int offset = cmap + bytes.getUint32(record + 4);

      final bool unicode =
          platform == 0 || (platform == 3 && (encoding == 1 || encoding == 10));
      if (!unicode) continue;

      switch (bytes.getUint16(offset)) {
        case 4:
          format4.add(offset);
        case 12:
          format12.add(offset);
      }
    }

    for (final int offset in format4) {
      _parseFormat4(bytes, offset, merged);
    }
    for (final int offset in format12) {
      _parseFormat12(bytes, offset, merged);
    }
    return merged;
  }

  static void _parseFormat4(ByteData bytes, int base, Map<int, int> into) {
    final int segCount = bytes.getUint16(base + 6) ~/ 2;
    final int endCodes = base + 14;
    final int startCodes = endCodes + segCount * 2 + 2;
    final int idDeltas = startCodes + segCount * 2;
    final int idRangeOffsets = idDeltas + segCount * 2;

    for (int s = 0; s < segCount; s++) {
      final int end = bytes.getUint16(endCodes + s * 2);
      final int start = bytes.getUint16(startCodes + s * 2);
      if (start > end) continue;
      final int delta = bytes.getUint16(idDeltas + s * 2);
      final int rangeOffset = bytes.getUint16(idRangeOffsets + s * 2);

      for (int c = start; c <= end && c != 0xFFFF; c++) {
        final int glyph;
        if (rangeOffset == 0) {
          glyph = (delta + c) % 65536;
        } else {
          final int address =
              idRangeOffsets + s * 2 + rangeOffset + (c - start) * 2;
          glyph = bytes.getUint16(address);
        }
        if (glyph != 0) into[c] = glyph;
      }
    }
  }

  static void _parseFormat12(ByteData bytes, int base, Map<int, int> into) {
    final int groups = bytes.getUint32(base + 12);
    for (int i = 0; i < groups; i++) {
      final int group = base + 16 + i * 12;
      final int start = bytes.getUint32(group);
      final int end = bytes.getUint32(group + 4);
      final int startGlyph = bytes.getUint32(group + 8);
      for (int c = start; c <= end; c++) {
        final int glyph = startGlyph + (c - start);
        if (glyph != 0) into[c] = glyph;
      }
    }
  }
}
