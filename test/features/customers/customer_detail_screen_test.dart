import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/widgets/app_table.dart';
import 'package:factorino/core/widgets/empty_state.dart';
import 'package:factorino/core/widgets/skeleton.dart';
import 'package:factorino/core/widgets/stat_tile.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/customer_totals.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_list_item.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/features/customers/presentation/customer_detail_screen.dart';
import 'package:factorino/features/invoices/presentation/invoices_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../invoices/fake_invoice_repository.dart';
import '../screen_harness.dart';
import 'fake_customer_repository.dart';

/// The customer detail screen — the one screen that answers "what is my history
/// with this customer".
///
/// Both overrides go in at the **interfaces**, which is the seam D-032 built
/// the composition root around: the screen cannot tell the difference, so this
/// exercises the real widget, the real providers and the real composition into
/// one `CustomerDetailView`.
void main() {
  final DateTime now = DateTime.utc(2026, 8, 24, 6);

  Customer customer({
    String id = 'c1',
    String name = 'مریم احمدی',
    String? mobile,
    String? company,
    String? nationalId,
    String? economicId,
    String? address,
    String? notes,
  }) {
    return Customer(
      id: id,
      fullName: name,
      mobile: mobile,
      companyName: company,
      nationalId: nationalId,
      economicId: economicId,
      address: address,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  InvoiceListItem invoice(String id, String number, {int rial = 1100000}) {
    return InvoiceListItem(
      invoice: Invoice(
        id: id,
        number: number,
        numberYear: 1405,
        numberSequence: 1,
        customerId: 'c1',
        issueDate: DateTime.utc(2026, 8, 20),
        status: InvoiceStatus.unpaid,
        discount: Money.zero,
        subtotal: Money.rial(rial),
        totalDiscount: Money.zero,
        totalTax: Money.zero,
        roundingAdjustment: Money.zero,
        grandTotal: Money.rial(rial),
        createdAt: now,
        updatedAt: now,
      ),
      customerName: 'مریم احمدی',
    );
  }

  List<Override> withRepositories({
    required FakeCustomerRepository customers,
    required FakeInvoiceRepository invoices,
  }) {
    return <Override>[
      customerRepositoryProvider.overrideWithValue(customers),
      invoiceRepositoryProvider.overrideWithValue(invoices),
    ];
  }

  Future<void> pumpDetail(
    WidgetTester tester, {
    required FakeCustomerRepository customers,
    required FakeInvoiceRepository invoices,
    Size size = kMobileSize,
  }) {
    return pumpScreen(
      tester,
      const CustomerDetailScreen(customerId: 'c1'),
      overrides: withRepositories(customers: customers, invoices: invoices),
      size: size,
    );
  }

  group('states', () {
    testWidgets('shows a skeleton, not a spinner, while loading', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository.pending(),
        invoices: FakeInvoiceRepository.pending(),
      );
      await tester.pump();

      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('an unknown id says so and offers the way back', (
      WidgetTester tester,
    ) async {
      // A stale deep link, or a customer deleted while the page was opening.
      // Rendering an empty record instead would read as a customer with no
      // details rather than as no customer.
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[]),
        invoices: FakeInvoiceRepository(const <InvoiceListItem>[]),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomerDetailScreen);
      expect(find.text(strings.customerNotFoundTitle), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.text(strings.customerBackToList),
        ),
        findsOneWidget,
      );
    });

    testWidgets('surfaces a failure as Persian copy, never as the exception', (
      WidgetTester tester,
    ) async {
      // §7: no stack trace, SQL statement, path or raw exception string may
      // reach the user.
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository.failing(
          StateError('SELECT * FROM customers -- C:\\Users\\x\\factorino.db'),
        ),
        invoices: FakeInvoiceRepository(const <InvoiceListItem>[]),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomerDetailScreen);
      expect(find.text(strings.errorGenericTitle), findsOneWidget);
      expect(find.textContaining('SELECT'), findsNothing);
      expect(find.textContaining('factorino.db'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
    });
  });

  group('totals', () {
    testWidgets('shows billed and outstanding, each naming its population', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[customer()]),
        invoices: FakeInvoiceRepository(
          <InvoiceListItem>[invoice('i1', 'INV-1405-0001')],
          customerTotals: CustomerTotals(
            billed: Money.rial(50000000),
            outstanding: Money.rial(11000000),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomerDetailScreen);
      expect(find.byType(StatTile), findsNWidgets(2));
      expect(find.text(strings.customerTotalBilled), findsOneWidget);
      expect(find.text(strings.customerTotalOutstanding), findsOneWidget);

      // The captions are the part that makes the figures reconcilable. Without
      // them "مجموع فاکتورهای صادرشده" is a number the user cannot check
      // against the list underneath, and a figure nobody can check is one they
      // learn to distrust (D-039).
      expect(find.text(strings.customerTotalBilledCaption), findsOneWidget);
      expect(
        find.text(strings.customerTotalOutstandingCaption),
        findsOneWidget,
      );

      // Toman, Persian digits, and never a bare number (§9).
      expect(find.text('۵٬۰۰۰٬۰۰۰'), findsOneWidget);
      expect(find.text('۱٬۱۰۰٬۰۰۰'), findsOneWidget);
      expect(find.text(strings.unitToman), findsWidgets);
    });

    testWidgets('the aggregate is scoped to this customer', (
      WidgetTester tester,
    ) async {
      // Without the customer predicate the query returns the dashboard's
      // figures on every customer's page -- which looks entirely plausible for
      // the first customer entered, and is wrong for every one after.
      final FakeInvoiceRepository invoices = FakeInvoiceRepository(
        const <InvoiceListItem>[],
      );
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[customer()]),
        invoices: invoices,
      );
      await tester.pumpAndSettle();

      expect(invoices.lastCustomerTotalsId, 'c1');
    });
  });

  /// Opens the record card, which is collapsed by default on a phone.
  Future<void> expandRecord(WidgetTester tester) async {
    final AppStrings strings = stringsOf(tester, CustomerDetailScreen);
    await tester.tap(find.text(strings.customerDetailsSection));
    await tester.pumpAndSettle();
  }

  group('the record', () {
    testWidgets('is collapsed on a phone, so the invoice list is not buried', (
      WidgetTester tester,
    ) async {
      // The card's height has no upper bound the layout can be designed around
      // -- notes run to two thousand characters -- so left open above the list
      // it can push the list off the page, on the one screen whose purpose is
      // to show it.
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[
          customer(mobile: '09123456789'),
        ]),
        invoices: FakeInvoiceRepository(<InvoiceListItem>[
          invoice('i1', 'INV-1405-0001'),
        ]),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomerDetailScreen);
      // The heading is there; the values are not, and the invoice list is.
      expect(find.text(strings.customerDetailsSection), findsOneWidget);
      expect(find.text('\u2068۰۹۱۲ ۳۴۵ ۶۷۸۹\u2069'), findsNothing);
      expect(find.byType(InvoiceCard), findsOneWidget);

      await expandRecord(tester);
      expect(find.text('\u2068۰۹۱۲ ۳۴۵ ۶۷۸۹\u2069'), findsOneWidget);
    });

    testWidgets('is open on desktop, where the panel has room of its own', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[
          customer(mobile: '09123456789'),
        ]),
        invoices: FakeInvoiceRepository(const <InvoiceListItem>[]),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      expect(find.text('\u2068۰۹۱۲ ۳۴۵ ۶۷۸۹\u2069'), findsOneWidget);
    });

    testWidgets('renders identifiers through the bidi-isolating formatters', (
      WidgetTester tester,
    ) async {
      // §9. Without the isolate a run of digits reorders against the Persian
      // beside it, and the number on screen stops matching the card the user
      // is copying from.
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[
          customer(
            mobile: '09123456789',
            nationalId: '0079542311',
            economicId: '411111111111',
          ),
        ]),
        invoices: FakeInvoiceRepository(const <InvoiceListItem>[]),
      );
      await tester.pumpAndSettle();
      await expandRecord(tester);
      expect(find.text('\u2068۰۹۱۲ ۳۴۵ ۶۷۸۹\u2069'), findsOneWidget);
      // The national ID is deliberately *not* grouped: it is quoted as an
      // unbroken ten-digit string on every official document.
      expect(find.text('\u2068۰۰۷۹۵۴۲۳۱۱\u2069'), findsOneWidget);
      expect(find.text('\u2068۴۱۱۱۱۱۱۱۱۱۱۱\u2069'), findsOneWidget);
    });

    testWidgets('says a field is not recorded rather than showing blank', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[customer()]),
        invoices: FakeInvoiceRepository(const <InvoiceListItem>[]),
      );
      await tester.pumpAndSettle();
      await expandRecord(tester);

      final AppStrings strings = stringsOf(tester, CustomerDetailScreen);
      // Every optional field is empty on this fixture, and each says so. A
      // record that hid what was missing would look complete, and the user
      // could not tell "no company" from "companies are not shown here".
      expect(find.text(strings.fieldNotRecorded), findsNWidgets(6));
    });

    testWidgets('never presents the national ID as verified (D-030)', (
      WidgetTester tester,
    ) async {
      // This screen displays a *stored* national ID, so the constraint binds
      // here as much as on the form. The checksum maps two distinct numbers
      // onto the same check digit, so a passing value narrows the space of
      // typos and proves nothing about whose number it is -- and a user shown
      // "verified" stops checking it.
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[
          customer(nationalId: '0079542311'),
        ]),
        invoices: FakeInvoiceRepository(const <InvoiceListItem>[]),
      );
      await tester.pumpAndSettle();
      await expandRecord(tester);

      final AppStrings strings = stringsOf(tester, CustomerDetailScreen);
      expect(find.text(strings.nationalIdFormatValid), findsNothing);
      for (final String claim in <String>['تأیید', 'تایید', 'صحیح', 'احراز']) {
        expect(
          find.textContaining(claim),
          findsNothing,
          reason: 'D-030: nothing on this screen may call the ID confirmed',
        );
      }
      // ...and no affirmative iconography either, which the copy rule alone
      // would not catch.
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.verified), findsNothing);
    });

    testWidgets('does not repeat the name it is already titled with', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[customer()]),
        invoices: FakeInvoiceRepository(const <InvoiceListItem>[]),
      );
      await tester.pumpAndSettle();

      expect(find.text('مریم احمدی'), findsOneWidget);
    });
  });

  group('the invoice list', () {
    testWidgets('a customer with no invoices gets a designed empty state', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[customer()]),
        invoices: FakeInvoiceRepository(const <InvoiceListItem>[]),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomerDetailScreen);
      expect(find.text(strings.customerEmptyInvoicesTitle), findsOneWidget);
      expect(find.text(strings.customerEmptyInvoicesBody), findsOneWidget);
    });

    testWidgets('the empty state offers no create action', (
      WidgetTester tester,
    ) async {
      // The invoice form is Phase 4. A button here would open nothing, which
      // §15 prohibits and which is worse than the absence it covers.
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[customer()]),
        invoices: FakeInvoiceRepository(const <InvoiceListItem>[]),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.byType(FilledButton),
        ),
        findsNothing,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('rows are not tappable until /invoices/:id exists', (
      WidgetTester tester,
    ) async {
      // Asserted rather than left implicit, so the absence reads as deliberate
      // (D-021, one level down). The invoice detail screen is Phase 5.
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[customer()]),
        invoices: FakeInvoiceRepository(<InvoiceListItem>[
          invoice('i1', 'INV-1405-0001'),
        ]),
      );
      await tester.pumpAndSettle();

      final InvoiceCard card = tester.widget<InvoiceCard>(
        find.byType(InvoiceCard),
      );
      expect(card.showCustomer, isFalse);

      await tester.tap(find.byType(InvoiceCard));
      await tester.pumpAndSettle();
      expect(lastLocation, '/');
    });

    testWidgets('the row heading is the invoice number, not the customer', (
      WidgetTester tester,
    ) async {
      // On this customer's own page the name is the same on every row: twenty
      // repetitions of something the reader already knows, pushing the number
      // -- which is what identifies the row -- into second place (§10).
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[customer()]),
        invoices: FakeInvoiceRepository(<InvoiceListItem>[
          invoice('i1', 'INV-1405-0001'),
          invoice('i2', 'INV-1405-0002'),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('\u2068INV-1405-0001\u2069'), findsOneWidget);
      // The page title is the one place the name appears.
      expect(find.text('مریم احمدی'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('desktop renders a table without a customer column', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[customer()]),
        invoices: FakeInvoiceRepository(<InvoiceListItem>[
          invoice('i1', 'INV-1405-0001'),
        ]),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomerDetailScreen);
      expect(find.byType(AppTableHeader), findsOneWidget);
      expect(find.text(strings.tableColumnNumber), findsOneWidget);
      expect(find.text(strings.tableColumnAmount), findsOneWidget);
      expect(
        find.text(strings.tableColumnCustomer),
        findsNothing,
        reason: 'the column would hold the same name on every row',
      );
    });

    testWidgets('mobile renders cards, not a table', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[customer()]),
        invoices: FakeInvoiceRepository(<InvoiceListItem>[
          invoice('i1', 'INV-1405-0001'),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InvoiceCard), findsOneWidget);
      expect(find.byType(AppTableHeader), findsNothing);
    });

    testWidgets('the mobile invoice list stays virtualized', (
      WidgetTester tester,
    ) async {
      // The whole page scrolls as one, which is why it is built from slivers
      // rather than a `ListView` of children: the latter would build a card
      // for every invoice this customer has ever had, to show the three that
      // fit (§13, D-037).
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[customer()]),
        invoices: FakeInvoiceRepository(<InvoiceListItem>[
          for (int i = 0; i < 300; i++) invoice('i$i', 'INV-1405-000$i'),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InvoiceCard), findsWidgets);
      expect(tester.widgetList(find.byType(InvoiceCard)).length, lessThan(30));
    });
  });

  group('navigation', () {
    testWidgets('the back control returns to the customer list', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[customer()]),
        invoices: FakeInvoiceRepository(const <InvoiceListItem>[]),
      );
      await tester.pumpAndSettle();

      // A directional icon, which §9 says *should* mirror in RTL -- unlike the
      // object icons in the navigation rail.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(lastLocation, '/customers');
    });

    testWidgets('edit opens the form for this customer', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        customers: FakeCustomerRepository(<Customer>[customer()]),
        invoices: FakeInvoiceRepository(const <InvoiceListItem>[]),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomerDetailScreen);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.actionEdit));
      await tester.pumpAndSettle();

      expect(lastLocation, '/customers/c1/edit');
    });

    testWidgets('deleting explains what survives, then leaves the page', (
      WidgetTester tester,
    ) async {
      // The Persian copy is the promise the invoice list keeps by not
      // filtering its customer join (D-040): the customer leaves the list and
      // the invoices already issued to them stay untouched.
      final FakeCustomerRepository customers = FakeCustomerRepository(
        <Customer>[customer()],
      );
      await pumpDetail(
        tester,
        customers: customers,
        invoices: FakeInvoiceRepository(const <InvoiceListItem>[]),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomerDetailScreen);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.actionDelete));
      await tester.pumpAndSettle();

      expect(find.text(strings.customerDeleteTitle), findsOneWidget);
      expect(find.text(strings.customerDeleteBody), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, strings.actionDelete),
        ),
      );
      await tester.pumpAndSettle();

      expect(customers.deleted, <String>['c1']);
      // Staying would present a customer the application no longer has.
      expect(lastLocation, '/customers');
    });
  });
}
