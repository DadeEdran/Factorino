import 'package:flutter/material.dart';

/// Clears a stale snackbar when the application comes back to the foreground.
///
/// ## The defect (D-101)
///
/// Reported from a phone: *"the snackbar doesn't dismiss. If I background the
/// app and come back — backgrounded, not closed — it's still sitting there, and
/// it stays."*
///
/// A `SnackBar` dismisses itself by running an animation, and an animation
/// needs frames. When the application is paused the framework stops producing
/// them and mutes every `Ticker`, so the exit animation cannot run — while the
/// `Timer` that was supposed to start it fires anyway, in an isolate that keeps
/// running. The message is left in a state it cannot leave: its dismissal has
/// already been requested and the animation that performs it never got a frame.
/// On resume there is nothing left to re-trigger it, so it sits there
/// indefinitely.
///
/// **It bites hardest on exactly the flow that made it visible.** Saving a PDF
/// leaves the application twice — once for the system save dialog, once more for
/// the PDF viewer (D-100) — so the export's own confirmation is the message most
/// likely to be showing across a lifecycle change.
///
/// ## Why clearing is right rather than merely convenient
///
/// A snackbar is a **transient** message: the contract is that it says something
/// about what just happened and then goes away. One that has survived a trip to
/// another application is no longer about what just happened. Every message this
/// application shows this way is a confirmation or a failure notice about an
/// action the user took moments earlier — «ذخیره شد», «پرداخت ثبت نشد» — and
/// none of them is the only record of anything: the state they describe is on
/// the screen behind them.
///
/// So the message is dropped rather than restarted. Restarting it would show a
/// four-second confirmation about something the user did before they left, which
/// is a worse answer than silence.
///
/// **Verified to bite** (D-072). With the `clearSnackBars` call commented out,
/// three of the six checks in `transient_message_scope_test.dart` fail; with it
/// in, all six pass. A guard that cannot fail reports clean and looks like
/// coverage, which is worse than none.
///
/// **The action goes with it, deliberately.** The no-seller notice carries the
/// one control that fixes it, and losing that on resume is a real cost — paid
/// because the alternative is a permanently stuck message carrying a
/// permanently stuck button. The settings screen carries the same prompt for
/// the user who goes looking, which is what D-077 built it for.
class TransientMessageScope extends StatefulWidget {
  const TransientMessageScope({required this.child, super.key});

  final Widget child;

  @override
  State<TransientMessageScope> createState() => _TransientMessageScopeState();
}

class _TransientMessageScopeState extends State<TransientMessageScope>
    with WidgetsBindingObserver {
  /// Whether the application has actually been away.
  ///
  /// **Resumed is not by itself a return.** The lifecycle reports `resumed` on
  /// first launch and on transitions that never hid anything, and clearing on
  /// every one of those would race a snackbar the user is being shown right
  /// now — most visibly the export confirmation, which is raised in the same
  /// breath as coming back from the save dialog. So a clear happens only when a
  /// hidden state was seen first.
  bool _wasHidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      // `hidden` and `paused` both mean the user is looking at something else.
      // `inactive` is deliberately not one of them: on desktop it fires for a
      // window merely losing focus, which is not leaving the application.
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _wasHidden = true;
      case AppLifecycleState.resumed:
        if (!_wasHidden) return;
        _wasHidden = false;
        // `maybeOf`, because this sits above the `Scaffold`s and a test may
        // pump it without a messenger at all.
        ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
