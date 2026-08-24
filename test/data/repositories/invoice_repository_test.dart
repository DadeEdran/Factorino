import 'dart:async';

import 'package:factorino/core/date/jalali_period.dart';
import 'package:factorino/core/money/invoice_calculator.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/invoice_draft.dart';
import 'package:factorino/data/models/invoice_list_item.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/models/payment.dart';
import 'package:factorino/data/models/payment_method.dart';
import 'package:factorino/data/models/product.dart';
import 'package:factorino/data/repositories/invoice_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repository_harness.dart';

void main() {
  late RepositoryHarness harness;
  late String customerId;

  setUp(() async {
    harness = await RepositoryHarness.open();
    customerId = (await harness.customer()).id;
  });
  tearDown(() async => harness.close());

  group('number allocation (D-013)', () {
    test('starts at 0001 and uses the settings prefix', () async {
      final result = await harness.invoices.create(harness.draft(customerId));

      expect(result.invoice.number, 'INV-1405-0001');
      expect(result.invoice.numberYear, 1405);
      expect(result.invoice.numberSequence, 1);
    });

    test('increments within a year', () async {
      await harness.invoices.create(harness.draft(customerId));
      final second = await harness.invoices.create(harness.draft(customerId));
      expect(second.invoice.number, 'INV-1405-0002');
    });

    test(
      'the year is the JALALI year of the issue date, not Gregorian',
      () async {
        // Both dates are in Gregorian March 2026, either side of Nowruz. A
        // Gregorian year would put them in the same sequence; the Jalali year
        // puts them in different ones (D-006).
        final before = await harness.invoices.create(
          harness.draft(customerId, issueDate: DateTime.utc(2026, 3, 15, 12)),
        );
        final after = await harness.invoices.create(
          harness.draft(customerId, issueDate: DateTime.utc(2026, 3, 25, 12)),
        );

        expect(before.invoice.number, 'INV-1404-0001');
        expect(after.invoice.number, 'INV-1405-0001');
      },
    );

    test('honours a reconfigured prefix', () async {
      final settings = await harness.settings.read();
      await harness.settings.write(
        settings.copyWith(invoiceNumberPrefix: 'FCT'),
      );

      final result = await harness.invoices.create(harness.draft(customerId));
      expect(result.invoice.number, 'FCT-1405-0001');
    });

    test('a spent number is never reissued after a soft delete', () async {
      final first = await harness.invoices.create(harness.draft(customerId));
      await harness.invoices.softDeleteDraft(first.invoice.id);

      final second = await harness.invoices.create(harness.draft(customerId));
      expect(
        second.invoice.number,
        'INV-1405-0002',
        reason:
            'a gap in the sequence is far better than two documents sharing '
            'one identity (D-013)',
      );
    });

    test('concurrent allocation cannot produce a duplicate', () async {
      // The reason allocation lives inside the write transaction. Reading the
      // maximum and inserting the row must not be separable, or two invoices
      // created in the same instant take the same number.
      final results = await Future.wait(
        List<Future<InvoiceCreationResult>>.generate(
          10,
          (_) => harness.invoices.create(harness.draft(customerId)),
        ),
      );

      final numbers = results.map((r) => r.invoice.number).toSet();
      expect(numbers, hasLength(10), reason: 'every number must be distinct');

      final sequences = results.map((r) => r.invoice.numberSequence).toList()
        ..sort();
      expect(
        sequences,
        List<int>.generate(10, (i) => i + 1),
        reason: 'the sequence must have no gaps and no repeats',
      );
    });
  });

  group('totals come from the engine, not the caller', () {
    test('stores the computed totals as snapshots', () async {
      // 1,000,000 Rial at the 10% default rate.
      final result = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 1000000),
      );
      final invoice = result.invoice;

      expect(invoice.subtotal, Money.rial(1000000));
      expect(invoice.totalTax, Money.rial(100000));
      expect(invoice.grandTotal, Money.rial(1100000));
    });

    test('the stored invoice reconciles with its stored lines', () async {
      final result = await harness.invoices.create(
        InvoiceDraft(
          customerId: customerId,
          issueDate: DateTime.utc(2026, 8, 24, 12),
          discount: Money.rial(50000),
          items: <InvoiceItemDraft>[
            InvoiceItemDraft(
              title: 'الف',
              unit: 'عدد',
              unitPrice: Money.rial(1000000),
              quantityMilli: 1500,
            ),
            InvoiceItemDraft(
              title: 'ب',
              unit: 'ساعت',
              unitPrice: Money.rial(300000),
              quantityMilli: 2000,
              discount: Money.rial(100000),
            ),
          ],
        ),
      );

      final detail = await harness.invoices.findDetail(result.invoice.id);
      final invoice = detail!.invoice;
      final lineSum = detail.items.fold<int>(
        0,
        (sum, item) => sum + item.lineTotal.rial,
      );

      expect(
        invoice.grandTotal.rial - invoice.roundingAdjustment.rial,
        lineSum,
        reason: 'the stored lines must sum to the stored total',
      );
      expect(
        invoice.grandTotal.rial - invoice.roundingAdjustment.rial,
        invoice.subtotal.rial - invoice.discount.rial + invoice.totalTax.rial,
        reason: 'the §4 invariant, on the persisted values',
      );
    });

    test(
      'resolves the tax chain item -> invoice -> settings (D-026)',
      () async {
        final result = await harness.invoices.create(
          InvoiceDraft(
            customerId: customerId,
            issueDate: DateTime.utc(2026, 8, 24, 12),
            taxRateBp: 900,
            items: <InvoiceItemDraft>[
              // Inherits the invoice rate.
              InvoiceItemDraft(
                title: 'الف',
                unit: 'عدد',
                unitPrice: Money.rial(1000000),
                quantityMilli: 1000,
              ),
              // Explicitly exempt: zero is a real rate, never "unset".
              InvoiceItemDraft(
                title: 'ب',
                unit: 'عدد',
                unitPrice: Money.rial(1000000),
                quantityMilli: 1000,
                taxRateBp: 0,
              ),
            ],
          ),
        );

        final detail = await harness.invoices.findDetail(result.invoice.id);
        expect(detail!.items[0].resolvedTaxRateBp, 900);
        expect(detail.items[1].resolvedTaxRateBp, 0);
        expect(detail.items[1].lineTax, Money.zero);
      },
    );

    test(
      'surfaces the money engine warnings from the write path (D-027)',
      () async {
        final result = await harness.invoices.create(
          InvoiceDraft(
            customerId: customerId,
            issueDate: DateTime.utc(2026, 8, 24, 12),
            items: <InvoiceItemDraft>[
              InvoiceItemDraft(
                title: 'الف',
                unit: 'عدد',
                unitPrice: Money.rial(1000000),
                quantityMilli: 1000,
                discount: Money.rial(1500000),
              ),
            ],
          ),
        );

        expect(result.hasWarnings, isTrue);
        expect(
          result.warnings.single.kind,
          InvoiceWarningKind.lineDiscountClamped,
        );
        // The invoice is stored, and stored with the effective discount.
        expect(result.invoice.totalDiscount, Money.rial(1000000));
      },
    );
  });

  group('price snapshots (D-004)', () {
    test('a later product price change does not touch the invoice', () async {
      final product = await harness.product(priceRial: 1000000);
      final result = await harness.invoices.create(
        InvoiceDraft(
          customerId: customerId,
          issueDate: DateTime.utc(2026, 8, 24, 12),
          items: <InvoiceItemDraft>[
            InvoiceItemDraft(
              productId: product.id,
              title: product.name,
              unit: product.unit,
              unitPrice: product.price,
              quantityMilli: 1000,
            ),
          ],
        ),
      );

      await harness.products.update(
        product.id,
        ProductDraft(
          name: product.name,
          type: product.type,
          price: Money.rial(9999999),
          unit: product.unit,
        ),
      );

      final detail = await harness.invoices.findDetail(result.invoice.id);
      expect(detail!.items.single.unitPrice, Money.rial(1000000));
      expect(detail.invoice.grandTotal, Money.rial(1100000));
    });

    test('the line survives its product being soft-deleted', () async {
      final product = await harness.product(priceRial: 500000);
      final result = await harness.invoices.create(
        InvoiceDraft(
          customerId: customerId,
          issueDate: DateTime.utc(2026, 8, 24, 12),
          items: <InvoiceItemDraft>[
            InvoiceItemDraft(
              productId: product.id,
              title: product.name,
              unit: product.unit,
              unitPrice: product.price,
              quantityMilli: 1000,
            ),
          ],
        ),
      );

      await harness.products.softDelete(product.id);

      final detail = await harness.invoices.findDetail(result.invoice.id);
      expect(detail!.items.single.title, product.name);
      expect(detail.items.single.unitPrice, Money.rial(500000));
    });
  });

  group('only a draft may be edited or deleted (§6)', () {
    test('updateDraft replaces the lines and the totals', () async {
      final created = await harness.invoices.create(harness.draft(customerId));

      final updated = await harness.invoices.updateDraft(
        created.invoice.id,
        harness.draft(customerId, unitPriceRial: 2000000),
      );

      expect(updated.invoice.grandTotal, Money.rial(2200000));
      expect(
        updated.invoice.number,
        created.invoice.number,
        reason: 'editing a draft must not reallocate its number',
      );

      final detail = await harness.invoices.findDetail(created.invoice.id);
      expect(
        detail!.items,
        hasLength(1),
        reason: 'the replaced line is soft-deleted, not shown',
      );
      expect(detail.items.single.unitPrice, Money.rial(2000000));
    });

    test('an issued invoice cannot be edited', () async {
      final created = await harness.invoices.create(harness.draft(customerId));
      await harness.invoices.issue(created.invoice.id);

      expect(
        () => harness.invoices.updateDraft(
          created.invoice.id,
          harness.draft(customerId, unitPriceRial: 1),
        ),
        throwsA(isA<InvoiceNotEditable>()),
      );
    });

    test('an issued invoice cannot be deleted', () async {
      final created = await harness.invoices.create(harness.draft(customerId));
      await harness.invoices.issue(created.invoice.id);

      expect(
        () => harness.invoices.softDeleteDraft(created.invoice.id),
        throwsA(isA<InvoiceNotEditable>()),
      );
      expect(await harness.invoices.findById(created.invoice.id), isNotNull);
    });

    test('cancellation keeps the number', () async {
      final created = await harness.invoices.create(harness.draft(customerId));
      await harness.invoices.issue(created.invoice.id);
      final cancelled = await harness.invoices.cancel(created.invoice.id);

      expect(cancelled.status, InvoiceStatus.cancelled);
      expect(cancelled.number, created.invoice.number);

      final next = await harness.invoices.create(harness.draft(customerId));
      expect(next.invoice.number, 'INV-1405-0002');
    });

    test('issuing moves a draft to unpaid', () async {
      final created = await harness.invoices.create(harness.draft(customerId));
      expect(created.invoice.status, InvoiceStatus.draft);
      expect(created.invoice.isEditable, isTrue);

      final issued = await harness.invoices.issue(created.invoice.id);
      expect(issued.status, InvoiceStatus.unpaid);
      expect(issued.isEditable, isFalse);
    });
  });

  group('Jalali reporting periods (D-006)', () {
    test(
      'watchInPeriod uses the Jalali month, not the Gregorian one',
      () async {
        // Esfand 1404 and Farvardin 1405: ten days apart, same Gregorian month.
        await harness.invoices.create(
          harness.draft(customerId, issueDate: DateTime.utc(2026, 3, 15, 12)),
        );
        await harness.invoices.create(
          harness.draft(customerId, issueDate: DateTime.utc(2026, 3, 25, 12)),
        );

        final esfand = await harness.invoices
            .watchInPeriod(jalaliMonth(1404, 12))
            .first;
        final farvardin = await harness.invoices
            .watchInPeriod(jalaliMonth(1405, 1))
            .first;

        expect(esfand, hasLength(1));
        expect(farvardin, hasLength(1));
        expect(esfand.single.id, isNot(farvardin.single.id));
      },
    );

    test('totalIssuedRial counts only issued invoices, in SQL', () async {
      // D-039. A draft is not yet a claim on anyone -- the payment path
      // already refuses money against one -- so it is not revenue. Before the
      // correction this summed drafts too, which made the dashboard's sales
      // figure move while the user was still typing an invoice.
      final first = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 1000000),
      );
      final second = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 2000000),
      );
      final period = jalaliMonth(1405, 6);

      // Both are drafts.
      expect(await harness.invoices.totalIssuedRial(period), 0);

      await harness.invoices.issue(second.invoice.id);
      expect(await harness.invoices.totalIssuedRial(period), 2200000);

      await harness.invoices.issue(first.invoice.id);
      expect(await harness.invoices.totalIssuedRial(period), 3300000);

      await harness.invoices.cancel(first.invoice.id);
      expect(await harness.invoices.totalIssuedRial(period), 2200000);
    });

    test('the live total and the resolved total agree', () async {
      final created = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 1000000),
      );
      await harness.invoices.issue(created.invoice.id);
      final period = jalaliMonth(1405, 6);

      expect(
        await harness.invoices.watchTotalIssuedRial(period).first,
        await harness.invoices.totalIssuedRial(period),
      );
    });

    test('the live total re-emits after a write', () async {
      // The whole reason this is a stream and not a Future: a provider over a
      // Future answers once, and the dashboard then shows a figure that was
      // true before the invoice the user just issued.
      final period = jalaliMonth(1405, 6);
      final List<int> seen = <int>[];
      final StreamSubscription<int> subscription = harness.invoices
          .watchTotalIssuedRial(period)
          .listen(seen.add);
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      expect(seen, <int>[0]);

      final created = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 1000000),
      );
      await harness.invoices.issue(created.invoice.id);
      await pumpEventQueue();

      expect(seen.last, 1100000);
    });

    test('watchIssuedCountInPeriod counts the same population', () async {
      final draftOnly = await harness.invoices.create(
        harness.draft(customerId),
      );
      final issued = await harness.invoices.create(harness.draft(customerId));
      await harness.invoices.issue(issued.invoice.id);

      final period = jalaliMonth(1405, 6);
      expect(await harness.invoices.watchIssuedCountInPeriod(period).first, 1);

      await harness.invoices.issue(draftOnly.invoice.id);
      expect(await harness.invoices.watchIssuedCountInPeriod(period).first, 2);

      await harness.invoices.cancel(draftOnly.invoice.id);
      expect(await harness.invoices.watchIssuedCountInPeriod(period).first, 1);
    });

    test('a Jalali period excludes an invoice one hour outside it', () async {
      // D-006. The boundary is the thing worth testing: an invoice issued in
      // the last hour of Mordad must not count towards Shahrivar.
      final inMonth = await harness.invoices.create(
        harness.draft(customerId, issueDate: DateTime.utc(2026, 8, 24, 12)),
      );
      await harness.invoices.issue(inMonth.invoice.id);

      final DateTime before = jalaliMonth(
        1405,
        6,
      ).start.subtract(const Duration(hours: 1));
      final earlier = await harness.invoices.create(
        harness.draft(customerId, issueDate: before, unitPriceRial: 5000000),
      );
      await harness.invoices.issue(earlier.invoice.id);

      expect(
        await harness.invoices.totalIssuedRial(jalaliMonth(1405, 6)),
        1100000,
      );
      expect(
        await harness.invoices.totalIssuedRial(jalaliMonth(1405, 5)),
        5500000,
      );
    });

    test('a period with no invoices totals zero, not null', () async {
      await harness.invoices.create(harness.draft(customerId));
      expect(await harness.invoices.totalIssuedRial(jalaliMonth(1403, 1)), 0);
    });

    test('watchCount is live and excludes soft-deleted invoices', () async {
      expect(await harness.invoices.watchCount().first, 0);

      final created = await harness.invoices.create(harness.draft(customerId));
      expect(await harness.invoices.watchCount().first, 1);

      await harness.invoices.softDeleteDraft(created.invoice.id);
      expect(await harness.invoices.watchCount().first, 0);
    });
  });

  group('outstanding balance', () {
    Future<void> pay(String invoiceId, int rial, int day) {
      return harness.payments.record(
        invoiceId,
        PaymentDraft(
          amount: Money.rial(rial),
          paidAt: DateTime.utc(2026, 8, day),
          method: PaymentMethod.cash,
        ),
      );
    }

    test('is grand total less payments, in one query', () async {
      final first = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 1000000),
      );
      final second = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 2000000),
      );
      await harness.invoices.issue(first.invoice.id);
      await harness.invoices.issue(second.invoice.id);

      expect(await harness.invoices.watchOutstandingRial().first, 3300000);

      await pay(first.invoice.id, 100000, 25);
      expect(await harness.invoices.watchOutstandingRial().first, 3200000);

      // Two instalments on one invoice. A join to payments instead of the
      // correlated subquery would double that invoice's grand total here, and
      // the tile would climb as the customer paid.
      await pay(first.invoice.id, 200000, 26);
      expect(await harness.invoices.watchOutstandingRial().first, 3000000);
    });

    test('a fully paid invoice leaves nothing outstanding', () async {
      final created = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 1000000),
      );
      await harness.invoices.issue(created.invoice.id);
      await pay(created.invoice.id, 1100000, 25);

      // The invoice is now `paid`, so it and its payments leave the aggregate
      // together -- which is why the payments side is scoped by the invoice
      // rather than summed on its own.
      expect(await harness.invoices.watchOutstandingRial().first, 0);
    });

    test('a draft owes nothing, and a cancellation stops owing', () async {
      final created = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 1000000),
      );
      expect(await harness.invoices.watchOutstandingRial().first, 0);

      await harness.invoices.issue(created.invoice.id);
      expect(await harness.invoices.watchOutstandingRial().first, 1100000);

      await harness.invoices.cancel(created.invoice.id);
      expect(await harness.invoices.watchOutstandingRial().first, 0);
    });
  });

  group('per-customer totals', () {
    Future<void> pay(String invoiceId, int rial, int day) {
      return harness.payments.record(
        invoiceId,
        PaymentDraft(
          amount: Money.rial(rial),
          paidAt: DateTime.utc(2026, 8, day),
          method: PaymentMethod.cash,
        ),
      );
    }

    test('billed counts issued invoices only (D-039)', () async {
      final draft = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 1000000),
      );
      final issued = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 2000000),
      );
      final cancelled = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 4000000),
      );
      await harness.invoices.issue(issued.invoice.id);
      await harness.invoices.issue(cancelled.invoice.id);
      await harness.invoices.cancel(cancelled.invoice.id);

      final totals = await harness.invoices
          .watchCustomerTotals(customerId)
          .first;

      // Only the second invoice: the draft is not yet a claim on anyone and
      // the cancellation is no longer one. A customer's billed history must
      // not climb while the user is still typing an invoice.
      expect(totals.billed, Money.rial(2200000));
      expect(draft.invoice.status, InvoiceStatus.draft);
    });

    test('outstanding is grand total less payments, per instalment', () async {
      final first = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 1000000),
      );
      final second = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 2000000),
      );
      await harness.invoices.issue(first.invoice.id);
      await harness.invoices.issue(second.invoice.id);

      expect(
        (await harness.invoices.watchCustomerTotals(customerId).first)
            .outstanding,
        Money.rial(3300000),
      );

      // Two instalments against one invoice. A join to payments rather than
      // the correlated subquery would double that invoice's grand total here,
      // so the figure would climb as the customer paid.
      await pay(first.invoice.id, 100000, 25);
      await pay(first.invoice.id, 200000, 26);

      final totals = await harness.invoices
          .watchCustomerTotals(customerId)
          .first;
      expect(totals.outstanding, Money.rial(3000000));
      // Billed does not move when money arrives: the invoice was issued for
      // that amount whether or not it has been paid. The two figures answer
      // different questions and neither is derivable from the other.
      expect(totals.billed, Money.rial(3300000));
    });

    test('a fully paid customer has billed history and owes nothing', () async {
      final created = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 1000000),
      );
      await harness.invoices.issue(created.invoice.id);
      await pay(created.invoice.id, 1100000, 25);

      final totals = await harness.invoices
          .watchCustomerTotals(customerId)
          .first;
      expect(totals.billed, Money.rial(1100000));
      expect(totals.outstanding, Money.rial(0));
      expect(totals.isEmpty, isFalse);
    });

    test('another customer\'s invoices are not counted', () async {
      // The scoping is the whole point of the read: without the customer
      // predicate this returns the dashboard's figures on every customer's
      // page, which would look plausible on the first customer entered.
      final other = await harness.customer(name: 'مشتری دیگر');
      final mine = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 1000000),
      );
      final theirs = await harness.invoices.create(
        harness.draft(other.id, unitPriceRial: 5000000),
      );
      await harness.invoices.issue(mine.invoice.id);
      await harness.invoices.issue(theirs.invoice.id);

      expect(
        (await harness.invoices.watchCustomerTotals(customerId).first).billed,
        Money.rial(1100000),
      );
      expect(
        (await harness.invoices.watchCustomerTotals(other.id).first).billed,
        Money.rial(5500000),
      );
    });

    test('a customer with no invoices reads zero, not an absent row', () async {
      // `SUM` over no rows is null, and the query still returns one row. If
      // that null reached the screen as an absent value the tile would show a
      // loading state forever on every new customer.
      final fresh = await harness.customer(name: 'مشتری تازه');

      final totals = await harness.invoices.watchCustomerTotals(fresh.id).first;
      expect(totals.billed, Money.rial(0));
      expect(totals.outstanding, Money.rial(0));
      expect(totals.isEmpty, isTrue);
    });

    test('a soft-deleted invoice leaves both figures', () async {
      final created = await harness.invoices.create(
        harness.draft(customerId, unitPriceRial: 1000000),
      );
      await harness.invoices.softDeleteDraft(created.invoice.id);

      final totals = await harness.invoices
          .watchCustomerTotals(customerId)
          .first;
      expect(totals.billed, Money.rial(0));
      expect(totals.outstanding, Money.rial(0));
    });
  });

  group('list with customer names', () {
    test('resolves the customer name in one query', () async {
      final created = await harness.invoices.create(harness.draft(customerId));

      final List<InvoiceListItem> items = await harness.invoices
          .watchList()
          .first;
      expect(items, hasLength(1));
      expect(items.single.invoice.id, created.invoice.id);
      expect(items.single.customerName, isNotEmpty);
    });

    test('the limit reaches SQL', () async {
      for (var i = 0; i < 5; i++) {
        await harness.invoices.create(harness.draft(customerId));
      }

      expect(await harness.invoices.watchList(limit: 2).first, hasLength(2));
    });

    test('newest first, by issue date then sequence', () async {
      final older = await harness.invoices.create(
        harness.draft(customerId, issueDate: DateTime.utc(2026, 8, 20, 12)),
      );
      final newer = await harness.invoices.create(
        harness.draft(customerId, issueDate: DateTime.utc(2026, 8, 24, 12)),
      );

      final List<InvoiceListItem> items = await harness.invoices
          .watchList()
          .first;
      expect(
        items.map((InvoiceListItem item) => item.invoice.id).toList(),
        <String>[newer.invoice.id, older.invoice.id],
      );
    });

    test('an invoice survives its customer being soft-deleted', () async {
      // The delete dialog promises, in Persian, that invoices already issued
      // to this customer stay untouched. Filtering the join on `deleted_at`
      // would make the invoice vanish from the list instead, and `findDetail`
      // returned null -- the promise broken silently.
      final created = await harness.invoices.create(harness.draft(customerId));
      final String name = (await harness.customers.findById(customerId))!
          .fullName;
      await harness.customers.softDelete(customerId);

      final List<InvoiceListItem> items = await harness.invoices
          .watchList()
          .first;
      expect(items, hasLength(1));
      expect(items.single.customerName, name);

      final detail = await harness.invoices.findDetail(created.invoice.id);
      expect(detail, isNotNull);
      expect(detail!.customer.id, customerId);
    });

    test('a soft-deleted invoice leaves the list', () async {
      final created = await harness.invoices.create(harness.draft(customerId));
      await harness.invoices.softDeleteDraft(created.invoice.id);

      expect(await harness.invoices.watchList().first, isEmpty);
    });
  });

  group('detail aggregate', () {
    test(
      'assembles invoice, customer, lines and payments in one read',
      () async {
        final created = await harness.invoices.create(
          harness.draft(customerId),
        );
        final detail = await harness.invoices.findDetail(created.invoice.id);

        expect(detail, isNotNull);
        expect(detail!.customer.id, customerId);
        expect(detail.items, hasLength(1));
        expect(detail.payments, isEmpty);
        expect(detail.amountPaid, Money.zero);
        expect(detail.amountDue, detail.invoice.grandTotal);
        expect(detail.isFullyPaid, isFalse);
      },
    );

    test('lines come back in position order', () async {
      final created = await harness.invoices.create(
        InvoiceDraft(
          customerId: customerId,
          issueDate: DateTime.utc(2026, 8, 24, 12),
          items: <InvoiceItemDraft>[
            InvoiceItemDraft(
              title: 'اول',
              unit: 'عدد',
              unitPrice: Money.rial(100),
              quantityMilli: 1000,
            ),
            InvoiceItemDraft(
              title: 'دوم',
              unit: 'عدد',
              unitPrice: Money.rial(200),
              quantityMilli: 1000,
            ),
            InvoiceItemDraft(
              title: 'سوم',
              unit: 'عدد',
              unitPrice: Money.rial(300),
              quantityMilli: 1000,
            ),
          ],
        ),
      );

      final detail = await harness.invoices.findDetail(created.invoice.id);
      expect(detail!.items.map((i) => i.title), <String>['اول', 'دوم', 'سوم']);
      expect(detail.items.map((i) => i.position), <int>[0, 1, 2]);
    });

    test('returns null for an unknown or deleted invoice', () async {
      expect(await harness.invoices.findDetail('no-such-id'), isNull);

      final created = await harness.invoices.create(harness.draft(customerId));
      await harness.invoices.softDeleteDraft(created.invoice.id);
      expect(await harness.invoices.findDetail(created.invoice.id), isNull);
    });
  });
}
