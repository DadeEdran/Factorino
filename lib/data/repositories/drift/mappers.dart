import '../../../core/money/money.dart';
import '../../database/app_database.dart';
import '../../models/customer.dart';
import '../../models/customer_snapshot.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/payment.dart';
import '../../models/product.dart';

/// The single place a Drift row becomes a domain model.
///
/// the project spec: *"Repositories expose domain models, never Drift-generated
/// row classes. The Drift row type stops at the repository boundary; mapping
/// happens there."* This file is that boundary, and having exactly one of it
/// means the two conversions that matter -- epoch milliseconds to a UTC
/// `DateTime`, and a plain `int` to [Money] -- are written once rather than
/// wherever a row is read.
///
/// Both conversions are places a mistake would be quiet. A `DateTime` built
/// without `isUtc: true` reads as local time and shifts every Jalali date by
/// the device's offset; an `int` Rial handed around without [Money] is one
/// implicit conversion away from being treated as Toman.

/// Epoch milliseconds to a **UTC** `DateTime` (D-005).
///
/// `isUtc: true` is not optional. Without it the value is interpreted in the
/// device's timezone, and `core/date/` would then convert an already-shifted
/// instant a second time.
DateTime instantFromMillis(int millis) =>
    DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);

DateTime? instantFromMillisOrNull(int? millis) =>
    millis == null ? null : instantFromMillis(millis);

/// A UTC instant back to the epoch milliseconds the schema stores.
int millisFromInstant(DateTime instant) =>
    instant.toUtc().millisecondsSinceEpoch;

int? millisFromInstantOrNull(DateTime? instant) =>
    instant == null ? null : millisFromInstant(instant);

Customer customerFromRow(CustomerRow row) => Customer(
  id: row.id,
  fullName: row.fullName,
  mobile: row.mobile,
  companyName: row.companyName,
  address: row.address,
  nationalId: row.nationalId,
  notes: row.notes,
  createdAt: instantFromMillis(row.createdAt),
  updatedAt: instantFromMillis(row.updatedAt),
);

Product productFromRow(ProductRow row) => Product(
  id: row.id,
  name: row.name,
  type: row.type,
  price: Money.rial(row.priceRial),
  unit: row.unit,
  description: row.description,
  createdAt: instantFromMillis(row.createdAt),
  updatedAt: instantFromMillis(row.updatedAt),
);

/// The party snapshot on an invoice row, or null if it has none (D-052).
///
/// **[CustomerSnapshot.fullName] is what decides.** The five columns are
/// nullable together — written in one statement by `issue()` and never
/// individually — so the name being present is the same question as the
/// snapshot being present, and it is the one field a document cannot be
/// printed without. A draft has no snapshot; nor has any invoice issued before
/// schema v3, which the read path handles by falling back to the live customer
/// (`Invoice.party`).
CustomerSnapshot? customerSnapshotFromRow(InvoiceRow row) {
  final String? fullName = row.customerNameSnapshot;
  if (fullName == null) return null;

  return CustomerSnapshot(
    fullName: fullName,
    companyName: row.customerCompanySnapshot,
    nationalId: row.customerNationalIdSnapshot,
    address: row.customerAddressSnapshot,
  );
}

Invoice invoiceFromRow(InvoiceRow row) => Invoice(
  id: row.id,
  number: row.number,
  numberYear: row.numberYear,
  numberSequence: row.numberSequence,
  customerId: row.customerId,
  customerSnapshot: customerSnapshotFromRow(row),
  issueDate: instantFromMillis(row.issueDate),
  dueDate: instantFromMillisOrNull(row.dueDate),
  status: row.status,
  discount: Money.rial(row.discountRial),
  discountPercentBp: row.discountPercentBp,
  taxRateBp: row.taxRateBp,
  notes: row.notes,
  grossTotal: Money.rialOrNull(row.grossTotalRial),
  subtotal: Money.rial(row.subtotalRial),
  totalDiscount: Money.rial(row.totalDiscountRial),
  totalTax: Money.rial(row.totalTaxRial),
  roundingAdjustment: Money.rial(row.roundingAdjustmentRial),
  grandTotal: Money.rial(row.grandTotalRial),
  createdAt: instantFromMillis(row.createdAt),
  updatedAt: instantFromMillis(row.updatedAt),
);

InvoiceItem invoiceItemFromRow(InvoiceItemRow row) => InvoiceItem(
  id: row.id,
  invoiceId: row.invoiceId,
  position: row.position,
  productId: row.productId,
  title: row.titleSnapshot,
  unit: row.unitSnapshot,
  unitPrice: Money.rial(row.unitPriceRial),
  quantityMilli: row.quantityMilli,
  discount: Money.rial(row.discountRial),
  discountPercentBp: row.discountPercentBp,
  resolvedTaxRateBp: row.resolvedTaxRateBp,
  gross: Money.rialOrNull(row.lineGrossRial),
  allocatedInvoiceDiscount: Money.rialOrNull(row.allocatedInvoiceDiscountRial),
  lineNet: Money.rial(row.lineNetRial),
  lineTax: Money.rial(row.lineTaxRial),
  lineTotal: Money.rial(row.lineTotalRial),
);

Payment paymentFromRow(PaymentRow row) => Payment(
  id: row.id,
  invoiceId: row.invoiceId,
  amount: Money.rial(row.amountRial),
  paidAt: instantFromMillis(row.paidAt),
  method: row.method,
  note: row.note,
  createdAt: instantFromMillis(row.createdAt),
  updatedAt: instantFromMillis(row.updatedAt),
);
