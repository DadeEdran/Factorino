import 'dart:async';

import 'package:factorino/core/date/jalali_instant.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/customer_repository.dart';
import 'package:factorino/data/repositories/settings_repository.dart';
import 'package:factorino/features/invoices/application/invoice_editor.dart';
import 'package:factorino/features/invoices/domain/invoice_editor_state.dart';
import 'package:factorino/features/invoices/presentation/widgets/invoice_details_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../screen_harness.dart';

/// The invoice-level fields — Phase 4 increment (c).
///
/// What is worth pinning here is the same shape as in (b): not that the widget
/// renders, but the places where a wrong answer produces a document that looks
/// right. Customer selection going through the **repository's** search rather
/// than a parallel one; dates leaving as UTC instants; `0` and inherit staying
/// apart at the invoice level too; and a derived due date moving with the issue
/// date while a chosen one does not.
void main() {
  final DateTime openedAt = DateTime.utc(2026, 8, 24, 12);

  const AppSettings settings = AppSettings(
    defaultTaxRateBp: 900,
    roundingUnitRial: 0,
    invoiceNumberPrefix: 'INV',
  );

  final Customer ali = Customer(
    id: 'customer-1',
    fullName: 'علی رضایی',
    createdAt: openedAt,
    updatedAt: openedAt,
  );

  late _FakeCustomerRepository customers;

  setUp(() => customers = _FakeCustomerRepository(<Customer>[ali]));

  Future<ProviderContainer> pumpSection(WidgetTester tester) async {
    await pumpScreen(
      tester,
      InvoiceDetailsSection(openedAt: openedAt),
      overrides: <Override>[
        customerRepositoryProvider.overrideWithValue(customers),
        settingsRepositoryProvider.overrideWithValue(
          _FakeSettingsRepository(settings),
        ),
      ],
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(InvoiceDetailsSection)),
    );
  }

  InvoiceEditorState stateOf(ProviderContainer container) =>
      container.read(invoiceEditorProvider(openedAt)).requireValue;

  testWidgets('a fresh invoice has no customer and a derived due date', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceDetailsSection);
    final InvoiceEditorState state = stateOf(container);

    expect(state.customerId, isNull);
    expect(find.text(strings.invoiceFieldCustomerEmpty), findsOneWidget);

    // The default term, applied to the issue date the form opened with.
    expect(state.dueDate, defaultDueDate(openedAt, kDefaultPaymentTermDays));
    expect(state.dueDateFollowsIssueDate, isTrue);
  });

  testWidgets('choosing a customer goes through the repository search', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceDetailsSection);

    await tester.tap(find.text(strings.invoiceFieldCustomerEmpty));
    await tester.pumpAndSettle();

    // Typing the term the user would actually type. The point of the
    // assertion below is *where* the folding happens: the term reaches the
    // repository as typed and the repository folds it (D-025, D-029). A sheet
    // that filtered a loaded list here would be a second normalizer, and the
    // two diverge silently.
    await tester.enterText(find.byType(TextField).last, 'علي');
    await tester.pumpAndSettle();

    expect(
      customers.searchedTerms,
      contains('علي'),
      reason: 'the raw term must reach the repository, unfolded by the widget',
    );

    await tester.tap(find.text(ali.fullName));
    await tester.pumpAndSettle();

    expect(stateOf(container).customerId, ali.id);
    // The chosen customer's name is shown, read by id rather than carried in
    // the editor state.
    expect(find.text(ali.fullName), findsOneWidget);
  });

  testWidgets('moving the issue date carries a derived due date with it', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);

    final DateTime moved = startOfJalaliDayUtc(Jalali(1405, 9, 1));
    container
        .read(invoiceEditorProvider(openedAt).notifier)
        .setIssueDate(moved);
    await tester.pumpAndSettle();

    final InvoiceEditorState state = stateOf(container);
    expect(state.issueDate, moved);
    // A due date the user never chose is a statement about the payment term.
    // Leaving it behind would produce a document due before it was issued.
    expect(state.dueDate, defaultDueDate(moved, kDefaultPaymentTermDays));
  });

  testWidgets('a due date the user chose is not dragged by the issue date', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final InvoiceEditor editor = container.read(
      invoiceEditorProvider(openedAt).notifier,
    );

    final DateTime chosen = startOfJalaliDayUtc(Jalali(1405, 6, 20));
    editor.setDueDate(chosen);
    await tester.pumpAndSettle();
    expect(stateOf(container).dueDateFollowsIssueDate, isFalse);

    editor.setIssueDate(startOfJalaliDayUtc(Jalali(1405, 6, 5)));
    await tester.pumpAndSettle();

    // Unmoved. A chosen due date is a commitment to a day, and dragging it
    // would silently rewrite an agreement.
    expect(stateOf(container).dueDate, chosen);
  });

  testWidgets(
    'clearing the due date leaves none, and does not resume guessing',
    (WidgetTester tester) async {
      final ProviderContainer container = await pumpSection(tester);
      final InvoiceEditor editor = container.read(
        invoiceEditorProvider(openedAt).notifier,
      );

      editor.setDueDate(null);
      await tester.pumpAndSettle();
      expect(stateOf(container).dueDate, isNull);

      editor.setIssueDate(startOfJalaliDayUtc(Jalali(1405, 9, 1)));
      await tester.pumpAndSettle();
      // Still none: once the user has expressed an intent about the date, the
      // app does not start filling it in again.
      expect(stateOf(container).dueDate, isNull);
    },
  );

  testWidgets('an invoice discount typed as an amount reaches the engine', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceDetailsSection);

    container
        .read(invoiceEditorProvider(openedAt).notifier)
        .addLine(
          InvoiceLineEntry(
            title: 'کالا',
            unit: 'عدد',
            unitPrice: Money.toman(100000),
            quantityMilli: 1000,
          ),
        );
    await tester.pumpAndSettle();

    await tester.enterText(
      find
          .widgetWithText(TextFormField, strings.invoiceLineDiscountModeAmount)
          .last,
      '20000',
    );
    await tester.pumpAndSettle();

    final InvoiceEditorState state = stateOf(container);
    expect(state.discount, Money.toman(20000));
    expect(state.discountPercentBp, isNull);
    // Allocated across the lines by the engine, before tax (§4 step 4).
    expect(state.totals.invoiceDiscount, Money.toman(20000));
  });

  testWidgets('switching the discount to a percentage clears the amount', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceDetailsSection);

    await tester.enterText(
      find
          .widgetWithText(TextFormField, strings.invoiceLineDiscountModeAmount)
          .last,
      '20000',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(strings.invoiceLineDiscountModePercent));
    await tester.pumpAndSettle();

    // The controller was told, not only the field. A stale amount left set
    // beside a percentage would reach the engine alongside it (§4 step 2).
    expect(stateOf(container).discount, Money.zero);
    expect(find.text('20000'), findsNothing);
  });

  testWidgets('an invoice tax rate of zero is not the same as inheriting', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceDetailsSection);

    // It starts inherited: null, resolving to the settings default.
    expect(stateOf(container).taxRateBp, isNull);

    await tester.tap(find.text(strings.invoiceLineTaxCustom));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, strings.invoiceLineTaxCustom).last,
      '0',
    );
    await tester.pumpAndSettle();

    // Zero, not null: this document is not taxed, as distinct from "use the
    // default" (D-026).
    expect(stateOf(container).taxRateBp, 0);

    await tester.tap(find.text(strings.invoiceLineTaxInherit));
    await tester.pumpAndSettle();
    expect(stateOf(container).taxRateBp, isNull);
  });

  testWidgets('the inherited rate names the default in force', (
    WidgetTester tester,
  ) async {
    await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceDetailsSection);

    // "Default" is only reassuring if it says which one. 900bp is 9%.
    expect(
      find.text(strings.invoiceLineTaxInheritedNote('۹٪')),
      findsOneWidget,
    );
  });

  testWidgets('notes reach the state as typed', (WidgetTester tester) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceDetailsSection);

    await tester.enterText(
      find.widgetWithText(TextFormField, strings.invoiceFieldNotes).last,
      'پرداخت تا پایان ماه',
    );
    await tester.pumpAndSettle();

    expect(stateOf(container).notes, 'پرداخت تا پایان ماه');
  });
}

class _FakeCustomerRepository implements CustomerRepository {
  _FakeCustomerRepository(this._customers);

  final List<Customer> _customers;

  /// Every term the widget handed to the repository, so a test can assert the
  /// search went through the repository rather than being done in Dart.
  final List<String> searchedTerms = <String>[];

  @override
  Stream<List<Customer>> watchAll({int limit = 100, int offset = 0}) =>
      Stream<List<Customer>>.value(_customers);

  @override
  Stream<List<Customer>> watchSearch(
    String term, {
    int limit = 100,
    int offset = 0,
  }) {
    searchedTerms.add(term);
    // Deliberately returns everything: the folding is the repository's job and
    // this fake is not reimplementing it. What is under test is that the term
    // arrived here at all.
    return Stream<List<Customer>>.value(_customers);
  }

  @override
  Future<Customer?> findById(String id) async =>
      _customers.where((Customer c) => c.id == id).firstOrNull;

  @override
  Future<List<Customer>> search(
    String term, {
    int limit = 100,
    int offset = 0,
  }) async {
    searchedTerms.add(term);
    return _customers;
  }

  @override
  Future<int> count() async => _customers.length;

  @override
  Stream<int> watchCount() => Stream<int>.value(_customers.length);

  @override
  Future<Customer> create(CustomerDraft draft) =>
      throw UnimplementedError('the picker never writes');

  @override
  Future<Customer> update(String id, CustomerDraft draft) =>
      throw UnimplementedError('the picker never writes');

  @override
  Future<void> softDelete(String id) =>
      throw UnimplementedError('the picker never writes');
}

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
