import 'dart:io';

import 'package:factorino/core/security/app_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// the project spec: *"Never log national IDs, economic IDs, phone numbers,
/// customer names, monetary amounts, or the encryption key — in any build.
/// Debug logging is stripped in release builds. Use a single logging wrapper so
/// this is enforceable in one place, and route all logging through it."*
///
/// A wrapper alone does not enforce anything — it only makes enforcement
/// possible. These are the two scans that do the enforcing, and they are the
/// same treatment the database opener (D-020), the soft-delete filter (D-003)
/// and the single normalizer (D-029) get, for the same reason: **the failure is
/// silent.** A `print` of a customer's phone number produces no error, no
/// crash, and no visible defect. It produces a line in logcat that anyone with
/// the device can read, on a build that looked fine in review.
///
/// 1. **Nothing in `lib/` writes output except the wrapper.** No `print`, no
///    `debugPrint`, no `stdout`/`stderr`, no `dart:developer`.
/// 2. **No sensitive field name appears inside an `AppLog` call.** This is the
///    primary control: the runtime scrubber in [scrubForLogging] catches
///    shapes, and a customer's name has no shape.
///
/// **Escape hatch.** `// logging-exempt: <reason>` on the line or in the
/// comment block directly above it.
void main() {
  const String wrapperPath = 'lib/core/security/app_log.dart';
  const String exemption = 'logging-exempt:';

  /// Every way to put a character on a console that is not the wrapper.
  ///
  /// `log(` on its own is deliberately absent: `math.log` is a legitimate call
  /// and the banned one arrives through `dart:developer`, which is matched by
  /// its import instead. A guard that fires on arithmetic is a guard someone
  /// eventually deletes.
  final RegExp consoleOutput = RegExp(
    r'''(?<![A-Za-z0-9_.$])print\s*\(|'''
    r'''(?<![A-Za-z0-9_.$])debugPrint\s*\(|'''
    r'''(?<![A-Za-z0-9_.$])(?:stdout|stderr)\s*\.\s*(?:write|writeln|writeAll|add)|'''
    r"""import\s+'dart:developer'|"""
    r'''dumpErrorToConsole''',
  );

  /// Field and getter names that hold something §7 forbids logging.
  ///
  /// Only names that are unambiguously a sensitive value. `name` is absent
  /// because `status.name` and `destination.name` are enum labels, and a guard
  /// with obvious false positives gets suppressed rather than obeyed.
  const List<String> sensitiveAccessors = <String>[
    // Third-party personal identifiers.
    'nationalId', 'economicId', 'mobile', 'phoneNumber',
    // Customer and company names.
    'fullName', 'displayName', 'companyName', 'customerName',
    // The same values again, under the names the invoice row gives them
    // (D-052). The match is anchored on `.<accessor>`, so `.nationalId` does
    // not cover `.customerNationalIdSnapshot` -- a snapshot of a کد ملی is
    // still a کد ملی, and §7 does not care which column it came out of.
    'customerNameSnapshot', 'customerCompanySnapshot',
    'customerNationalIdSnapshot', 'customerEconomicIdSnapshot',
    'customerAddressSnapshot', 'liveCustomerName',
    // Free text the user typed about a third party.
    'address', 'notes',
    // Monetary amounts.
    'grandTotal', 'subtotal', 'totalTax', 'totalDiscount', 'unitPrice',
    'lineTotal', 'lineNet', 'amountRial', 'priceRial',
    // The encryption key.
    'hex',
  ];

  List<File> librarySources() {
    return Directory('lib')
.listSync(recursive: true)
.whereType<File>()
.where((File file) => file.path.endsWith('.dart'))
.where((File file) {
          final String relative = file.path.replaceAll(r'\', '/');
          // Generated code is not hand-written and is regenerated from a
          // source this guard does cover.
          if (relative.endsWith('.g.dart')) return false;
          if (relative.contains('core/localization/generated/')) return false;
          return true;
        })
.toList();
  }

  test('nothing in lib/ writes output except the logging wrapper', () {
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
        if (!consoleOutput.hasMatch(code)) continue;

        offenders.add('$relative:${i + 1}: ${line.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these lines write output without passing through AppLog, so nothing '
          'scrubs them and nothing strips them from a release build. Route '
          'them through AppLog, or mark the line "// $exemption <reason>":\n'
          '${offenders.join('\n')}',
    );
  });

  test('no sensitive value is named inside an AppLog call', () {
    final List<String> offenders = <String>[];

    for (final File file in librarySources()) {
      final String relative = file.path.replaceAll(r'\', '/');
      if (relative == wrapperPath) continue;

      final List<String> lines = file.readAsLinesSync();
      for (final _LogCall call in _findLogCalls(lines)) {
        if (call.text.contains(exemption)) continue;

        for (final String accessor in sensitiveAccessors) {
          if (!RegExp('[.]$accessor\\b').hasMatch(call.text)) continue;
          offenders.add(
            '$relative:${call.line}: .$accessor inside '
            '${call.text.split('\n').first.trim()}',
          );
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'the project spec forbids logging national IDs, economic IDs, phone '
          'numbers, customer names, monetary amounts and the encryption key in '
          'ANY build. The runtime scrubber cannot catch a name -- it has no '
          'shape -- so this scan is the control. Log the id instead, or wrap '
          'the value in redact():\n${offenders.join('\n')}',
    );
  });

  test('the wrapper strips every record from a release build', () {
    // Asserting on the source rather than on behaviour, because a test cannot
    // run in release mode. What matters is that the guard is `kReleaseMode` --
    // a `const bool`, so the body is removed by the compiler -- and that it
    // sits before the sink rather than inside one level of it.
    final String source = File(wrapperPath).readAsStringSync();

    expect(
      source,
      contains('if (kReleaseMode) return;'),
      reason:
          'the release strip is the whole reason the wrapper exists; without '
          'it, every diagnostic reaches logcat on a shipped build.',
    );
    expect(
      source.indexOf('if (kReleaseMode) return;'),
      lessThan(source.indexOf('sink.write(')),
      reason: 'the strip must precede the sink, or it strips nothing.',
    );
    expect(
      source,
      contains('String Function() message'),
      reason:
          'the message is a closure so that release builds never even build '
          'the string -- see property 2 in the wrapper.',
    );
  });

  group('scrubForLogging', () {
    test('redacts a national ID', () {
      expect(
        scrubForLogging('validation failed for 0079542311'),
        'validation failed for <redacted:digits>',
      );
    });

    test('redacts an Iranian mobile number', () {
      expect(
        scrubForLogging('customer mobile 09123456789 rejected'),
        'customer mobile <redacted:digits> rejected',
      );
    });

    test('redacts Persian and Arabic-Indic digits too', () {
      // A value can reach a log line as the user typed it, before the input
      // boundary has folded it.
      expect(scrubForLogging('id ۰۰۷۹۵۴۲۳۱۱'), 'id <redacted:digits>');
      expect(scrubForLogging('id ٠٠٧٩٥٤٢٣١١'), 'id <redacted:digits>');
    });

    test('redacts database key material', () {
      const String key =
          'a3f5b8c2d1e4f60718293a4b5c6d7e8f'
          'a3f5b8c2d1e4f60718293a4b5c6d7e8f';
      expect(scrubForLogging('key $key'), 'key <redacted:hex>');
    });

    test('redacts a PRAGMA key argument, statement and all', () {
      const String statement = 'PRAGMA key = "x\'a3f5b8c2d1e4f607\'"';
      final String scrubbed = scrubForLogging(statement);
      expect(scrubbed, contains('PRAGMA key'));
      expect(scrubbed, isNot(contains('a3f5b8c2')));
    });

    test('leaves ordinary diagnostics alone', () {
      // A scrubber that mangles useful output gets switched off. These are the
      // shapes that legitimately appear in a log line.
      expect(scrubForLogging('loaded 42 rows'), 'loaded 42 rows');
      expect(
        scrubForLogging('invoice INV-1405-0001 issued'),
        'invoice INV-1405-0001 issued',
      );
      expect(
        scrubForLogging('customer 3f2504e0-4f89-41d3-9a0c-0305e82c3301'),
        'customer 3f2504e0-4f89-41d3-9a0c-0305e82c3301',
      );
      expect(
        scrubForLogging('period 2026-08-24T00:00:00.000Z'),
        'period 2026-08-24T00:00:00.000Z',
      );
    });
  });

  group('redact', () {
    test('keeps only the length', () {
      expect(redact('Ali Rezaei'), '<redacted:10>');
      expect(redact(null), '<null>');
      expect(redact(''), '<empty>');
    });
  });

  test('both scans would catch a real violation', () {
    // A matcher that never fires passes for free. Every line below is a
    // plausible thing to write, which is the point.
    expect(consoleOutput.hasMatch("print('rows: \$count');"), isTrue);
    expect(consoleOutput.hasMatch('debugPrint(error.toString());'), isTrue);
    expect(consoleOutput.hasMatch("stdout.writeln('opened');"), isTrue);
    expect(
      consoleOutput.hasMatch("import 'dart:developer' as developer;"),
      isTrue,
    );

    // ...and must not fire on ordinary code that merely contains the letters.
    expect(consoleOutput.hasMatch('final blueprint = Blueprint();'), isFalse);
    expect(consoleOutput.hasMatch('theme.printStyle;'), isFalse);
    expect(consoleOutput.hasMatch('final l = math.log(value);'), isFalse);

    // The sensitive-accessor scan, over a call that spans lines the way a real
    // one does.
    final List<String> offending = <String>[
      "    AppLog.debug(",
      "      () => 'saved customer \${customer.fullName}',",
      "    );",
    ];
    final List<_LogCall> calls = _findLogCalls(offending);
    expect(calls, hasLength(1));
    expect(calls.single.text, contains('.fullName'));

    // ...and one that is fine.
    final List<_LogCall> safe = _findLogCalls(<String>[
      "AppLog.debug(() => 'saved customer \${customer.id}');",
    ]);
    expect(safe.single.text, isNot(contains('.fullName')));
  });

  test('the wrapper is where this test expects it to be', () {
    // Keeps the scans above from passing vacuously after a move or a rename.
    expect(File(wrapperPath).existsSync(), isTrue);
    expect(scrubForLogging('x'), 'x');
  });
}

/// One `AppLog.<method>( ... )` call, with its full argument text.
class _LogCall {
  const _LogCall(this.line, this.text);

  /// 1-indexed line the call starts on.
  final int line;

  /// The call source, from `AppLog.` to its matching close paren.
  final String text;
}

/// Finds every `AppLog.` call in [lines], following it across line breaks.
///
/// A log call is routinely wrapped by the formatter, so a line-at-a-time scan
/// would see `AppLog.debug(` on one line and the sensitive value on the next
/// and match neither. Balancing the parentheses is what makes the scan see the
/// call the way the compiler does.
List<_LogCall> _findLogCalls(List<String> lines) {
  final List<_LogCall> calls = <_LogCall>[];

  for (int i = 0; i < lines.length; i++) {
    final int start = lines[i].indexOf('AppLog.');
    if (start == -1) continue;

    final StringBuffer buffer = StringBuffer();
    int depth = 0;
    bool opened = false;

    for (int j = i; j < lines.length; j++) {
      final String segment = j == i ? lines[j].substring(start) : lines[j];
      buffer.writeln(segment);

      for (final int unit in segment.codeUnits) {
        if (unit == 0x28) {
          depth++;
          opened = true;
        } else if (unit == 0x29) {
          depth--;
        }
      }
      if (opened && depth <= 0) break;
    }

    calls.add(_LogCall(i + 1, buffer.toString()));
  }

  return calls;
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
