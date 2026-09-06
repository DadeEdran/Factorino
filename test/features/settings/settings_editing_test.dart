import 'dart:async';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/models/seller_identity.dart';
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

  /// Scrolls until [text] is on screen.
  ///
  /// The seller section joined the top of this screen in D-077, so the
  /// sections below it are past the phone fold and, past the cache extent,
  /// **not in the tree at all** -- a finder returns nothing rather than
  /// something off-screen, which reads like a missing widget.
  Future<void> reach(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  /// Opens the **invoicing** editor.
  ///
  /// By tooltip rather than by icon: since D-077 two sections each carry an
  /// `Icons.edit_outlined` control, and `find.byIcon` matches both. The
  /// tooltips are exact strings and differ, which is also why the seller's is
  /// the full phrase rather than the bare «ویرایش» -- with two controls on one
  /// screen, a tooltip that does not say which section it opens is no help to
  /// a user either.
  Future<AppStrings> openEditor(WidgetTester tester) async {
    final AppStrings strings = await pumpSettings(tester);
    await tester.tap(find.byTooltip(strings.settingsEditTooltip));
    await tester.pumpAndSettle();
    return strings;
  }

  /// Opens the **seller** editor (D-077).
  Future<AppStrings> openSellerEditor(
    WidgetTester tester, {
    AppSettings initial = settings,
  }) async {
    final AppStrings strings = await pumpSettings(tester, initial: initial);
    await tester.tap(find.byTooltip(strings.settingsSellerEditTooltip));
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
      await reach(tester, strings.settingsLastBackupNever);
      expect(find.text(strings.settingsLastBackupNever), findsOneWidget);
    });

    testWidgets('renders a Jalali date, not an epoch number', (
      WidgetTester tester,
    ) async {
      // **Known issue 6's first half.** This row would have rendered
      // «۱٬۷۵۶٬۰۰۰٬۰۰۰٬۰۰۰» the moment `lastBackupAt` stopped being null, and
      // until this increment nothing could make it non-null, so nothing showed.
      final AppStrings strings = await pumpSettings(
        tester,
        initial: settings.copyWith(lastBackupAt: DateTime.utc(2026, 9, 1, 12)),
      );
      await reach(tester, strings.settingsLastBackup);

      expect(find.textContaining('۱۴۰۵'), findsWidgets);
      expect(
        find.textContaining('۱٬۷۵'),
        findsNothing,
        reason: 'an epoch millisecond count is on screen',
      );
    });
  });

  /// The seller editor (D-077).
  ///
  /// **One rule, and it is reported rather than clamped** (D-027): the
  /// business name is required as soon as any other seller field carries a
  /// value, because a block headed «فروشنده» over a telephone number and no
  /// name identifies nobody. Emptying all three is always allowed, and has to
  /// be — it is the only way for a user who wants no seller block to get rid
  /// of one.
  group('the seller editor', () {
    testWidgets('it opens with what is stored', (WidgetTester tester) async {
      final AppStrings strings = await openSellerEditor(
        tester,
        initial: settings.copyWith(
          // Two fields, so this pins that the sheet arrives filled rather
          // than that one controller happens to be wired.
          seller: const SellerIdentity(
            name: 'مهندسی نوآوران فناوری پارسیان',
            phone: '02188776655',
          ),
        ),
      );

      expect(find.text(strings.settingsSellerEditTitle), findsOneWidget);
      // `widgetWithText` on the field, not a bare `find.text`: the screen
      // behind the sheet is still in the tree and shows the same value in its
      // row, so a bare finder matches twice and would keep matching if the
      // field arrived empty.
      expect(
        find.widgetWithText(TextFormField, 'مهندسی نوآوران فناوری پارسیان'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, '02188776655'), findsOneWidget);
    });

    testWidgets('a name alone is enough, and is written', (
      WidgetTester tester,
    ) async {
      final AppStrings strings = await openSellerEditor(tester);
      await enter(tester, strings.settingsSellerFieldName, 'کارگاه فنی مهر');
      await save(tester, strings);

      expect(repository.written, hasLength(1));
      expect(repository.written.single.seller.name, 'کارگاه فنی مهر');
      expect(repository.written.single.seller.isPrintable, isTrue);
    });

    testWidgets('details with no name are refused, and nothing is written', (
      WidgetTester tester,
    ) async {
      // The combination the document cannot print. Refusing it in the form is
      // what keeps `_seller`'s re-check from ever being the thing the user
      // meets — and the assertion that matters is what the refusal **left
      // behind**: a guard that reports after writing is worse than none
      // (D-060).
      final AppStrings strings = await openSellerEditor(tester);
      // نشانی rather than the name: any field but the name reaches the same
      // rule, and this was کد اقتصادی until D-106 removed that field.
      await enter(
        tester,
        strings.settingsSellerFieldAddress,
        'تهران، خیابان ولی‌عصر، پلاک ۱۲۳',
      );
      await save(tester, strings);

      expect(
        find.text(strings.settingsErrorSellerNameRequired),
        findsOneWidget,
      );
      expect(repository.written, isEmpty);
      expect(
        find.text(strings.settingsSellerEditTitle),
        findsOneWidget,
        reason: 'the sheet stays open on a refusal, with the value still typed',
      );
    });

    testWidgets('clearing every field is allowed, and reaches the row as '
        'nulls', (WidgetTester tester) async {
      // **The case `copyWith` on four nullable strings could not express**,
      // and the reason `SellerIdentity` is a value object: `?? this.name` on a
      // cleared field writes the old name straight back, and the user finds
      // out on the next document they print.
      final AppStrings strings = await openSellerEditor(
        tester,
        initial: settings.copyWith(
          seller: const SellerIdentity(
            name: 'کارگاه فنی مهر',
            phone: '02188776655',
          ),
        ),
      );

      await enter(tester, strings.settingsSellerFieldName, '');
      await enter(tester, strings.settingsSellerFieldPhone, '');
      await save(tester, strings);

      expect(repository.written, hasLength(1));
      expect(repository.written.single.seller, SellerIdentity.none);
      expect(repository.written.single.seller.isEmpty, isTrue);
    });

    testWidgets('whitespace is not a value', (WidgetTester tester) async {
      // A name of three spaces would satisfy a `isNotEmpty` check, print as a
      // blank line under «فروشنده», and look exactly like a document that
      // failed. Folded at the sheet, and again at the repository.
      final AppStrings strings = await openSellerEditor(tester);
      await enter(tester, strings.settingsSellerFieldName, '   ');
      await enter(tester, strings.settingsSellerFieldPhone, '   ');
      await save(tester, strings);

      expect(repository.written, hasLength(1));
      expect(repository.written.single.seller, SellerIdentity.none);
    });

    testWidgets('editing the seller leaves the invoicing settings alone', (
      WidgetTester tester,
    ) async {
      // Two sheets, one settings row. A seller edit that reset the tax rate to
      // a default would be the kind of defect nobody looks for, and would show
      // up on the next invoice rather than on this screen.
      final AppStrings strings = await openSellerEditor(tester);
      await enter(tester, strings.settingsSellerFieldName, 'کارگاه فنی مهر');
      await save(tester, strings);

      final AppSettings written = repository.written.single;
      expect(written.defaultTaxRateBp, 900);
      expect(written.invoiceNumberPrefix, 'INV');
      expect(written.paymentTermDays, 45);
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

  @override
  Future<void> markTutorialSeen(DateTime at) async {}
}
