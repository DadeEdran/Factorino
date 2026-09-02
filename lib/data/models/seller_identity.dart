/// The business the invoice is issued **by**.
///
/// **Why this exists at all.** Until schema v5 the settings row held no
/// business identity whatsoever — no name, no نشانی, no کد اقتصادی, no
/// telephone — so the printed document carried a خریدار block and nothing
/// opposite it. A conventional Iranian فاکتور فروش names both parties, and a
/// page that names only one of them is not a document the user can hand to a
/// customer (D-076, D-077).
///
/// **Why it is a value object rather than four fields on [AppSettings].** Not
/// tidiness: `copyWith` on a nullable field cannot express *clear it*. With
/// `String? sellerName` on the settings model, `copyWith(sellerName: null)` is
/// indistinguishable from "leave it alone", so a user who empties the name in
/// the form would have the old one written straight back — silently, and
/// visible only on the next document they print. Replacing the whole object
/// makes clearing the ordinary case rather than a special one.
///
/// **Every field is nullable and stays nullable.** Every database that exists
/// today has none of them, and there is no honest value to invent for a
/// business the application has never been told about. What an empty identity
/// means for the document is [isEmpty]'s business and the renderer's; see
/// D-077.
class SellerIdentity {
  const SellerIdentity({this.name, this.economicId, this.address, this.phone});

  /// No identity at all — what every pre-v5 database carries after the
  /// migration, because the migration invents nothing.
  static const SellerIdentity none = SellerIdentity();

  /// The business name, as it should appear on the document.
  ///
  /// **The identifying field, and the one the others hang from.** A block
  /// headed «فروشنده» carrying a کد اقتصادی and no name is a fragment rather
  /// than an identification: it tells the reader nothing they can act on, and
  /// it looks like a document that failed to print. So the form requires this
  /// one as soon as any other is filled — reported, never clamped (D-027) —
  /// and [isPrintable] is what the document asks.
  final String? name;

  /// کد اقتصادی. Optional for the same reason it is optional on a customer:
  /// plenty of the businesses this application is for do not have one.
  final String? economicId;

  final String? address;

  /// A telephone number, kept as typed.
  ///
  /// Deliberately not normalized to the `09xxxxxxxxx` mobile shape §9 defines
  /// for a customer's mobile: a seller's published number is as often a
  /// landline with an area code, and rewriting what the user typed onto the
  /// document they hand a customer would be the application overruling them
  /// about their own letterhead.
  final String? phone;

  /// True when the user has told the application nothing about their business.
  ///
  /// The state every existing database is in, and the state the settings
  /// screen exists to get them out of.
  bool get isEmpty =>
      _blank(name) && _blank(economicId) && _blank(address) && _blank(phone);

  bool get isNotEmpty => !isEmpty;

  /// Whether the document can print a فروشنده block from this.
  ///
  /// **Not the same question as [isNotEmpty]**, and the difference is the
  /// point: an identity carrying an address and no name has something in it and
  /// still cannot head a block. The form prevents that combination from being
  /// saved; this is what the document checks anyway, because a value that
  /// reached the database before the rule existed — or through a restored
  /// backup, or a future sync — is not the renderer's to assume away.
  bool get isPrintable => !_blank(name);

  /// The four fields with blanks folded to null.
  ///
  /// A field the user cleared by selecting its text and deleting it arrives
  /// here as `''`, and a stored `''` would print as a labelled empty line —
  /// which on a document reads as data that failed to print rather than as
  /// data that was never given. Folding happens once, here, so no call site
  /// has to remember to.
  SellerIdentity normalized() => SellerIdentity(
    name: _orNull(name),
    economicId: _orNull(economicId),
    address: _orNull(address),
    phone: _orNull(phone),
  );

  static bool _blank(String? value) => value == null || value.trim().isEmpty;

  static String? _orNull(String? value) {
    if (_blank(value)) return null;
    return value!.trim();
  }

  @override
  bool operator ==(Object other) =>
      other is SellerIdentity &&
      other.name == name &&
      other.economicId == economicId &&
      other.address == address &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(name, economicId, address, phone);

  /// Deliberately says only whether an identity is set, never what it is: a
  /// business name and telephone number are the user's own identifiers and §7
  /// keeps them out of logs.
  @override
  String toString() => 'SellerIdentity(${isEmpty ? 'empty' : 'set'})';
}
