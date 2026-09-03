/// The maximum length of every free-text field, named once (the project spec:
/// *"Enforce field-level limits (length, character class) on customer/product
/// free-text fields"*).
///
/// **Why this file exists.** The schema has carried `withLength` on every text
/// column since increment (a); the forms carried nothing. So an over-long name
/// was accepted by the form, sent to the repository, and rejected by drift with
/// an `InvalidDataException` — which `describeFailure` does not recognise and
/// therefore reports as the generic «خطایی رخ داد». The user was told something
/// went wrong, not which field or why, and the value they had typed was still
/// on screen looking perfectly reasonable (D-042).
///
/// **Why one place rather than two that agree.** A schema limit and a form
/// limit that disagree fail silently in the direction that matters: the form
/// permits 200, the column permits 120, and the defect appears only for the
/// users who type long names. Naming the number once removes the possibility
/// rather than fixing it twice.
///
/// **The one thing that could not be made structural, and what stands in for
/// it.** These constants are deliberately *not* referenced from the table
/// definitions' `withLength` calls, even though that would be the obvious way
/// to share them. `drift_dev` reads that argument with `readIntLiteral`, which
/// accepts an `IntegerLiteral` and returns `null` for anything else — so
/// `withLength(max: CustomerLimits.fullName)` generates a column with **no
/// length constraint at all**, silently, and the schema would end up weaker
/// than before the sharing was introduced. Verified in
/// `drift_dev-2.34.5/lib/src/analysis/resolver/dart/helper.dart:206`.
///
/// So the tables keep their literals, and
/// `test/data/database/field_limits_test.dart` closes the gap by asking each
/// generated column where it actually starts rejecting values and comparing
/// that to the constant here. That is a stronger check than the shared
/// reference would have been: it proves the constraint exists and where it
/// bites, rather than proving two source files contain the same token.
///
/// Lengths are in the same unit drift measures — `String.length`, UTF-16 code
/// units — because that is what `GeneratedColumn.checkTextLength` compares.
library;

/// Customer fields, matching `lib/data/database/tables/customers.dart`.
abstract final class CustomerLimits {
  static const int fullName = 120;

  /// Generous for an `09xxxxxxxxx`, because a foreign client's number is kept
  /// as typed rather than discarded (see `CustomerRepository`).
  static const int mobile = 20;

  static const int companyName = 160;
  static const int address = 500;

  /// کد ملی is exactly ten digits. The field is optional; when present it is
  /// checksum-validated, and a passing checksum confirms a **format**, never an
  /// identity (D-030).
  static const int nationalId = 10;

  static const int notes = 2000;

  /// The denormalized search column (D-025). Not a form field — it is written
  /// by the repository from [fullName] and [companyName] through `searchKey`,
  /// which folds ZWNJ and diacritics away and so never exceeds their sum.
  //
  // normalizer-exempt: this names the column's *length*, not a value written
  // into it. `single_normalizer_path_test.dart` requires any file mentioning
  // searchName to call searchKey, because a second place that computes the
  // stored value would silently diverge from the query term -- but a constant
  // describing how long the column is cannot diverge from anything. The
  // repositories remain the only writers, and they still go through searchKey.
  static const int searchName = 300;
}

/// Limits on a money field, which has no column length to match because money
/// is stored as an integer (D-002).
///
/// The ceiling is real all the same: `kMaxAmountRial` is `10^14`, the money
/// engine **rejects** rather than truncates past it, and a field with no limit
/// lets the user type twenty digits before being told the amount is too large.
/// Stopping the entry at the widest amount that can exist says the same thing
/// sooner and without an error message.
abstract final class AmountLimits {
  /// Digits in the largest enterable Toman amount — `kMaxAmountRial ~/ 10`,
  /// which is `10^13` and therefore fourteen digits.
  ///
  /// A literal rather than a computed constant because Dart cannot take a
  /// string length at compile time; `field_limits_test.dart` asserts it against
  /// `kMaxAmountRial` so the two cannot drift apart.
  static const int tomanDigits = 14;
}

/// Payment fields, matching `lib/data/database/tables/payments.dart`.
abstract final class PaymentLimits {
  /// The note against one payment — a cheque number, a transfer reference, a
  /// reason for a part payment.
  ///
  /// Deliberately shorter than [InvoiceLimits.notes]. An invoice's note is a
  /// clause on a document and can run to a paragraph; a payment's note is an
  /// identifier for a transaction, and a field that invites an essay against a
  /// single receipt is a field nobody will scan later.
  static const int note = 500;
}

/// Product and service fields, matching
/// `lib/data/database/tables/products.dart`.
abstract final class ProductLimits {
  static const int name = 160;

  /// Free text: the set of units a workshop uses is not something this app
  /// should presume to fix.
  static const int unit = 30;

  static const int description = 2000;

  /// See [CustomerLimits.searchName].
  static const int searchName = 200;
}

/// Invoice line fields, matching
/// `lib/data/database/tables/invoice_items.dart`.
///
/// These are limits on **snapshots**, not on references (D-004). The line
/// carries its own copy of the title and unit, so a line sourced from the
/// catalogue is bounded by these numbers rather than by [ProductLimits] — and
/// the two differ: a product name may be 160 characters, an invoice line title
/// 200. A free-text line is the reason for the difference; a line often says
/// more than a catalogue entry does, because it describes one job rather than
/// naming a thing.
///
/// The consequence worth stating: copying a product in can never overflow the
/// line, because every [ProductLimits] value is at or below its counterpart
/// here. `field_limits_test.dart` asserts that relationship rather than
/// leaving it to be noticed if it ever stops holding.
abstract final class InvoiceLimits {
  /// The line's own title. Longer than [ProductLimits.name] on purpose.
  static const int lineTitle = 200;

  /// Same as [ProductLimits.unit] — a unit copied from a product must fit, and
  /// a freehand unit is the same kind of word either way.
  static const int lineUnit = 30;

  /// The invoice's own notes, matching `invoices.notes`. As generous as a
  /// customer's, because payment terms and delivery conditions get written
  /// here and an invoice that truncates them is worse than one that scrolls.
  static const int notes = 2000;
}

/// Bounds for the settings form and the backup password.
///
/// **Two of these are not column limits, and that is stated rather than
/// implied.** `settings.invoice_number_prefix` is a real column with a real
/// `withLength(max: 12)`, so [prefix] is the usual kind. [password] is not: a
/// backup password is never stored anywhere — it is fed to a KDF and forgotten
/// (D-069) — so nothing in the schema constrains it. It lives here because
/// `field_limit_path_test.dart` requires every `AppTextField` to name a
/// `*Limits.` constant rather than a bare number, and a password field is not
/// worth an exception to a rule that exists to stop exactly that.
abstract final class SettingsFieldLimits {
  /// Matches `settings.invoice_number_prefix`, `withLength(min: 1, max: 12)`.
  static const int prefix = 12;

  /// A percentage. Two digits plus a decimal point and two more is generous
  /// for a VAT rate.
  static const int taxRateDigits = 6;

  /// Days. Four digits is well past [SettingsLimits.maxPaymentTermDays], which
  /// is where the real bound is enforced and explained.
  static const int paymentTermDigits = 4;

  /// **Not a column limit.** Long enough that a passphrase — several words,
  /// which is what §8's warning should encourage — is never cut short, and
  /// bounded only so the field has one.
  static const int password = 200;
}

/// The seller's own details, matching the four `seller_*` columns on
/// `settings` (schema v5, D-077).
///
/// **Deliberately the same numbers as the customer's counterparts.** The two
/// sides of an invoice carry the same kinds of value — a name, a نشانی, a
/// کد اقتصادی — and a seller whose address had to be shorter than their
/// customer's would be an arbitrary asymmetry the user would meet only when
/// their own address was refused.
abstract final class SellerLimits {
  /// The business name. Matched to [CustomerLimits.companyName] rather than to
  /// [CustomerLimits.fullName]: this is a letterhead line, and a sole trader
  /// who puts their own name here still fits inside the longer of the two.
  static const int name = 160;

  /// Same as [CustomerLimits.address].
  static const int address = 500;

  /// Same as [CustomerLimits.mobile], and generous for the same reason: a
  /// seller's published number is as often a landline with an area code, and
  /// it is kept as typed rather than normalized to the mobile shape.
  static const int phone = 20;
}
