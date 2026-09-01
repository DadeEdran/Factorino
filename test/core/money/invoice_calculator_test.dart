import 'package:factorino/core/money/invoice_calculator.dart';
import 'package:factorino/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/money_magnitudes.dart';

/// the project spec, case by case. A wrong total here is the product-killing bug,
/// so these tests are the specification rather than a sample of it.
void main() {
  InvoiceLineInput line({
    int priceRial = 1000000,
    int quantityMilli = 1000,
    int discountRial = 0,
    int? discountPercentBp,
    int? taxRateBp,
  }) {
    return InvoiceLineInput(
      unitPrice: Money.rial(priceRial),
      quantityMilli: quantityMilli,
      discount: Money.rial(discountRial),
      discountPercentBp: discountPercentBp,
      taxRateBp: taxRateBp,
    );
  }

  CalculatedInvoice calculate(
    List<InvoiceLineInput> lines, {
    int discountRial = 0,
    int? discountPercentBp,
    int? taxRateBp,
    int defaultTaxRateBp = 1000,
    int roundingUnitRial = 0,
  }) {
    return calculateInvoice(
      InvoiceInput(
        lines: lines,
        defaultTaxRateBp: defaultTaxRateBp,
        discount: Money.rial(discountRial),
        discountPercentBp: discountPercentBp,
        taxRateBp: taxRateBp,
        roundingUnitRial: roundingUnitRial,
      ),
    );
  }

  /// The §4 invariant, checked as a test rather than trusted as a comment.
  void expectReconciles(CalculatedInvoice invoice) {
    expect(
      invoice.grandTotal.rial - invoice.roundingAdjustment.rial,
      invoice.subtotal.rial -
          invoice.invoiceDiscount.rial +
          invoice.totalTax.rial,
      reason: 'grandTotal != subtotal - invoiceDiscount + totalTax',
    );

    // Step 11 states the same total a second way; both must agree.
    final sumOfLines = invoice.lines.fold<int>(0, (s, l) => s + l.total.rial);
    expect(
      sumOfLines,
      invoice.grandTotal.rial - invoice.roundingAdjustment.rial,
      reason: 'the lines do not sum to the grand total',
    );

    // The allocation must be exact, which is what makes the above hold.
    final allocated = invoice.lines.fold<int>(
      0,
      (s, l) => s + l.allocatedInvoiceDiscount.rial,
    );
    expect(allocated, invoice.invoiceDiscount.rial);

    // The *printed summary* must add up too, which is a different claim from
    // the one above and the only one a customer actually checks: gross, less
    // the discount actually given, plus tax, plus any rounding.
    //
    // Starting from `subtotal` here instead would pass while the document
    // failed, because subtotal is already net of the line discounts -- anyone
    // reconciling with a pencil would subtract them twice.
    expect(
      invoice.grossTotal.rial -
          invoice.totalDiscount.rial +
          invoice.totalTax.rial +
          invoice.roundingAdjustment.rial,
      invoice.grandTotal.rial,
      reason:
          'grossTotal - totalDiscount + totalTax + rounding != grandTotal; '
          'the summary a document prints would not reconcile by hand',
    );

    // ...and the gross is the gross: the sum of the lines before anything.
    final sumOfGross = invoice.lines.fold<int>(0, (s, l) => s + l.gross.rial);
    expect(sumOfGross, invoice.grossTotal.rial);
  }

  group('step 1 - line gross', () {
    test('multiplies price by quantity in milli-units', () {
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000, quantityMilli: 1000), // 1 unit
      ]);
      expect(invoice.lines.single.gross, Money.rial(1000000));
    });

    test('handles a fractional quantity exactly', () {
      // 1.5 kg at 1,000,000 Rial = 1,500,000 Rial, with no floating point.
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000, quantityMilli: 1500),
      ]);
      expect(invoice.lines.single.gross, Money.rial(1500000));
    });

    test('rounds a fractional Rial half-up', () {
      // 0.333 x 1001 = 333.333 Rial -> 333
      expect(
        calculate(<InvoiceLineInput>[line(priceRial: 1001, quantityMilli: 333)])
.lines
.single
.gross,
        Money.rial(333),
      );
      // 5 x 0.5 = 2.5 Rial -> 3, not 2
      expect(
        calculate(<InvoiceLineInput>[line(priceRial: 5, quantityMilli: 500)])
.lines
.single
.gross,
        Money.rial(3),
      );
    });

    test('a zero quantity produces a zero line, not an error', () {
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000, quantityMilli: 0),
        line(priceRial: 2000000, quantityMilli: 1000),
      ]);

      expect(invoice.lines.first.gross, Money.zero);
      expect(invoice.lines.first.net, Money.zero);
      expect(invoice.lines.first.tax, Money.zero);
      expect(invoice.lines.first.total, Money.zero);
      expect(invoice.subtotal, Money.rial(2000000));
      expectReconciles(invoice);
    });

    test('an invoice with no lines totals zero', () {
      final invoice = calculate(<InvoiceLineInput>[]);
      expect(invoice.subtotal, Money.zero);
      expect(invoice.grandTotal, Money.zero);
      expectReconciles(invoice);
    });
  });

  group('steps 2-3 - line discount', () {
    test('subtracts an absolute discount', () {
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000, discountRial: 250000),
      ]);
      expect(invoice.lines.single.net, Money.rial(750000));
    });

    test('resolves a percentage to an amount and keeps both', () {
      // §4 step 2: store the entered percentage and the resolved amount.
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000, discountPercentBp: 1500), // 15%
      ]);

      expect(invoice.lines.single.discount, Money.rial(150000));
      expect(invoice.lines.single.discountPercentBp, 1500);
      expect(invoice.lines.single.net, Money.rial(850000));
    });

    test('clamps the line net at zero when the discount exceeds the line', () {
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000, discountRial: 1500000),
      ]);

      expect(invoice.lines.single.net, Money.zero);
      expect(invoice.lines.single.total, Money.zero);
      expectReconciles(invoice);
    });

    // D-027, the owner's correction to §4 step 9. This is the case the whole
    // entry is about: a line worth 1,000,000 with 1,500,000 entered against it
    // gives away 1,000,000, and that is the only figure a customer could ever
    // reconcile the document to by hand.
    test('reports the effective line discount, not the amount entered', () {
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000, discountRial: 1500000),
      ]);

      expect(invoice.totalDiscount, Money.rial(1000000));
      expect(invoice.lines.single.discount, Money.rial(1000000));
      expect(invoice.lines.single.discountRequested, Money.rial(1500000));
      expect(invoice.lines.single.discountWasClamped, isTrue);
    });

    test(
      'sums effective discounts across a mix of clamped and normal lines',
      () {
        final invoice = calculate(<InvoiceLineInput>[
          line(priceRial: 1000000, discountRial: 1500000), // gives 1,000,000
          line(priceRial: 2000000, discountRial: 300000), // gives   300,000
          line(priceRial: 500000), // gives         0
        ]);

        expect(invoice.totalDiscount, Money.rial(1300000));
        expect(invoice.lines[0].discountWasClamped, isTrue);
        expect(invoice.lines[1].discountWasClamped, isFalse);
        expect(invoice.lines[2].discountWasClamped, isFalse);
        expectReconciles(invoice);
      },
    );

    test('surfaces a clamped line discount as a warning', () {
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 800000),
        line(priceRial: 1000000, discountRial: 1500000),
      ]);

      expect(invoice.hasWarnings, isTrue);
      final warning = invoice.warnings.single;
      expect(warning.kind, InvoiceWarningKind.lineDiscountClamped);
      expect(warning.lineIndex, 1);
      expect(warning.requested, Money.rial(1500000));
      expect(warning.applied, Money.rial(1000000));
      expect(warning.absorbed, Money.rial(500000));
    });

    test('a clean invoice carries no warnings', () {
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000, discountRial: 100000),
      ], discountRial: 50000);

      expect(invoice.warnings, isEmpty);
      expect(invoice.hasWarnings, isFalse);
      expect(invoice.lines.single.discountWasClamped, isFalse);
    });

    test('a percentage discount can never be clamped', () {
      // Rates are validated at 0-10000 bp, so the resolved amount is at most
      // the gross. Only an absolute entry can overshoot a line.
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000, discountPercentBp: 10000),
      ]);

      expect(invoice.lines.single.discount, Money.rial(1000000));
      expect(invoice.lines.single.discountWasClamped, isFalse);
      expect(invoice.warnings, isEmpty);
      expect(invoice.totalDiscount, Money.rial(1000000));
    });
  });

  group('step 4 - invoice discount allocation', () {
    test('allocates proportionally by line net', () {
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000), // net 1,000,000
        line(priceRial: 3000000), // net 3,000,000
      ], discountRial: 400000);

      expect(invoice.lines[0].allocatedInvoiceDiscount, Money.rial(100000));
      expect(invoice.lines[1].allocatedInvoiceDiscount, Money.rial(300000));
      expectReconciles(invoice);
    });

    test('distributes remainders so nothing is lost', () {
      // 100 Rial across three equal lines: 33.33 each.
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000),
        line(priceRial: 1000),
        line(priceRial: 1000),
      ], discountRial: 100);

      expect(invoice.lines.map((l) => l.allocatedInvoiceDiscount.rial), <int>[
        34,
        33,
        33,
      ]);
      expectReconciles(invoice);
    });

    test('reconciles across many awkward discount amounts', () {
      for (var discount = 0; discount <= 300; discount++) {
        final invoice = calculate(<InvoiceLineInput>[
          line(priceRial: 333),
          line(priceRial: 777),
          line(priceRial: 1111),
        ], discountRial: discount);
        expectReconciles(invoice);
      }
    });

    test('resolves an invoice percentage against the subtotal', () {
      final invoice = calculate(
        <InvoiceLineInput>[line(priceRial: 2000000)],
        discountPercentBp: 500, // 5%
      );

      expect(invoice.invoiceDiscount, Money.rial(100000));
      expect(invoice.invoiceDiscountPercentBp, 500);
      expectReconciles(invoice);
    });

    test('clamps an invoice discount larger than the subtotal', () {
      // Unlike a line discount, this one is part of the invariant, so letting
      // it run past the subtotal would produce a negative grand total.
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000),
      ], discountRial: 5000000);

      expect(invoice.invoiceDiscount, Money.rial(1000000));
      expect(invoice.grandTotal, Money.zero);
      expectReconciles(invoice);
    });

    test('surfaces a clamped invoice discount, and reports it effectively', () {
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000),
      ], discountRial: 5000000);

      // Same D-027 treatment as a line: reported at what was given.
      expect(invoice.totalDiscount, Money.rial(1000000));
      expect(invoice.invoiceDiscountRequested, Money.rial(5000000));

      final warning = invoice.warnings.single;
      expect(warning.kind, InvoiceWarningKind.invoiceDiscountClamped);
      expect(warning.lineIndex, isNull);
      expect(warning.requested, Money.rial(5000000));
      expect(warning.applied, Money.rial(1000000));
    });

    test('reports both clamps when a line and the invoice overshoot', () {
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000, discountRial: 1500000), // line net 0
        line(priceRial: 400000), // line net 400,000
      ], discountRial: 900000); // subtotal is only 400,000

      expect(invoice.warnings.map((w) => w.kind), <InvoiceWarningKind>[
        InvoiceWarningKind.lineDiscountClamped,
        InvoiceWarningKind.invoiceDiscountClamped,
      ], reason: 'line warnings come first, invoice-level last');
      // 1,000,000 given on the line + 400,000 given on the invoice.
      expect(invoice.totalDiscount, Money.rial(1400000));
      expect(invoice.grandTotal, Money.zero);
      expectReconciles(invoice);
    });

    test('ignores an invoice discount when every line is worth zero', () {
      final invoice = calculate(<InvoiceLineInput>[
        line(quantityMilli: 0),
      ], discountRial: 50000);

      expect(invoice.subtotal, Money.zero);
      expect(invoice.invoiceDiscount, Money.zero);
      expect(invoice.grandTotal, Money.zero);
      expectReconciles(invoice);
    });
  });

  group('step 6 - tax rate resolution', () {
    test('prefers the item rate, then the invoice rate, then the default', () {
      final invoice = calculate(
        <InvoiceLineInput>[
          line(taxRateBp: 500), // item wins
          line(), // falls through to the invoice rate
        ],
        taxRateBp: 800,
        defaultTaxRateBp: 1000,
      );

      expect(invoice.lines[0].resolvedTaxRateBp, 500);
      expect(invoice.lines[1].resolvedTaxRateBp, 800);
    });

    test('falls through to the settings default when nothing overrides', () {
      final invoice = calculate(<InvoiceLineInput>[
        line(),
      ], defaultTaxRateBp: 900);
      expect(invoice.lines.single.resolvedTaxRateBp, 900);
    });

    test('treats a zero item rate as a real rate, not as absent', () {
      // A tax-exempt line is `0`, not null. Falling through to the default
      // here would tax something the user marked exempt.
      final invoice = calculate(<InvoiceLineInput>[
        line(taxRateBp: 0),
      ], defaultTaxRateBp: 1000);

      expect(invoice.lines.single.resolvedTaxRateBp, 0);
      expect(invoice.lines.single.tax, Money.zero);
    });

    test('computes mixed rates per line and sums them', () {
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000, taxRateBp: 1000), // 100,000
        line(priceRial: 1000000, taxRateBp: 500), // 50,000
        line(priceRial: 1000000, taxRateBp: 0), // 0
      ], defaultTaxRateBp: 900);

      expect(invoice.lines.map((l) => l.tax.rial), <int>[100000, 50000, 0]);
      expect(invoice.totalTax, Money.rial(150000));
      expectReconciles(invoice);
    });

    test('taxes the net after the invoice discount, not before', () {
      final invoice = calculate(
        <InvoiceLineInput>[line(priceRial: 1000000)],
        discountRial: 200000,
        defaultTaxRateBp: 1000,
      );

      // 10% of 800,000, not of 1,000,000.
      expect(invoice.lines.single.tax, Money.rial(80000));
      expect(invoice.grandTotal, Money.rial(880000));
      expectReconciles(invoice);
    });
  });

  group('steps 8-11 - totals', () {
    test('reports every §4 figure for a mixed invoice', () {
      final invoice = calculate(
        <InvoiceLineInput>[
          line(priceRial: 1000000, quantityMilli: 2000, discountRial: 100000),
          line(priceRial: 500000, quantityMilli: 1500, taxRateBp: 500),
        ],
        discountRial: 150000,
        defaultTaxRateBp: 1000,
      );

      // Line 1: gross 2,000,000, discount 100,000, net 1,900,000
      // Line 2: gross   750,000, discount       0, net   750,000
      expect(invoice.lines[0].net, Money.rial(1900000));
      expect(invoice.lines[1].net, Money.rial(750000));
      expect(invoice.subtotal, Money.rial(2650000));

      // 150,000 allocated by net: 1,900,000 : 750,000
      final allocated = invoice.lines.fold<int>(
        0,
        (s, l) => s + l.allocatedInvoiceDiscount.rial,
      );
      expect(allocated, 150000);

      expect(invoice.totalDiscount, Money.rial(250000)); // 100,000 + 150,000
      expectReconciles(invoice);
    });

    test('subtotal is before the invoice discount and before tax', () {
      final invoice = calculate(
        <InvoiceLineInput>[line(priceRial: 1000000)],
        discountRial: 300000,
        defaultTaxRateBp: 1000,
      );
      expect(invoice.subtotal, Money.rial(1000000));
    });
  });

  group('the printed summary reconciles by hand', () {
    test('a subtotal-based summary would double-count line discounts', () {
      // Why `grossTotal` exists. The engine was already self-consistent; what
      // it did not offer was a set of figures a *document* could print and a
      // customer could check with a pencil.
      final invoice = calculate(
        <InvoiceLineInput>[
          line(priceRial: 1000000, quantityMilli: 2000, discountRial: 300000),
          line(priceRial: 500000, quantityMilli: 1000, discountRial: 50000),
        ],
        discountRial: 100000,
        defaultTaxRateBp: 900,
      );

      // Gross: 2,000,000 + 500,000 = 2,500,000
      // Line discounts: 300,000 + 50,000 = 350,000  -> subtotal 2,150,000
      // Invoice discount: 100,000                   -> net 2,050,000
      // Tax at 9%: 184,500                          -> total 2,234,500
      expect(invoice.grossTotal, Money.rial(2500000));
      expect(invoice.subtotal, Money.rial(2150000));
      expect(invoice.totalDiscount, Money.rial(450000));
      expect(invoice.totalTax, Money.rial(184500));
      expect(invoice.grandTotal, Money.rial(2234500));

      // The summary as printed: it adds up.
      expect(
        invoice.grossTotal.rial -
            invoice.totalDiscount.rial +
            invoice.totalTax.rial,
        invoice.grandTotal.rial,
      );

      // The same summary starting from the subtotal does not, and is short by
      // exactly the line discounts -- subtracted once into the subtotal and
      // again as part of totalDiscount. This is the arithmetic a user would do
      // and get a different answer from the one printed.
      expect(
        invoice.subtotal.rial -
            invoice.totalDiscount.rial +
            invoice.totalTax.rial,
        invoice.grandTotal.rial - 350000,
      );
    });

    test('it still adds up when rounding moves the total', () {
      final invoice = calculate(
        <InvoiceLineInput>[
          line(priceRial: 333333, quantityMilli: 3000, discountRial: 1234),
        ],
        discountRial: 777,
        defaultTaxRateBp: 900,
        roundingUnitRial: 1000,
      );

      expect(invoice.roundingAdjustment, isNot(Money.zero));
      expect(
        invoice.grossTotal.rial -
            invoice.totalDiscount.rial +
            invoice.totalTax.rial +
            invoice.roundingAdjustment.rial,
        invoice.grandTotal.rial,
      );
      expectReconciles(invoice);
    });

    test('a clamped line discount is reported at what was given', () {
      // D-027: the summary shows the discount actually deducted, so it has to
      // be the clamped figure or the total will not reconcile.
      final invoice = calculate(<InvoiceLineInput>[
        line(priceRial: 1000000, quantityMilli: 1000, discountRial: 1500000),
      ], defaultTaxRateBp: 0);

      expect(invoice.grossTotal, Money.rial(1000000));
      expect(invoice.totalDiscount, Money.rial(1000000));
      expect(invoice.grandTotal, Money.zero);
      expectReconciles(invoice);
    });
  });

  group('rounding the grand total', () {
    test('is disabled by default', () {
      final invoice = calculate(<InvoiceLineInput>[line(priceRial: 1234567)]);
      expect(invoice.roundingAdjustment, Money.zero);
      expectReconciles(invoice);
    });

    test('rounds to the configured unit and records the delta', () {
      final invoice = calculate(
        <InvoiceLineInput>[line(priceRial: 1234567)],
        defaultTaxRateBp: 0,
        roundingUnitRial: 1000,
      );

      expect(invoice.grandTotal, Money.rial(1235000));
      expect(invoice.roundingAdjustment, Money.rial(433));
      // Still reconciles once the recorded delta is taken into account -- that
      // is why the delta is stored at all.
      expectReconciles(invoice);
    });

    test('rounds down when below the halfway point', () {
      final invoice = calculate(
        <InvoiceLineInput>[line(priceRial: 1234400)],
        defaultTaxRateBp: 0,
        roundingUnitRial: 1000,
      );

      expect(invoice.grandTotal, Money.rial(1234000));
      expect(invoice.roundingAdjustment, Money.rial(-400));
      expectReconciles(invoice);
    });

    test('rounds an exact half up', () {
      final invoice = calculate(
        <InvoiceLineInput>[line(priceRial: 1234500)],
        defaultTaxRateBp: 0,
        roundingUnitRial: 1000,
      );
      expect(invoice.grandTotal, Money.rial(1235000));
    });
  });

  group('range and validation', () {
    test('rejects an amount past the ceiling rather than truncating', () {
      expect(
        () => calculate(<InvoiceLineInput>[
          line(priceRial: kMaxAmountRial, quantityMilli: 2000),
        ]),
        throwsA(isA<MoneyRangeError>()),
      );
    });

    test('rejects a quantity that would overflow exact integer arithmetic', () {
      expect(
        () => calculate(<InvoiceLineInput>[
          line(priceRial: kMaxAmountRial, quantityMilli: 1000000000),
        ]),
        throwsA(isA<MoneyRangeError>()),
      );
    });

    test('rejects negative quantities, prices and discounts', () {
      expect(
        () => calculate(<InvoiceLineInput>[line(quantityMilli: -1)]),
        throwsArgumentError,
      );
      expect(
        () => calculateInvoice(
          InvoiceInput(
            lines: <InvoiceLineInput>[
              InvoiceLineInput(unitPrice: Money.rial(-1), quantityMilli: 1000),
            ],
            defaultTaxRateBp: 1000,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => calculate(<InvoiceLineInput>[line(discountRial: -1)]),
        throwsArgumentError,
      );
    });

    test('rejects out-of-range basis points', () {
      expect(
        () => calculate(<InvoiceLineInput>[line(taxRateBp: 10001)]),
        throwsArgumentError,
      );
      expect(
        () => calculate(<InvoiceLineInput>[line(taxRateBp: -1)]),
        throwsArgumentError,
      );
      expect(
        () => calculate(<InvoiceLineInput>[line()], discountPercentBp: 20000),
        throwsArgumentError,
      );
    });
  });

  group('a large invoice with an invoice discount (D-059)', () {
    // Known issue 19, at the level a user met it. Step 4's allocation
    // multiplied the discount by each line's net, and that product is quadratic
    // in the invoice total — so a 30,000,000 تومان invoice with a 10% discount,
    // which is ordinary Iranian business, could not be calculated at all. The
    // whole ladder now goes through the real engine, and `expectReconciles`
    // asserts every §4 identity on each rung, the exactness of the allocation
    // among them.

    for (final int toman in kMoneyStressToman) {
      for (final int percent in <int>[1, 10, 25]) {
        test('reconciles at $toman toman with a $percent% discount', () {
          final int totalRial = toman * 10;
          expectReconciles(
            calculate(
              <InvoiceLineInput>[
                line(priceRial: totalRial ~/ 3),
                line(priceRial: totalRial - totalRial ~/ 3),
                // A third line with a discount of its own, so the invoice-level
                // allocation runs over nets that are not simply the gross.
                line(priceRial: totalRial ~/ 5, discountRial: totalRial ~/ 50),
              ],
              discountPercentBp: percent * 100,
              defaultTaxRateBp: 900,
            ),
          );
        });
      }
    }
  });

  group('the reconciliation invariant holds across the input space', () {
    test('for many combinations of quantity, discount and rate', () {
      // Deterministic sweep rather than random input: a money engine should
      // fail the same way on every run, or a failure cannot be reproduced.
      for (final quantity in <int>[0, 1, 500, 1000, 1500, 3333]) {
        for (final lineDiscount in <int>[0, 1, 12345]) {
          for (final invoiceDiscount in <int>[0, 7, 999]) {
            for (final rate in <int>[0, 1, 900, 1000, 10000]) {
              final invoice = calculate(
                <InvoiceLineInput>[
                  line(
                    priceRial: 123457,
                    quantityMilli: quantity,
                    discountRial: lineDiscount,
                  ),
                  line(priceRial: 99991, quantityMilli: 1000),
                  line(priceRial: 7, quantityMilli: 1),
                ],
                discountRial: invoiceDiscount,
                defaultTaxRateBp: rate,
              );

              expectReconciles(invoice);
              expect(invoice.grandTotal.isNegative, isFalse);
            }
          }
        }
      }
    });
  });
}
