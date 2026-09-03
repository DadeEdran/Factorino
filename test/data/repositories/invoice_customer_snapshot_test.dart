// Drift, in a repository test, for one reason: writing the invoice row a
// database migrated from before schema v3 holds -- issued, with every snapshot
// column null. The repository cannot produce one any more, which is the point.
import 'package:drift/drift.dart' show Value;
import 'package:factorino/data/database/app_database.dart'
    show InvoicesCompanion;
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/customer_snapshot.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_detail.dart';
import 'package:factorino/data/models/invoice_list_item.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repository_harness.dart';

/// The party snapshot (D-052).
///
/// **The defect these are written against.** Before v3 an invoice stored a
/// `customer_id` and nothing else, and every screen resolved the name by
/// joining to the live row. Renaming a customer — a correction, a marriage, a
/// company changing its trading name — therefore rewrote the name on **every
/// invoice ever issued to them**, including ones already sent, already paid and
/// already filed. Reprinting last year's invoice produced a different document
/// from the one the customer holds. That is D-004's failure applied to the
/// party rather than the price, and it is worse here, because the identity of
/// the party is what an auditor reconciles against.
///
/// Two boundaries decide everything below:
///
/// * **At issue, not at draft creation.** A draft is not a document and should
///   pick up a correction; an issued invoice must not.
/// * **The tax identifiers, not just the name.** کد ملی and کد اقتصادی carry
///   the legal weight on an Iranian invoice and are exactly the fields a
///   correction changes. The mobile is excluded on purpose — contact detail,
///   not document content.
void main() {
  late RepositoryHarness harness;

  setUp(() async => harness = await RepositoryHarness.open());
  tearDown(() async => harness.close());

  /// A customer with every field the snapshot covers, and the one it does not.
  Future<Customer> fullCustomer() {
    return harness.customers.create(
      const CustomerDraft(
        fullName: 'مریم احمدی',
        companyName: 'کارگاه نمونه',
        nationalId: '0079542311',
        address: 'تهران، خیابان ولیعصر، پلاک ۱۰',
        mobile: '09123456789',
      ),
    );
  }

  group('when the snapshot is taken', () {
    test('a draft has none', () async {
      final Customer customer = await fullCustomer();
      final created = await harness.invoices.create(harness.draft(customer.id));

      expect(created.invoice.customerSnapshot, isNull);

      // And it therefore reads through to the live record, which is what a
      // draft should show: it is still being edited, and a correction made
      // while it sits there belongs in it.
      expect(created.invoice.party(customer).fullName, 'مریم احمدی');
    });

    test('issuing writes it, from the customer as they stand then', () async {
      final Customer customer = await fullCustomer();
      final created = await harness.invoices.create(harness.draft(customer.id));
      final Invoice issued = await harness.invoices.issue(created.invoice.id);

      final CustomerSnapshot? snapshot = issued.customerSnapshot;
      expect(snapshot, isNotNull);
      expect(snapshot!.fullName, 'مریم احمدی');
      expect(snapshot.companyName, 'کارگاه نمونه');
      expect(snapshot.nationalId, '0079542311');
      expect(snapshot.address, 'تهران، خیابان ولیعصر، پلاک ۱۰');
    });

    test('a draft written before a correction is issued with it', () async {
      // This is the whole reason the snapshot is taken at issue rather than at
      // draft creation. A draft is not a document; freezing the party when the
      // form opened would make a correction unreachable without deleting the
      // invoice and retyping it.
      final Customer customer = await harness.customers.create(
        const CustomerDraft(fullName: 'مریم احمدي', nationalId: '0079542311'),
      );
      final created = await harness.invoices.create(harness.draft(customer.id));

      await harness.customers.update(
        customer.id,
        const CustomerDraft(fullName: 'مریم احمدی', nationalId: '0084575948'),
      );

      final Invoice issued = await harness.invoices.issue(created.invoice.id);
      expect(issued.customerSnapshot!.fullName, 'مریم احمدی');
      expect(issued.customerSnapshot!.nationalId, '0084575948');
    });

    test('an invoice created already issued takes one too', () async {
      // `create(status:)` is a second route to a document, and a document
      // without a party snapshot is the defect this decision exists to close.
      final Customer customer = await fullCustomer();
      final created = await harness.invoices.create(
        harness.draft(customer.id),
        status: InvoiceStatus.unpaid,
      );

      expect(created.invoice.customerSnapshot?.fullName, 'مریم احمدی');
      expect(created.invoice.customerSnapshot?.nationalId, '0079542311');
    });
  });

  group('what the snapshot protects', () {
    test('renaming a customer does not rewrite an issued invoice', () async {
      final Customer customer = await fullCustomer();
      final created = await harness.invoices.create(harness.draft(customer.id));
      final Invoice issued = await harness.invoices.issue(created.invoice.id);

      // Every field with legal weight, changed at once — the shape a real
      // correction takes when a business's registration details are fixed.
      await harness.customers.update(
        customer.id,
        const CustomerDraft(
          fullName: 'مریم احمدی‌نژاد',
          companyName: 'کارگاه تازه',
          nationalId: '0084575948',
          address: 'تهران، خیابان انقلاب، پلاک ۲۰',
        ),
      );

      final InvoiceDetail detail = (await harness.invoices.findDetail(
        issued.id,
      ))!;

      // The document says what it said when it was issued.
      expect(detail.party.fullName, 'مریم احمدی');
      expect(detail.party.companyName, 'کارگاه نمونه');
      expect(detail.party.nationalId, '0079542311');
      expect(detail.party.address, 'تهران، خیابان ولیعصر، پلاک ۱۰');

      // And the live record is still available beside it, unchanged in the
      // other direction: this is who the customer is now, which is who to
      // contact and where a "go to customer" action leads.
      expect(detail.customer.fullName, 'مریم احمدی‌نژاد');
      expect(detail.customer.nationalId, '0084575948');
    });

    test('a draft still follows the live record', () async {
      final Customer customer = await fullCustomer();
      final created = await harness.invoices.create(harness.draft(customer.id));

      await harness.customers.update(
        customer.id,
        const CustomerDraft(fullName: 'مریم احمدی‌نژاد'),
      );

      final InvoiceDetail detail = (await harness.invoices.findDetail(
        created.invoice.id,
      ))!;
      expect(detail.party.fullName, 'مریم احمدی‌نژاد');
    });

    test('the mobile number is not frozen, deliberately', () async {
      // Contact detail rather than document content. An invoice reprinted next
      // year should reach the customer on the number they have now, not the
      // one they had then — which is why the mobile is the one field of the
      // record the snapshot leaves out.
      final Customer customer = await fullCustomer();
      final created = await harness.invoices.create(harness.draft(customer.id));
      final Invoice issued = await harness.invoices.issue(created.invoice.id);

      await harness.customers.update(
        customer.id,
        const CustomerDraft(fullName: 'مریم احمدی', mobile: '09121112233'),
      );

      final InvoiceDetail detail = (await harness.invoices.findDetail(
        issued.id,
      ))!;
      expect(detail.customer.mobile, '09121112233');
    });
  });

  group('an invoice issued before schema v3', () {
    /// The row a migrated database holds: issued, numbered, and with every
    /// snapshot column null. The migration writes nothing into them — it
    /// cannot know what the customer record said on the day that document was
    /// printed, and putting today's values in would look like a snapshot while
    /// being exactly the live join it replaces.
    Future<String> insertPreV3Invoice(String customerId) async {
      final row = await harness.db
          .into(harness.db.invoices)
          .insertReturning(
            InvoicesCompanion.insert(
              number: const Value<String>('INV-1404-0001'),
              numberYear: const Value<int>(1404),
              numberSequence: const Value<int>(1),
              customerId: customerId,
              issueDate: DateTime.utc(2025, 8, 24).millisecondsSinceEpoch,
              status: InvoiceStatus.unpaid,
              grandTotalRial: const Value<int>(12000000),
            ),
          );
      return row.id;
    }

    test('falls back to the live customer rather than showing blank', () async {
      final Customer customer = await fullCustomer();
      final String id = await insertPreV3Invoice(customer.id);

      final InvoiceDetail detail = (await harness.invoices.findDetail(id))!;

      expect(detail.invoice.customerSnapshot, isNull);
      // The behaviour those invoices already had, unchanged. Blank fields on a
      // historical document would be a regression introduced by the feature
      // meant to protect them.
      expect(detail.party.fullName, 'مریم احمدی');
      expect(detail.party.nationalId, '0079542311');
      expect(detail.party.address, 'تهران، خیابان ولیعصر، پلاک ۱۰');
    });

    test('and follows the live record when it changes', () async {
      // Stated rather than left implied: for these invoices the pre-v3
      // behaviour continues in full, including the part of it D-052 calls a
      // defect. Nothing can be done about it — there is no history to recover
      // — and pretending otherwise by freezing today's values would be worse.
      final Customer customer = await fullCustomer();
      final String id = await insertPreV3Invoice(customer.id);

      await harness.customers.update(
        customer.id,
        const CustomerDraft(fullName: 'مریم احمدی‌نژاد'),
      );

      final InvoiceDetail detail = (await harness.invoices.findDetail(id))!;
      expect(detail.party.fullName, 'مریم احمدی‌نژاد');
    });
  });

  group('the list shows the name the document states', () {
    test('an issued row keeps its name, a draft row follows', () async {
      final Customer customer = await fullCustomer();

      final issuedDraft = await harness.invoices.create(
        harness.draft(customer.id),
      );
      await harness.invoices.issue(issuedDraft.invoice.id);
      final stillDraft = await harness.invoices.create(
        harness.draft(customer.id),
      );

      await harness.customers.update(
        customer.id,
        const CustomerDraft(fullName: 'مریم احمدی‌نژاد'),
      );

      final List<InvoiceListItem> items = await harness.invoices
          .watchList()
          .first;
      final Map<String, InvoiceListItem> byId = <String, InvoiceListItem>{
        for (final InvoiceListItem item in items) item.invoice.id: item,
      };

      // The join still resolves the live name -- that is what the query is for
      // -- and the rule that prefers the snapshot lives in one getter, not in
      // the query and not in the widget.
      expect(byId[issuedDraft.invoice.id]!.liveCustomerName, 'مریم احمدی‌نژاد');
      expect(byId[issuedDraft.invoice.id]!.customerName, 'مریم احمدی');
      expect(byId[stillDraft.invoice.id]!.customerName, 'مریم احمدی‌نژاد');
    });
  });
}
