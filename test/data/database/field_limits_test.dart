import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/models/field_limits.dart';
import 'package:flutter_test/flutter_test.dart';

/// The schema's length limits and the forms' length limits are the same
/// numbers, proved rather than asserted by a comment.
///
/// the project spec asks for field-level limits on the customer and product
/// free-text fields. The schema has carried them since increment (a); the forms
/// carried none, so an over-long value was accepted by the form and refused by
/// drift with an `InvalidDataException` that surfaces as the generic
/// «خطایی رخ داد» — the user told that something failed, and not which field or
/// why (D-042).
///
/// The obvious fix — have `withLength(max:)` reference the shared constant —
/// **does not work and fails silently**, which is why this file exists.
/// `drift_dev` reads that argument with `readIntLiteral`
/// (`drift_dev-2.34.5/lib/src/analysis/resolver/dart/helper.dart:206`), which
/// accepts an `IntegerLiteral` and returns `null` for anything else. A constant
/// reference therefore generates a column with **no length constraint at all**,
/// and the schema would end up weaker than before the sharing was introduced.
///
/// So the tables keep their literals and this asks each generated column where
/// it actually starts rejecting values. That is the stronger check of the two:
/// it proves the constraint exists and where it bites, rather than proving two
/// source files contain the same token.
void main() {
  late AppDatabase db;

  setUp(() {
    // In memory and unencrypted, deliberately: every question below is about
    // the generated column objects, which no connection affects. The pragma is
    // set anyway because `AppDatabase.beforeOpen` verifies it, and a test that
    // failed there would be failing for a reason unrelated to what it checks.
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (db) => db.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
  });

  tearDown(() => db.close());

  /// The largest string [column] accepts, found by asking it.
  ///
  /// Deliberately behavioural. Reading a number out of the generated source
  /// would pass whether or not the constraint were ever applied; this exercises
  /// `additionalChecks`, which is the same code path a real insert goes
  /// through.
  void expectLimit(GeneratedColumn<String> column, int limit) {
    const VerificationMeta meta = VerificationMeta('probe');

    expect(
      column.isAcceptableValue('x' * limit, meta).success,
      isTrue,
      reason:
          '${column.$name} refused a value of exactly $limit characters, which '
          'field_limits.dart says is allowed. The form would let the user type '
          'it and the save would then fail.',
    );
    expect(
      column.isAcceptableValue('x' * (limit + 1), meta).success,
      isFalse,
      reason:
          '${column.$name} accepted ${limit + 1} characters. Either the column '
          'has a larger limit than field_limits.dart claims, or -- the failure '
          'this test exists for -- it has no length constraint at all, which '
          'is what drift generates when withLength(max:) is given anything but '
          'an integer literal.',
    );
  }

  group('customers', () {
    test('every column limit matches CustomerLimits', () {
      expectLimit(db.customers.fullName, CustomerLimits.fullName);
      expectLimit(db.customers.mobile, CustomerLimits.mobile);
      expectLimit(db.customers.companyName, CustomerLimits.companyName);
      expectLimit(db.customers.address, CustomerLimits.address);
      expectLimit(db.customers.nationalId, CustomerLimits.nationalId);
      expectLimit(db.customers.economicId, CustomerLimits.economicId);
      expectLimit(db.customers.notes, CustomerLimits.notes);
      expectLimit(db.customers.searchName, CustomerLimits.searchName);
    });
  });

  group('products', () {
    test('every column limit matches ProductLimits', () {
      expectLimit(db.products.name, ProductLimits.name);
      expectLimit(db.products.unit, ProductLimits.unit);
      expectLimit(db.products.description, ProductLimits.description);
      expectLimit(db.products.searchName, ProductLimits.searchName);
    });
  });

  test('the amount field is as wide as the largest amount that can exist', () {
    // `AmountLimits.tomanDigits` is a literal because Dart cannot take a
    // string's length at compile time. This is what keeps it honest: widen the
    // ceiling and the constant has to follow, or the price field would start
    // refusing amounts the engine accepts.
    expect('${kMaxAmountRial ~/ 10}'.length, AmountLimits.tomanDigits);
  });

  test('the length check measures what the validator measures', () {
    // `AppTextField`'s validator uses `String.length`; drift's
    // `checkTextLength` does too. If drift ever moved to grapheme clusters the
    // two would diverge for exactly the values -- Persian text carrying
    // combining marks -- that the validator exists to catch.
    const VerificationMeta meta = VerificationMeta('probe');
    // ALEF followed by FATHATAN: two UTF-16 code units, one grapheme cluster.
    // Written as escapes because the second character is invisible in a source
    // file and a reviewer could not otherwise tell what this fixture is.
    const String twoUnitsOneCluster = 'اً';
    expect(twoUnitsOneCluster.length, 2);

    final GeneratedColumn<String> column = db.customers.nationalId;
    final String atLimit =
        twoUnitsOneCluster * (CustomerLimits.nationalId ~/ 2);
    expect(atLimit.length, CustomerLimits.nationalId);
    expect(column.isAcceptableValue(atLimit, meta).success, isTrue);
    expect(
      column.isAcceptableValue(atLimit + twoUnitsOneCluster, meta).success,
      isFalse,
      reason:
          'drift counts UTF-16 code units, so the validator must too -- see '
          'AppTextField. Five grapheme clusters are ten code units here, so a '
          'maxLength alone would still let two more through.',
    );
  });
}
