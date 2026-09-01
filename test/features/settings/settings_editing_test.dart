import 'dart:async';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/settings_repository.dart';
import 'package:factorino/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screen_harness.dart';

/// Editing the settings — the part of Phase 6 (d) that is a **defect fix**.
///
/// the project spec requires the VAT rate to be configurable and never hardcoded.
/// It was hardcoded at whatever the database was seeded with, and the work
/// belonged to no phase in the plan, so the scope cut would have made that
/// permanent (D-068).
///
/// The bounds are the substance here. `AppSettings` deliberately does not clamp
/// (D-052) — a value that cannot be right is a data-entry error to report, not
/// a number to quietly adjust — so the form is the only thing standing between
/// a mistyped digit and an invoice due before it was issued.
void main() {
  const AppSettings settings = AppSettings(
    defaultTaxRateBp: 900,
    roundingUnitRial: 0,
    invoiceNumberPrefix: 'INV',
    paymentTermDays: 45,
  );

  late _FakeSettingsRepository repository;

  Future<AppStrings> pumpSettings(
    WidgetTester tester, {
    AppSettings initial = settings,
  }) async {
    repository = _FakeSettingsRepository(initial);
    await pumpScreen(
      tester,
      const SettingsScreen(),
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.pumpAndSettle();
    return stringsOf(tester, SettingsScreen);
  }

  Future<AppStrings> openEditor(WidgetTester tester) async {
    final AppStrings strings = await pumpSettings(tester);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    return strings;
  }

  Future<void> enter(WidgetTester tester, String label, String value) async {
    await tester.enterText(find.widgetWithText(TextFormField, label), value);
    await tester.pump();
  }

  Future<void> save(WidgetTester tester, AppStrings strings) async {
    await tester.tap(find.widgetWithText(FilledButton, strings.actionSave));
    await tester.pumpAndSettle();
  }

  group('the editor opens with what is in force', () {
    testWidgets('the rate is shown as a percentage, not basis points', (
      WidgetTester tester,
    ) async {
      // 900bp is 9%. Showing «۹۰۰» would be the model's unit leaking into the
      // user's, and the user would then type 9 and set the rate to 0.09%.
      final AppStrings strings = await openEditor(tester);

      expect(
        find.widgetWithText(TextFormField, strings.settingsFieldTaxRate),
        findsOneWidget,
      );
      expect(find.text('۹'), findsWidgets);
    });

    testWidgets('the field says a change cannot alter past invoices', (
      WidgetTester tester,
    ) async {
      // The property that makes the screen safe to open (§4, D-026). A user who
      // does not know it will not change a rate they should change.
      final AppStrings strings = await openEditor(tester);
      expect(find.text(strings.settingsFieldTaxRateHint), findsOneWidget);
    });
  });

  group('the bounds are enforced and reported, never clamped', () {
    testWidgets('a payment term beyond two years is refused', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await openEditor(tester);
      await enter(tester, strings.settingsFieldPaymentTerm, '۹۹۹۹');
      await save(tester, strings);

      expect(find.text(strings.settingsErrorPaymentTermRange), findsOneWidget);
      expect(
        repository.written,
        isEmpty,
        reason: 'a refused form must not write',
      );
    });

    testWidgets('a tax rate above 100% is refused', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await openEditor(tester);
      await enter(tester, strings.settingsFieldTaxRate, '۱۵۰');
      await save(tester, strings);

      expect(find.text(strings.settingsErrorTaxRateRange), findsOneWidget);
      expect(repository.written, isEmpty);
    });

    testWidgets('an empty prefix is refused', (WidgetTester tester) async {
      final AppStrings strings = await openEditor(tester);
      await enter(tester, strings.settingsFieldPrefix, '');
      await save(tester, strings);

      expect(find.text(strings.settingsErrorPrefixEmpty), findsOneWidget);
      expect(repository.written, isEmpty);
    });

    testWidgets('zero days is allowed — paid on delivery is a real term', (
      WidgetTester tester,
    ) async {
      // The bound is not "positive". Refusing 0 would refuse a business that
      // is paid when it delivers, which is most workshops.
      final AppStrings strings = await openEditor(tester);
      await enter(tester, strings.settingsFieldPaymentTerm, '۰');
      await save(tester, strings);

      expect(repository.written, hasLength(1));
      expect(repository.written.single.paymentTermDays, 0);
    });
  });

  group('a valid edit is written', () {
    testWidgets('in the model unit, converted from what was typed', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await openEditor(tester);
      await enter(tester, strings.settingsFieldTaxRate, '۸٫۵');
      await enter(tester, strings.settingsFieldPrefix, 'FCT');
      await enter(tester, strings.settingsFieldPaymentTerm, '۶۰');
      await save(tester, strings);

      expect(repository.written, hasLength(1));
      final AppSettings written = repository.written.single;
      expect(
        written.defaultTaxRateBp,
        850,
        reason: '8.5% is 850 basis points, and no floating point on the way',
      );
      expect(written.invoiceNumberPrefix, 'FCT');
      expect(written.paymentTermDays, 60);
    });

    testWidgets('Latin digits are accepted too, and normalized', (
      WidgetTester tester,
    ) async {
      // §9: users type the three digit sets interchangeably. A settings form
      // that only accepted one of them would be the exception.
      final AppStrings strings = await openEditor(tester);
      await enter(tester, strings.settingsFieldPaymentTerm, '60');
      await save(tester, strings);

      expect(repository.written.single.paymentTermDays, 60);
    });

    testWidgets('dismissing the sheet writes nothing', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await openEditor(tester);
      await enter(tester, strings.settingsFieldPaymentTerm, '۶۰');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(repository.written, isEmpty);
    });
  });

  group('the last-backup row', () {
    testWidgets('says so plainly when no backup has ever been taken', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await pumpSettings(tester);
      expect(find.text(strings.settingsLastBackupNever), findsOneWidget);
    });

    testWidgets('renders a Jalali date, not an epoch number', (
      WidgetTester tester,
    ) async {
      // **Known issue 6's first half.** This row would have rendered
      // «۱٬۷۵۶٬۰۰۰٬۰۰۰٬۰۰۰» the moment `lastBackupAt` stopped being null, and
      // until this increment nothing could make it non-null, so nothing showed.
      await pumpSettings(
        tester,
        initial: settings.copyWith(lastBackupAt: DateTime.utc(2026, 9, 1, 12)),
      );

      expect(find.textContaining('۱۴۰۵'), findsWidgets);
      expect(
        find.textContaining('۱٬۷۵'),
        findsNothing,
        reason: 'an epoch millisecond count is on screen',
      );
    });
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._current);

  AppSettings _current;
  final StreamController<AppSettings> _controller =
      StreamController<AppSettings>.broadcast();

  /// Every value the screen actually wrote. A refusal that still wrote would
  /// pass a test that only checked the error text.
  final List<AppSettings> written = <AppSettings>[];

  @override
  Future<AppSettings> read() async => _current;

  @override
  Stream<AppSettings> watch() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<AppSettings> write(AppSettings settings) async {
    written.add(settings);
    _current = settings;
    _controller.add(settings);
    return settings;
  }

  @override
  Future<void> markBackedUp(DateTime at) async {}
}
