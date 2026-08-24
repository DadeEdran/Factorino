import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/widgets/app_text_field.dart';
import 'package:factorino/data/models/field_limits.dart';
import 'package:factorino/data/models/product.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:factorino/features/products/presentation/product_form_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screen_harness.dart';

/// The product form's **field-level limits** — all that remained of Phase 3
/// once increment (f1) had delivered the rest of it (D-042).
///
/// The same gap the customer form had, with the same failure: an over-long name
/// was accepted here, sent to the repository, and refused by drift with an
/// `InvalidDataException` that `describeFailure` does not recognise — so the
/// user saw the generic «خطایی رخ داد» and was told neither which field nor
/// why.
void main() {
  Future<void> pumpForm(
    WidgetTester tester, {
    _RecordingProductRepository? repository,
  }) async {
    await pumpScreen(
      tester,
      const ProductFormScreen(),
      overrides: <Override>[
        productRepositoryProvider.overrideWithValue(
          repository ?? _RecordingProductRepository(),
        ),
      ],
      size: const Size(500, 1000),
    );
    await tester.pumpAndSettle();
  }

  Finder fieldFor(WidgetTester tester, String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(AppTextField),
    );
  }

  testWidgets('every limit is the column\'s, read off the widget', (
    WidgetTester tester,
  ) async {
    // Read off the widget rather than compared against a number copied into
    // this test: a test carrying its own copy of 160 would keep passing after
    // the column changed, which is the failure being designed out.
    await pumpForm(tester);
    final AppStrings strings = stringsOf(tester, ProductFormScreen);

    int limitOf(String label) =>
        tester.widget<AppTextField>(fieldFor(tester, label)).maxLength;

    expect(limitOf(strings.productFieldName), ProductLimits.name);
    expect(limitOf(strings.productFieldUnit), ProductLimits.unit);
    expect(limitOf(strings.productFieldDescription), ProductLimits.description);
    // Money has no column length -- it is stored as an integer (D-002) -- but
    // it has a ceiling, and the field is as wide as the widest amount that can
    // exist rather than unbounded.
    expect(limitOf(strings.productFieldPrice), AmountLimits.tomanDigits);
  });

  testWidgets('a name longer than the column allows cannot be typed', (
    WidgetTester tester,
  ) async {
    final _RecordingProductRepository repository =
        _RecordingProductRepository();
    await pumpForm(tester, repository: repository);
    final AppStrings strings = stringsOf(tester, ProductFormScreen);

    await tester.enterText(
      fieldFor(tester, strings.productFieldName),
      'ا' * (ProductLimits.name + 40),
    );
    await tester.enterText(fieldFor(tester, strings.productFieldUnit), 'عدد');
    await tester.enterText(fieldFor(tester, strings.productFieldPrice), '5000');
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.actionSave));
    await tester.pumpAndSettle();

    expect(repository.created, hasLength(1));
    expect(repository.created.single.name.length, ProductLimits.name);
  });

  testWidgets('the price field refuses letters', (WidgetTester tester) async {
    await pumpForm(tester);
    final AppStrings strings = stringsOf(tester, ProductFormScreen);

    await tester.enterText(
      fieldFor(tester, strings.productFieldPrice),
      'ا12b۳٤',
    );
    await tester.pumpAndSettle();

    // Digits survive in whichever set they were typed and are folded at parse
    // time, not rewritten under the cursor (§9).
    expect(find.text('12۳٤'), findsOneWidget);
  });

  testWidgets('an amount past the ceiling is still refused in Persian', (
    WidgetTester tester,
  ) async {
    // The limit stops the entry getting absurdly long; the validator is what
    // enforces `kMaxAmountRial` itself, and it must keep doing so (D-002).
    final _RecordingProductRepository repository =
        _RecordingProductRepository();
    await pumpForm(tester, repository: repository);
    final AppStrings strings = stringsOf(tester, ProductFormScreen);

    await tester.enterText(fieldFor(tester, strings.productFieldName), 'کالا');
    await tester.enterText(fieldFor(tester, strings.productFieldUnit), 'عدد');
    await tester.enterText(
      fieldFor(tester, strings.productFieldPrice),
      '9' * AmountLimits.tomanDigits,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.actionSave));
    await tester.pumpAndSettle();

    expect(find.text(strings.validationAmountTooLarge), findsOneWidget);
    expect(repository.created, isEmpty);
  });
}

/// Records what the form asked the data layer to store.
class _RecordingProductRepository implements ProductRepository {
  final List<ProductDraft> created = <ProductDraft>[];

  @override
  Future<Product> create(ProductDraft draft) async {
    created.add(draft);
    return Product(
      id: 'created-${created.length}',
      name: draft.name,
      type: draft.type,
      price: draft.price,
      unit: draft.unit,
      description: draft.description,
      createdAt: DateTime.utc(2026, 8, 24),
      updatedAt: DateTime.utc(2026, 8, 24),
    );
  }

  @override
  Future<Product> update(String id, ProductDraft draft) => create(draft);

  @override
  Future<int> count() async => created.length;

  @override
  Stream<int> watchCount() => Stream<int>.value(created.length);

  @override
  Future<Product?> findById(String id) async => null;

  @override
  Future<List<Product>> search(
    String term, {
    int limit = 100,
    int offset = 0,
  }) => throw UnimplementedError('not exercised by these tests');

  @override
  Stream<List<Product>> watchAll({int limit = 100, int offset = 0}) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Stream<List<Product>> watchSearch(
    String term, {
    int limit = 100,
    int offset = 0,
  }) => throw UnimplementedError('not exercised by these tests');

  @override
  Future<void> softDelete(String id) async {}
}
