import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/security/app_log.dart';
import 'data/database/app_database.dart';
import 'data/database/database_bootstrap.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _routeFrameworkErrorsThroughAppLog();

  // Startup opens the encrypted database and asserts, against the bytes on
  // disk, that it really is encrypted (D-020). A failure here is deliberately
  // fatal: the alternative is running on a plaintext database holding
  // financial records and third-party national IDs.
  //
  // There is no Persian failure screen and no recovery path, for the reason
  // D-020 records -- the only alternative to failing is writing those records
  // in the clear. The exception is unhandled, which is loud and honest.
  final AppDatabase database = await openAppDatabase();

  AppLog.info(() => 'database opened; starting up', scope: 'startup');

  // The composition root: everything below this point reaches the data layer
  // through providers, and the only thing that knows how the database was
  // opened is this line (D-007).
  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const FactorinoApp(),
    ),
  );
}

/// Sends framework and uncaught-async errors through [AppLog] instead of
/// straight to the console.
///
/// This is what makes "**all** logging routed through one wrapper" (§7) true
/// rather than aspirational. The framework's own error path is not a
/// hypothetical leak: a layout overflow dumps the offending widget subtree,
/// and in this application that subtree contains `Text` widgets holding
/// customer names and amounts. Left on the default path it reaches logcat
/// verbatim, on any build.
///
/// Through [AppLog] it is scrubbed, and in a release build it is not emitted at
/// all. The cost is the framework's formatted error box in the debug console;
/// the record carries the same information, and DevTools still shows it.
void _routeFrameworkErrorsThroughAppLog() {
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLog.error(
      () => details.summary.toString(),
      error: details.exception,
      stackTrace: details.stack,
      scope: 'flutter',
    );
  };

  // Errors that escape the framework entirely -- an unawaited future that
  // throws, or a failure in `main` itself.
  //
  // **Logged, then still fatal: this returns false.** Returning true would mark
  // them handled, and that is a trap this file walked into once already. A
  // failure inside `openAppDatabase` was swallowed here, `runApp` was never
  // reached, and because the Windows runner shows its window only after the
  // first frame, the result was a process that ran forever with no window and
  // no message anywhere. D-020's startup is deliberately fail-loud; a
  // catch-all that reports to nobody is precisely the silent degradation it
  // exists to prevent. So this hook adds one scrubbed line and hands the error
  // back to the platform to die on.
  WidgetsBinding.instance.platformDispatcher.onError =
      (Object error, StackTrace stack) {
        AppLog.error(
          () => 'uncaught asynchronous error',
          error: error,
          stackTrace: stack,
          scope: 'platform',
        );
        return false;
      };
}
