import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/router/back_policy.dart';
import 'package:factorino/core/theme/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/screen_harness.dart';

/// The system back rule (D-095).
///
/// Four behaviours, and the last is the one that would otherwise be found by
/// a user losing a half-typed invoice:
///
/// * inside a destination that has a page stacked in it, back unwinds that
///   destination's own stack (D-104);
/// * at the top of a destination, back returns home rather than exiting;
/// * on the home destination, the first press says how to leave and the second
///   one leaves;
/// * a screen holding unsaved work decides for itself.
///
/// **The order between the first two is the whole of D-104** and is pinned
/// below: before it, every press anywhere but the dashboard jumped straight to
/// the dashboard, so opening an invoice and pressing back abandoned فاکتورها
/// rather than returning to it.
///
/// **Driven through the real `BackButtonListener`**, not by calling the state's
/// method: the whole reason this file exists rather than a comment is that the
/// dispatcher plumbing is the part that goes wrong, and a test that invoked the
/// callback directly would pass with the listener unmounted. `pressBack` sends
/// the platform's own `popRoute` message, which is what an Android back gesture
/// sends.
void main() {
  /// Sends the platform back message, exactly as the system does.
  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  /// Builds the policy over a stub page, recording what it asked for.
  ///
  /// A `Router` has to be above it, because `BackButtonListener` resolves its
  /// dispatcher from one — which is itself worth pinning: without a router in
  /// the tree the listener silently does nothing, and that is a failure mode
  /// that would look exactly like a working application in a widget test.
  ///
  /// [sectionPages] is how many pages the current destination has stacked in
  /// it: the stub pops one per press and reports whether it had one, which is
  /// exactly the contract `app_router.dart` implements over `GoRouter.canPop`.
  Future<({BackClaims claims, List<String> log})> pump(
    WidgetTester tester, {
    required bool isHome,
    int sectionPages = 0,
  }) async {
    final BackClaims claims = BackClaims();
    final List<String> log = <String>[];
    int stacked = sectionPages;

    await pumpScreen(
      tester,
      AppBackPolicy(
        claims: claims,
        isHome: isHome,
        onPopSection: () {
          if (stacked == 0) return false;
          stacked--;
          log.add('pop');
          return true;
        },
        onGoHome: () => log.add('home'),
        child: const Scaffold(body: SizedBox.expand()),
      ),
    );
    await tester.pumpAndSettle();
    return (claims: claims, log: log);
  }

  testWidgets('inside a destination, back unwinds that destination first', (
    WidgetTester tester,
  ) async {
    // An invoice open over the invoice list. The press that follows undoes the
    // opening; it does not abandon فاکتورها for the dashboard (D-104).
    final ({BackClaims claims, List<String> log}) it = await pump(
      tester,
      isHome: false,
      sectionPages: 1,
    );

    await pressBack(tester);
    expect(it.log, <String>['pop']);

    // And once the destination is back at its root, the next press applies the
    // application-wide rule — which is the half that was already true.
    await pressBack(tester);
    expect(it.log, <String>['pop', 'home']);
  });

  testWidgets('a claim outranks the destination stack', (
    WidgetTester tester,
  ) async {
    // The invoice **form**, which is itself a page inside فاکتورها: popping it
    // is exactly the discard the claim exists to ask about first, so the order
    // between these two is load-bearing rather than incidental.
    final ({BackClaims claims, List<String> log}) it = await pump(
      tester,
      isHome: false,
      sectionPages: 1,
    );

    it.claims.claim(() async => true);
    await pressBack(tester);

    expect(it.log, isEmpty);
  });

  testWidgets('away from home, back goes home and does not exit', (
    WidgetTester tester,
  ) async {
    final ({BackClaims claims, List<String> log}) it = await pump(
      tester,
      isHome: false,
    );

    await pressBack(tester);

    expect(it.log, <String>['home']);
    // No prompt: the user is not near leaving, so saying anything about it
    // would be noise on every back press in the application.
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('on home, the first press says how to leave', (
    WidgetTester tester,
  ) async {
    final ({BackClaims claims, List<String> log}) it = await pump(
      tester,
      isHome: true,
    );
    final AppStrings strings = stringsOf(tester, AppBackPolicy);

    await pressBack(tester);

    expect(find.text(strings.exitConfirmPrompt), findsOneWidget);
    expect(it.log, isEmpty);
  });

  testWidgets('a second press inside the window is the one that leaves', (
    WidgetTester tester,
  ) async {
    // What "leaves" means here is `SystemNavigator.pop`, which a widget test
    // cannot observe as an exit — so the platform channel is watched instead.
    // That is the exact call the application makes, and it is made from one
    // place.
    final List<String> platform = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        platform.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pump(tester, isHome: true);

    await pressBack(tester);
    expect(platform, isNot(contains('SystemNavigator.pop')));

    await pressBack(tester);
    expect(platform, contains('SystemNavigator.pop'));
  });

  testWidgets('the window closes, and a later press only re-arms', (
    WidgetTester tester,
  ) async {
    // **The property that makes this a confirmation rather than a trap.** A
    // back press half a minute after the first must not still be armed: the
    // user has long since stopped thinking about leaving, and an application
    // that closes on it is one that closes at random.
    final List<String> platform = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        platform.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pump(tester, isHome: true);
    final AppStrings strings = stringsOf(tester, AppBackPolicy);

    await pressBack(tester);
    // Past the window, by a margin, and with the snackbar's own duration
    // elapsed so nothing is left animating.
    await tester.pump(AppDuration.exitConfirmation * 3);
    await tester.pumpAndSettle();

    await pressBack(tester);
    expect(
      platform,
      isNot(contains('SystemNavigator.pop')),
      reason: 'the second press was outside the window, so it only re-arms',
    );
    expect(find.text(strings.exitConfirmPrompt), findsOneWidget);
  });

  testWidgets('a claim takes the press, and home is not reached', (
    WidgetTester tester,
  ) async {
    // The invoice form's case: unsaved work, and a confirmation the shell rule
    // must not walk past. A claim that answers `true` has handled the press.
    final ({BackClaims claims, List<String> log}) it = await pump(
      tester,
      isHome: false,
    );

    int claimed = 0;
    it.claims.claim(() async {
      claimed++;
      return true;
    });

    await pressBack(tester);

    expect(claimed, 1);
    expect(
      it.log,
      isEmpty,
      reason: 'the claim handled it; navigating anyway would discard the work',
    );
  });

  testWidgets('a claim that declines hands the press back', (
    WidgetTester tester,
  ) async {
    // The form with nothing typed in it: there is nothing to confirm, so the
    // application-wide rule should apply unchanged. Returning `false` is how a
    // screen says "not mine after all" without having to know what the rule is.
    final ({BackClaims claims, List<String> log}) it = await pump(
      tester,
      isHome: false,
    );

    it.claims.claim(() async => false);
    await pressBack(tester);

    expect(it.log, <String>['home']);
  });

  testWidgets('a released claim stops being consulted', (
    WidgetTester tester,
  ) async {
    // The screen has been popped. A registry that kept a dead claim would
    // leave the back button running a disposed screen's confirmation — or,
    // worse, silently swallowing every press.
    final ({BackClaims claims, List<String> log}) it = await pump(
      tester,
      isHome: false,
    );

    Future<bool> claim() async => true;
    it.claims.claim(claim);
    it.claims.release(claim);

    await pressBack(tester);
    expect(it.log, <String>['home']);
  });

  test('releasing an older claim does not clear a newer one', () {
    // Route transitions dispose the outgoing screen **after** the incoming one
    // has registered, so an unconditional `release` in `dispose` would leave
    // the new screen's claim silently gone. Identity is what tells them apart.
    final BackClaims claims = BackClaims();
    Future<bool> older() async => true;
    Future<bool> newer() async => true;

    claims.claim(older);
    claims.claim(newer);
    claims.release(older);

    expect(claims.current, same(newer));
  });
}
