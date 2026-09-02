// Renders sample pages through the application's own SafeText, so a human can
// look at them.
//
// `dart run tool/render_document_text.dart [outputDirectory]`
//
// WHY THIS EXISTS
//
// Everything a unit test can assert about D-073's remedy is about span shapes
// and code units. The questions that actually decide whether the document is
// deliverable are not: does ش keep its final form, does ن keep its initial
// one, do the pieces sit in the right order, does the word survive a line
// break, and does the atom sit on the same baseline as the text beside it.
// Those are answered by rendering the page and looking at it.
//
// It imports `SafeText` and `FontGlyphSafety` directly rather than
// reconstructing them, because a probe that rebuilds the thing it is checking
// is a second implementation with its own faults (D-072's corollary). That is
// also why `core/pdf/font_glyph_safety.dart` carries no Flutter import: it
// keeps this runnable as plain Dart.
//
// Rasterise the output with `tools/pdf_raster/` and read the pixels.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:factorino/core/pdf/document_text.dart';
import 'package:factorino/core/pdf/font_glyph_safety.dart';
import 'package:factorino/core/pdf/safe_text.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const String _fontPath = 'assets/fonts/Vazirmatn-Regular.ttf';

Future<void> main(List<String> args) async {
  final Directory out = Directory(
    args.isNotEmpty ? args.first : 'build/document_text',
  )..createSync(recursive: true);

  final Uint8List bytes = File(_fontPath).readAsBytesSync();
  final FontGlyphSafety safety = FontGlyphSafety.parse(bytes);
  final SafeText safe = SafeText(safety);
  final DocumentTextBoundary boundary = DocumentTextBoundary(safety);
  final pw.Font font = pw.Font.ttf(ByteData.view(bytes.buffer));

  stdout.writeln(
    'font: unitsPerEm=${safety.unitsPerEm} '
    'descender=${safety.descender} descentEm=${safety.descentEm}',
  );
  stdout.writeln(
    'unsafe runes: ${safety.unsafeRunes.map((int r) => 'U+'
        '${r.toRadixString(16).toUpperCase().padLeft(4, '0')}').join(' ')}',
  );

  pw.TextStyle style(double size) =>
      pw.TextStyle(font: font, fontSize: size, lineSpacing: 4);

  Future<void> write(String name, pw.Widget body) async {
    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) => body,
      ),
    );
    final File file = File('${out.path}/$name.pdf');
    await file.writeAsBytes(await doc.save());
    stdout.writeln('wrote ${file.path}');
  }

  // 1. The baseline question. The same word through SafeText and as a plain
  //    pw.Text, stacked, so a vertical offset between the atom and ordinary
  //    text is visible as a step rather than having to be judged in isolation.
  await write(
    'baseline',
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        for (final double size in <double>[9, 12, 18, 28])
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: safe.paragraph(
              boundary('قبل پیش‌نویس بعد'),
              style: style(size),
            ),
          ),
      ],
    ),
  );

  // 2. The line-break question, at widths that bracket the fold.
  await write(
    'wrap',
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        for (final double width in <double>[150, 120, 100, 85, 70, 60])
          pw.Container(
            width: width,
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            ),
            child: safe.paragraph(
              boundary('فاکتور پیش‌نویس است'),
              style: style(14),
            ),
          ),
      ],
    ),
  );

  // 3. Every ARB string that carries an unsafe rune, through the real builder.
  final List<String> affected = _arbStringsWithUnsafeRunes(safety);
  stdout.writeln('ARB strings carrying an unsafe rune: ${affected.length}');
  await write(
    'arb',
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        for (final String message in affected.take(34))
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: safe.paragraph(boundary(message), style: style(9)),
          ),
      ],
    ),
  );
}

/// The ARB's messages: top-level entries whose key does not start with `@`.
///
/// Parsed rather than pattern-matched. A first version scanned lines for
/// `"key": "value"` and reported 73 affected strings against the sweep test's
/// 68, because it was also matching the `"description"` fields inside the
/// `@key` metadata blocks — Persian prose that the application never renders.
/// A five-string disagreement in a tool nobody would think to check is exactly
/// how a probe starts certifying a number the real path never produces.
List<String> _arbStringsWithUnsafeRunes(FontGlyphSafety safety) {
  final Map<String, dynamic> arb = jsonDecode(
    File('lib/core/localization/arb/app_fa.arb').readAsStringSync(),
  ) as Map<String, dynamic>;

  return <String>[
    for (final MapEntry<String, dynamic> entry in arb.entries)
      if (!entry.key.startsWith('@') &&
          entry.value is String &&
          safety.hasUnsafeRune(entry.value as String))
        entry.value as String,
  ];
}
