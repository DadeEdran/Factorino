import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/utils/list_query.dart';
import 'package:factorino/core/widgets/app_table.dart';
import 'package:factorino/core/widgets/empty_state.dart';
import 'package:factorino/core/widgets/load_more_footer.dart';
import 'package:factorino/core/widgets/skeleton.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/features/customers/application/customers_providers.dart';
import 'package:factorino/features/customers/presentation/customers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screen_harness.dart';
import 'fake_customer_repository.dart';

/// The customer list, at each of the four states it can be in and at both
/// layouts it has.
///
/// The overrides go in at `customerRepositoryProvider` — the interface, not the
/// implementation — which is the seam D-032 built the composition root around.
/// A screen cannot tell the difference, which is the point: this exercises the
/// real widget, the real providers and the real paging logic.
void main() {
  final DateTime now = DateTime.utc(2026, 8, 24, 6);

  Customer customer(String id, String name, {String? mobile, String? company}) {
    return Customer(
      id: id,
      fullName: name,
      mobile: mobile,
      companyName: company,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<Override> withRepository(FakeCustomerRepository repository) {
    return <Override>[customerRepositoryProvider.overrideWithValue(repository)];
  }

  group('states', () {
    testWidgets('shows a skeleton, not a spinner, while loading', (
      WidgetTester tester,
    ) async {
      // §10 asks for skeleton loaders over full-screen spinners. Asserting the
      // absence of the spinner as well, because "we added a skeleton" and "we
      // replaced the spinner" are different claims.
      final FakeCustomerRepository repository =
          FakeCustomerRepository.pending();
      await pumpScreen(
        tester,
        const CustomersScreen(),
        overrides: withRepository(repository),
      );
      await tester.pump();

      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the designed empty state with a call to action', (
      WidgetTester tester,
    ) async {
      final FakeCustomerRepository repository = FakeCustomerRepository(
        <Customer>[],
      );
      await pumpScreen(
        tester,
        const CustomersScreen(),
        overrides: withRepository(repository),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomersScreen);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(strings.emptyCustomersTitle), findsOneWidget);
      expect(find.text(strings.emptyCustomersBody), findsOneWidget);
      // The call to action §10 requires. It is inside the empty state, not
      // merely somewhere on the page.
      expect(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.text(strings.customerAdd),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an empty search is a different empty state from no data', (
      WidgetTester tester,
    ) async {
      // "You have no customers" in response to a search that matched nothing
      // would be false, and offering "add a customer" there would be answering
      // a question nobody asked.
      final FakeCustomerRepository repository = FakeCustomerRepository(
        <Customer>[],
      );
      late WidgetRef capturedRef;
      await pumpScreen(
        tester,
        Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            capturedRef = ref;
            return const CustomersScreen();
          },
        ),
        overrides: withRepository(repository),
      );
      await tester.pumpAndSettle();

      capturedRef.read(customerListQueryProvider.notifier).search('خسرو');
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomersScreen);
      expect(find.text(strings.searchNoResultsTitle), findsOneWidget);
      expect(find.text(strings.emptyCustomersTitle), findsNothing);
      // The page-level "add customer" action stays -- it belongs to the
      // screen, not to the empty state. What must not appear is a create
      // button *inside* the no-results state, which would be answering a
      // question the user did not ask.
      expect(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.text(strings.customerAdd),
        ),
        findsNothing,
      );
    });

    testWidgets('surfaces a failure as Persian copy, never as the exception', (
      WidgetTester tester,
    ) async {
      // §7: no stack trace, SQL statement, path or raw exception string may
      // reach the user.
      final FakeCustomerRepository repository = FakeCustomerRepository.failing(
        StateError('SELECT * FROM customers -- C:\\Users\\x\\factorino.db'),
      );
      await pumpScreen(
        tester,
        const CustomersScreen(),
        overrides: withRepository(repository),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomersScreen);
      expect(find.text(strings.errorGenericTitle), findsOneWidget);
      expect(find.textContaining('SELECT'), findsNothing);
      expect(find.textContaining('factorino.db'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
    });
  });

  group('layout', () {
    testWidgets('mobile renders cards, not a table', (
      WidgetTester tester,
    ) async {
      final FakeCustomerRepository repository = FakeCustomerRepository(
        <Customer>[customer('a', 'مریم احمدی', mobile: '09123456789')],
      );
      await pumpScreen(
        tester,
        const CustomersScreen(),
        overrides: withRepository(repository),
        size: kMobileSize,
      );
      await tester.pumpAndSettle();

      expect(find.text('مریم احمدی'), findsOneWidget);
      expect(find.byType(AppTableHeader), findsNothing);
    });

    testWidgets('desktop renders a real table with a header', (
      WidgetTester tester,
    ) async {
      final FakeCustomerRepository repository = FakeCustomerRepository(
        <Customer>[
          customer('a', 'مریم احمدی', mobile: '09123456789', company: 'پارس'),
        ],
      );
      await pumpScreen(
        tester,
        const CustomersScreen(),
        overrides: withRepository(repository),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomersScreen);
      expect(find.byType(AppTableHeader), findsOneWidget);
      expect(find.text(strings.tableColumnName), findsOneWidget);
      expect(find.text(strings.tableColumnMobile), findsOneWidget);
      expect(find.byType(AppTableRow), findsOneWidget);
    });

    testWidgets('the desktop table is virtualized, not fully built', (
      WidgetTester tester,
    ) async {
      // The reason this is not a `DataTable`. Material's table builds every
      // row it is handed, so a full page would build all 40; a virtualized one
      // builds only what fits on screen. The gap is invisible at forty rows
      // and fatal at five thousand, which is why it is asserted here rather
      // than left to be discovered.
      final FakeCustomerRepository repository = FakeCustomerRepository(
        <Customer>[for (int i = 0; i < 400; i++) customer('c$i', 'مشتری $i')],
      );
      await pumpScreen(
        tester,
        const CustomersScreen(),
        overrides: withRepository(repository),
        size: kDesktopSize,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppTableRow), findsWidgets);
      expect(
        tester.widgetList(find.byType(AppTableRow)).length,
        lessThan(ListQuery.defaultPageSize),
      );
    });
  });

  group('paging', () {
    testWidgets('asks the database for one page, not for everything', (
      WidgetTester tester,
    ) async {
      // §13: the limit reaches SQL. If it did not, this list would work at
      // fifty rows and die at five thousand -- a defect shipped rather than
      // discovered.
      final FakeCustomerRepository repository = FakeCustomerRepository(
        <Customer>[for (int i = 0; i < 200; i++) customer('c$i', 'مشتری $i')],
      );
      await pumpScreen(
        tester,
        const CustomersScreen(),
        overrides: withRepository(repository),
      );
      await tester.pumpAndSettle();

      expect(repository.lastLimit, ListQuery.defaultPageSize);
    });

    testWidgets('load more widens the query window by one page', (
      WidgetTester tester,
    ) async {
      final FakeCustomerRepository repository = FakeCustomerRepository(
        <Customer>[for (int i = 0; i < 200; i++) customer('c$i', 'مشتری $i')],
      );
      await pumpScreen(
        tester,
        const CustomersScreen(),
        overrides: withRepository(repository),
      );
      await tester.pumpAndSettle();

      // The footer is the last item of a virtualized list, so it does not
      // exist until the list is scrolled far enough to build it -- which is
      // the same property the virtualization test asserts, seen from the other
      // side. Dragging is explicit about that rather than relying on a helper
      // that assumes the target is already in the tree.
      final Finder list = find.byType(ListView);
      for (int i = 0; i < 30 && !tester.any(find.byType(LoadMoreFooter)); i++) {
        await tester.drag(list, const Offset(0, -600));
        await tester.pump();
      }
      expect(find.byType(LoadMoreFooter), findsOneWidget);

      // Built is not the same as on screen: a virtualized list also builds a
      // cache extent below the viewport, so the footer can exist and still sit
      // under the bottom edge where a tap does not reach it.
      await tester.ensureVisible(find.byType(LoadMoreFooter));
      await tester.pumpAndSettle();

      // The button, not its label -- the label is a child of the ink well and
      // is not itself the hit target.
      await tester.tap(
        find.descendant(
          of: find.byType(LoadMoreFooter),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.lastLimit, ListQuery.defaultPageSize * 2);
    });

    testWidgets('no load-more control once the last page is short', (
      WidgetTester tester,
    ) async {
      final FakeCustomerRepository repository = FakeCustomerRepository(
        <Customer>[for (int i = 0; i < 3; i++) customer('c$i', 'مشتری $i')],
      );
      await pumpScreen(
        tester,
        const CustomersScreen(),
        overrides: withRepository(repository),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoadMoreFooter), findsNothing);
    });

    testWidgets('searching resets the window to one page', (
      WidgetTester tester,
    ) async {
      final FakeCustomerRepository repository = FakeCustomerRepository(
        <Customer>[for (int i = 0; i < 200; i++) customer('c$i', 'مشتری $i')],
      );
      late WidgetRef capturedRef;
      await pumpScreen(
        tester,
        Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            capturedRef = ref;
            return const CustomersScreen();
          },
        ),
        overrides: withRepository(repository),
      );
      await tester.pumpAndSettle();

      capturedRef.read(customerListQueryProvider.notifier).loadMore();
      capturedRef.read(customerListQueryProvider.notifier).loadMore();
      await tester.pumpAndSettle();
      expect(repository.lastLimit, ListQuery.defaultPageSize * 3);

      capturedRef.read(customerListQueryProvider.notifier).search('مشتری');
      await tester.pumpAndSettle();
      expect(repository.lastLimit, ListQuery.defaultPageSize);
      expect(repository.lastSearchTerm, 'مشتری');
    });
  });

  group('display', () {
    testWidgets('a missing mobile number says so rather than showing blank', (
      WidgetTester tester,
    ) async {
      final FakeCustomerRepository repository = FakeCustomerRepository(
        <Customer>[customer('a', 'مریم احمدی')],
      );
      await pumpScreen(
        tester,
        const CustomersScreen(),
        overrides: withRepository(repository),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomersScreen);
      expect(find.text(strings.customerNoMobile), findsOneWidget);
    });

    testWidgets('a mobile number is grouped and bidi-isolated', (
      WidgetTester tester,
    ) async {
      // §9. Without the isolate the number can reorder against the Persian
      // text beside it, and the same customer's number then reads differently
      // in a card and in a table.
      final FakeCustomerRepository repository = FakeCustomerRepository(
        <Customer>[customer('a', 'مریم احمدی', mobile: '09123456789')],
      );
      await pumpScreen(
        tester,
        const CustomersScreen(),
        overrides: withRepository(repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('\u2068۰۹۱۲ ۳۴۵ ۶۷۸۹\u2069'), findsOneWidget);
    });
  });

  group('delete', () {
    testWidgets('explains what survives, then completes the write', (
      WidgetTester tester,
    ) async {
      // This path shipped in (f1) untested, and it was broken: nothing on this
      // screen watches `customerEditorProvider`, so the auto-disposed
      // controller was collected during the await and the state write after it
      // threw `UnmountedRefException`. The delete itself had already happened,
      // so the user was shown nothing for something that did occur. The
      // controller now holds a `keepAlive` link for the duration of the write.
      final FakeCustomerRepository repository = FakeCustomerRepository(
        <Customer>[customer('a', 'مریم احمدی')],
      );
      await pumpScreen(
        tester,
        const CustomersScreen(),
        overrides: withRepository(repository),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomersScreen);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.actionDelete));
      await tester.pumpAndSettle();

      // The Persian copy §6 requires: the customer leaves the list, and the
      // invoices already issued to them keep their snapshotted figures (D-004).
      expect(find.text(strings.customerDeleteTitle), findsOneWidget);
      expect(find.text(strings.customerDeleteBody), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, strings.actionDelete),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.deleted, <String>['a']);
      expect(find.text(strings.customerDeleted), findsOneWidget);
    });

    testWidgets('cancelling deletes nothing', (WidgetTester tester) async {
      final FakeCustomerRepository repository = FakeCustomerRepository(
        <Customer>[customer('a', 'مریم احمدی')],
      );
      await pumpScreen(
        tester,
        const CustomersScreen(),
        overrides: withRepository(repository),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, CustomersScreen);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.actionDelete));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, strings.actionCancel),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.deleted, isEmpty);
    });
  });
}
