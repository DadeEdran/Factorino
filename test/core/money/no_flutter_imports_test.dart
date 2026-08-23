import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// the project spec: the money engine imports **nothing from Flutter**, so it is
/// unit-testable without a widget binding.
///
/// Same spirit as the soft-delete and single-opener guards: a rule that lives
/// only in a document is a rule until someone needs a `Color` for one debug
/// line. Once a single Flutter import lands, every test in this directory
/// silently starts needing a binding, and the engine stops being the isolated,
/// deterministic thing the money rules depend on.
///
/// Checked **transitively** through project-relative imports: pulling in a
/// `core/formatting/` helper that itself imports Flutter would defeat a
/// direct-import check while doing exactly the damage the rule forbids.
void main() {
  const root = 'lib/core/money';

  final forbidden = <RegExp>[
    RegExp(r'''import\s+['"]package:flutter/'''),
    RegExp(r'''import\s+['"]package:flutter_test/'''),
    RegExp(r'''import\s+['"]dart:ui'''),
    RegExp(r'''export\s+['"]package:flutter/'''),
  ];

  test(
    'the money engine has no Flutter dependency, directly or transitively',
    () {
      final offenders = <String>[];
      final visited = <String>{};

      void inspect(String path, List<String> via) {
        final normalized = path.replaceAll(r'\', '/');
        if (!visited.add(normalized)) return;

        final file = File(normalized);
        if (!file.existsSync()) return;

        final source = file.readAsStringSync();
        final trail = via.isEmpty ? '' : ' (reached via ${via.join(' -> ')})';

        for (final pattern in forbidden) {
          final match = pattern.firstMatch(source);
          if (match != null) {
            offenders.add('$normalized: ${match.group(0)}...$trail');
          }
        }

        // Follow project-relative imports only; package imports other than
        // Flutter's are third-party and cannot pull Flutter into a pure library
        // without declaring it, which pubspec review covers.
        for (final match in RegExp(
          '''import\\s+['"](\\.[^'"]+)['"]''',
        ).allMatches(source)) {
          final target = _resolve(normalized, match.group(1)!);
          inspect(target, <String>[...via, normalized]);
        }
      }

      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          inspect(entity.path, const <String>[]);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'the money engine must stay pure Dart:\n'
            '${offenders.join('\n')}',
      );
    },
  );

  test('the engine is actually there to be checked', () {
    // Guards against the scan passing because the directory moved or emptied.
    final files = Directory(root)
.listSync(recursive: true)
.whereType<File>()
.where((f) => f.path.endsWith('.dart'))
.toList();

    expect(files, isNotEmpty, reason: '$root has no Dart files');
    expect(
      files.map((f) => f.path.replaceAll(r'\', '/').split('/').last),
      containsAll(<String>['money.dart', 'invoice_calculator.dart']),
    );
  });

  test('the matcher would catch a real Flutter import', () {
    // Guards the guard: a pattern that matches nothing passes silently.
    final pattern = RegExp(r'''import\s+['"]package:flutter/''');
    expect(pattern.hasMatch("import 'package:flutter/material.dart';"), isTrue);
    expect(pattern.hasMatch('import "package:flutter/widgets.dart";'), isTrue);
    expect(pattern.hasMatch("import 'package:intl/intl.dart';"), isFalse);
  });
}

/// Resolves a relative import against the importing file's directory.
String _resolve(String fromFile, String relative) {
  final segments = fromFile.split('/')..removeLast();
  for (final part in relative.split('/')) {
    if (part == '.') continue;
    if (part == '..') {
      if (segments.isNotEmpty) segments.removeLast();
    } else {
      segments.add(part);
    }
  }
  return segments.join('/');
}
