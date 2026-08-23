import 'package:flutter/material.dart';

import '../localization/generated/app_strings.dart';
import '../router/destinations.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';
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
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    required this.destination,
    required this.onDestinationSelected,
    required this.child,
    super.key,
  });

  final AppDestination destination;
  final ValueChanged<AppDestination> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final LayoutTier tier = context.tier;

    return switch (tier) {
      LayoutTier.mobile => _MobileShell(
        destination: destination,
        onDestinationSelected: onDestinationSelected,
        child: child,
      ),
      LayoutTier.tablet || LayoutTier.desktop => _RailShell(
        destination: destination,
        onDestinationSelected: onDestinationSelected,
        extended: tier.isDesktop,
        child: child,
      ),
    };
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
        child: NavigationBar(
          selectedIndex: destinations.indexOf(destination),
          onDestinationSelected: (int index) =>
              onDestinationSelected(destinations[index]),
          destinations: <Widget>[
            for (final AppDestination item in destinations)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label(strings),
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
