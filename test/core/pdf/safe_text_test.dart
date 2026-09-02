import 'dart:io';
import 'dart:typed_data';

import 'package:factorino/core/pdf/document_text.dart';
import 'package:factorino/core/pdf/font_glyph_safety.dart';
import 'package:factorino/core/pdf/safe_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

/// [SafeText]'s contract, at the level a unit test can reach.
///
/// What a unit test **cannot** settle is what the page looks like — whether ش
/// keeps its final form and ن its initial one, whether the pieces sit in the
/// right order and whether a word survives a line break. Those were read off
/// rendered pages (D-073) and the ARB sweep next door re-asserts the machine
/// half over every string the application ships. This file asserts the shape:
/// that the control character never survives, that only the word carrying it
/// becomes indivisible, and that the ordinary case is left alone.
void main() {
  late final SafeText safe;
  late final DocumentTextBoundary boundary;
  late final pw.TextStyle style;

  setUpAll(() {
    final Uint8List bytes = File('assets/fonts/Vazirmatn-Regular.ttf')
        .readAsBytesSync();
    final FontGlyphSafety safety = FontGlyphSafety.parse(bytes);
    safe = SafeText(safety);
    boundary = DocumentTextBoundary(safety);
    style = pw.TextStyle(
      font: pw.Font.ttf(ByteData.view(bytes.buffer)),
      fontSize: 10,
    );
  });

  /// Every string a span tree would hand to the shaper.
  List<String> textOf(List<pw.InlineSpan> spans) {
    final List<String> out = <String>[];
    void walk(pw.InlineSpan span) {
      if (span is pw.TextSpan) {
        if (span.text != null) out.add(span.text!);
        span.children?.forEach(walk);
      } else if (span is pw.WidgetSpan) {
        final pw.Widget child = span.child;
        if (child is pw.Row) {
          for (final pw.Widget piece in child.children) {
            if (piece is pw.Text) out.add(piece.text.toPlainText());
          }
        }
      }
    }

    spans.forEach(walk);
    return out;
  }

  group('the ordinary case is untouched', () {
    test('a string with no unsafe rune is one plain span', () {
      final List<pw.InlineSpan> spans = safe.spansOf(
        boundary('این فاکتور صادر شد'),
        style: style,
      );
      expect(spans, hasLength(1));
      expect(spans.single, isA<pw.TextSpan>());
      expect(textOf(spans), <String>['این فاکتور صادر شد']);
    });

    test('an empty string is one plain span', () {
      expect(safe.spansOf(boundary(''), style: style), hasLength(1));
    });
  });

  group('a word carrying the control', () {
    test('becomes an indivisible box, and the control does not survive', () {
      final List<pw.InlineSpan> spans = safe.spansOf(
        boundary('پیش‌نویس'),
        style: style,
      );
      expect(spans.whereType<pw.WidgetSpan>(), hasLength(1));
      expect(textOf(spans), <String>['پیش', 'نویس']);
      for (final String piece in textOf(spans)) {
        expect(safe.safety.hasUnsafeRune(piece), isFalse);
      }
    });

    test('keeps its pieces in logical order', () {
      // Reversing them looks obviously right for RTL and renders «نویس‌پیش»:
      // pw.Row has no textDirection and the line's mirroring does not reach
      // inside a WidgetSpan child.
      expect(textOf(safe.spansOf(boundary('پیش‌نویس'), style: style)), <String>[
        'پیش',
        'نویس',
      ]);
    });

    test('a word with two controls yields three pieces', () {
      expect(
        textOf(safe.spansOf(boundary('می‌خواهم‌بروم'), style: style)),
        <String>['می', 'خواهم', 'بروم'],
      );
    });

    test('drops to a plain span when cutting leaves one piece', () {
      // A control at an edge joins nothing, so there is no atom to build --
      // and building a one-child Row would make the word indivisible for no
      // reason.
      final List<pw.InlineSpan> spans = safe.spansOf(
        boundary('نویس‌'),
        style: style,
      );
      expect(spans.whereType<pw.WidgetSpan>(), isEmpty);
      expect(textOf(spans), <String>['نویس']);
    });
  });

  group('only that word becomes indivisible', () {
    test('the rest of the sentence stays ordinary, wrappable text', () {
      final List<pw.InlineSpan> spans = safe.spansOf(
        boundary('این فاکتور پیش‌نویس است'),
        style: style,
      );
      expect(spans.whereType<pw.WidgetSpan>(), hasLength(1));
      expect(textOf(spans), <String>['این فاکتور ', 'پیش', 'نویس', ' است']);
    });

    test('the spaces around it are preserved exactly', () {
      // The renderer's own word handling has to see them: a lost space is a
      // run of two words joined, which reads as a different sentence.
      final String source = 'الف‌ب  ج\nد';
      final String rebuilt = textOf(
        safe.spansOf(boundary(source), style: style),
      ).join();
      expect(rebuilt, source.replaceAll('‌', ''));
    });

    test('two atoms in one sentence stay separate', () {
      final List<pw.InlineSpan> spans = safe.spansOf(
        boundary('پرداخت‌نشده و پیش‌نویس'),
        style: style,
      );
      expect(spans.whereType<pw.WidgetSpan>(), hasLength(2));
    });
  });

  group('the atom is placed on the text baseline', () {
    test('by the font descent, not by a tuned constant', () {
      final pw.WidgetSpan atom = safe
          .spansOf(boundary('پیش‌نویس'), style: style)
          .whereType<pw.WidgetSpan>()
          .single;
      expect(atom.baseline, style.fontSize! * safe.safety.descentEm);
      expect(atom.baseline, lessThan(0));
    });
  });

  group('paragraph()', () {
    test('carries the same spans into a RichText', () {
      final pw.Widget widget = safe.paragraph(
        boundary('پیش‌نویس'),
        style: style,
      );
      expect(widget, isA<pw.RichText>());
      final pw.RichText rich = widget as pw.RichText;
      expect(textOf(<pw.InlineSpan>[rich.text]), <String>['پیش', 'نویس']);
    });
  });
}
