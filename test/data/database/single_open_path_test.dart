import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// D-020 requires that the keyed open sequence cannot be bypassed. A comment
/// saying so is not enforcement -- a second call site that opens a database its
/// own way would be encryption-free and would look perfectly ordinary in review.
///
/// This test makes the choke point structural: exactly one file in `lib/` may
/// open a database, and only through `openEncryptedDatabase`.
void main() {
  /// The single sanctioned opener.
  const opener = 'lib/data/database/encrypted_database.dart';

  /// Ways to obtain a database connection that would skip the keyed setup.
  ///
  /// Matched with a preceding-character guard rather than a plain substring
  /// search: `driftDatabase(` otherwise matches inside drift's own
  /// `@DriftDatabase(` annotation, and a guard that cries wolf on correct code
  /// gets deleted by the next person who hits it.
  const forbidden = <String, String>{
    'NativeDatabase': 'constructs a drift executor directly',
    'sqlite3.open': 'opens sqlite3 directly',
    'sqlite3.openInMemory': 'opens sqlite3 directly',
    'driftDatabase': 'opens a connection through drift_flutter (see D-016)',
  };

  test('only one file in lib/ opens a database', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final relative = entity.path.replaceAll(r'\', '/');
      if (relative == opener) continue;

      final source = entity.readAsStringSync();

      for (final entry in forbidden.entries) {
        // Not preceded by an identifier character, `@`, `.` or `$`, so
        // annotations and longer names containing this one do not match.
        final pattern = RegExp(
          r'(?<![A-Za-z0-9_@$.])' + RegExp.escape(entry.key) + r'\s*[.(]',
        );
        if (pattern.hasMatch(source)) {
          offenders.add('$relative: "${entry.key}" -- ${entry.value}');
        }
      }

      // The key pragma may only ever be issued by the setup sequence.
      if (RegExp('pragma\\s+key', caseSensitive: false).hasMatch(source)) {
        offenders.add(
          '$relative: "pragma key" -- issues the key pragma outside the '
          'single setup sequence',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these files bypass openEncryptedDatabase, so their connections are '
          'not keyed and their data is not encrypted (D-020):\n'
          '${offenders.join('\n')}',
    );
  });

  test('the matcher still catches a real bypass', () {
    // Guards the guard: the boundary rule above must not have been loosened
    // into something that matches nothing.
    final pattern = RegExp(r'(?<![A-Za-z0-9_@$.])NativeDatabase\s*[.(]');

    expect(pattern.hasMatch('final db = NativeDatabase(file);'), isTrue);
    expect(pattern.hasMatch('NativeDatabase.memory()'), isTrue);
    expect(pattern.hasMatch('@DriftDatabase(tables: [])'), isFalse);
  });

  test('the sanctioned opener still exists at the expected path', () {
    // Guards against the test above passing vacuously after a rename.
    expect(
      File(opener).existsSync(),
      isTrue,
      reason: '$opener is missing; update this test if it moved deliberately',
    );
    expect(
      File(opener).readAsStringSync(),
      contains('QueryExecutor openEncryptedDatabase('),
    );
  });
}
