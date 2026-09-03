import 'dart:async';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/models/product.dart';
import 'package:factorino/data/models/product_type.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/product_repository.dart';
import 'package:factorino/data/repositories/settings_repository.dart';
import 'package:factorino/features/invoices/application/invoice_editor.dart';
import 'package:factorino/features/invoices/domain/invoice_editor_state.dart';
import 'package:factorino/features/invoices/presentation/widgets/invoice_lines_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screen_harness.dart';

/// Line item entry — Phase 4 increment (b).
///
/// The claims worth testing here are not "the widget renders". They are the
/// ones where getting it wrong produces a document that is quietly wrong:
///
/// * a picked product is **copied**, never referenced (D-004);
/// * a quantity reaches the state as `quantity_milli`, exactly, and a fourth
///   decimal place is **refused** rather than truncated (§4);
/// * `0` and *inherit* are different tax states and stay different (D-026);
/// * every figure on a row is the engine's, including the discount, which is
///   the one **applied** and not the one entered (§4 step 9, D-027).
void main() {
  final DateTime openedAt = DateTime.utc(2026, 8, 24, 12);

  const AppSettings settings = AppSettings(
    defaultTaxRateBp: 900,
    roundingUnitRial: 0,
    invoiceNumberPrefix: 'INV',
  );

  final Product catalogueEntry = Product(
    id: 'product-1',
    name: 'طراحی وب‌سایت',
    type: ProductType.service,
    price: Money.toman(500000),
    unit: 'ساعت',
    description: null,
    createdAt: openedAt,
    updatedAt: openedAt,
  );

  late _FakeProductRepository products;
  late _FakeSettingsRepository settingsRepository;

  setUp(() {
    products = _FakeProductRepository(<Product>[catalogueEntry]);
    settingsRepository = _FakeSettingsRepository(settings);
  });

  List<Override> overrides() => <Override>[
    productRepositoryProvider.overrideWithValue(products),
    settingsRepositoryProvider.overrideWithValue(settingsRepository),
  ];

  /// Pumps the section and returns a handle on the editor behind it, so a test
  /// can assert on the state the widget produced rather than on the pixels.
  Future<ProviderContainer> pumpSection(
    WidgetTester tester, {
    Size size = kMobileSize,
  }) async {
    await pumpScreen(
      tester,
      InvoiceLinesSection(openedAt: openedAt),
      overrides: overrides(),
      size: size,
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(InvoiceLinesSection)),
    );
  }

  InvoiceEditorState stateOf(ProviderContainer container) =>
      container.read(invoiceEditorProvider(openedAt)).requireValue;

  /// Fills the line editor sheet and submits it.
  Future<void> submitSheet(
    WidgetTester tester,
    AppStrings strings, {
    String? title,
    String? quantity,
    String? unit,
    String? unitPrice,
  }) async {
    Future<void> fill(String label, String? value) async {
      if (value == null) return;
      await tester.enterText(
        find.widgetWithText(TextFormField, label).last,
        value,
      );
      await tester.pump();
    }

    await fill(strings.invoiceLineFieldTitle, title);
    await fill(strings.invoiceLineFieldQuantity, quantity);
    await fill(strings.productFieldUnit, unit);
    await fill(strings.invoiceLineFieldUnitPrice, unitPrice);

    await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
    await tester.pumpAndSettle();
  }

  testWidgets('an invoice with no lines offers both ways to add one', (
    WidgetTester tester,
  ) async {
    await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

    expect(find.text(strings.invoiceLinesEmptyTitle), findsOneWidget);
    // Both routes visible at once: for a workshop billing one-off jobs, the
    // free-text line is the ordinary case and not a fallback.
    expect(find.text(strings.invoiceLineAddFromCatalogue), findsOneWidget);
    expect(find.text(strings.invoiceLineAddCustom), findsOneWidget);
  });

  testWidgets('a picked product is copied into the line, not referenced', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

    await tester.tap(find.text(strings.invoiceLineAddFromCatalogue));
    await tester.pumpAndSettle();
    await tester.tap(find.text(catalogueEntry.name));
    await tester.pumpAndSettle();

    await submitSheet(tester, strings);

    final InvoiceLineEntry added = stateOf(container).lines.single;
    expect(added.title, catalogueEntry.name);
    expect(added.unit, catalogueEntry.unit);
    expect(added.unitPrice, catalogueEntry.price);
    // The id rides along for traceability only. D-004's whole point is that
    // the three values above are now this invoice's own.
    expect(added.productId, catalogueEntry.id);

    // The proof that it is a copy: change the catalogue underneath it and the
    // line does not move. A live reference would rewrite financial history the
    // next time the price changed.
    products.replace(
      Product(
        id: catalogueEntry.id,
        name: 'نام تازه',
        type: catalogueEntry.type,
        price: Money.toman(999999),
        unit: catalogueEntry.unit,
        description: null,
        createdAt: openedAt,
        updatedAt: openedAt,
      ),
    );
    await tester.pumpAndSettle();

    final InvoiceLineEntry after = stateOf(container).lines.single;
    expect(after.title, catalogueEntry.name);
    expect(after.unitPrice, catalogueEntry.price);
  });

  testWidgets('a fractional quantity reaches the state as quantity_milli', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

    await tester.tap(find.text(strings.invoiceLineAddCustom));
    await tester.pumpAndSettle();
    await submitSheet(
      tester,
      strings,
      title: 'کار ساعتی',
      quantity: '1.5',
      unit: 'ساعت',
      unitPrice: '200000',
    );

    // 1.5 → 1500, exactly, with no double anywhere between the keyboard and
    // here (§4, D-002).
    expect(stateOf(container).lines.single.quantityMilli, 1500);
  });

  testWidgets('Persian digits are accepted in the quantity field', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

    await tester.tap(find.text(strings.invoiceLineAddCustom));
    await tester.pumpAndSettle();
    await submitSheet(
      tester,
      strings,
      title: 'کار ساعتی',
      // What an Iranian user's keyboard actually produces (§9).
      quantity: '۲٫۲۵',
      unit: 'ساعت',
      unitPrice: '۱۰۰۰۰۰',
    );

    expect(stateOf(container).lines.single.quantityMilli, 2250);
    expect(stateOf(container).lines.single.unitPrice, Money.toman(100000));
  });

  testWidgets('a fourth decimal place is refused, not truncated', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

    await tester.tap(find.text(strings.invoiceLineAddCustom));
    await tester.pumpAndSettle();
    await submitSheet(
      tester,
      strings,
      title: 'کار ساعتی',
      quantity: '1.2345',
      unit: 'ساعت',
      unitPrice: '200000',
    );

    // No line was added, and the message says *why* — "invalid" would leave
    // the user retyping the same thing. Billing 1.234 for an entered 1.2345 is
    // exactly the silent arithmetic error §4 exists to prevent.
    expect(stateOf(container).lines, isEmpty);
    expect(find.text(strings.validationQuantityTooPrecise), findsOneWidget);
  });

  testWidgets('an explicit zero tax rate is not the same as inheriting', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

    await tester.tap(find.text(strings.invoiceLineAddCustom));
    await tester.pumpAndSettle();

    await tester.tap(find.text(strings.invoiceLineTaxCustom));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, strings.invoiceLineTaxCustom).last,
      '0',
    );
    await submitSheet(
      tester,
      strings,
      title: 'کالای معاف',
      quantity: '1',
      unit: 'عدد',
      unitPrice: '100000',
    );

    final InvoiceEditorState state = stateOf(container);
    // `0`, not null. This is D-026 in one assertion: had the two collapsed,
    // a line the user marked exempt would have taken the 9% default.
    expect(state.lines.single.taxRateBp, 0);
    expect(state.totals.lines.single.resolvedTaxRateBp, 0);
    expect(state.totals.lines.single.tax, Money.zero);
  });

  testWidgets('an inherited rate resolves to the settings default', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

    await tester.tap(find.text(strings.invoiceLineAddCustom));
    await tester.pumpAndSettle();
    await submitSheet(
      tester,
      strings,
      title: 'کالای عادی',
      quantity: '1',
      unit: 'عدد',
      unitPrice: '100000',
    );

    final InvoiceEditorState state = stateOf(container);
    expect(state.lines.single.taxRateBp, isNull, reason: 'inherit is null');
    // Resolved by the engine, not by the widget: item → invoice → settings.
    expect(state.totals.lines.single.resolvedTaxRateBp, 900);
  });

  testWidgets('a percentage discount is stored as basis points', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

    await tester.tap(find.text(strings.invoiceLineAddCustom));
    await tester.pumpAndSettle();

    await tester.tap(find.text(strings.invoiceLineDiscountModePercent));
    await tester.pumpAndSettle();
    await tester.enterText(
      find
          .widgetWithText(TextFormField, strings.invoiceLineDiscountModePercent)
          .last,
      '9.5',
    );
    await submitSheet(
      tester,
      strings,
      title: 'کالا',
      quantity: '1',
      unit: 'عدد',
      unitPrice: '100000',
    );

    final InvoiceLineEntry line = stateOf(container).lines.single;
    // Two decimal places of a percent *is* basis points: 9.5% is 950, exactly.
    expect(line.discountPercentBp, 950);
    // And the absolute field stays zero, so a stale amount cannot compete with
    // the percentage in the engine (§4 step 2).
    expect(line.discount, Money.zero);
  });

  testWidgets(
    'switching discount mode clears the value rather than reusing it',
    (WidgetTester tester) async {
      await pumpSection(tester);
      final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

      await tester.tap(find.text(strings.invoiceLineAddCustom));
      await tester.pumpAndSettle();

      await tester.enterText(
        find
            .widgetWithText(
              TextFormField,
              strings.invoiceLineDiscountModeAmount,
            )
            .last,
        '5000',
      );
      await tester.pump();

      await tester.tap(find.text(strings.invoiceLineDiscountModePercent));
      await tester.pumpAndSettle();

      // `5000` means five thousand Toman in one mode and an impossible
      // percentage in the other. Carrying it across would silently change what
      // the user entered into something they never typed.
      expect(find.text('5000'), findsNothing);
    },
  );

  testWidgets('a line shows the discount applied, not the one entered', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

    // A discount larger than the line is worth. The engine clamps it (§4 step
    // 3) and reports both figures (D-027).
    container
        .read(invoiceEditorProvider(openedAt).notifier)
        .addLine(
          InvoiceLineEntry(
            title: 'کالا',
            unit: 'عدد',
            unitPrice: Money.toman(10000),
            quantityMilli: 1000,
            discount: Money.toman(50000),
          ),
        );
    await tester.pumpAndSettle();

    final InvoiceEditorState state = stateOf(container);
    expect(state.totals.lines.single.discountRequested, Money.toman(50000));
    expect(state.totals.lines.single.discount, Money.toman(10000));

    // The row prints the applied figure — the one a customer reconciling the
    // document by hand can arrive at.
    expect(
      find.textContaining(strings.invoiceLineLabelDiscount('۱۰٬۰۰۰')),
      findsOneWidget,
    );
    // And the clamp is surfaced rather than absorbed: both figures, named.
    expect(find.text(strings.invoiceWarningsTitle), findsOneWidget);
  });

  testWidgets('lines can be reordered and removed', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

    final InvoiceEditor editor = container.read(
      invoiceEditorProvider(openedAt).notifier,
    );
    for (final String title in <String>['اول', 'دوم']) {
      editor.addLine(
        InvoiceLineEntry(
          title: title,
          unit: 'عدد',
          unitPrice: Money.toman(1000),
          quantityMilli: 1000,
        ),
      );
    }
    await tester.pumpAndSettle();

    // The first row's "up" is disabled rather than hidden: a control that
    // vanishes shifts the two beside it under the user's finger.
    final Finder moveUp = find.widgetWithIcon(IconButton, Icons.arrow_upward);
    expect(tester.widget<IconButton>(moveUp.first).onPressed, isNull);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.arrow_downward).first,
    );
    await tester.pumpAndSettle();
    expect(
      stateOf(container).lines.map((InvoiceLineEntry l) => l.title),
      <String>['دوم', 'اول'],
    );

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.delete_outline).first,
    );
    await tester.pumpAndSettle();
    expect(stateOf(container).lines.single.title, 'اول');

    expect(strings.invoiceLineActionRemove, isNotEmpty);
  });

  testWidgets('a line picked from the catalogue asks only how many', (
    WidgetTester tester,
  ) async {
    // **D-097, and it is the same rule D-090 stated one case of.** Whether the
    // line is new or reopened is not the question; whether a product record
    // stands behind it is. A price typed over the catalogue's own matches no
    // record anybody can look up six months later, and the invoice line still
    // points at the product it no longer agrees with.
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

    await tester.tap(find.text(strings.invoiceLineAddFromCatalogue));
    await tester.pumpAndSettle();
    await tester.tap(find.text(catalogueEntry.name));
    await tester.pumpAndSettle();

    // The sheet opened on the product, and asks one question.
    expect(
      find.widgetWithText(TextFormField, strings.invoiceLineFieldQuantity),
      findsOneWidget,
    );
    for (final String label in <String>[
      strings.invoiceLineFieldTitle,
      strings.invoiceLineFieldUnitPrice,
      strings.productFieldUnit,
    ]) {
      expect(
        find.widgetWithText(TextFormField, label),
        findsNothing,
        reason: 'the product record owns «\$label», not this sheet',
      );
    }
    // The values are stated rather than merely withheld, so the user can see
    // what they are agreeing to add.
    expect(find.text(catalogueEntry.name), findsWidgets);
    expect(find.text(strings.invoiceLineFixedNote), findsOneWidget);

    await submitSheet(tester, strings, quantity: '3');

    // The snapshot is the catalogue's, exactly (D-004), and the one figure the
    // user gave is theirs.
    final InvoiceLineEntry added = stateOf(container).lines.single;
    expect(added.quantityMilli, 3000);
    expect(added.title, catalogueEntry.name);
    expect(added.unit, catalogueEntry.unit);
    expect(added.unitPrice, catalogueEntry.price);
    expect(added.productId, catalogueEntry.id);
  });

  testWidgets('a free line still collects everything, because nothing backs it', (
    WidgetTester tester,
  ) async {
    // **The exception that keeps the rule honest.** There is no product record
    // behind «سطر آزاد», so a title and a price typed there duplicate nothing —
    // they are the only statement of what is being billed. For a workshop
    // billing one-off jobs this is the ordinary case, not a fallback.
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

    await tester.tap(find.text(strings.invoiceLineAddCustom));
    await tester.pumpAndSettle();

    for (final String label in <String>[
      strings.invoiceLineFieldTitle,
      strings.invoiceLineFieldQuantity,
      strings.invoiceLineFieldUnitPrice,
      strings.productFieldUnit,
    ]) {
      expect(find.widgetWithText(TextFormField, label), findsOneWidget);
    }

    await submitSheet(
      tester,
      strings,
      title: 'تعمیر موردی',
      quantity: '1',
      unit: 'عدد',
      unitPrice: '450000',
    );

    final InvoiceLineEntry added = stateOf(container).lines.single;
    expect(added.title, 'تعمیر موردی');
    expect(added.unitPrice, Money.toman(450000));
    expect(
      added.productId,
      isNull,
      reason: 'a free line points at no product, which is why it may be typed',
    );
  });

  testWidgets('editing a row changes its quantity and nothing else', (
    WidgetTester tester,
  ) async {
    // **Reopening a line collects the quantity, and only the quantity**
    // (D-090). The title, unit, price, discount and rate are shown as the line
    // states them and are not fields: a price on an invoice line is a snapshot
    // of the catalogue (D-004), and one retyped here matches no product record
    // and nothing anybody can look up when the customer queries it.
    final ProviderContainer container = await pumpSection(tester);
    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);

    container
        .read(invoiceEditorProvider(openedAt).notifier)
        .addLine(
          InvoiceLineEntry(
            title: 'قبلی',
            unit: 'عدد',
            unitPrice: Money.toman(1000),
            quantityMilli: 2000,
            productId: 'product-7',
          ),
        );
    await tester.pumpAndSettle();

    await tester.tap(find.text('قبلی'));
    await tester.pumpAndSettle();

    // The sheet opened pre-filled with the line's own quantity, in the
    // editable form: `2000` milli reads as `2`, not as `2.000`.
    expect(find.text('2'), findsOneWidget);

    // The fields that are gone are **gone**, not disabled: a greyed-out input
    // is an invitation the sheet then refuses.
    expect(
      find.widgetWithText(TextFormField, strings.invoiceLineFieldTitle),
      findsNothing,
    );
    expect(
      find.widgetWithText(TextFormField, strings.invoiceLineFieldUnitPrice),
      findsNothing,
    );
    // ...and the values they held are stated instead, so the user can still
    // see what the line says.
    expect(find.text('قبلی'), findsWidgets);
    expect(find.text(strings.invoiceLineFixedNote), findsOneWidget);

    await submitSheet(tester, strings, quantity: '5');

    final InvoiceLineEntry edited = stateOf(container).lines.single;
    expect(edited.quantityMilli, 5000);
    // Everything else survives the round trip through the sheet untouched --
    // the controllers still hold it, so not collecting a field is not the same
    // as dropping it.
    expect(edited.title, 'قبلی');
    expect(edited.unit, 'عدد');
    expect(edited.unitPrice, Money.toman(1000));
    expect(edited.productId, 'product-7');
  });

  testWidgets('the desktop tier renders a table, the phone renders cards', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSection(
      tester,
      size: kDesktopSize,
    );

    container
        .read(invoiceEditorProvider(openedAt).notifier)
        .addLine(
          InvoiceLineEntry(
            title: 'کالا',
            unit: 'عدد',
            unitPrice: Money.toman(1000),
            quantityMilli: 1000,
          ),
        );
    await tester.pumpAndSettle();

    final AppStrings strings = stringsOf(tester, InvoiceLinesSection);
    // A real data table on desktop, not a stretched mobile list (§10).
    expect(find.text(strings.invoiceLineColumnTotal), findsOneWidget);
  });
}

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this._products);

  List<Product> _products;
  final StreamController<List<Product>> _controller =
      StreamController<List<Product>>.broadcast();

  /// Changes the catalogue under a line that was already taken from it — the
  /// scenario D-004 exists for.
  void replace(Product product) {
    _products = <Product>[product];
    _controller.add(_products);
  }

  Stream<List<Product>> _stream() async* {
    yield _products;
    yield* _controller.stream;
  }

  @override
  Stream<List<Product>> watchAll({int limit = 100, int offset = 0}) =>
      _stream();

  @override
  Stream<List<Product>> watchSearch(
    String term, {
    int limit = 100,
    int offset = 0,
  }) => _stream();

  @override
  Future<Product?> findById(String id) async =>
      _products.where((Product p) => p.id == id).firstOrNull;

  @override
  Future<int> count() async => _products.length;

  @override
  Stream<int> watchCount() => Stream<int>.value(_products.length);

  @override
  Future<List<Product>> search(
    String term, {
    int limit = 100,
    int offset = 0,
  }) async => _products;

  @override
  Future<Product> create(ProductDraft draft) =>
      throw UnimplementedError('the picker never writes');

  @override
  Future<Product> update(String id, ProductDraft draft) =>
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
