import 'package:factorino/core/date/jalali_instant.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_detail.dart';
import 'package:factorino/data/models/invoice_draft.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/invoice_repository.dart';
import 'package:factorino/features/invoices/application/invoice_editor.dart';
import 'package:factorino/features/invoices/domain/invoice_editor_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../data/repositories/repository_harness.dart';

/// The save — Phase 4 increment (c), and the first write of a whole invoice
/// from the editor.
///
/// Through the **real encrypted database**, because the properties that matter
/// are about what reaches storage: a draft takes no number, issuing allocates
/// one, and neither path lets a caller supply a total.
void main() {
  late RepositoryHarness harness;
  late String customerId;
  late ProviderContainer container;

  final DateTime openedAt = startOfJalaliDayUtc(Jalali(1405, 6, 2));

  setUp(() async {
    harness = await RepositoryHarness.open();
    customerId = (await harness.customer()).id;

    container = ProviderContainer(
      overrides: <Override>[
        invoiceRepositoryProvider.overrideWithValue(harness.invoices),
        settingsRepositoryProvider.overrideWithValue(harness.settings),
      ],
    );
    addTearDown(container.dispose);
    // A listener stands in for the widget that would hold this auto-disposed
    // provider open; without one each read builds and discards it.
    container.listen(
      invoiceEditorProvider(openedAt),
      (_, _) {},
      fireImmediately: true,
    );
    await container.read(invoiceEditorProvider(openedAt).future);
  });

  tearDown(() async => harness.close());

  InvoiceEditor editor() =>
      container.read(invoiceEditorProvider(openedAt).notifier);

  InvoiceEditorState state() =>
      container.read(invoiceEditorProvider(openedAt)).requireValue;

  /// Fills the editor with everything a complete invoice needs.
  void fillComplete() {
    editor().selectCustomer(customerId);
    editor().addLine(
      InvoiceLineEntry(
        title: 'خدمات',
        unit: 'ساعت',
        unitPrice: Money.toman(100000),
        quantityMilli: 1500,
      ),
    );
  }

  test('an incomplete invoice does not write', () async {
    // No customer and no lines. `isComplete` refuses rather than `toDraft`
    // inventing a placeholder customer, which would write a row referencing
    // nothing.
    expect(await editor().save(), isNull);

    editor().selectCustomer(customerId);
    expect(await editor().save(), isNull, reason: 'still no lines');

    expect(await harness.invoices.count(), 0);
  });

  test('saving writes a draft, and a draft takes no number', () async {
    fillComplete();
    final InvoiceCreationResult? result = await editor().save();

    expect(result, isNotNull);
    expect(result!.invoice.status, InvoiceStatus.draft);
    // D-048: allocating here meant an abandoned draft consumed a number
    // permanently, because the unique index covers soft-deleted rows.
    expect(result.invoice.number, isNull);
    expect(result.invoice.numberYear, isNull);
    expect(result.invoice.numberSequence, isNull);
  });

  test('the stored totals are the previewed ones', () async {
    fillComplete();
    final InvoiceEditorState previewed = state();
    final InvoiceCreationResult? result = await editor().save();

    // The editor sends no total — `toDraft` carries none — and the repository
    // recomputes inside the write transaction. This asserts the two agree; the
    // exhaustive version of this claim is
    // `invoice_preview_matches_write_test.dart`.
    expect(result!.invoice.grandTotal, previewed.totals.grandTotal);
    expect(result.invoice.subtotal, previewed.totals.subtotal);
    expect(result.invoice.totalTax, previewed.totals.totalTax);
  });

  test(
    'the invoice-level fields the editor holds are the ones written',
    () async {
      fillComplete();
      final DateTime due = startOfJalaliDayUtc(Jalali(1405, 7, 2));
      editor().setDueDate(due);
      editor().setTaxRate(0);
      editor().setDiscountPercent(1000);
      editor().setNotes('پرداخت نقدی');

      final InvoiceCreationResult? result = await editor().save();
      final InvoiceDetail detail = (await harness.invoices.findDetail(
        result!.invoice.id,
      ))!;

      expect(detail.invoice.customerId, customerId);
      expect(detail.invoice.issueDate.toUtc(), openedAt);
      expect(detail.invoice.dueDate!.toUtc(), due);
      // Zero, not null — this invoice is untaxed, as distinct from inheriting
      // the settings default (D-026).
      expect(detail.invoice.taxRateBp, 0);
      expect(detail.invoice.totalTax, Money.zero);
      expect(detail.invoice.discountPercentBp, 1000);
      expect(detail.invoice.notes, 'پرداخت نقدی');
    },
  );

  test('issuing saves and then allocates the number', () async {
    fillComplete();
    final Invoice? issued = await editor().issue();

    expect(issued, isNotNull);
    expect(issued!.status, InvoiceStatus.unpaid);
    // The Jalali year of the invoice's **own** issue date, not of today
    // (D-013): 1405/06/02 is in 1405.
    expect(issued.number, 'INV-1405-0001');
    expect(issued.numberYear, 1405);
    expect(issued.numberSequence, 1);

    expect(await harness.invoices.count(), 1);
  });

  test('an abandoned draft does not consume a number', () async {
    // The defect D-048 was written against, at the level the user meets it.
    fillComplete();
    final InvoiceCreationResult? abandoned = await editor().save();
    await harness.invoices.softDelete(abandoned!.invoice.id);

    final InvoiceCreationResult next = await harness.invoices.create(
      harness.draft(customerId),
    );
    final Invoice issued = await harness.invoices.issue(next.invoice.id);

    expect(issued.number, 'INV-1405-0001');
  });

  test(
    'a failed write returns null rather than throwing at the widget',
    () async {
      // §7: a raw exception, stack trace or SQL statement must never reach the
      // user. The repository throws; the controller turns that into a null the
      // screen renders its own Persian copy for.
      final ProviderContainer failing = ProviderContainer(
        overrides: <Override>[
          invoiceRepositoryProvider.overrideWithValue(_ThrowingRepository()),
          settingsRepositoryProvider.overrideWithValue(harness.settings),
        ],
      );
      addTearDown(failing.dispose);
      failing.listen(
        invoiceEditorProvider(openedAt),
        (_, _) {},
        fireImmediately: true,
      );
      await failing.read(invoiceEditorProvider(openedAt).future);

      final InvoiceEditor broken = failing.read(
        invoiceEditorProvider(openedAt).notifier,
      );
      broken.selectCustomer(customerId);
      broken.addLine(
        InvoiceLineEntry(
          title: 'خدمات',
          unit: 'عدد',
          unitPrice: Money.toman(1000),
          quantityMilli: 1000,
        ),
      );

      expect(await broken.save(), isNull);
      expect(await broken.issue(), isNull);
    },
  );

  group('reopening a saved draft (known issue 29)', () {
    /// Saves a complete draft and returns its id.
    Future<String> savedDraft() async {
      fillComplete();
      editor().setNotes('پرداخت تا سررسید.');
      editor().setDiscountAmount(Money.toman(10000));
      final InvoiceCreationResult? created = await editor().save();
      return created!.invoice.id;
    }

    test('loads the stored draft back into the form', () async {
      final String id = await savedDraft();

      // A second editor, as a fresh screen would open one.
      final DateTime reopenedAt = openedAt.add(const Duration(minutes: 5));
      container.listen(
        invoiceEditorProvider(reopenedAt),
        (_, _) {},
        fireImmediately: true,
      );
      await container.read(invoiceEditorProvider(reopenedAt).future);
      await container
          .read(invoiceEditorProvider(reopenedAt).notifier)
          .loadDraft(id);

      final InvoiceEditorState reopened = container
          .read(invoiceEditorProvider(reopenedAt))
          .requireValue;

      expect(reopened.editingInvoiceId, id);
      expect(reopened.customerId, customerId);
      expect(reopened.lines, hasLength(1));
      expect(reopened.lines.single.title, 'خدمات');
      expect(reopened.lines.single.quantityMilli, 1500);
      expect(reopened.discount, Money.toman(10000));
      expect(reopened.notes, 'پرداخت تا سررسید.');
      // A stored due date is a day somebody committed to; reopening must not
      // re-derive it from the payment term (D-052).
      expect(reopened.dueDateFollowsIssueDate, isFalse);
    });

    test(
      'saving an edit updates that invoice rather than adding a second',
      () async {
        final String id = await savedDraft();

        final DateTime reopenedAt = openedAt.add(const Duration(minutes: 5));
        container.listen(
          invoiceEditorProvider(reopenedAt),
          (_, _) {},
          fireImmediately: true,
        );
        await container.read(invoiceEditorProvider(reopenedAt).future);
        final InvoiceEditor reopened = container.read(
          invoiceEditorProvider(reopenedAt).notifier,
        );
        await reopened.loadDraft(id);

        reopened.setNotes('ویرایش شد.');
        final InvoiceCreationResult? saved = await reopened.save();

        // **The property that matters.** Without the update branch this would
        // have written a second invoice beside the original -- a duplicate the
        // user finds later with no way to explain it.
        expect(saved!.invoice.id, id);
        final InvoiceDetail? stored = await harness.invoices.findDetail(id);
        expect(stored!.invoice.notes, 'ویرایش شد.');
        expect(
          stored.invoice.status,
          InvoiceStatus.draft,
          reason:
              'editing a draft leaves it a draft; issuing is a separate act',
        );
      },
    );

    test('a second load does not discard what has been typed', () async {
      final String id = await savedDraft();

      final DateTime reopenedAt = openedAt.add(const Duration(minutes: 5));
      container.listen(
        invoiceEditorProvider(reopenedAt),
        (_, _) {},
        fireImmediately: true,
      );
      await container.read(invoiceEditorProvider(reopenedAt).future);
      final InvoiceEditor reopened = container.read(
        invoiceEditorProvider(reopenedAt).notifier,
      );
      await reopened.loadDraft(id);
      reopened.setNotes('در حال ویرایش');

      // A settings change rebuilds the provider and the screen would load
      // again. Idempotence is what stops that throwing away the edit.
      await reopened.loadDraft(id);

      expect(
        container.read(invoiceEditorProvider(reopenedAt)).requireValue.notes,
        'در حال ویرایش',
      );
    });

    test('an issued invoice is refused, leaving the form empty', () async {
      fillComplete();
      final Invoice? issued = await editor().issue();

      final DateTime reopenedAt = openedAt.add(const Duration(minutes: 5));
      container.listen(
        invoiceEditorProvider(reopenedAt),
        (_, _) {},
        fireImmediately: true,
      );
      await container.read(invoiceEditorProvider(reopenedAt).future);
      final InvoiceEditor reopened = container.read(
        invoiceEditorProvider(reopenedAt).notifier,
      );
      await reopened.loadDraft(issued!.id);

      final InvoiceEditorState state = container
          .read(invoiceEditorProvider(reopenedAt))
          .requireValue;
      expect(
        state.editingInvoiceId,
        isNull,
        reason:
            'an issued invoice is corrected by cancellation, never by editing '
            '(§6) -- and composing a new invoice out of its lines silently '
            'would be worse than doing nothing',
      );
      expect(state.lines, isEmpty);
    });
  });
}

/// A repository whose writes fail, to exercise the controller's error path.
class _ThrowingRepository implements InvoiceRepository {
  @override
  Future<InvoiceCreationResult> create(
    InvoiceDraft draft, {
    InvoiceStatus status = InvoiceStatus.draft,
  }) async => throw StateError('the database is unavailable');

  @override
  Future<Invoice> issue(String id) async =>
      throw StateError('the database is unavailable');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not exercised by this test');
}
