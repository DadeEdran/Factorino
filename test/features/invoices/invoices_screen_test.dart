import 'package:factorino/core/date/jalali_period.dart';
import 'package:factorino/core/formatting/jalali_display.dart';
import 'package:factorino/core/formatting/number_display.dart';
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
import 'package:factorino/data/models/invoice_filter.dart';
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
        grossTotal: Money.rial(grandTotalRial),
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

    testWidgets('the empty state offers the create action it now can', (
      WidgetTester tester,
    ) async {
      // Until Phase 4 (d) the invoice form did not exist and its route was
      // unregistered, so this state deliberately explained and stopped —
      // an affordance leading nowhere is worse than its absence (D-021, one
      // level down). The form exists now, so the state gets its call to
      // action (§10).
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(const <InvoiceListItem>[]),
        ),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, InvoicesScreen);
      expect(find.text(strings.emptyInvoicesTitle), findsOneWidget);
      expect(find.text(strings.emptyInvoicesBody), findsOneWidget);
      // Scoped to the empty state, because this page carries a second create
      // button in its header at this tier: an unscoped `find.text` would pass
      // with the empty state's own action missing entirely.
      expect(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.text(strings.invoiceCreateAction),
        ),
        findsOneWidget,
      );
    });

    testWidgets('on a phone the empty state leaves the button to the FAB', (
      WidgetTester tester,
    ) async {
      // The floating action button already sits over this state on a phone,
      // and two buttons saying «فاکتور جدید» a centimetre apart is one too
      // many.
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(const <InvoiceListItem>[]),
        ),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, InvoicesScreen);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.text(strings.invoiceCreateAction),
        ),
        findsNothing,
      );
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

  group('filters (e)', () {
    /// A hundred invoices, so a page is smaller than the set and "did the
    /// filter reach the query" is a question with a visible answer.
    FakeInvoiceRepository stocked() => FakeInvoiceRepository(<InvoiceListItem>[
      for (int i = 0; i < 100; i++)
        item('i$i', liveCustomerName: 'مشتری $i', sequence: i + 1),
    ]);

    Future<(AppStrings, FakeInvoiceRepository, WidgetRef)> pumpList(
      WidgetTester tester, {
      FakeInvoiceRepository? repository,
      Size size = kMobileSize,
    }) async {
      final FakeInvoiceRepository repo = repository ?? stocked();
      late WidgetRef capturedRef;
      await pumpScreen(
        tester,
        Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            capturedRef = ref;
            return const InvoicesScreen();
          },
        ),
        overrides: withRepository(repo),
        size: size,
      );
      await tester.pumpAndSettle();
      return (stringsOf(tester, InvoicesScreen), repo, capturedRef);
    }

    testWidgets('the unfiltered list asks for no filter at all', (
      WidgetTester tester,
    ) async {
      final (_, FakeInvoiceRepository repo, _) = await pumpList(tester);

      expect(repo.lastFilter, InvoiceFilter.none);
      expect(repo.lastFilter!.isActive, isFalse);
    });

    testWidgets('the filter reaches the repository, not a Dart .where', (
      WidgetTester tester,
    ) async {
      // **The assertion this whole increment turns on.** The fake does not
      // narrow its own list, so the only way a screen can appear to filter is
      // by sending the predicate to the query. If this ever passes while
      // `lastFilter` is `none`, the narrowing has moved into Dart and the page
      // limit is being applied to the wrong set.
      final (_, FakeInvoiceRepository repo, WidgetRef ref) = await pumpList(
        tester,
      );

      ref
          .read(invoiceListQueryProvider.notifier)
          .filter(
            const InvoiceFilter(
              statuses: <InvoiceStatus>{InvoiceStatus.cancelled},
            ),
          );
      await tester.pumpAndSettle();

      expect(repo.lastFilter, isNotNull);
      expect(repo.lastFilter!.statuses, <InvoiceStatus>{
        InvoiceStatus.cancelled,
      });
    });

    testWidgets('changing the filter resets the window to one page', (
      WidgetTester tester,
    ) async {
      // A user who has loaded eight pages and then narrows should not have the
      // app ask for eight pages of the narrower set. That rule lives in
      // `InvoiceQuery.filtering`, which is why the window and the filter are
      // one value rather than two providers.
      final (_, FakeInvoiceRepository repo, WidgetRef ref) = await pumpList(
        tester,
      );

      ref.read(invoiceListQueryProvider.notifier).loadMore();
      ref.read(invoiceListQueryProvider.notifier).loadMore();
      await tester.pumpAndSettle();
      expect(repo.lastLimit, ListQuery.defaultPageSize * 3);

      ref
          .read(invoiceListQueryProvider.notifier)
          .filter(
            const InvoiceFilter(statuses: <InvoiceStatus>{InvoiceStatus.paid}),
          );
      await tester.pumpAndSettle();

      expect(repo.lastLimit, ListQuery.defaultPageSize);
    });

    testWidgets('and load-more keeps the filter it was widening', (
      WidgetTester tester,
    ) async {
      final (_, FakeInvoiceRepository repo, WidgetRef ref) = await pumpList(
        tester,
      );

      const InvoiceFilter paid = InvoiceFilter(
        statuses: <InvoiceStatus>{InvoiceStatus.paid},
      );
      ref.read(invoiceListQueryProvider.notifier).filter(paid);
      await tester.pumpAndSettle();
      ref.read(invoiceListQueryProvider.notifier).loadMore();
      await tester.pumpAndSettle();

      expect(repo.lastLimit, ListQuery.defaultPageSize * 2);
      expect(
        repo.lastFilter,
        paid,
        reason: 'widening the window must not quietly drop the predicate',
      );
    });

    testWidgets('the control says how many filters are on', (
      WidgetTester tester,
    ) async {
      // A filter control that looks the same filtered and unfiltered is how a
      // user comes back tomorrow, sees four invoices where there were four
      // hundred, and concludes the app lost them.
      final (AppStrings strings, _, WidgetRef ref) = await pumpList(tester);

      expect(find.text(strings.invoiceFilterAction), findsOneWidget);

      ref
          .read(invoiceListQueryProvider.notifier)
          .filter(
            InvoiceFilter(
              statuses: const <InvoiceStatus>{InvoiceStatus.paid},
              customerId: 'c1',
            ),
          );
      await tester.pumpAndSettle();

      expect(
        find.text(strings.invoiceFilterActiveLabel(formatGroupedPersian(2))),
        findsOneWidget,
      );
      expect(find.text(strings.invoiceFilterAction), findsNothing);
    });

    testWidgets('an empty filtered list is not "you have no invoices"', (
      WidgetTester tester,
    ) async {
      // Telling a user with four hundred invoices that they have none is false,
      // and it sends them looking for lost data instead of at the chips they
      // just tapped.
      final (AppStrings strings, _, WidgetRef ref) = await pumpList(
        tester,
        repository: FakeInvoiceRepository(const <InvoiceListItem>[]),
      );

      expect(find.text(strings.emptyInvoicesTitle), findsOneWidget);

      ref
          .read(invoiceListQueryProvider.notifier)
          .filter(
            const InvoiceFilter(
              statuses: <InvoiceStatus>{InvoiceStatus.cancelled},
            ),
          );
      await tester.pumpAndSettle();

      expect(find.text(strings.emptyInvoicesFilteredTitle), findsOneWidget);
      expect(find.text(strings.emptyInvoicesFilteredBody), findsOneWidget);
      expect(find.text(strings.emptyInvoicesTitle), findsNothing);
    });

    testWidgets('and it offers the way out, which is not "make an invoice"', (
      WidgetTester tester,
    ) async {
      final (AppStrings strings, _, WidgetRef ref) = await pumpList(
        tester,
        repository: FakeInvoiceRepository(const <InvoiceListItem>[]),
        size: kDesktopSize,
      );

      ref
          .read(invoiceListQueryProvider.notifier)
          .filter(
            const InvoiceFilter(
              statuses: <InvoiceStatus>{InvoiceStatus.cancelled},
            ),
          );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.text(strings.invoiceFilterClearAll),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.emptyInvoicesTitle), findsOneWidget);
    });

    testWidgets('the sheet opens and offers the five stored statuses', (
      WidgetTester tester,
    ) async {
      // Five, not six: «سررسید گذشته» is derived at display time (D-041) and is
      // deliberately not a filter, because a SQL predicate for it would be a
      // second implementation of a rule `invoiceStatusViewOf` owns.
      final (AppStrings strings, _, _) = await pumpList(tester);

      await tester.tap(find.text(strings.invoiceFilterAction));
      await tester.pumpAndSettle();

      expect(find.text(strings.invoiceFilterTitle), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(5));
      expect(find.text(strings.statusOverdue), findsNothing);
    });

    testWidgets('tapping a status chip sends that status to the query', (
      WidgetTester tester,
    ) async {
      final (AppStrings strings, FakeInvoiceRepository repo, _) =
          await pumpList(tester);

      await tester.tap(find.text(strings.invoiceFilterAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilterChip, strings.statusCancelled),
      );
      await tester.pumpAndSettle();

      expect(repo.lastFilter!.statuses, <InvoiceStatus>{
        InvoiceStatus.cancelled,
      });
    });

    testWidgets('the period presets are Jalali, resolved from the clock', (
      WidgetTester tester,
    ) async {
      // §5 and D-006. «این ماه» must be the Jalali month the fixed clock is in
      // — Shahrivar 1405 — and never a Gregorian one.
      final (AppStrings strings, FakeInvoiceRepository repo, _) =
          await pumpList(tester);

      await tester.tap(find.text(strings.invoiceFilterAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ChoiceChip, strings.invoiceFilterPeriodThisMonth),
      );
      await tester.pumpAndSettle();

      expect(repo.lastFilter!.period, jalaliMonth(1405, 6));
    });

    testWidgets('«ماه گذشته» is the previous Jalali month', (
      WidgetTester tester,
    ) async {
      final (AppStrings strings, FakeInvoiceRepository repo, _) =
          await pumpList(tester);

      await tester.tap(find.text(strings.invoiceFilterAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ChoiceChip, strings.invoiceFilterPeriodLastMonth),
      );
      await tester.pumpAndSettle();

      expect(repo.lastFilter!.period, jalaliMonth(1405, 5));
    });

    // **Every tier, because the filter control and the sheet are new layout**
    // (D-057). No money is rendered here, so this sweeps the tiers rather than
    // the amount ladder: what varies across tiers is where the control sits and
    // how many chips fit on a row, and a `Wrap` that overflowed would fail each
    // of these on its own.
    for (final MapEntry<String, Size> tier in kAllTierSizes.entries) {
      testWidgets('the filter sheet lays out at ${tier.key}', (
        WidgetTester tester,
      ) async {
        final (AppStrings strings, _, _) = await pumpList(
          tester,
          // The tier's real width, and a height that renders the whole sheet.
          size: Size(tier.value.width, 2000),
        );

        await tester.tap(find.text(strings.invoiceFilterAction));
        await tester.pumpAndSettle();

        // **Scoped to the sheet.** At the desktop tier «وضعیت» is also the
        // invoice table's status column header behind it, so an unscoped finder
        // reports two and fails a sheet that is laid out perfectly well. The
        // same trap the empty-state assertions in this file already carry.
        Finder inSheet(String text) => find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(text),
        );

        expect(inSheet(strings.invoiceFilterStatusSection), findsOneWidget);
        expect(inSheet(strings.invoiceFilterCustomerSection), findsOneWidget);
        expect(inSheet(strings.invoiceFilterPeriodSection), findsOneWidget);
        expect(find.byType(FilterChip), findsNWidgets(5));
      });

      testWidgets('the filter control is reachable at ${tier.key}', (
        WidgetTester tester,
      ) async {
        // On a phone the create action is the floating button and only the
        // filter is in the title row; on the wider tiers both are. Either way
        // the list must be narrowable — the tier where a user has the most
        // invoices on screen is not the tier where they most need to filter.
        final (AppStrings strings, _, _) = await pumpList(
          tester,
          size: tier.value,
        );

        expect(find.text(strings.invoiceFilterAction), findsOneWidget);
      });
    }

    testWidgets('clearing puts every filter back', (WidgetTester tester) async {
      final (AppStrings strings, FakeInvoiceRepository repo, _) =
          await pumpList(tester);

      await tester.tap(find.text(strings.invoiceFilterAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilterChip, strings.statusCancelled),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.invoiceFilterClearAll));
      await tester.pumpAndSettle();

      expect(repo.lastFilter, InvoiceFilter.none);
    });
  });

  group('a row opens the invoice it names', () {
    // **This group is the one it replaces, inverted.** Until Phase 5 (b) it was
    // called "routes that do not exist yet" and asserted that a row had no
    // `onTap` and that tapping went nowhere: `/invoices/:id` was deliberately
    // unregistered until the screen it opens existed (D-021, one level down),
    // so the absence of the affordance was the feature and was asserted rather
    // than assumed.
    //
    // The route and the screen arrived together in (b), so the assertion turns
    // over in the same change instead of being quietly deleted — a row still
    // has exactly one defined destination, and it is still pinned. Deleting it
    // would have left the tap untested at precisely the moment it started doing
    // something.

    testWidgets('on a desktop table row', (WidgetTester tester) async {
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
      expect(row.onTap, isNotNull);

      await tester.tap(find.byType(AppTableRow));
      await tester.pumpAndSettle();
      expect(lastLocation, '/invoices/a');
    });

    testWidgets('on a mobile card', (WidgetTester tester) async {
      // Asserted on both tiers rather than one. They are different widgets with
      // the same job, and the card is the one a phone user ever touches.
      await pumpScreen(
        tester,
        const InvoicesScreen(),
        overrides: withRepository(
          FakeInvoiceRepository(<InvoiceListItem>[
            item('a', liveCustomerName: 'مریم احمدی'),
            item('b', liveCustomerName: 'رضا کاظمی', sequence: 2),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      // The second card, so a test that navigated to whichever row happened to
      // be first would not pass by luck.
      await tester.tap(find.byType(InvoiceCard).at(1));
      await tester.pumpAndSettle();
      expect(lastLocation, '/invoices/b');
    });
  });
}
