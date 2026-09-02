import 'package:factorino/core/formatting/jalali_display.dart';
import 'package:factorino/core/formatting/number_display.dart';
import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/theme/app_dimensions.dart';
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
import 'package:factorino/data/repositories/payment_repository.dart';
import 'package:factorino/features/invoices/presentation/invoice_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/money_magnitudes.dart';
import '../../support/text_fit.dart';
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

  Payment payment(
    int rial, {
    String id = 'p1',
    PaymentMethod method = PaymentMethod.cash,
    String? note,
  }) => Payment(
    id: id,
    invoiceId: 'i1',
    amount: Money.rial(rial),
    paidAt: issued,
    method: method,
    note: note,
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

  group('the document table is never crushed by what sits beside it', () {
    // **The defect this group exists for, reported on the Windows build.** The
    // desktop tier lays the lines out beside a `detailPanelWidth` panel, and
    // the three money columns in the table are fixed-width by D-037. The
    // arithmetic was never done for the composed width: 1240 content, less 96
    // of page padding, less the 320 panel and the 24 gap beside it, less 32 of
    // row padding, is **768** — and three columns at `tablePriceWidth` are 732
    // of it. The description and the quantity shared the remaining 36, so the
    // description was laid out at **21.6 pixels** and Persian rendered one
    // glyph per row, vertically.
    //
    // D-058 did the same sum and reached 1144, which is the *full* content
    // column. That is §10's own rule, missed in the file that quotes it: a
    // widget measured at its own full width has not been measured at the width
    // it is composed into.
    for (final MapEntry<String, Size> tier in kAllTierSizes.entries) {
      testWidgets('at ${tier.key}, with a real line title', (
        WidgetTester tester,
      ) async {
        await pumpDetail(
          tester,
          view: detail(
            status: InvoiceStatus.cancelled,
            payments: <Payment>[payment(5000000)],
            items: <InvoiceItem>[
              line(title: PersianFixtures.longLineTitle),
              line(id: 'l2', position: 1, title: PersianFixtures.longLineTitle),
            ],
          ),
          size: Size(tier.value.width, 2400),
        );

        expectNoCrushedText(tester, where: 'the invoice detail screen');
      });
    }

    testWidgets('the description keeps a readable column on desktop', (
      WidgetTester tester,
    ) async {
      // Stated as a width rather than only as "not crushed", because the
      // failure mode above is continuous: a column one word wide passes the
      // crushed-text check and is still not a column anybody can read.
      await pumpDetail(
        tester,
        view: detail(
          items: <InvoiceItem>[line(title: PersianFixtures.longLineTitle)],
        ),
        size: const Size(1400, 2400),
      );

      final Finder description = find.text(PersianFixtures.longLineTitle);
      expect(description, findsOneWidget);
      expect(
        tester.getSize(description).width,
        greaterThanOrEqualTo(AppLayout.tableMinTextWidth),
        reason:
            'the description is the primary content of a document line, and a '
            'primary column narrower than the secondary figures beside it is '
            'wrong on its face (AppLayout.tableMinTextWidth)',
      );
    });
  });

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

      // **The rule, not the shape.** This used to assert the bare «ثبت‌نشده»
      // on the grounds that "the desktop table has a مبلغ کل column, so the
      // absence is a cell" — which stopped being true when the table learned to
      // give that column up at the width it is actually composed into (D-065).
      // The rule D-055 states survives the change and is what is asserted now:
      // an unrecorded figure is admitted, never zeroed, and it keeps the label
      // saying *which* figure is missing — which the sentence form does more
      // plainly than the cell ever did.
      expect(
        find.text(
          strings.invoiceLineLabelUnrecorded(strings.invoiceLineColumnGross),
        ),
        findsWidgets,
      );
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

  group('payments (c)', () {
    /// A repository that records what it was asked to do and answers from a
    /// list, so a test can assert **what the screen sent** rather than what a
    /// database made of it. The real write is pinned at the repository, in
    /// `payment_repository_test.dart`, against a real database.
    late _FakePaymentRepository payments;

    setUp(() => payments = _FakePaymentRepository());

    Future<AppStrings> pumpWithPayments(
      WidgetTester tester, {
      required InvoiceDetail view,
      Size size = tallPhone,
    }) async {
      final FakeInvoiceRepository repo = FakeInvoiceRepository(
        const <InvoiceListItem>[],
      );
      repo.details[view.invoice.id] = view;
      payments.invoice = view.invoice;

      await pumpScreen(
        tester,
        const InvoiceDetailScreen(invoiceId: 'i1'),
        overrides: <Override>[
          invoiceRepositoryProvider.overrideWithValue(repo),
          paymentRepositoryProvider.overrideWithValue(payments),
          nowProvider.overrideWithValue(now),
        ],
        size: size,
      );
      await tester.pumpAndSettle();
      return stringsOf(tester, InvoiceDetailScreen);
    }

    testWidgets('an invoice with no payments says so', (
      WidgetTester tester,
    ) async {
      // A designed empty state rather than a blank region, which would read as
      // a section that failed to load (§10).
      final AppStrings strings = await pumpWithPayments(tester, view: detail());

      expect(find.text(strings.invoiceDetailPaymentsEmpty), findsOneWidget);
    });

    testWidgets('each payment shows its date, method, amount and note', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpWithPayments(
        tester,
        view: detail(
          payments: <Payment>[
            payment(5000000, method: PaymentMethod.cheque, note: 'چک ۱۲۳۴۵۶'),
          ],
        ),
      );

      expect(find.text(strings.paymentMethodCheque), findsOneWidget);
      expect(find.text('چک ۱۲۳۴۵۶'), findsOneWidget);
      expect(find.text(formatJalaliDate(issued)), findsWidgets);
      expect(find.textContaining(formatGroupedPersian(500000)), findsWidgets);
    });

    testWidgets('a draft says why it cannot take a payment', (
      WidgetTester tester,
    ) async {
      // The rule is the repository's — `PaymentNotAccepted` — and the screen
      // explains it rather than merely hiding the control. A user who arrives
      // at a draft and finds nothing has to guess.
      final AppStrings strings = await pumpWithPayments(
        tester,
        view: detail(status: InvoiceStatus.draft),
      );

      expect(
        find.text(strings.invoiceDetailPaymentsUnavailableDraft),
        findsOneWidget,
      );
      expect(find.text(strings.invoiceDetailRecordPayment), findsNothing);
    });

    testWidgets('a cancelled invoice says why too, in its own words', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpWithPayments(
        tester,
        view: detail(status: InvoiceStatus.cancelled),
      );

      expect(
        find.text(strings.invoiceDetailPaymentsUnavailableCancelled),
        findsOneWidget,
      );
      expect(find.text(strings.invoiceDetailRecordPayment), findsNothing);
    });

    testWidgets('the phone offers the action once, in the floating slot', (
      WidgetTester tester,
    ) async {
      // Two controls saying the same thing is one too many (§10), and the
      // invoice list already settled this: on mobile the floating button is on
      // screen, so the inline one is omitted.
      await pumpWithPayments(tester, view: detail(), size: kMobileSize);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('the wider tiers offer it once, inline', (
      WidgetTester tester,
    ) async {
      await pumpWithPayments(tester, view: detail(), size: kDesktopSize);

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('recording sends the repository what the sheet built', (
      WidgetTester tester,
    ) async {
      // The whole path: the inline button, the real sheet, the real controller,
      // and the draft that reached the repository. What the screen *sent* is
      // the assertion -- a screen that records a different payment from the one
      // typed is the defect.
      final AppStrings strings = await pumpWithPayments(
        tester,
        view: detail(payments: <Payment>[payment(5000000)]),
        size: kDesktopSize,
      );

      await tester.tap(find.text(strings.invoiceDetailRecordPayment));
      await tester.pumpAndSettle();

      // The sheet's own field, not its title: the title deliberately repeats
      // the button that opened it, so it is not what tells the two apart.
      expect(find.text(strings.paymentFieldAmount), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '۷۵۰۰۰۰');
      await tester.tap(find.text(strings.paymentMethodBankTransfer));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
      await tester.pumpAndSettle();

      expect(payments.recorded, hasLength(1));
      final (String id, PaymentDraft draft) = payments.recorded.single;
      expect(id, 'i1');
      // Typed in Persian digits and stored in Rial: 750,000 تومان.
      expect(draft.amount, Money.rial(7500000));
      expect(draft.method, PaymentMethod.bankTransfer);
    });

    testWidgets('the sheet offers the outstanding balance, and fills it', (
      WidgetTester tester,
    ) async {
      // `amountDue` is the aggregate's, passed in. The sheet computes nothing —
      // a second answer to "what is still owed" would eventually disagree with
      // the one on the card above it.
      final AppStrings strings = await pumpWithPayments(
        tester,
        view: detail(payments: <Payment>[payment(5000000)]),
        size: kDesktopSize,
      );

      await tester.tap(find.text(strings.invoiceDetailRecordPayment));
      await tester.pumpAndSettle();

      // 20,000,000 rial invoice less 5,000,000 paid = 1,500,000 تومان due.
      expect(
        find.text(
          strings.paymentAmountRemainingHelper(formatGroupedPersian(1500000)),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text(strings.paymentAmountFillRemaining));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
      await tester.pumpAndSettle();

      expect(payments.recorded.single.$2.amount, Money.rial(15000000));
    });

    testWidgets('paying over the balance warns, and still goes through', (
      WidgetTester tester,
    ) async {
      // A warning, not a refusal (D-027's principle applied to an input): the
      // repository accepts an overpayment because they happen, and it is
      // usually a data-entry error, so it is said before the write rather than
      // discovered on the invoice afterwards.
      final AppStrings strings = await pumpWithPayments(
        tester,
        view: detail(),
        size: kDesktopSize,
      );

      await tester.tap(find.text(strings.invoiceDetailRecordPayment));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '۹۰۰۰۰۰۰');
      await tester.pumpAndSettle();

      expect(find.text(strings.paymentAmountExceedsDue), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
      await tester.pumpAndSettle();
      expect(payments.recorded, hasLength(1));
    });

    testWidgets('a zero payment is refused at the field, not at the write', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpWithPayments(
        tester,
        view: detail(),
        size: kDesktopSize,
      );

      await tester.tap(find.text(strings.invoiceDetailRecordPayment));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '۰');
      await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
      await tester.pumpAndSettle();

      expect(find.text(strings.validationAmountPositive), findsOneWidget);
      expect(payments.recorded, isEmpty);
    });

    testWidgets('deleting asks first, and declining writes nothing', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpWithPayments(
        tester,
        view: detail(payments: <Payment>[payment(5000000)]),
        size: kDesktopSize,
      );

      await tester.tap(find.byTooltip(strings.paymentDeleteAction));
      await tester.pumpAndSettle();

      expect(find.text(strings.paymentDeleteTitle), findsOneWidget);
      // The amount being removed is named, so the confirmation is about this
      // payment rather than about payments in general.
      expect(
        find.text(strings.paymentDeleteBody(formatGroupedPersian(500000))),
        findsOneWidget,
      );

      await tester.tap(find.text(strings.actionCancel));
      await tester.pumpAndSettle();
      expect(payments.deleted, isEmpty);
    });

    testWidgets('confirming deletes that payment', (WidgetTester tester) async {
      final AppStrings strings = await pumpWithPayments(
        tester,
        view: detail(payments: <Payment>[payment(5000000)]),
        size: kDesktopSize,
      );

      await tester.tap(find.byTooltip(strings.paymentDeleteAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, strings.paymentDeleteAction),
      );
      await tester.pumpAndSettle();

      expect(payments.deleted, <String>['p1']);
    });

    testWidgets('it warns when the deletion takes the invoice out of paid', (
      WidgetTester tester,
    ) async {
      // The derived status is recomputed by the repository inside the delete's
      // own transaction (§6). This copy is a claim about what the user is about
      // to cause, not a second derivation of it — and it appears only where it
      // is true, because a warning shown every time is one nobody reads on the
      // occasion that matters.
      final AppStrings strings = await pumpWithPayments(
        tester,
        view: detail(
          status: InvoiceStatus.paid,
          payments: <Payment>[payment(20000000)],
        ),
        size: kDesktopSize,
      );

      await tester.tap(find.byTooltip(strings.paymentDeleteAction));
      await tester.pumpAndSettle();
      expect(find.text(strings.paymentDeleteStatusWarning), findsOneWidget);
    });

    testWidgets('and stays quiet when the invoice was never paid off', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpWithPayments(
        tester,
        view: detail(
          status: InvoiceStatus.partiallyPaid,
          payments: <Payment>[payment(5000000)],
        ),
        size: kDesktopSize,
      );

      await tester.tap(find.byTooltip(strings.paymentDeleteAction));
      await tester.pumpAndSettle();
      expect(find.text(strings.paymentDeleteStatusWarning), findsNothing);
    });

    testWidgets('a failed write is a Persian line, never an exception', (
      WidgetTester tester,
    ) async {
      // §7: no stack trace, no SQL, no raw exception string in front of a user.
      payments.failWrites = true;
      final AppStrings strings = await pumpWithPayments(
        tester,
        view: detail(payments: <Payment>[payment(5000000)]),
        size: kDesktopSize,
      );

      await tester.tap(find.byTooltip(strings.paymentDeleteAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, strings.paymentDeleteAction),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.paymentDeleteFailed), findsOneWidget);
    });
  });

  group('cancellation (d)', () {
    /// The same harness the payments group uses, so a cancelled invoice can be
    /// rendered with real payments on it.
    late _FakePaymentRepository payments;

    setUp(() => payments = _FakePaymentRepository());

    Future<(AppStrings, FakeInvoiceRepository)> pumpCancellable(
      WidgetTester tester, {
      required InvoiceDetail view,
      Size size = tallPhone,
      bool failWrites = false,
    }) async {
      final FakeInvoiceRepository repo = FakeInvoiceRepository(
        const <InvoiceListItem>[],
      );
      repo.details[view.invoice.id] = view;
      repo.failWrites = failWrites;
      // The same switch covers the draft delete: 'writes fail' is one condition.
      repo.failDelete = failWrites;
      payments.invoice = view.invoice;

      await pumpScreen(
        tester,
        const InvoiceDetailScreen(invoiceId: 'i1'),
        overrides: <Override>[
          invoiceRepositoryProvider.overrideWithValue(repo),
          paymentRepositoryProvider.overrideWithValue(payments),
          nowProvider.overrideWithValue(now),
        ],
        size: size,
      );
      await tester.pumpAndSettle();
      return (stringsOf(tester, InvoiceDetailScreen), repo);
    }

    Future<AppStrings> openDialog(
      WidgetTester tester, {
      required InvoiceDetail view,
      Size size = tallPhone,
    }) async {
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: view,
        size: size,
      );
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.invoiceCancelAction));
      await tester.pumpAndSettle();
      return strings;
    }

    testWidgets('a settled invoice withdraws the floating action and says why', (
      WidgetTester tester,
    ) async {
      // **Finding 5.** A fully paid invoice went on offering «ثبت پرداخت» as
      // the page's primary action, which is wrong twice over: nothing is owed,
      // and the floating slot is for the thing the user came to do.
      //
      // Withdrawing it silently is the mistake a draft's page made, so the card
      // says the invoice is settled — and it keeps the way in, because money
      // arriving twice is a fact the record has to be able to hold.
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(
          status: InvoiceStatus.paid,
          payments: <Payment>[payment(20000000)],
        ),
      );

      expect(
        find.widgetWithText(
          FloatingActionButton,
          strings.invoiceDetailRecordPayment,
        ),
        findsNothing,
        reason: 'nothing is owed, so this is not the page\'s primary action',
      );
      expect(
        find.text(strings.invoiceDetailPaymentsSettled),
        findsOneWidget,
        reason: 'a control that vanishes without a word reads as broken',
      );
      expect(
        find.widgetWithText(FilledButton, strings.invoiceDetailRecordPayment),
        findsOneWidget,
        reason:
            'an overpayment must stay recordable: money really does arrive '
            'twice, and the record has to be able to hold that',
      );
    });

    testWidgets('a partly paid invoice keeps the floating action', (
      WidgetTester tester,
    ) async {
      // The boundary: something is still owed, so the primary action stands.
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(
          status: InvoiceStatus.partiallyPaid,
          payments: <Payment>[payment(5000000)],
        ),
      );

      expect(
        find.widgetWithText(
          FloatingActionButton,
          strings.invoiceDetailRecordPayment,
        ),
        findsOneWidget,
      );
      expect(find.text(strings.invoiceDetailPaymentsSettled), findsNothing);
    });

    testWidgets('a draft offers issuing, in the slot the phone puts it', (
      WidgetTester tester,
    ) async {
      // **The gap reported from the phone, 2026-09-02.** Issuing lived only on
      // the editor screen, at creation time, so a saved draft had no way
      // forward at all — and because a draft correctly refuses payments and
      // cancellation, the whole page read as broken rather than incomplete.
      //
      // On a phone the floating slot is the one place a primary action costs no
      // height (§10), and on a draft it was empty: `acceptsPayments` is false.
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.draft),
      );

      expect(
        find.widgetWithText(FloatingActionButton, strings.invoiceIssueAction),
        findsOneWidget,
        reason: 'a draft must offer the one action that moves it forward',
      );
      expect(
        find.text(strings.invoiceDetailRecordPayment),
        findsNothing,
        reason: 'and not the one it correctly refuses',
      );
    });

    testWidgets('an issued invoice keeps the payment action, not issuing', (
      WidgetTester tester,
    ) async {
      // The two states are mutually exclusive by construction: `isEditable` and
      // `acceptsPayments` cannot both be true. This pins that the new branch
      // did not displace the old one.
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(),
      );

      expect(
        find.widgetWithText(
          FloatingActionButton,
          strings.invoiceDetailRecordPayment,
        ),
        findsOneWidget,
      );
      expect(find.text(strings.invoiceIssueAction), findsNothing);
    });

    testWidgets('issuing asks first, names what it costs, and reports the '
        'number', (WidgetTester tester) async {
      final (
        AppStrings strings,
        FakeInvoiceRepository repo,
      ) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.draft),
      );

      await tester.tap(find.text(strings.invoiceIssueAction));
      await tester.pumpAndSettle();

      // The editor's own copy, reused verbatim: the consequences do not depend
      // on where issuing was started from, and two wordings of one irreversible
      // act is how they drift apart.
      expect(find.text(strings.invoiceIssueConfirmTitle), findsOneWidget);
      expect(find.text(strings.invoiceIssueConfirmBody), findsOneWidget);
      expect(
        strings.invoiceIssueConfirmBody,
        allOf(contains('شماره'), contains('ویرایش')),
        reason:
            'the copy must name both irreversible consequences — the number is '
            'spent (D-013) and editing ends (§6)',
      );

      await tester.tap(
        find.widgetWithText(FilledButton, strings.invoiceIssueConfirmAction),
      );
      await tester.pumpAndSettle();

      expect(repo.issuedIds, <String>['i1']);
      expect(
        find.textContaining(FakeInvoiceRepository.issuedNumber),
        findsWidgets,
        reason:
            'the allocated number is the one fact that did not exist a moment '
            'ago, and the thing the user quotes to their customer',
      );
    });

    testWidgets('declining to issue writes nothing', (
      WidgetTester tester,
    ) async {
      final (
        AppStrings strings,
        FakeInvoiceRepository repo,
      ) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.draft),
      );

      await tester.tap(find.text(strings.invoiceIssueAction));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, strings.actionCancel));
      await tester.pumpAndSettle();

      expect(repo.issuedIds, isEmpty);
    });

    testWidgets('a failed issue says so and the draft stays a draft', (
      WidgetTester tester,
    ) async {
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.draft),
        failWrites: true,
      );

      await tester.tap(find.text(strings.invoiceIssueAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, strings.invoiceIssueConfirmAction),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.invoiceSaveFailed), findsOneWidget);
    });

    testWidgets('the wider tiers offer issuing inline, not floating', (
      WidgetTester tester,
    ) async {
      // D-060's shape, reused: the phone puts the primary action in the
      // floating slot and the wider tiers put it inline, so the two are never
      // on screen together.
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.draft),
        size: const Size(1400, 1200),
      );

      expect(
        find.widgetWithText(FilledButton, strings.invoiceIssueAction),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(FloatingActionButton, strings.invoiceIssueAction),
        findsNothing,
      );
    });

    testWidgets('a draft offers deletion, and an issued invoice does not', (
      WidgetTester tester,
    ) async {
      // **Known issue 27.** `softDeleteDraft` existed and was tested from
      // Phase 4 and nothing called it, so a draft made by mistake could not be
      // removed at all — the application unable to undo its own most common
      // action. The two ways out are mutually exclusive by §6: a draft is
      // deleted, an issued invoice is cancelled.
      final (AppStrings draftStrings, _) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.draft),
      );
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text(draftStrings.invoiceDeleteDraftAction), findsOneWidget);
      expect(find.text(draftStrings.invoiceCancelAction), findsNothing);

      final (AppStrings issuedStrings, _) = await pumpCancellable(
        tester,
        view: detail(),
      );
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text(issuedStrings.invoiceDeleteDraftAction), findsNothing);
      expect(find.text(issuedStrings.invoiceCancelAction), findsOneWidget);
    });

    testWidgets('the delete confirmation says what it does not cost', (
      WidgetTester tester,
    ) async {
      // The two facts the user cannot see: no number was spent (D-048) and
      // nothing reached the customer. A confirmation that decays into
      // «مطمئن هستید؟» is one people learn to dismiss.
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.draft),
      );
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.invoiceDeleteDraftAction));
      await tester.pumpAndSettle();

      expect(find.text(strings.invoiceDeleteDraftTitle), findsOneWidget);
      expect(find.text(strings.invoiceDeleteDraftBody), findsOneWidget);
      expect(
        strings.invoiceDeleteDraftBody,
        allOf(contains('شماره'), contains('مشتری')),
        reason:
            'the copy must name the two things deleting does NOT cost, or it '
            'is a bare confirmation',
      );
    });

    testWidgets('confirming deletes the draft and leaves for the list', (
      WidgetTester tester,
    ) async {
      final (
        AppStrings strings,
        FakeInvoiceRepository repo,
      ) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.draft),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.invoiceDeleteDraftAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, strings.invoiceDeleteDraftAction),
      );
      await tester.pumpAndSettle();

      expect(repo.deletedDrafts, <String>['i1']);
      expect(find.text(strings.invoiceDeleteDraftSuccess), findsOneWidget);
      // **Unlike cancelling, which stays.** A deleted draft's page has nothing
      // left to show.
      expect(lastLocation, '/invoices');
    });

    testWidgets('declining deletes nothing', (WidgetTester tester) async {
      final (
        AppStrings strings,
        FakeInvoiceRepository repo,
      ) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.draft),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.invoiceDeleteDraftAction));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, strings.actionCancel));
      await tester.pumpAndSettle();

      expect(repo.deletedDrafts, isEmpty);
      expect(lastLocation, '/');
    });

    testWidgets('a failed delete says so and stays on the page', (
      WidgetTester tester,
    ) async {
      // Staying put is what lets the user try again; navigating away on a
      // failure would leave them on the list wondering whether it worked.
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.draft),
        failWrites: true,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.invoiceDeleteDraftAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, strings.invoiceDeleteDraftAction),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.invoiceDeleteDraftFailed), findsOneWidget);
      expect(lastLocation, '/');
    });

    testWidgets('an issued invoice offers cancellation', (
      WidgetTester tester,
    ) async {
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text(strings.invoiceCancelAction), findsOneWidget);
    });

    testWidgets('a draft is not offered it: a draft is deleted, not voided', (
      WidgetTester tester,
    ) async {
      // Absent, not disabled (D-021). A draft has no number and nobody has seen
      // it; marking it «باطل شده» would void a document that never existed, and
      // the screen must not offer two ways out of one state.
      //
      // **The menu itself is now present**, which changed in (d): it carries
      // the PDF export, which every invoice is offered including a draft
      // (D-075 — a draft prints, marked with its band). So the assertion is
      // about the cancel ITEM rather than about the menu button. Asserting the
      // button's absence would now pass only by accident of what else the menu
      // happens to hold.
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.draft),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text(strings.invoiceCancelAction), findsNothing);
      expect(
        find.text(strings.invoiceDocumentExportAction),
        findsOneWidget,
        reason: 'a draft still prints, so the export is offered on it',
      );
    });

    testWidgets('an invoice already cancelled is not offered it either', (
      WidgetTester tester,
    ) async {
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.cancelled),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text(strings.invoiceCancelAction), findsNothing);
      expect(
        find.text(strings.invoiceDocumentExportAction),
        findsOneWidget,
        reason:
            'a cancelled invoice is still a document (D-061), and a user who '
            'could not produce a PDF of what is on their screen would ask why',
      );
    });

    testWidgets('the confirmation says what cancelling does not do', (
      WidgetTester tester,
    ) async {
      // **The copy is pinned, exactly as the issue confirmation's is.** Three
      // consequences the button cannot show and the user cannot take back: the
      // record is kept rather than removed, the number stays spent (D-013), and
      // editing is still not the way back (§6). A confirmation that decays into
      // «مطمئن هستید؟» is a dialog people learn to dismiss.
      final AppStrings strings = await openDialog(tester, view: detail());

      expect(find.text(strings.invoiceCancelTitle), findsOneWidget);
      expect(find.text(strings.invoiceCancelBody), findsOneWidget);
      expect(
        strings.invoiceCancelBody,
        allOf(contains('حذف نمی‌شود'), contains('شماره'), contains('ویرایش')),
        reason:
            'the Persian copy must say the record is kept, the number stays '
            'spent and editing is not the way back',
      );
    });

    testWidgets('and, where there are payments, that it refunds nothing', (
      WidgetTester tester,
    ) async {
      // The sentence (d) exists for. Cancelling never touches the payments
      // table (D-061), and a user cancelling a part-paid invoice has to be told
      // that **before** committing rather than discover it on the page after.
      final AppStrings strings = await openDialog(
        tester,
        view: detail(
          status: InvoiceStatus.partiallyPaid,
          payments: <Payment>[payment(5000000)],
        ),
      );

      expect(
        find.text(
          strings.invoiceCancelPaymentsNote(formatGroupedPersian(500000)),
        ),
        findsOneWidget,
      );
      expect(
        strings.invoiceCancelPaymentsNote('X'),
        allOf(contains('حذف نمی‌شود'), contains('بازگردانده نمی‌شود')),
        reason:
            'both halves are the claim: the payment is neither erased from the '
            'record nor returned to the customer',
      );
    });

    testWidgets('an invoice with no payments gets no payments sentence', (
      WidgetTester tester,
    ) async {
      // D-060's rule: a warning printed on every cancellation is one nobody
      // reads on the cancellation where it matters.
      final AppStrings strings = await openDialog(tester, view: detail());

      expect(find.textContaining('بازگردانده نمی‌شود'), findsNothing);
      expect(find.text(strings.invoiceCancelBody), findsOneWidget);
    });

    testWidgets('declining writes nothing at all', (WidgetTester tester) async {
      final (AppStrings strings, FakeInvoiceRepository repo) =
          await pumpCancellable(tester, view: detail());

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.invoiceCancelAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.actionCancel));
      await tester.pumpAndSettle();

      expect(repo.cancelledIds, isEmpty);
    });

    testWidgets('confirming cancels it, and says the payments stand', (
      WidgetTester tester,
    ) async {
      final (
        AppStrings strings,
        FakeInvoiceRepository repo,
      ) = await pumpCancellable(
        tester,
        view: detail(payments: <Payment>[payment(5000000)]),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.invoiceCancelAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, strings.invoiceCancelAction),
      );
      await tester.pumpAndSettle();

      expect(repo.cancelledIds, <String>['i1']);
      expect(find.text(strings.invoiceCancelSuccess), findsOneWidget);
    });

    testWidgets('a failed write is a Persian line, never an exception', (
      WidgetTester tester,
    ) async {
      // §7: no stack trace, no SQL, no raw exception string in front of a user.
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(),
        failWrites: true,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.invoiceCancelAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, strings.invoiceCancelAction),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.invoiceCancelFailed), findsOneWidget);
    });

    testWidgets('a cancelled invoice carrying payments says so plainly', (
      WidgetTester tester,
    ) async {
      // Requirement two of three. A void document showing «پرداخت‌شده:
      // ۵۰۰٬۰۰۰ تومان» with no explanation reads as a fault in the software
      // rather than as a fact about the record.
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(
          status: InvoiceStatus.cancelled,
          payments: <Payment>[payment(5000000)],
        ),
      );

      expect(
        find.text(strings.invoiceDetailCancelledPaymentsNote),
        findsOneWidget,
      );
    });

    testWidgets('a cancelled invoice with no payments does not say it', (
      WidgetTester tester,
    ) async {
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.cancelled),
      );

      expect(
        find.text(strings.invoiceDetailCancelledPaymentsNote),
        findsNothing,
      );
    });

    testWidgets('the remaining balance is shown, and said not to be owed', (
      WidgetTester tester,
    ) async {
      // «مانده» is a real figure — it is what was never paid — but on a void
      // document it reads as money still owed, which is the one thing a
      // cancellation means it is not. Explained rather than hidden: removing
      // the row would leave the page silently missing a number every other
      // invoice shows.
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.cancelled),
      );

      expect(find.text(strings.invoiceDetailDueLabel), findsOneWidget);
      expect(find.text(strings.invoiceDetailCancelledDueNote), findsOneWidget);
    });

    testWidgets('and an ordinary invoice says nothing of the kind', (
      WidgetTester tester,
    ) async {
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(payments: <Payment>[payment(5000000)]),
      );

      expect(find.text(strings.invoiceDetailCancelledDueNote), findsNothing);
      expect(
        find.text(strings.invoiceDetailCancelledPaymentsNote),
        findsNothing,
      );
    });

    testWidgets('the refusal to record names the way forward', (
      WidgetTester tester,
    ) async {
      // The copy explains the refusal rather than only stating it. A payment
      // genuinely received against a cancelled invoice belongs on the invoice
      // that replaced it — the correction path §6 already prescribes.
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(status: InvoiceStatus.cancelled),
      );

      expect(
        find.text(strings.invoiceDetailPaymentsUnavailableCancelled),
        findsOneWidget,
      );
      expect(
        strings.invoiceDetailPaymentsUnavailableCancelled,
        contains('جایگزین'),
        reason: 'a refusal that names no alternative leaves the user stuck',
      );
    });

    testWidgets('deleting a payment off a cancelled invoice stays possible', (
      WidgetTester tester,
    ) async {
      // The other half of the ruling. Correcting a mis-entered receipt is a fix
      // to the money record, and the money record must be correctable whether
      // or not the document still stands — it does not resurrect the invoice
      // (`_recomputeStatus` returns early for `cancelled`, §6), and the copy
      // says so instead of promising a balance that would go up.
      final (AppStrings strings, _) = await pumpCancellable(
        tester,
        view: detail(
          status: InvoiceStatus.cancelled,
          payments: <Payment>[payment(5000000)],
        ),
        size: kDesktopSize,
      );

      await tester.tap(find.byTooltip(strings.paymentDeleteAction));
      await tester.pumpAndSettle();

      expect(
        find.text(
          strings.paymentDeleteBodyCancelled(formatGroupedPersian(500000)),
        ),
        findsOneWidget,
      );
      expect(
        find.text(strings.paymentDeleteBody(formatGroupedPersian(500000))),
        findsNothing,
        reason:
            'the ordinary wording promises a balance that would go up, and '
            'nothing is owed on a void document',
      );

      await tester.tap(
        find.widgetWithText(FilledButton, strings.paymentDeleteAction),
      );
      await tester.pumpAndSettle();
      expect(payments.deleted, <String>['p1']);
    });

    testWidgets('the fold: the cancelled notices do not push the lines off', (
      WidgetTester tester,
    ) async {
      // **The new copy lands in the summary card, which is above the lines on a
      // phone**, so it goes through the same 400 x 800 check that caught the
      // party card in (b) and the payments card in (c) — the §10 rule this
      // increment writes down. The cancel action itself is in the title row and
      // costs no height at all, which is why it is there.
      await pumpCancellable(
        tester,
        view: detail(
          status: InvoiceStatus.cancelled,
          snapshot: CustomerSnapshot.of(customer()),
          payments: <Payment>[payment(5000000)],
          notes: 'تحویل تا پایان شهریور',
          dueDate: DateTime.utc(2026, 9, 20, 6),
        ),
        size: kMobileSize,
      );

      expect(find.text('طراحی وب‌سایت'), findsOneWidget);
    });

    // **The dialog carries an amount, so it goes through the ladder** (D-057).
    // A confirmation is the narrowest surface in the app that prints money, and
    // the figure it prints is the one nobody can check afterwards.
    for (final MapEntry<String, Size> tier in kAllTierSizes.entries) {
      for (final int value in kMoneyStressToman) {
        testWidgets('the confirmation at ${tier.key}, $value toman', (
          WidgetTester tester,
        ) async {
          final int rial = value * 10;
          final AppStrings strings = await openDialog(
            tester,
            size: Size(tier.value.width, 2400),
            view: detail(
              status: InvoiceStatus.partiallyPaid,
              snapshot: CustomerSnapshot.of(customer()),
              grossTotalRial: rial,
              grandTotalRial: rial,
              payments: <Payment>[payment(rial ~/ 3)],
              items: <InvoiceItem>[
                line(unitPriceRial: rial, grossRial: rial, lineNetRial: rial),
              ],
            ),
          );

          expect(find.text(strings.invoiceCancelBody), findsOneWidget);
          expect(
            find.text(
              strings.invoiceCancelPaymentsNote(
                formatGroupedPersian(Money.rial(rial ~/ 3).toman),
              ),
            ),
            findsOneWidget,
          );
        });
      }
    }
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
      // The payments card did the same thing again when it arrived in (c) —
      // 182 logical pixels of height with nothing in it, between the summary
      // and the lines — which is how this test earned its keep a second time.
      // Both now sit below the lines, and on a phone the record action moves to
      // the floating slot so it stays reachable.
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

/// A [PaymentRepository] that records what it was asked to do.
///
/// Implements the interface rather than mocking it, so this stops compiling if
/// the contract moves — which is the notification a test should get, instead of
/// a green run against a signature nobody has any more.
///
/// **[invoice] is the invoice under test, handed in rather than invented.** The
/// real repository returns the row *as it stands after the write*, with the
/// derived status already recomputed inside the same transaction (§6) — and
/// that recomputation is the repository's own claim, pinned against a real
/// database in `payment_repository_test.dart`. A fake that made one up would be
/// asserting a second answer to it. The screen does not read this value at all:
/// it takes the invoice from the live detail query, which is why handing back
/// the unchanged row is enough here.
class _FakePaymentRepository implements PaymentRepository {
  /// Set by the harness from the fixture, so nothing here is fabricated.
  late Invoice invoice;

  /// Every `(invoiceId, draft)` handed to [record], in order.
  final List<(String, PaymentDraft)> recorded = <(String, PaymentDraft)>[];

  /// The payment ids passed to [softDelete], in order.
  final List<String> deleted = <String>[];

  /// Turns both writes into failures, for the «ممکن نشد» path (§7).
  bool failWrites = false;

  @override
  Future<PaymentResult> record(String invoiceId, PaymentDraft draft) async {
    if (failWrites) throw StateError('write refused by the fake');
    recorded.add((invoiceId, draft));
    return PaymentResult(
      invoice: invoice,
      payment: Payment(
        id: 'written',
        invoiceId: invoiceId,
        amount: draft.amount,
        paidAt: draft.paidAt,
        method: draft.method,
        note: draft.note,
        createdAt: draft.paidAt,
        updatedAt: draft.paidAt,
      ),
    );
  }

  @override
  Future<PaymentResult> softDelete(String paymentId) async {
    if (failWrites) throw StateError('write refused by the fake');
    deleted.add(paymentId);
    return PaymentResult(invoice: invoice, payment: null);
  }

  @override
  Stream<List<Payment>> watchForInvoice(String invoiceId) =>
      Stream<List<Payment>>.value(const <Payment>[]);

  @override
  Future<List<Payment>> findForInvoice(String invoiceId) async =>
      const <Payment>[];

  @override
  Future<int> totalPaidRial(String invoiceId) async => 0;
}
