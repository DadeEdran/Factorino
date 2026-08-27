import 'dart:async';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/settings_repository.dart';
import 'package:factorino/features/settings/presentation/settings_screen.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screen_harness.dart';

/// The settings screen, which is read-only and shows the configuration the
/// invoice engine actually uses.
///
/// It had no test until the payment term landed on it (D-052). This covers the
/// new row and the one property that is easy to get wrong on a screen full of
/// numbers: **every figure is in Persian digits**, because a Latin numeral in
/// an RTL Persian page is a user-facing English string by another name (§9).
void main() {
  const AppSettings settings = AppSettings(
    defaultTaxRateBp: 900,
    roundingUnitRial: 0,
    invoiceNumberPrefix: 'INV',
    paymentTermDays: 45,
  );

  Future<AppStrings> pumpSettings(WidgetTester tester) async {
    await pumpScreen(
      tester,
      const SettingsScreen(),
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(
          _FakeSettingsRepository(settings),
        ),
      ],
    );
    await tester.pumpAndSettle();
    return stringsOf(tester, SettingsScreen);
  }

  testWidgets('the payment term is shown, in days', (
    WidgetTester tester,
  ) async {
    final AppStrings strings = await pumpSettings(tester);

    expect(find.text(strings.settingsPaymentTerm), findsOneWidget);
    // Persian digits, not `45` -- the same treatment every other figure on
    // this screen gets.
    expect(find.text('۴۵'), findsOneWidget);
    expect(find.text(strings.unitDays), findsOneWidget);
  });

  testWidgets('it reads the stored value, not the seed default', (
    WidgetTester tester,
  ) async {
    // The row would look entirely correct showing `kDefaultPaymentTermDays`
    // for every user, and would be wrong for exactly the businesses the
    // setting exists for. The fixture is 45 for that reason.
    await pumpSettings(tester);

    expect(find.text('۴۵'), findsOneWidget);
    expect(
      find.text('۳۰'),
      findsNothing,
      reason:
          'the screen must render AppSettings.paymentTermDays, never the seed '
          'default the column happens to carry',
    );
  });

  testWidgets('a row whose value is a sentence still fits the phone', (
    WidgetTester tester,
  ) async {
    // The backup row renders «هنوز پشتیبان تهیه نشده است» in the prominent
    // figure style, because no backup has ever been taken. As a `Row` that
    // group took its natural width first and squeezed the label to nothing:
    // 132 logical pixels of overflow at phone width, a row of content the user
    // cannot see. The defect predates the payment-term row and is what made
    // this the screen's first test.
    //
    // No `expect` for the overflow itself: a `RenderFlex` overflow fails the
    // test on its own, which is exactly the assertion wanted here.
    final AppStrings strings = await pumpSettings(tester);

    expect(find.text(strings.settingsLastBackupNever), findsOneWidget);
    expect(find.text(strings.settingsLastBackup), findsOneWidget);
  });

  testWidgets('the term sits beside the other invoicing settings', (
    WidgetTester tester,
  ) async {
    // A payment term belongs with the VAT rate and the numbering prefix -- it
    // is the same kind of thing, and the backup section below is not.
    final AppStrings strings = await pumpSettings(tester);

    expect(find.text(strings.settingsInvoicingSection), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(strings.settingsPaymentTerm)).dy,
      lessThan(tester.getTopLeft(find.text(strings.settingsBackupSection)).dy),
    );
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._current);

  AppSettings _current;

  @override
  Future<AppSettings> read() async => _current;

  @override
  Stream<AppSettings> watch() => Stream<AppSettings>.value(_current);

  @override
  Future<AppSettings> write(AppSettings settings) async {
    _current = settings;
    return settings;
  }

  @override
  Future<void> markBackedUp(DateTime at) async {}
}
