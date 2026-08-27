import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_strings.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/router/destinations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/page_body.dart';
import '../../../data/models/invoice.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../application/invoice_editor.dart';
import '../domain/invoice_editor_state.dart';
import '../domain/invoice_number_label.dart';
import 'widgets/invoice_details_section.dart';
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
/// * **Mobile** — one column, one field per row, everything reached by
///   scrolling; the summary and both actions live in a bar pinned to the bottom
///   of the screen, so the figure the user is deciding about stays visible while
///   they edit the lines that change it.
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
  const InvoiceEditorScreen({super.key});

  @override
  ConsumerState<InvoiceEditorScreen> createState() =>
      _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends ConsumerState<InvoiceEditorScreen> {
  /// The family key, settled once. See the class comment.
  late final DateTime _openedAt = ref.read(nowProvider);

  /// True while a write is in flight, so a double tap cannot produce two
  /// invoices. Local rather than derived, because `InvoiceEditor` returns its
  /// result rather than parking it in `state` — the controller's `AsyncValue`
  /// describes the invoice being edited, not the save.
  bool _writing = false;

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
      busy: _writing,
      onSaveDraft: _saveDraft,
      onIssue: () => _issue(strings, state),
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
    required this.busy,
    required this.onSaveDraft,
    required this.onIssue,
  });

  final AppStrings strings;
  final String? blockedReason;
  final bool busy;
  final VoidCallback onSaveDraft;
  final VoidCallback onIssue;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (vertical) ...<Widget>[
          issue,
          const SizedBox(height: AppSpacing.sm),
          draft,
        ] else
          Row(
            children: <Widget>[
              Expanded(child: draft),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: issue),
            ],
          ),
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

/// One column, and a bar pinned to the bottom.
///
/// The bar is what makes this a phone layout rather than a narrow desktop one:
/// the grand total and the two actions stay on screen while the user scrolls
/// through the lines that change it, so the figure being decided about is never
/// the one thing that has scrolled away.
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
        Expanded(
          child: ListView(
            // Room above the first field for its floating label, and room
            // below the last for the bar -- the same clearance a floating
            // action button needs, and for the same reason.
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xl,
            ),
            children: <Widget>[
              InvoiceDetailsSection(openedAt: openedAt),
              const SizedBox(height: AppSpacing.xxl),
              InvoiceLinesSection(openedAt: openedAt),
            ],
          ),
        ),
        _StickyBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _TotalOrEmpty(state: state, strings: strings, dense: true),
              const SizedBox(height: AppSpacing.md),
              actions.stacked(context),
            ],
          ),
        ),
      ],
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
                child: _PinnedGrandTotal(state: state, strings: strings),
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

/// The one figure that stays on screen: what this invoice comes to.
///
/// Not the whole breakdown — that is in the panel above, and repeating it in
/// the bar would be two answers to the same question a scroll apart. Silent
/// until there is a line, for the reason [_TotalOrEmpty] gives.
class _PinnedGrandTotal extends StatelessWidget {
  const _PinnedGrandTotal({required this.state, required this.strings});

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
            size: AmountSize.large,
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
      totals: state.totals,
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
