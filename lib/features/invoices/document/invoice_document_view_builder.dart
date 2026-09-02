import '../../../core/formatting/jalali_display.dart';
import '../../../core/formatting/number_display.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/localization/month_names.dart';
import '../../../core/money/money.dart';
import '../../../core/pdf/document_text.dart';
import '../../../data/models/customer_snapshot.dart';
import '../../../data/models/invoice.dart';
import '../../../data/models/invoice_detail.dart';
import '../../../data/models/invoice_item.dart';
import '../../../data/models/invoice_status.dart';
import '../../../data/models/seller_identity.dart';
import '../domain/invoice_party_view.dart';
import '../domain/invoice_summary_figures.dart';
import '../domain/invoice_status_view.dart';
import 'invoice_document_view.dart';

/// Turns a stored invoice into the fully-computed, already-formatted view the
/// renderer receives (§12).
///
/// **Everything that could be a decision happens here, once.** Which figure is
/// printed, which row is omitted, which date format, which digits, whether the
/// party note appears — all of it resolved before the renderer sees anything,
/// so the layout layer has nothing to decide and therefore nothing to get
/// wrong differently from the screen.
///
/// **It computes nothing.** Every amount comes from the stored invoice or from
/// [InvoiceSummaryFigures], which is itself a rearrangement of figures
/// `core/money/` produced. There is no arithmetic in this file and there must
/// not be: `single_calculation_path_test.dart` fails the build over it.
InvoiceDocumentView buildInvoiceDocumentView({
  required InvoiceDetail detail,
  required AppStrings strings,
  required DocumentTextBoundary boundary,
  SellerIdentity seller = SellerIdentity.none,
}) {
  final Invoice invoice = detail.invoice;
  final InvoiceSummaryFigures figures = InvoiceSummaryFigures.ofStored(invoice);

  DocumentText text(String raw) => boundary(raw);

  DocumentAmount toman(Money amount) => DocumentAmount(
    digits: text(formatGroupedPersian(amount.toman)),
    unit: text(strings.unitToman),
  );

  return InvoiceDocumentView(
    title: text(strings.invoiceDocumentTitle),
    // A draft is marked, not withheld (D-075). پیش‌فاکتور is an ordinary
    // document in this market, and refusing to print one would push the user
    // to issue and cancel an invoice, spending a number permanently.
    // **One slot, two markings, and they cannot co-occur** (D-085). A draft was
    // never cancelled and a cancelled invoice was never a draft.
    banner: switch (invoice.status) {
      InvoiceStatus.draft => text(strings.invoiceDocumentDraftBanner),
      InvoiceStatus.cancelled => text(strings.invoiceDocumentCancelledBanner),
      _ => null,
    },
    // **The stored status, not a recomputation** (§6). It is derived from the
    // payments and persisted by the repository; re-deriving it here would give
    // the page its own opinion, and a second opinion about whether a customer
    // has paid is the worst possible place to find one.
    //
    // Absent on a draft (nothing to state) and on a cancelled invoice (where
    // «پرداخت نشده» beside the void band reads as a demand to pay it).
    paymentStatus: switch (invoice.status) {
      InvoiceStatus.draft || InvoiceStatus.cancelled => null,
      final InvoiceStatus status => DocumentField(
        label: text(strings.invoiceDocumentStatusLabel),
        value: text(
          invoiceStatusLabel(invoiceStatusViewOfStored(status), strings),
        ),
      ),
    },
    number: DocumentField(
      label: text(strings.invoiceDocumentNumberLabel),
      // The isolated form, straight from the screen layer's own helper --
      // which is exactly the string that prints nine of ten digits if it
      // reaches the shaper unstripped. The boundary is what makes reusing it
      // safe rather than reckless.
      value: text(invoiceNumberFor(invoice, strings)),
    ),
    issueDate: DocumentField(
      label: text(strings.invoiceDetailIssueDate),
      value: text(
        formatJalaliDateLong(
          invoice.issueDate,
          monthNames: jalaliMonthNames(strings),
        ),
      ),
    ),
    dueDate: invoice.dueDate == null
        ? null
        : DocumentField(
            label: text(strings.invoiceDetailDueDate),
            value: text(
              formatJalaliDateLong(
                invoice.dueDate!,
                monthNames: jalaliMonthNames(strings),
              ),
            ),
          ),
    // Null when the user has given no business name -- the state every
    // database is in until they fill the settings form in (D-077). Decided
    // here, once, like every other decision on this page.
    seller: _seller(seller, strings, text),
    party: _party(detail, strings, text),
    lineColumns: <DocumentText>[
      text(strings.invoiceDocumentColumnRow),
      text(strings.invoiceLineColumnDescription),
      text(strings.invoiceLineColumnQuantity),
      text(strings.invoiceLineColumnUnitPrice),
      text(strings.invoiceLineColumnGross),
    ],
    lines: <InvoiceDocumentLine>[
      for (int i = 0; i < detail.items.length; i++)
        _line(detail.items[i], i, strings, text, toman),
    ],
    totals: _totals(figures, strings, text, toman),
    grandTotal: DocumentAmountRow(
      label: text(strings.invoiceSummaryGrandTotal),
      amount: toman(figures.grandTotal),
    ),
    notes: invoice.notes == null || invoice.notes!.isEmpty
        ? null
        : text(invoice.notes!),
  );
}

/// The number as the screen states it: isolated when real, the Persian
/// placeholder when the invoice is an unissued draft.
///
/// Re-exported here under its own name so the import above reads as what it
/// is — the single place that decides how a missing number is shown, reused
/// rather than re-decided.
String invoiceNumberFor(Invoice invoice, AppStrings strings) =>
    invoice.number == null
    ? strings.invoiceNumberPending
    : isolate(invoice.number!);

/// The seller block, or null.
///
/// **Null when there is no business name**, which is not the same test as
/// "nothing stored" and the difference is the whole of the ruling. An identity
/// carrying a code and no name has something in it and still cannot head a
/// block: a heading over an economic ID alone identifies nobody, and on a
/// printed page it reads as a document that failed rather than as one that was
/// never filled in. The settings form refuses to save that combination; this
/// checks anyway, because a value that arrived before the rule existed -- or
/// through a restored backup -- is not the document layer to assume away.
///
/// **An empty field is omitted, never printed blank.** The same rule as the
/// buyer block below, for the same reason, and the reason it has to be a rule
/// rather than a habit is that a labelled empty line looks exactly like data
/// that was lost on the way to the page.
///
/// **No `sourceNote`.** The seller is read from the live settings row by
/// definition, and there is no snapshot for it to have diverged from, so there
/// is nothing factual to say. D-075 note exists for a buyer whose details the
/// document never stored; that case has no counterpart on this side.
InvoiceDocumentParty? _seller(
  SellerIdentity seller,
  AppStrings strings,
  DocumentText Function(String) text,
) {
  final SellerIdentity identity = seller.normalized();
  if (!identity.isPrintable) return null;

  return InvoiceDocumentParty(
    heading: text(strings.invoiceDocumentSellerHeading),
    name: text(identity.name!),
    fields: <DocumentField>[
      if (identity.economicId != null)
        DocumentField(
          label: text(strings.settingsSellerFieldEconomicId),
          // The same isolating helper the buyer identifiers go through: a
          // code printed unisolated inside RTL text scrambles, and the
          // boundary is what makes reusing the screen helper safe here.
          value: text(formatIdentifierForDisplay(identity.economicId!)),
        ),
      if (identity.phone != null)
        DocumentField(
          label: text(strings.invoiceDocumentSellerPhoneLabel),
          value: text(formatIdentifierForDisplay(identity.phone!)),
        ),
      if (identity.address != null)
        DocumentField(
          label: text(strings.settingsSellerFieldAddress),
          value: text(identity.address!),
        ),
    ],
  );
}

InvoiceDocumentParty _party(
  InvoiceDetail detail,
  AppStrings strings,
  DocumentText Function(String) text,
) {
  final CustomerSnapshot party = detail.party;
  final InvoicePartyProvenance provenance = partyProvenanceOf(detail);

  return InvoiceDocumentParty(
    heading: text(strings.invoiceDocumentBuyerHeading),
    name: text(party.fullName),
    fields: <DocumentField>[
      if (party.companyName != null && party.companyName!.isNotEmpty)
        DocumentField(
          label: text(strings.customerFieldCompany),
          value: text(party.companyName!),
        ),
      if (party.nationalId != null && party.nationalId!.isNotEmpty)
        DocumentField(
          label: text(strings.customerFieldNationalId),
          value: text(formatIdentifierForDisplay(party.nationalId!)),
        ),
      if (party.economicId != null && party.economicId!.isNotEmpty)
        DocumentField(
          label: text(strings.customerFieldEconomicId),
          value: text(formatIdentifierForDisplay(party.economicId!)),
        ),
      if (party.address != null && party.address!.isNotEmpty)
        DocumentField(
          label: text(strings.customerFieldAddress),
          value: text(party.address!),
        ),
    ],
    // One case of four, and only one (D-075). A snapshot that matches, and a
    // snapshot that has since diverged, both print the snapshot and say
    // nothing -- the document is right in both, and the divergence is the
    // app user's business rather than the reader's. A draft says nothing
    // either, because its banner has already said that nothing is final.
    sourceNote: provenance == InvoicePartyProvenance.issuedWithoutSnapshot
        ? text(strings.invoiceDocumentPartyFromRecord)
        : null,
  );
}

InvoiceDocumentLine _line(
  InvoiceItem item,
  int index,
  AppStrings strings,
  DocumentText Function(String) text,
  DocumentAmount Function(Money) toman,
) {
  return InvoiceDocumentLine(
    rowNumber: text(formatGroupedPersian(index + 1)),
    // The snapshot title. Joining to the live product here would undo D-004
    // at the last possible moment, on the one artifact the customer keeps.
    description: text(item.title),
    quantity: text('${formatQuantityMilli(item.quantityMilli)} ${item.unit}'),
    unitPrice: toman(item.unitPrice),
    // Null means unknown, never zero (D-055). The admission carries the
    // column's own name, exactly as it does on screen — and carries no unit,
    // because «ثبت‌نشده تومان» would be nonsense: there is no amount for the
    // unit to qualify.
    gross: switch (item.gross) {
      final Money gross => toman(gross),
      null => DocumentAmount(
        digits: text(
          strings.invoiceLineLabelUnrecorded(strings.invoiceLineColumnGross),
        ),
        unit: text(''),
      ),
    },
  );
}

/// The summary rows above the grand total, in reconciliation order.
///
/// A row whose figure is zero is **omitted**, not printed as «۰»: a discount
/// line reading zero invites the reader to look for a discount that was never
/// given, and a tax line reading zero on an invoice from a business that is not
/// VAT-registered is a statement about their registration rather than about
/// this sale.
///
/// The gross row is the exception, because its absence means something. Where
/// the figure was never recorded (D-055) the row still appears, carrying the
/// admission rather than a number.
List<DocumentAmountRow> _totals(
  InvoiceSummaryFigures figures,
  AppStrings strings,
  DocumentText Function(String) text,
  DocumentAmount Function(Money) toman,
) {
  return <DocumentAmountRow>[
    DocumentAmountRow(
      label: text(strings.invoiceSummaryGross),
      amount: switch (figures.grossTotal) {
        final Money gross => toman(gross),
        null => DocumentAmount(
          digits: text(
            strings.invoiceLineLabelUnrecorded(strings.invoiceSummaryGross),
          ),
          unit: text(''),
        ),
      },
    ),
    if (figures.totalDiscount != Money.zero)
      DocumentAmountRow(
        label: text(strings.invoiceSummaryDiscount),
        amount: toman(figures.totalDiscount),
      ),
    if (figures.totalTax != Money.zero)
      DocumentAmountRow(
        label: text(strings.invoiceSummaryTax),
        amount: toman(figures.totalTax),
      ),
    if (figures.roundingAdjustment != Money.zero)
      DocumentAmountRow(
        label: text(strings.invoiceSummaryRounding),
        amount: toman(figures.roundingAdjustment),
      ),
  ];
}
