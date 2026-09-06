// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutorial_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(TutorialController)
final tutorialControllerProvider = TutorialControllerProvider._();

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
final class TutorialControllerProvider
    extends $NotifierProvider<TutorialController, TutorialStep?> {
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
  TutorialControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tutorialControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tutorialControllerHash();

  @$internal
  @override
  TutorialController create() => TutorialController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TutorialStep? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TutorialStep?>(value),
    );
  }
}

String _$tutorialControllerHash() =>
    r'3fdb81e504927b92baa55c0404691e6424032659';

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

abstract class _$TutorialController extends $Notifier<TutorialStep?> {
  TutorialStep? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TutorialStep?, TutorialStep?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TutorialStep?, TutorialStep?>,
              TutorialStep?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
