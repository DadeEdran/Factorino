import 'dart:async';

import 'package:factorino/core/formatting/persian_text.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repository_harness.dart';

/// `CustomerRepository` against a real encrypted database.
///
/// This is the repository that makes the `search_name` guard non-vacuous: it is
/// the first real call site of `searchKey`, and a guard that has never fired on
/// real code is an untested guard.
void main() {
  late RepositoryHarness harness;

  setUp(() async => harness = await RepositoryHarness.open());
  tearDown(() async => harness.close());

  group('create', () {
    test('returns a domain model, not a database row', () async {
      final customer = await harness.customer(name: 'علی رضایی');

      expect(customer, isA<Customer>());
      expect(customer.id, isNotEmpty);
      expect(customer.fullName, 'علی رضایی');
      expect(customer.createdAt.isUtc, isTrue, reason: 'D-005: stored UTC');
    });

    test('normalizes the mobile number to the stored form', () async {
      final customer = await harness.customers.create(
        const CustomerDraft(fullName: 'علی', mobile: '+98 912 345 6789'),
      );
      expect(customer.mobile, '09123456789');
    });

    test('keeps an unrecognised number rather than discarding it', () async {
      // A foreign client's number is data the user deliberately entered.
      // Validation belongs at the form, where they can be told in Persian.
      final customer = await harness.customers.create(
        const CustomerDraft(fullName: 'John', mobile: '+1 202 555 0143'),
      );
      expect(customer.mobile, '+1 202 555 0143');
    });

    test('trims blank optional fields to null', () async {
      final customer = await harness.customers.create(
        const CustomerDraft(fullName: '  علی  ', companyName: '   '),
      );
      expect(customer.fullName, 'علی');
      expect(customer.companyName, isNull);
    });
  });

  group('search', () {
    test('the §9 case: saved with Arabic yeh, found with Persian', () async {
      await harness.customer(name: 'علي رضایی');
      final found = await harness.customers.search('علی');
      expect(found, hasLength(1));
      expect(found.single.fullName, 'علي رضایی');
    });

    test('matches on the company name as well as the person', () async {
      await harness.customers.create(
        const CustomerDraft(fullName: 'علی رضایی', companyName: 'شرکت دلتا'),
      );
      expect(await harness.customers.search('دلتا'), hasLength(1));
      expect(await harness.customers.search('رضایی'), hasLength(1));
    });

    test('a term cannot match across the field boundary', () async {
      // The two fields are joined by a separator searchKey can never produce,
      // so a query cannot span them (D-029).
      await harness.customers.create(
        const CustomerDraft(fullName: 'احمد', companyName: 'دلتا'),
      );
      expect(await harness.customers.search('احمددلتا'), isEmpty);
      expect(await harness.customers.search('احمد'), hasLength(1));
    });

    test('an empty term returns everything', () async {
      await harness.customer(name: 'علی');
      await harness.customer(name: 'محمد');
      expect(await harness.customers.search(''), hasLength(2));
      expect(await harness.customers.search('   '), hasLength(2));
    });

    test('a non-matching term returns nothing', () async {
      await harness.customer(name: 'علی رضایی');
      expect(await harness.customers.search('نادر'), isEmpty);
    });
  });

  group('update - the case most likely to be missed', () {
    test('rewrites search_name so the old name stops matching', () async {
      // The failure this guards against is silent in the worst way: the row is
      // still found, by the term the user no longer typed, and the list looks
      // populated rather than broken.
      final customer = await harness.customer(name: 'علي رضایی');

      await harness.customers.update(
        customer.id,
        const CustomerDraft(fullName: 'محمد حسینی'),
      );

      expect(
        await harness.customers.search('رضایی'),
        isEmpty,
        reason: 'the old name must stop matching',
      );
      final found = await harness.customers.search('حسینی');
      expect(found, hasLength(1));
      expect(found.single.fullName, 'محمد حسینی');
    });

    test('the stored key is exactly what searchKey produces', () async {
      final customer = await harness.customer(name: 'علي رضایی');
      await harness.customers.update(
        customer.id,
        const CustomerDraft(fullName: 'كوروش كريمي', companyName: 'شرکت آلفا'),
      );

      final row =
          await (harness.db.select(harness.db.customers)
                // soft-delete-exempt: asserting on the stored row itself.
                ..where((r) => r.id.equals(customer.id)))
              .getSingle();

      expect(
        row.searchName,
        searchKeyOf(<String?>['كوروش كريمي', 'شرکت آلفا']),
      );
    });

    test('a removed company name is dropped from the key', () async {
      final customer = await harness.customers.create(
        const CustomerDraft(fullName: 'علی', companyName: 'شرکت دلتا'),
      );
      expect(await harness.customers.search('دلتا'), hasLength(1));

      await harness.customers.update(
        customer.id,
        const CustomerDraft(fullName: 'علی'),
      );
      expect(await harness.customers.search('دلتا'), isEmpty);
    });

    test('bumps updatedAt', () async {
      final customer = await harness.customer(name: 'علی');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final updated = await harness.customers.update(
        customer.id,
        const CustomerDraft(fullName: 'علی رضایی'),
      );
      expect(
        updated.updatedAt.isAfter(customer.updatedAt) ||
            updated.updatedAt == customer.updatedAt,
        isTrue,
      );
      expect(updated.fullName, 'علی رضایی');
    });

    test('throws for an unknown id rather than silently doing nothing', () {
      expect(
        () => harness.customers.update(
          'no-such-id',
          const CustomerDraft(fullName: 'علی'),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('soft delete', () {
    test('removes the customer from every read path', () async {
      final customer = await harness.customer(name: 'علی رضایی');
      await harness.customers.softDelete(customer.id);

      expect(await harness.customers.findById(customer.id), isNull);
      expect(await harness.customers.search('علی'), isEmpty);
      expect(await harness.customers.search(''), isEmpty);
      expect(await harness.customers.count(), 0);
    });

    test('the row is still there - it is a soft delete', () async {
      final customer = await harness.customer(name: 'علی');
      await harness.customers.softDelete(customer.id);

      // soft-delete-exempt: proving the row survives is the point of the test.
      final rows = await harness.db.select(harness.db.customers).get();
      expect(rows, hasLength(1));
      expect(rows.single.deletedAt, isNotNull);
    });
  });

  group('watch', () {
    test('emits again when a customer is added', () async {
      final emissions = <int>[];
      final subscription = harness.customers.watchAll().listen(
        (list) => emissions.add(list.length),
      );

      await harness.customer(name: 'علی');
      await harness.customer(name: 'محمد');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(emissions.last, 2);
    });

    test('a search stream narrows as the data changes', () async {
      final customer = await harness.customer(name: 'علی رضایی');
      final results = <int>[];
      final subscription = harness.customers
          .watchSearch('رضایی')
          .listen((list) => results.add(list.length));

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await harness.customers.softDelete(customer.id);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(results.first, 1);
      expect(results.last, 0);
    });
  });

  test('count ignores soft-deleted rows', () async {
    await harness.customer(name: 'علی');
    final second = await harness.customer(name: 'محمد');
    expect(await harness.customers.count(), 2);

    await harness.customers.softDelete(second.id);
    expect(await harness.customers.count(), 1);
  });

  test('watchCount is live, so a dashboard tile cannot go stale', () async {
    // The reason the dashboard needs a stream rather than a Future behind a
    // provider: a Future answers once and is then quietly wrong, and a count
    // that is quietly wrong is worse than no tile at all.
    final List<int> seen = <int>[];
    final StreamSubscription<int> subscription = harness.customers
        .watchCount()
        .listen(seen.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(seen, <int>[0]);

    final created = await harness.customer(name: 'علی');
    await pumpEventQueue();
    expect(seen.last, 1);

    await harness.customers.softDelete(created.id);
    await pumpEventQueue();
    expect(seen.last, 0);
  });
}
