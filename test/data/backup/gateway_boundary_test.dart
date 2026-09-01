import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// D-071 makes `flutter_file_dialog` a **dated dependency**: it applies the
/// Kotlin Gradle Plugin, and Flutter has announced that future versions will
/// refuse to build applications using such plugins. The fallback is specified —
/// app-external storage via `path_provider`, no dependency and no permission —
/// and it is only a one-file change *if the file-picking packages are reachable
/// from exactly one file*.
///
/// A note in a decision log does not make that true. This does.
///
/// The same guard covers `file_selector`, for the same reason and a second one:
/// a picker called straight from a widget would also be a screen reaching past
/// the data layer, which the project spec forbids on its own terms.
void main() {
  /// The single sanctioned adapter.
  const String gateway = 'lib/data/backup/backup_file_gateway.dart';

  /// Packages that may be imported only there.
  const Map<String, String> confined = <String, String>{
    'package:flutter_file_dialog':
        'the Android save dialog (D-071) — dated: '
        'applies KGP, which future Flutter versions will refuse to build',
    'package:file_selector':
        'the Windows save dialog and both open dialogs '
        '(D-071)',
  };

  test('only the gateway imports a file-picking package', () {
    final List<String> offenders = <String>[];

    for (final FileSystemEntity entity in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final String relative = entity.path.replaceAll(r'\', '/');
      if (relative == gateway) continue;

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
          'a file-picking package must be reachable only through '
          'BackupFileGateway, so that replacing one is a one-file change '
          '(D-071):\n${offenders.join('\n')}',
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
            '$gateway no longer imports $package; if the dependency was '
            'replaced, update this test deliberately',
      );
    }
    expect(source, contains('abstract interface class BackupFileGateway'));
  });
}
