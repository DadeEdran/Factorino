import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// the project spec requires one query helper for `deleted_at IS NULL` "so this
/// cannot be forgotten per-call-site". A helper nobody is obliged to use is
/// still forgettable, so this test is the obligation.
///
/// `selectOnly` is covered as well as `select`. Aggregates are the easier of
/// the two to get wrong: no rows are materialised, so a sum that quietly
/// includes deleted invoices looks exactly like one that does not -- it is just
/// a larger number on a dashboard.
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

  final rawQuery = RegExp(
    r'(?<![A-Za-z0-9_])(select|customSelect|selectOnly)\s*\(',
  );

  /// Riverpod's `provider.select((value) => value.field)`, which is **not** a
  /// database read and is the narrowing the project spec asks for by name.
  ///
  /// It cannot be excluded by the lookbehind: drift's own `_db.select(table)`
  /// is preceded by a dot too, and that is the main form this test exists to
  /// catch. What separates them is the argument -- a provider selector is
  /// handed a function literal, so `select(` is immediately followed by `(`,
  /// and a drift select is handed a table.
  final providerSelector = RegExp(r'\.select\s*\(\s*\(');

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
        if (providerSelector.hasMatch(line)) continue;
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

  test('a provider selector is not a database read', () {
    // The refinement above, pinned in both directions: it must keep catching
    // drift's form, which is also preceded by a dot, or the exclusion has
    // blinded the scanner rather than narrowed it.
    expect(
      providerSelector.hasMatch(
        'invoiceListQueryProvider.select((query) => query.filter),',
      ),
      isTrue,
    );
    expect(providerSelector.hasMatch('_db.select(_db.invoices)'), isFalse);
    expect(rawQuery.hasMatch('_db.select(_db.invoices)'), isTrue);
    expect(rawQuery.hasMatch('_db.selectOnly(_db.payments)'), isTrue);
  });

  test('the helper is where it is expected to be', () {
    // Keeps the test above from passing vacuously after a rename.
    final source = File(helper).readAsStringSync();
    expect(source, contains('selectAlive'));
    expect(source, contains('selectOnlyAlive'));
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
