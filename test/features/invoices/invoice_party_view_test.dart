import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/customer_snapshot.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_detail.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/features/invoices/domain/invoice_party_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// The four cases the detail screen has to tell apart, and the one it must stay
/// silent about (D-052).
void main() {
  final DateTime at = DateTime.utc(2026, 8, 20, 6);

  Customer customer({
    String fullName = 'مریم احمدی',
    String? nationalId = '0012345678',
    String? address = 'تهران',
  }) => Customer(
    id: 'c1',
    fullName: fullName,
    nationalId: nationalId,
    address: address,
    createdAt: at,
    updatedAt: at,
  );

  InvoiceDetail detail({
    required InvoiceStatus status,
    CustomerSnapshot? snapshot,
    Customer? live,
    bool customerIsDeleted = false,
  }) => InvoiceDetail(
    invoice: Invoice(
      id: 'i1',
      number: status == InvoiceStatus.draft ? null : 'INV-1405-0001',
      numberYear: status == InvoiceStatus.draft ? null : 1405,
      numberSequence: status == InvoiceStatus.draft ? null : 1,
      customerId: 'c1',
      issueDate: at,
      status: status,
      discount: Money.zero,
      grossTotal: Money.rial(1000000),
      subtotal: Money.rial(1000000),
      totalDiscount: Money.zero,
      totalTax: Money.zero,
      roundingAdjustment: Money.zero,
      grandTotal: Money.rial(1000000),
      customerSnapshot: snapshot,
      createdAt: at,
      updatedAt: at,
    ),
    customer: live ?? customer(),
    items: const <dynamic>[].cast(),
    payments: const <dynamic>[].cast(),
    customerIsDeleted: customerIsDeleted,
  );

  test('a snapshot that still matches the record says nothing', () {
    // The ordinary case, and the important one: a panel that explained itself
    // on every invoice would train the user to skip the explanation on the one
    // invoice where it matters.
    expect(
      partyProvenanceOf(
        detail(
          status: InvoiceStatus.unpaid,
          snapshot: CustomerSnapshot.of(customer()),
        ),
      ),
      InvoicePartyProvenance.snapshotMatchesRecord,
    );
  });

  test('a renamed customer diverges from the document', () {
    expect(
      partyProvenanceOf(
        detail(
          status: InvoiceStatus.unpaid,
          snapshot: CustomerSnapshot.of(customer()),
          live: customer(fullName: 'مریم احمدی‌نژاد'),
        ),
      ),
      InvoicePartyProvenance.snapshotDivergedFromRecord,
    );
  });

  test('a corrected کد ملی diverges too, not only a rename', () {
    // The comparison is over the whole snapshot on purpose. D-052 chose these
    // fields because they are the ones a correction touches, and a کد ملی is
    // the one carrying legal weight on an Iranian invoice -- so a screen that
    // only watched the name would stay silent on the field an auditor
    // reconciles against.
    expect(
      partyProvenanceOf(
        detail(
          status: InvoiceStatus.unpaid,
          snapshot: CustomerSnapshot.of(customer()),
          live: customer(nationalId: '0087654321'),
        ),
      ),
      InvoicePartyProvenance.snapshotDivergedFromRecord,
    );
  });

  test('a changed address diverges as well', () {
    expect(
      partyProvenanceOf(
        detail(
          status: InvoiceStatus.unpaid,
          snapshot: CustomerSnapshot.of(customer()),
          live: customer(address: 'اصفهان'),
        ),
      ),
      InvoicePartyProvenance.snapshotDivergedFromRecord,
    );
  });

  test('a draft follows the live record, and that is not a gap', () {
    // A draft is not a document yet and *should* pick up a correction (D-052).
    // It shares "no snapshot" with a pre-v3 invoice and means something
    // completely different by it, which is why the status decides between them.
    expect(
      partyProvenanceOf(detail(status: InvoiceStatus.draft)),
      InvoicePartyProvenance.draftFollowsRecord,
    );
  });

  test('an issued invoice with no snapshot is a gap, and says so', () {
    // Issued before schema v3. There is no snapshot and D-052 refuses to
    // fabricate one, so the live record is shown -- and the fact that this
    // document's own statement of the party was never stored is the same kind
    // of admission «ثبت‌نشده» makes for a figure.
    for (final InvoiceStatus status in <InvoiceStatus>[
      InvoiceStatus.unpaid,
      InvoiceStatus.partiallyPaid,
      InvoiceStatus.paid,
      InvoiceStatus.cancelled,
    ]) {
      expect(
        partyProvenanceOf(detail(status: status)),
        InvoicePartyProvenance.issuedWithoutSnapshot,
        reason: '$status is not editable, so it is a document without a party',
      );
    }
  });

  test('a soft-deleted customer is orthogonal to all four', () {
    // Deletion is a separate fact and stacks: a customer can be both renamed
    // and deleted, and the two are separately actionable -- one is about which
    // name is right, the other about why they are not in the list.
    final InvoiceDetail deletedAndDiverged = detail(
      status: InvoiceStatus.unpaid,
      snapshot: CustomerSnapshot.of(customer()),
      live: customer(fullName: 'مریم احمدی‌نژاد'),
      customerIsDeleted: true,
    );

    expect(
      partyProvenanceOf(deletedAndDiverged),
      InvoicePartyProvenance.snapshotDivergedFromRecord,
    );
    expect(deletedAndDiverged.customerIsDeleted, isTrue);
  });
}
