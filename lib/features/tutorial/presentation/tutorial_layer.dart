import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/persian_text.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/router/back_policy.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../data/models/app_settings.dart';
import '../../settings/application/settings_providers.dart';
import '../application/tutorial_controller.dart';
import '../domain/tutorial_step.dart';

/// The first-run tutorial: eight plain screens, drawn over the whole shell.
///
/// ## Why plain screens and not a coach-mark overlay on the real controls
///
/// A step-through overlay pointing at real buttons was the other candidate and
/// it was rejected on a fact about the moment it would run, not on taste:
/// **the tutorial runs on an empty database, where most of the controls it
/// teaches do not exist.** There is no invoice on a first launch, so there is
/// no invoice page, no «ثبت پرداخت», no «خروجی PDF» and no issue action to
/// point at — five of the eight steps have no target. An overlay would have had
/// to seed demonstration data to have something to highlight, which §15
/// prohibits outright, or point at empty space.
///
/// The rest follows from that:
///
/// * **Rot.** A coach-mark is anchored to a widget by a key, and when that
///   widget moves or is renamed nothing fails — the arrow just points at the
///   wrong place, in a release build, on somebody's phone. §10 has three
///   recorded cases of a card being moved after it shipped; every one of them
///   would have silently invalidated an anchor. A tutorial pointing at a moved
///   button is worse than none, and there is no compile-time check that would
///   have caught it.
/// * **Three tiers and RTL.** A cut-out has geometry: it has to be right at
///   every width, over a `NavigationBar` on a phone and a rail on the right in
///   Persian, and it has to survive the font-size setting that has already
///   broken two layouts here (D-108, D-114). These screens are one centred
///   column with a scrolling middle and a pinned footer — the shape D-053 and
///   D-062 arrived at, which is already known to hold on all three tiers.
///
/// **What is done instead of pointing, so the words cannot rot either:** every
/// sentence that names a section fills the name in from `AppDestination` rather
/// than spelling it in the ARB, so the tutorial quotes the label the navigation
/// bar actually draws. See [TutorialStep.body].
///
/// ## It draws nothing until it knows
///
/// Same rule as the seller prompt (D-102): while the settings row is loading or
/// has failed, this renders nothing rather than assuming the flag is null. A
/// tutorial that flashed on every cold start before the read landed would greet
/// a user who has been running the application for a year.
class TutorialLayer extends ConsumerStatefulWidget {
  const TutorialLayer({super.key});

  @override
  ConsumerState<TutorialLayer> createState() => _TutorialLayerState();
}

class _TutorialLayerState extends ConsumerState<TutorialLayer> {
  /// Whether the first-launch question has been answered this session.
  ///
  /// The auto-start decision is taken **once**, from the first settings value
  /// that arrives, and never again — `appSettingsProvider` is a live query, so
  /// without this every later write to the settings row would be a chance to
  /// reopen a tutorial the user has just closed.
  bool _autoStartDecided = false;

  @override
  Widget build(BuildContext context) {
    _considerAutoStart(ref.watch(appSettingsProvider));

    final TutorialStep? step = ref.watch(tutorialControllerProvider);
    if (step == null) return const SizedBox.shrink();

    return _TutorialSheet(step: step);
  }

  void _considerAutoStart(AsyncValue<AppSettings> settings) {
    if (_autoStartDecided) return;

    // Loading, or failed: decide nothing. Not "assume it has never been shown".
    final AppSettings? value = settings.value;
    if (value == null) return;

    _autoStartDecided = true;
    if (value.tutorialSeenAt != null) return;

    // After the frame, because this runs during `build` and starting the
    // tutorial changes a provider the same build is reading.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      ref.read(tutorialControllerProvider.notifier).start();
    });
  }
}

/// One step, full-bleed.
class _TutorialSheet extends ConsumerStatefulWidget {
  const _TutorialSheet({required this.step});

  final TutorialStep step;

  @override
  ConsumerState<_TutorialSheet> createState() => _TutorialSheetState();
}

class _TutorialSheetState extends ConsumerState<_TutorialSheet> {
  /// The system back press, while this is on screen.
  ///
  /// **Registered with [BackClaims] rather than as a second
  /// `BackButtonListener`**, which is the whole point of that class: nested
  /// listeners do not hand priority back, and a second one here would leave the
  /// back button silently dead after the tutorial had been shown once. See
  /// `back_policy.dart`.
  ///
  /// Without a claim the press would fall through to the application-wide rule
  /// and be answered by the shell **behind** the tutorial — on a first launch
  /// that means the exit prompt appearing invisibly under this layer and the
  /// second press closing the application.
  ///
  /// A field bound to a method rather than a closure written here, so the
  /// identity [BackClaims.release] checks stays the same object across every
  /// rebuild — the same shape `invoice_editor_screen.dart` uses.
  late final BackClaim _claim = _onSystemBack;

  BackClaims? _claims;

  Future<bool> _onSystemBack() async {
    // On the first step there is nothing behind: back leaves, exactly as
    // «رد کردن» does. Conventional on Android, and not a hidden destructive
    // action — the visible skip control does the same thing, and the tutorial
    // can be replayed from settings whenever the user wants it.
    if (widget.step.isFirst) {
      await ref.read(tutorialControllerProvider.notifier).dismiss();
      return true;
    }
    ref.read(tutorialControllerProvider.notifier).back();
    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // In `didChangeDependencies` rather than `initState`, because reading an
    // inherited widget is not allowed in the latter.
    final BackClaims? claims = BackPolicyScope.maybeOf(context);
    if (identical(claims, _claims)) return;
    _claims?.release(_claim);
    _claims = claims;
    _claims?.claim(_claim);
  }

  @override
  void dispose() {
    _claims?.release(_claim);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final TutorialStep step = widget.step;
    final TutorialController controller = ref.read(
      tutorialControllerProvider.notifier,
    );

    return Material(
      // Opaque, and the surface colour rather than a scrim over the shell. A
      // translucent overlay would put the application's own chrome behind the
      // words at a contrast nobody designed, in both themes.
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // One centred column at every tier, capped at a readable measure.
            // There is deliberately no tier branch in this file: the layout
            // that works on a phone is the layout that works on a desktop
            // window, and a variant per tier is three things to keep true
            // instead of one.
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Header(
                    step: step,
                    strings: strings,
                    onSkip: controller.dismiss,
                  ),
                  // **The middle scrolls and the actions are pinned**, which is
                  // D-062's shape: at a 400x800 phone with the font-size
                  // setting turned up, an icon, a heading and a sentence can
                  // exceed the height, and the control that leaves must not be
                  // the thing that goes off the bottom.
                  Expanded(
                    child: SingleChildScrollView(
                      child: _Body(step: step, strings: strings, theme: theme),
                    ),
                  ),
                  _Footer(
                    step: step,
                    strings: strings,
                    onBack: controller.back,
                    onNext: step.isLast ? controller.dismiss : controller.next,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The step counter, and the skip control that is present on every step.
class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.strings,
    required this.onSkip,
  });

  final TutorialStep step;
  final AppStrings strings;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            strings.tutorialProgress(
              // Persian digits, like every other number in the application
              // (§9). The placeholders are strings for exactly this reason —
              // an ICU number would render `1` and `8`.
              toPersianDigits('${step.index + 1}'),
              toPersianDigits('${TutorialStep.values.length}'),
            ),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        // **On every step, not only the first.** A user who has understood the
        // application three screens in must not have to page through the rest
        // to get out of it.
        TextButton(onPressed: onSkip, child: Text(strings.tutorialSkip)),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.step, required this.strings, required this.theme});

  final TutorialStep step;
  final AppStrings strings;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: AppSpacing.xxl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(
            step.icon,
            size: AppIconSize.xxl,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(step.title(strings), style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        Text(
          step.body(strings),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// The progress dots and the two navigation actions, pinned.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.strings,
    required this.onBack,
    required this.onNext,
  });

  final TutorialStep step;
  final AppStrings strings;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (final TutorialStep other in TutorialStep.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                child: Container(
                  width: AppSpacing.sm,
                  height: AppSpacing.sm,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: other == step
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // `OverflowBar` for the reason the backup actions use one (D-108): the
        // two labels take their natural width and stack when the width and the
        // user's font size together stop allowing a row, rather than being
        // crushed inside an even split.
        OverflowBar(
          spacing: AppSpacing.md,
          overflowSpacing: AppSpacing.sm,
          overflowAlignment: OverflowBarAlignment.start,
          children: <Widget>[
            // Absent rather than disabled on the first step: there is nothing
            // behind it, and a dead control is a question the user has to
            // answer.
            if (!step.isFirst)
              OutlinedButton(
                onPressed: onBack,
                child: Text(strings.tutorialBack),
              ),
            FilledButton(
              onPressed: onNext,
              child: Text(
                step.isLast ? strings.tutorialDone : strings.tutorialNext,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
