import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// the project spec: *"Enforce field-level limits (length, character class) on
/// customer/product free-text fields."*
///
/// [AppTextField] makes `maxLength` a required parameter, so a field cannot be
/// added without a limit — that half is enforced by the compiler. This file
/// enforces the two halves the compiler cannot:
///
/// 1. **Nothing in `lib/` builds a raw text field.** A `TextFormField` written
///    directly has no limit, no character class and no length validator, and
///    it looks exactly like every other field on the screen. That is the whole
///    failure mode: it is not wrong until someone types a long name.
/// 2. **The limit is a shared constant, never a bare number.** A literal
///    `maxLength: 120` beside a column declared `withLength(max: 120)` is two
///    numbers that agree today. The one that gets changed is the column, and
///    nothing anywhere fails — the form simply starts accepting values the
///    database will refuse, for the users who type long names.
///
/// The same treatment as the single database opener (D-020), the single
/// normalizer (D-029) and the logging wrapper (D-035), for the same reason:
/// **the failure is silent**, so review is the only thing that could catch it,
/// and review is what missed it for all of Phase 1.
///
/// **Escape hatch.** `// field-limit-exempt: <reason>` on the line or in the
/// comment block directly above it.
void main() {
  const String wrapperPath = 'lib/core/widgets/app_text_field.dart';
  const String limitsPath = 'lib/data/models/field_limits.dart';
  const String exemption = 'field-limit-exempt:';

  /// A text field built without going through the wrapper.
  ///
  /// `TextField` as well as `TextFormField`: the first has no validator at all,
  /// which is a worse version of the same problem rather than an exception to
  /// it.
  final RegExp rawTextField = RegExp(
    r'(?<![A-Za-z0-9_.$])(TextFormField|TextField)\s*\(',
  );

  /// `maxLength:` followed by anything that is not a `*Limits.` reference.
  ///
  /// Written to match the argument rather than the absence of one, because the
  /// absence is already impossible — the parameter is required.
  final RegExp maxLengthArgument = RegExp(r'maxLength:\s*([^,)\n]+)');
  final RegExp sharedConstant = RegExp(r'^[A-Za-z]*Limits\.[A-Za-z]');

  List<File> librarySources() {
    return Directory('lib')
.listSync(recursive: true)
.whereType<File>()
.where((File file) => file.path.endsWith('.dart'))
.where((File file) {
          final String relative = file.path.replaceAll(r'\', '/');
          if (relative.endsWith('.g.dart')) return false;
          if (relative.contains('core/localization/generated/')) return false;
          return true;
        })
.toList();
  }

  test('nothing in lib/ builds a text field except the wrapper', () {
    final List<String> offenders = <String>[];

    for (final File file in librarySources()) {
      final String relative = file.path.replaceAll(r'\', '/');
      if (relative == wrapperPath) continue;

      final List<String> lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        if (line.contains(exemption)) continue;
        if (_precedingCommentBlock(lines, i).contains(exemption)) continue;

        final String code = _stripComments(line);
        if (!rawTextField.hasMatch(code)) continue;

        offenders.add('$relative:${i + 1}: ${line.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these lines build a text field that carries no length limit, no '
          'character class and no length validator. Use AppTextField, whose '
          'maxLength is required, or mark the line '
          '"// $exemption <reason>":\n${offenders.join('\n')}',
    );
  });

  test('every maxLength is a shared constant, not a literal', () {
    final List<String> offenders = <String>[];

    for (final File file in librarySources()) {
      final String relative = file.path.replaceAll(r'\', '/');
      // The wrapper declares the parameter and passes it through; it never
      // chooses a value.
      if (relative == wrapperPath) continue;

      final List<String> lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        if (line.contains(exemption)) continue;
        if (_precedingCommentBlock(lines, i).contains(exemption)) continue;

        final String code = _stripComments(line);
        final RegExpMatch? match = maxLengthArgument.firstMatch(code);
        if (match == null) continue;

        final String argument = match.group(1)!.trim();
        if (sharedConstant.hasMatch(argument)) continue;

        offenders.add('$relative:${i + 1}: maxLength: $argument');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a form limit written as a number is a second copy of the column '
          'limit, and the copy that gets updated is never the one in the '
          'form. Name it in $limitsPath and reference it, so the two cannot '
          'disagree:\n${offenders.join('\n')}',
    );
  });

  test('the shared limits are where the other tests expect them', () {
    // Keeps both scans from passing vacuously after a move or a rename.
    expect(File(wrapperPath).existsSync(), isTrue, reason: wrapperPath);
    expect(File(limitsPath).existsSync(), isTrue, reason: limitsPath);
  });

  test('both scans would catch a real violation', () {
    // A matcher that never fires passes for free. Every line below is a
    // plausible thing to write, which is the point.
    expect(rawTextField.hasMatch('    TextFormField('), isTrue);
    expect(rawTextField.hasMatch('child: TextField(controller: c),'), isTrue);
    // ...and must not fire on the wrapper, or on a type name that merely ends
    // in the same letters.
    expect(rawTextField.hasMatch('    AppTextField('), isFalse);
    expect(rawTextField.hasMatch('find.byType(TextFormField)'), isFalse);

    String? argumentOf(String line) =>
        maxLengthArgument.firstMatch(line)?.group(1)?.trim();

    expect(argumentOf('maxLength: 120,'), '120');
    expect(sharedConstant.hasMatch('120'), isFalse);
    expect(
      argumentOf('maxLength: CustomerLimits.fullName,'),
      'CustomerLimits.fullName',
    );
    expect(sharedConstant.hasMatch('CustomerLimits.fullName'), isTrue);
    expect(sharedConstant.hasMatch('AmountLimits.tomanDigits'), isTrue);
    // A local variable is not a shared constant either -- it could hold
    // anything, which is exactly what this scan is about.
    expect(sharedConstant.hasMatch('limit'), isFalse);
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
