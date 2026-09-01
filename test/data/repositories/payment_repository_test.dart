import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/models/payment.dart';
import 'package:factorino/data/models/payment_method.dart';
import 'package:factorino/data/repositories/payment_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repository_harness.dart';

/// the project spec: `partiallyPaid` and `paid` are derived from the sum of
/// payments and **recomputed on every payment write**.
///
/// The tests below check the derivation, and — more importantly — that it
/// happens as part of the same write. A payment that lands without its status
/// update is a wrong badge on a financial document, with the payment sitting
/// right there contradicting it.
void main() {
  late RepositoryHarness harness;
  late String invoiceId;

  /// An issued 1,100,000 Rial invoice (1,000,000 + 10% tax).
  setUp(() async {
    harness = await RepositoryHarness.open();
    final customer = await harness.customer();
    final created = await harness.invoices.create(
      harness.draft(customer.id, unitPriceRial: 1000000),
    );
    await harness.invoices.issue(created.invoice.id);
    invoiceId = created.invoice.id;
  });
  tearDown(() async => harness.close());

  PaymentDraft payment(int rial) => PaymentDraft(
    amount: Money.rial(rial),
    paidAt: DateTime.utc(2026, 8, 24, 12),
    method: PaymentMethod.cash,
  );

  group('the derived status', () {
    test('a partial payment gives partiallyPaid', () async {
      final result = await harness.payments.record(invoiceId, payment(400000));

      expect(result.invoice.status, InvoiceStatus.partiallyPaid);
      expect(result.payment, isNotNull);
    });

    test('payments totalling the grand total give paid', () async {
      await harness.payments.record(invoiceId, payment(600000));
      final result = await harness.payments.record(invoiceId, payment(500000));

      expect(result.invoice.status, InvoiceStatus.paid);
    });

    test('an overpayment is paid, not something else', () async {
      final result = await harness.payments.record(invoiceId, payment(2000000));
      expect(result.invoice.status, InvoiceStatus.paid);

      final detail = await harness.invoices.findDetail(invoiceId);
      expect(detail!.isOverpaid, isTrue);
      expect(
        detail.amountDue,
        Money.zero,
        reason: 'an invoice cannot owe a negative amount',
      );
    });

    test('the status is persisted, not just returned', () async {
      // The whole point of deriving *and* storing it (§6): a list query must
      // not have to join payments to know the badge.
      await harness.payments.record(invoiceId, payment(400000));

      final reread = await harness.invoices.findById(invoiceId);
      expect(reread!.status, InvoiceStatus.partiallyPaid);
    });

    test(
      'the invoice row is updated in the same write, not afterwards',
      () async {
        // If the status update were a separate call, this snapshot — taken from
        // the value the write itself returned — could disagree with the stored
        // row. It cannot, because both happen in one transaction.
        final result = await harness.payments.record(
          invoiceId,
          payment(1100000),
        );
        final stored = await harness.invoices.findById(invoiceId);

        expect(result.invoice.status, stored!.status);
        expect(stored.status, InvoiceStatus.paid);
      },
    );

    test('removing a payment moves the status back', () async {
      final recorded = await harness.payments.record(
        invoiceId,
        payment(1100000),
      );
      expect(recorded.invoice.status, InvoiceStatus.paid);

      final removed = await harness.payments.softDelete(recorded.payment!.id);

      expect(removed.invoice.status, InvoiceStatus.unpaid);
      expect(removed.payment, isNull);
      expect(await harness.payments.totalPaidRial(invoiceId), 0);
    });

    test('removing one of two payments falls back to partiallyPaid', () async {
      final first = await harness.payments.record(invoiceId, payment(600000));
      await harness.payments.record(invoiceId, payment(500000));

      final removed = await harness.payments.softDelete(first.payment!.id);
      expect(removed.invoice.status, InvoiceStatus.partiallyPaid);
      expect(await harness.payments.totalPaidRial(invoiceId), 500000);
    });
  });

  group('draft and cancelled are set by hand, never derived (§6)', () {
    test('a draft invoice refuses a payment', () async {
      final customer = await harness.customer(name: 'دیگری');
      final draftInvoice = await harness.invoices.create(
        harness.draft(customer.id),
      );

      expect(
        () => harness.payments.record(draftInvoice.invoice.id, payment(1000)),
        throwsA(isA<PaymentNotAccepted>()),
      );
    });

    test('a cancelled invoice refuses a payment', () async {
      await harness.invoices.cancel(invoiceId);

      expect(
        () => harness.payments.record(invoiceId, payment(1000)),
        throwsA(isA<PaymentNotAccepted>()),
      );
    });

    test('cancelling after payment leaves the status cancelled', () async {
      await harness.payments.record(invoiceId, payment(1100000));
      await harness.invoices.cancel(invoiceId);

      final stored = await harness.invoices.findById(invoiceId);
      expect(stored!.status, InvoiceStatus.cancelled);
    });

    test('a zero or negative payment is refused', () async {
      expect(
        () => harness.payments.record(invoiceId, payment(0)),
        throwsA(isA<PaymentNotAccepted>()),
      );
      expect(
        () => harness.payments.record(invoiceId, payment(-500)),
        throwsA(isA<PaymentNotAccepted>()),
      );
    });

    test('a refused payment leaves nothing behind', () async {
      try {
        await harness.payments.record(invoiceId, payment(0));
      } on PaymentNotAccepted {
        // expected
      }

      expect(await harness.payments.findForInvoice(invoiceId), isEmpty);
      final stored = await harness.invoices.findById(invoiceId);
      expect(stored!.status, InvoiceStatus.unpaid);
    });
  });

  group('the guard is the repository\'s, and a refusal leaves nothing behind', () {
    // **Called directly, not through a screen**, on the precedent Phase 4 (c)
    // set for `updateDraft`. The detail screen hides the record control on a
    // draft and on a cancelled invoice and explains why — but a deep link, a
    // second window and a future sync path never come through that screen, so
    // the rule has to live here or it does not live anywhere.
    //
    // And a guard that throws *after* writing half the change is worse than no
    // guard, so every refusal below is checked for what it left behind as well
    // as for the throw.

    Future<void> expectUntouched(
      String id, {
      required InvoiceStatus status,
      required int paidRial,
      required int paymentCount,
    }) async {
      final stored = await harness.invoices.findById(id);
      expect(stored!.status, status, reason: 'the status moved');
      expect(
        await harness.payments.totalPaidRial(id),
        paidRial,
        reason: 'the total paid moved',
      );
      expect(
        await harness.payments.findForInvoice(id),
        hasLength(paymentCount),
        reason: 'a payment row survived the refusal',
      );
    }

    test('a draft refuses, and is left exactly as it was', () async {
      final customer = await harness.customer(name: 'پیش‌نویس');
      final created = await harness.invoices.create(harness.draft(customer.id));
      final String id = created.invoice.id;

      await expectLater(
        harness.payments.record(id, payment(100000)),
        throwsA(isA<PaymentNotAccepted>()),
      );
      await expectUntouched(
        id,
        status: InvoiceStatus.draft,
        paidRial: 0,
        paymentCount: 0,
      );
    });

    test(
      'a cancelled invoice refuses, and keeps the payments it had',
      () async {
        // The harder case: the invoice already has a payment on it, so a guard
        // that wrote first and checked afterwards would be visible as a changed
        // total rather than only as a stray row.
        await harness.payments.record(invoiceId, payment(400000));
        await harness.invoices.cancel(invoiceId);

        await expectLater(
          harness.payments.record(invoiceId, payment(100000)),
          throwsA(isA<PaymentNotAccepted>()),
        );
        await expectUntouched(
          invoiceId,
          status: InvoiceStatus.cancelled,
          paidRial: 400000,
          paymentCount: 1,
        );
      },
    );

    test('a zero and a negative payment refuse, and leave nothing', () async {
      await harness.payments.record(invoiceId, payment(400000));

      for (final int rial in <int>[0, -500]) {
        await expectLater(
          harness.payments.record(invoiceId, payment(rial)),
          throwsA(isA<PaymentNotAccepted>()),
          reason: '$rial must be refused',
        );
      }
      await expectUntouched(
        invoiceId,
        status: InvoiceStatus.partiallyPaid,
        paidRial: 400000,
        paymentCount: 1,
      );
    });

    test('deleting a payment that is not there refuses', () async {
      await expectLater(
        harness.payments.softDelete('no-such-payment'),
        throwsA(isA<StateError>()),
      );
    });

    test('deleting the same payment twice refuses the second time', () async {
      // The double-tap, and the stale second window. The first delete
      // soft-deletes the row; the second must not silently recompute the status
      // again off a row that is already gone.
      final result = await harness.payments.record(invoiceId, payment(400000));
      await harness.payments.softDelete(result.payment!.id);

      await expectLater(
        harness.payments.softDelete(result.payment!.id),
        throwsA(isA<StateError>()),
      );
      await expectUntouched(
        invoiceId,
        status: InvoiceStatus.unpaid,
        paidRial: 0,
        paymentCount: 0,
      );
    });
  });

  group('the status moves in both directions', () {
    // §6 requires the derived status to be recomputed on **every** payment
    // write. Recording moves it forward; deleting has to move it back by the
    // same rule, in the same transaction, or an invoice keeps a «پرداخت شده»
    // badge with nothing paid against it.

    test('removing the only payment returns the invoice to unpaid', () async {
      final result = await harness.payments.record(invoiceId, payment(1100000));
      expect(result.invoice.status, InvoiceStatus.paid);

      final removed = await harness.payments.softDelete(result.payment!.id);
      expect(removed.invoice.status, InvoiceStatus.unpaid);
      expect(removed.payment, isNull);
      expect(await harness.payments.totalPaidRial(invoiceId), 0);
    });

    test('paid to partiallyPaid to unpaid, one deletion at a time', () async {
      final first = await harness.payments.record(invoiceId, payment(600000));
      final second = await harness.payments.record(invoiceId, payment(500000));
      expect(second.invoice.status, InvoiceStatus.paid);

      expect(
        (await harness.payments.softDelete(second.payment!.id)).invoice.status,
        InvoiceStatus.partiallyPaid,
      );
      expect(
        (await harness.payments.softDelete(first.payment!.id)).invoice.status,
        InvoiceStatus.unpaid,
      );
    });

    test(
      'the result carries the recomputed invoice, not a stale read',
      () async {
        // The caller sees the status the write produced without a second read,
        // which is what the return type is for -- and what a screen relies on
        // when it decides whether to warn that a deletion leaves «پرداخت شده».
        final result = await harness.payments.record(
          invoiceId,
          payment(1100000),
        );
        final stored = await harness.invoices.findById(invoiceId);

        expect(result.invoice.status, stored!.status);
        expect(result.invoice.id, invoiceId);
      },
    );

    test(
      'deleting a payment on a cancelled invoice leaves it cancelled',
      () async {
        // `cancelled` is set by hand and never derived (§6). Correcting a
        // mis-entered payment on a cancelled invoice is legitimate -- the money
        // record should be right either way -- but it must not resurrect the
        // invoice into `unpaid`.
        final result = await harness.payments.record(
          invoiceId,
          payment(400000),
        );
        await harness.invoices.cancel(invoiceId);

        final removed = await harness.payments.softDelete(result.payment!.id);
        expect(removed.invoice.status, InvoiceStatus.cancelled);
        expect(await harness.payments.totalPaidRial(invoiceId), 0);
      },
    );
  });

  group('reads', () {
    test('lists payments most recent first', () async {
      await harness.payments.record(
        invoiceId,
        PaymentDraft(
          amount: Money.rial(100000),
          paidAt: DateTime.utc(2026, 8, 20),
          method: PaymentMethod.cash,
        ),
      );
      await harness.payments.record(
        invoiceId,
        PaymentDraft(
          amount: Money.rial(200000),
          paidAt: DateTime.utc(2026, 8, 24),
          method: PaymentMethod.bankTransfer,
        ),
      );

      final payments = await harness.payments.findForInvoice(invoiceId);
      expect(payments.map((p) => p.amount.rial), <int>[200000, 100000]);
      expect(payments.first.method, PaymentMethod.bankTransfer);
    });

    test('the detail aggregate reflects payments', () async {
      await harness.payments.record(invoiceId, payment(400000));
      final detail = await harness.invoices.findDetail(invoiceId);

      expect(detail!.amountPaid, Money.rial(400000));
      expect(detail.amountDue, Money.rial(700000));
      expect(detail.isFullyPaid, isFalse);
      expect(detail.payments, hasLength(1));
    });

    test('a soft-deleted payment is excluded from every total', () async {
      final recorded = await harness.payments.record(
        invoiceId,
        payment(400000),
      );
      await harness.payments.softDelete(recorded.payment!.id);

      expect(await harness.payments.totalPaidRial(invoiceId), 0);
      expect(await harness.payments.findForInvoice(invoiceId), isEmpty);

      final detail = await harness.invoices.findDetail(invoiceId);
      expect(detail!.amountPaid, Money.zero);
    });

    test('payments are returned as domain models', () async {
      final result = await harness.payments.record(invoiceId, payment(400000));
      expect(result.payment, isA<Payment>());
      expect(result.payment!.paidAt.isUtc, isTrue);
      expect(result.payment!.amount, Money.rial(400000));
    });
  });
}
