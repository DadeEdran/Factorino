import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// the project spec: *"No hardcoded colors, sizes, radii, or spacing inside
/// widgets. Everything comes from theme tokens."*
///
/// This is the rule most likely to erode quietly. Nothing breaks when someone
/// writes `EdgeInsets.all(14)` — it compiles, it looks fine in the one place
/// they were looking, and the next person copies it. A hundred screens later
/// the layout is subtly irregular in a way nobody can point at, and the
/// "design system" is a folder of constants nothing reads.
///
/// So the tokens are not merely available; using anything else fails the build.
///
/// **Escape hatch.** `// tokens-exempt: <reason>` on the line or in the comment
/// block directly above it. There are legitimate cases — a value that comes
/// from a framework API and is not a design decision — and the point is to make
/// them visible and justified rather than forbidden.
void main() {
  /// The token files themselves, which necessarily name raw values.
  const List<String> tokenSources = <String>[
    'lib/core/theme/app_colors.dart',
    'lib/core/theme/app_dimensions.dart',
    'lib/core/theme/app_typography.dart',
  ];

  const String exemption = 'tokens-exempt:';

  /// A literal colour, in any of the forms Dart offers.
  final RegExp literalColour = RegExp(
    r'(Color\(0x)|(Color\.fromARGB\()|(Color\.fromRGBO\()|'
    r'(?<![A-Za-z0-9_])Colors\.',
  );

  /// A bare number where a token belongs.
  ///
  /// Each alternative is anchored to the API that takes a design value, rather
  /// than looking for numbers generally — `itemCount: 3` and `maxLines: 2` are
  /// not design decisions and must not be flagged, or the guard becomes noise
  /// and someone turns it off.
  final RegExp literalDimension = RegExp(
    r'(EdgeInsets\.[A-Za-z]+\(\s*[\d.]+)|'
    r'(EdgeInsets\.[A-Za-z]+\([^)]*(?:left|top|right|bottom|horizontal|vertical):\s*[\d.]+)|'
    r'(BorderRadius\.circular\(\s*[\d.]+)|'
    r'(Radius\.circular\(\s*[\d.]+)|'
    r'(SizedBox\(\s*(?:height|width):\s*[\d.]+)|'
    r'(fontSize:\s*[\d.]+)|'
    r'(letterSpacing:\s*-?[\d.]+)|'
    r'(elevation:\s*[\d.]+)|'
    r'(BorderSide\([^)]*width:\s*[\d.]+)|'
    r'(Duration\(milliseconds:\s*[\d.]+)',
  );

  List<File> widgetSources() {
    return Directory('lib')
.listSync(recursive: true)
.whereType<File>()
.where((File file) => file.path.endsWith('.dart'))
.where((File file) {
          final String relative = file.path.replaceAll(r'\', '/');
          if (relative.endsWith('.g.dart')) return false;
          // Generated localizations are not hand-written UI.
          if (relative.contains('core/localization/generated/')) return false;
          return !tokenSources.contains(relative);
        })
.toList();
  }

  List<String> scan(RegExp pattern) {
    final List<String> offenders = <String>[];

    for (final File file in widgetSources()) {
      final String relative = file.path.replaceAll(r'\', '/');
      final List<String> lines = file.readAsLinesSync();

      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        if (line.contains(exemption)) continue;
        if (_precedingCommentBlock(lines, i).contains(exemption)) continue;

        // Comments describe values; they do not set them.
        final String code = _stripComments(line);
        if (!pattern.hasMatch(code)) continue;

        offenders.add('$relative:${i + 1}: ${line.trim()}');
      }
    }
    return offenders;
  }

  test('no literal colour outside the token files', () {
    expect(
      scan(literalColour),
      isEmpty,
      reason:
          'colour is defined once, in app_colors.dart, and read from the theme '
          'everywhere else. A literal here is a colour that will not follow '
          'dark mode.',
    );
  });

  test('no literal size, radius or spacing outside the token files', () {
    expect(
      scan(literalDimension),
      isEmpty,
      reason:
          'use AppSpacing / AppRadius / AppBorders / AppElevation / '
          'AppDuration. Scattered literals drift, and the result is a layout '
          'that is irregular in a way nobody can point at.',
    );
  });

  test('the token files exist and are what is being exempted', () {
    // Without this, renaming a token file would silently exempt nothing and
    // the scan above would start failing for the wrong reason -- or, worse,
    // the exemption list would keep matching a file that no longer exists.
    for (final String path in tokenSources) {
      expect(File(path).existsSync(), isTrue, reason: '$path is missing');
    }
  });

  test('the matchers would catch a real violation', () {
    // A guard that matches nothing passes for free.
    expect(literalColour.hasMatch('color: Color(0xFF00FF00),'), isTrue);
    expect(literalColour.hasMatch('color: Colors.red,'), isTrue);
    expect(literalColour.hasMatch('color: scheme.primary,'), isFalse);
    expect(
      literalColour.hasMatch('color: theme.colorScheme.onSurface,'),
      isFalse,
    );

    expect(
      literalDimension.hasMatch('padding: const EdgeInsets.all(14),'),
      isTrue,
    );
    expect(
      literalDimension.hasMatch('padding: EdgeInsets.symmetric(vertical: 8),'),
      isTrue,
    );
    expect(literalDimension.hasMatch('BorderRadius.circular(12)'), isTrue);
    expect(literalDimension.hasMatch('const SizedBox(height: 16)'), isTrue);
    expect(literalDimension.hasMatch('fontSize: 15,'), isTrue);

    // ...and would not fire on values that are not design decisions.
    expect(
      literalDimension.hasMatch(
        'padding: const EdgeInsets.all(AppSpacing.lg),',
      ),
      isFalse,
    );
    expect(
      literalDimension.hasMatch('const SizedBox(height: AppSpacing.xl)'),
      isFalse,
    );
    expect(literalDimension.hasMatch('itemCount: 3,'), isFalse);
    expect(literalDimension.hasMatch('maxLines: 2,'), isFalse);
    expect(literalDimension.hasMatch('final int index = 0;'), isFalse);
  });
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
