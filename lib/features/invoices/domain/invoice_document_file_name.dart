import '../../../core/formatting/jalali_display.dart';
import '../../../data/models/invoice.dart';

/// The name a saved invoice document is offered under (D-099).
///
/// `INV-1405-0001_1405-06-12_14-30-05.pdf`, and every part of that is load
/// bearing.
///
/// **The invoice number first**, because it is already the user's own
/// identifier for the document and it is what they would search a folder for.
/// Putting it first also groups every export of one invoice together in any
/// file manager that sorts by name. A draft has no number (D-048), so it falls
/// back to a fixed stem rather than inventing one.
///
/// **Then the Jalali date and the time, to the second**, which is what makes
/// the name unique. Before this, saving one invoice twice offered the same name
/// both times and what happened next was the platform's to decide: the Windows
/// dialog asks whether to overwrite — one careless Enter and the first file is
/// gone — while Android's SAF silently writes `INV-1405-0001(1).pdf`, leaving
/// two files whose names say nothing about which is which. Neither is
/// acceptable for a document a customer may already hold a copy of.
///
/// **Seconds rather than minutes**, because re-saving after correcting the
/// seller details happens inside one minute routinely.
///
/// **Latin digits and hyphens**, on the rule `formatJalaliDateForFileName`
/// already records for backups: a file name travels outside the application —
/// into a file manager, a cloud drive, an email attachment, a Windows dialog —
/// and Persian digits in one sort unpredictably, break some pickers, and are
/// awkward to type when the user is looking for the file months later. The
/// *date* is still Jalali, which is the part that matters: the user recognises
/// 1405-06-12 as their own calendar.
///
/// Underscores separate the three parts and hyphens live inside them, so the
/// boundaries stay readable at a glance in a list of forty files.
///
/// ## What this does and does not promise
///
/// It guarantees that **the application never proposes the same name twice**.
/// It cannot guarantee what lands on disk: the user may rename the file in the
/// save dialog, and a genuine collision is still the platform's to resolve.
/// That is the right division — the destination is the user's choice, and this
/// owns only what is suggested.
String invoiceDocumentFileName(Invoice invoice, DateTime at) {
  final String stem = invoice.number ?? kInvoiceDocumentDraftStem;
  return '${stem}_${formatJalaliDateForFileName(at)}'
      '_${formatJalaliTimeForFileName(at)}.pdf';
}

/// The stem a draft's export carries, having no number of its own (D-048).
// l10n-exempt: part of a file name, which is Latin by rule (D-099) so that it
// survives a file manager, a cloud drive and a Windows dialog.
const String kInvoiceDocumentDraftStem = 'draft';
