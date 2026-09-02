import 'dart:io';
import 'dart:typed_data';

import 'package:factorino/core/formatting/jalali_display.dart';
import 'package:factorino/core/formatting/persian_text.dart';
import 'package:factorino/core/pdf/document_text.dart';
import 'package:factorino/core/pdf/font_glyph_safety.dart';
import 'package:flutter_test/flutter_test.dart';

/// The view-model boundary: D-070 finding 1 and contract rule 1.
///
/// **What is being prevented.** The screen layer wraps invoice numbers, phone
/// numbers and national IDs in U+2068/U+2069 because §9 requires bidi isolation
/// on screen, where it is correct. The PDF shaper drops the **last character**
/// of a run containing one, silently: a ten-digit کد ملی prints nine digits and
/// still looks like a کد ملی.
///
/// The controls tested here are therefore not hypothetical. They are what
/// `isolate()` — the application's own formatter, exercised below rather than
/// imitated — puts on every identifier the document has to print.
void main() {
  late final FontGlyphSafety safety;
  late final DocumentTextBoundary boundary;

  setUpAll(() {
    final Uint8List bytes = File('assets/fonts/Vazirmatn-Regular.ttf')
        .readAsBytesSync();
    safety = FontGlyphSafety.parse(bytes);
    boundary = DocumentTextBoundary(safety);
  });

  group('the real formatters, not imitations of them', () {
    test('an isolated identifier crosses the boundary with its digits '
        'intact', () {
      const String nationalId = '0069543210';
      final String onScreen = formatIdentifierForDisplay(nationalId);

      // The control: the screen string really does carry what would break it.
      expect(onScreen.runes, contains(0x2068));
      expect(onScreen.runes, contains(0x2069));
      expect(boundary.wouldStrip(onScreen), isTrue);

      final DocumentText printed = boundary(onScreen);
      expect(printed.value.runes, isNot(contains(0x2068)));
      expect(printed.value.runes, isNot(contains(0x2069)));
      expect(
        printed.value,
        toPersianDigits(nationalId),
        reason: 'every digit must survive; the fault this guards drops one',
      );
      expect(printed.value.runes.length, 10);
    });

    test('an isolated invoice number keeps its full length', () {
      final String onScreen = isolate('INV-1405-0001');
      expect(boundary(onScreen).value, 'INV-1405-0001');
    });

    test('an isolated amount keeps its separators', () {
      final String onScreen = isolate(toPersianDigits('83,875,000'));
      final DocumentText printed = boundary(onScreen);
      expect(printed.value.contains(','), isTrue);
      expect(boundary.wouldStrip(printed.value), isFalse);
    });
  });

  group('what it removes', () {
    test('every rune it removes is one the renderer cannot draw correctly', () {
      for (final int rune in boundary.removedRunes) {
        final bool empty = safety.isUnsafe(rune);
        final bool unmapped = safety.glyphOf(rune) == null;
        expect(
          empty || unmapped,
          isTrue,
          reason:
              'U+${rune.toRadixString(16)} is removed but the font draws '
              'it correctly -- the boundary is deleting real text',
        );
      }
    });

    test('the removal set covers both faults', () {
      expect(boundary.removedRunes, containsAll(<int>[0x2068, 0x2069]));
      expect(boundary.removedRunes, containsAll(<int>[0x200E, 0x200F]));
      expect(boundary.removedRunes, containsAll(<int>[0x202A, 0x202E]));
    });

    test('and it is derived, so it grows with the font', () {
      // Everything empty in the bundled font is removed except the two
      // join-breakers. Stated as a relation rather than as a list, so a font
      // update cannot leave a stale constant behind.
      for (final int rune in safety.unsafeRunes) {
        expect(
          boundary.removedRunes.contains(rune),
          !DocumentTextBoundary.joinBreakers.contains(rune),
          reason: 'U+${rune.toRadixString(16)}',
        );
      }
    });
  });

  group('what it deliberately keeps', () {
    test('the ZWNJ survives, because SafeText needs it to know where to '
        'cut', () {
      final DocumentText printed = boundary('پیش‌نویس');
      expect(printed.value.runes, contains(0x200C));
      expect(printed.value, 'پیش‌نویس');
    });

    test('so does the zero-width space', () {
      expect(boundary('الف​ب').value.runes, contains(0x200B));
    });

    test('ordinary Persian is returned byte for byte', () {
      const String sentence = 'این فاکتور صادر شد';
      expect(boundary(sentence).value, sentence);
      expect(boundary.wouldStrip(sentence), isFalse);
    });

    test('a ZWJ is removed rather than cut, because it means the opposite', () {
      // ZWNJ says "do not join" and is honoured by cutting; ZWJ says "join",
      // which cutting would invert. It has an empty glyph either way, so it
      // cannot simply be passed through.
      expect(boundary('الف‍ب').value, 'الفب');
    });
  });

  group('rule 2 -- the label and the value are never one string', () {
    test('interpolating a DocumentText does not yield its text', () {
      // `'$label: $value'` is the shape D-070 finding 2 takes in Dart. It
      // cannot be forbidden by the compiler, so it is made loud: a page built
      // that way shows a wrapper, not a scrambled phone number that looks
      // almost right.
      final DocumentText value = boundary('۰۹۱۲۱۲۳۴۵۶۷');
      expect('$value', isNot(contains('۰۹۱۲')));
      expect('$value', startsWith('DocumentText('));
    });

    test('and equality is by text, so a view model can still be compared', () {
      expect(boundary('الف'), boundary('الف'));
      expect(boundary('الف'), isNot(boundary('ب')));
    });
  });
}
