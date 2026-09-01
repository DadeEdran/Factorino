import 'dart:async';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/data/backup/backup_service.dart';
import 'package:factorino/features/settings/presentation/widgets/backup_password_sheet.dart';
import 'package:factorino/features/settings/presentation/widgets/backup_restore_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screen_harness.dart';

/// The two things standing between a user and losing their records: the
/// password they will need again, and the sentence telling them a restore
/// replaces rather than merges.
void main() {
  /// Opens a sheet or dialog from a host screen and returns the strings.
  Future<(AppStrings, Future<Object?>)> open(
    WidgetTester tester,
    Future<Object?> Function(BuildContext context) show,
  ) async {
    late BuildContext hostContext;

    await pumpScreen(
      tester,
      Builder(
        builder: (BuildContext context) {
          hostContext = context;
          return const Scaffold(body: SizedBox.expand());
        },
      ),
    );

    final AppStrings strings = AppStrings.of(hostContext);
    final Future<Object?> result = show(hostContext);
    await tester.pumpAndSettle();
    return (strings, result);
  }

  Future<void> enter(WidgetTester tester, String label, String value) async {
    await tester.enterText(find.widgetWithText(TextFormField, label), value);
    await tester.pump();
  }

  group('the password sheet, when taking a backup', () {
    testWidgets('states that losing the password loses the backup', (
      WidgetTester tester,
    ) async {
      // Required by §8, in Persian, and deliberately not softened: there is no
      // recovery path and nobody who can help.
      final (AppStrings strings, Future<Object?> _) = await open(
        tester,
        (BuildContext context) =>
            showBackupPasswordSheet(context, confirming: true),
      );

      expect(find.text(strings.backupPasswordWarning), findsOneWidget);
    });

    testWidgets('asks for it twice', (WidgetTester tester) async {
      // A mistyped password produces a file that can never be opened, and
      // nothing would reveal that until the day it mattered.
      final (AppStrings strings, Future<Object?> _) = await open(
        tester,
        (BuildContext context) =>
            showBackupPasswordSheet(context, confirming: true),
      );

      expect(
        find.widgetWithText(TextFormField, strings.backupPasswordField),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, strings.backupPasswordRepeatField),
        findsOneWidget,
      );
    });

    testWidgets('refuses two that do not match', (WidgetTester tester) async {
      final (AppStrings strings, Future<Object?> result) = await open(
        tester,
        (BuildContext context) =>
            showBackupPasswordSheet(context, confirming: true),
      );

      await enter(tester, strings.backupPasswordField, 'correct-horse');
      await enter(tester, strings.backupPasswordRepeatField, 'correct-house');
      await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
      await tester.pumpAndSettle();

      expect(find.text(strings.backupPasswordMismatch), findsOneWidget);
      expect(
        find.text(strings.backupPasswordWarning),
        findsOneWidget,
        reason: 'the sheet must still be open, not dismissed with a null',
      );
      unawaited(result);
    });

    testWidgets('refuses one too short to be worth the warning', (
      WidgetTester tester,
    ) async {
      final (AppStrings strings, Future<Object?> result) = await open(
        tester,
        (BuildContext context) =>
            showBackupPasswordSheet(context, confirming: true),
      );

      await enter(tester, strings.backupPasswordField, '1234');
      await enter(tester, strings.backupPasswordRepeatField, '1234');
      await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
      await tester.pumpAndSettle();

      expect(find.text(strings.backupPasswordTooShort), findsOneWidget);
      unawaited(result);
    });

    testWidgets('returns the password exactly as typed, spaces included', (
      WidgetTester tester,
    ) async {
      // **Trimming is the reflex this must not have.** A trailing space is part
      // of the password: trimmed here, the container is keyed with a different
      // string than the user believes they chose, and the file refuses them
      // later. Pinned at the container level too, in
      // `backup_passphrase_characters_test.dart`.
      const String typed = ' my backup pass ';
      final (AppStrings strings, Future<Object?> result) = await open(
        tester,
        (BuildContext context) =>
            showBackupPasswordSheet(context, confirming: true),
      );

      await enter(tester, strings.backupPasswordField, typed);
      await enter(tester, strings.backupPasswordRepeatField, typed);
      await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
      await tester.pumpAndSettle();

      expect(await result, typed);
    });
  });

  group('the password sheet, when restoring', () {
    testWidgets('asks once, and does not repeat the warning', (
      WidgetTester tester,
    ) async {
      // Restoring cannot lose anything by a typo: the password either opens
      // the file or it does not, and the answer arrives in a second. Repeating
      // the warning here would be noise attached to the wrong risk.
      final (AppStrings strings, Future<Object?> _) = await open(
        tester,
        (BuildContext context) =>
            showBackupPasswordSheet(context, confirming: false),
      );

      expect(
        find.widgetWithText(TextFormField, strings.backupPasswordField),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, strings.backupPasswordRepeatField),
        findsNothing,
      );
      expect(find.text(strings.backupPasswordWarning), findsNothing);
    });

    testWidgets('refuses an empty one before it reaches the file', (
      WidgetTester tester,
    ) async {
      // An empty key produces an unencrypted database under SQLCipher
      // semantics, so it is refused at three levels: here, in the service, and
      // in the opener.
      final (AppStrings strings, Future<Object?> result) = await open(
        tester,
        (BuildContext context) =>
            showBackupPasswordSheet(context, confirming: false),
      );

      await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
      await tester.pumpAndSettle();

      expect(find.text(strings.backupPasswordEmpty), findsOneWidget);
      unawaited(result);
    });
  });

  group('the restore confirmation', () {
    final BackupSummary summary = BackupSummary(
      formatVersion: 1,
      appSchemaVersion: 4,
      createdAt: DateTime.utc(2026, 9, 1, 12),
      rowCounts: const <String, int>{
        'customers': 12,
        'invoices': 34,
        'payments': 56,
        'products': 7,
        'invoice_items': 89,
        'settings': 1,
      },
      sizeBytes: 40960,
    );

    testWidgets('says data is replaced and not merged', (
      WidgetTester tester,
    ) async {
      // **The sentence that prevents the loss** (D-069). "Restore" implies
      // addition to most people, so a user expecting a merge loses everything
      // entered since the backup and has no reason to expect it.
      final (AppStrings strings, Future<Object?> _) = await open(
        tester,
        (BuildContext context) =>
            showBackupRestoreConfirmDialog(context, summary: summary),
      );

      expect(find.text(strings.backupImportConfirmReplaces), findsOneWidget);
      expect(find.text(strings.backupImportConfirmLoses), findsOneWidget);
    });

    testWidgets('describes the file, in Persian digits', (
      WidgetTester tester,
    ) async {
      // The counts come from a container already opened, its password
      // accepted, its version checked and its counts verified -- so these are
      // the file's numbers rather than a hope about it, and a user who does not
      // recognise them can still back out.
      await open(
        tester,
        (BuildContext context) =>
            showBackupRestoreConfirmDialog(context, summary: summary),
      );

      expect(find.textContaining('۱۲'), findsWidgets);
      expect(find.textContaining('۳۴'), findsWidgets);
      expect(find.textContaining('۵۶'), findsWidgets);
      expect(
        find.textContaining('1405'),
        findsNothing,
        reason:
            'a Latin numeral in Persian RTL copy is English by another name',
      );
    });

    testWidgets('cancelling returns false', (WidgetTester tester) async {
      final (AppStrings strings, Future<Object?> result) = await open(
        tester,
        (BuildContext context) =>
            showBackupRestoreConfirmDialog(context, summary: summary),
      );

      await tester.tap(find.widgetWithText(TextButton, strings.actionCancel));
      await tester.pumpAndSettle();

      expect(await result, isFalse);
    });

    testWidgets('confirming returns true', (WidgetTester tester) async {
      final (AppStrings strings, Future<Object?> result) = await open(
        tester,
        (BuildContext context) =>
            showBackupRestoreConfirmDialog(context, summary: summary),
      );

      await tester.tap(
        find.widgetWithText(FilledButton, strings.backupImportConfirmAction),
      );
      await tester.pumpAndSettle();

      expect(await result, isTrue);
    });
  });
}
