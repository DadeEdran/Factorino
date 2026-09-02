import '../../../core/pdf/document_text.dart';

/// A label and the value it labels, kept apart.
///
/// **D-070's contract rule 2, as a type.** Probe 3 measured thirteen field
/// shapes: every one renders correctly bare and scrambles only when it shares
/// one run with its own Persian label. `'تلفن: ' + number` came out
/// `۴۵۶۷ ۱۲۳ ۹۱۲ ۹۸+` — the groups reversed — because the `+` and the spaces
/// are bidi-neutral and resolve against whatever sits beside them.
///
/// So the view model never holds a joined string, and the renderer draws two
/// widgets. This is what makes finding 2 *disappear* rather than need a
/// remedy: with the label in its own run there is no neutral run to misresolve.
class DocumentField {
  const DocumentField({required this.label, required this.value});

  final DocumentText label;
  final DocumentText value;

  @override
  String toString() => 'DocumentField(${label.value})';
}

/// An amount and its unit, kept apart for the same reason.
///
/// D-070 sanctions two shapes for an amount-with-unit — two widgets, or left
/// bare — and forbids the third, wrapping it in an LTR `Directionality`, which
/// renders «تومان» as «ناموت». Two widgets is chosen because it mirrors
/// `AmountText` on screen, which has always drawn the digits and the unit as
/// separate `Text`s, and because it keeps the choice visible in the type rather
/// than resting on a string that happens to be safe.
class DocumentAmount {
  const DocumentAmount({required this.digits, required this.unit});

  final DocumentText digits;
  final DocumentText unit;

  @override
  String toString() => 'DocumentAmount(${digits.value.length} digits)';
}

/// One row of the lines table, already formatted.
class InvoiceDocumentLine {
  const InvoiceDocumentLine({
    required this.rowNumber,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.gross,
  });

  /// The ردیف column. Persian digits, formatted once, here.
  final DocumentText rowNumber;

  /// The **snapshot** title, never the live product name (D-004).
  final DocumentText description;

  /// Quantity with its unit of measure, as one value — this is not a
  /// label/value pair: «۲ عدد» is one quantity, and the unit of measure is
  /// part of reading it.
  final DocumentText quantity;

  final DocumentAmount unitPrice;

  /// `lineGross`, or the «ثبت‌نشده» admission where a pre-v4 row never stored
  /// one (D-055). The view model carries whichever it is; the renderer does
  /// not know the difference and must not.
  ///
  /// A [DocumentAmount] rather than a [DocumentText] so it carries its unit
  /// like every other money cell. It was a bare string in the first draft and
  /// the rendered page showed it: one column of figures with no «تومان» beside
  /// them, between two columns that had it. §9 is explicit -- the unit label is
  /// always shown next to amounts, never a bare number -- and the admission
  /// case is what made a bare string look reasonable while writing it.
  final DocumentAmount gross;

  // **There is deliberately no per-line total** (D-082). «جمع سطر» was here and
  // was removed: it is the line's own amount after its share of the
  // invoice-level discount and its tax, and that share comes from a
  // proportional allocation the document never shows — so it was the one figure
  // on the page a reader could not arrive at with a pencil, which §4 forbids on
  // the artifact a customer keeps.
}

/// The party block.
class InvoiceDocumentParty {
  const InvoiceDocumentParty({
    required this.heading,
    required this.name,
    required this.fields,
    this.sourceNote,
  });

  final DocumentText heading;

  /// The party as the **document** states them: the snapshot where there is
  /// one, the live record where there is not (D-052).
  final DocumentText name;

  /// Company, کد ملی, کد اقتصادی, نشانی — only those that have a value. An
  /// empty field is omitted rather than printed blank: a labelled empty line on
  /// a document reads as data that failed to print.
  final List<DocumentField> fields;

  /// One factual line, present only where the details above are **not** the
  /// document's own statement of the party (D-075).
  ///
  /// Exactly one of the four `InvoicePartyProvenance` cases produces it. It is
  /// not an apology and not a warning: it says where the details came from,
  /// which is true and is the thing a reader would otherwise assume wrongly.
  final DocumentText? sourceNote;
}

/// Everything the renderer needs, computed and formatted once.
///
/// **The renderer computes nothing.** No arithmetic, no rounding, no date
/// conversion, no digit substitution, no unit choice. `core/money/` is the only
/// calculator in this application (§4) and a second one inside a PDF layout
/// would be the worst possible place for it: a total that disagrees with the
/// screen by one Rial, discovered by a customer.
///
/// Every string here has crossed [DocumentTextBoundary], so the isolates §9
/// correctly puts on a کد ملی for the screen cannot reach a shaper that would
/// print nine of its ten digits (D-070 finding 1).
class InvoiceDocumentView {
  const InvoiceDocumentView({
    required this.title,
    required this.number,
    required this.issueDate,
    required this.party,
    required this.lineColumns,
    required this.lines,
    required this.totals,
    required this.grandTotal,
    this.seller,
    this.banner,
    this.paymentStatus,
    this.dueDate,
    this.notes,
  });

  /// «فاکتور فروش».
  final DocumentText title;

  /// The invoice number, or «بدون شماره» for a draft that has not been issued
  /// (D-048). Never blank: an empty cell reads as data that failed to load.
  final DocumentField number;

  final DocumentField issueDate;

  /// Absent where the invoice has no due date, rather than printed empty.
  final DocumentField? dueDate;

  /// The unmissable marking across the top of the page: a **draft** (D-075) or
  /// a **cancelled** invoice (D-085), and null for an ordinary one.
  ///
  /// **One field for both, because they cannot co-occur.** A draft has never
  /// been cancelled — cancellation is refused on it (`isCancellable`) — and a
  /// cancelled invoice was issued, so it is not a draft. Two nullable fields
  /// for one slot would have made a state the domain forbids expressible in the
  /// view, and the renderer would have had to pick one.
  ///
  /// Both are drawn as a filled band because the requirement is the same for
  /// each: somebody **holding** the page must know it is not a valid claim
  /// without reading it closely. A cancelled invoice is the more dangerous of
  /// the two — it carries a real number and may already have been sent.
  final DocumentText? banner;

  /// «وضعیت پرداخت» and its value, printed under the payable total.
  ///
  /// **From the stored status, never recomputed** (§6). The status is derived
  /// from the payments and persisted onto the invoice by the repository; the
  /// renderer computes nothing, and a page that re-derived it could disagree
  /// with the screen that produced it.
  ///
  /// Null for a draft, which has no payment status worth printing, and null for
  /// a cancelled invoice, where «پرداخت نشده» beside the void band would read
  /// as a demand.
  final DocumentField? paymentStatus;

  /// The business the invoice was issued **by** (D-077).
  ///
  /// **Null is the ordinary case, not an error**, and the renderer omits the
  /// block entirely rather than drawing a heading over blanks. Every database
  /// reaches schema v5 with no seller stored, because there was nothing to
  /// migrate from and nothing honest to invent; a fabricated seller on the one
  /// page the customer keeps is the thing this phase must not do.
  ///
  /// Null here means precisely one thing — the user has given no business
  /// name — and it is [SellerIdentity.isPrintable] that decided it, in the
  /// builder, once. A seller with an address and no name is not a block with a
  /// gap in it; it is not a block.
  ///
  /// **The fact travels with the view so the print path can say something
  /// about it.** The settings screen prompts, which covers the user who goes
  /// looking; a caller holding this view can see that the document names only
  /// one party without re-reading the settings row to find out.
  final InvoiceDocumentParty? seller;

  final InvoiceDocumentParty party;

  /// Column headings, in table order.
  final List<DocumentText> lineColumns;

  final List<InvoiceDocumentLine> lines;

  /// The summary rows above the grand total: gross, discount, tax, rounding —
  /// only those that apply. A zero discount row is omitted rather than printed
  /// as «۰», which invites the reader to look for a discount that was never
  /// given.
  final List<DocumentAmountRow> totals;

  /// «مبلغ قابل پرداخت» and the figure. Separated from [totals] because it is
  /// the one number the document exists to state.
  final DocumentAmountRow grandTotal;

  final DocumentText? notes;
}

/// A totals row: a label and an amount.
class DocumentAmountRow {
  const DocumentAmountRow({required this.label, required this.amount});

  final DocumentText label;
  final DocumentAmount amount;
}
