import 'dart:async';

import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/settings_repository.dart';
import 'package:factorino/features/invoices/application/invoice_editor.dart';
import 'package:factorino/features/invoices/domain/invoice_editor_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// The controller that owns the editing state.
///
/// Two claims, and they are the reason it exists rather than the screen holding
/// a mutable list: **every intent rebuilds the state**, so the totals cannot
/// belong to an earlier version of the lines, and **the settings are watched**,
/// so the last step of §4's tax chain follows a change instead of going stale.
void main() {
  final DateTime openedAt = DateTime.utc(2026, 8, 24, 12);

  const AppSettings initialSettings = AppSettings(
    defaultTaxRateBp: 900,
    roundingUnitRial: 0,
    invoiceNumberPrefix: 'INV',
  );

  InvoiceLineEntry line({int priceRial = 1000000, int quantityMilli = 1000}) {
    return InvoiceLineEntry(
      title: 'خدمات',
      unit: 'عدد',
      unitPrice: Money.rial(priceRial),
      quantityMilli: quantityMilli,
    );
  }

  /// A container wired the way the app wires it, over a settings repository a
  /// test can push new values through.
  ({ProviderContainer container, _FakeSettingsRepository settings}) open() {
    final _FakeSettingsRepository settings = _FakeSettingsRepository(
      initialSettings,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(container.dispose);
    // A listener, because the editor is auto-disposed: without one, each
    // `read` builds it and throws it away again, and the settings stream
    // underneath is disposed mid-load. In the application a widget watching
    // the provider is what holds it -- this stands in for that widget.
    container.listen(
      invoiceEditorProvider(openedAt),
      (_, _) {},
      fireImmediately: true,
    );
    return (container: container, settings: settings);
  }

  Future<InvoiceEditorState> stateOf(ProviderContainer container) =>
      container.read(invoiceEditorProvider(openedAt).future);

  InvoiceEditor notifierOf(ProviderContainer container) =>
      container.read(invoiceEditorProvider(openedAt).notifier);

  test('opens empty, on the instant the form was opened', () async {
    final container = open().container;
    final InvoiceEditorState state = await stateOf(container);

    expect(state.issueDate, openedAt);
    expect(state.lines, isEmpty);
    expect(state.customerId, isNull);
    expect(state.isComplete, isFalse);
    expect(state.totals.grandTotal, Money.zero);
  });

  test('every line edit recomputes the totals', () async {
    final container = open().container;
    await stateOf(container);
    final InvoiceEditor editor = notifierOf(container);

    editor.addLine(line(priceRial: 1000000));
    expect(
      container.read(invoiceEditorProvider(openedAt)).value!.totals.grandTotal,
      // 1,000,000 + 9% = 1,090,000
      Money.rial(1090000),
    );

    editor.addLine(line(priceRial: 500000));
    expect(
      container.read(invoiceEditorProvider(openedAt)).value!.totals.grandTotal,
      Money.rial(1635000),
    );

    editor.removeLine(0);
    expect(
      container.read(invoiceEditorProvider(openedAt)).value!.totals.grandTotal,
      Money.rial(545000),
    );
  });

  test('updateLine changes one field without restating the rest', () async {
    final container = open().container;
    await stateOf(container);
    final InvoiceEditor editor = notifierOf(container);

    editor.addLine(line(priceRial: 1000000, quantityMilli: 1000));
    editor.updateLine(
      0,
      (InvoiceLineEntry l) => l.copyWith(quantityMilli: 2500),
    );

    final InvoiceEditorState state = container
        .read(invoiceEditorProvider(openedAt))
        .value!;
    expect(state.lines.single.quantityMilli, 2500);
    expect(state.lines.single.unitPrice, Money.rial(1000000));
    expect(state.totals.lines.single.gross, Money.rial(2500000));
  });

  test('a stale index from a removed row is ignored, not thrown', () async {
    // An ordinary race in a list being edited: a row's callback fires after the
    // row has gone. Throwing here would surface as a crash from a widget the
    // user has already dismissed.
    final container = open().container;
    await stateOf(container);
    final InvoiceEditor editor = notifierOf(container);

    editor.addLine(line());
    editor.removeLine(0);
    editor.updateLine(0, (InvoiceLineEntry l) => l.copyWith(quantityMilli: 5));
    editor.removeLine(3);

    expect(
      container.read(invoiceEditorProvider(openedAt)).value!.lines,
      isEmpty,
    );
  });

  test(
    'moveLine reorders, because position is what the document prints',
    () async {
      final container = open().container;
      await stateOf(container);
      final InvoiceEditor editor = notifierOf(container);

      editor.addLine(line(priceRial: 100));
      editor.addLine(line(priceRial: 200));
      editor.addLine(line(priceRial: 300));
      editor.moveLine(2, 0);

      expect(
        container
            .read(invoiceEditorProvider(openedAt))
            .value!
            .lines
            .map((InvoiceLineEntry l) => l.unitPrice.rial)
            .toList(),
        <int>[300, 100, 200],
      );
    },
  );

  group('discount is an amount or a percentage, never both', () {
    test('setting an amount clears a percentage', () async {
      // The engine lets a percentage win over an absolute amount (§4 step 2),
      // so a stale percentage left behind would silently override the amount
      // the user just typed.
      final container = open().container;
      await stateOf(container);
      final InvoiceEditor editor = notifierOf(container);

      editor.addLine(line(priceRial: 1000000));
      editor.setDiscountPercent(1000);
      expect(
        container
            .read(invoiceEditorProvider(openedAt))
            .value!
            .totals
            .invoiceDiscount,
        Money.rial(100000),
      );

      editor.setDiscountAmount(Money.rial(50000));
      final InvoiceEditorState state = container
          .read(invoiceEditorProvider(openedAt))
          .value!;
      expect(state.discountPercentBp, isNull);
      expect(state.totals.invoiceDiscount, Money.rial(50000));
    });

    test('setting a percentage clears an amount', () async {
      final container = open().container;
      await stateOf(container);
      final InvoiceEditor editor = notifierOf(container);

      editor.addLine(line(priceRial: 1000000));
      editor.setDiscountAmount(Money.rial(50000));
      editor.setDiscountPercent(2000);

      final InvoiceEditorState state = container
          .read(invoiceEditorProvider(openedAt))
          .value!;
      expect(state.discount, Money.zero);
      expect(state.totals.invoiceDiscount, Money.rial(200000));
    });
  });

  test('a tax override of zero is kept, and null clears it', () async {
    // D-026 through the controller: the two must stay distinguishable all the
    // way from the widget that sets them.
    final container = open().container;
    await stateOf(container);
    final InvoiceEditor editor = notifierOf(container);

    editor.addLine(line());
    editor.setTaxRate(0);
    expect(
      container
          .read(invoiceEditorProvider(openedAt))
          .value!
          .totals
          .lines
          .single
          .resolvedTaxRateBp,
      0,
    );

    editor.setTaxRate(null);
    expect(
      container
          .read(invoiceEditorProvider(openedAt))
          .value!
          .totals
          .lines
          .single
          .resolvedTaxRateBp,
      900,
    );
  });

  test('a settings change updates the preview and keeps the entries', () async {
    // The last step of the tax chain lives in settings. A preview that captured
    // the rate at open time would keep describing a rule that no longer
    // applies -- and the repository, which re-reads settings inside the write
    // transaction, would then store something the user was never shown.
    final opened = open();
    await stateOf(opened.container);
    final InvoiceEditor editor = notifierOf(opened.container);

    editor.selectCustomer('c1');
    editor.addLine(line(priceRial: 1000000));
    expect(
      opened.container
          .read(invoiceEditorProvider(openedAt))
          .value!
          .totals
          .grandTotal,
      Money.rial(1090000),
    );

    opened.settings.emit(initialSettings.copyWith(defaultTaxRateBp: 1000));
    // The stream event, the settings provider's rebuild and the editor's own
    // rebuild are three separate turns of the event loop.
    await pumpEventQueue();

    final InvoiceEditorState state = opened.container
        .read(invoiceEditorProvider(openedAt))
        .value!;
    // The entries survived the rebuild...
    expect(state.lines, hasLength(1));
    expect(state.customerId, 'c1');
    // ...and the figure followed the rule.
    expect(state.totals.grandTotal, Money.rial(1100000));
  });

  group('the payment term is a setting now (D-052)', () {
    test('a fresh form derives the due date from it', () async {
      final opened = open();
      opened.settings.emit(initialSettings.copyWith(paymentTermDays: 45));
      await pumpEventQueue();

      final InvoiceEditorState state = opened.container
          .read(invoiceEditorProvider(openedAt))
          .value!;
      expect(state.dueDate, defaultDueDate(openedAt, 45));
      expect(state.dueDateFollowsIssueDate, isTrue);
    });

    test('changing the term moves a derived due date', () async {
      // The same argument that makes a derived due date follow the issue date
      // makes it follow the term: it is a statement about the term, not about
      // a calendar day. A form left open across a settings change would
      // otherwise keep a date computed from a rule that no longer applies.
      final opened = open();
      await stateOf(opened.container);
      expect(
        opened.container.read(invoiceEditorProvider(openedAt)).value!.dueDate,
        defaultDueDate(openedAt, kDefaultPaymentTermDays),
      );

      opened.settings.emit(initialSettings.copyWith(paymentTermDays: 60));
      await pumpEventQueue();

      expect(
        opened.container.read(invoiceEditorProvider(openedAt)).value!.dueDate,
        defaultDueDate(openedAt, 60),
      );
    });

    test('a due date the user chose is not moved by it', () async {
      // A date the user set is a commitment to a day. Dragging it because an
      // unrelated setting changed would silently rewrite an agreement.
      final opened = open();
      await stateOf(opened.container);
      final InvoiceEditor editor = notifierOf(opened.container);

      final DateTime chosen = DateTime.utc(2026, 9, 1, 12);
      editor.setDueDate(chosen);

      opened.settings.emit(initialSettings.copyWith(paymentTermDays: 60));
      await pumpEventQueue();

      final InvoiceEditorState state = opened.container
          .read(invoiceEditorProvider(openedAt))
          .value!;
      expect(state.dueDate, chosen);
      expect(state.dueDateFollowsIssueDate, isFalse);
    });
  });
}

/// A settings repository a test can push new values through, so the editor's
/// `ref.watch` can be exercised rather than assumed.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._current);

  AppSettings _current;
  final StreamController<AppSettings> _controller =
      StreamController<AppSettings>.broadcast();

  void emit(AppSettings settings) {
    _current = settings;
    _controller.add(settings);
  }

  @override
  Future<AppSettings> read() async => _current;

  @override
  Stream<AppSettings> watch() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<AppSettings> write(AppSettings settings) async {
    emit(settings);
    return settings;
  }

  @override
  Future<void> markBackedUp(DateTime at) async {}

  @override
  Future<void> markTutorialSeen(DateTime at) async {}
}
