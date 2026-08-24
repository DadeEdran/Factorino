import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/localization/generated/app_strings_fa.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/widgets/status_badge.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/features/invoices/domain/invoice_status_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one place a stored status becomes a displayed one.
///
/// Two properties are being pinned here, and they pull in opposite directions:
/// the mapping must pass the **stored** answer through untouched for the four
/// statuses the repository owns, and it must add `overdue` — which is not
/// stored and must never be — for the two that can be late.
void main() {
  Invoice invoice(InvoiceStatus status, {DateTime? dueDate}) {
    final DateTime issued = DateTime.utc(2026, 8, 1);
    return Invoice(
      id: 'i1',
      number: 'INV-1405-0001',
      numberYear: 1405,
      numberSequence: 1,
      customerId: 'c1',
      issueDate: issued,
      dueDate: dueDate,
      status: status,
      discount: Money.zero,
      subtotal: Money.rial(1000000),
      totalDiscount: Money.zero,
      totalTax: Money.zero,
      roundingAdjustment: Money.zero,
      grandTotal: Money.rial(1000000),
      createdAt: issued,
      updatedAt: issued,
    );
  }

  group('the stored answer is passed through, never recomputed', () {
    test('a stored status with no due date maps one-to-one', () {
      final DateTime now = DateTime.utc(2026, 8, 24, 6);

      expect(
        invoiceStatusViewOf(invoice(InvoiceStatus.draft), now: now),
        InvoiceStatusView.draft,
      );
      expect(
        invoiceStatusViewOf(invoice(InvoiceStatus.unpaid), now: now),
        InvoiceStatusView.unpaid,
      );
      expect(
        invoiceStatusViewOf(invoice(InvoiceStatus.partiallyPaid), now: now),
        InvoiceStatusView.partiallyPaid,
      );
      expect(
        invoiceStatusViewOf(invoice(InvoiceStatus.paid), now: now),
        InvoiceStatusView.paid,
      );
      expect(
        invoiceStatusViewOf(invoice(InvoiceStatus.cancelled), now: now),
        InvoiceStatusView.cancelled,
      );
    });

    test('a paid invoice long past its due date is still paid', () {
      // The tempting bug: age everything with a due date. `paid` is derived by
      // the repository on every payment write and persisted (§6); a display
      // layer that overrode it would put a red badge on an invoice the
      // customer has settled.
      final view = invoiceStatusViewOf(
        invoice(InvoiceStatus.paid, dueDate: DateTime.utc(2026, 1, 1)),
        now: DateTime.utc(2026, 8, 24),
      );
      expect(view, InvoiceStatusView.paid);
    });

    test('a cancelled invoice past its due date is cancelled, not overdue', () {
      // A cancelled invoice is no longer a claim on anyone, so nobody is late
      // on it.
      final view = invoiceStatusViewOf(
        invoice(InvoiceStatus.cancelled, dueDate: DateTime.utc(2026, 1, 1)),
        now: DateTime.utc(2026, 8, 24),
      );
      expect(view, InvoiceStatusView.cancelled);
    });

    test('a draft past its due date is a draft', () {
      final view = invoiceStatusViewOf(
        invoice(InvoiceStatus.draft, dueDate: DateTime.utc(2026, 1, 1)),
        now: DateTime.utc(2026, 8, 24),
      );
      expect(view, InvoiceStatusView.draft);
    });
  });

  group('overdue is derived, and only from the due date', () {
    test('an unpaid invoice past its due date is overdue', () {
      final view = invoiceStatusViewOf(
        invoice(InvoiceStatus.unpaid, dueDate: DateTime.utc(2026, 8, 1)),
        now: DateTime.utc(2026, 8, 24),
      );
      expect(view, InvoiceStatusView.overdue);
    });

    test('a partially paid invoice past its due date is overdue too', () {
      final view = invoiceStatusViewOf(
        invoice(InvoiceStatus.partiallyPaid, dueDate: DateTime.utc(2026, 8, 1)),
        now: DateTime.utc(2026, 8, 24),
      );
      expect(view, InvoiceStatusView.overdue);
    });

    test('no due date is never overdue', () {
      final view = invoiceStatusViewOf(
        invoice(InvoiceStatus.unpaid),
        now: DateTime.utc(2030, 1, 1),
      );
      expect(view, InvoiceStatusView.unpaid);
    });

    test('an invoice due today is not overdue until the day is over', () {
      // The defect this pins down: comparing instants rather than Jalali days
      // marks an invoice due at the start of today as overdue for the whole of
      // the day it is actually due. A red badge on a document nobody is late
      // on is worse than no badge -- it teaches the user to ignore red.
      //
      // 2026-08-24T00:00Z is early on 2 Shahrivar 1405 in Tehran (UTC+3:30).
      final DateTime due = DateTime.utc(2026, 8, 24);

      expect(
        isOverdue(
          invoice(InvoiceStatus.unpaid, dueDate: due),
          // Later the same Jalali day, well past the due instant.
          now: DateTime.utc(2026, 8, 24, 20),
        ),
        isFalse,
      );
      expect(
        isOverdue(
          invoice(InvoiceStatus.unpaid, dueDate: due),
          // The following Jalali day, once Tehran has passed midnight.
          now: DateTime.utc(2026, 8, 25, 21),
        ),
        isTrue,
      );
    });

    test('the boundary is Tehran midnight, to the minute', () {
      // The due instant 2026-08-24T00:00Z is 03:30 on 2 Shahrivar in Tehran
      // (UTC+3:30), so the Jalali day it belongs to ends at 2026-08-24T20:30Z
      // -- the same date in UTC, which is exactly the off-by-one an instant
      // comparison invites.
      final DateTime due = DateTime.utc(2026, 8, 24);
      final DateTime firstLateInstant = DateTime.utc(2026, 8, 24, 20, 30);

      expect(
        isOverdue(
          invoice(InvoiceStatus.unpaid, dueDate: due),
          now: firstLateInstant.subtract(const Duration(minutes: 1)),
        ),
        isFalse,
      );
      expect(
        isOverdue(
          invoice(InvoiceStatus.unpaid, dueDate: due),
          now: firstLateInstant,
        ),
        isTrue,
      );
    });
  });

  test('every displayed status has a Persian label', () {
    // Guards the switch, not the copy: a case added to InvoiceStatusView
    // without a label would fall through silently if the mapping ever grew a
    // default. Resolved from the generated Persian strings rather than from
    // literals copied into this file, which would keep passing after the copy
    // changed.
    final AppStrings strings = AppStringsFa();
    for (final InvoiceStatusView view in InvoiceStatusView.values) {
      expect(
        invoiceStatusLabel(view, strings),
        isNotEmpty,
        reason: '$view has no label',
      );
    }
    expect(
      invoiceStatusLabel(InvoiceStatusView.overdue, strings),
      strings.statusOverdue,
    );
    expect(
      invoiceStatusLabel(InvoiceStatusView.partiallyPaid, strings),
      strings.statusPartiallyPaid,
    );
  });
}
