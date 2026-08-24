import 'package:factorino/core/money/invoice_calculator.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_detail.dart';
import 'package:factorino/data/models/invoice_item.dart';
import 'package:factorino/data/models/product.dart';
import 'package:factorino/data/repositories/invoice_repository.dart';
import 'package:factorino/features/invoices/domain/invoice_editor_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../data/repositories/repository_harness.dart';

/// **The figure the user was shown and the figure that was stored are the same
/// figure.**
///
/// There are two callers of the money engine, and they exist for different
/// reasons: `InvoiceEditorState` computes the preview on every edit, and
/// `DriftInvoiceRepository` computes the totals again inside the transaction
/// that writes them, because a caller must not be able to supply a total. That
/// is the right design and it has one hazard — the two could be fed *slightly*
/// different inputs, and each answer would look entirely reasonable on its own.
/// The user would agree to one number and receive another, and nothing in
/// either code path would look wrong.
///
/// `single_calculation_path_test.dart` keeps a third caller from appearing.
/// This is what keeps the two that exist honest, through the **real encrypted
/// database** rather than a fake, because the round trip through integer
/// columns is part of the claim.
void main() {
  late RepositoryHarness harness;
  late String customerId;
  late AppSettings settings;

  setUp(() async {
    harness = await RepositoryHarness.open();
    customerId = (await harness.customer()).id;
    // The editor previews against the same settings the repository will resolve
    // against inside the transaction. Reading them from the same place is the
    // point: a test that hardcoded them would pass while the two diverged.
    settings = await harness.settings.read();
  });
  tearDown(() async => harness.close());

  InvoiceLineEntry line({
    String title = 'خدمات',
    String unit = 'عدد',
    int priceRial = 1000000,
    int quantityMilli = 1000,
    int discountRial = 0,
    int? discountPercentBp,
    int? taxRateBp,
  }) {
    return InvoiceLineEntry(
      title: title,
      unit: unit,
      unitPrice: Money.rial(priceRial),
      quantityMilli: quantityMilli,
      discount: Money.rial(discountRial),
      discountPercentBp: discountPercentBp,
      taxRateBp: taxRateBp,
    );
  }

  InvoiceEditorState editor({
    required List<InvoiceLineEntry> lines,
    int discountRial = 0,
    int? discountPercentBp,
    int? taxRateBp,
  }) {
    return InvoiceEditorState(
      settings: settings,
      issueDate: DateTime.utc(2026, 8, 24, 12),
      customerId: customerId,
      lines: lines,
      discount: Money.rial(discountRial),
      discountPercentBp: discountPercentBp,
      taxRateBp: taxRateBp,
    );
  }

  /// Writes [state] and asserts the stored invoice matches its preview, figure
  /// for figure, down to each line.
  Future<InvoiceDetail> expectPreviewSurvivesTheWrite(
    InvoiceEditorState state,
  ) async {
    final CalculatedInvoice preview = state.totals;
    final InvoiceCreationResult result = await harness.invoices.create(
      state.toDraft(),
    );

    final Invoice stored = result.invoice;
    expect(stored.subtotal, preview.subtotal, reason: 'subtotal');
    expect(
      stored.totalDiscount,
      preview.totalDiscount,
      reason: 'totalDiscount -- the figure a document prints (D-027)',
    );
    expect(stored.totalTax, preview.totalTax, reason: 'totalTax');
    expect(
      stored.roundingAdjustment,
      preview.roundingAdjustment,
      reason: 'roundingAdjustment',
    );
    expect(
      stored.grandTotal,
      preview.grandTotal,
      reason: 'grandTotal -- the number the user agreed to',
    );
    expect(stored.discount, preview.invoiceDiscount);

    // The warnings the write reports are the ones the preview showed, so a
    // clamp the user was asked about is not re-raised as news afterwards, and
    // one they were never shown does not appear for the first time on save.
    expect(result.warnings.length, preview.warnings.length);
    for (int i = 0; i < result.warnings.length; i++) {
      expect(result.warnings[i].kind, preview.warnings[i].kind);
      expect(result.warnings[i].lineIndex, preview.warnings[i].lineIndex);
      expect(result.warnings[i].requested, preview.warnings[i].requested);
      expect(result.warnings[i].applied, preview.warnings[i].applied);
    }

    final InvoiceDetail? detail = await harness.invoices.findDetail(stored.id);
    expect(detail, isNotNull);
    expect(detail!.items, hasLength(preview.lines.length));

    for (int i = 0; i < preview.lines.length; i++) {
      final CalculatedLine expected = preview.lines[i];
      final InvoiceItem actual = detail.items[i];
      expect(actual.position, i, reason: 'line $i position');
      expect(
        actual.discount,
        expected.discount,
        reason: 'line $i discount must be the effective one (D-027)',
      );
      expect(
        actual.resolvedTaxRateBp,
        expected.resolvedTaxRateBp,
        reason: 'line $i resolved tax rate, snapshotted (§4 step 6)',
      );
      expect(
        actual.lineNet,
        expected.netAfterInvoiceDiscount,
        reason: 'line $i net after the allocated invoice discount',
      );
      expect(actual.lineTax, expected.tax, reason: 'line $i tax');
      expect(actual.lineTotal, expected.total, reason: 'line $i total');
    }

    return detail;
  }

  test('a plain invoice stores exactly what the preview showed', () async {
    await expectPreviewSurvivesTheWrite(
      editor(
        lines: <InvoiceLineEntry>[
          line(priceRial: 1000000, quantityMilli: 2500),
          line(priceRial: 400000),
        ],
      ),
    );
  });

  test('line and invoice discounts survive the allocation', () async {
    // The allocation is where the preview and the write could most plausibly
    // diverge: it is the one step whose result depends on every other line.
    await expectPreviewSurvivesTheWrite(
      editor(
        lines: <InvoiceLineEntry>[
          line(priceRial: 1000000, quantityMilli: 2000, discountRial: 300000),
          line(priceRial: 500000, discountRial: 50000),
          line(priceRial: 7, quantityMilli: 1),
        ],
        discountRial: 100000,
      ),
    );
  });

  test('an allocation with an inexact remainder still matches', () async {
    // 100 Rial across three equal lines is 33.33 each; naive rounding loses a
    // Rial and the invoice stops reconciling. Both callers must lose or keep
    // the same Rial, in the same place.
    final InvoiceDetail detail = await expectPreviewSurvivesTheWrite(
      editor(
        lines: <InvoiceLineEntry>[
          line(priceRial: 1000),
          line(priceRial: 1000),
          line(priceRial: 1000),
        ],
        discountRial: 100,
      ),
    );

    final int allocated = detail.items.fold<int>(
      0,
      (int sum, InvoiceItem i) => sum + (i.lineNet.rial),
    );
    // 3,000 gross − 100 discount = 2,900 across the three lines, exactly.
    expect(allocated, 2900);
  });

  test('mixed per-line tax rates are snapshotted as resolved', () async {
    final InvoiceDetail detail = await expectPreviewSurvivesTheWrite(
      editor(
        lines: <InvoiceLineEntry>[
          line(taxRateBp: 0), // exempt, and 0 is a rate (D-026)
          line(taxRateBp: 500),
          line(), // inherits the invoice rate below
        ],
        taxRateBp: 700,
      ),
    );

    expect(
      detail.items.map((InvoiceItem i) => i.resolvedTaxRateBp).toList(),
      <int>[0, 500, 700],
    );
  });

  test(
    'a fractional quantity round-trips through the integer column',
    () async {
      final InvoiceDetail detail = await expectPreviewSurvivesTheWrite(
        editor(
          lines: <InvoiceLineEntry>[
            line(priceRial: 333333, quantityMilli: 1500),
            line(priceRial: 250000, quantityMilli: 1),
          ],
        ),
      );

      expect(
        detail.items.map((InvoiceItem i) => i.quantityMilli).toList(),
        <int>[1500, 1],
      );
    },
  );

  test(
    'a clamped discount is stored at what was given, and warned about once',
    () async {
      final InvoiceEditorState state = editor(
        lines: <InvoiceLineEntry>[
          line(priceRial: 1000000, discountRial: 1500000),
        ],
      );
      expect(state.hasWarnings, isTrue);

      final InvoiceDetail detail = await expectPreviewSurvivesTheWrite(state);
      // The effective amount, not the entered one: a total discount of 150
      // against a line that only ever gave 100 is a figure the customer finds
      // before we do (D-027).
      expect(detail.items.single.discount, Money.rial(1000000));
      expect(detail.invoice.totalDiscount, Money.rial(1000000));
    },
  );

  test(
    'rounding configured in settings applies to both, identically',
    () async {
      await harness.settings.write(settings.copyWith(roundingUnitRial: 1000));
      settings = await harness.settings.read();

      final InvoiceDetail detail = await expectPreviewSurvivesTheWrite(
        editor(
          lines: <InvoiceLineEntry>[
            line(priceRial: 333333, quantityMilli: 3000, discountRial: 1234),
          ],
          discountRial: 777,
        ),
      );

      expect(detail.invoice.roundingAdjustment, isNot(Money.zero));
      // And the stored invoice still reconciles the way the summary printed it.
      expect(
        detail.invoice.subtotal.rial -
            detail.invoice.discount.rial +
            detail.invoice.totalTax.rial +
            detail.invoice.roundingAdjustment.rial,
        detail.invoice.grandTotal.rial,
      );
    },
  );

  test(
    'the title and price stored are the snapshot, not the product',
    () async {
      // D-004, from the editor's side: the entry carries its own copies, so a
      // later price change cannot reach an invoice already written.
      final Product product = await harness.product(
        name: 'کالای اصلی',
        priceRial: 900000,
      );
      final InvoiceEditorState state = InvoiceEditorState(
        settings: settings,
        issueDate: DateTime.utc(2026, 8, 24, 12),
        customerId: customerId,
        lines: <InvoiceLineEntry>[
          InvoiceLineEntry(
            title: 'کالای اصلی',
            unit: 'عدد',
            unitPrice: Money.rial(900000),
            quantityMilli: 1000,
            productId: product.id,
          ),
        ],
      );

      final InvoiceDetail detail = await expectPreviewSurvivesTheWrite(state);
      expect(detail.items.single.unitPrice, Money.rial(900000));
      expect(detail.items.single.productId, product.id);

      await harness.products.update(
        product.id,
        ProductDraft.from(product).copyWithPrice(Money.rial(5000000)),
      );

      final InvoiceDetail? after = await harness.invoices.findDetail(
        detail.invoice.id,
      );
      expect(after!.items.single.unitPrice, Money.rial(900000));
      expect(after.invoice.grandTotal, detail.invoice.grandTotal);
    },
  );
}

extension on ProductDraft {
  /// A price change, expressed without restating the rest of the product.
  ProductDraft copyWithPrice(Money price) => ProductDraft(
    name: name,
    type: type,
    price: price,
    unit: unit,
    description: description,
  );
}
