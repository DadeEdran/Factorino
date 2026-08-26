import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/money/money.dart';
import '../../../core/security/app_log.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/models/invoice.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../settings/application/settings_providers.dart';
import '../domain/invoice_editor_state.dart';

part 'invoice_editor.g.dart';

/// The invoice being edited, and every intent that changes it.
///
/// **The controller holds the state; the engine holds the arithmetic.** Every
/// method here rebuilds [InvoiceEditorState], whose constructor runs
/// `calculateInvoice` — so the totals on screen are recomputed from the entries
/// on every single edit and can never belong to an earlier version of them.
/// Nothing in this file adds two amounts together.
///
/// **Settings are watched, not captured.** The tax default and the rounding
/// unit are the last step of §4's resolution chain, and they live in settings.
/// Watching means that changing the VAT rate while a form is open updates the
/// preview instead of leaving it describing a rule that no longer applies. The
/// repository re-reads settings inside the write transaction anyway — that
/// resolution is the authoritative one — so the two can differ for at most the
/// frame in which the change lands.
///
/// Keyed by the clock reading the form opened with, so `issueDate` is settled
/// once rather than drifting while the user types (D-041's reasoning, one
/// screen along).
///
/// **The screen must hold that instant, not re-read the clock in `build`.** The
/// family key is compared by value, so a fresh `DateTime.now()` on every frame
/// would address a different provider each time — a new, empty editor per
/// rebuild, discarding the invoice as it is typed. Take it from `nowProvider`
/// once, in `initState` or an equivalent, and pass the same value down.
///
/// Auto-disposed, like every other provider here (§3). It stays alive because
/// the screen watches it; nothing else holds it open, so leaving the form
/// discards the draft — which is the intended behaviour for something that has
/// not been saved, and is why saving is an explicit action.
@riverpod
class InvoiceEditor extends _$InvoiceEditor {
  @override
  Future<InvoiceEditorState> build(DateTime openedAt) async {
    final AppSettings settings = await ref.watch(appSettingsProvider.future);

    // Rebuilt when settings change, which discards in-progress edits -- so the
    // previous entries are carried across rather than reset. `.value` is the
    // nullable accessor in Riverpod 3 (`valueOrNull` is gone), and it is null
    // only on the very first build.
    final InvoiceEditorState? previous = state.value;
    if (previous == null) {
      return InvoiceEditorState(
        settings: settings,
        issueDate: openedAt,
        dueDate: defaultDueDate(openedAt),
      );
    }
    return previous.copyWith(settings: settings);
  }

  /// Applies [change] to the current state.
  ///
  /// Every intent below funnels through here so that "there is no path that
  /// mutates the state without recomputing the totals" is a property of one
  /// method rather than of a dozen. A silent no-op while the first settings
  /// read is in flight is the right behaviour: there is no invoice to edit yet.
  void _update(InvoiceEditorState Function(InvoiceEditorState state) change) {
    final InvoiceEditorState? current = state.value;
    if (current == null) return;
    state = AsyncValue<InvoiceEditorState>.data(change(current));
  }

  // ---- invoice-level ------------------------------------------------------

  void selectCustomer(String? customerId) => _update(
    (InvoiceEditorState s) => customerId == null
        ? s.copyWith(clearCustomer: true)
        : s.copyWith(customerId: customerId),
  );

  /// Moves the issue date, and carries a **derived** due date with it.
  ///
  /// A due date the user never chose is a statement about the payment term, not
  /// about a calendar day: leaving it behind a later issue date would produce a
  /// document due before it was issued. A due date the user *did* choose is a
  /// commitment to a day, and dragging it would silently rewrite an agreement.
  /// `dueDateFollowsIssueDate` is what tells the two apart.
  void setIssueDate(DateTime issueDate) => _update(
    (InvoiceEditorState s) => s.copyWith(
      issueDate: issueDate,
      dueDate: s.dueDateFollowsIssueDate ? defaultDueDate(issueDate) : null,
    ),
  );

  /// Sets the due date the user picked, and stops deriving it.
  ///
  /// Never set back to derived: once the user has expressed an intent about a
  /// date, the app does not resume guessing on their behalf.
  void setDueDate(DateTime? dueDate) => _update(
    (InvoiceEditorState s) => dueDate == null
        ? s.copyWith(clearDueDate: true, dueDateFollowsIssueDate: false)
        : s.copyWith(dueDate: dueDate, dueDateFollowsIssueDate: false),
  );

  void setNotes(String? notes) => _update(
    (InvoiceEditorState s) =>
        notes == null ? s.copyWith(clearNotes: true) : s.copyWith(notes: notes),
  );

  /// An absolute invoice-level discount. Clears any percentage: the two are
  /// alternatives, and leaving a stale percentage set would let it win in the
  /// engine over the amount the user just typed (§4 step 2).
  void setDiscountAmount(Money discount) => _update(
    (InvoiceEditorState s) =>
        s.copyWith(discount: discount, clearDiscountPercent: true),
  );

  /// A percentage invoice-level discount, in basis points. The engine resolves
  /// it against the subtotal and reports both figures.
  void setDiscountPercent(int? basisPoints) => _update(
    (InvoiceEditorState s) => basisPoints == null
        ? s.copyWith(clearDiscountPercent: true)
        : s.copyWith(discountPercentBp: basisPoints, discount: Money.zero),
  );

  /// The invoice-level tax override. `null` inherits the settings default; `0`
  /// is a real rate meaning zero percent (D-026).
  void setTaxRate(int? basisPoints) => _update(
    (InvoiceEditorState s) => basisPoints == null
        ? s.copyWith(clearTaxRate: true)
        : s.copyWith(taxRateBp: basisPoints),
  );

  // ---- lines --------------------------------------------------------------

  void addLine(InvoiceLineEntry line) => _update(
    (InvoiceEditorState s) =>
        s.copyWith(lines: <InvoiceLineEntry>[...s.lines, line]),
  );

  /// Replaces the line at [index]. Out-of-range indexes are ignored rather than
  /// throwing: a stale callback from a row that has just been removed is an
  /// ordinary race in a list being edited, not a programming error.
  void replaceLine(int index, InvoiceLineEntry line) =>
      _update((InvoiceEditorState s) {
        if (index < 0 || index >= s.lines.length) return s;
        final List<InvoiceLineEntry> lines = <InvoiceLineEntry>[...s.lines];
        lines[index] = line;
        return s.copyWith(lines: lines);
      });

  /// Applies [change] to one line, so a caller can alter a single field without
  /// restating the rest of it.
  void updateLine(
    int index,
    InvoiceLineEntry Function(InvoiceLineEntry line) change,
  ) => _update((InvoiceEditorState s) {
    if (index < 0 || index >= s.lines.length) return s;
    final List<InvoiceLineEntry> lines = <InvoiceLineEntry>[...s.lines];
    lines[index] = change(lines[index]);
    return s.copyWith(lines: lines);
  });

  void removeLine(int index) => _update((InvoiceEditorState s) {
    if (index < 0 || index >= s.lines.length) return s;
    final List<InvoiceLineEntry> lines = <InvoiceLineEntry>[...s.lines];
    lines.removeAt(index);
    return s.copyWith(lines: lines);
  });

  /// Moves a line, so the document prints in the order the user arranged it —
  /// `invoice_items.position` exists for exactly this.
  // ---- persistence --------------------------------------------------------

  /// Writes the invoice as a **draft** and returns it, or null if the write
  /// failed or the state is not complete enough to write.
  ///
  /// **A draft, deliberately.** `create` allocates no number for one (D-048),
  /// so saving a form the user may still abandon costs nothing permanent. The
  /// number is allocated by [issue], which is the moment the document becomes
  /// one.
  ///
  /// **No total crosses this boundary.** [InvoiceEditorState.toDraft] carries
  /// what the user chose and nothing computed; the repository re-runs the
  /// engine inside the write transaction. That is what makes a stored total
  /// unable to disagree with its lines, and it is pinned against the preview by
  /// `invoice_preview_matches_write_test.dart`.
  ///
  /// The warnings the write reports are returned with the invoice rather than
  /// swallowed: a clamp is an observation about the input (D-027), and the
  /// screen decides what to say about it.
  Future<InvoiceCreationResult?> save() async {
    final InvoiceEditorState? current = state.value;
    if (current == null || !current.isComplete) return null;

    return _guarded(() {
      return ref.read(invoiceRepositoryProvider).create(current.toDraft());
    });
  }

  /// Saves the invoice and issues it, in that order.
  ///
  /// Two transactions, not one, and that is the repository's shape rather than
  /// a compromise here: `create` writes the invoice and its lines, `issue`
  /// allocates the number and moves the status, each inside its own transaction
  /// (D-013, D-048). The allocation is what must be atomic — reading
  /// `MAX(number_sequence)` and writing it back cannot be separable, or two
  /// invoices issued in the same instant take the same number — and it is.
  ///
  /// A failure between the two leaves a saved draft with no number, which is a
  /// state the app already handles and the user can retry from. The opposite
  /// arrangement — a number allocated against an invoice that failed to write —
  /// would spend a number on nothing, permanently (D-013).
  Future<Invoice?> issue() async {
    final InvoiceCreationResult? created = await save();
    if (created == null) return null;

    return _guarded(
      () => ref.read(invoiceRepositoryProvider).issue(created.invoice.id),
    );
  }

  /// Runs a write, turning a failure into null and a log line.
  ///
  /// The repository's exceptions never reach a widget: §7 requires a friendly
  /// Persian message and forbids a raw exception, a stack trace or a SQL
  /// statement reaching the user. The screen renders its own copy from a null
  /// return. Logged through the wrapper, which is what strips it in release and
  /// keeps customer names and amounts out of it.
  Future<T?> _guarded<T>(Future<T> Function() write) async {
    try {
      return await write();
    } on Object catch (error, stackTrace) {
      AppLog.error(
        () => 'invoice write failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'invoice-editor',
      );
      return null;
    }
  }

  void moveLine(int from, int to) => _update((InvoiceEditorState s) {
    if (from < 0 || from >= s.lines.length) return s;
    if (to < 0 || to >= s.lines.length || from == to) return s;
    final List<InvoiceLineEntry> lines = <InvoiceLineEntry>[...s.lines];
    lines.insert(to, lines.removeAt(from));
    return s.copyWith(lines: lines);
  });
}
