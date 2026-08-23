/// An allocated invoice number, and the one place its format is expressed
/// (D-013).
///
/// Format: `{prefix}-{jalaliYear}-{sequence:0000}`, e.g. `INV-1405-0001`.
///
/// The parts are kept alongside the formatted string and are what the schema
/// stores, so allocation is `MAX(number_sequence) WHERE number_year = ?` rather
/// than parsing formatted strings back apart -- a parser that would have to
/// keep working after the user reconfigures the prefix.
class InvoiceNumber {
  const InvoiceNumber({
    required this.prefix,
    required this.year,
    required this.sequence,
  });

  final String prefix;

  /// The **Jalali** year the invoice was issued in, not the Gregorian one
  /// (D-006). A business's numbering restarts at Nowruz.
  final int year;

  final int sequence;

  /// Padded to four digits, which keeps a year's invoices sorting correctly as
  /// text and looks deliberate on a document.
  ///
  /// A business issuing more than 9,999 invoices in one year simply gets a
  /// five-digit sequence: the padding is a minimum, never a limit, so nothing
  /// wraps or collides.
  String get formatted =>
      '$prefix-$year-${sequence.toString().padLeft(4, '0')}';

  @override
  String toString() => formatted;
}
