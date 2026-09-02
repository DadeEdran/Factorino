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
import '../domain/invoice_party_view.dart';
import '../domain/invoice_summary_figures.dart';
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
}) {
  final Invoice invoice = detail.invoice;
  final InvoiceSummaryFigures figures = InvoiceSummaryFigures.ofStored(invoice);
  final bool isDraft = invoice.isEditable;

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
    draftBanner: isDraft ? text(strings.invoiceDocumentDraftBanner) : null,
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
    party: _party(detail, strings, text),
    lineColumns: <DocumentText>[
      text(strings.invoiceDocumentColumnRow),
      text(strings.invoiceLineColumnDescription),
      text(strings.invoiceLineColumnQuantity),
      text(strings.invoiceLineColumnUnitPrice),
      text(strings.invoiceLineColumnGross),
      text(strings.invoiceLineColumnTotal),
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
    total: toman(item.lineTotal),
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
