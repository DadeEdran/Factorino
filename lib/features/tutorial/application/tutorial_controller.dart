import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/security/app_log.dart';
import '../../../data/providers.dart';
import '../domain/tutorial_step.dart';

part 'tutorial_controller.g.dart';

/// Whether the tutorial is on screen, and where in it the user is.
///
/// **`null` is the ordinary state**: not showing. A nullable step rather than a
/// `(bool visible, TutorialStep step)` pair, so there is no such thing as
/// "hidden, on step four" for a later reader to have to think about.
///
/// `keepAlive`, because the one widget that watches it is mounted for the life
/// of the application and the value it holds is a position in a sequence the
/// user is part-way through — an auto-dispose here would be a rebuild away from
/// starting the tutorial again at step one.
@Riverpod(keepAlive: true)
class TutorialController extends _$TutorialController {
  @override
  TutorialStep? build() => null;

  /// Opens the tutorial at the first step.
  ///
  /// **Always at the first step**, from both entry points. The first launch has
  /// nowhere else to start, and the «راهنما» entry in settings is used by
  /// someone who came looking for the sequence rather than for wherever they
  /// abandoned it months ago.
  void start() => state = TutorialStep.values.first;

  void next() {
    final TutorialStep? current = state;
    if (current == null || current.isLast) return;
    state = TutorialStep.values[current.index + 1];
  }

  void back() {
    final TutorialStep? current = state;
    if (current == null || current.isFirst) return;
    state = TutorialStep.values[current.index - 1];
  }

  /// Closes the tutorial and records that it has been seen.
  ///
  /// **One method for finishing and for skipping, deliberately.** The
  /// requirement is that it runs once; a skip that did not write the flag would
  /// bring it back on the next launch, which is the behaviour a user skipping
  /// it is explicitly asking not to have. The flag says "this user has been
  /// offered the tutorial", not "this user read all eight screens".
  ///
  /// **The screen closes before the write, and does not wait for it.** The
  /// write is idempotent and the flag is already set on every replay from
  /// settings, so there is nothing for the user to see happen — and a tutorial
  /// whose last button paused on a database write would feel broken for the
  /// one reason it must not.
  Future<void> dismiss() async {
    state = null;

    // The write outlives the widget that started it (D-045), which here is a
    // layer that has just removed itself.
    final link = ref.keepAlive();
    try {
      await ref
          .read(settingsRepositoryProvider)
          .markTutorialSeen(DateTime.now());
    } on Object catch (error, stackTrace) {
      // Not surfaced. The worst case is that the tutorial is offered once more
      // on the next launch, which is a nuisance rather than a fault, and an
      // error dialog thrown at a user who has just finished being welcomed
      // would be a worse first impression than the repeat.
      AppLog.error(
        () => 'recording the tutorial as seen failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'tutorial',
      );
    } finally {
      link.close();
    }
  }
}
