import 'package:flutter/material.dart';

import '../localization/generated/app_strings.dart';

/// The navigation destinations, in display order.
///
/// **گزارش‌ها is absent, and its route is not registered either** (D-021). Not
/// disabled, not a coming-soon placeholder: The project spec forbids a dead nav
/// item, and omission is the stronger of the two options it permits. It arrives
/// in Phase 8, when it does something — and because the route is unregistered,
/// no deep link or typed web URL can reach a screen that does not exist either.
enum AppDestination {
  dashboard('/'),
  invoices('/invoices'),
  customers('/customers'),
  products('/products'),
  settings('/settings');

  const AppDestination(this.path);

  /// The URL. Real and shareable on the web, and the deep-link target on
  /// Windows and Android (D-009).
  final String path;

  /// The Persian label. Resolved from the localization layer rather than stored
  /// here, so no navigation string is hardcoded (§1).
  String label(AppStrings strings) => switch (this) {
    AppDestination.dashboard => strings.navDashboard,
    AppDestination.invoices => strings.navInvoices,
    AppDestination.customers => strings.navCustomers,
    AppDestination.products => strings.navProducts,
    AppDestination.settings => strings.navSettings,
  };

  /// The outline icon, shown when the destination is not selected.
  ///
  /// None of these mirror in RTL, and none should: they are object icons, not
  /// directional ones (§9). A back arrow would mirror; a receipt does not.
  IconData get icon => switch (this) {
    AppDestination.dashboard => Icons.dashboard_outlined,
    AppDestination.invoices => Icons.receipt_long_outlined,
    AppDestination.customers => Icons.people_outline,
    AppDestination.products => Icons.inventory_2_outlined,
    AppDestination.settings => Icons.settings_outlined,
  };

  /// The filled counterpart, shown when selected. The weight change is what
  /// makes the selection legible without relying on colour alone.
  IconData get selectedIcon => switch (this) {
    AppDestination.dashboard => Icons.dashboard,
    AppDestination.invoices => Icons.receipt_long,
    AppDestination.customers => Icons.people,
    AppDestination.products => Icons.inventory_2,
    AppDestination.settings => Icons.settings,
  };
}

/// Routes that are not navigation destinations: the forms a destination opens.
///
/// Registered **with the screens they open**, never before. A route that
/// resolves to nothing is the same failure D-021 rejects for گزارش‌ها, one
/// level down — a typed web URL or a restored deep link would land on a blank
/// page rather than being refused.
///
/// The paths sit under their destination so the browser URL reads as a
/// hierarchy (`/customers/<id>/edit`) and the shell keeps the right navigation
/// item selected.
abstract final class AppRoutes {
  /// The new-customer form.
  static const String customerCreate = '/customers/new';

  /// One customer's record, totals and invoices.
  ///
  /// Declared **after** [customerCreate] in the router, because `:id` would
  /// otherwise match the literal `new` and open a detail page for a customer
  /// whose id is the word "new".
  static const String customerDetail = '/customers/:id';

  static String customerDetailFor(String id) => '/customers/$id';

  /// The edit form for one customer.
  static const String customerEdit = '/customers/:id/edit';

  static String customerEditFor(String id) => '/customers/$id/edit';

  /// The invoice form.
  ///
  /// `/invoices/new`, and — for the same reason `/customers/new` is declared
  /// before `/customers/:id` — it stays ahead of [invoiceDetail], or a link to
  /// the form would resolve to a detail page for an invoice whose id is the
  /// word "new".
  static const String invoiceCreate = '/invoices/new';

  /// One invoice as a document: its party, its lines and what it comes to.
  ///
  /// Registered in Phase 5 (b), **with the screen it opens** (D-021). Until
  /// then the invoice list's rows were deliberately not tappable and a test
  /// asserted the absence; that test came out in the same change that put this
  /// here, so the affordance and the destination arrived together.
  static const String invoiceDetail = '/invoices/:id';

  static String invoiceDetailFor(String id) => '/invoices/$id';

  /// Reopening a saved **draft** in the editor (known issue 29).
  ///
  /// Declared after [invoiceDetail] for the reason [customerEdit] is: `:id`
  /// would otherwise swallow the literal segment.
  static const String invoiceEdit = '/invoices/:id/edit';

  static String invoiceEditFor(String id) => '/invoices/$id/edit';

  /// The new product or service form.
  static const String productCreate = '/products/new';

  static const String productEdit = '/products/:id/edit';

  static String productEditFor(String id) => '/products/$id/edit';
}
