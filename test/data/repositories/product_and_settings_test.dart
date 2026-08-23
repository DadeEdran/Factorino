import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/product.dart';
import 'package:factorino/data/models/product_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repository_harness.dart';

void main() {
  late RepositoryHarness harness;

  setUp(() async => harness = await RepositoryHarness.open());
  tearDown(() async => harness.close());

  group('ProductRepository', () {
    test('round-trips a product as a domain model', () async {
      final product = await harness.products.create(
        ProductDraft(
          name: 'طراحی وب‌سایت',
          type: ProductType.service,
          price: Money.rial(25000000),
          unit: 'ساعت',
          description: 'شامل پشتیبانی',
        ),
      );

      expect(product, isA<Product>());
      expect(product.isService, isTrue);
      expect(product.price, Money.rial(25000000));
      expect(product.unit, 'ساعت');
    });

    test('search is normalization-insensitive, like customers', () async {
      await harness.product(name: 'كتاب آموزشي');

      expect(await harness.products.search('کتاب'), hasLength(1));
      expect(await harness.products.search('آموزشی'), hasLength(1));
    });

    test(
      'update rewrites search_name so the old name stops matching',
      () async {
        final product = await harness.product(name: 'كتاب آموزشي');

        await harness.products.update(
          product.id,
          ProductDraft(
            name: 'دفتر یادداشت',
            type: product.type,
            price: product.price,
            unit: product.unit,
          ),
        );

        expect(await harness.products.search('کتاب'), isEmpty);
        expect(await harness.products.search('دفتر'), hasLength(1));
      },
    );

    test(
      'a price change is stored and does not affect anything else',
      () async {
        final product = await harness.product(priceRial: 1000000);
        final updated = await harness.products.update(
          product.id,
          ProductDraft(
            name: product.name,
            type: product.type,
            price: Money.rial(1500000),
            unit: product.unit,
          ),
        );

        expect(updated.price, Money.rial(1500000));
        expect(updated.id, product.id);
      },
    );

    test('soft delete hides it from reads but keeps the row', () async {
      final product = await harness.product();
      await harness.products.softDelete(product.id);

      expect(await harness.products.findById(product.id), isNull);
      expect(await harness.products.count(), 0);

      // soft-delete-exempt: proving the row survives is the point.
      final rows = await harness.db.select(harness.db.products).get();
      expect(rows, hasLength(1));
      expect(rows.single.deletedAt, isNotNull);
    });

    test('the price crosses the boundary as Money, not a bare int', () async {
      final product = await harness.product(priceRial: 1234567);
      // The repository is the single place that converts (ARCHITECTURE §B.6).
      expect(product.price, isA<Money>());
      expect(product.price.rial, 1234567);
      expect(product.price.toman, 123456);
    });
  });

  group('SettingsRepository', () {
    test('the row exists from the moment the database does', () async {
      final settings = await harness.settings.read();

      expect(settings.defaultTaxRateBp, 1000);
      expect(settings.roundingUnitRial, 0);
      expect(settings.invoiceNumberPrefix, 'INV');
      expect(settings.devicePrefix, isNull);
      expect(settings.lastBackupAt, isNull);
    });

    test('writes are persisted', () async {
      final original = await harness.settings.read();
      await harness.settings.write(
        original.copyWith(
          defaultTaxRateBp: 900,
          roundingUnitRial: 1000,
          invoiceNumberPrefix: 'FCT',
        ),
      );

      final reread = await harness.settings.read();
      expect(reread.defaultTaxRateBp, 900);
      expect(reread.roundingUnitRial, 1000);
      expect(reread.invoiceNumberPrefix, 'FCT');
    });

    test('changing the tax rate does not alter an existing invoice', () async {
      // §4 and D-026: the resolved rate is snapshotted onto every item, so a
      // later settings change cannot rewrite a document already issued.
      final customer = await harness.customer();
      final created = await harness.invoices.create(
        harness.draft(customer.id, unitPriceRial: 1000000),
      );
      expect(created.invoice.totalTax, Money.rial(100000));

      final settings = await harness.settings.read();
      await harness.settings.write(settings.copyWith(defaultTaxRateBp: 5000));

      final reread = await harness.invoices.findDetail(created.invoice.id);
      expect(reread!.invoice.totalTax, Money.rial(100000));
      expect(reread.items.single.resolvedTaxRateBp, 1000);
      expect(reread.invoice.grandTotal, Money.rial(1100000));
    });

    test('the new rate applies to invoices created afterwards', () async {
      final customer = await harness.customer();
      final settings = await harness.settings.read();
      await harness.settings.write(settings.copyWith(defaultTaxRateBp: 900));

      final created = await harness.invoices.create(
        harness.draft(customer.id, unitPriceRial: 1000000),
      );
      expect(created.invoice.totalTax, Money.rial(90000));
    });

    test('rounding from settings reaches the stored invoice', () async {
      final customer = await harness.customer();
      final settings = await harness.settings.read();
      await harness.settings.write(settings.copyWith(roundingUnitRial: 1000));

      // 1,234,567 + 10% = 1,358,023.7 -> tax rounds to 123,457, total
      // 1,358,024, rounded to the nearest 1,000 -> 1,358,000.
      final created = await harness.invoices.create(
        harness.draft(customer.id, unitPriceRial: 1234567),
      );

      expect(created.invoice.grandTotal.rial % 1000, 0);
      expect(
        created.invoice.grandTotal.rial -
            created.invoice.roundingAdjustment.rial,
        created.invoice.subtotal.rial +
            created.invoice.totalTax.rial -
            created.invoice.discount.rial,
        reason: 'the adjustment is what keeps the invoice reconciling',
      );
    });

    test('markBackedUp records the instant in UTC', () async {
      final at = DateTime.utc(2026, 8, 24, 9, 30);
      await harness.settings.markBackedUp(at);

      final settings = await harness.settings.read();
      expect(settings.lastBackupAt, at);
      expect(settings.lastBackupAt!.isUtc, isTrue);
    });

    test('watch emits the updated settings', () async {
      final seen = <int>[];
      final subscription = harness.settings.watch().listen(
        (s) => seen.add(s.defaultTaxRateBp),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      final settings = await harness.settings.read();
      await harness.settings.write(settings.copyWith(defaultTaxRateBp: 800));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(seen.first, 1000);
      expect(seen.last, 800);
    });
  });
}
