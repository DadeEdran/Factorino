import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/models/app_settings.dart';
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

  group('invoice lines', () {
    test('every column limit matches InvoiceLimits', () {
      expectLimit(db.invoiceItems.titleSnapshot, InvoiceLimits.lineTitle);
      expectLimit(db.invoiceItems.unitSnapshot, InvoiceLimits.lineUnit);
    });

    test('a product always fits in the line it is copied into', () {
      // D-004 copies a product's title and unit onto the line. If the line's
      // columns were ever the narrower pair, that copy would start failing at
      // the database for exactly the products with the longest names -- a
      // defect that appears only for some users and only sometimes, which is
      // the worst shape for one to have.
      expect(
        ProductLimits.name,
        lessThanOrEqualTo(InvoiceLimits.lineTitle),
        reason: 'a product name must fit in an invoice line title',
      );
      expect(
        ProductLimits.unit,
        lessThanOrEqualTo(InvoiceLimits.lineUnit),
        reason: 'a product unit must fit in an invoice line unit',
      );
    });
  });

  group('the customer snapshot on an invoice (D-052)', () {
    test('every snapshot column matches its source column exactly', () {
      // Not "at least as wide" but **equal**, and the direction that matters
      // is the narrow one: a snapshot column shorter than the customer column
      // it copies from would make a customer with a long address impossible to
      // issue an invoice to -- the write failing inside `issue()`, at the
      // moment the invoice is meant to become a document, for exactly the
      // users whose records are the fullest.
      expectLimit(db.invoices.customerNameSnapshot, CustomerLimits.fullName);
      expectLimit(
        db.invoices.customerCompanySnapshot,
        CustomerLimits.companyName,
      );
      expectLimit(
        db.invoices.customerNationalIdSnapshot,
        CustomerLimits.nationalId,
      );
      expectLimit(db.invoices.customerAddressSnapshot, CustomerLimits.address);
    });
  });

  test('the payment term column defaults to the constant that names it', () {
    // `withDefault(const Constant(30))` carries a literal for the same reason
    // `withLength(max:)` does -- `drift_dev` reads the source expression, and
    // what it makes of a named constant is not a thing to discover from a
    // shipped default. So the constant and the column are checked against each
    // other here instead.
    //
    // Read off the generated column's default expression rather than by
    // inserting a row, because the question is what the *schema* declares:
    // that is what a migrated database's existing settings row takes.
    expect(
      db.settings.paymentTermDays.defaultValue?.toString(),
      contains('$kDefaultPaymentTermDays'),
      reason:
          'settings.payment_term_days must default to kDefaultPaymentTermDays, '
          'because that default is what every pre-v3 settings row is given by '
          'the migration.',
    );
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
