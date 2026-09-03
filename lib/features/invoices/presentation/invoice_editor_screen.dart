import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_strings.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/router/back_policy.dart';
import '../../../core/router/destinations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/page_body.dart';
import '../../../data/models/invoice.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../application/invoice_editor.dart';
import '../domain/invoice_summary_figures.dart';
import '../domain/invoice_editor_state.dart';
import '../domain/invoice_number_label.dart';
import 'widgets/invoice_details_section.dart';
import 'widgets/invoice_discount_sheet.dart';
import 'widgets/invoice_lines_section.dart';
import 'widgets/invoice_totals_summary.dart';

/// The invoice form: the sections built in (b) and (c), composed and routed.
///
/// **The clock is read once, here.** `invoiceEditorProvider` is a family keyed
/// by a `DateTime`, compared by value — so a fresh `DateTime.now()` in `build`
/// would address a different provider on every frame, giving a new empty editor
/// each time and discarding the invoice as the user types it. It is captured in
/// [initState] and passed to both sections, which take it as a parameter for
/// exactly this reason.
///
/// **Three layouts, not one stretched three ways** (§10):
///
/// * **Mobile** — the two things an invoice cannot exist without, **pinned at
///   the top**: who it is for, and how to add a line (D-096). The lines and the
///   optional details scroll between that and a bar pinned to the bottom
///   carrying the payable figure and both actions. Nothing the user must do is
///   ever more than zero scrolls away, and the figure they are deciding about
///   stays visible while they edit the lines that change it.
/// * **Tablet** — two panes side by side. The document's own fields sit in the
///   left pane and its lines in the right, each scrolling independently, which
///   is the arrangement that suits the tier's shape: a tablet in portrait and a
///   large phone in landscape both have more width than height to spend.
/// * **Desktop** — the main column carries the fields and the lines as a real
///   table, with a **sticky summary panel** beside it holding the totals and
///   both actions (§10). Nothing scrolls out of reach of the figure it changes.
///
/// **This screen computes nothing.** Every figure it renders comes from
/// `InvoiceEditorState.totals`, the `CalculatedInvoice` the engine produced;
/// `single_calculation_path_test.dart` fails the build on any other arithmetic
/// path (D-046).
class InvoiceEditorScreen extends ConsumerStatefulWidget {
  const InvoiceEditorScreen({this.invoiceId, super.key});

  /// The saved **draft** to reopen, or null to compose a new invoice.
  ///
  /// Passed to the notifier rather than into the provider's family key, which
  /// is the instant the form opened and is threaded through four widgets. See
  /// `InvoiceEditorState.editingInvoiceId`.
  final String? invoiceId;

  @override
  ConsumerState<InvoiceEditorScreen> createState() =>
      _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends ConsumerState<InvoiceEditorScreen> {
  /// The family key, settled once. See the class comment.
  late final DateTime _openedAt = ref.read(nowProvider);

  /// Loading the draft is deferred to the first frame because the provider's
  /// own `build` is async — the state does not exist yet in `initState`, and
  /// `loadDraft` returns immediately when it is null. `loadDraft` is idempotent,
  /// so the rebuild a settings change causes cannot discard what has been typed.
  @override
  void initState() {
    super.initState();
    final String? id = widget.invoiceId;
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(invoiceEditorProvider(_openedAt).future);
      if (!mounted) return;
      await ref.read(invoiceEditorProvider(_openedAt).notifier).loadDraft(id);
    });
  }

  /// True while a write is in flight, so a double tap cannot produce two
  /// invoices. Local rather than derived, because `InvoiceEditor` returns its
  /// result rather than parking it in `state` — the controller's `AsyncValue`
  /// describes the invoice being edited, not the save.
  bool _writing = false;

  /// The system back press, while this screen is open.
  ///
  /// **Registered rather than intercepted with a second listener** — see
  /// [BackClaims] for why there is exactly one of those in the application.
  /// Without this the shell's rule («back returns to the dashboard») would leave
  /// a half-typed invoice without asking, which is the one thing the [PopScope]
  /// above exists to prevent. The claim runs the same confirmation and then
  /// obeys the shell's rule rather than the in-page back arrow's: the arrow
  /// goes up one level to the invoice list, and the hardware back goes home.
  ///
  /// A tear-off held in a field rather than a fresh closure at each call site:
  /// [BackClaims.release] checks identity, so a claim that could not be
  /// recognised again would never be withdrawn.
  late final BackClaim _backClaim = _onSystemBack;

  Future<bool> _onSystemBack() async {
    final AsyncValue<InvoiceEditorState> editor = ref.read(
      invoiceEditorProvider(_openedAt),
    );
    if (_hasContent(editor) && !await _confirmDiscard(AppStrings.of(context))) {
      // Handled: the user chose to stay, which is a decision and not a
      // no-op — returning false here would let the shell navigate anyway.
      return true;
    }
    if (mounted) context.go(AppDestination.dashboard.path);
    return true;
  }

  BackClaims? _claims;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Null in a widget test that pumps this screen without the shell, which is
    // the ordinary way it is tested.
    _claims = BackPolicyScope.maybeOf(context)?..claim(_backClaim);
  }

  @override
  void dispose() {
    _claims?.release(_backClaim);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final AsyncValue<InvoiceEditorState> editor = ref.watch(
      invoiceEditorProvider(_openedAt),
    );

    return PopScope<Object?>(
      // The editor is auto-disposed and nothing outside this screen watches it,
      // so leaving discards the invoice. That is right for something never
      // saved — but it must not happen silently to someone who has typed one,
      // and back is one tap away on every tier.
      canPop: !_hasContent(editor),
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (await _confirmDiscard(strings) && mounted) _leave();
      },
      child: PageBody(
        title: strings.invoiceCreateTitle,
        onBack: () async {
          if (!_hasContent(editor) || await _confirmDiscard(strings)) _leave();
        },
        backTooltip: strings.invoiceBackTooltip,
        child: editor.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // The editor's only failure is the settings read behind it, and the
          // sections stay quiet about it precisely so this is the one place it
          // surfaces.
          error: (Object error, StackTrace stack) => AsyncErrorView(
            error: error,
            stackTrace: stack,
            scope: 'invoice-editor',
            onRetry: () => ref.invalidate(invoiceEditorProvider(_openedAt)),
          ),
          data: (InvoiceEditorState state) => _layout(context, strings, state),
        ),
      ),
    );
  }

  Widget _layout(
    BuildContext context,
    AppStrings strings,
    InvoiceEditorState state,
  ) {
    return switch (context.tier) {
      LayoutTier.mobile => _MobileLayout(
        openedAt: _openedAt,
        state: state,
        strings: strings,
        actions: _actions(strings, state),
      ),
      LayoutTier.tablet => _TabletLayout(
        openedAt: _openedAt,
        state: state,
        strings: strings,
        actions: _actions(strings, state),
      ),
      LayoutTier.desktop => _DesktopLayout(
        openedAt: _openedAt,
        state: state,
        strings: strings,
        actions: _actions(strings, state),
      ),
    };
  }

  /// The two actions, built once and placed differently by each layout.
  _EditorActions _actions(AppStrings strings, InvoiceEditorState state) {
    return _EditorActions(
      strings: strings,
      // Both are disabled for the same reason and the reason is spelled out
      // beneath them, so a disabled button is never a dead end.
      blockedReason: _blockedReason(strings, state),
      // **Absent until there is something to issue** (D-021, D-086). An
      // invoice with no lines cannot be issued at all, so a filled button
      // offering it is advertising an action that can only fail — and it was
      // doing so from the most prominent place on the screen, directly over
      // the add-line control that is what the user actually needs to find.
      showIssue: state.lines.isNotEmpty,
      // **Absent until there is something to discount** (D-021, D-098). A
      // discount screen listing no lines and an invoice worth nothing is a
      // control that can only disappoint, and it would sit beside the two that
      // are already explaining why they cannot be used yet.
      showDiscount: state.lines.isNotEmpty,
      busy: _writing,
      onSaveDraft: _saveDraft,
      onIssue: () => _issue(strings, state),
      onDiscount: () => showInvoiceDiscountSheet(context, ref, _openedAt),
    );
  }

  /// Why the actions are unavailable, in Persian, or null when they are not.
  ///
  /// `isComplete` is the repository's own precondition (a customer, at least
  /// one line, every line named and united). Saying which half is missing is
  /// the difference between a form the user can finish and one that has simply
  /// stopped responding.
  String? _blockedReason(AppStrings strings, InvoiceEditorState state) {
    if (state.customerId == null) return strings.invoiceIncompleteCustomer;
    if (!state.isComplete) return strings.invoiceIncompleteLines;
    return null;
  }

  bool _hasContent(AsyncValue<InvoiceEditorState> editor) {
    final InvoiceEditorState? state = editor.value;
    if (state == null) return false;
    // A customer or a line is content. The dates are not: a freshly opened
    // form already has both, so treating them as content would make every
    // exit ask a question with an obvious answer, which is how a confirmation
    // dialog stops being read.
    return state.customerId != null || state.lines.isNotEmpty;
  }

  void _leave() => context.go(AppDestination.invoices.path);

  Future<bool> _confirmDiscard(AppStrings strings) async {
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.invoiceDiscardTitle),
        content: Text(strings.invoiceDiscardBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.invoiceDiscardKeepAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.invoiceDiscardAction),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  /// Writes the invoice as a draft: no number, still editable (D-048).
  Future<void> _saveDraft() async {
    final AppStrings strings = AppStrings.of(context);
    setState(() => _writing = true);

    final InvoiceCreationResult? result = await ref
.read(invoiceEditorProvider(_openedAt).notifier)
.save();

    if (!mounted) return;
    setState(() => _writing = false);

    if (result == null) {
      _tell(strings.invoiceSaveFailed);
      return;
    }
    _tell(strings.invoiceSaveDraftSuccess);
    _leave();
  }

  /// Issues the invoice — after saying, in Persian, what that costs.
  ///
  /// The confirmation is not ceremony. Issuing allocates a number that is
  /// **spent permanently** even if the invoice is later cancelled (D-013), and
  /// it ends editability: from then on the document is corrected by
  /// cancellation, not by editing. Neither consequence is
  /// visible from the button, and both are irreversible.
  Future<void> _issue(AppStrings strings, InvoiceEditorState state) async {
    final bool confirmed = await _confirmIssue(strings, state);
    if (!confirmed || !mounted) return;

    setState(() => _writing = true);
    final Invoice? issued = await ref
.read(invoiceEditorProvider(_openedAt).notifier)
.issue();

    if (!mounted) return;
    setState(() => _writing = false);

    if (issued == null) {
      _tell(strings.invoiceSaveFailed);
      return;
    }
    // The number is what the user needs to see: it is the identity the
    // document now has, and the thing they will search for. `hasNumber` rather
    // than the status, because that is a question about the row (D-048).
    _tell(strings.invoiceIssueSuccess(invoiceNumberLabel(issued, strings)));
    _leave();
  }

  Future<bool> _confirmIssue(
    AppStrings strings,
    InvoiceEditorState state,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.invoiceIssueConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(strings.invoiceIssueConfirmBody),
            const SizedBox(height: AppSpacing.lg),
            // The amount, restated at the moment of commitment. The user is
            // agreeing to a figure, and it should not be behind them on a
            // scrolled page when they agree to it.
            AmountText(
              state.totals.grandTotal,
              unitLabel: strings.unitToman,
              size: AmountSize.medium,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.invoiceIssueConfirmAction),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _tell(String message) {
    ScaffoldMessenger.of(context)
.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// The two actions, and the one sentence explaining why they are unavailable.
///
/// **They are deliberately not two equal buttons.** Saving a draft is
/// reversible and costs nothing — it takes no number and stays editable — while
/// issuing spends a number permanently and ends editability. So the draft is a
/// tonal button carrying a one-line note about what it does *not* do, and issue
/// is the filled one, behind a confirmation. Two identical buttons side by side
/// would say the two outcomes are equivalent, which is the one thing this
/// screen must not say.
class _EditorActions extends StatelessWidget {
  const _EditorActions({
    required this.strings,
    required this.blockedReason,
    required this.showIssue,
    required this.showDiscount,
    required this.busy,
    required this.onSaveDraft,
    required this.onIssue,
    required this.onDiscount,
  });

  final AppStrings strings;
  final String? blockedReason;

  /// Whether issuing is offered at all.
  ///
  /// False until the invoice has a line. **Absent rather than disabled**, which
  /// is D-021's rule and is why this is a separate flag from [blockedReason]:
  /// a *missing customer* is a gap the user can see and fix from here, so that
  /// button stays and explains itself; *no lines at all* means the screen has
  /// not been used yet, and a prominent filled control for the last step of a
  /// task nobody has started is noise at the exact moment the user is looking
  /// for the first step (D-086).
  final bool showIssue;

  /// Whether discounting is offered at all (D-098). False until the invoice
  /// has a line, for the reason [showIssue] is.
  final bool showDiscount;

  final bool busy;
  final VoidCallback onSaveDraft;
  final VoidCallback onIssue;
  final VoidCallback onDiscount;

  /// Stacked, for the sticky bar on a phone where two buttons and a total do
  /// not fit on one line.
  Widget stacked(BuildContext context) => _build(context, vertical: true);

  @override
  Widget build(BuildContext context) => _build(context, vertical: false);

  Widget _build(BuildContext context, {required bool vertical}) {
    final ThemeData theme = Theme.of(context);
    final bool enabled = blockedReason == null && !busy;

    final Widget draft = FilledButton.tonal(
      onPressed: enabled ? onSaveDraft : null,
      child: Text(strings.invoiceActionSaveDraft),
    );
    final Widget issue = FilledButton(
      onPressed: enabled ? onIssue : null,
      child: Text(strings.invoiceActionIssue),
    );
    // **Outlined, and beside the draft rather than under the issue.** It is a
    // step taken *before* committing, and neither writing nor issuing anything
    // -- so it must not read as a third way to finish. Enabled whenever there
    // are lines, including while the customer is still missing: discounting a
    // list of lines does not need to know who they are for (D-098).
    final Widget discount = OutlinedButton(
      onPressed: busy ? null : onDiscount,
      child: Text(strings.invoiceDiscountAction),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (vertical) ...<Widget>[
          if (showIssue) ...<Widget>[
            issue,
            const SizedBox(height: AppSpacing.sm),
          ],
          // Side by side, so a third action costs the pinned bar no height at
          // all -- which is the budget D-096 spent on the header above.
          if (showDiscount)
            Row(
              children: <Widget>[
                Expanded(child: draft),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: discount),
              ],
            )
          else
            draft,
        ] else ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(child: draft),
              if (showIssue) ...<Widget>[
                const SizedBox(width: AppSpacing.md),
                Expanded(child: issue),
              ],
            ],
          ),
          if (showDiscount) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            discount,
          ],
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          // The blocking reason wins the line when there is one: a user
          // looking at a disabled button needs to know what to do, not what
          // the enabled button would have done.
          blockedReason ?? strings.invoiceActionSaveDraftHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: blockedReason == null
                ? theme.colorScheme.onSurfaceVariant
: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// The phone: two pinned edges and a scroll between them.
///
/// **What is pinned is what the user must do** (D-096). Creating an invoice is
/// two acts — say who it is for, and say what is on it — and until this both
/// were inside the scroll, one of them behind a fold. Known issue 30 was three
/// separate attempts at keeping the add-line control reachable (D-054, D-086,
/// D-093), each of which moved it somewhere better and left it scrolling. This
/// takes it out of the scroll entirely, and takes the customer with it, because
/// the customer had the same problem and a worse one: it was a field inside a
/// collapsed section called «جزئیات فاکتور», which is exactly where a user would
/// not look for the one thing a save cannot do without.
///
/// **What scrolls is what varies**: the lines, however many there are, and the
/// optional detail — dates, discount, rate, note — that most invoices never
/// touch.
///
/// **The breakdown moved into the scroll, and that is what pays for the header**
/// (D-053, applied to this tier). The bar used to carry the whole
/// reconciliation — gross, discount, tax, then the payable total — roughly 190
/// logical pixels of it. The desktop tier already decided this question the
/// other way and recorded why: the *decision* is what has to stay in front of
/// the user, and the breakdown belongs with the fields that explain it.
/// Repeating it in the bar was two answers to one question a scroll apart. So
/// the bar now carries the payable figure and the two actions, the breakdown
/// sits under the lines it sums, and the room that frees is roughly what the
/// pinned header costs.
class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.openedAt,
    required this.state,
    required this.strings,
    required this.actions,
  });

  final DateTime openedAt;
  final InvoiceEditorState state;
  final AppStrings strings;
  final _EditorActions actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _PinnedHeader(openedAt: openedAt, state: state, strings: strings),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.xl,
            ),
            children: <Widget>[
              // Without its add buttons: they are in the header above, and two
              // controls doing one thing is one too many (§10).
              InvoiceLinesSection(openedAt: openedAt, showAddActions: false),
              const SizedBox(height: AppSpacing.xl),
              // Directly under the lines it sums.
              _TotalOrEmpty(state: state, strings: strings, dense: true),
              const SizedBox(height: AppSpacing.xxl),
              // **Collapsible here and nowhere else** (D-054), and without the
              // customer, which is pinned above. What is left behind the fold
              // is genuinely optional: a date most invoices take as offered, a
              // discount and a rate most never set, and a note.
              InvoiceDetailsSection(
                openedAt: openedAt,
                collapsible: true,
                showCustomer: false,
              ),
            ],
          ),
        ),
        _StickyBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _PinnedGrandTotal(
                key: kPinnedGrandTotalKey,
                state: state,
                strings: strings,
              ),
              const SizedBox(height: AppSpacing.md),
              actions.stacked(context),
            ],
          ),
        ),
      ],
    );
  }
}

/// The two acts an invoice cannot exist without, held above the scroll.
///
/// A hairline beneath rather than a card: this is chrome, not content, and it
/// has to read as the edge of the scrolling region rather than as the first
/// thing in it.
class _PinnedHeader extends ConsumerWidget {
  const _PinnedHeader({
    required this.openedAt,
    required this.state,
    required this.strings,
  });

  final DateTime openedAt;
  final InvoiceEditorState state;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final InvoiceEditor editor = ref.read(
      invoiceEditorProvider(openedAt).notifier,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: AppBorders.hairline,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InvoiceCustomerField(
              strings: strings,
              customerId: state.customerId,
              onPick: () => pickInvoiceCustomer(context, editor),
              onClear: () => editor.selectCustomer(null),
            ),
            const SizedBox(height: AppSpacing.md),
            InvoiceAddLineActions(
              strings: strings,
              onAddFromCatalogue: () =>
                  addInvoiceLineFromCatalogue(context, ref, openedAt),
              onAddCustom: () => addCustomInvoiceLine(context, ref, openedAt),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two panes: the document's fields, and its lines.
///
/// A tablet in portrait and a large phone in landscape both have width to spend
/// and height to save, so the two halves of the form sit beside each other and
/// scroll independently rather than one below the other. The summary and the
/// actions run across the bottom, where they belong to both panes.
class _TabletLayout extends StatelessWidget {
  const _TabletLayout({
    required this.openedAt,
    required this.state,
    required this.strings,
    required this.actions,
  });

  final DateTime openedAt;
  final InvoiceEditorState state;
  final AppStrings strings;
  final _EditorActions actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 5:7 rather than half and half. The fields are labelled inputs
              // of a known width; the lines are rows that carry a description
              // and three figures, and they are what runs out of room first.
              Expanded(
                flex: 5,
                child: ListView(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  children: <Widget>[InvoiceDetailsSection(openedAt: openedAt)],
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                flex: 7,
                child: ListView(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  children: <Widget>[InvoiceLinesSection(openedAt: openedAt)],
                ),
              ),
            ],
          ),
        ),
        _StickyBar(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: _TotalOrEmpty(
                  state: state,
                  strings: strings,
                  dense: true,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              SizedBox(width: AppLayout.detailPanelWidth, child: actions),
            ],
          ),
        ),
      ],
    );
  }
}

/// The fields beside the breakdown, and the table underneath both.
///
/// **§10 asks for a sticky summary panel on this tier, and the measurement
/// forced a different shape.** A 320-pixel panel down the side leaves 792
/// pixels for the main column, and the lines table needs a description, a
/// quantity and **two money columns** — money columns that are fixed-width by
/// rule (D-037), because a flexed one clips a figure at some window size. At
/// 792 they overflowed by 58 pixels. The panel and the table cannot both have
/// the width, at any realistic window: the content column is capped at 1240 for
/// readability, and the table wants nearly all of it.
///
/// So the width goes to the table, and the summary splits in two by what it is
/// for: the **breakdown** sits beside the fields, which are short and were
/// wasting the width anyway, and the **decision** — the grand total and the two
/// actions — is what stays pinned. Detail scrolls; the figure being agreed to
/// does not. That is the sticky-summary requirement met by its purpose rather
/// than by its silhouette, and it is what makes this tier's arrangement neither
/// the phone's single column nor the tablet's two panes.
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.openedAt,
    required this.state,
    required this.strings,
    required this.actions,
  });

  final DateTime openedAt;
  final InvoiceEditorState state;
  final AppStrings strings;
  final _EditorActions actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: InvoiceDetailsSection(openedAt: openedAt)),
                  const SizedBox(width: AppSpacing.xxl),
                  // Fixed, not a flex share: the panel holds labelled figures,
                  // and extra width only puts each value further from its
                  // label — the reasoning `detailPanelWidth` was introduced
                  // with.
                  SizedBox(
                    width: AppLayout.detailPanelWidth,
                    child: _TotalOrEmpty(state: state, strings: strings),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Full width, which is what lets it be a real table rather than
              // a squeezed one.
              InvoiceLinesSection(openedAt: openedAt),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
        _StickyBar(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: _PinnedGrandTotal(
                  key: kPinnedGrandTotalKey,
                  state: state,
                  strings: strings,
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              SizedBox(width: AppLayout.detailPanelWidth, child: actions),
            ],
          ),
        ),
      ],
    );
  }
}

/// Identifies the **pinned** payable figure.
///
/// The same label «مبلغ قابل پرداخت» appears twice on a phone since D-096 —
/// once in the breakdown inside the scroll, and once in the bar — and that is
/// correct: they are the same figure answering two questions, "what does this
/// add up to" and "what am I agreeing to". A test that measured whether the bar
/// stays put has to be able to say which one it means, and matching on the text
/// cannot. Public and named rather than a bare string at the call site, so the
/// two ends cannot drift apart.
const Key kPinnedGrandTotalKey = Key('invoice-editor.pinned-grand-total');

/// The one figure that stays on screen: what this invoice comes to.
///
/// Not the whole breakdown — that is in the panel or the scroll above, and
/// repeating it in the bar would be two answers to the same question a scroll
/// apart. Silent until there is a line, for the reason [_TotalOrEmpty] gives.
///
/// **Used by the phone as well as the desktop since D-096.** The size steps
/// down where the width does not allow the large style: `AppLayout` records
/// that an [AmountSize.large] figure needs 376 logical pixels at the top of the
/// ladder, and a 328-pixel phone does not have them. A figure is never clipped
/// to keep a type size (D-057).
class _PinnedGrandTotal extends StatelessWidget {
  const _PinnedGrandTotal({
    required this.state,
    required this.strings,
    super.key,
  });

  final InvoiceEditorState state;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (state.lines.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          strings.invoiceSummaryGrandTotal,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(width: AppSpacing.lg),
        Flexible(
          child: AmountText(
            state.totals.grandTotal,
            unitLabel: strings.unitToman,
            size: context.tier.isMobile ? AmountSize.medium : AmountSize.large,
          ),
        ),
      ],
    );
  }
}

/// The summary, or the sentence that stands in for it before there is one.
///
/// An invoice with no lines has totals — all of them zero — and rendering them
/// would be honest but useless: a column of «۰ تومان» tells the user nothing
/// and looks like a fault. So until there is a line, the panel says what will
/// appear there instead (§10's designed empty state, applied to a panel rather
/// than a list).
class _TotalOrEmpty extends StatelessWidget {
  const _TotalOrEmpty({
    required this.state,
    required this.strings,
    this.dense = false,
  });

  final InvoiceEditorState state;
  final AppStrings strings;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (state.lines.isEmpty) {
      final ThemeData theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          strings.invoiceSummaryEmpty,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return InvoiceTotalsSummary(
      totals: InvoiceSummaryFigures.ofCalculation(state.totals),
      strings: strings,
      dense: dense,
    );
  }
}

/// The bar the two touch tiers pin to the bottom of the screen.
///
/// A hairline above it and the page's own surface behind it, so content
/// scrolling underneath is visibly separated rather than bleeding into the
/// actions. `SafeArea` on the bottom only: the top of this widget is inside the
/// page, not against the status bar.
class _StickyBar extends StatelessWidget {
  const _StickyBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: AppBorders.hairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.md,
          ),
          child: child,
        ),
      ),
    );
  }
}
