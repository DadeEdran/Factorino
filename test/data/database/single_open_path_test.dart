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
  const forbidden = <String, String>{
    'NativeDatabase(': 'constructs a drift executor directly',
    'NativeDatabase.memory(': 'constructs a drift executor directly',
    'NativeDatabase.createInBackground(':
        'constructs a drift executor directly',
    'NativeDatabase.opened(': 'constructs a drift executor directly',
    'sqlite3.open(': 'opens sqlite3 directly',
    'sqlite3.openInMemory(': 'opens sqlite3 directly',
    'driftDatabase(': 'opens a connection through drift_flutter (see D-016)',
    'pragma key': 'issues the key pragma outside the single setup sequence',
  };

  test('only one file in lib/ opens a database', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final relative = entity.path.replaceAll(r'\', '/');
      if (relative == opener) continue;

      final source = entity.readAsStringSync().toLowerCase();
      for (final entry in forbidden.entries) {
        if (source.contains(entry.key.toLowerCase())) {
          offenders.add('$relative: "${entry.key}" -- ${entry.value}');
        }
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
