import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/localization/generated/app_strings_fa.dart';
import 'package:factorino/core/money/invoice_calculator.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/features/invoices/domain/invoice_editor_state.dart';
import 'package:factorino/features/invoices/domain/invoice_warning_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// D-027's warnings, turned into something a user reads.
///
/// The decision was that the engine reports a clamped discount as **data** —
/// kind, line, requested and applied — and carries no message, because Persian
/// belongs to the localization layer. This is the first consumer of that, and
/// the property worth testing is the one the decision insisted on: **both
/// figures appear**. A message that only said something was ignored would leave
/// the user to find out which line and by how much using the arithmetic they
/// opened this screen to avoid.
void main() {
  final AppStrings strings = AppStringsFa();

  const AppSettings settings = AppSettings(
    defaultTaxRateBp: 0,
    roundingUnitRial: 0,
    invoiceNumberPrefix: 'INV',
  );

  InvoiceEditorState stateWith({
    required List<InvoiceLineEntry> lines,
    int discountRial = 0,
  }) {
    return InvoiceEditorState(
      settings: settings,
      issueDate: DateTime.utc(2026, 8, 24, 12),
      customerId: 'c1',
      lines: lines,
      discount: Money.rial(discountRial),
    );
  }

  InvoiceLineEntry line({int priceRial = 1000000, int discountRial = 0}) {
    return InvoiceLineEntry(
      title: 'خدمات',
      unit: 'عدد',
      unitPrice: Money.rial(priceRial),
      quantityMilli: 1000,
      discount: Money.rial(discountRial),
    );
  }

  test('a clamped line names the line and both figures', () {
    // 1,500,000 Rial entered against a line worth 1,000,000 Rial. In Toman
    // those are 150,000 and 100,000 -- the display unit every other figure on
    // the screen uses, because a warning quoting Rial beside a summary quoting
    // Toman would read as a tenfold error in the app's favour.
    final InvoiceEditorState state = stateWith(
      lines: <InvoiceLineEntry>[line(discountRial: 1500000)],
    );

    final String message = invoiceWarningMessages(
      state.warnings,
      strings,
    ).single;

    expect(message, contains('۱۵۰٬۰۰۰'), reason: 'the requested amount');
    expect(message, contains('۱۰۰٬۰۰۰'), reason: 'the amount actually given');
    expect(message, contains('۱'), reason: 'the line number, 1-based');
  });

  test('the line number is one-based, not the array index', () {
    // `warning.lineIndex` counts from zero and no invoice has a line zero.
    final InvoiceEditorState state = stateWith(
      lines: <InvoiceLineEntry>[
        line(),
        line(),
        line(priceRial: 1000000, discountRial: 9000000),
      ],
    );

    expect(state.warnings.single.lineIndex, 2);
    final String message = invoiceWarningMessages(
      state.warnings,
      strings,
    ).single;
    expect(message, contains('۳'));
  });

  test('an invoice-level clamp names both figures and no line', () {
    final InvoiceEditorState state = stateWith(
      lines: <InvoiceLineEntry>[line(priceRial: 1000000)],
      discountRial: 5000000,
    );

    final String message = invoiceWarningMessages(
      state.warnings,
      strings,
    ).single;

    expect(message, contains('۵۰۰٬۰۰۰'), reason: 'requested, in Toman');
    expect(message, contains('۱۰۰٬۰۰۰'), reason: 'applied, in Toman');
  });

  test('every message is Persian copy from the ARB, never a raw figure', () {
    // §1 and §7: no English, and nothing that leaks an internal name. A
    // message that fell back to `warning.toString()` would render
    // "InvoiceWarning(lineDiscountClamped, ...)" on screen and still look like
    // a message.
    final InvoiceEditorState state = stateWith(
      lines: <InvoiceLineEntry>[line(discountRial: 9000000)],
      discountRial: 9000000,
    );

    for (final String message in invoiceWarningMessages(
      state.warnings,
      strings,
    )) {
      expect(message, isNot(contains('InvoiceWarning')));
      expect(message, isNot(contains('Clamped')));
      expect(message, isNot(contains('Rial')));
      expect(RegExp(r'[A-Za-z]').hasMatch(message), isFalse);
    }
  });

  test('every warning kind has a message', () {
    // A `switch` over the enum, so adding a kind without copy for it fails to
    // compile rather than rendering nothing at the moment it first fires.
    for (final InvoiceWarningKind kind in InvoiceWarningKind.values) {
      final String message = invoiceWarningMessage(
        InvoiceWarning(
          kind: kind,
          lineIndex: kind == InvoiceWarningKind.lineDiscountClamped ? 0 : null,
          requested: Money.rial(2000000),
          applied: Money.rial(1000000),
        ),
        strings,
        lineNumberOf: (int index) => index + 1,
      );
      expect(message, isNotEmpty);
      expect(message, contains('۲۰۰٬۰۰۰'));
      expect(message, contains('۱۰۰٬۰۰۰'));
    }
  });

  test('messages come back in the engine\'s order', () {
    final InvoiceEditorState state = stateWith(
      lines: <InvoiceLineEntry>[
        line(priceRial: 1000000, discountRial: 9000000),
        line(priceRial: 2000000, discountRial: 9000000),
      ],
      discountRial: 9000000,
    );

    final List<String> messages = invoiceWarningMessages(
      state.warnings,
      strings,
    );
    expect(messages, hasLength(3));
    // Line 1 gave 100,000 Toman, line 2 gave 200,000, and the invoice-level
    // clamp is last -- document order, so the list reads down the invoice.
    expect(messages[0], contains('۱۰۰٬۰۰۰'));
    expect(messages[1], contains('۲۰۰٬۰۰۰'));
    expect(messages[2], isNot(contains('سطر')));
  });
}
