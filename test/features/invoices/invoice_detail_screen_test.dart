import 'package:factorino/core/formatting/jalali_display.dart';
import 'package:factorino/core/formatting/number_display.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/utils/clock.dart';
import 'package:factorino/core/widgets/app_table.dart';
import 'package:factorino/core/widgets/empty_state.dart';
import 'package:factorino/core/widgets/skeleton.dart';
import 'package:factorino/core/widgets/status_badge.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/customer_snapshot.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_detail.dart';
import 'package:factorino/data/models/invoice_item.dart';
import 'package:factorino/data/models/invoice_list_item.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/models/payment.dart';
import 'package:factorino/data/models/payment_method.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/features/invoices/presentation/invoice_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/money_magnitudes.dart';
import '../screen_harness.dart';
import 'fake_invoice_repository.dart';

/// The invoice detail screen: the first read site for everything schema v4
/// stored, and the first screen that has to make D-052's snapshot-versus-record
/// distinction visible.
///
/// Run at **all three tiers** wherever the layout differs, per D-057 — the rule
/// that exists because a phone-only pass let a desktop overflow through a phase
/// close.
void main() {
  final DateTime now = DateTime.utc(2026, 8, 24, 6);
  final DateTime issued = DateTime.utc(2026, 8, 20, 6);

  Customer customer({
    String fullName = 'مریم احمدی',
    String? nationalId = '0012345678',
    String? mobile = '09121234567',
  }) => Customer(
    id: 'c1',
    fullName: fullName,
    mobile: mobile,
    nationalId: nationalId,
    createdAt: issued,
    updatedAt: issued,
  );

  InvoiceItem line({
    String id = 'l1',
    int position = 0,
    String title = 'طراحی وب‌سایت',
    int unitPriceRial = 20000000,
    int quantityMilli = 1000,
    int discountRial = 0,
    int? grossRial = 20000000,
    int? allocatedRial = 0,
    int taxRateBp = 0,
    int? lineNetRial,
    int? lineTaxRial,
    int? lineTotalRial,
  }) {
    final int net = lineNetRial ?? (unitPriceRial - discountRial);
    return InvoiceItem(
      id: id,
      invoiceId: 'i1',
      position: position,
      title: title,
      unit: 'عدد',
      unitPrice: Money.rial(unitPriceRial),
      quantityMilli: quantityMilli,
      discount: Money.rial(discountRial),
      resolvedTaxRateBp: taxRateBp,
      gross: grossRial == null ? null : Money.rial(grossRial),
      allocatedInvoiceDiscount: allocatedRial == null
          ? null
          : Money.rial(allocatedRial),
      lineNet: Money.rial(net),
      lineTax: Money.rial(lineTaxRial ?? 0),
      lineTotal: Money.rial(lineTotalRial ?? net + (lineTaxRial ?? 0)),
    );
  }

  InvoiceDetail detail({
    InvoiceStatus status = InvoiceStatus.unpaid,
    CustomerSnapshot? snapshot,
    Customer? live,
    bool customerIsDeleted = false,
    List<InvoiceItem>? items,
    List<Payment> payments = const <Payment>[],
    int? grossTotalRial = 20000000,
    int discountRial = 0,
    int grandTotalRial = 20000000,
    String? notes,
    DateTime? dueDate,
  }) => InvoiceDetail(
    invoice: Invoice(
      id: 'i1',
      number: status == InvoiceStatus.draft ? null : 'INV-1405-0001',
      numberYear: status == InvoiceStatus.draft ? null : 1405,
      numberSequence: status == InvoiceStatus.draft ? null : 1,
      customerId: 'c1',
      issueDate: issued,
      dueDate: dueDate,
      status: status,
      discount: Money.rial(discountRial),
      grossTotal: grossTotalRial == null ? null : Money.rial(grossTotalRial),
      subtotal: Money.rial(grandTotalRial),
      totalDiscount: Money.rial(discountRial),
      totalTax: Money.zero,
      roundingAdjustment: Money.zero,
      grandTotal: Money.rial(grandTotalRial),
      notes: notes,
      customerSnapshot: snapshot,
      createdAt: issued,
      updatedAt: issued,
    ),
    customer: live ?? customer(),
    items: items ?? <InvoiceItem>[line()],
    payments: payments,
    customerIsDeleted: customerIsDeleted,
  );

  Payment payment(int rial) => Payment(
    id: 'p1',
    invoiceId: 'i1',
    amount: Money.rial(rial),
    paidAt: issued,
    method: PaymentMethod.values.first,
    createdAt: issued,
    updatedAt: issued,
  );

  /// A phone's **width** with room to render the whole page.
  ///
  /// The tier is read from the width alone, so this is a phone in every way
  /// that matters to the layout — it just does not cut the page off at the
  /// first viewport. Content assertions use it so that "is this sentence on the
  /// page" is a question about the page rather than about scroll position;
  /// where the fold itself is the subject, a test says so and uses
  /// [kMobileSize].
  const Size tallPhone = Size(400, 2400);

  /// Pumps the screen over the real provider, overriding the **interface**
  /// rather than the implementation (D-032), so the widget, the provider and
  /// the view model are all the real ones.
  Future<AppStrings> pumpDetail(
    WidgetTester tester, {
    InvoiceDetail? view,
    FakeInvoiceRepository? repository,
    Size size = tallPhone,
    String id = 'i1',
  }) async {
    final FakeInvoiceRepository repo =
        repository ?? FakeInvoiceRepository(const <InvoiceListItem>[]);
    if (view != null) repo.details[view.invoice.id] = view;

    await pumpScreen(
      tester,
      InvoiceDetailScreen(invoiceId: id),
      overrides: <Override>[
        invoiceRepositoryProvider.overrideWithValue(repo),
        nowProvider.overrideWithValue(now),
      ],
      size: size,
    );
    await tester.pumpAndSettle();
    return stringsOf(tester, InvoiceDetailScreen);
  }

  group('states', () {
    testWidgets('a skeleton, not a spinner, while the invoice loads', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const InvoiceDetailScreen(invoiceId: 'i1'),
        overrides: <Override>[
          invoiceRepositoryProvider.overrideWithValue(
            FakeInvoiceRepository.pending(),
          ),
          nowProvider.overrideWithValue(now),
        ],
      );
      await tester.pump();

      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a missing invoice is said, not rendered empty', (
      WidgetTester tester,
    ) async {
      // A stale deep link, or the invoice deleted while the page was opening.
      // An empty document would read as an invoice with nothing on it.
      final AppStrings strings = await pumpDetail(tester, id: 'gone');

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(strings.invoiceDetailNotFoundTitle), findsOneWidget);
    });
  });

  group('the party is the document\'s, not the record\'s (D-052)', () {
    testWidgets('a renamed customer shows the snapshot and says why', (
      WidgetTester tester,
    ) async {
      // The defect this whole distinction exists to prevent, seen from the
      // screen: the document said «مریم احمدی», the customer is now «مریم
      // احمدی‌نژاد», and the invoice must keep saying what it said.
      final AppStrings strings = await pumpDetail(
        tester,
        view: detail(
          snapshot: CustomerSnapshot.of(customer()),
          live: customer(fullName: 'مریم احمدی‌نژاد'),
        ),
      );

      expect(find.text('مریم احمدی'), findsOneWidget);
      expect(find.text(strings.invoiceDetailPartyDiverged), findsOneWidget);
      // And the live name, so the user can still find them in the list --
      // labelled as the record, because neither name is wrong.
      expect(
        find.text(strings.invoiceDetailPartyRecordNow('مریم احمدی‌نژاد')),
        findsOneWidget,
      );
    });

    testWidgets('an unchanged customer gets no notice at all', (
      WidgetTester tester,
    ) async {
      // The ordinary case has to be silent, or the notice becomes furniture the
      // user skips on the one invoice where it matters.
      final AppStrings strings = await pumpDetail(
        tester,
        view: detail(snapshot: CustomerSnapshot.of(customer())),
      );

      expect(find.text(strings.invoiceDetailPartyDiverged), findsNothing);
      expect(find.text(strings.invoiceDetailPartyDraft), findsNothing);
      expect(find.text(strings.invoiceDetailPartyNoSnapshot), findsNothing);
      expect(find.text(strings.invoiceDetailCustomerDeleted), findsNothing);
    });

    testWidgets('a draft says it still follows the record', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpDetail(
        tester,
        view: detail(status: InvoiceStatus.draft),
      );

      expect(find.text(strings.invoiceDetailPartyDraft), findsOneWidget);
      // And it has no number to show, so the title says so rather than leaving
      // a gap (D-048).
      expect(
        find.text(strings.invoiceDetailTitle(strings.invoiceNumberPending)),
        findsOneWidget,
      );
    });

    testWidgets('an invoice issued before v3 admits it has no snapshot', (
      WidgetTester tester,
    ) async {
      // Nothing was backfilled and nothing will be (D-052): a snapshot invented
      // from today's row would look like history while being the live join it
      // replaces. So the screen shows the live record and says that is what it
      // is doing.
      final AppStrings strings = await pumpDetail(tester, view: detail());

      expect(find.text(strings.invoiceDetailPartyNoSnapshot), findsOneWidget);
      expect(find.text('مریم احمدی'), findsOneWidget);
    });

    testWidgets('a soft-deleted customer is said, and stacks with a rename', (
      WidgetTester tester,
    ) async {
      // Two separately actionable facts: which name is right, and why the
      // customer is not in the list. The sentence also restates the promise the
      // delete dialog made, at the moment the user would otherwise wonder
      // whether the invoice is broken.
      final AppStrings strings = await pumpDetail(
        tester,
        view: detail(
          snapshot: CustomerSnapshot.of(customer()),
          live: customer(fullName: 'مریم احمدی‌نژاد'),
          customerIsDeleted: true,
        ),
      );

      expect(find.text(strings.invoiceDetailCustomerDeleted), findsOneWidget);
      expect(find.text(strings.invoiceDetailPartyDiverged), findsOneWidget);
    });

    testWidgets('the mobile number comes from the live record', (
      WidgetTester tester,
    ) async {
      // Deliberately not part of the snapshot: contact detail rather than
      // document content, so a reprint next year reaches the number the
      // customer has now. The snapshot here carries no mobile at all -- there
      // is no field for one -- so a screen reading the party for it would show
      // «ثبت نشده» instead.
      await pumpDetail(
        tester,
        view: detail(
          snapshot: CustomerSnapshot.of(customer()),
          live: customer(mobile: '09129999999'),
        ),
      );

      // Through the formatter, not against a literal: it groups an Iranian
      // mobile and isolates the run so it cannot reorder inside RTL text (§9),
      // and a test asserting on raw digits would pass while the screen showed
      // something else.
      expect(find.text(formatMobileForDisplay('09129999999')), findsOneWidget);
    });

    testWidgets('«رفتن به مشتری» leads to the live record', (
      WidgetTester tester,
    ) async {
      // A snapshot is not a row and has nowhere to lead. This is the one place
      // on the screen `detail.customer` is the right answer.
      final AppStrings strings = await pumpDetail(
        tester,
        view: detail(snapshot: CustomerSnapshot.of(customer())),
      );

      await tester.tap(find.text(strings.invoiceDetailGoToCustomer));
      await tester.pumpAndSettle();
      expect(lastLocation, '/customers/c1');
    });
  });

  group('figures come from storage, and their absence is admitted', () {
    testWidgets('an unrecorded gross renders «ثبت‌نشده» in the summary', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpDetail(
        tester,
        view: detail(grossTotalRial: null),
      );

      expect(find.text(strings.invoiceFigureUnrecorded), findsWidgets);
      // And the sentence that keeps the admission from reading as a fault in
      // the invoice rather than a gap in what was stored about it.
      expect(
        find.text(strings.invoiceSummaryGrossUnrecordedNote),
        findsOneWidget,
      );
      // Never a zero. The grand total is real and is still shown.
      expect(find.textContaining(formatGroupedPersian(2000000)), findsWidgets);
    });

    testWidgets('an unrecorded line gross renders «ثبت‌نشده», never zero', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpDetail(
        tester,
        view: detail(
          items: <InvoiceItem>[line(grossRial: null, allocatedRial: null)],
        ),
        size: kDesktopSize,
      );

      // The desktop table has a مبلغ کل column, so the absence is a cell.
      expect(find.text(strings.invoiceFigureUnrecorded), findsWidgets);
    });

    testWidgets('an unrecorded share names which figure is missing', (
      WidgetTester tester,
    ) async {
      // Only where the invoice actually carries a discount: on those documents
      // the deduction is real on every line, and a line silently omitting it is
      // a line whose net cannot be reconciled against its gross.
      final AppStrings strings = await pumpDetail(
        tester,
        view: detail(
          discountRial: 1000000,
          grandTotalRial: 19000000,
          items: <InvoiceItem>[
            line(grossRial: null, allocatedRial: null, lineNetRial: 19000000),
          ],
        ),
      );

      expect(
        find.text(
          strings.invoiceLineLabelUnrecorded(
            strings.invoiceDetailInvoiceDiscountShareLabel,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a recorded share is shown as the figure it is', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpDetail(
        tester,
        view: detail(
          discountRial: 1000000,
          grandTotalRial: 19000000,
          items: <InvoiceItem>[
            line(allocatedRial: 1000000, lineNetRial: 19000000),
          ],
        ),
      );

      expect(
        find.text(
          strings.invoiceLineLabelInvoiceDiscountShare(
            formatGroupedPersian(100000),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a line with no deductions carries no detail lines', (
      WidgetTester tester,
    ) async {
      // A row of «تخفیف ۰» on every line of every invoice is noise a reader has
      // to dismiss to find the lines that do have one.
      final AppStrings strings = await pumpDetail(tester, view: detail());

      expect(
        find.text(strings.invoiceLineLabelDiscount(formatGroupedPersian(0))),
        findsNothing,
      );
    });

    testWidgets('an invoice with no lines says so', (
      WidgetTester tester,
    ) async {
      // The one case where a gross of zero is a real figure rather than a
      // missing one, which is why the v4 column is nullable at all (D-056).
      final AppStrings strings = await pumpDetail(
        tester,
        view: detail(
          items: const <InvoiceItem>[],
          grossTotalRial: 0,
          grandTotalRial: 0,
        ),
      );

      expect(find.text(strings.invoiceDetailNoLines), findsOneWidget);
      expect(find.text(strings.invoiceFigureUnrecorded), findsNothing);
    });
  });

  group('what is owed', () {
    testWidgets('paid and remaining are both shown', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpDetail(
        tester,
        view: detail(payments: <Payment>[payment(5000000)]),
      );

      expect(find.text(strings.invoiceDetailPaidLabel), findsOneWidget);
      expect(find.text(strings.invoiceDetailDueLabel), findsOneWidget);
      expect(find.textContaining(formatGroupedPersian(500000)), findsWidgets);
      expect(find.textContaining(formatGroupedPersian(1500000)), findsWidgets);
    });

    testWidgets('an overpayment is surfaced, not clamped away silently', (
      WidgetTester tester,
    ) async {
      // `amountDue` clamps at zero because an invoice cannot owe money, which
      // makes an overpayment invisible in the figure -- and it is usually a
      // data-entry error, so it is said.
      final AppStrings strings = await pumpDetail(
        tester,
        view: detail(payments: <Payment>[payment(25000000)]),
      );

      expect(find.text(strings.invoiceDetailOverpaidNote), findsOneWidget);
    });

    testWidgets('a status badge sits beside the title', (
      WidgetTester tester,
    ) async {
      // The one fact about an invoice that is not on the document: a printed
      // invoice does not say whether it has been paid.
      final AppStrings strings = await pumpDetail(
        tester,
        view: detail(
          status: InvoiceStatus.unpaid,
          dueDate: DateTime.utc(2026, 8, 1, 6),
        ),
      );

      expect(find.byType(StatusBadge), findsOneWidget);
      // Overdue is derived from the clock at display time, never stored -- a
      // stored `overdue` would be wrong the moment midnight passed.
      expect(find.text(strings.statusOverdue), findsOneWidget);
    });
  });

  group('the fold on a real phone', () {
    testWidgets('the first line is reachable without scrolling', (
      WidgetTester tester,
    ) async {
      // **At the device's real height, not a test-convenient one.** The page
      // first put the party card between the summary and the lines, and on a
      // 400 x 800 phone that pushed the first line off the bottom entirely —
      // D-044's finding about the customer record card, rediscovered on the one
      // screen whose purpose is to show the lines. A party card has no upper
      // bound on its height: five fields, up to three notices and a contact
      // block.
      //
      // Every other test on this screen uses a tall viewport so that content
      // assertions are about the page rather than about scroll position. This
      // one is the exception, and it is the exception on purpose: without it,
      // that ordering could regress and nothing would notice.
      await pumpDetail(
        tester,
        view: detail(
          snapshot: CustomerSnapshot.of(customer()),
          notes: 'تحویل تا پایان شهریور',
          dueDate: DateTime.utc(2026, 9, 20, 6),
        ),
        size: kMobileSize,
      );

      expect(find.text('طراحی وب‌سایت'), findsOneWidget);
    });
  });

  group('every tier, over the whole amount ladder (D-057)', () {
    // **Three tiers times four magnitudes, and both halves are the rule.** A
    // `RenderFlex` overflow fails each of these on its own, which is the whole
    // assertion. The defect that prompted D-057 was invisible on the one tier
    // that was checked *and* at the amounts the demo data happened to hold; a
    // sweep that fixed either variable would have missed it.
    for (final MapEntry<String, Size> tier in kAllTierSizes.entries) {
      for (final int value in kMoneyStressToman) {
        testWidgets('${tier.key} at $value toman', (WidgetTester tester) async {
          final int rial = value * 10;
          final AppStrings strings = await pumpDetail(
            tester,
            // The tier's real width, and a height that renders the whole page:
            // an off-screen widget is never laid out, so a page cut off at the
            // fold is a page whose lower half went unchecked.
            size: Size(tier.value.width, 2400),
            view: detail(
              snapshot: CustomerSnapshot.of(customer()),
              notes: 'تحویل تا پایان شهریور',
              dueDate: DateTime.utc(2026, 9, 20, 6),
              discountRial: rial ~/ 20,
              grossTotalRial: rial,
              grandTotalRial: rial,
              payments: <Payment>[payment(rial ~/ 3)],
              items: <InvoiceItem>[
                line(
                  unitPriceRial: rial,
                  grossRial: rial,
                  allocatedRial: rial ~/ 20,
                  lineNetRial: rial - rial ~/ 20,
                  taxRateBp: 900,
                  lineTaxRial: rial ~/ 10,
                ),
                line(
                  id: 'l2',
                  position: 1,
                  title: 'پشتیبانی ماهانه',
                  unitPriceRial: rial,
                  grossRial: rial,
                  discountRial: rial ~/ 40,
                  lineNetRial: rial - rial ~/ 40,
                ),
              ],
            ),
          );

          expect(find.text(strings.invoiceDetailPartySection), findsOneWidget);
          expect(find.text('طراحی وب‌سایت'), findsOneWidget);
          // Only the widest tier gets a table; the other two get cards, which
          // is a genuinely different layout rather than a squeezed one (§10).
          expect(
            find.byType(AppTableRow),
            tier.key == 'desktop' ? findsNWidgets(2) : findsNothing,
          );
        });
      }
    }
  });
}
