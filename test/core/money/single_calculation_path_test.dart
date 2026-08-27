import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The money engine is the authority, and there is exactly one way to reach it.
///
/// the project spec forbids business logic in widgets and §4 makes the invoice
/// calculation a single authoritative order of operations. Neither statement
/// stops a screen from calling `calculateInvoice` itself with slightly
/// different inputs — a preview that passes the invoice-level discount but
/// forgets the rounding unit, say — and the result of that is two figures that
/// are each individually defensible and disagree with one another. The one the
/// user believes is whichever is on screen; the one that reaches the document
/// is the other.
///
/// So the call sites are enumerated:
///
/// * `core/money/` — the engine itself.
/// * `InvoiceEditorState` — the **preview**, computed once per edit and the
///   single source of every figure a screen displays.
/// * `DriftInvoiceRepository` — the **write**, computed inside the transaction
///   that persists it, so a stored total cannot disagree with its lines.
/// * `invoice_figures_backfill.dart` — the **v3 -> v4 backfill** (D-055), which
///   is a different kind of caller from the other two and is listed for that
///   reason rather than by exception. The preview and the write both *produce*
///   figures the user then sees; the backfill produces nothing it has not first
///   checked against figures the database already holds, and where the engine's
///   output disagrees with the stored row by a single Rial it writes null
///   instead. So it is covered — not by the preview/write comparison below, but
///   by being a comparison itself. The alternative was open-coding §4 step 1
///   and the largest-remainder allocation in the data layer, which is the
///   second implementation this scan exists to prevent.
///
/// The first two callers are deliberate and they are tested against each other:
/// `invoice_preview_matches_write_test.dart` builds a state, writes its draft
/// through the real repository, and asserts that every stored figure equals the
/// one the preview showed. A fourth caller would not be covered by that test,
/// which is the reason this scan exists rather than a comment asking for care.
///
/// **Escape hatch.** `// calculation-exempt: <reason>` on the line or in the
/// comment block directly above it.
void main() {
  const String engineDirectory = 'lib/core/money/';
  const String exemption = 'calculation-exempt:';

  /// The sanctioned callers, by path.
  const Set<String> sanctioned = <String>{
    'lib/features/invoices/domain/invoice_editor_state.dart',
    'lib/data/repositories/drift/drift_invoice_repository.dart',
    'lib/data/database/invoice_figures_backfill.dart',
  };

  final RegExp callsEngine = RegExp(
    r'(?<![A-Za-z0-9_.$])calculateInvoice\s*\(',
  );

  List<File> librarySources() {
    return Directory('lib')
.listSync(recursive: true)
.whereType<File>()
.where((File file) => file.path.endsWith('.dart'))
.where((File file) {
          final String relative = file.path.replaceAll(r'\', '/');
          if (relative.endsWith('.g.dart')) return false;
          return !relative.startsWith(engineDirectory);
        })
.toList();
  }

  test('only the preview and the write call the money engine', () {
    final List<String> offenders = <String>[];

    for (final File file in librarySources()) {
      final String relative = file.path.replaceAll(r'\', '/');
      if (sanctioned.contains(relative)) continue;

      final List<String> lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        if (line.contains(exemption)) continue;
        if (_precedingCommentBlock(lines, i).contains(exemption)) continue;

        final String code = _stripComments(line);
        if (!callsEngine.hasMatch(code)) continue;

        offenders.add('$relative:${i + 1}: ${line.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these lines run the invoice calculation outside the two sanctioned '
          'call sites. A third one is a second answer to the same question, '
          'and nothing compares it against the first. Read the totals from '
          'InvoiceEditorState, or mark the line "// $exemption <reason>":\n'
          '${offenders.join('\n')}',
    );
  });

  test('every sanctioned caller still exists and still calls it', () {
    // Without this the scan above passes for free after a rename -- and it
    // would pass most convincingly at the exact moment the preview stopped
    // being computed by the engine at all.
    for (final String path in sanctioned) {
      final File file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path is missing');
      expect(
        callsEngine.hasMatch(file.readAsStringSync()),
        isTrue,
        reason: '$path no longer calls calculateInvoice',
      );
    }
  });

  test('the scan would catch a real violation', () {
    expect(
      callsEngine.hasMatch('final totals = calculateInvoice(input);'),
      isTrue,
    );
    expect(
      callsEngine.hasMatch('      calculateInvoice(InvoiceInput(lines: l)),'),
      isTrue,
    );
    // ...and must not fire on anything that is not a call to it.
    expect(
      callsEngine.hasMatch('/// See calculateInvoice for the order.'),
      isFalse,
    );
    expect(callsEngine.hasMatch('engine.calculateInvoiceLater();'), isFalse);
    expect(callsEngine.hasMatch('final x = recalculateInvoices();'), isFalse);

    // A doc comment that *does* spell the call is stripped before matching, so
    // documenting the rule cannot break the rule -- the same treatment the
    // other lib/-scanning guards give comments.
    expect(_stripComments('/// calls calculateInvoice(input) once.'), '');
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
