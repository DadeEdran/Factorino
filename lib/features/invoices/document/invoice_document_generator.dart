import 'dart:typed_data';

import 'invoice_document_view.dart';

/// Renders an invoice to a document file.
///
/// **The interface `ARCHITECTURE.md` §B.13 said Phase 1 had defined and never
/// did.** The claim was withdrawn there rather than quietly satisfied by
/// writing this file to make it true (D-074); it exists now because there is a
/// renderer to put behind it.
///
/// **It takes a fully computed, already formatted view** (§12). The renderer
/// receives no `Invoice`, no `Money` and no `DateTime`, so it cannot recompute
/// a total, re-round a figure or re-convert a date — and therefore cannot
/// disagree with the screen about any of them. `core/money/` is the only
/// calculator in this application and a second one inside a page layout is the
/// worst possible place to find one.
abstract interface class InvoiceDocumentGenerator {
  /// The document bytes, ready to be written or shared.
  ///
  /// Throws [InvoiceDocumentFailure] rather than returning empty bytes. §12's
  /// rule is that this boundary **fails loudly rather than silently producing
  /// nothing**: a zero-byte file that a save dialog happily writes is a bug the
  /// user discovers days later, when they open the attachment they sent.
  Future<Uint8List> render(InvoiceDocumentView view);
}

/// A document that could not be produced.
///
/// Carries a code rather than a message: the Persian sentence the user sees is
/// the presentation layer's decision, and §7 forbids a raw exception string
/// reaching them.
class InvoiceDocumentFailure implements Exception {
  const InvoiceDocumentFailure(this.reason);

  final InvoiceDocumentFailureReason reason;

  @override
  String toString() => 'InvoiceDocumentFailure(${reason.name})';
}

enum InvoiceDocumentFailureReason {
  /// The page model could not be laid out or serialised.
  renderFailed,

  /// The view carried text the renderer refuses to draw.
  ///
  /// Unreachable through [DocumentTextBoundary], which is the point: if it
  /// ever fires, a call site has constructed a view by some other route and
  /// the type-level guarantee has a hole in it. Failing here is how that hole
  /// gets found, rather than by a customer holding a page with a Latin `à` in
  /// the middle of a Persian word (D-073).
  unsafeText,
}
