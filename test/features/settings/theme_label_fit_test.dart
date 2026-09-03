import 'dart:async';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/settings_repository.dart';
import 'package:factorino/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/text_fit.dart';
import '../screen_harness.dart';

/// The three theme labels, at every phone width and every font size a phone
/// offers (D-108).
///
/// **The defect this pins.** The owner's second phone report: «سیستم» rendering
/// as «سیست» over «م». `SegmentedButton` divides its width evenly between its
/// segments and each segment spent 18 logical pixels on a leading icon plus 8
/// on the gap before it; the label is `Flexible` inside what remains. That is a
/// *crush*, not an overflow — a flexible child handed too little width lays out
/// successfully at too little width, and `RenderFlex` has nothing to complain
/// about — so nothing failed. The measurements, taken on this harness:
///
/// | width | label box | «سیستم» needs |
/// |---|---|---|
/// | 320 | **30.7** | 45.0 |
/// | 360 | **44.0** | 45.0 |
/// | 400 | 45.0 | 45.0 |
///
/// So it broke outright below 360, and at 400 it had **exactly zero pixels of
/// margin** — which is why a phone whose owner has moved the font-size slider
/// one notch sees it and a test at 1.0 never does. Removing the icons returns
/// 26 pixels per segment; the labels now fit at every width here up to 2.0×, and
/// the widest phone case, 400 at 1.3, clears by a wide margin.
///
/// **The scale ladder is Android's own**, not round numbers: the font-size
/// setting offers 0.85 / 1.0 / 1.15 / 1.3, and 1.3 is therefore the ceiling a
/// phone can actually be in, in the same spirit as D-057's amount ladder and
/// D-062's measured 255-pixel keyboard. The width ladder is the phone tier from
/// its narrowest realistic device up.
///
/// **Why this is its own file and not a line in the settings screen's tests.**
/// Those pump one width at 1.0, which is the state that could not see this.
void main() {
  const AppSettings settings = AppSettings(
    defaultTaxRateBp: 900,
    roundingUnitRial: 0,
    invoiceNumberPrefix: 'INV',
    paymentTermDays: 45,
  );

  /// Phone widths, narrowest first. 320 is a small phone in portrait; 400 is
  /// the tier's own `kMobileSize`.
  const List<double> widths = <double>[320, 360, 400];

  /// What Android's font-size setting can actually be set to.
  const List<double> scales = <double>[0.85, 1.0, 1.15, 1.3];

  Future<AppStrings> pumpAppearance(
    WidgetTester tester, {
    required double width,
    required double scale,
  }) async {
    await pumpScreen(
      tester,
      const SettingsScreen(),
      size: Size(width, 900),
      textScaler: TextScaler.linear(scale),
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(
          _FakeSettingsRepository(settings),
        ),
      ],
    );
    await tester.pumpAndSettle();

    final AppStrings strings = stringsOf(tester, SettingsScreen);
    // The appearance card is past the fold on a phone, and past the cache
    // extent it is not in the tree at all — a finder would return nothing,
    // which reads as a missing widget rather than an off-screen one.
    await tester.scrollUntilVisible(
      find.text(strings.settingsThemeModeSystem),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    return strings;
  }

  for (final double width in widths) {
    for (final double scale in scales) {
      testWidgets(
        'the theme labels fit at ${width.toInt()} px, text scale $scale',
        (WidgetTester tester) async {
          final AppStrings strings = await pumpAppearance(
            tester,
            width: width,
            scale: scale,
          );

          for (final String label in <String>[
            strings.settingsThemeModeSystem,
            strings.settingsThemeModeLight,
            strings.settingsThemeModeDark,
          ]) {
            final RenderParagraph paragraph = tester
                .renderObject<RenderParagraph>(find.text(label));
            final double needed = paragraph.getMinIntrinsicWidth(
              double.infinity,
            );

            expect(
              paragraph.size.width,
              greaterThanOrEqualTo(needed),
              reason:
                  '«$label» was laid out at '
                  '${paragraph.size.width.toStringAsFixed(1)} logical pixels '
                  'and its longest word needs ${needed.toStringAsFixed(1)} at '
                  '${width.toInt()} px, text scale $scale. Narrower than its '
                  'own word means it breaks inside the word — «سیست» over «م» — '
                  'which is what the owner saw and is worse than a truncation, '
                  'because a Persian letter split from its neighbours changes '
                  'shape. Give the segments room; do not shrink the text '
                  '(D-108).',
            );
          }

          // The same claim made the shared way, over the whole card rather than
          // the three labels this file is named for: the owner asked that the
          // other labels be checked at the same widths, and there is no reason
          // to ask it only of these three.
          expectNoCrushedText(
            tester,
            where: 'the settings screen at ${width.toInt()} px, scale $scale',
          );
        },
      );
    }
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._current);

  AppSettings _current;

  @override
  Future<AppSettings> read() async => _current;

  @override
  Stream<AppSettings> watch() => Stream<AppSettings>.value(_current);

  @override
  Future<AppSettings> write(AppSettings settings) async {
    _current = settings;
    return settings;
  }

  @override
  Future<void> markBackedUp(DateTime at) async {}
}
