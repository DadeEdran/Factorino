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
    required this.total,
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

  final DocumentAmount total;
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
    this.draftBanner,
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

  /// Present only for a draft (D-075). The renderer draws it as a filled band
  /// across the page, because the requirement is that somebody **holding** the
  /// page knows it is not final without reading it closely.
  final DocumentText? draftBanner;

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
