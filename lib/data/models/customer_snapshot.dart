import 'customer.dart';

/// The customer as an invoice states them.
///
/// **A document does not change after it is issued** (D-052). Renaming a
/// customer — a correction, a marriage, a company changing its trading name —
/// must not rewrite the name on every invoice ever issued to them, including
/// ones already sent, already paid and already filed. This is the same rule
/// [Customer] pricing gets through `invoice_items` (D-004), applied to the
/// party rather than to the price, and it matters more here: the identity of
/// the party is what an auditor reconciles against.
///
/// **What is here, and what is not.** The fields an Iranian invoice prints and
/// an auditor checks: the name, the company, the two tax identifiers and the
/// address. The mobile number is deliberately absent — it is contact detail
/// rather than document content, and an invoice reprinted next year should
/// reach the customer on the number they have now, not the one they had then.
///
/// Every field is nullable, including [fullName], because this type also
/// describes an invoice issued **before** schema v3, where the snapshot columns
/// are null and there is nothing honest to put in them. Reading that case is
/// [Customer]'s job, through the fallback the read paths apply.
class CustomerSnapshot {
  const CustomerSnapshot({
    required this.fullName,
    this.companyName,
    this.nationalId,
    this.economicId,
    this.address,
  });

  /// The party as they were at issue.
  factory CustomerSnapshot.of(Customer customer) => CustomerSnapshot(
    fullName: customer.fullName,
    companyName: customer.companyName,
    nationalId: customer.nationalId,
    economicId: customer.economicId,
    address: customer.address,
  );

  final String fullName;

  final String? companyName;

  /// کد ملی and کد اقتصادی as they stood when the document was issued. These
  /// carry the legal weight on an Iranian invoice and are exactly the fields a
  /// correction to a customer record changes, which is why a snapshot of the
  /// name alone would have protected the least consequential field (D-052).
  final String? nationalId;
  final String? economicId;

  final String? address;

  /// What the document shows where a name alone is ambiguous. Mirrors
  /// [Customer.displayName] so a screen renders the same shape either way.
  String get displayName => companyName == null || companyName!.isEmpty
      ? fullName
      : '$fullName ($companyName)';

  @override
  bool operator ==(Object other) =>
      other is CustomerSnapshot &&
      other.fullName == fullName &&
      other.companyName == companyName &&
      other.nationalId == nationalId &&
      other.economicId == economicId &&
      other.address == address;

  @override
  int get hashCode =>
      Object.hash(fullName, companyName, nationalId, economicId, address);

  /// Deliberately identifier-free, for the reason [Customer.toString] is:
  /// every field on this class is something §7 forbids reaching a log line.
  @override
  String toString() => 'CustomerSnapshot()';
}
