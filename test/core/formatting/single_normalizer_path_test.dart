import 'dart:io';

import 'package:factorino/core/formatting/persian_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// D-025 rests on one thing: the value written into `search_name` and the term
/// queried against it are produced by **the same function**.
///
/// Two call sites that normalize almost the same way do not fail loudly. The
/// write succeeds, the index builds, the query runs, and a customer the user
/// saved yesterday is simply not found -- with no error anywhere to explain it.
/// Nobody discovers that by testing the two sides separately, because each one
/// is individually correct.
///
/// So the single path is enforced structurally here, the way the database
/// opener is by `single_open_path_test.dart`, rather than left to whoever
/// writes the repository in increment (d):
///
/// 1. nothing in `lib/` outside `core/formatting/` may open-code a character
///    fold of its own, and
/// 2. anything touching `searchName` must go through [searchKey].
///
/// **Escape hatch.** Mark a deliberate exception `// normalizer-exempt: <why>`
/// on the line or in the comment block directly above it. The point is not to
/// forbid the raw form; it is to make using it a visible, justified choice.
void main() {
  const normalizerDirectory = 'lib/core/formatting/';
  const exemption = 'normalizer-exempt:';

  /// Code points that only a hand-rolled normalizer would need to name: the
  /// three digit sets' zeros, the letter pairs §9 folds, and ZWNJ.
  ///
  /// Written as escapes so this list is reviewable -- several of the glyphs are
  /// invisible or indistinguishable from one another in a source file.
  const foldDomain = <int>{
    0x06F0, // EXTENDED ARABIC-INDIC DIGIT ZERO (Persian digits)
    0x0660, // ARABIC-INDIC DIGIT ZERO
    0x064A, // ARABIC LETTER YEH
    0x06CC, // FARSI YEH
    0x0643, // ARABIC LETTER KAF
    0x06A9, // KEHEH
    0x200C, // ZERO WIDTH NON-JOINER
  };

  /// The same characters as they would be written in Dart source escapes or as
  /// integer literals -- the other two ways to spell a fold table.
  final escapedFoldDomain = RegExp(
    r'''(\\u\{?0?6[0-9A-Fa-f]{2}\}?)|(0x06[0-9A-Fa-f]{2})|(\\u\{?200[Cc]\}?)|(0x200[Cc])''',
  );

  List<File> librarySources({required bool excludeNormalizer}) {
    return Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) {
          final relative = file.path.replaceAll(r'\', '/');
          if (relative.endsWith('.g.dart')) return false;
          if (excludeNormalizer && relative.contains(normalizerDirectory)) {
            return false;
          }
          return true;
        })
        .toList();
  }

  test('no second normalizer: nothing outside core/formatting/ folds characters', () {
    final offenders = <String>[];

    for (final file in librarySources(excludeNormalizer: true)) {
      final relative = file.path.replaceAll(r'\', '/');
      final lines = file.readAsLinesSync();

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains(exemption)) continue;
        if (_precedingCommentBlock(lines, i).contains(exemption)) continue;

        // Comments are scanned out first. Persian belongs in documentation --
        // naming کد ملی in a doc comment is describing a field, not folding a
        // character -- and a comment cannot execute a fold in any case. Only
        // code can, so only code is checked.
        final code = _stripComments(line);
        final hasRawGlyph = code.runes.any(foldDomain.contains);
        final hasEscape = escapedFoldDomain.hasMatch(code);
        if (!hasRawGlyph && !hasEscape) continue;

        offenders.add('$relative:${i + 1}: ${line.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these lines name characters that only a normalizer needs. A second '
          'normalizer drifts from the first, and the symptom is a search that '
          'silently stops matching. Call searchKey / normalizePersianDigits '
          'instead, or mark the line "// $exemption <reason>":\n'
          '${offenders.join('\n')}',
    );
  });

  test('every search_name call site goes through searchKey', () {
    // Vacuous today -- repositories arrive in increment (d) -- and that is the
    // point: the rule is in place before the first call site, exactly as the
    // single-open-path rule was written before any repository opened a
    // database.
    const columnName = 'searchName';
    const tableDirectory = 'lib/data/database/tables/';
    final offenders = <String>[];

    for (final file in librarySources(excludeNormalizer: true)) {
      final relative = file.path.replaceAll(r'\', '/');
      // The table definitions declare the column; they do not write to it.
      if (relative.contains(tableDirectory)) continue;

      final source = file.readAsStringSync();
      if (!source.contains(columnName)) continue;
      if (source.contains(exemption)) continue;
      if (source.contains('searchKey(')) continue;

      offenders.add(relative);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these files reference $columnName without calling searchKey. The '
          'stored value and the query term must come from the same function '
          'or the index stops matching (D-025):\n${offenders.join('\n')}',
    );
  });

  test('the normalizer is where this test expects it to be', () {
    // Keeps both tests above from passing vacuously after a move or a rename.
    final source = File('${normalizerDirectory}persian_text.dart')
        .readAsStringSync();

    expect(source, contains('String searchKey('));
    expect(source, contains('String normalizePersianDigits('));
  });

  test('the scan would catch a real second normalizer', () {
    // A matcher that never fires is worse than no matcher. These are the two
    // shapes a hand-rolled fold actually takes.
    final rawGlyphLine = "if (c == 'ي') return 'ی';";
    final escapedLine = r"if (c == 0x064A) return 0x06CC;";

    expect(
      rawGlyphLine.runes.any(foldDomain.contains),
      isTrue,
      reason: 'the raw-glyph scan must fire on a hand-rolled fold',
    );
    expect(
      escapedFoldDomain.hasMatch(escapedLine),
      isTrue,
      reason: 'the escape scan must fire on a code-point fold',
    );
    // ...and must not fire on ordinary code.
    expect(escapedFoldDomain.hasMatch('final total = 0x1F + count;'), isFalse);

    // The comment-stripping must not become a hole: a fold on a line that also
    // carries a trailing comment still has to be caught.
    expect(
      _stripComments(r"if (c == 0x064A) return 0x06CC; // fold the yeh")
          .contains('0x064A'),
      isTrue,
    );
    // ...while a doc comment naming a Persian field is left alone.
    expect(_stripComments('/// کد ملی — optional.').trim(), isEmpty);
  });

  test('searchKey is exported under the name the guard checks for', () {
    // The guard matches on the literal text "searchKey(". If the function were
    // renamed, the guard would go quiet rather than fail, so this ties the
    // string to the real symbol.
    expect(searchKey('test'), isNotNull);
  });
}

/// [line] with any comment removed, leaving only what the compiler sees.
///
/// Deliberately naive about `//` inside a string literal: cutting a line early
/// can only make this scan miss something, never make it fire wrongly, and no
/// line that contains a URL also contains a character fold. A false positive
/// here would push someone toward suppressing the guard, which is the failure
/// worth avoiding.
String _stripComments(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('///') ||
      trimmed.startsWith('//') ||
      trimmed.startsWith('*') ||
      trimmed.startsWith('/*')) {
    return '';
  }
  final commentStart = line.indexOf('//');
  return commentStart == -1 ? line : line.substring(0, commentStart);
}

/// The contiguous run of `//` comment lines directly above [index].
String _precedingCommentBlock(List<String> lines, int index) {
  final buffer = StringBuffer();
  for (var i = index - 1; i >= 0; i--) {
    final trimmed = lines[i].trim();
    if (!trimmed.startsWith('//')) break;
    buffer.writeln(trimmed);
  }
  return buffer.toString();
}
