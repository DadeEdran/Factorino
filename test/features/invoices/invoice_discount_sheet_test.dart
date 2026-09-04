import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/settings_repository.dart';
import 'package:factorino/features/invoices/application/invoice_editor.dart';
import 'package:factorino/features/invoices/domain/invoice_editor_state.dart';
import 'package:factorino/features/invoices/presentation/widgets/invoice_discount_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screen_harness.dart';

/// The discount screen (D-098).
///
/// **One place that answers "what is coming off this invoice", at both levels.**
/// Before this, a per-line discount was a field inside the sheet that adds a
/// line and the invoice-level one was among the optional fields under
/// «مشخصات فاکتور» — the same question asked in two forms, on two screens, one
/// of them mixed into the act of adding a product.
///
/// Three things are pinned here, and the third is the one that had nowhere to
/// live before: that the preview is the **engine's** answer, that it updates
/// while typing, and that D-027's clamp warnings are stated against the figure
/// that caused them **before** anything is applied.
void main() {
  final DateTime openedAt = DateTime.utc(2026, 8, 24, 12);

  const AppSettings settings = AppSettings(
    // Zero VAT, so the arithmetic under test is the discount's alone. Tax has
    // its own suites; mixing it in here would make every expectation below a
    // second assertion about §4 step 6.
    defaultTaxRateBp: 0,
    roundingUnitRial: 0,
    invoiceNumberPrefix: 'INV',
  );

  InvoiceLineEntry line({
    String title = 'کالا',
    int toman = 100000,
    int quantityMilli = 1000,
  }) => InvoiceLineEntry(
    title: title,
    unit: 'عدد',
    unitPrice: Money.toman(toman),
    quantityMilli: quantityMilli,
  );

  /// A host screen with a button that opens the sheet, which is how it is
  /// reached in the application — the sheet takes a `WidgetRef` and writes
  /// through the editor, so pumping it bare would test a different thing.
  Future<ProviderContainer> pumpHost(
    WidgetTester tester, {
    required List<InvoiceLineEntry> lines,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) async {
    await pumpScreen(
      tester,
      _Host(openedAt: openedAt),
      viewInsets: viewInsets,
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(
          _FakeSettingsRepository(settings),
        ),
      ],
    );
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(_Host)),
    );
    final InvoiceEditor editor = container.read(
      invoiceEditorProvider(openedAt).notifier,
    );
    for (final InvoiceLineEntry entry in lines) {
      editor.addLine(entry);
    }
    await tester.pumpAndSettle();
    return container;
  }

  InvoiceEditorState stateOf(ProviderContainer container) =>
      container.read(invoiceEditorProvider(openedAt)).requireValue;

  Future<AppStrings> open(WidgetTester tester) async {
    final AppStrings strings = stringsOf(tester, _Host);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    return strings;
  }

  /// Types [value] into the control identified by [key].
  ///
  /// **By key and scrolled to, not by index.** Every control on this sheet
  /// carries the same two Persian words, so matching on the label cannot say
  /// which one is meant — and the list is virtualized, so a control below the
  /// fold is not in the tree until it is scrolled to. Counting fields found
  /// "the third one that happened to be built", which is a different control on
  /// a different screen height.
  Future<void> reach(WidgetTester tester, Key key) async {
    final Finder target = find.byKey(key);
    // Built already on a short invoice; below the fold on a long one. Asking
    // `scrollUntilVisible` to find something already on screen is not the same
    // call, so the two cases are separated rather than merged.
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        200,
        // The list's own scrollable, first in tree order. A `SegmentedButton`
        // brings one of its own, so the finder has to be narrowed or it
        // matches several.
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    } else {
      await tester.ensureVisible(target);
    }
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, Key key, String value) async {
    await reach(tester, key);
    await tester.enterText(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(TextFormField),
      ),
      value,
    );
    await tester.pumpAndSettle();
  }

  /// Switches one control to percentage mode.
  Future<void> toPercent(
    WidgetTester tester,
    AppStrings strings,
    Key key,
  ) async {
    await reach(tester, key);
    await tester.tap(
      find.descendant(
        of: find.byKey(key),
        matching: find.text(strings.invoiceLineDiscountModePercent),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Taps the pinned commit action, which never scrolls (D-062).
  Future<void> apply(WidgetTester tester, AppStrings strings) async {
    await tester.tap(find.text(strings.invoiceDiscountApply));
    await tester.pumpAndSettle();
  }

  testWidgets('an invoice discount typed as an amount reaches the engine', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpHost(
      tester,
      lines: <InvoiceLineEntry>[line()],
    );
    final AppStrings strings = await open(tester);

    await type(tester, kInvoiceDiscountInvoiceKey, '20000');
    await apply(tester, strings);

    final InvoiceEditorState state = stateOf(container);
    expect(state.discount, Money.toman(20000));
    expect(state.discountPercentBp, isNull);
    // Allocated across the lines by the engine, before tax (§4 step 4).
    expect(state.totals.invoiceDiscount, Money.toman(20000));
  });

  testWidgets('switching to a percentage clears the amount', (
    WidgetTester tester,
  ) async {
    // The two are alternatives, not two views of one number: `10` means ten
    // Toman in one mode and ten percent in the other. A stale amount left
    // beside a percentage would reach the engine alongside it (§4 step 2).
    final ProviderContainer container = await pumpHost(
      tester,
      lines: <InvoiceLineEntry>[line()],
    );
    final AppStrings strings = await open(tester);

    await type(tester, kInvoiceDiscountInvoiceKey, '20000');
    expect(find.text('20000'), findsOneWidget);

    await toPercent(tester, strings, kInvoiceDiscountInvoiceKey);
    expect(find.text('20000'), findsNothing);

    await apply(tester, strings);

    expect(stateOf(container).discount, Money.zero);
    expect(stateOf(container).discountPercentBp, isNull);
  });

  testWidgets('a percentage is stored as basis points, not resolved here', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpHost(
      tester,
      lines: <InvoiceLineEntry>[line()],
    );
    final AppStrings strings = await open(tester);

    await toPercent(tester, strings, kInvoiceDiscountInvoiceKey);
    await type(tester, kInvoiceDiscountInvoiceKey, '9.5');
    await apply(tester, strings);

    // Two decimal places of a percent *is* basis points: 9.5 at scale 100 is
    // 950, exactly, with no rounding. The amount is the engine's to resolve.
    expect(stateOf(container).discountPercentBp, 950);
    expect(stateOf(container).discount, Money.zero);
  });

  testWidgets('a per-line discount reaches the line it was entered against', (
    WidgetTester tester,
  ) async {
    // **The capability D-097 removed from the add-a-line sheet, restored
    // here.** Two lines, and only the second is discounted, so the test would
    // fail if the sheet applied an entry to the wrong line — which is the one
    // thing a screen listing every line has to get right.
    final ProviderContainer container = await pumpHost(
      tester,
      lines: <InvoiceLineEntry>[
        line(title: 'اول', toman: 100000),
        line(title: 'دوم', toman: 200000),
      ],
    );
    final AppStrings strings = await open(tester);

    // The second line specifically, named rather than counted.
    await type(tester, invoiceDiscountLineKey(1), '50000');
    await apply(tester, strings);

    final InvoiceEditorState state = stateOf(container);
    expect(state.lines[0].discount, Money.zero);
    expect(state.lines[1].discount, Money.toman(50000));
    // And nothing else about either line moved.
    expect(state.lines[0].title, 'اول');
    expect(state.lines[1].unitPrice, Money.toman(200000));
  });

  testWidgets(
    'the payable figure updates while typing, before anything is applied',
    (WidgetTester tester) async {
      // **The screen's whole purpose.** "Apply a discount" is an intention; what
      // the user agrees to is a number, and it is shown before they commit.
      final ProviderContainer container = await pumpHost(
        tester,
        lines: <InvoiceLineEntry>[line(toman: 100000)],
      );
      final AppStrings strings = await open(tester);

      expect(find.text(strings.invoiceDiscountPayableNow), findsOneWidget);
      expect(find.text(strings.invoiceDiscountPayableAfter), findsOneWidget);

      await type(tester, kInvoiceDiscountInvoiceKey, '20000');

      // ۸۰٬۰۰۰ — the engine's answer, on screen, with nothing committed yet.
      expect(find.text('۸۰٬۰۰۰'), findsOneWidget);
      expect(
        stateOf(container).discount,
        Money.zero,
        reason: 'the preview must not write; that is what «اعمال» is for',
      );
    },
  );

  testWidgets('dismissing applies nothing at all', (WidgetTester tester) async {
    final ProviderContainer container = await pumpHost(
      tester,
      lines: <InvoiceLineEntry>[line()],
    );
    await open(tester);

    await type(tester, kInvoiceDiscountInvoiceKey, '20000');

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(stateOf(container).discount, Money.zero);
  });

  testWidgets('a clamped discount is stated here, while it is being typed', (
    WidgetTester tester,
  ) async {
    // **D-027 finally has somewhere to be said.** The engine has reported a
    // clamped discount as data since Phase 4, and the only screen rendering it
    // was the lines section of the form — where a user entering a discount was
    // not looking, and only after the value had been committed. Here it appears
    // against the field that caused it, before anything is applied.
    await pumpHost(tester, lines: <InvoiceLineEntry>[line(toman: 100000)]);
    final AppStrings strings = await open(tester);

    expect(find.text(strings.invoiceWarningsTitle), findsNothing);

    // More off the line than the line is worth.
    await type(tester, invoiceDiscountLineKey(0), '150000');

    expect(find.text(strings.invoiceWarningsTitle), findsOneWidget);
    // Both figures, named separately — requested and applied — so the
    // difference is readable rather than derivable.
    expect(
      find.text(
        strings.invoiceWarningLineDiscountClamped(
          '۱',
          '۱۵۰٬۰۰۰',
          '۱۰۰٬۰۰۰',
          strings.unitToman,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the warning goes away when the figure is corrected', (
    WidgetTester tester,
  ) async {
    // A warning that stayed after the input was fixed would train the user to
    // ignore it, which is the one thing a warning cannot afford.
    await pumpHost(tester, lines: <InvoiceLineEntry>[line(toman: 100000)]);
    final AppStrings strings = await open(tester);

    await type(tester, invoiceDiscountLineKey(0), '150000');
    expect(find.text(strings.invoiceWarningsTitle), findsOneWidget);

    await type(tester, invoiceDiscountLineKey(0), '50000');
    expect(find.text(strings.invoiceWarningsTitle), findsNothing);
  });

  testWidgets('the action and the warnings stay above the keyboard', (
    WidgetTester tester,
  ) async {
    // **D-062's rule, on the sheet that needed it most.** Every control here
    // raises a numeric keyboard, and the thing being agreed to — «اعمال تخفیف»,
    // and the sentence saying the figure was clamped — must not be the part
    // that goes under it. 255 logical pixels is what a Redmi Note 8 Pro
    // actually takes; a test that invented a friendlier keyboard would be the
    // small-test-data mistake in a different unit.
    //
    // This lives here rather than in `sheet_keyboard_test.dart` because the
    // sheet needs an editor with lines behind it, and that file's harness opens
    // sheets from a bare context.
    const double keyboard = 255;

    await pumpHost(
      tester,
      lines: <InvoiceLineEntry>[line(toman: 100000)],
      viewInsets: const EdgeInsets.only(bottom: keyboard),
    );
    final AppStrings strings = await open(tester);

    // A clamped figure, so the warnings are on screen with the action.
    await type(tester, invoiceDiscountLineKey(0), '150000');

    final double visibleBottom = kMobileSize.height - keyboard;

    for (final Finder pinned in <Finder>[
      find.widgetWithText(FilledButton, strings.invoiceDiscountApply),
      find.text(strings.invoiceWarningsTitle),
    ]) {
      expect(pinned, findsOneWidget);
      expect(
        tester.getRect(pinned).bottom,
        lessThanOrEqualTo(visibleBottom),
        reason:
            'it sits at ${tester.getRect(pinned).bottom.toInt()}, past the '
            '${visibleBottom.toInt()} the keyboard leaves — a user typing a '
            'discount would not see what they are committing to',
      );
    }
  });

  testWidgets('an existing discount opens in the field it was entered in', (
    WidgetTester tester,
  ) async {
    // Reopening the screen shows what is already set, in the mode it was set
    // in — otherwise the user cannot tell a discount they gave from one they
    // are about to give, and would enter it twice.
    final ProviderContainer container = await pumpHost(
      tester,
      lines: <InvoiceLineEntry>[line()],
    );
    container
        .read(invoiceEditorProvider(openedAt).notifier)
        .setDiscountPercent(1500);
    await tester.pumpAndSettle();

    await open(tester);
    expect(find.text('15'), findsOneWidget);
  });
}

/// A screen with one button that opens the sheet.
class _Host extends ConsumerWidget {
  const _Host({required this.openedAt});

  final DateTime openedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched so the host rebuilds when the editor does, which is what makes
    // `stateOf` read the state the sheet actually wrote.
    ref.watch(invoiceEditorProvider(openedAt));

    return Center(
      child: FilledButton(
        onPressed: () => showInvoiceDiscountSheet(context, ref, openedAt),
        child: const Text('...'),
      ),
    );
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._settings);

  final AppSettings _settings;

  @override
  Future<AppSettings> read() async => _settings;

  @override
  Stream<AppSettings> watch() => Stream<AppSettings>.value(_settings);

  @override
  Future<AppSettings> write(AppSettings settings) async => settings;

  @override
  Future<void> markBackedUp(DateTime at) async {}
}
