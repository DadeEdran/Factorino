import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/responsive/adaptive_scaffold.dart';
import 'package:factorino/core/router/destinations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/screen_harness.dart';

/// The bottom navigation bar's five destinations are five of the same thing
/// (D-088).
///
/// **The defect this pins was reported from a phone as "the «محصولات و خدمات»
/// button is a different size from the others".** It was not a spacing
/// oversight. `NavigationDestination.label` is a `String` that Material renders
/// as a bare `Text` with no line limit, and that phrase is long enough to wrap
/// where the other four do not — and
/// `_NavigationDestinationLayoutDelegate.performLayout` places the selected
/// icon at `halfHeight(icon) + halfHeight(label)` above centre. So the one
/// two-line label lifted its own icon half a line clear of its neighbours',
/// which is exactly what a person sees and cannot name.
///
/// Every assertion below is a **measurement**, not an inspection of the fix: it
/// would fail again the moment a destination's label wraps, whichever way that
/// came about, and it would have failed before the fix.
void main() {
  Future<AppStrings> pumpShell(
    WidgetTester tester, {
    required AppDestination selected,
    Size size = kMobileSize,
  }) async {
    await pumpScreen(
      tester,
      AdaptiveScaffold(
        // Nothing is stacked over a destination here, so there is never a
        // page inside one to pop (D-104).
        onPopSection: () => false,
        destination: selected,
        onDestinationSelected: (_) {},
        child: const SizedBox.expand(),
      ),
      size: size,
    );
    await tester.pumpAndSettle();
    return stringsOf(tester, AdaptiveScaffold);
  }

  /// The five destination icons, in bar order.
  List<Finder> icons(AppDestination selected) => <Finder>[
    for (final AppDestination d in AppDestination.values)
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(d == selected ? d.selectedIcon : d.icon),
      ),
  ];

  testWidgets('every destination label occupies the same height', (
    WidgetTester tester,
  ) async {
    // **The measurement, stated as the defect was.** A label that wraps is
    // taller than one that does not, and that height is what the layout
    // delegate reads to place the icon. Comparing the five heights asks the
    // question directly rather than through a proxy: before the fix
    // «محصولات و خدمات» measured a second line and the other four did not. The
    // label has since been shortened to «محصولات», which removes the cause —
    // but the clamp and this measurement stay, because they hold for whatever
    // the five labels become next.
    final AppStrings strings = await pumpShell(
      tester,
      selected: AppDestination.dashboard,
    );

    final Map<String, double> heights = <String, double>{};
    for (final AppDestination destination in AppDestination.values) {
      final Finder label = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(destination.label(strings)),
      );
      expect(label, findsOneWidget, reason: '${destination.name} is missing');
      heights[destination.name] = tester.getSize(label).height;
    }

    expect(
      heights.values.toSet(),
      hasLength(1),
      reason:
          'the destination labels measure $heights — one of them wraps, which '
          'moves its icon relative to the other four (D-088)',
    );
  });

  testWidgets('every destination icon sits at the same height', (
    WidgetTester tester,
  ) async {
    // The visible symptom, measured directly. Selection is what makes the
    // delegate consult the label's height at all, so the check is run with
    // every destination selected in turn -- a single-state check would have
    // missed the original defect on four of its five runs.
    for (final AppDestination selected in AppDestination.values) {
      await pumpShell(tester, selected: selected);

      final List<double> tops = <double>[
        for (final Finder icon in icons(selected)) tester.getTopLeft(icon).dy,
      ];

      expect(
        tops.toSet(),
        hasLength(1),
        reason:
            'with ${selected.name} selected the icons sit at $tops — one '
            'destination is a different size from the others (D-088)',
      );
    }
  });

  testWidgets(
    'and at the narrowest supported phone, where the label is tightest',
    (WidgetTester tester) async {
      // 328 is the narrowest width `width_sweep_test` covers, and five equal
      // shares of it is 65 logical pixels each.
      await pumpShell(
        tester,
        selected: AppDestination.products,
        size: const Size(328, 800),
      );

      final List<double> tops = <double>[
        for (final Finder icon in icons(AppDestination.products))
          tester.getTopLeft(icon).dy,
      ];
      expect(tops.toSet(), hasLength(1));
      expect(tester.takeException(), isNull);

      // **The abbreviation is gone, and this is the line that says so.** This
      // assertion used to be `isTrue`, with a comment pinning the cost of a
      // label that could not fit: «محصولات و خدمات» really was ellipsised at an
      // equal fifth of a 328-wide bar, and the note said that if a future change
      // ever made it fit, deleting the line should be a deliberate act rather
      // than a discovery. Renaming the destination to «محصولات» is that change,
      // so the assertion is inverted rather than removed — the label now fits
      // whole at the narrowest width the application supports, and a future
      // label long enough to break that will fail here.
      final AppStrings strings = stringsOf(tester, AdaptiveScaffold);
      expect(
        tester
            .renderObject<RenderParagraph>(
              find.descendant(
                of: find.byType(NavigationBar),
                matching: find.text(strings.navProducts),
              ),
            )
            .didExceedMaxLines,
        isFalse,
        reason:
            'no navigation label may be abbreviated at the narrowest '
            'supported phone width',
      );
    },
  );

  testWidgets('the full label is still reachable, as the destination tooltip', (
    WidgetTester tester,
  ) async {
    // **The tooltip survives the rename, and still earns its place.** §11
    // names «محصولات و خدمات», and that phrase is still the *screen's* heading
    // — `productsTitle` — while the navigation item is now the shorter
    // «محصولات». `NavigationDestination` uses its label as its own tooltip, so
    // a user who is unsure what a five-item bar means can still hold a
    // destination and read it. Nothing is abbreviated at any supported width
    // any more, but the affordance is free and removing it would only make the
    // bar less legible.
    final AppStrings strings = await pumpShell(
      tester,
      selected: AppDestination.dashboard,
      size: const Size(328, 800),
    );

    expect(
      find.byTooltip(strings.navProducts),
      findsOneWidget,
      reason: 'the destination carries its own label as a tooltip',
    );
  });

  testWidgets('the wider tiers show the whole label, unabbreviated', (
    WidgetTester tester,
  ) async {
    // The rail has the width the bar does not, and this is what makes the
    // trade above acceptable rather than a loss.
    final AppStrings strings = await pumpShell(
      tester,
      selected: AppDestination.dashboard,
      size: kDesktopSize,
    );

    final Finder label = find.descendant(
      of: find.byType(NavigationRail),
      matching: find.text(strings.navProducts),
    );
    expect(label, findsOneWidget);

    expect(
      tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
      isFalse,
      reason:
          'the extended rail is where the full phrase is read; if it truncates '
          'here there is nowhere left that shows it',
    );
  });
}
