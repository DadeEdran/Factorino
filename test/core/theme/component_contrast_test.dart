import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:factorino/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/screen_harness.dart';

/// Every component that paints a label on its own background, **measured off
/// the pixels it actually painted**, in both brightnesses and in every state it
/// has.
///
/// **Why pixels rather than tokens.** The defect this file was written for was
/// not a wrong colour token, it was **no colour token at all** (D-066). The
/// theme set `chipTheme.labelStyle` to a `TextStyle` naming no colour;
/// Material's `RawChip` uses the theme's style *in place of* its own
/// state-dependent default rather than merging over it, so the label was
/// painted with the engine's fallback — **white** — and the light theme put
/// white text on a pale chip at a contrast ratio of **1.12:1**.
///
/// A test that read the theme and compared tokens would have had nothing to
/// compare: the whole failure is that the token is absent, and the value that
/// reaches the screen comes from neither the theme nor the scheme. Only the
/// rendered pixels know.
///
/// **It hid because the accident ran the right way in one place.** White on the
/// dark theme's `surfaceContainer` is about 14:1 and perfectly readable, so
/// dark mode looked fine; and the *checkmark* on a selected chip takes its
/// colour from a separate default that the flat `labelStyle` never touched, so
/// a selected chip showed a correctly-coloured tick beside an invisible word.
///
/// **The threshold is WCAG AA for body text, 4.5:1.** Chip labels are 12px, so
/// the large-text allowance of 3:1 does not apply to them. It is a floor, not a
/// target.
void main() {
  /// What one component painted its [label] in, and what it painted it on.
  ///
  /// **Sampled inside the label's own box**, which is the part that took two
  /// attempts to get right. Sampling the whole component and taking the colour
  /// furthest from the background finds the *checkmark* on a selected chip —
  /// which is correctly coloured — and so reports a healthy ratio for a chip
  /// whose label is invisible beside it. The assertion has to be about the text.
  Future<double> contrastOfLabel(
    WidgetTester tester,
    ThemeData theme,
    Widget component,
    String label,
  ) async {
    await loadPersianFont();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Center(
            child: RepaintBoundary(
              key: const ValueKey<String>('subject'),
              child: component,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const double scale = 3;
    final Rect boundary = tester.getRect(
      find.byKey(const ValueKey<String>('subject')),
    );
    final Rect text = tester.getRect(find.text(label));

    final ui.Image image = (await tester.runAsync<ui.Image>(() async {
      final RenderRepaintBoundary object = tester.renderObject(
        find.byKey(const ValueKey<String>('subject')),
      ) as RenderRepaintBoundary;
      // Captured larger than logical size, so a thin Persian stroke has an
      // interior rather than being entirely antialiasing.
      return object.toImage(pixelRatio: scale);
    }))!;
    final ByteData bytes = (await tester.runAsync<ByteData?>(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;

    final int left = ((text.left - boundary.left) * scale).floor();
    final int top = ((text.top - boundary.top) * scale).floor();
    final int right = ((text.right - boundary.left) * scale).ceil();
    final int bottom = ((text.bottom - boundary.top) * scale).ceil();

    final Map<int, int> counts = <int, int>{};
    for (int y = math.max(0, top); y < math.min(image.height, bottom); y++) {
      for (int x = math.max(0, left); x < math.min(image.width, right); x++) {
        final int i = (y * image.width + x) * 4;
        // Fully transparent pixels are outside the component, not part of it.
        if (bytes.getUint8(i + 3) < 255) continue;
        final int rgb =
            (bytes.getUint8(i) << 16) |
            (bytes.getUint8(i + 1) << 8) |
            bytes.getUint8(i + 2);
        counts[rgb] = (counts[rgb] ?? 0) + 1;
      }
    }

    final List<MapEntry<int, int>> byFrequency = counts.entries.toList()
      ..sort(
        (MapEntry<int, int> a, MapEntry<int, int> b) =>
            b.value.compareTo(a.value),
      );

    // The background is what most of the label's box is: letterforms never
    // cover more of their own line box than the space around them does.
    final int background = byFrequency.first.key;
    final double backgroundLuminance = _relativeLuminance(background);

    // **The glyph colour is the solid colour furthest from the background in
    // luminance, in whichever direction.** Not "the darkest, because text is
    // dark" — that assumption is exactly what a broken foreground breaks, and a
    // sampler that only looks downwards reports a pale-on-pale label as having
    // no foreground at all, which reads as a broken measurement rather than as
    // the defect it is.
    //
    // Three occurrences is the floor for "solid": Persian at 12px captured at
    // 3x is a few hundred pixels, most of them blends, so a threshold tuned on
    // blocky Latin glyphs finds no interior at all.
    int foreground = background;
    double furthest = 0;
    for (final MapEntry<int, int> entry in byFrequency) {
      if (entry.value < 3) continue;
      final double distance =
          (_relativeLuminance(entry.key) - backgroundLuminance).abs();
      if (distance > furthest) {
        furthest = distance;
        foreground = entry.key;
      }
    }

    return _contrastRatio(foreground, background);
  }

  /// Everything in the application that paints a label on its own background.
  ///
  /// **The filter chips are here because the payment sheet's choice chips were
  /// the ones reported** — same component, same theme entry, a different
  /// screen. "Check the same component everywhere else it is used" is not a
  /// thing to remember next time; it is a row in this table.
  final List<(String, Widget, String)> subjects = <(String, Widget, String)>[
    (
      'ChoiceChip, unselected',
      ChoiceChip(
        label: const Text('نقدی'),
        selected: false,
        onSelected: (_) {},
      ),
      'نقدی',
    ),
    (
      'ChoiceChip, selected',
      ChoiceChip(label: const Text('نقدی'), selected: true, onSelected: (_) {}),
      'نقدی',
    ),
    (
      'FilterChip, unselected',
      FilterChip(
        label: const Text('پرداخت نشده'),
        selected: false,
        onSelected: (_) {},
      ),
      'پرداخت نشده',
    ),
    (
      'FilterChip, selected',
      FilterChip(
        label: const Text('پرداخت نشده'),
        selected: true,
        onSelected: (_) {},
      ),
      'پرداخت نشده',
    ),
    (
      'ActionChip',
      ActionChip(label: const Text('انتخاب مشتری'), onPressed: () {}),
      'انتخاب مشتری',
    ),
  ];

  for (final (String brightness, ThemeData theme) in <(String, ThemeData)>[
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    for (final (String name, Widget component, String label) in subjects) {
      testWidgets('$brightness — $name', (WidgetTester tester) async {
        final double ratio = await contrastOfLabel(
          tester,
          theme,
          component,
          label,
        );

        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              '$name in $brightness paints its label at a contrast ratio of '
              '${ratio.toStringAsFixed(2)}:1 against the background it sits on. '
              'Below 4.5:1 the text is not readable, and the way this happens '
              'is not a wrong token but a missing one — a foreground nobody '
              'chose falls through to the engine default (D-066).',
        );
      });
    }
  }

  // ---------------------------------------------------------------------
  testWidgets('the probe reports a pale label as pale', (
    WidgetTester tester,
  ) async {
    // **The negative control this file needed** (D-072). Every subject above
    // passes, and a suite in which nothing ever fails cannot tell "every
    // component is readable" apart from "the probe stopped reading the glyph".
    //
    // The failure mode is specific: this measures the darkest pixel **inside
    // the label's rect**, so a probe that drifted onto a border, a shadow or
    // the background would report a healthier ratio than the text has — and
    // D-066's defect, a selected chip at 3.75:1, would sail through exactly as
    // it did before this file existed.
    //
    // #9E9E9E on white is 2.68:1 by the WCAG formula, computed independently.
    // If this starts failing because the number came back *higher*, the
    // instrument has drifted, not the theme.
    final double ratio = await contrastOfLabel(
      tester,
      AppTheme.light,
      const Chip(
        backgroundColor: Color(0xFFFFFFFF),
        label: Text('کنترل', style: TextStyle(color: Color(0xFF9E9E9E))),
      ),
      'کنترل',
    );

    expect(
      ratio,
      closeTo(2.68, 0.05),
      reason:
          'the probe measured ${ratio.toStringAsFixed(2)}:1 for a label whose '
          'true ratio is 2.68:1, so it is no longer sampling the glyph and '
          'every ratio in this file is read off the wrong pixel (D-072)',
    );
    expect(ratio, lessThan(4.5));
  });
}

/// WCAG relative luminance of a packed 24-bit RGB value.
double _relativeLuminance(int rgb) {
  double channel(int value) {
    final double v = value / 255;
    return v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel((rgb >> 16) & 0xFF) +
      0.7152 * channel((rgb >> 8) & 0xFF) +
      0.0722 * channel(rgb & 0xFF);
}

/// The WCAG contrast ratio between two packed RGB values.
double _contrastRatio(int a, int b) {
  final double la = _relativeLuminance(a);
  final double lb = _relativeLuminance(b);
  final double lighter = la > lb ? la : lb;
  final double darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
