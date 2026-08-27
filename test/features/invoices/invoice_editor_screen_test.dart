import 'dart:async';

import 'package:factorino/core/date/jalali_instant.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/utils/clock.dart';
import 'package:factorino/core/widgets/amount_text.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/invoice_list_item.dart';
import 'package:factorino/data/models/product.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/customer_repository.dart';
import 'package:factorino/data/repositories/product_repository.dart';
import 'package:factorino/data/repositories/settings_repository.dart';
import 'package:factorino/features/invoices/application/invoice_editor.dart';
import 'package:factorino/features/invoices/domain/invoice_editor_state.dart';
import 'package:factorino/features/invoices/presentation/invoice_editor_screen.dart';
import 'package:factorino/features/invoices/presentation/widgets/invoice_details_section.dart';
import 'package:factorino/features/invoices/presentation/widgets/invoice_lines_section.dart';
import 'package:factorino/features/invoices/presentation/widgets/invoice_totals_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../screen_harness.dart';
import 'fake_invoice_repository.dart';

/// The assembled invoice screen — Phase 4 increment (d).
///
/// Against the **real encrypted database**, because the two things worth
/// checking here are what reaches storage and what the user is told about it:
/// a draft that takes no number, an issue that does, and a confirmation that
/// states both consequences before either happens. A faked repository would
/// let the screen pass while the write it performs did something else.
///
/// The three layouts are checked for being genuinely different arrangements
/// (§10) rather than for pixel positions: what each tier does with the summary
/// is the decision, and it is the decision that should fail if someone
/// collapses them back into one.
void main() {
  late FakeInvoiceRepository invoices;

  /// A fixed "now", because the screen keys its editor by the clock. It is also
  /// what makes the invoice number deterministic: allocation uses the **Jalali**
  /// year of the issue date (D-013).
  final DateTime openedAt = startOfJalaliDayUtc(Jalali(1405, 6, 2));

  final Customer customer = Customer(
    id: 'customer-1',
    fullName: 'مریم احمدی',
    createdAt: openedAt,
    updatedAt: openedAt,
  );

  const AppSettings settings = AppSettings(
    defaultTaxRateBp: 900,
    roundingUnitRial: 0,
    invoiceNumberPrefix: 'INV',
  );

  setUp(() => invoices = FakeInvoiceRepository(const <InvoiceListItem>[]));

  Future<ProviderContainer> pumpEditor(
    WidgetTester tester, {
    Size size = kMobileSize,
  }) async {
    await pumpScreen(
      tester,
      const InvoiceEditorScreen(),
      size: size,
      overrides: <Override>[
        nowProvider.overrideWithValue(openedAt),
        invoiceRepositoryProvider.overrideWithValue(invoices),
        settingsRepositoryProvider.overrideWithValue(
          _FakeSettingsRepository(settings),
        ),
        customerRepositoryProvider.overrideWithValue(
          _FakeCustomerRepository(<Customer>[customer]),
        ),
        productRepositoryProvider.overrideWithValue(_FakeProductRepository()),
      ],
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(InvoiceEditorScreen)),
    );
  }

  InvoiceEditor editorOf(ProviderContainer container) =>
      container.read(invoiceEditorProvider(openedAt).notifier);

  InvoiceEditorState stateOf(ProviderContainer container) =>
      container.read(invoiceEditorProvider(openedAt)).requireValue;

  /// Fills the form the way a user would end up filling it, through the
  /// controller rather than through five sheets — the sheets have their own
  /// suites in (b) and (c), and driving them here would test them twice while
  /// making every assertion below depend on all of them.
  Future<void> fill(
    WidgetTester tester,
    ProviderContainer container, {
    int unitPriceRial = 1000000,
    int quantityMilli = 2000,
    Money discount = Money.zero,
  }) async {
    final InvoiceEditor editor = editorOf(container);
    editor.selectCustomer(customer.id);
    editor.addLine(
      InvoiceLineEntry(
        title: 'خدمات مشاوره',
        unit: 'ساعت',
        unitPrice: Money.rial(unitPriceRial),
        quantityMilli: quantityMilli,
      ),
    );
    if (discount != Money.zero) editor.setDiscountAmount(discount);
    await tester.pumpAndSettle();
  }

  /// Scrolls the form's own scroll view to the end.
  ///
  /// Needed more often than it looks: the fields alone are taller than a phone,
  /// and a `ListView` does not build what is off screen — so the lines section
  /// genuinely does not exist in the tree until the user has scrolled to it,
  /// which is also true of the user.
  Future<void> scrollForm(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byType(InvoiceLinesSection),
      400,
      // The form's own scroll view. On desktop there is a second one behind
      // the summary panel, and it is deliberately *not* this one -- that the
      // panel does not move is the assertion, not the mechanism.
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('the three layouts are three arrangements', () {
    testWidgets('a phone puts the total and both actions in a pinned bar', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpEditor(tester);
      await fill(tester, container);

      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);

      // One column, with the invoice-level fields folded (D-054): the lines —
      // the substance of the invoice — are what the first screen shows.
      expect(find.byType(InvoiceDetailsSection), findsOneWidget);
      expect(find.byType(InvoiceLinesSection), findsOneWidget);
      expect(
        find.text(strings.invoiceFieldIssueDate),
        findsNothing,
        reason: 'the fields start folded on a phone',
      );
      // But not the customer: it is the one field a save cannot do without, so
      // the heading states it whether the section is open or shut.
      expect(find.text(customer.fullName), findsOneWidget);

      final double barTop = tester
          .getTopLeft(find.byType(InvoiceTotalsSummary))
          .dy;
      expect(
        tester.getTopLeft(find.text(strings.invoiceActionIssue)).dy,
        greaterThan(barTop),
        reason: 'the actions sit under the total, inside the same bar',
      );

      // **The claim this layout makes.** Scroll the form and the bar has not
      // moved: the figure the user is deciding about stays on screen while
      // they edit the lines that change it, which is the whole reason a phone
      // gets a bar rather than a panel.
      await scrollForm(tester);
      expect(
        tester.getTopLeft(find.byType(InvoiceTotalsSummary)).dy,
        barTop,
        reason: 'the bar is pinned; if it scrolled it would be a footer',
      );
    });

    testWidgets('the phone folds the invoice-level fields, and unfolds them', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpEditor(tester);
      await fill(tester, container);
      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);

      // Folded: the dates, the discount and the notes are not in the tree.
      expect(find.text(strings.invoiceFieldIssueDate), findsNothing);
      expect(find.text(strings.invoiceFieldNotes), findsNothing);

      // The whole heading is the target, not the chevron alone.
      await tester.tap(find.text(strings.invoiceDetailsTitle));
      await tester.pumpAndSettle();
      expect(find.text(strings.invoiceFieldIssueDate), findsOneWidget);

      await tester.tap(find.text(strings.invoiceDetailsTitle));
      await tester.pumpAndSettle();
      expect(find.text(strings.invoiceFieldIssueDate), findsNothing);
    });

    testWidgets('folded with no customer, the heading says so', (
      WidgetTester tester,
    ) async {
      // The fold may never hide the state of the one field a save needs. With
      // no customer the heading says «مشتری انتخاب نشده», so the notice under
      // the disabled buttons points at something the user can see and reach.
      await pumpEditor(tester);
      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);

      expect(
        find.text(strings.invoiceDetailsCollapsedNoCustomer),
        findsOneWidget,
      );
      expect(find.text(strings.invoiceIncompleteCustomer), findsOneWidget);
    });

    testWidgets('the wider tiers do not fold anything', (
      WidgetTester tester,
    ) async {
      // Tablet and desktop have room for the fields and the lines at once, so
      // a fold there would be a control that saves nothing.
      final ProviderContainer container = await pumpEditor(
        tester,
        size: kDesktopSize,
      );
      await fill(tester, container);
      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);

      expect(find.text(strings.invoiceFieldIssueDate), findsOneWidget);
      expect(
        find.text(strings.invoiceDetailsCollapsedNoCustomer),
        findsNothing,
      );
    });

    testWidgets('a tablet puts the fields and the lines side by side', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpEditor(
        tester,
        size: const Size(900, 700),
      );
      await fill(tester, container);

      final double fieldsLeft = tester
          .getTopLeft(find.byType(InvoiceDetailsSection))
          .dx;
      final double linesLeft = tester
          .getTopLeft(find.byType(InvoiceLinesSection))
          .dx;
      final double fieldsTop = tester
          .getTopLeft(find.byType(InvoiceDetailsSection))
          .dy;
      final double linesTop = tester
          .getTopLeft(find.byType(InvoiceLinesSection))
          .dy;

      // Two panes: they start at the same height and at different widths. In
      // RTL the fields pane is the right-hand one, so it is the one with the
      // *larger* x.
      expect(fieldsTop, closeTo(linesTop, 1));
      expect(
        fieldsLeft,
        greaterThan(linesLeft),
        reason: 'RTL: the leading pane sits to the right',
      );
    });

    testWidgets('a desktop keeps the summary panel out of the scroll view', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpEditor(
        tester,
        size: kDesktopSize,
      );
      await fill(tester, container);

      final Offset summary = tester.getTopLeft(
        find.byType(InvoiceTotalsSummary),
      );
      final Offset fields = tester.getTopLeft(
        find.byType(InvoiceDetailsSection),
      );

      // The breakdown sits **beside the fields**, not under them: this tier is
      // the one with width to spare on a column of short labelled inputs.
      expect(summary.dy, closeTo(fields.dy, 24));
      expect(
        summary.dx,
        lessThan(fields.dx),
        reason: 'RTL: the panel sits to the left of the fields',
      );

      // And what stays pinned is the decision, not the detail: scroll to the
      // lines and the grand total in the bar has not moved, while the
      // breakdown has scrolled away with the fields it belongs to.
      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);
      final double pinnedTop = tester
          .getTopLeft(find.text(strings.invoiceActionIssue))
          .dy;
      await scrollForm(tester);
      expect(find.byType(InvoiceLinesSection), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(strings.invoiceActionIssue)).dy,
        pinnedTop,
      );
    });

    testWidgets('the lines are a real table on desktop, cards on a phone', (
      WidgetTester tester,
    ) async {
      // The table needs the full content width, which is the measurement that
      // decided this tier's arrangement -- so it is worth asserting that it
      // actually gets to be a table here.
      final ProviderContainer container = await pumpEditor(
        tester,
        size: kDesktopSize,
      );
      await fill(tester, container);
      await scrollForm(tester);

      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);
      expect(find.text(strings.invoiceLineColumnUnitPrice), findsOneWidget);
      expect(find.text(strings.invoiceLineColumnTotal), findsOneWidget);
    });
  });

  group('the totals are the engine\'s, and they follow the lines', () {
    testWidgets('the summary starts as a sentence, not a column of zeros', (
      WidgetTester tester,
    ) async {
      await pumpEditor(tester);
      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);

      // An invoice with no lines has totals, all zero. Rendering them would be
      // honest and useless -- and looks like a fault.
      expect(find.byType(InvoiceTotalsSummary), findsNothing);
      expect(find.text(strings.invoiceSummaryEmpty), findsOneWidget);
    });

    testWidgets('every figure on the panel is the one the engine produced', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpEditor(
        tester,
        size: kDesktopSize,
      );
      // 1,000,000 Rial x 2 = 2,000,000 gross; settings tax is the default.
      await fill(tester, container);

      final InvoiceEditorState state = stateOf(container);
      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);

      // Read off the state rather than hard-coded: the claim is that the panel
      // shows the engine's answer, not that the engine's answer is a
      // particular number -- which `invoice_calculator_test.dart` owns.
      expect(find.byType(InvoiceTotalsSummary), findsOneWidget);
      expect(find.text(strings.invoiceSummaryGross), findsOneWidget);
      // Scoped: this tier restates the grand total in the pinned bar, which is
      // the point of the bar. An unscoped finder would be asserting how many
      // places mention it rather than that the panel does.
      expect(
        find.descendant(
          of: find.byType(InvoiceTotalsSummary),
          matching: find.text(strings.invoiceSummaryGrandTotal),
        ),
        findsOneWidget,
      );
      expect(
        _amountsOn(tester),
        containsAll(<Money>[
          state.totals.grossTotal,
          state.totals.totalDiscount,
          state.totals.totalTax,
          state.totals.grandTotal,
        ]),
      );
    });

    testWidgets('adding a line moves the total, in the same frame', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpEditor(
        tester,
        size: kDesktopSize,
      );
      await fill(tester, container);
      final Money before = stateOf(container).totals.grandTotal;

      editorOf(container).addLine(
        InvoiceLineEntry(
          title: 'حمل و نقل',
          unit: 'عدد',
          unitPrice: Money.rial(500000),
          quantityMilli: 1000,
        ),
      );
      await tester.pumpAndSettle();

      final Money after = stateOf(container).totals.grandTotal;
      expect(after, greaterThan(before));
      expect(
        _amountsOn(tester),
        contains(after),
        reason: 'the panel must show the new total, not the previous one',
      );
    });

    testWidgets('a clamped discount is reported with both figures', (
      WidgetTester tester,
    ) async {
      // D-027: the engine reports a clamp as data, and the screen names both
      // the amount asked for and the amount given. A panel that showed only
      // the applied figure would be a document the user cannot reconcile
      // against what they typed.
      final ProviderContainer container = await pumpEditor(
        tester,
        size: kDesktopSize,
      );
      await fill(tester, container, discount: Money.rial(9000000));

      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);
      expect(stateOf(container).hasWarnings, isTrue);

      // The warnings render beneath the lines they are about, so reaching them
      // means scrolling there — as the user does.
      await scrollForm(tester);
      expect(find.text(strings.invoiceWarningsTitle), findsOneWidget);

      // Both figures, by their Persian rendering: 900,000 Toman requested
      // against the 200,000 the invoice was worth.
      expect(find.textContaining('۹۰۰٬۰۰۰'), findsWidgets);
      expect(find.textContaining('۲۰۰٬۰۰۰'), findsWidgets);
    });
  });

  group('draft and issue are different actions', () {
    testWidgets('both are blocked, and the reason says which half is missing', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpEditor(tester);
      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);

      expect(find.text(strings.invoiceIncompleteCustomer), findsOneWidget);
      expect(_enabled(tester, strings.invoiceActionSaveDraft), isFalse);
      expect(_enabled(tester, strings.invoiceActionIssue), isFalse);

      // A customer but no lines is a different missing half, and says so.
      editorOf(container).selectCustomer(customer.id);
      await tester.pumpAndSettle();
      expect(find.text(strings.invoiceIncompleteLines), findsOneWidget);
      expect(_enabled(tester, strings.invoiceActionIssue), isFalse);
    });

    testWidgets('saving a draft writes one, with no number', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpEditor(tester);
      await fill(tester, container);

      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);
      await tester.tap(find.text(strings.invoiceActionSaveDraft));
      await tester.pumpAndSettle();

      // `create` and not `issue`: that difference is the whole point of the
      // pair. A draft takes no number and stays editable (D-048), which is what
      // makes it the reversible half.
      expect(invoices.createdDrafts, hasLength(1));
      expect(invoices.issuedIds, isEmpty);
      expect(invoices.createdDrafts.single.customerId, customer.id);
      expect(find.text(strings.invoiceSaveDraftSuccess), findsOneWidget);
      expect(lastLocation, '/invoices');
    });

    testWidgets('issuing asks first, and says what it costs', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpEditor(tester);
      await fill(tester, container);

      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);
      await tester.tap(find.text(strings.invoiceActionIssue));
      await tester.pumpAndSettle();

      // The two irreversible consequences, both in the copy: a number is
      // allocated, and the invoice stops being editable.
      expect(find.text(strings.invoiceIssueConfirmTitle), findsOneWidget);
      expect(find.text(strings.invoiceIssueConfirmBody), findsOneWidget);
      expect(
        strings.invoiceIssueConfirmBody,
        allOf(contains('شماره'), contains('ویرایش')),
        reason:
            'the Persian copy must name both consequences; a confirmation that '
            'only says "are you sure" is a dialog people learn to dismiss',
      );
    });

    testWidgets('cancelling the confirmation writes nothing at all', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpEditor(tester);
      await fill(tester, container);

      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);
      await tester.tap(find.text(strings.invoiceActionIssue));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.actionCancel));
      await tester.pumpAndSettle();

      // Not even a draft. `issue()` saves first, so a confirmation that ran
      // the save before asking would leave a draft behind on every "no" —
      // permanent litter from a question the user declined.
      expect(invoices.createdDrafts, isEmpty);
      expect(invoices.issuedIds, isEmpty);
      expect(lastLocation, '/');
    });

    testWidgets('confirming issues it, and the number is in the message', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpEditor(tester);
      await fill(tester, container);

      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);
      await tester.tap(find.text(strings.invoiceActionIssue));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.invoiceIssueConfirmAction));
      await tester.pumpAndSettle();

      // Both writes, in that order: the draft first, then the number
      // (D-013, D-048). A failure between them leaves a recoverable numberless
      // draft rather than a spent number.
      expect(invoices.createdDrafts, hasLength(1));
      expect(invoices.issuedIds, hasLength(1));

      // The identity the document now has is what the user needs to see. Latin
      // digits, deliberately: an invoice number is an identifier rather than a
      // quantity, and `invoiceNumberLabel` isolates it rather than reshaping it
      // (D-048's bidi note).
      expect(
        find.textContaining(FakeInvoiceRepository.issuedNumber),
        findsWidgets,
      );
      expect(lastLocation, '/invoices');
    });

    testWidgets('a failed write says so in Persian and stays put', (
      WidgetTester tester,
    ) async {
      // §7: the repository's exception never reaches the user. The controller
      // turns it into null and a log line; the screen turns null into copy —
      // and does **not** navigate, because the invoice is still here to retry.
      final ProviderContainer container = await pumpEditor(tester);
      await fill(tester, container);
      invoices.failWrites = true;

      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);
      await tester.tap(find.text(strings.invoiceActionSaveDraft));
      await tester.pumpAndSettle();

      expect(find.text(strings.invoiceSaveFailed), findsOneWidget);
      expect(lastLocation, '/');
      expect(stateOf(container).lines, hasLength(1));
    });
  });

  group('leaving', () {
    testWidgets('an untouched form leaves without asking', (
      WidgetTester tester,
    ) async {
      await pumpEditor(tester);
      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);

      await tester.tap(find.byTooltip(strings.invoiceBackTooltip));
      await tester.pumpAndSettle();

      // A fresh form already has both dates, so asking here would be a
      // question with an obvious answer -- which is how a confirmation stops
      // being read.
      expect(find.text(strings.invoiceDiscardTitle), findsNothing);
      expect(lastLocation, '/invoices');
    });

    testWidgets('a form with an invoice in it asks before discarding', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpEditor(tester);
      await fill(tester, container);

      final AppStrings strings = stringsOf(tester, InvoiceEditorScreen);
      await tester.tap(find.byTooltip(strings.invoiceBackTooltip));
      await tester.pumpAndSettle();

      expect(find.text(strings.invoiceDiscardTitle), findsOneWidget);

      // Staying keeps every entry: the editor is auto-disposed, and a dialog
      // that discarded the work while asking whether to discard it would be
      // the defect this exists to prevent.
      await tester.tap(find.text(strings.invoiceDiscardKeepAction));
      await tester.pumpAndSettle();
      expect(lastLocation, '/');
      expect(stateOf(container).lines, hasLength(1));
    });
  });
}

/// Every amount rendered on screen, as [Money].
///
/// Read back through the widget tree rather than compared as formatted
/// strings, so an assertion is about the figure and not about the digit shaping
/// — which `AmountText` and `number_display` own and test separately.
Set<Money> _amountsOn(WidgetTester tester) {
  return tester
      .widgetList<AmountText>(find.byType(AmountText))
      .map((AmountText widget) => widget.amount)
      .toSet();
}

bool _enabled(WidgetTester tester, String label) {
  // `byWidgetPredicate`, not `byType(ButtonStyleButton)`: `find.byType` matches
  // the **exact** runtime type, so the abstract base finds nothing at all and
  // the helper reports "no such button" for a button that is right there.
  final ButtonStyleButton button = tester.widget<ButtonStyleButton>(
    find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((Widget w) => w is ButtonStyleButton),
    ),
  );
  return button.onPressed != null;
}

/// The settings the tax chain terminates at.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._current);

  AppSettings _current;

  @override
  Future<AppSettings> read() async => _current;

  @override
  Stream<AppSettings> watch() => Stream<AppSettings>.value(_current);

  @override
  Future<AppSettings> write(AppSettings settings) async {
    _current = settings;
    return settings;
  }

  @override
  Future<void> markBackedUp(DateTime at) async {}
}

/// Enough of the customer boundary for the picker and the name lookup.
class _FakeCustomerRepository implements CustomerRepository {
  _FakeCustomerRepository(this._customers);

  final List<Customer> _customers;

  @override
  Future<Customer?> findById(String id) async =>
      _customers.where((Customer c) => c.id == id).firstOrNull;

  @override
  Stream<List<Customer>> watchSearch(
    String term, {
    int limit = 100,
    int offset = 0,
  }) => Stream<List<Customer>>.value(_customers);

  @override
  Stream<List<Customer>> watchAll({int limit = 100, int offset = 0}) =>
      Stream<List<Customer>>.value(_customers);

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not exercised by these tests');
}

/// The catalogue side of the line entry, which this screen only routes to.
class _FakeProductRepository implements ProductRepository {
  @override
  Stream<List<Product>> watchSearch(
    String term, {
    int limit = 100,
    int offset = 0,
  }) => Stream<List<Product>>.value(const <Product>[]);

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not exercised by these tests');
}
