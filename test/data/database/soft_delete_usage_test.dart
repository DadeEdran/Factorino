import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// the project spec requires one query helper for `deleted_at IS NULL` "so this
/// cannot be forgotten per-call-site". A helper nobody is obliged to use is
/// still forgettable, so this test is the obligation.
///
/// Forgetting it does not surface as an error: the query succeeds and returns
/// rows the user deleted. For a customer list that is confusing; for an
/// invoice total or a dashboard figure it is wrong money.
///
/// **Escape hatch.** Some reads legitimately bypass the helper -- the sync
/// layer must see tombstones, a restore screen must list deleted rows, and
/// bootstrap runs `select 1`. Mark those lines with `// soft-delete-exempt:`
/// and a reason. The point is not to forbid the raw form, it is to make using
/// it a visible, justified choice.
void main() {
  /// Defines the helper itself, so it necessarily contains the raw calls.
  const helper = 'lib/data/database/soft_delete.dart';

  final rawQuery = RegExp(r'(?<![A-Za-z0-9_])(select|customSelect)\s*\(');
  const exemption = 'soft-delete-exempt:';

  test('no unexplained raw select() in lib/', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final relative = entity.path.replaceAll(r'\', '/');
      // Generated code is drift's own and is not a call site anyone reviews.
      if (relative == helper || relative.endsWith('.g.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!rawQuery.hasMatch(line)) continue;
        if (line.contains(exemption)) continue;
        // The marker may sit anywhere in the comment block immediately above
        // the call, so a reason long enough to be useful can wrap.
        if (_precedingCommentBlock(lines, i).contains(exemption)) continue;

        offenders.add('$relative:${i + 1}: ${line.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these reads bypass selectAlive/countAlive and will return rows the '
          'user deleted. Use the helper, or mark the line '
          '"// $exemption <reason>" if the raw form is deliberate:\n'
          '${offenders.join('\n')}',
    );
  });

  test('the helper is where it is expected to be', () {
    // Keeps the test above from passing vacuously after a rename.
    final source = File(helper).readAsStringSync();
    expect(source, contains('selectAlive'));
    expect(source, contains('countAlive'));
    expect(source, contains(kDeletedAtLiteral));
  });
}

/// Spelled out rather than imported, so that renaming the constant in the
/// production code cannot silently change what this test checks for.
const String kDeletedAtLiteral = 'deleted_at';

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
