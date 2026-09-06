import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/models/seller_identity.dart';
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

  /// A business that has filled the seller section in, at the length real
  /// Iranian data reaches -- `PersianFixtures`' rule applied to this screen.
  const SellerIdentity filledSeller = SellerIdentity(
    name: 'مهندسی نوآوران فناوری پارسیان',
    address: 'تهران، خیابان ولی‌عصر، بالاتر از میدان ونک، پلاک ۱۲۳',
    phone: '02188776655',
  );

  Future<AppStrings> pumpSettings(
    WidgetTester tester, {
    AppSettings value = settings,
    Size size = kMobileSize,
  }) async {
    await pumpScreen(
      tester,
      const SettingsScreen(),
      size: size,
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(
          _FakeSettingsRepository(value),
        ),
      ],
    );
    await tester.pumpAndSettle();
    return stringsOf(tester, SettingsScreen);
  }

  /// Scrolls until [text] is on screen.
  ///
  /// Needed since the seller section joined the top of this screen (D-077):
  /// the sections below it are past the phone fold and, past the cache extent,
  /// **not in the tree at all** -- a finder returns nothing rather than
  /// something off-screen, which reads like a missing widget. The same trap
  /// D-064 hit on the desktop form.
  Future<void> reach(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
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
    await reach(tester, strings.settingsLastBackupNever);

    expect(find.text(strings.settingsLastBackupNever), findsOneWidget);
    expect(find.text(strings.settingsLastBackup), findsOneWidget);
  });

  testWidgets('the term sits beside the other invoicing settings', (
    WidgetTester tester,
  ) async {
    // A payment term belongs with the VAT rate and the numbering prefix -- it
    // is the same kind of thing, and the sections below it are not.
    //
    // **Pumped at the desktop size and not scrolled**, which is a change of
    // method rather than of claim. Both landmarks have to be in the tree at
    // once for a comparison of their positions to mean anything, and with the
    // appearance section joining the screen (D-087) there is no scroll offset
    // on a 400 x 800 phone where the invoicing heading and the backup heading
    // are both built -- a `ListView` does not keep what is far off screen. A
    // window tall enough to hold the whole screen removes the question, and
    // the order under test is the same order at every tier.
    //
    // The height is a measuring instrument rather than a claim about any real
    // window: it is simply larger than the screen's own content, so nothing is
    // virtualized away while two positions are compared.
    final AppStrings strings = await pumpSettings(
      tester,
      size: const Size(1400, 1600),
    );

    expect(find.text(strings.settingsInvoicingSection), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(strings.settingsPaymentTerm)).dy,
      lessThan(tester.getTopLeft(find.text(strings.settingsBackupSection)).dy),
    );
  });

  group('the seller section (D-077)', () {
    testWidgets('an empty seller says what the document will do about it', (
      WidgetTester tester,
    ) async {
      // **The state every existing database is in.** Schema v5 adds the four
      // columns and backfills nothing, because there was nothing to migrate
      // from and nothing honest to invent -- so this is what every user sees
      // the first time they open this screen after updating.
      //
      // The obligation is not that they fill it in. An empty seller blocks
      // nothing -- not issuing, not printing; it is their document and their
      // call. The obligation is that they are **told what it costs**, here,
      // where they can act on it, before they print a page missing half its
      // identity.
      final AppStrings strings = await pumpSettings(tester);

      expect(find.text(strings.settingsSellerSection), findsOneWidget);
      expect(find.text(strings.settingsSellerConsequence), findsOneWidget);
      expect(
        find.text(strings.settingsSellerEmpty),
        findsNWidgets(3),
        reason:
            'every unfilled seller row states that it was never given, rather '
            'than leaving a blank that reads as a value which failed to load',
      );
    });

    testWidgets('the consequence goes away once the name is there', (
      WidgetTester tester,
    ) async {
      // What makes it a prompt rather than a standing notice: filling the
      // field the sentence is about removes the sentence. A warning that
      // stays put after it has been answered is one the user learns to read
      // past.
      final AppStrings strings = await pumpSettings(
        tester,
        value: settings.copyWith(seller: filledSeller),
      );

      expect(find.text(strings.settingsSellerConsequence), findsNothing);
      expect(find.text(filledSeller.name!), findsOneWidget);
      expect(find.text(strings.settingsSellerEmpty), findsNothing);
    });

    testWidgets('a partly-filled seller still warns, because it will not '
        'print', (WidgetTester tester) async {
      // The case the form refuses to create and the document refuses to
      // print: details with no name to hang them on. It can still arrive
      // through a restored backup or a pre-rule write, and the screen has to
      // tell the truth about it rather than assume it away -- the same
      // reasoning that makes the builder re-check `isPrintable`.
      final AppStrings strings = await pumpSettings(
        tester,
        value: settings.copyWith(
          seller: const SellerIdentity(phone: '02188776655'),
        ),
      );

      expect(find.text(strings.settingsSellerConsequence), findsOneWidget);
    });

    testWidgets('it is the first thing on the screen', (
      WidgetTester tester,
    ) async {
      // Deliberate, and worth pinning: every database reaches v5 with this
      // section empty, so it is the one part of this screen every existing
      // user has something to do in.
      final AppStrings strings = await pumpSettings(tester);

      expect(
        tester.getTopLeft(find.text(strings.settingsSellerSection)).dy,
        lessThan(
          tester.getTopLeft(find.text(strings.settingsInvoicingSection)).dy,
        ),
      );
    });

    testWidgets('a filled seller fits the phone, at real Persian lengths', (
      WidgetTester tester,
    ) async {
      // A `RenderFlex` overflow fails the test on its own, which is the
      // assertion wanted here -- the same shape as the backup-row test above,
      // and for the same reason: these rows put a long value in the prominent
      // figure style beside a label, which is exactly the pairing that
      // overflowed by 132 pixels before `_SettingRow` became a `Wrap`.
      final AppStrings strings = await pumpSettings(
        tester,
        value: settings.copyWith(seller: filledSeller),
      );

      expect(find.text(filledSeller.address!), findsOneWidget);
      expect(find.text(strings.settingsSellerFieldAddress), findsOneWidget);
    });
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

  @override
  Future<void> markTutorialSeen(DateTime at) async {}
}
