import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// D-071 requires that replacing a file-picking dependency is a **one-file
/// change**, which is only true if every such package is reachable from exactly
/// one file. A note in a decision log does not make that true. This does.
///
/// **D-103 is what the guard was for.** `flutter_file_dialog` returned the SAF
/// URI's path component with the scheme and the authority stripped, so the
/// Android save had to be replaced outright — and it was a change to this one
/// file plus `MainActivity`, exactly as the decision promised. The channel that
/// replaced it is confined here too: it is the same kind of thing, the platform
/// handle for getting a file out of app-private storage, and letting a widget
/// reach it directly would be the boundary going the same way by another route.
///
/// The same guard covers `file_selector`, for that reason and a second one: a
/// picker called straight from a widget would also be a screen reaching past
/// the data layer, which the project spec forbids on its own terms.
void main() {
  /// The single sanctioned adapter.
  const String gateway = 'lib/data/backup/backup_file_gateway.dart';

  /// The one other file allowed to use the channel the gateway declares.
  ///
  /// The opener is the other half of the same act — it can only be handed a
  /// [DeliveredFile] the gateway produced — so it uses the gateway's channel
  /// constant. What it must not do is declare a channel of its own.
  const String opener = 'lib/data/backup/saved_file_opener.dart';

  /// Packages and platform handles that may be named only there.
  const Map<String, String> confined = <String, String>{
    'package:file_selector':
        'the desktop save dialog and both open dialogs '
        '(D-071)',
    'io.github.erysaw.factorino/documents':
        'the Android save-and-open channel (D-103) — the gateway declares it, '
        'and nothing else may name it',
  };

  test('only the gateway imports a file-picking package', () {
    final List<String> offenders = <String>[];

    for (final FileSystemEntity entity in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final String relative = entity.path.replaceAll(r'\', '/');
      if (relative == gateway) continue;
      // The opener imports the gateway to reach `kDocumentsChannel`, which is
      // the arrangement being enforced rather than a hole in it.
      if (relative == opener) continue;

      final String source = entity.readAsStringSync();
      for (final MapEntry<String, String> entry in confined.entries) {
        if (source.contains(entry.key)) {
          offenders.add('$relative: imports "${entry.key}" — ${entry.value}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a file-picking package or platform channel must be reachable '
          'only through BackupFileGateway, so that replacing one is a '
          'one-file change (D-071, D-103):\n${offenders.join('\n')}',
    );
  });

  test('the gateway still exists and still holds the confined imports', () {
    // Guards against the test above passing vacuously — after a rename, or
    // after someone "cleans up" the imports by moving them somewhere else.
    final File file = File(gateway);
    expect(file.existsSync(), isTrue, reason: '$gateway is missing');

    final String source = file.readAsStringSync();
    for (final String package in confined.keys) {
      expect(
        source,
        contains(package),
        reason:
            '$gateway no longer names $package; if the dependency was '
            'replaced, update this test deliberately',
      );
    }
    expect(source, contains('abstract interface class BackupFileGateway'));
  });
}
