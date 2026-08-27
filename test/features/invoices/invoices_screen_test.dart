import 'package:factorino/core/formatting/jalali_display.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/utils/clock.dart';
import 'package:factorino/core/utils/list_query.dart';
import 'package:factorino/core/widgets/amount_text.dart';
import 'package:factorino/core/widgets/app_table.dart';
import 'package:factorino/core/widgets/empty_state.dart';
import 'package:factorino/core/widgets/load_more_footer.dart';
import 'package:factorino/core/widgets/skeleton.dart';
import 'package:factorino/core/widgets/status_badge.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_list_item.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/features/invoices/application/invoices_providers.dart';
import 'package:factorino/features/invoices/presentation/invoices_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screen_harness.dart';
import 'fake_invoice_repository.dart';

/// The invoice list, at each state it can be in and at both layouts it has.
///
/// The override goes in at `invoiceRepositoryProvider` — the interface, not the
/// implementation — so this exercises the real widget, the real providers and
/// the real paging logic (D-032).
void main() {
  /// Fixed, so the overdue derivation is answering a question with one right
  /// answer rather than one that changes with the wall clock.
  final DateTime now = DateTime.utc(2026, 8, 24, 6);

  InvoiceListItem item(
    String id, {
    required String liveCustomerName,
    InvoiceStatus status = InvoiceStatus.unpaid,
    int sequence = 1,
    int grandTotalRial = 12000000,
    DateTime? dueDate,
    // A draft carries no number until it is issued (D-048).
    bool numbered = true,
  }) {
    final DateTime issued = DateTime.utc(2026, 8, 20, 6);
    return InvoiceListItem(
      liveCustomerName: liveCustomerName,
      invoice: Invoice(
        id: id,
        number: numbered
            ? 'INV-1405-${sequence.toString().padLeft(4, '0')}'
            : null,
        numberYear: numbered ? 1405 : null,
        numberSequence: numbered ? sequence : null,
        customerId: 'c1',
        issueDate: issued,
        dueDate: dueDate,
        status: status,
        discount: Money.zero,
        subtotal: Money.rial(grandTotalRial),
        totalDiscount: Money.zero,
        totalTax: Money.zero,
        roundingAdjustment: Money.zero,
        grandTotal: Money.rial(grandTotalRial),
        createdAt: issued,
        updatedAt: issued,
      ),
    );
  }

  List<Override> withRepository(FakeInvoiceRepository repository) {
    return <Override>[
      invoiceRepositoryProvider.overrideWithValue(repository),
      nowProvider.overrideWithValue(now),
    ];
  }

  group('states', () {
    testWidgets('shows a skeleton, not a spinner, while loading', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(FakeInvoiceRepository.pending()),
      );
      await tester.pump();

      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('the empty state offers no create action', (
      WidgetTester tester,
    ) async {
      // The invoice form is Phase 4 and its route is unregistered, so an
      // affordance here would lead nowhere (D-021, one level down). The empty
      // state explains and stops.
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(const <InvoiceListItem>[]),
        ),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, InvoicesScreen);
      expect(find.text(strings.emptyInvoicesTitle), findsOneWidget);
      expect(find.text(strings.emptyInvoicesBody), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.byType(FilledButton),
        ),
        findsNothing,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('surfaces a failure as Persian copy, never as the exception', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository.failing(
            StateError('SELECT * FROM invoices -- C:\\Users\\x\\factorino.db'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, InvoicesScreen);
      expect(find.text(strings.errorGenericTitle), findsOneWidget);
      expect(find.textContaining('SELECT'), findsNothing);
      expect(find.textContaining('factorino.db'), findsNothing);
    });
  });

  group('a draft with no number yet (D-048)', () {
    testWidgets('the table cell says so in Persian, not blank', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            item(
              'a',
              liveCustomerName: 'مریم احمدی',
              status: InvoiceStatus.draft,
              numbered: false,
            ),
          ]),
        ),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, InvoicesScreen);
      expect(find.text(strings.invoiceNumberPending), findsOneWidget);

      // An empty cell reads as data that failed to load, which on a financial
      // list is the worst of the available wrong impressions.
      expect(find.text(''), findsNothing);
    });

    testWidgets('the mobile card says so too, with the same words', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            item(
              'a',
              liveCustomerName: 'مریم احمدی',
              status: InvoiceStatus.draft,
              numbered: false,
            ),
          ]),
        ),
        size: kMobileSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, InvoicesScreen);
      expect(find.byType(InvoiceCard), findsOneWidget);
      expect(find.text(strings.invoiceNumberPending), findsOneWidget);
      // The badge already says «پیش‌نویس»; the placeholder must not repeat it.
      expect(strings.invoiceNumberPending, isNot(strings.statusDraft));
    });

    testWidgets('the placeholder carries no bidi isolate characters', (
      WidgetTester tester,
    ) async {
      // A real invoice number is isolated because it mixes a Latin prefix with
      // digits (§9). The Persian placeholder is ordinary RTL prose with
      // nothing to protect, and wrapping it would put invisible control
      // characters into a string that tests and screen readers both handle.
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            item(
              'a',
              liveCustomerName: 'مریم احمدی',
              status: InvoiceStatus.draft,
              numbered: false,
            ),
          ]),
        ),
        size: kMobileSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, InvoicesScreen);
      final Iterable<Text> texts = tester.widgetList<Text>(find.byType(Text));
      final Text placeholder = texts.firstWhere(
        (Text t) => t.data == strings.invoiceNumberPending,
      );

      // Asserted against the constants the formatter actually applies, rather
      // than against a literal here: the source encoding of a bidi control is
      // not something to depend on twice.
      expect(placeholder.data, isNot(contains(kFirstStrongIsolate)));
      expect(placeholder.data, isNot(contains(kPopDirectionalIsolate)));
    });

    testWidgets('a numbered invoice is still isolated', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            item('a', liveCustomerName: 'مریم احمدی'),
          ]),
        ),
        size: kMobileSize,
      );
      await tester.pumpAndSettle();

      expect(find.text(isolate('INV-1405-0001')), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('mobile renders cards, not a table', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            item('a', liveCustomerName: 'مریم احمدی'),
          ]),
        ),
        size: kMobileSize,
      );
      await tester.pumpAndSettle();

      expect(find.byType(InvoiceCard), findsOneWidget);
      expect(find.byType(AppTableHeader), findsNothing);
      expect(find.text('مریم احمدی'), findsOneWidget);
    });

    testWidgets('desktop renders a real table with all five columns', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            item('a', liveCustomerName: 'مریم احمدی'),
          ]),
        ),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, InvoicesScreen);
      expect(find.byType(AppTableHeader), findsOneWidget);
      expect(find.text(strings.tableColumnNumber), findsOneWidget);
      expect(find.text(strings.tableColumnCustomer), findsOneWidget);
      expect(find.text(strings.tableColumnDate), findsOneWidget);
      expect(find.text(strings.tableColumnStatus), findsOneWidget);
      expect(find.text(strings.tableColumnAmount), findsOneWidget);
      expect(find.byType(InvoiceTableRow), findsOneWidget);
    });

    testWidgets('the desktop table is virtualized, not fully built', (
      WidgetTester tester,
    ) async {
      // The reason it is not a `DataTable`, asserted rather than trusted: a
      // full page of rows must not produce a full page of widgets (D-037).
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            for (int i = 0; i < 400; i++)
              item('i$i', liveCustomerName: 'مشتری $i', sequence: i + 1),
          ]),
        ),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppTableRow), findsWidgets);
      expect(
        tester.widgetList(find.byType(AppTableRow)).length,
        lessThan(ListQuery.defaultPageSize),
      );
    });

    testWidgets('the amount column is leading-aligned, not pushed to the end', (
      WidgetTester tester,
    ) async {
      // The RTL trap from (f1), pinned so it cannot come back: `alignEnd`
      // resolves to the *left* edge in RTL while numbers still render
      // left-to-right, so the column would line up by its first digit and
      // leave the units ragged -- undoing what tabular figures are for.
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            item('a', liveCustomerName: 'مریم احمدی'),
          ]),
        ),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, InvoicesScreen);
      final TableColumnSpec amountColumn = invoiceColumns(strings).last;
      expect(amountColumn.alignEnd, isFalse);
      expect(amountColumn.width, isNotNull);
    });
  });

  group('display', () {
    testWidgets('an amount is shown through AmountText, with its unit', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            item('a', liveCustomerName: 'مریم احمدی', grandTotalRial: 12000000),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, InvoicesScreen);
      expect(find.byType(AmountText), findsOneWidget);
      // 12,000,000 Rial displayed as 1,200,000 Toman, in Persian digits with
      // the Arabic thousands separator -- never a bare number (§9).
      expect(find.text('۱٬۲۰۰٬۰۰۰'), findsOneWidget);
      expect(find.text(strings.unitToman), findsOneWidget);
    });

    testWidgets('the invoice number is bidi-isolated', (
      WidgetTester tester,
    ) async {
      // `INV-1405-0001` mixes a Latin prefix, digits and hyphens; without the
      // isolate the run resolves against the Persian beside it and the same
      // number reads differently in a card and in a table (§9).
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            item('a', liveCustomerName: 'مریم احمدی', sequence: 1),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('\u2068INV-1405-0001\u2069'), findsOneWidget);
    });

    testWidgets('the badge shows the stored status, not a recomputed one', (
      WidgetTester tester,
    ) async {
      // The list model carries no payment information at all, so the screen
      // has nothing to recompute *from* -- which is the structural half of the
      // guarantee. This is the observable half.
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            item(
              'a',
              liveCustomerName: 'مریم احمدی',
              status: InvoiceStatus.partiallyPaid,
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, InvoicesScreen);
      expect(find.text(strings.statusPartiallyPaid), findsOneWidget);

      final StatusBadge badge = tester.widget<StatusBadge>(
        find.byType(StatusBadge),
      );
      expect(badge.status, InvoiceStatusView.partiallyPaid);
    });

    testWidgets('an unpaid invoice past its due date shows as overdue', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            item(
              'a',
              liveCustomerName: 'مریم احمدی',
              status: InvoiceStatus.unpaid,
              dueDate: DateTime.utc(2026, 8, 1),
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, InvoicesScreen);
      expect(find.text(strings.statusOverdue), findsOneWidget);
      expect(find.text(strings.statusUnpaid), findsNothing);
    });
  });

  group('paging', () {
    testWidgets('asks the database for one page, not for everything', (
      WidgetTester tester,
    ) async {
      final FakeInvoiceRepository repository = FakeInvoiceRepository(
        <InvoiceListItem>[
          for (int i = 0; i < 200; i++)
            item('i$i', liveCustomerName: 'مشتری $i', sequence: i + 1),
        ],
      );
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(repository),
      );
      await tester.pumpAndSettle();

      expect(repository.lastLimit, ListQuery.defaultPageSize);
    });

    testWidgets('load more widens the query window by one page', (
      WidgetTester tester,
    ) async {
      final FakeInvoiceRepository repository = FakeInvoiceRepository(
        <InvoiceListItem>[
          for (int i = 0; i < 200; i++)
            item('i$i', liveCustomerName: 'مشتری $i', sequence: i + 1),
        ],
      );
      late WidgetRef capturedRef;
      await pumpScreen(
        tester,
        Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            capturedRef = ref;
            return const InvoicesScreen();
          },
        ),
        overrides: withRepository(repository),
      );
      await tester.pumpAndSettle();

      capturedRef.read(invoiceListQueryProvider.notifier).loadMore();
      await tester.pumpAndSettle();

      expect(repository.lastLimit, ListQuery.defaultPageSize * 2);
    });

    testWidgets('no load-more control once the last page is short', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            for (int i = 0; i < 3; i++)
              item('i$i', liveCustomerName: 'مشتری $i', sequence: i + 1),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoadMoreFooter), findsNothing);
    });
  });

  group('routes that do not exist yet', () {
    testWidgets('a row is not tappable', (WidgetTester tester) async {
      // `/invoices/:id` is deliberately unregistered until the detail screen
      // exists (D-021). A row that navigated would land on nothing -- so the
      // absence of the affordance is the feature, and it is asserted rather
      // than assumed.
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            item('a', liveCustomerName: 'مریم احمدی'),
          ]),
        ),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      final AppTableRow row = tester.widget<AppTableRow>(
        find.byType(AppTableRow),
      );
      expect(row.onTap, isNull);

      await tester.tap(find.byType(AppTableRow));
      await tester.pumpAndSettle();
      expect(lastLocation, '/');
    });
  });
}
