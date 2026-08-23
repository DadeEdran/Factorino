import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// the project spec: *"Repositories expose domain models, never Drift-generated
/// row classes. The Drift row type stops at the repository boundary."*
///
/// Stated that way it is a code-review rule, and code review is exactly what
/// misses it: returning `CustomerRow` instead of `Customer` compiles, runs, and
/// looks entirely ordinary at the call site. By the time it matters, drift row
/// types are threaded through providers and widgets, and the layering is gone.
///
/// So the rule is made structural instead. **The interfaces cannot name a drift
/// type because their libraries do not import drift** — a signature cannot
/// mention a type it has no access to. Implementations live one directory down
/// in `repositories/drift/` and may import whatever they need; they are the
/// mapping layer, and mapping is their job.
///
/// The same applies to `data/models/`: a domain model that imported drift would
/// let a row type leak in through a field rather than through a signature.
void main() {
  const modelsDirectory = 'lib/data/models';
  const interfaceDirectory = 'lib/data/repositories';
  const implementationDirectory = 'lib/data/repositories/drift';

  /// Imports that would put a drift type within reach.
  final forbidden = <RegExp>[
    RegExp(r'''import\s+['"]package:drift/'''),
    RegExp(r'''import\s+['"][^'"]*app_database\.dart['"]'''),
    RegExp(r'''import\s+['"][^'"]*database/tables/'''),
    RegExp(r'''import\s+['"][^'"]*\.g\.dart['"]'''),
  ];

  List<File> dartFilesIn(String directory, {bool recursive = true}) {
    return Directory(directory)
.listSync(recursive: recursive)
.whereType<File>()
.where((file) => file.path.endsWith('.dart'))
.where(
          (file) => !file.path
.replaceAll(r'\', '/')
.contains('$implementationDirectory/'),
        )
.toList();
  }

  List<String> offendersIn(String directory, {bool recursive = true}) {
    final offenders = <String>[];
    for (final file in dartFilesIn(directory, recursive: recursive)) {
      final relative = file.path.replaceAll(r'\', '/');
      final source = file.readAsStringSync();
      for (final pattern in forbidden) {
        final match = pattern.firstMatch(source);
        if (match != null) {
          offenders.add('$relative: ${match.group(0)}...');
        }
      }
    }
    return offenders;
  }

  test('domain models do not import drift', () {
    expect(
      offendersIn(modelsDirectory),
      isEmpty,
      reason:
          'a domain model that reaches drift can carry a row type in a field, '
          'which defeats the boundary just as thoroughly as returning one '
          '',
    );
  });

  test('repository interfaces do not import drift', () {
    expect(
      offendersIn(interfaceDirectory, recursive: false),
      isEmpty,
      reason:
          'an interface that imports drift can name a row type in a signature. '
          'Keep the interface drift-free and put the mapping in '
          '$implementationDirectory/',
    );
  });

  test('the directories being checked actually contain something', () {
    // A scan over an empty or moved directory passes silently.
    expect(dartFilesIn(modelsDirectory), isNotEmpty);
    expect(
      dartFilesIn(interfaceDirectory, recursive: false),
      isNotEmpty,
      reason: 'the interfaces should sit directly in $interfaceDirectory',
    );
    expect(
      Directory(implementationDirectory).listSync().whereType<File>(),
      isNotEmpty,
      reason: 'the implementations should sit in $implementationDirectory',
    );
  });

  test('the matcher would catch a real drift import', () {
    // Guards the guard: a pattern that matches nothing passes for free.
    final drift = forbidden.first;
    expect(drift.hasMatch("import 'package:drift/drift.dart';"), isTrue);
    expect(drift.hasMatch('import "package:drift/drift.dart";'), isTrue);
    expect(drift.hasMatch("import 'package:uuid/uuid.dart';"), isFalse);

    final database = forbidden[1];
    expect(
      database.hasMatch("import '../database/app_database.dart';"),
      isTrue,
    );
    expect(database.hasMatch("import '../models/customer.dart';"), isFalse);
  });

  test('every interface has an implementation that is checked to match', () {
    // The compiler enforces `implements`; this only keeps the two directories
    // from drifting apart silently, which is what would make the split above
    // decorative.
    final interfaces = dartFilesIn(
      interfaceDirectory,
      recursive: false,
    ).map((f) => f.path.replaceAll(r'\', '/').split('/').last).toSet();
    final implementations = Directory(implementationDirectory)
.listSync()
.whereType<File>()
.map((f) => f.path.replaceAll(r'\', '/').split('/').last)
.where((name) => name.startsWith('drift_'))
.map((name) => name.substring('drift_'.length))
.toSet();

    expect(
      interfaces.difference(implementations),
      isEmpty,
      reason: 'these interfaces have no drift_*.dart implementation',
    );
  });
}
