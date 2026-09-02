import 'package:pdf/widgets.dart' as pw;

import 'document_text.dart';
import 'font_glyph_safety.dart';

/// Builds document text that cannot trigger D-073's wrong-glyph fault.
///
/// ## What it does, and why that is the whole remedy
///
/// A zero-width control's only job in Persian is to stop two letters joining.
/// The renderer's shaper — `bidi.logicalToVisual`, applied **once per span** —
/// gives a letter its final form when nothing joinable follows it in the same
/// span. So a span that simply *ends* breaks the join exactly as a ZWNJ does,
/// and costs no character:
///
/// ```
/// 'پیش‌نویس' as one span -> FEB2 FBFE FEEE FEE7 [200C] FEB6 FBFF FB58
/// 'پیش'      alone       ->                            FEB6 FBFF FB58
/// 'نویس'     alone       -> FEB2 FBFE FEEE FEE7
/// ```
///
/// Identical shaping — ش in final form, ن in initial form — with the control
/// character gone. Nothing is substituted for it, because every zero-width
/// candidate is in the same hazard class: `FontGlyphSafety` derives that class
/// from the font, and in Vazirmatn it is U+200C, U+200D, U+200E and U+200F.
///
/// ## Why a `WidgetSpan` and not simply two `TextSpan`s
///
/// Two spans produce correct glyphs and correct order, and introduce a fault
/// of their own: the renderer may end a line between them, splitting a word
/// across two lines at its half-space. Measured at seven column widths, a bare
/// split broke «پیش‌نویس» at four of them. That is a defect traded for a
/// defect — «پیش» and «نویس» on separate lines is as wrong as «پیشنویس», just
/// less obviously.
///
/// A `WidgetSpan` is laid out as one indivisible box, so the word travels
/// whole and wraps to the next line rather than through the middle. Only words
/// that actually contain an unsafe rune become atoms; everything around them
/// stays ordinary text and wraps normally.
///
/// **The pieces go in logical order inside the [pw.Row].** `pw.Row` takes no
/// `textDirection` argument, which invites the conclusion that it lays out
/// left to right and that RTL therefore needs the pieces reversed. It does
/// not: `Flex.layout` reads `Directionality.of(context)` and starts from the
/// right on an RTL page, so logical order is already correct and reversing
/// renders «نویس‌پیش». Verified on a rendered page before and after, because
/// the wrong version also looks deliberate.
///
/// ## Why it takes [DocumentText] and not [String]
///
/// This class answers the font fault. It does **not** answer D-070 finding 1,
/// where a bidi isolate the screen layer added makes the shaper drop the last
/// character of a run — those characters are absent from Vazirmatn rather than
/// empty in it, so nothing derived from `loca` will ever see them. That is
/// [DocumentTextBoundary]'s job, and requiring its output here is what stops
/// the two remedies being applied in only one of the places that needs both.
class SafeText {
  const SafeText(this.safety);

  /// Derived from the same font bytes the document embeds.
  final FontGlyphSafety safety;

  /// [document] as spans, safe to place inside a larger paragraph.
  ///
  /// The common case allocates nothing extra: a string with no unsafe rune
  /// comes back as a single [pw.TextSpan].
  List<pw.InlineSpan> spansOf(
    DocumentText document, {
    required pw.TextStyle style,
  }) {
    final String text = document.value;
    if (!safety.hasUnsafeRune(text)) {
      return <pw.InlineSpan>[pw.TextSpan(text: text, style: style)];
    }

    final List<pw.InlineSpan> spans = <pw.InlineSpan>[];
    final StringBuffer plain = StringBuffer();

    void flush() {
      if (plain.isEmpty) return;
      spans.add(pw.TextSpan(text: plain.toString(), style: style));
      plain.clear();
    }

    for (final String token in _tokens(text)) {
      if (!safety.hasUnsafeRune(token)) {
        plain.write(token);
        continue;
      }
      flush();
      spans.add(_atom(token, style));
    }
    flush();
    return spans;
  }

  /// [document] as a paragraph widget.
  ///
  /// The direction is left to the surrounding [pw.Directionality] — the page
  /// is RTL and every string this renders is Persian, so overriding it per
  /// widget would only create places for the two to disagree.
  pw.Widget paragraph(
    DocumentText document, {
    required pw.TextStyle style,
    pw.TextAlign? textAlign,
    int? maxLines,
  }) {
    return pw.RichText(
      text: pw.TextSpan(
        style: style,
        children: spansOf(document, style: style),
      ),
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }

  /// One word that contains at least one unsafe rune, as an indivisible box.
  ///
  /// Falls back to a plain span where cutting leaves a single piece — a string
  /// that is *only* control characters, or one where the control sits at an
  /// edge and joins nothing.
  pw.InlineSpan _atom(String word, pw.TextStyle style) {
    final List<String> pieces = _cut(word);
    if (pieces.isEmpty) {
      return pw.TextSpan(text: '', style: style);
    }
    if (pieces.length == 1) {
      return pw.TextSpan(text: pieces.single, style: style);
    }

    return pw.WidgetSpan(
      style: style,
      // A WidgetSpan is placed by its box and the text around it by its
      // baseline; dropping the box by the font's descent is what puts the two
      // on one line. Read from the font, not tuned by eye.
      baseline: (style.fontSize ?? 0) * safety.descentEm,
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: <pw.Widget>[
          for (final String piece in pieces) pw.Text(piece, style: style),
        ],
      ),
    );
  }

  /// [word] split at every unsafe rune, which is dropped.
  List<String> _cut(String word) {
    final List<String> pieces = <String>[];
    final StringBuffer piece = StringBuffer();
    for (final int rune in word.runes) {
      if (safety.isUnsafe(rune)) {
        if (piece.isNotEmpty) {
          pieces.add(piece.toString());
          piece.clear();
        }
        continue;
      }
      piece.writeCharCode(rune);
    }
    if (piece.isNotEmpty) pieces.add(piece.toString());
    return pieces;
  }

  /// [text] as alternating whitespace and non-whitespace runs.
  ///
  /// Splitting on whitespace rather than on the unsafe runes directly is what
  /// keeps ordinary wrapping intact: only the word carrying the control
  /// becomes an atom, and the spaces around it stay inside neighbouring text
  /// spans where the renderer's own word handling can see them.
  static List<String> _tokens(String text) {
    final List<String> tokens = <String>[];
    final StringBuffer run = StringBuffer();
    bool? runIsSpace;

    for (final int rune in text.runes) {
      final bool isSpace = _whitespace.hasMatch(String.fromCharCode(rune));
      if (runIsSpace != null && isSpace != runIsSpace) {
        tokens.add(run.toString());
        run.clear();
      }
      runIsSpace = isSpace;
      run.writeCharCode(rune);
    }
    if (run.isNotEmpty) tokens.add(run.toString());
    return tokens;
  }

  static final RegExp _whitespace = RegExp(r'\s');
}
