import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/customer_repository.dart';
import 'package:factorino/features/customers/presentation/customer_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screen_harness.dart';

/// The customer form — and, specifically, **D-030's first real call site**.
///
/// The decision was recorded in the log and then checked mechanically against
/// the ARB by `no_hardcoded_strings_test.dart`. Neither of those can tell
/// whether the copy is actually *used* correctly on a screen: an ARB entry that
/// says the right thing is worthless if the field shows a green "verified" tick
/// beside it. This file is where the constraint is checked against behaviour.
void main() {
  Future<void> pumpForm(
    WidgetTester tester, {
    _RecordingCustomerRepository? repository,
  }) async {
    await pumpScreen(
      tester,
      const CustomerFormScreen(),
      overrides: <Override>[
        customerRepositoryProvider.overrideWithValue(
          repository ?? _RecordingCustomerRepository(),
        ),
      ],
      size: const Size(500, 1000),
    );
    await tester.pumpAndSettle();
  }

  Finder fieldFor(WidgetTester tester, String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(TextFormField),
    );
  }

  group('national ID — D-030', () {
    testWidgets('a failing checksum is called invalid, plainly', (
      WidgetTester tester,
    ) async {
      // A value that fails the checksum is genuinely invalid and may be called
      // so. D-030 constrains only the success wording.
      await pumpForm(tester);
      final AppStrings strings = stringsOf(tester, CustomerFormScreen);

      await tester.enterText(
        fieldFor(tester, strings.customerFieldFullName),
        'مریم احمدی',
      );
      await tester.enterText(
        fieldFor(tester, strings.customerFieldNationalId),
        '1234567890',
      );
      await tester.tap(find.text(strings.actionSave));
      await tester.pumpAndSettle();

      expect(find.text(strings.nationalIdInvalid), findsOneWidget);
    });

    testWidgets('a passing checksum produces no affirmative message', (
      WidgetTester tester,
    ) async {
      // The heart of D-030. A passing checksum narrows the space of typos and
      // says nothing about whether the number belongs to the person named on
      // the invoice — remainders 1 and 10 map to the same check digit, so a
      // transposition can survive. A user told their entry is "verified" stops
      // checking it, which is exactly when a transposed digit reaches a tax
      // document.
      final _RecordingCustomerRepository repository =
          _RecordingCustomerRepository();
      await pumpForm(tester, repository: repository);
      final AppStrings strings = stringsOf(tester, CustomerFormScreen);

      await tester.enterText(
        fieldFor(tester, strings.customerFieldFullName),
        'مریم احمدی',
      );
      await tester.enterText(
        fieldFor(tester, strings.customerFieldNationalId),
        // A genuinely valid کد ملی by the published algorithm.
        '0079542311',
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.nationalIdInvalid), findsNothing);
      // No affirmative message anywhere on the screen -- not the ARB's own
      // "format is valid" string, and certainly nothing stronger.
      expect(find.text(strings.nationalIdFormatValid), findsNothing);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.verified), findsNothing);
      expect(find.byIcon(Icons.verified_user), findsNothing);
    });

    testWidgets('the field is optional and an empty value saves', (
      WidgetTester tester,
    ) async {
      final _RecordingCustomerRepository repository =
          _RecordingCustomerRepository();
      await pumpForm(tester, repository: repository);
      final AppStrings strings = stringsOf(tester, CustomerFormScreen);

      await tester.enterText(
        fieldFor(tester, strings.customerFieldFullName),
        'مریم احمدی',
      );
      await tester.tap(find.text(strings.actionSave));
      await tester.pumpAndSettle();

      expect(repository.created, hasLength(1));
      expect(repository.created.single.nationalId, isNull);
    });
  });

  group('validation at the form boundary', () {
    testWidgets('a name is required', (WidgetTester tester) async {
      final _RecordingCustomerRepository repository =
          _RecordingCustomerRepository();
      await pumpForm(tester, repository: repository);
      final AppStrings strings = stringsOf(tester, CustomerFormScreen);

      await tester.tap(find.text(strings.actionSave));
      await tester.pumpAndSettle();

      expect(find.text(strings.validationRequired), findsOneWidget);
      expect(repository.created, isEmpty);
    });

    testWidgets('a mobile number typed in Persian digits is accepted', (
      WidgetTester tester,
    ) async {
      // §9: users type Persian and Arabic-Indic digits interchangeably, and
      // every numeric input passes through the normalizer before it is judged.
      // Rejecting ۰۹۱۲... as "not a mobile number" would be the app failing to
      // read its own language.
      final _RecordingCustomerRepository repository =
          _RecordingCustomerRepository();
      await pumpForm(tester, repository: repository);
      final AppStrings strings = stringsOf(tester, CustomerFormScreen);

      await tester.enterText(
        fieldFor(tester, strings.customerFieldFullName),
        'مریم احمدی',
      );
      await tester.enterText(
        fieldFor(tester, strings.customerFieldMobile),
        '۰۹۱۲۳۴۵۶۷۸۹',
      );
      await tester.tap(find.text(strings.actionSave));
      await tester.pumpAndSettle();

      expect(find.text(strings.validationMobileInvalid), findsNothing);
      expect(repository.created, hasLength(1));
    });

    testWidgets('a +98 number is accepted', (WidgetTester tester) async {
      final _RecordingCustomerRepository repository =
          _RecordingCustomerRepository();
      await pumpForm(tester, repository: repository);
      final AppStrings strings = stringsOf(tester, CustomerFormScreen);

      await tester.enterText(
        fieldFor(tester, strings.customerFieldFullName),
        'مریم احمدی',
      );
      await tester.enterText(
        fieldFor(tester, strings.customerFieldMobile),
        '+989123456789',
      );
      await tester.tap(find.text(strings.actionSave));
      await tester.pumpAndSettle();

      expect(repository.created, hasLength(1));
    });

    testWidgets('a number that is not an Iranian mobile is rejected here', (
      WidgetTester tester,
    ) async {
      // Validation lives at the form boundary, not in the repository: the
      // repository deliberately stores an unrecognised number as typed, so
      // this screen is the only thing that can ask the user whether they meant
      // it.
      final _RecordingCustomerRepository repository =
          _RecordingCustomerRepository();
      await pumpForm(tester, repository: repository);
      final AppStrings strings = stringsOf(tester, CustomerFormScreen);

      await tester.enterText(
        fieldFor(tester, strings.customerFieldFullName),
        'مریم احمدی',
      );
      await tester.enterText(
        fieldFor(tester, strings.customerFieldMobile),
        '12345',
      );
      await tester.tap(find.text(strings.actionSave));
      await tester.pumpAndSettle();

      expect(find.text(strings.validationMobileInvalid), findsOneWidget);
      expect(repository.created, isEmpty);
    });
  });
}

/// Records what the form asked the data layer to store.
class _RecordingCustomerRepository implements CustomerRepository {
  final List<CustomerDraft> created = <CustomerDraft>[];

  @override
  Future<Customer> create(CustomerDraft draft) async {
    created.add(draft);
    return Customer(
      id: 'created-${created.length}',
      fullName: draft.fullName,
      mobile: draft.mobile,
      companyName: draft.companyName,
      nationalId: draft.nationalId,
      economicId: draft.economicId,
      address: draft.address,
      notes: draft.notes,
      createdAt: DateTime.utc(2026, 8, 24),
      updatedAt: DateTime.utc(2026, 8, 24),
    );
  }

  @override
  Future<Customer> update(String id, CustomerDraft draft) => create(draft);

  @override
  Future<int> count() async => created.length;

  @override
  Stream<int> watchCount() => Stream<int>.value(created.length);

  @override
  Future<Customer?> findById(String id) async => null;

  @override
  Future<List<Customer>> search(
    String term, {
    int limit = 100,
    int offset = 0,
  }) async => const <Customer>[];

  @override
  Future<void> softDelete(String id) async {}

  @override
  Stream<List<Customer>> watchAll({int limit = 100, int offset = 0}) =>
      Stream<List<Customer>>.value(const <Customer>[]);

  @override
  Stream<List<Customer>> watchSearch(
    String term, {
    int limit = 100,
    int offset = 0,
  }) => Stream<List<Customer>>.value(const <Customer>[]);
}
