import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/customers/presentation/customer_form_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/products/presentation/product_form_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../responsive/adaptive_scaffold.dart';
import '../theme/app_dimensions.dart';
import 'destinations.dart';

/// The router (D-009).
///
/// **Only routes whose screens exist are registered.** The detail and create
/// routes named in the project spec — customer detail, product detail, invoice
/// detail, create/edit invoice — arrive with the screens they open, in later
/// increments. Registering them now would mean a typed URL or a restored deep
/// link could land on a route that resolves to nothing, which is the same
/// failure D-021 rejects for گزارش‌ها, one level down.
///
/// گزارش‌ها itself is absent from both the destination list and this file
/// (D-021), and arrives in Phase 8.
///
/// A [StatefulShellRoute] rather than plain routes under a shell: each
/// destination keeps its own navigation stack and its own scroll position, so
/// moving from an invoice list back to the dashboard and returning does not
/// reset where the user was.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppDestination.dashboard.path,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell shell,
            ) {
              return AdaptiveScaffold(
                destination: AppDestination.values[shell.currentIndex],
                onDestinationSelected: (AppDestination destination) {
                  shell.goBranch(
                    AppDestination.values.indexOf(destination),
                    // Tapping the destination you are already on returns it to
                    // its root -- the behaviour every platform's navigation
                    // bar has, and one users reach for without thinking.
                    initialLocation:
                        shell.currentIndex ==
                        AppDestination.values.indexOf(destination),
                  );
                },
                child: shell,
              );
            },
        branches: <StatefulShellBranch>[
          _branch(AppDestination.dashboard, const DashboardScreen()),
          _branch(AppDestination.invoices, const InvoicesScreen()),
          _branch(
            AppDestination.customers,
            const CustomersScreen(),
            // The forms are children of the destination, so the URL reads as a
            // hierarchy and the shell keeps مشتریان selected while one is open.
            children: <RouteBase>[
              GoRoute(
                path: 'new',
                builder: (BuildContext context, GoRouterState state) =>
                    const CustomerFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (BuildContext context, GoRouterState state) =>
                    CustomerFormScreen(customerId: state.pathParameters['id']),
              ),
            ],
          ),
          _branch(
            AppDestination.products,
            const ProductsScreen(),
            children: <RouteBase>[
              GoRoute(
                path: 'new',
                builder: (BuildContext context, GoRouterState state) =>
                    const ProductFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (BuildContext context, GoRouterState state) =>
                    ProductFormScreen(productId: state.pathParameters['id']),
              ),
            ],
          ),
          _branch(AppDestination.settings, const SettingsScreen()),
        ],
      ),
    ],
  );
}

/// One destination's branch, with a transition that is subtle and fast (§10).
StatefulShellBranch _branch(
  AppDestination destination,
  Widget screen, {
  List<RouteBase> children = const <RouteBase>[],
}) {
  return StatefulShellBranch(
    routes: <RouteBase>[
      GoRoute(
        path: destination.path,
        routes: children,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: AppDuration.medium,
            reverseTransitionDuration: AppDuration.fast,
            child: screen,
            transitionsBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondary,
                  Widget child,
                ) {
                  // A short fade with a few pixels of rise. No horizontal
                  // slide: in an RTL layout a slide has to be mirrored to feel
                  // right, and a vertical motion sidesteps the question while
                  // reading as "this replaced that" just as clearly.
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.012),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  );
                },
          );
        },
      ),
    ],
  );
}
