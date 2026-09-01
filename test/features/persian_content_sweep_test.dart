import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_draft.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/models/payment.dart';
import 'package:factorino/data/models/payment_method.dart';
import 'package:factorino/data/models/product.dart';
import 'package:factorino/data/models/product_type.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/features/customers/presentation/customer_detail_screen.dart';
import 'package:factorino/features/customers/presentation/customer_form_screen.dart';
import 'package:factorino/features/customers/presentation/customers_screen.dart';
import 'package:factorino/features/dashboard/presentation/dashboard_screen.dart';
import 'package:factorino/features/invoices/presentation/invoice_detail_screen.dart';
import 'package:factorino/features/invoices/presentation/invoice_editor_screen.dart';
import 'package:factorino/features/invoices/presentation/invoices_screen.dart';
import 'package:factorino/features/products/presentation/product_form_screen.dart';
import 'package:factorino/features/products/presentation/products_screen.dart';
import 'package:factorino/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/repositories/repository_harness.dart';
import '../support/money_magnitudes.dart';
import '../support/text_fit.dart';
import 'screen_harness.dart';

/// **Every screen, at every tier, with Persian content at the length real data
/// reaches** — and the amounts at the top of the ladder while it is there.
///
/// **The question this file answers is "what else".** Two visual defects were
/// reported off a Windows build, and both were of a kind no existing check
/// could see: an invoice line description crushed to 21.6 logical pixels by the
/// fixed money columns beside it, and a chip label with no foreground colour at
/// all. Neither raises an overflow. Neither fails a widget test. Both were
/// found by a person looking at a screen — which does not scale, and which
/// finds them one screenshot at a time.
///
/// So rather than enumerating the places that might be wrong, this renders all
/// of them and asserts two properties that no screen may violate:
///
/// 1. **Nothing overflows.** Caught by the framework, which fails a widget test
///    on a `RenderFlex` overflow of its own accord — so a screen appearing in
///    this file is a screen whose overflow behaviour is now checked at three
///    widths with long content in it, which most of them were not.
/// 2. **No text is laid out narrower than its own longest word**
///    (`expectNoCrushedText`). This is the silent half, and the one the reported
///    defect lived in: a flexible column handed nothing is laid out
///    successfully at nothing, and Persian then renders one glyph per row.
///
/// **The content is the point.** Fixtures a few characters long fit anywhere
/// and prove nothing, which is the small-test-data mistake D-057 wrote the
/// amount ladder about, in the other dimension. Every string here is the length
/// an Iranian business actually types — a registered company name, a compound
/// surname, a full street address, a service description, a delivery note — and
/// every amount is the ceiling of the ladder.
///
/// **Real repositories over a real encrypted database**, so this is the screens
/// as the application assembles them rather than as a fake hands them over.
void main() {
  late RepositoryHarness harness;
  late Customer customer;
  late Invoice invoice;

  setUpAll(() async {
    harness = await RepositoryHarness.open();

    customer = await harness.customers.create(
      const CustomerDraft(
        fullName: PersianFixtures.longPersonName,
        companyName: PersianFixtures.longCompanyName,
        address: PersianFixtures.longAddress,
        nationalId: '0079542311',
        economicId: '411123456789',
        mobile: '09121234567',
        notes: PersianFixtures.longNote,
      ),
    );

    await harness.products.create(
      ProductDraft(
        name: PersianFixtures.longLineTitle,
        type: ProductType.service,
        price: Money.rial(kMoneyStressCeilingRial),
        unit: 'ساعت',
        description: PersianFixtures.longNote,
      ),
    );

    final created = await harness.invoices.create(
      InvoiceDraft(
        customerId: customer.id,
        issueDate: DateTime.now().toUtc(),
        dueDate: DateTime.now().toUtc().add(const Duration(days: 30)),
        notes: PersianFixtures.longNote,
        // An invoice-level discount, so every line carries a share of it and
        // the detail sentences under each description are all present.
        discount: Money.rial(kMoneyStressCeilingRial ~/ 20),
        items: <InvoiceItemDraft>[
          InvoiceItemDraft(
            title: PersianFixtures.longLineTitle,
            unit: 'ساعت',
            unitPrice: Money.rial(kMoneyStressCeilingRial),
            quantityMilli: 2500,
          ),
          InvoiceItemDraft(
            title: PersianFixtures.longCompanyName,
            unit: 'ماه',
            unitPrice: Money.rial(kMoneyStressCeilingRial),
            quantityMilli: 1000,
            discount: Money.rial(kMoneyStressCeilingRial ~/ 40),
          ),
        ],
      ),
      status: InvoiceStatus.unpaid,
    );
    invoice = created.invoice;

    // A part payment, so the payments card has a row and «مانده» has a figure.
    await harness.payments.record(
      invoice.id,
      PaymentDraft(
        amount: Money.rial(invoice.grandTotal.rial ~/ 3),
        paidAt: DateTime.now().toUtc(),
        method: PaymentMethod.cardTransfer,
        note: PersianFixtures.longNote,
      ),
    );
  });

  tearDownAll(() async => harness.close());

  /// Every screen the application routes to, as **builders** — the ids they
  /// need are seeded in `setUpAll`, which runs after the test list is built.
  ///
  /// **The forms are here too.** A label that wraps mid-word in a text field is
  /// the same defect as one in a table cell, and the forms had never been
  /// rendered at a desktop width with a long helper string in them.
  final Map<String, Widget Function()> screens = <String, Widget Function()>{
    'dashboard': () => const DashboardScreen(),
    'customers': () => const CustomersScreen(),
    'customer detail': () => CustomerDetailScreen(customerId: customer.id),
    'customer form, new': () => const CustomerFormScreen(),
    'customer form, editing': () => CustomerFormScreen(customerId: customer.id),
    'products': () => const ProductsScreen(),
    'product form, new': () => const ProductFormScreen(),
    'invoices': () => const InvoicesScreen(),
    'invoice detail': () => InvoiceDetailScreen(invoiceId: invoice.id),
    'invoice editor': () => const InvoiceEditorScreen(),
    'settings': () => const SettingsScreen(),
  };

  for (final MapEntry<String, Size> tier in kAllTierSizes.entries) {
    for (final MapEntry<String, Widget Function()> entry in screens.entries) {
      final String name = entry.key;
      testWidgets('$name at ${tier.key}', (WidgetTester tester) async {
        await pumpScreen(
          tester,
          entry.value(),
          overrides: <Override>[
            appDatabaseProvider.overrideWithValue(harness.db),
          ],
          // The tier's real width, and a height that renders the whole page —
          // an off-screen widget is never laid out, so a page checked only at
          // its first viewport is a page whose lower half went unchecked.
          size: Size(tier.value.width, 2400),
          // **Required, not tidiness.** `Skeleton` repeats its pulse forever
          // unless motion is off, so any screen that shows a loading state for
          // even one frame makes `pumpAndSettle` run until its ten-minute
          // timeout. This sweep is about layout, and a resting skeleton lays
          // out exactly as a pulsing one does.
          disableAnimations: true,
        );
        await tester.pumpAndSettle();

        expectNoCrushedText(tester, where: '$name at ${tier.key}');

        // **Tear the tree down inside the test.** These screens hold live
        // drift stream subscriptions through the real providers; left open,
        // they keep a timer pending past the end of the test (which the binding
        // rightly fails on) and keep `db.close()` waiting in `tearDownAll`.
        // Replacing the tree disposes the `ProviderScope` and everything under
        // it while the test still owns the clock.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}
