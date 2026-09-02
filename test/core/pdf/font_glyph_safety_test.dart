import 'dart:io';
import 'dart:typed_data';

import 'package:factorino/core/pdf/font_glyph_safety.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/font/ttf_parser.dart';

/// The D-073 class guard, and the controls that keep it falsifiable.
///
/// **What is being guarded.** `package:pdf`'s `TtfParser.readGlyph(i)` reads a
/// glyph's outline at `glyphOffsets[i]` without checking whether that equals
/// `glyphOffsets[i + 1]`. For a zero-length glyph the address it reads is where
/// the **next** glyph begins, so the character draws a different letter — at
/// zero advance width, so nothing about the layout looks wrong. In Vazirmatn,
/// U+200C draws `à`.
///
/// **Why it needs three controls rather than one assertion.** A guard whose
/// subject cannot fail it is not a guard (D-072). This one has three ways to
/// go quietly wrong, and each has a test:
///
/// 1. it could derive an **empty** set — from a parse failure, a renamed
///    table, a font with no `loca` — and then report every string clean;
/// 2. it could derive a set that **disagrees with the renderer**, because the
///    rune-to-glyph mapping is the package's business and this file parses the
///    font independently on purpose;
/// 3. its `hasUnsafeRune` could stop firing, and the ARB sweep next door would
///    pass on strings that are about to print a Latin `à`.
void main() {
  late final Uint8List regularBytes;
  late final FontGlyphSafety safety;

  setUpAll(() {
    regularBytes = File('assets/fonts/Vazirmatn-Regular.ttf').readAsBytesSync();
    safety = FontGlyphSafety.parse(regularBytes);
  });

  group('the derivation', () {
    test('finds the zero-width controls in the bundled font', () {
      // The existence control. If the parse silently produced nothing, every
      // other assertion in this file and in the ARB sweep would pass.
      expect(safety.unsafeRunes, isNotEmpty);
      expect(
        safety.unsafeRunes,
        containsAll(<int>[
          0x200C, // ZERO WIDTH NON-JOINER   -- draws à
          0x200D, // ZERO WIDTH JOINER       -- draws ₪
          0x200E, // LEFT-TO-RIGHT MARK      -- draws ₪
          0x200F, // RIGHT-TO-LEFT MARK      -- draws ₪
        ]),
      );
    });

    test('and finds members no hand-written list contained', () {
      // The argument for deriving rather than listing, stated as a test. Every
      // account of this fault so far -- D-070, D-072, D-073 -- named the four
      // above. The font also condemns ZWSP and the five bidi embedding and
      // override controls, none of which anybody thought to write down.
      expect(
        safety.unsafeRunes,
        containsAll(<int>[
          0x200B, // ZERO WIDTH SPACE
          0x202A, // LEFT-TO-RIGHT EMBEDDING
          0x202B, // RIGHT-TO-LEFT EMBEDDING
          0x202C, // POP DIRECTIONAL FORMATTING
          0x202D, // LEFT-TO-RIGHT OVERRIDE
          0x202E, // RIGHT-TO-LEFT OVERRIDE
        ]),
      );
    });

    test('U+2068 and U+2069 are a different fault and are not in this set', () {
      // D-070 finding 1: the isolates are ABSENT from Vazirmatn's cmap, not
      // empty in it. They fall back to `.notdef`, which is itself empty, so
      // they are just as dangerous -- but cutting the run does not fix them,
      // and pretending it did would let them through the view-model boundary
      // that actually strips them.
      expect(safety.glyphOf(0x2068), isNull);
      expect(safety.glyphOf(0x2069), isNull);
      expect(safety.isUnsafe(0x2068), isFalse);
    });

    test('does not condemn the space, which the renderer never draws', () {
      // RichText splits every span on RegExp(r'\s') and advances the pen for
      // the empty pieces, so a whitespace glyph is never read. Condemning it
      // would make the text builder delete the spaces out of every sentence.
      expect(safety.isUnsafe(0x20), isFalse);
      expect(safety.isUnsafe(0x0A), isFalse);
      expect(safety.glyphLength(safety.glyphOf(0x20)!), 0);
    });

    test('does not condemn ordinary Persian letters', () {
      for (final int rune in 'پیشنویسفاکتور۰۹'.runes) {
        expect(
          safety.isUnsafe(rune),
          isFalse,
          reason: 'U+${rune.toRadixString(16)} is a letter and has an outline',
        );
      }
    });

    test('reads the vertical metrics it places an atom with', () {
      expect(safety.unitsPerEm, greaterThan(0));
      expect(safety.descender, lessThan(0));
      expect(safety.descentEm, inExclusiveRange(-1.0, 0.0));
    });

    test('fails loudly on a font it cannot answer for', () {
      // Not a silent empty set: a truncated or non-TrueType font must throw,
      // because a safety set that came back empty would clear every string.
      expect(
        () =>
            FontGlyphSafety.parse(Uint8List.fromList(List<int>.filled(64, 0))),
        throwsA(anything),
      );
    });
  });

  group('cross-check against the renderer that has the fault', () {
    // This is the control for "the two parsers agree". The production code
    // deliberately does NOT read the font through package:pdf -- a guard
    // derived from the thing it guards agrees with it by construction -- so
    // the agreement has to be asserted here instead of assumed.
    late final TtfParser parsed;

    setUpAll(() {
      parsed = TtfParser(ByteData.view(regularBytes.buffer));
    });

    test('every rune we condemn really selects an empty glyph in the package '
        'parser too', () {
      for (final int rune in safety.unsafeRunes) {
        final int? glyph = parsed.charToGlyphIndexMap[rune];
        expect(
          glyph,
          isNotNull,
          reason: 'U+${rune.toRadixString(16)} unmapped by package:pdf',
        );
        expect(
          parsed.glyphOffsets[glyph! + 1] - parsed.glyphOffsets[glyph],
          0,
          reason: 'U+${rune.toRadixString(16)} is not empty to package:pdf',
        );
      }
    });

    test('and the mapping agrees on every rune the renderer knows', () {
      // Not a sampled comparison and not a threshold somebody guessed: every
      // rune package:pdf maps must map identically here. Measured 2026-09-02,
      // the package's map holds 811 runes and this covers all 811 -- so the
      // coverage claim is `unknown.isEmpty`, which cannot quietly shrink.
      final List<String> disagreements = <String>[];
      final List<String> unknown = <String>[];

      parsed.charToGlyphIndexMap.forEach((int rune, int glyph) {
        final int? ours = safety.glyphOf(rune);
        if (ours == null) {
          unknown.add('U+${rune.toRadixString(16)}');
        } else if (ours != glyph) {
          disagreements.add('U+${rune.toRadixString(16)}: $ours vs $glyph');
        }
      });

      expect(parsed.charToGlyphIndexMap, isNotEmpty);
      expect(
        unknown,
        isEmpty,
        reason:
            'the renderer maps runes this guard has never heard of, so '
            'the guard is watching a different font from the one that draws',
      );
      expect(
        disagreements,
        isEmpty,
        reason: 'the two parsers disagree: ${disagreements.take(5).join(', ')}',
      );
    });

    test('the fault itself is still present in the package we pinned', () {
      // The subject control. If a future `pdf` fixes readGlyph, this fails --
      // which is the signal to reconsider the whole remedy rather than carry
      // a workaround for a bug that no longer exists.
      final int zwnj = parsed.charToGlyphIndexMap[0x200C]!;
      final TtfGlyphInfo empty = parsed.readGlyph(zwnj);
      final TtfGlyphInfo next = parsed.readGlyph(zwnj + 1);

      expect(
        parsed.glyphOffsets[zwnj + 1] - parsed.glyphOffsets[zwnj],
        0,
        reason: 'the ZWNJ glyph should have no outline of its own',
      );
      expect(
        empty.data,
        next.data,
        reason:
            'readGlyph should still be returning the NEXT glyph for an '
            'empty one; if this fails, package:pdf has fixed D-073',
      );
      expect(empty.data, isNotEmpty);
    });
  });

  group('the negative control -- the guard must be able to fire', () {
    test('a raw ZWNJ is reported unsafe', () {
      expect(safety.hasUnsafeRune('پیش‌نویس'), isTrue);
    });

    test('the same word without it is not', () {
      expect(safety.hasUnsafeRune('پیشنویس'), isFalse);
    });

    test('an ordinary Persian sentence is not', () {
      expect(safety.hasUnsafeRune('این فاکتور صادر شد'), isFalse);
    });
  });
}
