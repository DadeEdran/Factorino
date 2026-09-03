import 'package:factorino/core/widgets/transient_message_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A snackbar must not outlive a trip to another application (D-101).
///
/// **The defect these pin was reported from a phone**, not found here: background
/// the application, come back, and the message is still sitting there — and
/// stays. A `SnackBar` leaves by running an animation, an animation needs
/// frames, and a paused application produces none while the timer that requests
/// the dismissal fires anyway. The message ends up in a state it cannot leave.
///
/// The exit is asserted through the **real lifecycle messages**, the ones the
/// platform sends, rather than by calling the state's method: the whole reason
/// this widget exists is the observer plumbing, and a test that invoked the
/// callback directly would pass with the observer unregistered.
void main() {
  /// A screen with a button that raises a snackbar, under the scope.
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TransientMessageScope(
          child: Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: ElevatedButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('saved'))),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> show(WidgetTester tester) async {
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('saved'), findsOneWidget);
  }

  Future<void> lifecycle(WidgetTester tester, AppLifecycleState state) async {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pumpAndSettle();
  }

  testWidgets('a message shown before leaving is gone on return', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    await show(tester);

    await lifecycle(tester, AppLifecycleState.inactive);
    await lifecycle(tester, AppLifecycleState.paused);
    await lifecycle(tester, AppLifecycleState.resumed);

    expect(
      find.text('saved'),
      findsNothing,
      reason:
          'a transient message that survived a trip to another application is '
          'no longer about what just happened',
    );
  });

  testWidgets('hidden counts as away, as well as paused', (
    WidgetTester tester,
  ) async {
    // `hidden` is what a desktop window minimising reports, and what newer
    // Android versions send ahead of `paused`. Treating only one of them as
    // leaving would fix the defect on one platform.
    await pump(tester);
    await show(tester);

    await lifecycle(tester, AppLifecycleState.hidden);
    await lifecycle(tester, AppLifecycleState.resumed);

    expect(find.text('saved'), findsNothing);
  });

  testWidgets('a resume with no absence before it clears nothing', (
    WidgetTester tester,
  ) async {
    // **The regression this guards against is the fix eating the message it
    // was meant to preserve.** The lifecycle reports `resumed` on first launch
    // and after transitions that hid nothing; clearing on every one of those
    // would race the export confirmation, which is raised in the same breath as
    // coming back from the system save dialog.
    await pump(tester);
    await show(tester);

    await lifecycle(tester, AppLifecycleState.resumed);

    expect(find.text('saved'), findsOneWidget);
  });

  testWidgets('losing focus is not leaving', (WidgetTester tester) async {
    // On desktop `inactive` fires when the window merely loses focus — clicking
    // another window, or the taskbar. A message cleared by that would vanish
    // while the user is still looking at the application.
    await pump(tester);
    await show(tester);

    await lifecycle(tester, AppLifecycleState.inactive);
    await lifecycle(tester, AppLifecycleState.resumed);

    expect(find.text('saved'), findsOneWidget);
  });

  testWidgets('a message raised after the return survives', (
    WidgetTester tester,
  ) async {
    // The ordinary export sequence: the save dialog takes the application away,
    // it comes back, and *then* the confirmation is shown. That one is about
    // what just happened and must stay.
    await pump(tester);

    await lifecycle(tester, AppLifecycleState.paused);
    await lifecycle(tester, AppLifecycleState.resumed);

    await show(tester);
    expect(find.text('saved'), findsOneWidget);
  });

  testWidgets('a second absence clears again', (WidgetTester tester) async {
    // The flag has to reset, or the fix works once per launch.
    await pump(tester);

    for (int round = 0; round < 2; round++) {
      await show(tester);
      await lifecycle(tester, AppLifecycleState.paused);
      await lifecycle(tester, AppLifecycleState.resumed);
      expect(find.text('saved'), findsNothing, reason: 'round $round');
    }
  });
}
