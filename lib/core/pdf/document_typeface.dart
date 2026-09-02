import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'document_text.dart';
import 'font_glyph_safety.dart';
import 'safe_text.dart';

/// The fonts a document is drawn with, and the two safety layers derived from
/// the same bytes.
///
/// **They are derived from the same bytes on purpose.** `FontGlyphSafety`
/// answers "which runes does *this* font draw wrongly", and the answer is only
/// true of the file that is actually embedded. Loading the safety analysis from
/// one file and the glyphs from another would produce a guard that passes about
/// a font nobody is using — the shape D-072 calls a guard that cannot fail.
///
/// Only the regular and bold faces are carried. Vazirmatn-Medium is bundled for
/// the screen, where it separates a section title from body text at close
/// reading distance; a printed page has the whole sheet for hierarchy and does
/// not need a third weight to get it.
class DocumentTypeface {
  DocumentTypeface._(this.regular, this.bold, this.safety)
    : boundary = DocumentTextBoundary(safety),
      safe = SafeText(safety);

  /// Builds from the raw font files.
  ///
  /// Takes bytes rather than an asset path so this is constructible from a
  /// plain `dart run` as well as from the app — `tool/render_invoice.dart`
  /// drives the real generator, and a tool that had to boot Flutter to render
  /// a page would not get used.
  factory DocumentTypeface.fromBytes({
    required Uint8List regular,
    required Uint8List bold,
  }) {
    return DocumentTypeface._(
      pw.Font.ttf(ByteData.view(regular.buffer, regular.offsetInBytes)),
      pw.Font.ttf(ByteData.view(bold.buffer, bold.offsetInBytes)),
      FontGlyphSafety.parse(regular),
    );
  }

  final pw.Font regular;
  final pw.Font bold;

  /// Derived from the **regular** face, which draws almost every glyph on the
  /// page. A weight-specific difference in which glyphs are empty is possible
  /// in principle; `document_typeface_test.dart` asserts the two faces agree,
  /// so if it ever stops being true the suite says so rather than the page.
  final FontGlyphSafety safety;

  /// The only way to obtain text the renderer accepts.
  final DocumentTextBoundary boundary;

  /// Cuts what the boundary deliberately kept.
  final SafeText safe;
}
