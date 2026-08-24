import 'package:flutter/material.dart';

import '../errors/failure_message.dart';
import '../localization/generated/app_strings.dart';
import '../security/app_log.dart';
import 'empty_state.dart';

/// What a screen shows when a provider fails.
///
/// Two jobs, and it is a `StatefulWidget` for the second one:
///
/// * **Show Persian copy**, resolved through [describeFailure] so no raw
///   exception text can reach the screen (§7).
/// * **Log the real error exactly once.** Logging inside `build` would emit a
///   line on every rebuild — a resize, a theme change, a keyboard appearing —
///   and turn one failure into a flood that hides the next one. `initState`
///   fires once per error, which is the number of times the failure actually
///   happened.
class AsyncErrorView extends StatefulWidget {
  const AsyncErrorView({
    required this.error,
    required this.scope,
    this.stackTrace,
    this.onRetry,
    super.key,
  });

  final Object error;
  final StackTrace? stackTrace;

  /// The area this failure came from — `customers`, `products`. Free text and
  /// never a value.
  final String scope;

  final VoidCallback? onRetry;

  @override
  State<AsyncErrorView> createState() => _AsyncErrorViewState();
}

class _AsyncErrorViewState extends State<AsyncErrorView> {
  @override
  void initState() {
    super.initState();
    AppLog.error(
      () => 'provider failed',
      error: widget.error,
      stackTrace: widget.stackTrace,
      scope: widget.scope,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final FailureMessage message = describeFailure(widget.error, strings);

    return EmptyState(
      icon: Icons.error_outline,
      title: message.title,
      body: message.body,
      action: widget.onRetry == null
          ? null
          : FilledButton.tonal(
              onPressed: widget.onRetry,
              child: Text(strings.actionRetry),
            ),
    );
  }
}
