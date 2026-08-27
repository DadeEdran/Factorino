import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/customers/presentation/customer_detail_screen.dart';
import '../../features/customers/presentation/customer_form_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/invoices/presentation/invoice_editor_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/products/presentation/product_form_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../responsive/adaptive_scaffold.dart';
import '../theme/app_dimensions.dart';
import 'destinations.dart';

/// The router (D-009).
///
/// **Only routes whose screens exist are registered.** The remaining routes
/// named in the project spec — product detail and invoice detail — arrive with
/// the screens they open, in later phases. `/invoices/new` arrived with
/// Phase 4 (d). Registering
/// them now would mean a typed URL or a restored deep link could land on a
/// route that resolves to nothing, which is the same failure D-021 rejects for
/// گزارش‌ها, one level down.
///
/// Customer detail arrived in Phase 2, with its screen. `/products/:id` did
/// not: the edit form already shows every field a product has, and the one
/// question a detail page could answer that the form cannot — where has this
/// been sold, and at what price — is a report, so it registers in Phase 8 with
/// the screen that answers it (D-042).
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
          _branch(
            AppDestination.invoices,
            const InvoicesScreen(),
            children: <RouteBase>[
              // `new` first, as under /customers: go_router matches in
              // declaration order, and a future `/invoices/:id` declared above
              // this would resolve /invoices/new to a detail page for an
              // invoice whose id is the word "new".
              GoRoute(
                path: 'new',
                builder: (BuildContext context, GoRouterState state) =>
                    const InvoiceEditorScreen(),
              ),
            ],
          ),
          _branch(
            AppDestination.customers,
            const CustomersScreen(),
            // The forms are children of the destination, so the URL reads as a
            // hierarchy and the shell keeps مشتریان selected while one is open.
            children: <RouteBase>[
              // `new` before `:id`: go_router matches in declaration order, so
              // the reverse would resolve /customers/new to a detail page for a
              // customer whose id is the word "new" -- which renders the
              // not-found state rather than the form, and looks like the form
              // is broken.
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
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) =>
                    CustomerDetailScreen(
                      customerId: state.pathParameters['id']!,
                    ),
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
