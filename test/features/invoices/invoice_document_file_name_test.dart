import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/features/invoices/domain/invoice_document_file_name.dart';
import 'package:flutter_test/flutter_test.dart';

/// The name a saved invoice document is offered under (D-099).
///
/// **The property under test is uniqueness**, and it is the one the previous
/// scheme did not have: `INV-1405-0001.pdf` every time, so the second save was
/// the platform's problem — Windows asking whether to overwrite (one careless
/// Enter and the first file is gone) or SAF quietly writing
/// `INV-1405-0001(1).pdf`, two files whose names say nothing about which is
/// which. On a document a customer may already hold a copy of, neither is
/// acceptable.
void main() {
  Invoice invoice({String? number = 'INV-1405-0001'}) => Invoice(
    id: 'i1',
    number: number,
    numberYear: number == null ? null : 1405,
    numberSequence: number == null ? null : 1,
    customerId: 'c1',
    issueDate: DateTime.utc(2026, 8, 24, 6, 30),
    status: number == null ? InvoiceStatus.draft : InvoiceStatus.unpaid,
    discount: Money.zero,
    grossTotal: Money.zero,
    subtotal: Money.zero,
    totalDiscount: Money.zero,
    totalTax: Money.zero,
    roundingAdjustment: Money.zero,
    grandTotal: Money.zero,
    createdAt: DateTime.utc(2026, 8, 24, 6, 30),
    updatedAt: DateTime.utc(2026, 8, 24, 6, 30),
  );

  /// 10:00 Tehran on 1405/06/02.
  final DateTime at = DateTime.utc(2026, 8, 24, 6, 30);

  test('the whole name, spelled out', () {
    expect(
      invoiceDocumentFileName(invoice(), at),
      'INV-1405-0001_1405-06-02_10-00-00.pdf',
    );
  });

  test('two saves a second apart are two different names', () {
    // The defect this scheme exists for, at the tightest interval a person can
    // produce by hand.
    expect(
      invoiceDocumentFileName(invoice(), at),
      isNot(
        invoiceDocumentFileName(invoice(), at.add(const Duration(seconds: 1))),
      ),
    );
  });

  test('seconds are part of the name, not just minutes', () {
    // **Why the resolution is seconds.** Re-saving after correcting the seller
    // details happens inside one minute routinely, and a minute-resolution name
    // would collide on exactly that.
    final String first = invoiceDocumentFileName(invoice(), at);
    final String second = invoiceDocumentFileName(
      invoice(),
      at.add(const Duration(seconds: 40)),
    );
    expect(first, isNot(second));
  });

  test('the invoice number comes first, so exports of one invoice group', () {
    // A file manager sorting by name puts every export of one invoice together,
    // and the user searches for the number they already know.
    expect(invoiceDocumentFileName(invoice(), at), startsWith('INV-1405-0001'));
  });

  test('a draft has no number, and does not get one invented', () {
    // D-048: a draft never allocates a number, and a file name is not the place
    // to start.
    final String name = invoiceDocumentFileName(invoice(number: null), at);
    expect(name, startsWith(kInvoiceDocumentDraftStem));
    expect(name, isNot(contains('INV')));
    // Still unique, which matters more for drafts than for anything else: they
    // are the documents saved repeatedly while being worked on.
    expect(
      name,
      isNot(
        invoiceDocumentFileName(
          invoice(number: null),
          at.add(const Duration(seconds: 1)),
        ),
      ),
    );
  });

  test('it is Latin digits and safe punctuation, end to end', () {
    // **The rule `formatJalaliDateForFileName` records for backups, applied
    // here.** A name travels outside the application, and Persian digits in one
    // sort unpredictably, break some pickers, and are awkward to type when the
    // user is hunting for the file months later. A colon would be worse than
    // awkward: it is illegal in a Windows filename and the drive separator
    // besides, so it fails at the save dialog with a message about an invalid
    // name that says nothing about why.
    for (final Invoice subject in <Invoice>[invoice(), invoice(number: null)]) {
      final String name = invoiceDocumentFileName(subject, at);
      expect(
        RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(name),
        isTrue,
        reason: '"$name" carries a character a file system may object to',
      );
      expect(name, endsWith('.pdf'));
    }
  });

  test('the date in it is Jalali, which is the part that matters', () {
    // Latin *digits*, Jalali *calendar*: the user recognises 1405-06-02 as
    // their own date even though the numerals are not the ones on screen.
    expect(invoiceDocumentFileName(invoice(), at), contains('1405-06-02'));
    expect(invoiceDocumentFileName(invoice(), at), isNot(contains('2026')));
  });

  test('the time is Tehran wall clock, not UTC', () {
    // The same rule every displayed instant follows (§5). A name stamped in UTC
    // would be an hour and a half out of step with the time printed on the
    // document it names.
    expect(invoiceDocumentFileName(invoice(), at), contains('10-00-00'));
  });

  test('a day boundary is a Jalali one', () {
    // 20:30 UTC is midnight in Tehran: the next Jalali day, at 00-00-00.
    final String name = invoiceDocumentFileName(
      invoice(),
      DateTime.utc(2026, 8, 24, 20, 30),
    );
    expect(name, contains('1405-06-03'));
    expect(name, contains('00-00-00'));
  });
}
