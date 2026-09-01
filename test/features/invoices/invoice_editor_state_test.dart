import 'package:factorino/core/money/invoice_calculator.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/models/invoice_draft.dart';
import 'package:factorino/features/invoices/domain/invoice_editor_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/money_magnitudes.dart';

/// The invoice editor's state model, and its wiring to `core/money/`.
///
/// The claim under test throughout is that **the state computes nothing**: it
/// holds what the user entered and exposes what the engine made of it. Where a
/// figure is asserted here, the expected value is worked out in the comment the
/// way a user would work it out on paper, so a change to the engine that broke
/// the arithmetic would fail here with the reasoning visible beside it.
void main() {
  const AppSettings settings = AppSettings(
    defaultTaxRateBp: 900,
    roundingUnitRial: 0,
    invoiceNumberPrefix: 'INV',
  );

  final DateTime issueDate = DateTime.utc(2026, 8, 24, 12);

  InvoiceLineEntry line({
    String title = 'خدمات',
    String unit = 'عدد',
    int priceRial = 1000000,
    int quantityMilli = 1000,
    int discountRial = 0,
    int? discountPercentBp,
    int? taxRateBp,
    String? productId,
  }) {
    return InvoiceLineEntry(
      title: title,
      unit: unit,
      unitPrice: Money.rial(priceRial),
      quantityMilli: quantityMilli,
      discount: Money.rial(discountRial),
      discountPercentBp: discountPercentBp,
      taxRateBp: taxRateBp,
      productId: productId,
    );
  }

  InvoiceEditorState stateWith({
    List<InvoiceLineEntry> lines = const <InvoiceLineEntry>[],
    String? customerId = 'c1',
    int discountRial = 0,
    int? discountPercentBp,
    int? taxRateBp,
    AppSettings appSettings = settings,
  }) {
    return InvoiceEditorState(
      settings: appSettings,
      issueDate: issueDate,
      customerId: customerId,
      lines: lines,
      discount: Money.rial(discountRial),
      discountPercentBp: discountPercentBp,
      taxRateBp: taxRateBp,
    );
  }

  group('the engine is the authority', () {
    test('an empty invoice totals zero rather than failing', () {
      // The state a form opens in. It must be computable: a screen cannot have
      // a loading state for arithmetic over nothing.
      final InvoiceEditorState state = stateWith(customerId: null);

      expect(state.totals.grossTotal, Money.zero);
      expect(state.totals.subtotal, Money.zero);
      expect(state.totals.grandTotal, Money.zero);
      expect(state.warnings, isEmpty);
      expect(state.isComplete, isFalse);
    });

    test('totals come from the engine, line by line', () {
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[
          line(priceRial: 1000000, quantityMilli: 2500), // 2,500,000
          line(priceRial: 400000, quantityMilli: 1000), //    400,000
        ],
      );

      // Gross 2,900,000; no discounts; tax at the settings default of 9% is
      // 261,000; total 3,161,000.
      expect(state.totals.grossTotal, Money.rial(2900000));
      expect(state.totals.subtotal, Money.rial(2900000));
      expect(state.totals.totalTax, Money.rial(261000));
      expect(state.totals.grandTotal, Money.rial(3161000));
      expect(state.totals.lines, hasLength(2));
    });

    test('a fractional quantity never becomes a double', () {
      // 1.5 kg at 333,333 Rial. Half-up at the Rial: 499,999.5 -> 500,000.
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[line(priceRial: 333333, quantityMilli: 1500)],
        taxRateBp: 0,
      );

      expect(state.totals.lines.single.gross, Money.rial(500000));
      expect(state.totals.grandTotal, Money.rial(500000));
    });

    test('recomputed on every edit, never carried across one', () {
      final InvoiceEditorState before = stateWith(
        lines: <InvoiceLineEntry>[line(priceRial: 1000000)],
        taxRateBp: 0,
      );
      expect(before.totals.grandTotal, Money.rial(1000000));

      final InvoiceEditorState after = before.copyWith(
        lines: <InvoiceLineEntry>[...before.lines, line(priceRial: 500000)],
      );

      expect(after.totals.grandTotal, Money.rial(1500000));
      // The old state is untouched -- immutability is what makes a stale total
      // impossible rather than merely unlikely.
      expect(before.totals.grandTotal, Money.rial(1000000));
    });
  });

  group('the summary reconciles by hand', () {
    test('gross less discount plus tax is the total, exactly', () {
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[
          line(priceRial: 1000000, quantityMilli: 2000, discountRial: 300000),
          line(priceRial: 500000, quantityMilli: 1000, discountRial: 50000),
        ],
        discountRial: 100000,
      );

      final CalculatedInvoice t = state.totals;
      // 2,500,000 gross − 450,000 discount = 2,050,000; 9% tax = 184,500;
      // total 2,234,500. Every figure below is one a document would print.
      expect(t.grossTotal, Money.rial(2500000));
      expect(t.totalDiscount, Money.rial(450000));
      expect(t.totalTax, Money.rial(184500));
      expect(t.grandTotal, Money.rial(2234500));
      expect(
        t.grossTotal.rial - t.totalDiscount.rial + t.totalTax.rial,
        t.grandTotal.rial,
      );
    });

    test('it still reconciles when settings round the total', () {
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[
          line(priceRial: 333333, quantityMilli: 3000, discountRial: 1234),
        ],
        appSettings: const AppSettings(
          defaultTaxRateBp: 900,
          roundingUnitRial: 1000,
          invoiceNumberPrefix: 'INV',
        ),
      );

      final CalculatedInvoice t = state.totals;
      expect(t.roundingAdjustment, isNot(Money.zero));
      expect(
        t.grossTotal.rial -
            t.totalDiscount.rial +
            t.totalTax.rial +
            t.roundingAdjustment.rial,
        t.grandTotal.rial,
      );
    });
  });

  group('tax rate resolution (§4 step 6, D-026)', () {
    test('item beats invoice beats the settings default', () {
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[
          line(taxRateBp: 500), // item override
          line(), // inherits
        ],
        taxRateBp: 700, // invoice override
      );

      expect(state.totals.lines[0].resolvedTaxRateBp, 500);
      expect(state.totals.lines[1].resolvedTaxRateBp, 700);
    });

    test('with no overrides every line takes the settings default', () {
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[line(), line()],
      );

      expect(state.totals.lines[0].resolvedTaxRateBp, 900);
      expect(state.totals.lines[1].resolvedTaxRateBp, 900);
    });

    test('a zero rate is a rate, not an absence', () {
      // D-026. Treating 0 as "unset" would apply the default VAT rate to a
      // line the user deliberately marked exempt -- a wrong total on a tax
      // document that looks correct to everyone except the tax authority.
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[line(taxRateBp: 0), line()],
      );

      expect(state.totals.lines[0].resolvedTaxRateBp, 0);
      expect(state.totals.lines[0].tax, Money.zero);
      expect(state.totals.lines[1].resolvedTaxRateBp, 900);
    });

    test('a zero invoice rate is a rate too, and beats the default', () {
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[line()],
        taxRateBp: 0,
      );

      expect(state.totals.lines.single.resolvedTaxRateBp, 0);
      expect(state.totals.totalTax, Money.zero);
    });

    test('clearing an override falls back rather than setting zero', () {
      // The trap copyWith's `clear` flags exist for: without them a caller
      // could set a rate but never unset it, and "inherit" would be
      // unreachable once anything had been chosen.
      final InvoiceLineEntry overridden = line(taxRateBp: 0);
      expect(overridden.taxRateBp, 0);

      final InvoiceLineEntry inherited = overridden.copyWith(
        clearTaxRate: true,
      );
      expect(inherited.taxRateBp, isNull);

      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[inherited],
      );
      expect(state.totals.lines.single.resolvedTaxRateBp, 900);
    });
  });

  group('warnings surface, with both figures (D-027)', () {
    test('a line discount larger than its line is reported, not absorbed', () {
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[
          line(priceRial: 1000000, quantityMilli: 1000, discountRial: 1500000),
        ],
        taxRateBp: 0,
      );

      expect(state.hasWarnings, isTrue);
      final InvoiceWarning warning = state.warnings.single;
      expect(warning.kind, InvoiceWarningKind.lineDiscountClamped);
      expect(warning.lineIndex, 0);
      // Both figures, so the UI can state the difference exactly rather than
      // saying "some discount was ignored".
      expect(warning.requested, Money.rial(1500000));
      expect(warning.applied, Money.rial(1000000));
      expect(warning.absorbed, Money.rial(500000));

      // ...and the invoice is still computed and still usable. A warning is an
      // observation about the input, never a failure.
      expect(state.totals.grandTotal, Money.zero);
      expect(state.isComplete, isTrue);
    });

    test('an invoice discount larger than the subtotal is reported', () {
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[line(priceRial: 1000000)],
        discountRial: 5000000,
        taxRateBp: 0,
      );

      final InvoiceWarning warning = state.warnings.single;
      expect(warning.kind, InvoiceWarningKind.invoiceDiscountClamped);
      expect(warning.lineIndex, isNull);
      expect(warning.requested, Money.rial(5000000));
      expect(warning.applied, Money.rial(1000000));
      // Never negative: this clamp is part of the reconciliation invariant.
      expect(state.totals.grandTotal, Money.zero);
    });

    test('warnings arrive in document order, invoice level last', () {
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[
          line(priceRial: 1000000, discountRial: 9000000),
          line(priceRial: 1000000, discountRial: 9000000),
        ],
        discountRial: 9000000,
      );

      expect(state.warnings, hasLength(3));
      expect(state.warnings[0].lineIndex, 0);
      expect(state.warnings[1].lineIndex, 1);
      expect(state.warnings[2].lineIndex, isNull);
    });

    test('a clean invoice reports nothing', () {
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[line(discountRial: 1000)],
        discountRial: 1000,
      );
      expect(state.hasWarnings, isFalse);
    });

    test('a percentage discount can never trip the line clamp', () {
      // Rates are validated at 0-10000 bp, so a resolved percentage is at most
      // the gross. Only an absolute entry can overshoot -- worth pinning,
      // because it is why the percentage path needs no warning of its own.
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[line(discountPercentBp: 10000)],
      );

      expect(state.hasWarnings, isFalse);
      expect(state.totals.subtotal, Money.zero);
    });
  });

  group('a large invoice can be typed at all (D-059, known issue 19)', () {
    // **This is where the defect was actually met, and why it is tested here as
    // well as in the engine.** `InvoiceEditorState`'s constructor runs
    // `calculateInvoice`, so step 4's overflow landed on the **preview** rather
    // than on the save: `InvoiceEditor.build` threw as the user typed and the
    // screen rendered `AsyncErrorView` in place of the form they were filling
    // in. An invoice of 30,000,000 تومان with a 10% discount could not be
    // entered.
    //
    // The failure mode was the right one — the guard refused rather than
    // truncating, so no wrong total ever reached a document — which is why the
    // fix removes the intermediate and leaves the guard alone.

    for (final int toman in kMoneyStressToman) {
      test('$toman toman with a 10% discount previews without throwing', () {
        final int totalRial = toman * 10;

        final InvoiceEditorState state = stateWith(
          lines: <InvoiceLineEntry>[
            line(priceRial: totalRial ~/ 3),
            line(priceRial: totalRial - totalRial ~/ 3),
          ],
          discountPercentBp: 1000,
        );

        // The preview exists, which is the whole assertion: constructing the
        // state is what used to throw.
        expect(state.totals.lines, hasLength(2));
        expect(state.totals.grandTotal.rial, greaterThan(0));

        // And it is right, not merely present.
        expect(
          state.totals.grossTotal.rial -
              state.totals.totalDiscount.rial +
              state.totals.totalTax.rial +
              state.totals.roundingAdjustment.rial,
          state.totals.grandTotal.rial,
        );
        expect(
          state.totals.lines
              .map((CalculatedLine line) => line.allocatedInvoiceDiscount.rial)
              .reduce((int a, int b) => a + b),
          state.totals.invoiceDiscount.rial,
        );
      });
    }
  });

  group('completeness', () {
    test('needs a customer', () {
      expect(
        stateWith(
          customerId: null,
          lines: <InvoiceLineEntry>[line()],
        ).isComplete,
        isFalse,
      );
    });

    test('needs at least one line', () {
      expect(stateWith().isComplete, isFalse);
    });

    test('needs every line named and united', () {
      expect(
        stateWith(lines: <InvoiceLineEntry>[line(title: '  ')]).isComplete,
        isFalse,
      );
      expect(
        stateWith(lines: <InvoiceLineEntry>[line(unit: '')]).isComplete,
        isFalse,
      );
    });

    test('a zero-quantity line does not block it', () {
      // §4 handles zero quantity and the engine has a test for it. A line
      // entered at zero pending a count is a real thing a user does, and
      // refusing to save the invoice over it would be the app inventing a rule.
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[line(quantityMilli: 0)],
      );
      expect(state.isComplete, isTrue);
      expect(state.totals.grandTotal, Money.zero);
    });

    test('toDraft refuses rather than inventing a customer', () {
      expect(
        () => stateWith(
          customerId: null,
          lines: <InvoiceLineEntry>[line()],
        ).toDraft(),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('toDraft carries choices, never computed figures', () {
    test('it hands over the entries and the snapshots', () {
      final InvoiceEditorState state = InvoiceEditorState(
        settings: settings,
        issueDate: issueDate,
        customerId: 'c1',
        dueDate: DateTime.utc(2026, 9, 24),
        lines: <InvoiceLineEntry>[
          line(
            title: '  مشاوره  ',
            unit: ' ساعت ',
            priceRial: 2000000,
            quantityMilli: 1500,
            productId: 'p1',
            taxRateBp: 0,
          ),
        ],
        discount: Money.rial(50000),
        notes: '  یادداشت  ',
      );

      final InvoiceDraft draft = state.toDraft();
      expect(draft.customerId, 'c1');
      expect(draft.issueDate, issueDate);
      expect(draft.dueDate, DateTime.utc(2026, 9, 24));
      expect(draft.discount, Money.rial(50000));
      expect(draft.notes, 'یادداشت');
      expect(draft.items, hasLength(1));

      final InvoiceItemDraft item = draft.items.single;
      // Trimmed, because the trimmed form is what the document prints.
      expect(item.title, 'مشاوره');
      expect(item.unit, 'ساعت');
      // The snapshot, carried explicitly even though productId is set (D-004).
      expect(item.unitPrice, Money.rial(2000000));
      expect(item.quantityMilli, 1500);
      expect(item.productId, 'p1');
      expect(item.taxRateBp, 0);
    });

    test('an empty note becomes null rather than an empty string', () {
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[line()],
      ).copyWith(notes: '   ');
      expect(state.toDraft().notes, isNull);
    });

    test('lines keep the order they were arranged in', () {
      final InvoiceEditorState state = stateWith(
        lines: <InvoiceLineEntry>[
          line(title: 'اول'),
          line(title: 'دوم'),
          line(title: 'سوم'),
        ],
      );

      expect(
        state.toDraft().items.map((InvoiceItemDraft i) => i.title).toList(),
        <String>['اول', 'دوم', 'سوم'],
      );
    });
  });

  group('settings are the last step of the chain, and they are live', () {
    test('changing the default rate re-resolves the inheriting lines', () {
      final InvoiceEditorState before = stateWith(
        lines: <InvoiceLineEntry>[line(taxRateBp: 500), line()],
      );
      expect(before.totals.lines[1].resolvedTaxRateBp, 900);

      final InvoiceEditorState after = before.copyWith(
        settings: settings.copyWith(defaultTaxRateBp: 1000),
      );

      // The overridden line is untouched; the inheriting one follows.
      expect(after.totals.lines[0].resolvedTaxRateBp, 500);
      expect(after.totals.lines[1].resolvedTaxRateBp, 1000);
    });

    test('changing the rounding unit re-rounds the total', () {
      final InvoiceEditorState before = stateWith(
        lines: <InvoiceLineEntry>[line(priceRial: 333333, quantityMilli: 3000)],
      );
      expect(before.roundingIsOff, isTrue);

      final InvoiceEditorState after = before.copyWith(
        settings: settings.copyWith(roundingUnitRial: 1000),
      );
      expect(after.totals.roundingAdjustment, isNot(Money.zero));
    });
  });
}

extension on InvoiceEditorState {
  /// Readability helper for the assertion above; rounding disabled means the
  /// engine reports no adjustment.
  bool get roundingIsOff => totals.roundingAdjustment == Money.zero;
}
