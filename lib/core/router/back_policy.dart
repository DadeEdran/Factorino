import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/generated/app_strings.dart';
import '../theme/app_dimensions.dart';

/// What a screen does when the system back gesture arrives, if it wants to
/// decide for itself.
///
/// Returns whether the press was handled. `false` hands it back to
/// [AppBackPolicy], which applies the application-wide rule.
typedef BackClaim = Future<bool> Function();

/// The one screen, if any, that has claimed the system back press.
///
/// A mutable holder passed down an [InheritedWidget] rather than a second
/// [BackButtonListener] deeper in the tree, and that is the whole reason this
/// file exists rather than being three lines in the shell.
///
/// **Nested `BackButtonListener`s do not reliably hand priority back.** Each
/// one creates a child of the *root* dispatcher and calls `takePriority()`, so
/// the deepest-mounted wins — but when it is disposed its `forget()` clears the
/// parent's active child and nothing re-activates the listener that was there
/// before. The result is a back button that silently stops working after the
/// user has visited the invoice form once. There is exactly one listener in
/// this application, in the shell, and screens that need their own behaviour
/// register it here instead.
class BackClaims {
  BackClaim? _claim;

  /// The claim in force, or null when the application-wide rule applies.
  BackClaim? get current => _claim;

  /// Registers [claim] as the screen currently owning the back press.
  ///
  /// Last caller wins, which matches the single screen that can be on top.
  void claim(BackClaim claim) => _claim = claim;

  /// Withdraws [claim] if it is still the one in force.
  ///
  /// Identity-checked rather than unconditional: a screen disposing after a
  /// newer one has already claimed must not clear the newer claim, which is
  /// the order route transitions actually run in.
  void release(BackClaim claim) {
    if (identical(_claim, claim)) _claim = null;
  }
}

/// Publishes the [BackClaims] holder to the screens under the shell.
class BackPolicyScope extends InheritedWidget {
  const BackPolicyScope({
    required this.claims,
    required super.child,
    super.key,
  });

  final BackClaims claims;

  /// Null outside the shell — a widget test that pumps a screen on its own is
  /// the ordinary case, and it must not have to build a shell to do it.
  static BackClaims? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BackPolicyScope>()?.claims;

  @override
  bool updateShouldNotify(BackPolicyScope oldWidget) =>
      !identical(oldWidget.claims, claims);
}

/// The application's system-back rule, in one place.
///
/// * On the dashboard, the first press says how to leave and the second one
///   leaves. A financial application that exits on a single stray back press
///   is one the user loses their place in constantly, and on Android the back
///   gesture is an edge swipe that is easy to trigger by accident.
/// * Anywhere else, back returns to the dashboard rather than exiting — so
///   there is exactly one place in the application where the back press can
///   close it, and the user can always find it.
/// * A screen holding unsaved work claims the press instead ([BackClaims]),
///   because "return to the dashboard" must not be a way to discard a typed
///   invoice without being asked.
///
/// **The window is a timer, not two clock readings.** `nowProvider` is
/// deliberately frozen for the life of the process (see `core/utils/clock.dart`)
/// so it cannot measure an interval, and reaching for `DateTime.now()` beside
/// it is exactly the second clock that file exists to prevent. A timer that is
/// either running or not says the same thing and reads nothing.
class AppBackPolicy extends StatefulWidget {
  const AppBackPolicy({
    required this.claims,
    required this.isHome,
    required this.onGoHome,
    required this.child,
    super.key,
  });

  final BackClaims claims;

  /// Whether the shell is currently showing the destination back leads to.
  final bool isHome;

  /// Switches to that destination.
  final VoidCallback onGoHome;

  final Widget child;

  @override
  State<AppBackPolicy> createState() => _AppBackPolicyState();
}

class _AppBackPolicyState extends State<AppBackPolicy> {
  /// Running exactly while a second press would exit.
  Timer? _armed;

  @override
  void dispose() {
    _armed?.cancel();
    super.dispose();
  }

  Future<bool> _onBack() async {
    final BackClaim? claim = widget.claims.current;
    if (claim != null && await claim()) return true;

    // The claim may have navigated, and a claim that returns false may still
    // have awaited a dialog. Either way the press is answered.
    if (!mounted) return true;

    if (!widget.isHome) {
      _disarm();
      widget.onGoHome();
      return true;
    }

    if (_armed?.isActive ?? false) {
      _disarm();
      await SystemNavigator.pop();
      return true;
    }

    _armed = Timer(AppDuration.exitConfirmation, _disarm);
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    messenger?.showSnackBar(
      SnackBar(
        content: Text(AppStrings.of(context).exitConfirmPrompt),
        // The message is on screen for exactly as long as the second press
        // will be accepted, so it is never advice the user acts on too late.
        duration: AppDuration.exitConfirmation,
      ),
    );
    return true;
  }

  void _disarm() {
    _armed?.cancel();
    _armed = null;
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: _onBack,
      child: BackPolicyScope(claims: widget.claims, child: widget.child),
    );
  }
}
