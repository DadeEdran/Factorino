import 'package:flutter/material.dart';

import '../localization/generated/app_strings.dart';
import '../router/back_policy.dart';
import '../router/destinations.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';
import '../widgets/transient_message_scope.dart';
import 'breakpoints.dart';

/// The application shell: navigation chrome plus the current destination.
///
/// **Three genuinely different layouts, not one stretched** (§10):
///
/// | Tier | Navigation | Content |
/// |---|---|---|
/// | Mobile | `NavigationBar` along the bottom, thumb-reachable | single column, full-bleed |
/// | Tablet | compact `NavigationRail`, icons with labels | single column, wider gutters |
/// | Desktop | extended rail with a header, 232 px | centred column capped at a readable measure |
///
/// The rail sits on the **right** in RTL without any work here: `Row` resolves
/// its children against the ambient `Directionality`, so the first child is the
/// leading edge, which in Persian is the right. Positioning it explicitly would
/// be fighting the framework, which §9 warns against.
class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({
    required this.destination,
    required this.onDestinationSelected,
    required this.onPopSection,
    required this.child,
    this.overlay,
    super.key,
  });

  final AppDestination destination;
  final ValueChanged<AppDestination> onDestinationSelected;

  /// Pops one page inside the destination on screen, reporting whether it had
  /// one to pop. Passed straight to [AppBackPolicy]; see D-104.
  ///
  /// The shell does not answer this itself because only the router knows, and
  /// keeping `go_router` out of `core/responsive/` is what makes this file a
  /// layout concern and nothing else.
  final bool Function() onPopSection;

  final Widget child;

  /// A layer drawn over the whole shell, navigation chrome included.
  ///
  /// **A slot rather than a widget this file knows about**, so `core/` does not
  /// acquire a dependency on a feature: the router supplies what goes in it,
  /// and this file stays a layout concern. It is a parameter here rather than a
  /// `Stack` around `AdaptiveScaffold` at the call site for one reason that is
  /// not cosmetic — everything inside this widget sits under
  /// [BackPolicyScope], and a layer outside it could not claim the system back
  /// press. One that could not claim it would be navigated out from underneath,
  /// invisibly.
  ///
  /// Null on every tier and in every test that does not need one.
  final Widget? overlay;

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  /// Held by the shell rather than rebuilt, so a screen's claim survives the
  /// rebuilds a destination switch causes. See [BackClaims].
  final BackClaims _backClaims = BackClaims();

  @override
  Widget build(BuildContext context) {
    final LayoutTier tier = context.tier;

    final Widget shell = switch (tier) {
      LayoutTier.mobile => _MobileShell(
        destination: widget.destination,
        onDestinationSelected: widget.onDestinationSelected,
        child: widget.child,
      ),
      LayoutTier.tablet || LayoutTier.desktop => _RailShell(
        destination: widget.destination,
        onDestinationSelected: widget.onDestinationSelected,
        extended: tier.isDesktop,
        child: widget.child,
      ),
    };

    // **The only `BackButtonListener` in the application**, wrapping the whole
    // shell so every destination and every page inside one is covered by the
    // same rule. See [AppBackPolicy] for why there is exactly one.
    //
    // [TransientMessageScope] sits with it for the same reason: both are
    // application-wide behaviour about chrome rather than about any one screen,
    // and the shell is the one place that is always mounted.
    return TransientMessageScope(
      child: AppBackPolicy(
        claims: _backClaims,
        isHome: widget.destination == AppDestination.dashboard,
        onPopSection: widget.onPopSection,
        onGoHome: () => widget.onDestinationSelected(AppDestination.dashboard),
        // The overlay is a sibling of the shell **inside** the back policy, so
        // whatever it holds can claim the press; see [AdaptiveScaffold.overlay].
        // It is also above the navigation bar and the rail, which is what makes
        // it an overlay rather than a page.
        child: widget.overlay == null
            ? shell
            : Stack(
                children: <Widget>[
                  shell,
                  Positioned.fill(child: widget.overlay!),
                ],
              ),
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.destination,
    required this.onDestinationSelected,
    required this.child,
  });

  final AppDestination destination;
  final ValueChanged<AppDestination> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const List<AppDestination> destinations = AppDestination.values;
    final AppStrings strings = AppStrings.of(context);

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: AppBorders.hairline,
            ),
          ),
        ),
        // **Every destination's label is one line, and that is a fix rather
        // than a preference.** `NavigationDestination.label` is a `String`
        // that Material renders as a bare `Text` with no line limit, and
        // «محصولات و خدمات» was long enough to wrap where the other four did
        // not. That label has since been shortened to «محصولات», which removes
        // the cause; the clamp stays because it is a property of the bar rather
        // than of one string, and the next long label would land here again.
        // That is not merely untidy: the destination's icon and label are
        // placed by `_NavigationDestinationLayoutDelegate`, whose selected-state
        // icon offset is `halfHeight(icon) + halfHeight(label)` — so the one
        // two-line label lifted its icon half a line above the other four and
        // made that button visibly a different size, which is exactly what was
        // reported from the phone.
        //
        // `Text` falls back to the ambient `DefaultTextStyle` for `maxLines`
        // and `overflow` when it is given neither, which is the only seam
        // Material leaves open here — a merge rather than a replacement, so the
        // theme's label style still decides everything about how it looks.
        //
        // **Around each destination, not around the bar**, and that is a
        // measured detail rather than a stylistic one: `NavigationBar` builds
        // its own `Material`, whose `AnimatedDefaultTextStyle` replaces the
        // ambient one — so a merge outside the bar is discarded before the
        // label is built, and the destination goes on wrapping. `destinations`
        // is a `List<Widget>` and each entry becomes the child of the bar's
        // per-destination info widget, which is below that `Material`, so this
        // is the innermost point the application can reach. Found by
        // `navigation_bar_test.dart`, which measured 36 logical pixels against
        // the other four destinations' 18 with the wrapper on the outside.
        //
        // **The cost is stated rather than hidden:** on a narrow phone the
        // longest label ellipsises, because five equal shares of 328 logical
        // pixels is 65 each and the Persian phrase does not fit in that at any
        // size worth reading. It is not lost — `NavigationDestination` uses the
        // label as its own tooltip, and the full phrase is what the tablet and
        // desktop rails show. Five identical buttons with one abbreviated word
        // beats four aligned buttons and one that is not. See D-088.
        child: NavigationBar(
          selectedIndex: destinations.indexOf(destination),
          onDestinationSelected: (int index) =>
              onDestinationSelected(destinations[index]),
          destinations: <Widget>[
            for (final AppDestination item in destinations)
              DefaultTextStyle.merge(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label(strings),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailShell extends StatelessWidget {
  const _RailShell({
    required this.destination,
    required this.onDestinationSelected,
    required this.extended,
    required this.child,
  });

  final AppDestination destination;
  final ValueChanged<AppDestination> onDestinationSelected;

  /// Desktop shows labels beside the icons; tablet shows them beneath, which
  /// keeps the rail narrow enough to leave the content real room.
  final bool extended;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const List<AppDestination> destinations = AppDestination.values;
    final ThemeData theme = Theme.of(context);
    final AppStrings strings = AppStrings.of(context);

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: extended
                    ? AppLayout.navigationRailWidth
                    : AppLayout.navigationRailCompactWidth,
                maxWidth: extended
                    ? AppLayout.navigationRailWidth
                    : AppLayout.navigationRailCompactWidth,
              ),
              child: NavigationRail(
                extended: extended,
                minWidth: AppLayout.navigationRailCompactWidth,
                minExtendedWidth: AppLayout.navigationRailWidth,
                labelType: extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                selectedIndex: destinations.indexOf(destination),
                onDestinationSelected: (int index) =>
                    onDestinationSelected(destinations[index]),
                leading: extended
                    ? _RailHeader(title: strings.appTitle)
                    : const SizedBox(height: AppSpacing.lg),
                destinations: <NavigationRailDestination>[
                  for (final AppDestination item in destinations)
                    NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: extended
                          ? Text(item.label(strings))
                          // Compact: the label sits beneath its icon inside a
                          // narrow rail, so it is given an explicit measure
                          // and allowed a second line. Without this the
                          // longest destination overflows the rail at exactly
                          // one breakpoint.
                          : SizedBox(
                              width: AppLayout.navigationRailLabelWidth,
                              child: Text(
                                item.label(strings),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs,
                      ),
                    ),
                ],
              ),
            ),
            VerticalDivider(
              width: AppBorders.hairline,
              thickness: AppBorders.hairline,
              color: theme.colorScheme.outlineVariant,
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// The product name above the rail on desktop.
///
/// Desktop has the vertical room for it and gains from the anchor; mobile does
/// not, and a title bar there would cost a line of content on every screen.
class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.receipt_long,
            size: AppIconSize.lg,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              title,
              style: AppTypography.sectionTitle.copyWith(
                color: theme.colorScheme.onSurface,
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
