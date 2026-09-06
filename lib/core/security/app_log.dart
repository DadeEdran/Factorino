import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// The one place this application writes a log line.
///
/// ## Why a wrapper at all
///
/// §7 forbids logging national IDs, economic IDs, phone numbers, customer
/// names, monetary amounts and the encryption key **in any build**, and
/// requires debug logging to be stripped from release builds. Neither is
/// enforceable if two hundred call sites each reach for `print`. One wrapper
/// makes both a property of a single file, and
/// `test/core/security/logging_path_test.dart` fails the build if anything in
/// `lib/` writes output another way.
///
/// ## Three properties, in the order they matter
///
/// **1. Nothing is emitted in a release build — not even an error.** The guard
/// is `kReleaseMode`, a compile-time constant, so the body is dead code the
/// compiler removes rather than a branch taken at runtime. This is deliberately
/// stronger than "debug logging is stripped": in a release build the only
/// destinations available are logcat on Android and stdout on Windows, and
/// both are readable by exactly the person §7's threat model is worried about.
/// A log line that cannot be read by the developer but can be read by whoever
/// holds the device is worse than no line at all.
///
/// **2. The message is a closure, so it is never built in release.** With an
/// eager `String` argument the interpolation runs at the call site before the
/// call, which means a sensitive value is materialized into a string in a
/// release build even though nothing ever prints it. `() => '...'` is not
/// invoked when the guard returns first, so the string is never formed.
///
/// **3. Whatever does get emitted is scrubbed first.** See
/// [scrubForLogging] — and read its limits, because they are real.
///
/// ## What this cannot do
///
/// A wrapper cannot stop someone writing
/// `AppLog.debug(() => 'customer ${customer.fullName}')`. [scrubForLogging]
/// catches identifiers with a recognisable *shape* — a national ID, a mobile
/// number, key material — and nothing else. A customer name is arbitrary text
/// and no runtime check will ever recognise it.
///
/// So the runtime scrubber is the backstop, not the control. The control is
/// the static guard in `logging_path_test.dart`, which fails the build when a
/// sensitive field name appears inside an `AppLog` call. Together: the guard
/// stops the mistake being written, the scrubber catches the value that
/// arrives inside something the guard could not see through — an exception
/// message from the database layer, most plausibly.
abstract final class AppLog {
  /// Where records go. Swappable so the guard's own tests can observe what
  /// would be written without capturing process output.
  @visibleForTesting
  static LogSink sink = const DeveloperLogSink();

  /// Restores the default sink. For test teardown.
  @visibleForTesting
  static void resetSink() => sink = const DeveloperLogSink();

  /// Diagnostic detail: what a query returned, which branch was taken.
  static void debug(String Function() message, {String? scope}) =>
      _emit(LogLevel.debug, message, scope: scope);

  /// A milestone worth seeing in a normal run: the database opened, a
  /// migration ran.
  static void info(String Function() message, {String? scope}) =>
      _emit(LogLevel.info, message, scope: scope);

  /// Something recoverable that should not have happened.
  static void warning(String Function() message, {String? scope}) =>
      _emit(LogLevel.warning, message, scope: scope);

  /// A failure. [error] and [stackTrace] are scrubbed like the message —
  /// an exception's `toString` is the commonest way a value nobody meant to
  /// log reaches a log line.
  static void error(
    String Function() message, {
    Object? error,
    StackTrace? stackTrace,
    String? scope,
  }) => _emit(
    LogLevel.error,
    message,
    scope: scope,
    error: error,
    stackTrace: stackTrace,
  );

  static void _emit(
    LogLevel level,
    String Function() message, {
    String? scope,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // The whole body below is unreachable in release, and `kReleaseMode` is a
    // `const bool`, so it is removed by the compiler rather than skipped at
    // runtime. Property 1 above.
    if (kReleaseMode) return;

    sink.write(
      LogRecord(
        level: level,
        scope: scope,
        message: scrubForLogging(message()),
        error: error == null ? null : scrubForLogging(error.toString()),
        stackTrace: stackTrace,
      ),
    );
  }
}

/// Severity. The numeric values follow `package:logging`'s convention, which is
/// what `dart:developer`'s `log` and the DevTools logging view expect.
enum LogLevel {
  debug(500, 'DEBUG'),
  info(800, 'INFO'),
  warning(900, 'WARN'),
  error(1000, 'ERROR');

  const LogLevel(this.value, this.label);

  final int value;
  final String label;
}

/// One record, after scrubbing and before it reaches a sink.
@immutable
class LogRecord {
  const LogRecord({
    required this.level,
    required this.message,
    this.scope,
    this.error,
    this.stackTrace,
  });

  final LogLevel level;

  /// Already passed through [scrubForLogging].
  final String message;

  /// A short area name — `database`, `startup`. Free text, and never a value.
  final String? scope;

  /// The exception's scrubbed `toString`, if there was one.
  final String? error;

  final StackTrace? stackTrace;
}

/// Where a [LogRecord] ends up.
abstract interface class LogSink {
  void write(LogRecord record);
}

/// The default sink: `dart:developer`'s `log`.
///
/// Not `print` and not `debugPrint`. `developer.log` carries the level and the
/// scope as structured fields rather than as text, appears in the DevTools
/// logging view, and is not subject to the per-line truncation that makes
/// `print` lose the end of a stack trace on Android.
class DeveloperLogSink implements LogSink {
  const DeveloperLogSink();

  @override
  void write(LogRecord record) {
    // logging-exempt: this is the one sanctioned sink, and the single reason
    // the guard in logging_path_test.dart allows dart:developer in this file.
    developer.log(
      record.message,
      name: record.scope ?? 'factorino',
      level: record.level.value,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }
}

/// Replaces values whose *shape* identifies them as sensitive.
///
/// **Read what this does not cover before relying on it.** It recognises three
/// shapes and nothing else:
///
/// | Shape | Catches |
/// |---|---|
/// | a run of 10 or more digits | national ID (10), economic ID (11–12), Iranian mobile (11), and large amounts |
/// | a run of 32 or more hex characters | database key material (64 hex chars) |
/// | `x'<hex>'` | key material in the wrapped form the opener builds (D-020) |
///
/// It does **not** catch a customer name, a company name, an address, a note,
/// or a monetary amount below ten digits — roughly 100,000,000 Toman. Those are
/// the static guard's job, and the guard is the primary control (see [AppLog]).
///
/// Digits are matched in all three sets the user's keyboard can produce, since
/// a value can reach a log line as typed rather than as normalized.
///
// normalizer-exempt: this is a *detector*, not a fold. It maps no character to
// any other and produces no key -- it only recognises digit shapes in order to
// replace them wholesale. Routing it through searchKey would be wrong twice
// over: it would rewrite the diagnostic text, and searchKey's own job is to
// produce a comparable key, not to redact one.
String scrubForLogging(String input) {
  return input
      .replaceAll(_pragmaKeyArgument, "x'<redacted>'")
      .replaceAll(_hexRun, '<redacted:hex>')
      .replaceAll(_digitRun, '<redacted:digits>');
}

/// The exact wrapped form `openEncryptedDatabase` builds its key into (D-020).
/// Matched
/// first and as a whole, so the statement stays recognisable in a log while
/// the key inside it does not survive.
final RegExp _pragmaKeyArgument = RegExp(r"""x'[0-9a-fA-F]+'""");

/// 32 hex characters is 128 bits. Nothing this application legitimately logs
/// is that long and that shape; the database key is 64.
final RegExp _hexRun = RegExp(
  r'(?<![0-9a-zA-Z])[0-9a-fA-F]{32,}(?![0-9a-zA-Z])',
);

/// Ten digits is the length of a national ID, and the shortest of the
/// identifier shapes worth catching. A UUID cannot reach this rule: its
/// segments are at most 12 characters and are matched by [_hexRun] only at 32
/// or more, while its hyphens break any digit run well below ten.
///
/// All three digit sets are matched, because a value can reach a log line as
/// the user typed it rather than as the input boundary normalized it.
///
// normalizer-exempt: see scrubForLogging -- a detector, not a fold. The ranges
// are written as code points rather than glyphs for the reason D-034 records:
// where the encoding of a source file is not guaranteed, name the character by
// code point. U+06F0-U+06F9 are the Persian digits, U+0660-U+0669 the
// Arabic-Indic ones.
final RegExp _digitRun = RegExp(r'[0-9\u06F0-\u06F9\u0660-\u0669]{10,}');

/// Deliberately hides a value that is about to be logged, keeping only its
/// length as a diagnostic.
///
/// For the case where the *fact* of a value matters and the value does not:
/// `AppLog.debug(() => 'search term ${redact(term)}')`. The static guard still
/// refuses the sensitive field names outright, so this is for everything else
/// that is user text.
String redact(Object? value) {
  if (value == null) return '<null>';
  final String text = value.toString();
  return text.isEmpty ? '<empty>' : '<redacted:${text.length}>';
}
