import 'dart:async';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/data/models/app_settings.dart';
import 'package:factorino/data/models/seller_identity.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/invoice_list_item.dart';
import 'package:factorino/data/repositories/customer_repository.dart';
import 'package:factorino/data/repositories/settings_repository.dart';
import 'package:factorino/features/dashboard/presentation/dashboard_screen.dart';
import 'package:factorino/features/settings/presentation/widgets/seller_identity_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../invoices/fake_invoice_repository.dart';
import '../screen_harness.dart';

/// The dashboard's seller prompt (D-102).
///
/// **The gap it closes is one of timing, not of information.** D-077 put the
/// prompt on the settings screen, which covers the user who goes looking. Every
/// other user met the requirement at the moment they saved their first PDF and
/// got an explanation instead of a document — and the owner, testing exactly
/// that, read a working save as a failure (D-101).
///
/// Three properties are pinned here, and the third is the one that would decay
/// quietly: that it appears for the user it is *for*, that it goes away by being
/// satisfied, and that it **blocks nothing** — D-077's ruling, which this must
/// not reopen.
void main() {
  const AppSettings empty = AppSettings(
    defaultTaxRateBp: 900,
    roundingUnitRial: 0,
    invoiceNumberPrefix: 'INV',
  );

  final AppSettings named = empty.copyWith(
    seller: const SellerIdentity(name: 'کارگاه نمونه'),
  );

  Future<AppStrings> pumpPrompt(
    WidgetTester tester, {
    required AppSettings settings,
  }) async {
    await pumpScreen(
      tester,
      const SellerIdentityPrompt(),
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(
          _FakeSettingsRepository(settings),
        ),
      ],
    );
    await tester.pumpAndSettle();
    return stringsOf(tester, SellerIdentityPrompt);
  }

  testWidgets('it asks, while there is no business name', (
    WidgetTester tester,
  ) async {
    final AppStrings strings = await pumpPrompt(tester, settings: empty);

    expect(find.text(strings.sellerPromptTitle), findsOneWidget);
    expect(find.text(strings.sellerPromptBody), findsOneWidget);
    expect(find.text(strings.sellerPromptAction), findsOneWidget);
  });

  testWidgets('it says both consequences, including the one that confused', (
    WidgetTester tester,
  ) async {
    // The second half — that the file will not open by itself — is the sentence
    // that stops D-101's sequence from being a surprise. Saying only that the
    // seller block will be missing would leave the export message's behaviour
    // unexplained until it happened.
    final AppStrings strings = await pumpPrompt(tester, settings: empty);

    expect(strings.sellerPromptBody, contains('فروشنده'));
    expect(strings.sellerPromptBody, contains('باز نمی‌شود'));
  });

  testWidgets('it is gone once the name is there', (WidgetTester tester) async {
    final AppStrings strings = await pumpPrompt(tester, settings: named);

    expect(find.text(strings.sellerPromptTitle), findsNothing);
    expect(
      find.byType(Card),
      findsNothing,
      reason: 'a satisfied prompt leaves nothing behind, not an empty card',
    );
  });

  testWidgets('a name alone satisfies it — the other fields are optional', (
    WidgetTester tester,
  ) async {
    // `isPrintable` is the question, not `isNotEmpty` (D-077): the document
    // prints no block without a name, and prints one perfectly well without an
    // address or a کد اقتصادی. A prompt that held out for all four would be
    // asking for something the document does not need.
    final AppStrings strings = await pumpPrompt(
      tester,
      settings: empty.copyWith(
        seller: const SellerIdentity(name: 'کارگاه نمونه'),
      ),
    );
    expect(find.text(strings.sellerPromptTitle), findsNothing);
  });

  testWidgets('an address without a name does not satisfy it', (
    WidgetTester tester,
  ) async {
    // The other side of the same rule: an identity with something in it that
    // still cannot head a block. `isNotEmpty` would be true here and the
    // document would still print nothing.
    final AppStrings strings = await pumpPrompt(
      tester,
      settings: empty.copyWith(
        seller: const SellerIdentity(address: 'تهران، خیابان ولی‌عصر'),
      ),
    );
    expect(find.text(strings.sellerPromptTitle), findsOneWidget);
  });

  testWidgets('it has no way to be dismissed', (WidgetTester tester) async {
    // **The design, asserted.** A prompt that can be waved away is one that
    // gets waved away and forgotten, which returns the application to the state
    // this exists to prevent. It leaves by being satisfied or not at all.
    await pumpPrompt(tester, settings: empty);

    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(
      find.byType(FilledButton),
      findsOneWidget,
      reason: 'exactly one control, and it is the one that fixes the problem',
    );
  });

  testWidgets('nothing is shown while the answer is unknown', (
    WidgetTester tester,
  ) async {
    // A prompt that flashed before the settings read landed would tell a user
    // with a perfectly good business name to enter one, on every cold start.
    await pumpScreen(
      tester,
      const SellerIdentityPrompt(),
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(
          _NeverSettingsRepository(),
        ),
      ],
    );
    await tester.pump();

    expect(find.byType(FilledButton), findsNothing);
  });

  /// A brand-new database: no invoices, no customers, no seller.
  List<Override> dashboardOverrides() => <Override>[
    settingsRepositoryProvider.overrideWithValue(
      _FakeSettingsRepository(empty),
    ),
    invoiceRepositoryProvider.overrideWithValue(
      FakeInvoiceRepository(const <InvoiceListItem>[]),
    ),
    customerRepositoryProvider.overrideWithValue(_NoCustomers()),
  ];

  group('on the dashboard, where the user it is for actually is', () {
    testWidgets('it shows above the empty state a new user sees', (
      WidgetTester tester,
    ) async {
      // **The placement this widget lives or dies by.** A brand-new database
      // has no invoices, so the dashboard renders its empty state rather than
      // `_DashboardBody` — and a prompt placed inside the body would have been
      // shown to everybody except the first-time user it exists for.
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: dashboardOverrides(),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, DashboardScreen);
      expect(find.text(strings.sellerPromptTitle), findsOneWidget);
      expect(
        find.text(strings.emptyDashboardTitle),
        findsOneWidget,
        reason: 'this is the state a first-time user is in',
      );
      expect(
        tester.getTopLeft(find.text(strings.sellerPromptTitle)).dy,
        lessThan(tester.getTopLeft(find.text(strings.emptyDashboardTitle)).dy),
      );
    });

    testWidgets('and it blocks nothing — D-077 stands', (
      WidgetTester tester,
    ) async {
      // A prompt, not a gate: the dashboard is fully usable with it on screen,
      // exactly as it is without.
      //
      // **Not asserted by looking for a `ModalBarrier`** — every route under a
      // `Navigator` has one, so that check passes and fails for reasons that
      // have nothing to do with this widget. What "blocks nothing" means here
      // is that the page's own content is present and reachable beside the
      // prompt, and that nothing modal has been put over it.
      await pumpScreen(
        tester,
        const DashboardScreen(),
        overrides: dashboardOverrides(),
      );
      await tester.pumpAndSettle();

      final AppStrings strings = stringsOf(tester, DashboardScreen);
      expect(find.text(strings.sellerPromptTitle), findsOneWidget);
      expect(
        find.text(strings.emptyDashboardTitle),
        findsOneWidget,
        reason: 'the dashboard still says what it has to say',
      );
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

/// No customers at all, which is what a new database has.
class _NoCustomers implements CustomerRepository {
  @override
  Stream<int> watchCount() => Stream<int>.value(0);

  @override
  Future<int> count() async => 0;

  @override
  Stream<List<Customer>> watchAll({int limit = 100, int offset = 0}) =>
      Stream<List<Customer>>.value(const <Customer>[]);

  @override
  Stream<List<Customer>> watchSearch(
    String term, {
    int limit = 100,
    int offset = 0,
  }) => Stream<List<Customer>>.value(const <Customer>[]);

  @override
  Future<List<Customer>> search(
    String term, {
    int limit = 100,
    int offset = 0,
  }) async => const <Customer>[];

  @override
  Future<Customer?> findById(String id) async => null;

  @override
  Future<Customer> create(CustomerDraft draft) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Future<Customer> update(String id, CustomerDraft draft) =>
      throw UnimplementedError('not exercised by these tests');

  @override
  Future<void> softDelete(String id) async {}
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._settings);

  final AppSettings _settings;

  @override
  Future<AppSettings> read() async => _settings;

  @override
  Stream<AppSettings> watch() => Stream<AppSettings>.value(_settings);

  @override
  Future<AppSettings> write(AppSettings settings) async => settings;

  @override
  Future<void> markBackedUp(DateTime at) async {}
}

/// Never emits: the state between a cold start and the first read.
class _NeverSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings> read() => Completer<AppSettings>().future;

  @override
  Stream<AppSettings> watch() => const Stream<AppSettings>.empty();

  @override
  Future<AppSettings> write(AppSettings settings) async => settings;

  @override
  Future<void> markBackedUp(DateTime at) async {}
}
