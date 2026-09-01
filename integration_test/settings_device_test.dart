import 'dart:io';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/theme/app_theme.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/features/settings/presentation/settings_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'device_assertions.dart';

/// The settings screen on the real target — Phase 6 (d).
///
/// **Reduced on purpose, and by exactly how much is written down** (D-068):
/// phone tier, one large realistic amount, rather than the D-057 three-tier
/// four-rung sweep. Two things are *not* reduced, and they are why this file
/// exists rather than being skipped along with the sweep:
///
/// 1. **The keyboard rule** (D-062). A backup password field in a sheet is
///    precisely what that rule was written for, and this sheet is the hardest
///    case any sheet in the application has posed: above its fields sits the §8
///    warning, several lines of Persian, which is the tallest thing anything has
///    ever put above a pinned action.
/// 2. **The write reaching the real database.** The widget tests write to a
///    fake repository. This writes through the real repository into the real
///    encrypted file and reads the value back out of it.
///
/// Uses a probe database, so running it never touches the real one.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// The top rung of the ladder, in Rial. Settings' one money figure is the
  /// rounding unit; a large one is what would push the row's value off the
  /// edge if the `Wrap` that replaced the `Row` ever became a `Row` again.
  const int largeRoundingRial = 1000000000;

  final List<String> layoutErrors = <String>[];

  testWidgets('settings edit and the backup sheets, on the target', (
    WidgetTester tester,
  ) async {
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final String message = details.exceptionAsString();
      if (message.contains('overflowed')) layoutErrors.add(message);
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    // ---- a probe database, through the production bootstrap ---------------
    final File file = await defaultDatabaseFile(name: 'settings_probe.db');
    for (final String suffix in <String>['', '-wal', '-shm']) {
      final File stale = File('${file.path}$suffix');
      if (stale.existsSync()) stale.deleteSync();
    }
    final AppDatabase db = await openAppDatabase(file: file);
    addTearDown(() async {
      await db.close();
      for (final String suffix in <String>['', '-wal', '-shm']) {
        final File probe = File('${file.path}$suffix');
        if (probe.existsSync()) probe.deleteSync();
      }
    });

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    // A large rounding unit and a real last-backup date, so both of the rows
    // that could overflow are carrying their worst case.
    final AppSettings seeded = await container
        .read(settingsRepositoryProvider)
        .read();
    await container
        .read(settingsRepositoryProvider)
        .write(seeded.copyWith(roundingUnitRial: largeRoundingRial));
    await container
        .read(settingsRepositoryProvider)
        .markBackedUp(DateTime.now().toUtc());

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('fa'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: SettingsScreen()),
          builder: (BuildContext context, Widget? child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final BuildContext screen = tester.element(find.byType(SettingsScreen));
    final AppStrings strings = AppStrings.of(screen);
    final Size size = MediaQuery.sizeOf(screen);

    debugPrint('=== PHASE 6 (d) SETTINGS ON DEVICE ===');
    debugPrint('platform      : ${Platform.operatingSystem}');
    debugPrint(
      'logical size  : ${size.width.toStringAsFixed(1)} x '
      '${size.height.toStringAsFixed(1)}',
    );

    // ---- the read side, at the large amount -------------------------------
    expectNoCrushedText(tester, where: 'settings, at the ladder top rung');
    expect(
      find.text(strings.settingsLastBackupNever),
      findsNothing,
      reason: 'a backup was just recorded, so the row must show its date',
    );
    debugPrint('last backup   : rendered as a date, not «هرگز»');

    // ---- the backup password sheet, with the REAL keyboard up -------------
    //
    // The one D-062 was written for. Its password field carries `autofocus`,
    // so this is the state a user meets it in.
    await tester.tap(find.text(strings.backupExportAction));
    await tester.pumpAndSettle();

    final Finder passwordField = find.widgetWithText(
      TextFormField,
      strings.backupPasswordField,
    );
    expect(passwordField, findsOneWidget);
    expect(
      find.text(strings.backupPasswordWarning),
      findsOneWidget,
      reason: '§8 requires the warning, and it must survive the real layout',
    );

    final double inset = await raiseKeyboard(tester, passwordField);
    debugPrint('password kbd  : ${inset.toStringAsFixed(1)}');

    expectActionAboveKeyboard(
      tester,
      find.widgetWithText(FilledButton, strings.actionSave),
      sheet: 'backup password sheet',
    );
    expectNoCrushedText(tester, where: 'the backup password sheet');

    // Out again, without taking a backup: the save dialog is system UI and is
    // proved separately in `backup_gateway_save_test.dart`, which needs a tap
    // this run cannot supply.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // ---- the settings editor, with the real keyboard up -------------------
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    final Finder termField = find.widgetWithText(
      TextFormField,
      strings.settingsFieldPaymentTerm,
    );
    final double editorInset = await raiseKeyboard(tester, termField);
    debugPrint('editor kbd    : ${editorInset.toStringAsFixed(1)}');

    expectActionAboveKeyboard(
      tester,
      find.widgetWithText(FilledButton, strings.actionSave),
      sheet: 'settings editor sheet',
    );

    // ---- and the write reaches the real encrypted database ----------------
    await tester.enterText(termField, '۶۰');
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, strings.settingsFieldTaxRate),
      '۸٫۵',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
    await tester.pumpAndSettle();

    final AppSettings written = await container
        .read(settingsRepositoryProvider)
        .read();
    expect(written.paymentTermDays, 60);
    expect(
      written.defaultTaxRateBp,
      850,
      reason: '8.5% must reach the database as 850 basis points',
    );
    debugPrint(
      'written       : term ${written.paymentTermDays}, '
      'rate ${written.defaultTaxRateBp}bp',
    );

    expectNoCrushedText(tester, where: 'settings after the edit');
    debugPrint('layout errors : ${layoutErrors.length}');
    expect(layoutErrors, isEmpty, reason: layoutErrors.join('\n'));
  });
}
