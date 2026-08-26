import '../../../core/money/invoice_calculator.dart';
import '../../../core/money/money.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/models/invoice_draft.dart';

/// One line of an invoice while it is being edited.
///
/// Holds **parsed, typed values only** — a `Money`, an integer
/// `quantityMilli`, basis points. Raw text belongs to the form's controllers;
/// parsing happens at the field boundary through `core/formatting/`, so nothing
/// downstream of here has to wonder whether a value is trustworthy. That is
/// also what keeps this file free of Flutter and directly unit-testable.
///
/// [title], [unit] and [unitPrice] are carried even when [productId] is set,
/// because they are **snapshots** (D-004). Picking a product copies its values
/// in once; editing the product tomorrow changes nothing here, and neither does
/// anything that happens between now and the moment the invoice is written.
class InvoiceLineEntry {
  const InvoiceLineEntry({
    required this.title,
    required this.unit,
    required this.unitPrice,
    required this.quantityMilli,
    this.productId,
    this.discount = Money.zero,
    this.discountPercentBp,
    this.taxRateBp,
  });

  /// Traceability only; never a pricing reference (D-004).
  final String? productId;

  final String title;
  final String unit;
  final Money unitPrice;

  /// Scaled by 1000: `1.5` is `1500` (§4). Never a `double`, at any point
  /// between the keyboard and the database.
  final int quantityMilli;

  /// Absolute discount. When [discountPercentBp] is set the engine resolves the
  /// amount from the percentage instead and reports both (§4 step 2).
  final Money discount;
  final int? discountPercentBp;

  /// Item-level tax rate override — the first step of the resolution order
  /// item → invoice → settings default (§4 step 6).
  ///
  /// `null` means *inherit*; `0` is a real rate meaning zero percent, and the
  /// two must never be conflated (D-026). A line the user marked tax-exempt is
  /// `0`, and treating that as "not set" would apply the default VAT rate to a
  /// line deliberately marked exempt — a wrong total on a tax document that
  /// looks right to everyone except the tax authority.
  final int? taxRateBp;

  /// Whether this line is complete enough to appear on a document.
  ///
  /// A zero quantity is **not** disqualifying: §4 handles it, the engine has a
  /// test for it, and a line entered at zero pending a count is a real thing a
  /// user does. What a line cannot be is nameless or unitless, because those
  /// are what the document prints.
  bool get isComplete => title.trim().isNotEmpty && unit.trim().isNotEmpty;

  InvoiceLineEntry copyWith({
    String? title,
    String? unit,
    Money? unitPrice,
    int? quantityMilli,
    Money? discount,
    bool clearProduct = false,
    String? productId,
    bool clearDiscountPercent = false,
    int? discountPercentBp,
    bool clearTaxRate = false,
    int? taxRateBp,
  }) {
    return InvoiceLineEntry(
      title: title ?? this.title,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      quantityMilli: quantityMilli ?? this.quantityMilli,
      productId: clearProduct ? null : (productId ?? this.productId),
      discount: discount ?? this.discount,
      // `clear` flags rather than "null means unchanged", because for these
      // three fields null is a *meaningful value* -- an inherited tax rate, an
      // absolute rather than percentage discount, a freehand line. Without them
      // copyWith could set those but never unset them (D-026).
      discountPercentBp: clearDiscountPercent
          ? null
          : (discountPercentBp ?? this.discountPercentBp),
      taxRateBp: clearTaxRate ? null : (taxRateBp ?? this.taxRateBp),
    );
  }

  InvoiceItemDraft toDraft() => InvoiceItemDraft(
    title: title.trim(),
    unit: unit.trim(),
    unitPrice: unitPrice,
    quantityMilli: quantityMilli,
    productId: productId,
    discount: discount,
    discountPercentBp: discountPercentBp,
    taxRateBp: taxRateBp,
  );

  InvoiceLineInput toInput() => InvoiceLineInput(
    unitPrice: unitPrice,
    quantityMilli: quantityMilli,
    discount: discount,
    discountPercentBp: discountPercentBp,
    taxRateBp: taxRateBp,
  );
}

/// An invoice as it is being edited, and the totals the engine makes of it.
///
/// **This class holds no arithmetic.** [totals] is whatever `calculateInvoice`
/// returned for the current entries; every figure a screen displays comes from
/// there, including ones that look trivial. The engine is the authority — if a
/// figure is needed that it does not produce, the engine is what gets extended
/// (which is where `CalculatedInvoice.grossTotal` came from). A screen that
/// added two amounts together would be a second implementation of §4, and the
/// two would disagree on the day one of them was changed.
///
/// `single_calculation_path_test.dart` enforces that structurally: nothing in
/// `lib/` outside `core/money/`, this file and the repository may call
/// `calculateInvoice` at all.
///
/// **Immutable, and recomputed on construction.** Every edit produces a new
/// state with fresh totals, so the figures on screen can never belong to an
/// earlier version of the lines. The computation is a pure integer pass over a
/// handful of lines; caching it would be an optimisation with a staleness bug
/// attached.
class InvoiceEditorState {
  InvoiceEditorState({
    required this.settings,
    required this.issueDate,
    this.customerId,
    this.dueDate,
    this.dueDateFollowsIssueDate = true,
    this.lines = const <InvoiceLineEntry>[],
    this.discount = Money.zero,
    this.discountPercentBp,
    this.taxRateBp,
    this.notes,
  }) : totals = calculateInvoice(
         InvoiceInput(
           lines: <InvoiceLineInput>[
             for (final InvoiceLineEntry line in lines) line.toInput(),
           ],
           // The last step of the tax chain, and the rounding rule, both come
           // from settings and are never hardcoded (§4, D-026). Held on the
           // state so that a settings change re-renders the preview rather than
           // leaving it describing a rule that no longer applies.
           defaultTaxRateBp: settings.defaultTaxRateBp,
           discount: discount,
           discountPercentBp: discountPercentBp,
           taxRateBp: taxRateBp,
           roundingUnitRial: settings.roundingUnitRial,
         ),
       );

  /// The settings the preview was computed against.
  ///
  /// The repository re-reads settings **inside** the write transaction, which
  /// is the authoritative resolution. The two can differ only if the user
  /// changes the VAT rate while a form is open; the editor watches the settings
  /// provider so the preview follows, which narrows that to a single frame.
  final AppSettings settings;

  /// Null until a customer is chosen. An invoice cannot be written without one
  /// — `invoices.customer_id` is a non-null foreign key — so [isComplete]
  /// refuses, rather than [toDraft] inventing a placeholder.
  final String? customerId;

  /// UTC (D-005). The **Jalali** year of this instant is what the invoice
  /// number is allocated against when the invoice is issued (D-013).
  final DateTime issueDate;
  final DateTime? dueDate;

  /// Whether [dueDate] is still the default derived from [issueDate], rather
  /// than a date the user chose.
  ///
  /// It exists because moving the issue date must move a *derived* due date and
  /// must not move a *chosen* one, and nothing else in the state can tell those
  /// apart — a due date thirty days out looks identical either way. Without the
  /// flag the editor has to pick one wrong behaviour: leave a default due date
  /// behind the new issue date (a document due before it was issued), or drag a
  /// date the user deliberately set.
  ///
  /// Set false the moment the user picks a due date, and never set back: once
  /// they have expressed an intent, the app does not resume guessing.
  final bool dueDateFollowsIssueDate;

  final List<InvoiceLineEntry> lines;

  /// Invoice-level discount, allocated across the lines by the engine before
  /// tax with largest-remainder rounding (§4 step 4). Not allocated here.
  final Money discount;
  final int? discountPercentBp;

  /// Invoice-level tax rate — the middle step of the resolution order. `null`
  /// inherits the settings default; `0` is a real rate (D-026).
  final int? taxRateBp;

  final String? notes;

  /// Everything §4 produces for the current entries.
  ///
  /// The single source of every figure on screen: line totals, the summary,
  /// the resolved tax rate per line, and [warnings].
  final CalculatedInvoice totals;

  /// Inputs the engine had to clamp, with both figures (D-027).
  ///
  /// Not an error state — the totals are correct and the invoice is usable.
  /// What is questionable is the input, and only the user can settle it, so the
  /// engine reports and the screen asks. Absorbing one silently is how a wrong
  /// figure reaches a document nobody questions.
  List<InvoiceWarning> get warnings => totals.warnings;

  bool get hasWarnings => totals.hasWarnings;

  /// Whether this can be written at all.
  ///
  /// A customer, at least one line, and every line named and united. Deliberately
  /// not "and the totals look sensible": a zero-total invoice is a document a
  /// user may legitimately produce, and the engine has already refused anything
  /// it cannot compute.
  bool get isComplete =>
      customerId != null &&
      lines.isNotEmpty &&
      lines.every((InvoiceLineEntry line) => line.isComplete);

  /// What the repository is handed (§3: repositories take domain models).
  ///
  /// Carries **no computed figure**. Every total is the repository's to produce
  /// inside the write transaction, from this same engine — so a stored total
  /// cannot disagree with its lines, and a caller cannot supply one.
  InvoiceDraft toDraft() {
    final String? customer = customerId;
    if (customer == null) {
      throw StateError(
        'toDraft() called on an incomplete editor state: no customer has been '
        'chosen. Check isComplete first.',
      );
    }

    return InvoiceDraft(
      customerId: customer,
      issueDate: issueDate,
      items: <InvoiceItemDraft>[
        for (final InvoiceLineEntry line in lines) line.toDraft(),
      ],
      dueDate: dueDate,
      discount: discount,
      discountPercentBp: discountPercentBp,
      taxRateBp: taxRateBp,
      notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
    );
  }

  InvoiceEditorState copyWith({
    AppSettings? settings,
    DateTime? issueDate,
    bool clearCustomer = false,
    String? customerId,
    bool clearDueDate = false,
    DateTime? dueDate,
    bool? dueDateFollowsIssueDate,
    List<InvoiceLineEntry>? lines,
    Money? discount,
    bool clearDiscountPercent = false,
    int? discountPercentBp,
    bool clearTaxRate = false,
    int? taxRateBp,
    bool clearNotes = false,
    String? notes,
  }) {
    return InvoiceEditorState(
      settings: settings ?? this.settings,
      issueDate: issueDate ?? this.issueDate,
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueDateFollowsIssueDate:
          dueDateFollowsIssueDate ?? this.dueDateFollowsIssueDate,
      lines: lines ?? this.lines,
      discount: discount ?? this.discount,
      discountPercentBp: clearDiscountPercent
          ? null
          : (discountPercentBp ?? this.discountPercentBp),
      taxRateBp: clearTaxRate ? null : (taxRateBp ?? this.taxRateBp),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }
}

/// How long after issue an invoice is due, by default.
///
/// **A constant here, not a setting, and that is a gap rather than a decision.**
/// A payment term is exactly the sort of thing a business configures, and it
/// belongs in `settings` beside the VAT rate and the numbering prefix. Putting
/// it there is a schema change — `settings` has no such column — and D-051
/// records why a schema change is not folded into an increment that is not
/// about one. Until then the app picks the common term and lets the user
/// override it per invoice, which it can already do.
const int kDefaultPaymentTermDays = 30;

/// The due date a freshly opened form starts with: [issueDate] plus the
/// default term.
///
/// Computed by adding days to the **instant**, not by adding to a Jalali date
/// and converting back. Iran keeps a fixed offset with no DST transitions
/// (D-005), so the two agree — and the instant arithmetic is the one that stays
/// correct if that ever stops being true, because a term is a duration and not
/// a calendar-field operation.
DateTime defaultDueDate(DateTime issueDate) =>
    issueDate.toUtc().add(const Duration(days: kDefaultPaymentTermDays));
