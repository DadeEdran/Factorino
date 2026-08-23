import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// the project spec: *"There must be zero English user-facing text... but all
/// strings must go through the localization layer from day one — never hardcode
/// a Persian literal inside a widget."*
///
/// The second half is the one that needs enforcing. Hardcoding a Persian string
/// in a widget is not a bug — it renders correctly, in the right language, and
/// looks completely finished. It only becomes a problem later, all at once: the
/// day a second locale is added, or a wording decision has to be applied
/// consistently, or someone needs to check every user-facing string against a
/// rule like D-030's. At that point the strings are scattered across fifty
/// widgets and the localization layer is a fiction.
///
/// So: **no Arabic-script character may appear in code anywhere in `lib/`.**
/// Comments are exempt — describing a Persian field in a doc comment is
/// documentation — and so is `core/localization/`, which is where the strings
/// legitimately live.
///
/// **Escape hatch.** `// l10n-exempt: <reason>` on the line or in the comment
/// block directly above it.
void main() {
  const String localizationDirectory = 'lib/core/localization/';
  const String exemption = 'l10n-exempt:';

  /// The Unicode ranges Persian is written in.
  ///
  /// Arabic (0600–06FF) covers the letters and the Persian digits; the
  /// presentation-forms blocks cover text pasted from sources that use the
  /// legacy shaped codepoints, which is common when copying out of older
  /// Iranian software.
  bool isPersianScript(int rune) {
    return (rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0xFB50 && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF);
  }

  List<File> librarySources() {
    return Directory('lib')
.listSync(recursive: true)
.whereType<File>()
.where((File file) => file.path.endsWith('.dart'))
.where((File file) {
          final String relative = file.path.replaceAll(r'\', '/');
          if (relative.endsWith('.g.dart')) return false;
          return !relative.contains(localizationDirectory);
        })
.toList();
  }

  test('no Persian literal in code outside the localization layer', () {
    final List<String> offenders = <String>[];

    for (final File file in librarySources()) {
      final String relative = file.path.replaceAll(r'\', '/');
      final List<String> lines = file.readAsLinesSync();

      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        if (line.contains(exemption)) continue;
        if (_precedingCommentBlock(lines, i).contains(exemption)) continue;

        final String code = _stripComments(line);
        if (!code.runes.any(isPersianScript)) continue;

        offenders.add('$relative:${i + 1}: ${line.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these lines hold Persian text in code. Add the string to '
          'lib/core/localization/arb/app_fa.arb and read it from AppStrings, '
          'so every user-facing word is in one reviewable place (§1):\n'
          '${offenders.join('\n')}',
    );
  });

  test('the localization layer is where the strings actually are', () {
    // Keeps the test above from passing because the ARB file vanished or the
    // generated output moved.
    final File arb = File('lib/core/localization/arb/app_fa.arb');
    expect(arb.existsSync(), isTrue);

    final String source = arb.readAsStringSync();
    expect(source.runes.any(isPersianScript), isTrue);
    expect(source, contains('"@@locale": "fa"'));

    expect(
      File('lib/core/localization/generated/app_strings.dart').existsSync(),
      isTrue,
      reason: 'run `flutter gen-l10n` and commit the result',
    );
  });

  test('D-030: the national-ID copy states a format, never an identity', () {
    // The constraint the owner set, checked against the Persian itself rather
    // than trusted to survive in a decision log. If someone later "improves"
    // this string to say the ID is confirmed, this fails.
    final String arb = File('lib/core/localization/arb/app_fa.arb')
.readAsStringSync();

    expect(arb, contains('"nationalIdFormatValid"'));

    // «فرمت کد ملی معتبر است» -- the format is valid.
    expect(arb, contains('فرمت'), reason: 'the copy must name the format');

    // None of the words that would turn a checksum into a claim about identity.
    for (final String forbidden in <String>[
      'تأیید',
      'تایید',
      'صحیح',
      'احراز',
    ]) {
      expect(
        arb.contains('"nationalIdFormatValid": "') &&
            _valueOf(arb, 'nationalIdFormatValid').contains(forbidden),
        isFalse,
        reason:
            'D-030: a passing checksum is not a verified identity, and the '
            'copy must not say it is. Found "$forbidden".',
      );
    }
  });

  test('the matcher would catch a real hardcoded string', () {
    // Guards the guard.
    expect("const Text('سلام')".runes.any(isPersianScript), isTrue);
    expect("const Text('hello')".runes.any(isPersianScript), isFalse);
    expect(_stripComments('/// یک توضیح').trim(), isEmpty);
    expect(
      _stripComments("const Text('سلام'); // توضیح").runes.any(isPersianScript),
      isTrue,
    );
  });
}

/// The value of [key] in the ARB source.
String _valueOf(String arb, String key) {
  final RegExp pattern = RegExp('"$key"\\s*:\\s*"([^"]*)"');
  return pattern.firstMatch(arb)?.group(1) ?? '';
}

/// [line] with any comment removed, leaving only what the compiler sees.
String _stripComments(String line) {
  final String trimmed = line.trimLeft();
  if (trimmed.startsWith('///') ||
      trimmed.startsWith('//') ||
      trimmed.startsWith('*') ||
      trimmed.startsWith('/*')) {
    return '';
  }
  final int commentStart = line.indexOf('//');
  return commentStart == -1 ? line : line.substring(0, commentStart);
}

/// The contiguous run of `//` comment lines directly above [index].
String _precedingCommentBlock(List<String> lines, int index) {
  final StringBuffer buffer = StringBuffer();
  for (int i = index - 1; i >= 0; i--) {
    final String trimmed = lines[i].trim();
    if (!trimmed.startsWith('//')) break;
    buffer.writeln(trimmed);
  }
  return buffer.toString();
}
