import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:factorino/core/pdf/document_text.dart';
import 'package:factorino/core/pdf/font_glyph_safety.dart';
import 'package:factorino/core/pdf/safe_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

/// D-070 requirement 2, as a test rather than a probe: **every** string the
/// application ships, not a handful of hand-picked ones.
///
/// The probe that found this checked 68 entries once, on a machine, in a
/// scratchpad that no longer exists. That is evidence, not coverage — the
/// next string somebody adds to the ARB is the one this has to catch, and
/// «پیش‌نویس» was in the ARB for five phases before anybody rendered it.
///
/// **What it asserts is the class rule, not the character.** An entry fails if
/// it shapes to any rune whose glyph is empty in the bundled font, whatever
/// that rune turns out to be. Written as "contains a ZWNJ" it would pass a
/// string containing a ZWJ, and pass entirely on a font update that moved the
/// set.
void main() {
  const String arbPath = 'lib/core/localization/arb/app_fa.arb';

  late final FontGlyphSafety safety;
  late final SafeText safe;
  late final DocumentTextBoundary boundary;
  late final pw.TextStyle style;
  late final Map<String, String> messages;

  setUpAll(() {
    final Uint8List bytes = File('assets/fonts/Vazirmatn-Regular.ttf')
        .readAsBytesSync();
    safety = FontGlyphSafety.parse(bytes);
    safe = SafeText(safety);
    boundary = DocumentTextBoundary(safety);
    style = pw.TextStyle(
      font: pw.Font.ttf(ByteData.view(bytes.buffer)),
      fontSize: 10,
    );

    final Map<String, dynamic> arb =
        jsonDecode(File(arbPath).readAsStringSync()) as Map<String, dynamic>;
    messages = <String, String>{
      for (final MapEntry<String, dynamic> entry in arb.entries)
        if (!entry.key.startsWith('@') && entry.value is String)
          entry.key: entry.value as String,
    };
  });

  /// Everything the span tree would hand to the shaper, flattened.
  List<String> drawnOf(List<pw.InlineSpan> spans) {
    final List<String> out = <String>[];
    void walk(pw.InlineSpan span) {
      if (span is pw.TextSpan) {
        if (span.text != null) out.add(span.text!);
        span.children?.forEach(walk);
      } else if (span is pw.WidgetSpan && span.child is pw.Row) {
        for (final pw.Widget piece in (span.child as pw.Row).children) {
          if (piece is pw.Text) out.add(piece.text.toPlainText());
        }
      }
    }

    spans.forEach(walk);
    return out;
  }

  test('the ARB is where it is expected and is not empty', () {
    // The existence control. A renamed file or a changed layout would
    // otherwise turn this whole sweep into a loop over nothing.
    expect(File(arbPath).existsSync(), isTrue);
    expect(messages.length, greaterThan(300));
  });

  test('the sweep has something to find -- entries do carry unsafe runes', () {
    // If this ever reports zero, the sweep below is vacuous and the failure is
    // in the sweep, not in the ARB. Recorded as 68 of 356 on 2026-09-02.
    final Iterable<String> affected = messages.entries
        .where((MapEntry<String, String> e) => safety.hasUnsafeRune(e.value))
        .map((MapEntry<String, String> e) => e.key);
    expect(
      affected,
      isNotEmpty,
      reason:
          'no ARB entry contains a rune with an empty glyph, which would '
          'make this sweep prove nothing -- check FontGlyphSafety first',
    );
  });

  test('every ARB entry is unsafe through a plain span', () {
    // The negative control for the sweep: the strings that carry a control
    // really would print a wrong glyph if they went through the renderer as
    // written. Without this, "0 failures" below could mean the remedy works
    // or could mean nothing was ever at risk.
    final List<String> atRisk = <String>[];
    for (final MapEntry<String, String> entry in messages.entries) {
      if (safety.hasUnsafeRune(entry.value)) atRisk.add(entry.key);
    }
    expect(atRisk, isNotEmpty);

    for (final String key in atRisk) {
      expect(
        safety.hasUnsafeRune(messages[key]!),
        isTrue,
        reason: '$key would print a glyph that is not its own',
      );
    }
  });

  test('no ARB entry keeps an unsafe rune through SafeText', () {
    final List<String> offenders = <String>[];

    for (final MapEntry<String, String> entry in messages.entries) {
      final List<String> drawn = drawnOf(
        safe.spansOf(boundary(entry.value), style: style),
      );
      for (final String piece in drawn) {
        if (safety.hasUnsafeRune(piece)) {
          offenders.add(
            '${entry.key}: ${piece.runes.where(safety.isUnsafe).map((int r) => 'U+${r.toRadixString(16).toUpperCase()}').join(', ')}',
          );
          break;
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these ARB entries would still print a wrong glyph:\n'
          '${offenders.join('\n')}',
    );
  });

  test('and no ARB entry loses a visible character on the way', () {
    // The other half. Deleting the whole string would also pass the test
    // above; what must be gone is exactly the unsafe runes and nothing else.
    for (final MapEntry<String, String> entry in messages.entries) {
      final String rebuilt = drawnOf(
        safe.spansOf(boundary(entry.value), style: style),
      ).join();
      final String expected = String.fromCharCodes(
        entry.value.runes.where((int r) => !safety.isUnsafe(r)),
      );
      expect(
        rebuilt,
        expected,
        reason: '${entry.key} lost or gained characters',
      );
    }
  });
}
