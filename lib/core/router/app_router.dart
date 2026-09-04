import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/customers/presentation/customer_detail_screen.dart';
import '../../features/customers/presentation/customer_form_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/dashboard/presentation/daily_sales_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/invoices/presentation/invoice_detail_screen.dart';
import '../../features/invoices/presentation/invoice_editor_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/products/presentation/product_form_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../responsive/adaptive_scaffold.dart';
import 'destinations.dart';

/// The router (D-009).
///
/// **Only routes whose screens exist are registered.** The one route named in
/// the project spec that is still absent is product detail, and it arrives with
/// the screen it opens. `/invoices/new` arrived with Phase 4 (d) and
/// `/invoices/:id` with Phase 5 (b), each with its screen. Registering one
/// early would mean a typed URL or a restored deep link could land on a route
/// that resolves to nothing, which is the same failure D-021 rejects for
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
                // **Back moves inside the destination before it leaves it**
                // (D-104). `GoRouter.canPop` and `pop` both walk into the
                // branch navigator a `StatefulShellRoute` gives each
                // destination, so this is the current section's own stack and
                // not the shell's -- which is exactly the distinction the rule
                // is about, and the reason the shell cannot answer it.
                onPopSection: () {
                  final GoRouter router = GoRouter.of(context);
                  if (!router.canPop()) return false;
                  router.pop();
                  return true;
                },
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
          _branch(
            AppDestination.dashboard,
            const DashboardScreen(),
            children: <RouteBase>[
              // `/day`, under the dashboard, so the URL reads as a hierarchy
              // and the shell keeps داشبورد selected while it is open. The
              // dashboard's own path is `/`, so this is its only child and
              // there is no `:id` above it to swallow the literal segment.
              GoRoute(
                path: 'day',
                builder: (BuildContext context, GoRouterState state) =>
                    const DailySalesScreen(),
              ),
            ],
          ),
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
              // `:id/edit` before `:id` for the same reason `new` comes before
              // both: declaration order decides, and `:id` would otherwise
              // match `/invoices/x/edit` as a detail page.
              GoRoute(
                path: ':id/edit',
                builder: (BuildContext context, GoRouterState state) =>
                    InvoiceEditorScreen(invoiceId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) =>
                    InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
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

/// One destination's branch.
///
/// **No page transition, and that is the fix for the flash the owner saw when
/// switching tabs** (D-089). A branch root inside a
/// [StatefulShellRoute.indexedStack] is not pushed over anything: the shell
/// keeps every visited branch mounted and swaps which one is painted, so a
/// destination switch is an index change and not a navigation. Giving those
/// roots a `CustomTransitionPage` meant the incoming destination was drawn at
/// **zero opacity on its first frame** and faded up over 220 ms, while the
/// stack it sits in was already showing the new index — one frame of a page
/// that is not yet there, over a shell that has already moved, which is the
/// glitch. It is invisible on a desktop at 120 Hz and unmissable on a phone.
///
/// The transition was never buying anything here either. Bottom-bar and rail
/// navigation is not a push and every platform renders it instantly; the fade
/// existed because `_branch` was written before there were sub-routes to move
/// between. The sub-routes — `/invoices/:id`, the forms — keep the platform's
/// own transition, which is where a transition actually says something.
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
        pageBuilder: (BuildContext context, GoRouterState state) =>
            NoTransitionPage<void>(key: state.pageKey, child: screen),
      ),
    ],
  );
}
