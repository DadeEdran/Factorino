import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/responsive/adaptive_scaffold.dart';
import 'package:factorino/core/router/destinations.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_draft.dart';
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/repositories/repository_harness.dart';
import 'screen_harness.dart';

/// Every screen, at every width between the tiers — not only at the three the
/// tiers are named at.
///
/// **The defect this exists for was found by the owner dragging a Windows
/// window**, and close to nothing else could have found it. The three named
/// tier sizes (400, 840, 1400) are three points on a continuum and a real
/// window passes through every width between them. Between 1024 and ~1300 the
/// dashboard, both lists and the customer detail screen each laid a table out
/// narrower than its columns need: a red `ErrorWidget` in debug, where
/// `AppTableHeader`'s D-065 guard throws — and in release, where that guard is
/// compiled out, the silent version, Persian at one glyph per row.
///
/// **This is §10's rule one tier further out.** *"A widget tested only at its
/// own full width has not been tested at the width it is composed into"* had
/// already cost this project two defects. The same argument applies to the tier
/// **boundaries**, because nothing constrains a window to sit on one — and the
/// screens here are composed inside the real [AdaptiveScaffold], so the rail
/// and the page padding come out of the width first, exactly as they do in the
/// application.
///
/// **It is also the only widget test the app shell appears in at all.**
/// `pumpScreen` renders a bare screen, so the navigation chrome — and with it
/// the bottom-bar/rail switch and the compact/extended rail switch — had never
/// been pumped by anything before this file.
///
/// The step is 24 logical pixels rather than 1: the failures span hundreds of
/// pixels, and a sweep fine enough to find a one-pixel cliff would cost more
/// than it is worth on every run. `Breakpoints.desktop` is the number this
/// pins; lower it and this fails.
void main() {
  late RepositoryHarness harness;
  late Customer customer;
  late Invoice invoice;

  setUpAll(() async {
    harness = await RepositoryHarness.open();
    customer = await harness.customers.create(
      const CustomerDraft(
        fullName: 'مریم احمدی‌نژاد',
        companyName: 'شرکت مهندسی پیش‌رو صنعت پارس',
        nationalId: '0079542311',
        address: 'تهران، خیابان ولیعصر، بالاتر از میدان ونک، پلاک ۱۲۳',
        mobile: '09121234567',
      ),
    );
    final created = await harness.invoices.create(
      InvoiceDraft(
        customerId: customer.id,
        issueDate: DateTime.now().toUtc(),
        dueDate: DateTime.now().toUtc().add(const Duration(days: 30)),
        notes: 'پرداخت تا سررسید انجام شود.',
        discount: Money.rial(5000000),
        items: <InvoiceItemDraft>[
          InvoiceItemDraft(
            title: 'طراحی و پیاده‌سازی سامانهٔ نگه‌داری تجهیزات',
            unit: 'ساعت',
            quantityMilli: 2500,
            unitPrice: Money.rial(400000000),
          ),
        ],
      ),
    );
    invoice = await harness.invoices.issue(created.invoice.id);
  });

  tearDownAll(() async => harness.close());

  final Map<String, Widget Function()> screens = <String, Widget Function()>{
    'dashboard': () => const DashboardScreen(),
    'customers': () => const CustomersScreen(),
    'customer detail': () => CustomerDetailScreen(customerId: customer.id),
    'customer form new': () => const CustomerFormScreen(),
    'products': () => const ProductsScreen(),
    'product form new': () => const ProductFormScreen(),
    'invoices': () => const InvoicesScreen(),
    'invoice detail': () => InvoiceDetailScreen(invoiceId: invoice.id),
    'invoice editor': () => const InvoiceEditorScreen(),
    'settings': () => const SettingsScreen(),
  };

  for (final MapEntry<String, Widget Function()> entry in screens.entries) {
    testWidgets('SWEEP ${entry.key}', (WidgetTester tester) async {
      final List<String> broken = <String>[];

      for (double width = 328; width <= 1600; width += 24) {
        final List<FlutterErrorDetails> caught = <FlutterErrorDetails>[];
        final FlutterExceptionHandler? previous = FlutterError.onError;
        FlutterError.onError = caught.add;

        try {
          await pumpScreen(
            tester,
            AdaptiveScaffold(
              onPopSection: () => false,
              destination: AppDestination.invoices,
              onDestinationSelected: (_) {},
              child: entry.value(),
            ),
            overrides: <Override>[
              appDatabaseProvider.overrideWithValue(harness.db),
            ],
            size: Size(width, 900),
            disableAnimations: true,
          );
          await tester.pumpAndSettle();
        } on Object catch (error) {
          caught.add(FlutterErrorDetails(exception: error));
        } finally {
          FlutterError.onError = previous;
        }

        if (caught.isNotEmpty) {
          broken.add(
            '${width.toInt()} ${caught.first.exceptionAsString().split(nl).first}',
          );
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }

      expect(
        broken,
        isEmpty,
        reason:
            '${entry.key} threw at ${broken.length} of the swept widths, every '
            'one of which a window is dragged through:'
            '$nl${broken.take(4).join(nl)}',
      );
    });
  }
}

const String nl = '\n';
