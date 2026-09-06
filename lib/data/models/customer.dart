/// A person or business invoices are issued to.
///
/// A **domain model**, not a Drift row. Nothing in
/// `data/models/` imports drift, which is what makes that rule checkable rather
/// than merely stated -- see `domain_boundary_test.dart`.
///
/// Holds third-party personal identifiers (national ID, economic ID, mobile).
/// None of them may ever reach a log or a user-facing error message (§7), which
/// is why this class has no `toString` override dumping its fields.
class Customer {
  const Customer({
    required this.id,
    required this.fullName,
    required this.createdAt,
    required this.updatedAt,
    this.mobile,
    this.companyName,
    this.address,
    this.nationalId,
    this.notes,
  });

  /// UUID v4, allocated by the database on insert (D-001).
  final String id;

  final String fullName;

  /// Normalized to `09xxxxxxxxx` before storage, by the repository, using the
  /// one normalizer in `core/formatting/` (§9).
  final String? mobile;

  final String? companyName;
  final String? address;

  /// کد ملی. Optional, and checksum-validated when present -- but a passing
  /// checksum confirms a **format**, never an identity (D-030).
  final String? nationalId;

  final String? notes;

  /// UTC (D-005). Displayed Jalali; never stored as a localized string.
  final DateTime createdAt;
  final DateTime updatedAt;

  /// What the UI shows when a name alone is ambiguous.
  String get displayName => companyName == null || companyName!.isEmpty
      ? fullName
      : '$fullName ($companyName)';

  @override
  bool operator ==(Object other) =>
      other is Customer && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);

  /// Deliberately identifier-free: this class is full of personal data, and a
  /// `toString` that dumped it would eventually be interpolated into a log line
  /// or an error message (§7).
  @override
  String toString() => 'Customer($id)';
}

/// The editable fields of a customer -- what a form produces.
///
/// Separate from [Customer] because a draft has no `id`, no `createdAt` and no
/// `updatedAt`: those belong to the database, and a create call that accepted
/// them would invite a caller to invent one.
class CustomerDraft {
  const CustomerDraft({
    required this.fullName,
    this.mobile,
    this.companyName,
    this.address,
    this.nationalId,
    this.notes,
  });

  final String fullName;
  final String? mobile;
  final String? companyName;
  final String? address;
  final String? nationalId;
  final String? notes;

  /// A draft pre-filled from an existing customer, for an edit form.
  factory CustomerDraft.from(Customer customer) => CustomerDraft(
    fullName: customer.fullName,
    mobile: customer.mobile,
    companyName: customer.companyName,
    address: customer.address,
    nationalId: customer.nationalId,
    notes: customer.notes,
  );
}
