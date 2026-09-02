import 'dart:io';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/theme/app_theme.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/models/seller_identity.dart';
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

  /// A seller at the length real Iranian business data reaches (§10, §14) —
  /// not «تست». The address is the field that grows, and it is the one that
  /// was clipping mid-word on the printed page until (c) caught it, so the
  /// value used here is a full two-line نشانی rather than a token.
  const String sellerName = 'صنایع چوب و دکوراسیون آرمان‌فر';
  const String sellerEconomicId = '۴۱۱۳۸۷۶۵۴۳۲۱';
  const String sellerPhone = '۰۲۱-۸۸۷۴۵۶۹۰';
  const String sellerAddress =
      'تهران، خیابان شهید بهشتی، نبش کوچهٔ اندیشهٔ سوم، '
      'ساختمان نگین، طبقهٔ چهارم، واحد ۱۲';

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

    // ---- the seller sheet, with the REAL keyboard up ----------------------
    //
    // **New here, because (c) shipped a sheet this suite never ran.** Schema
    // v5 put a fourth sheet on this screen — four text fields and a pinned
    // action — and the device pass was not re-run over it, so until now it had
    // never met a real keyboard on a real phone. D-062 applies to it exactly
    // as it applies to the three that were already here, and its address field
    // is `maxLines: 3`, which is the tallest field any sheet in the
    // application puts above its action.
    expect(
      find.text(strings.settingsSellerConsequence),
      findsOneWidget,
      reason:
          'an empty seller must carry the D-077 prompt where it can be '
          'acted on, before anything is printed',
    );

    await tester.tap(find.byTooltip(strings.settingsSellerEditTooltip));
    await tester.pumpAndSettle();

    final Finder sellerNameField = find.widgetWithText(
      TextFormField,
      strings.settingsSellerFieldName,
    );
    final double sellerInset = await raiseKeyboard(tester, sellerNameField);
    debugPrint('seller kbd    : ${sellerInset.toStringAsFixed(1)}');

    expectActionAboveKeyboard(
      tester,
      find.widgetWithText(FilledButton, strings.actionSave),
      sheet: 'seller editor sheet',
    );
    expectNoCrushedText(tester, where: 'the seller editor sheet');

    await tester.enterText(sellerNameField, sellerName);
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, strings.settingsSellerFieldEconomicId),
      sellerEconomicId,
    );
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, strings.settingsSellerFieldPhone),
      sellerPhone,
    );
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, strings.settingsSellerFieldAddress),
      sellerAddress,
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
    await tester.pumpAndSettle();

    // ---- and it reached the real encrypted database -----------------------
    final SellerIdentity storedSeller =
        (await container.read(settingsRepositoryProvider).read()).seller;
    expect(storedSeller.name, sellerName);
    expect(storedSeller.economicId, sellerEconomicId);
    expect(storedSeller.phone, sellerPhone);
    expect(storedSeller.address, sellerAddress);
    expect(
      storedSeller.isPrintable,
      isTrue,
      reason: 'the document can only head a فروشنده block from a name',
    );
    debugPrint('seller write  : reached the database, isPrintable=true');

    // D-077: filling the name is what takes the prompt away. A notice that
    // stayed put after the user did the thing it asked for would be a standing
    // warning rather than a prompt, and would train them to ignore it.
    expect(
      find.text(strings.settingsSellerConsequence),
      findsNothing,
      reason: 'the prompt must go away once the name it asks for is there',
    );

    // ---- the backup password sheet, with the REAL keyboard up -------------
    //
    // The one D-062 was written for. Its password field carries `autofocus`,
    // so this is the state a user meets it in.
    //
    // **`reach` rather than a bare tap, and that is a (c) regression.** The
    // seller section went in above this one, and on a 803.6-pixel phone it
    // pushed «تهیهٔ پشتیبان» off the bottom — so the finder reported absence,
    // not invisibility, and the suite failed at the tap. The control is
    // perfectly reachable by scrolling; what was wrong was a suite that
    // assumed the screen it was written against.
    // `reach` and then `ensureVisible`, because they answer different
    // questions and this suite needed both: `reach` drags until the widget is
    // laid out at all — a `ListView` child past the cache extent is not in the
    // tree, so a finder reports absence — and `ensureVisible` then puts it
    // inside the viewport. Stopping after `reach` left the button in the tree
    // and still below the bottom edge, and the tap silently missed it.
    await reach(tester, find.text(strings.backupExportAction));
    await tester.ensureVisible(find.text(strings.backupExportAction));
    await tester.pumpAndSettle();
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
    //
    // **By tooltip, and that is the other half of the same (c) regression.**
    // There are two `Icons.edit_outlined` on this screen now — the seller
    // section's and this one — so `find.byIcon` matches both and cannot say
    // which sheet it opened. The tooltips are already distinct because they
    // have to be for a screen reader; using them here means the finder names
    // the section rather than the glyph.
    await reach(tester, find.byTooltip(strings.settingsEditTooltip));
    await tester.ensureVisible(find.byTooltip(strings.settingsEditTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(strings.settingsEditTooltip));
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
