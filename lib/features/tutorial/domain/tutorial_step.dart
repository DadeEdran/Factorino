import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_strings.dart';
import '../../../core/router/destinations.dart';

/// The eight things a new user needs, in the order they need them (D-122).
///
/// The order is the order of a first real job rather than the order of the
/// navigation bar: name the business, then the two records an invoice is built
/// out of, then the invoice, then what happens to it afterwards, and a backup
/// last because it is the only step that is about the application rather than
/// about the work.
///
/// **Each step is one sentence.** This is orientation, not documentation — a
/// screen a user reads once and acts on, not a manual they are asked to
/// absorb. Anything that needs a paragraph does not belong here; it belongs in
/// the screen it describes, where it is read at the moment it applies (which is
/// what the seller prompt and the export message already do).
enum TutorialStep {
  /// The business name. First for the reason D-102 gives: every database starts
  /// with an empty seller, and it is what the printed document is missing.
  seller(Icons.storefront_outlined),

  customer(Icons.person_add_alt_1_outlined),

  product(Icons.inventory_2_outlined),

  invoice(Icons.note_add_outlined),

  /// Issuing, which is the one irreversible thing in the sequence (§6).
  issue(Icons.task_alt_outlined),

  payment(Icons.payments_outlined),

  document(Icons.picture_as_pdf_outlined),

  /// Backup last, and it is the only step that is about the application rather
  /// than about invoicing. It closes on the consequence §8 is written around.
  backup(Icons.backup_outlined);

  const TutorialStep(this.icon);

  /// The illustration. None of these mirror in RTL and none should — they are
  /// object icons, not directional ones (§9), the same rule
  /// [AppDestination.icon] follows.
  final IconData icon;

  bool get isFirst => index == 0;
  bool get isLast => index == values.length - 1;

  String title(AppStrings strings) => switch (this) {
    TutorialStep.seller => strings.tutorialSellerTitle,
    TutorialStep.customer => strings.tutorialCustomerTitle,
    TutorialStep.product => strings.tutorialProductTitle,
    TutorialStep.invoice => strings.tutorialInvoiceTitle,
    TutorialStep.issue => strings.tutorialIssueTitle,
    TutorialStep.payment => strings.tutorialPaymentTitle,
    TutorialStep.document => strings.tutorialDocumentTitle,
    TutorialStep.backup => strings.tutorialBackupTitle,
  };

  /// The sentence, with the section names filled in from the navigation labels.
  ///
  /// **This is the whole anti-rot mechanism, and it is worth being explicit
  /// about what it does and does not buy.** A tutorial that named «تنظیمات» as
  /// a literal in the ARB would keep saying «تنظیمات» after somebody shortened
  /// the tab the way «محصولات و خدمات» was shortened to «محصولات» (D-114) — and
  /// nothing would fail, because a sentence naming a tab that no longer exists
  /// still lays out perfectly. Reading the label from [AppDestination] means
  /// there is exactly one string, drawn by the navigation bar and quoted here,
  /// and renaming a destination renames it in both places at once.
  ///
  /// What it does not buy: if a destination is *removed*, this switch stops
  /// compiling only because [AppDestination] is an enum the label getter
  /// switches over exhaustively. That is the intended failure — loud, at build
  /// time, in the file that would otherwise start lying.
  String body(AppStrings strings) => switch (this) {
    TutorialStep.seller => strings.tutorialSellerBody(
      AppDestination.settings.label(strings),
    ),
    TutorialStep.customer => strings.tutorialCustomerBody(
      AppDestination.customers.label(strings),
    ),
    TutorialStep.product => strings.tutorialProductBody(
      AppDestination.products.label(strings),
    ),
    TutorialStep.invoice => strings.tutorialInvoiceBody(
      AppDestination.invoices.label(strings),
    ),
    TutorialStep.issue => strings.tutorialIssueBody,
    TutorialStep.payment => strings.tutorialPaymentBody,
    TutorialStep.document => strings.tutorialDocumentBody,
    TutorialStep.backup => strings.tutorialBackupBody(
      AppDestination.settings.label(strings),
    ),
  };
}
