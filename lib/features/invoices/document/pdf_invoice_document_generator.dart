import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/pdf/document_text.dart';
import '../../../core/pdf/document_typeface.dart';
import 'invoice_document_generator.dart';
import 'invoice_document_view.dart';

/// The one invoice template (D-068: no template choice, no logo, no
/// customisation).
///
/// **Every value it draws is already decided.** It reads only
/// [InvoiceDocumentView], which holds [DocumentText] and nothing else — no
/// `Money`, no `DateTime`, no `int`. There is no arithmetic in this file and no
/// formatting decision; what it owns is where things sit on the page.
///
/// **Every string goes through [SafeText].** A `pw.Text` built directly from a
/// raw string would compile and would print a Latin `à` in the middle of every
/// Persian word containing a half-space (D-073). `_text` is the only way text
/// enters this layout, and it takes [DocumentText], which only
/// [DocumentTextBoundary] can produce.
class PdfInvoiceDocumentGenerator implements InvoiceDocumentGenerator {
  const PdfInvoiceDocumentGenerator(this.typeface);

  final DocumentTypeface typeface;

  @override
  Future<Uint8List> render(InvoiceDocumentView view) async {
    try {
      final pw.Document document = pw.Document(
        title: view.title.value,
        // The producer string is the only place this application's name
        // reaches a file a third party opens. Deliberately no version: it
        // would tell a reader which build produced a document, which is
        // information about the sender's device rather than about the sale.
        producer: 'Factorino',
      );

      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(
            base: typeface.regular,
            bold: typeface.bold,
          ),
          margin: const pw.EdgeInsets.all(_Doc.pageMargin),
          header: (pw.Context context) => _header(view, context),
          footer: (pw.Context context) => _footer(view, context),
          build: (pw.Context context) => <pw.Widget>[
            if (view.draftBanner != null) _draftBand(view.draftBanner!),
            _meta(view),
            pw.SizedBox(height: _Doc.blockGap),
            _parties(view),
            pw.SizedBox(height: _Doc.blockGap),
            _lines(view),
            pw.SizedBox(height: _Doc.blockGap),
            _totals(view),
            if (view.notes != null) ...<pw.Widget>[
              pw.SizedBox(height: _Doc.blockGap),
              _notes(view.notes!),
            ],
          ],
        ),
      );

      return await document.save();
    } on InvoiceDocumentFailure {
      rethrow;
    } catch (_) {
      // §7: no raw exception reaches the user, and nothing about the invoice
      // is logged on the way out. The reason code is all the presentation
      // layer needs to choose its Persian sentence.
      throw const InvoiceDocumentFailure(
        InvoiceDocumentFailureReason.renderFailed,
      );
    }
  }

  // ---------------------------------------------------------------- sections

  /// The title, and the invoice number opposite it.
  ///
  /// Repeated on every page by `MultiPage`, because a second sheet that does
  /// not say which invoice it belongs to is a loose page in a filing cabinet.
  pw.Widget _header(InvoiceDocumentView view, pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: _Doc.gap),
      margin: const pw.EdgeInsets.only(bottom: _Doc.gap),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _Doc.rule, width: _Doc.ruleWidth),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: <pw.Widget>[
          _text(view.title, _Doc.title),
          pw.Spacer(),
          _field(view.number, _Doc.body),
        ],
      ),
    );
  }

  pw.Widget _footer(InvoiceDocumentView view, pw.Context context) {
    // The page counter is drawn from `context`, which is the renderer's own
    // state rather than invoice data, so it is the one number on the page the
    // view model does not carry. Latin digits deliberately: it is not part of
    // the document's content and a Persian «۲ از ۳» invites being read as one.
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.only(top: _Doc.gap),
      child: pw.Text(
        '${context.pageNumber} / ${context.pagesCount}',
        style: pw.TextStyle(
          font: typeface.regular,
          fontSize: _Doc.caption,
          color: _Doc.muted,
        ),
      ),
    );
  }

  /// The draft marking: a filled band, not a line of prose.
  ///
  /// The requirement is that somebody **holding** the page knows it is not
  /// final without reading it closely (owner, D-075). A sentence in the body
  /// text does not do that; reversed-out type in a solid band does, at arm's
  /// length and after a photocopy.
  pw.Widget _draftBand(DocumentText banner) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: _Doc.blockGap),
      padding: const pw.EdgeInsets.symmetric(
        horizontal: _Doc.gap,
        vertical: _Doc.gap,
      ),
      color: _Doc.bandFill,
      child: _text(banner, _Doc.band, bold: true, color: _Doc.bandInk),
    );
  }

  pw.Widget _meta(InvoiceDocumentView view) {
    return pw.Row(
      children: <pw.Widget>[
        _field(view.issueDate, _Doc.body),
        if (view.dueDate != null) ...<pw.Widget>[
          pw.SizedBox(width: _Doc.blockGap),
          _field(view.dueDate!, _Doc.body),
        ],
      ],
    );
  }

  /// The two parties, side by side (D-077).
  ///
  /// **Side by side rather than stacked, and it was measured.** The content
  /// width is 531 pt, so each block gets [_Doc.partyBlockWidth] -- comfortably
  /// wider than the longest word either block can hold, which is what D-065
  /// says to check rather than assume. Stacking them would have cost the height
  /// of a whole block above the lines table, on a page whose whole job is to
  /// show the lines; a row costs nothing, and it is also how an Iranian invoice
  /// is conventionally set.
  ///
  /// **The seller is declared LAST, so that it lands on the right**, which is
  /// the side an Iranian reader looks at first and where the issuer belongs.
  ///
  /// That is the opposite of what it looks like, and it was measured rather
  /// than reasoned: **`pw.Table` lays column 0 out at the left even under
  /// `textDirection: rtl`.** Read off the rendered page — the first attempt
  /// declared the seller first and printed it on the left, which looks
  /// entirely deliberate and is wrong. See the note on
  /// [_Doc.partyColumnWidths].
  ///
  /// **When there is no seller the buyer takes the full width**, rather than
  /// half a page with a gap where the issuer should be. The layout changes
  /// shape rather than leaving a hole -- D-065's rule, applied to a block
  /// instead of to a column.
  pw.Widget _parties(InvoiceDocumentView view) {
    final InvoiceDocumentParty? seller = view.seller;
    if (seller == null) return _party(view.party);

    // **A `Table`, not a `Row`, and both halves of that are measured.**
    //
    // A `Row` of two `Expanded`s with `crossAxisAlignment: stretch` gives the
    // row an unbounded height and `MultiPage` refuses the page outright:
    // *"Widget won't fit into the page as its height (Infinity) exceed a page
    // height"*. Found by rendering, not by reading, which is this phase's
    // method. Dropping `stretch` compiles and renders and looks wrong: two
    // bordered boxes of different heights side by side read as one of them
    // having failed to finish. `package:pdf` has no `IntrinsicHeight` to
    // bound it with.
    //
    // `TableCellVerticalAlignment.full` is what makes both cells take the
    // taller one's height, and the widths are **declared** rather than flexed
    // — D-065's rule, and the same shape as the lines table below.
    return pw.Table(
      columnWidths: _Doc.partyColumnWidths,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      children: <pw.TableRow>[
        pw.TableRow(
          children: <pw.Widget>[
            // Buyer, gap, seller -- left to right on the page, which puts the
            // seller on the right for the reader. See above.
            _party(view.party),
            pw.SizedBox(width: _Doc.gap),
            _party(seller),
          ],
        ),
      ],
    );
  }

  pw.Widget _party(InvoiceDocumentParty party) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(_Doc.gap),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _Doc.rule, width: _Doc.hairline),
        borderRadius: pw.BorderRadius.circular(_Doc.radius),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          _text(party.heading, _Doc.caption, color: _Doc.muted),
          pw.SizedBox(height: _Doc.tight),
          _text(party.name, _Doc.subtitle, bold: true),
          for (final DocumentField field in party.fields) ...<pw.Widget>[
            pw.SizedBox(height: _Doc.tight),
            // `fill`, so a long نشانی wraps inside the box instead of running
            // off its edge and being clipped mid-word. See `_field`.
            _field(field, _Doc.body, fill: true),
          ],
          if (party.sourceNote != null) ...<pw.Widget>[
            pw.SizedBox(height: _Doc.gap),
            _text(party.sourceNote!, _Doc.caption, color: _Doc.muted),
          ],
        ],
      ),
    );
  }

  /// The lines table.
  ///
  /// Column widths are **declared**, not flexed, for every money column — the
  /// D-065 rule, which this application learned by shipping a description
  /// column 21.6 points wide. The description is the one flexible column and
  /// it takes what the fixed ones leave.
  pw.Widget _lines(InvoiceDocumentView view) {
    return pw.Table(
      border: pw.TableBorder.all(color: _Doc.rule, width: _Doc.hairline),
      columnWidths: _Doc.columnWidths,
      children: <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _Doc.headerFill),
          children: <pw.Widget>[
            for (final DocumentText column in view.lineColumns)
              _cell(_text(column, _Doc.caption, bold: true)),
          ],
        ),
        for (final InvoiceDocumentLine line in view.lines)
          pw.TableRow(
            children: <pw.Widget>[
              _cell(_text(line.rowNumber, _Doc.small)),
              _cell(_text(line.description, _Doc.small)),
              _cell(_text(line.quantity, _Doc.small)),
              _cell(_amount(line.unitPrice, _Doc.small)),
              _cell(_amount(line.gross, _Doc.small)),
              _cell(_amount(line.total, _Doc.small)),
            ],
          ),
      ],
    );
  }

  /// The summary, and then the one figure the document exists to state.
  pw.Widget _totals(InvoiceDocumentView view) {
    return pw.Row(
      children: <pw.Widget>[
        pw.Spacer(),
        pw.SizedBox(
          width: _Doc.totalsWidth,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              for (final DocumentAmountRow row in view.totals) ...<pw.Widget>[
                _totalRow(row, _Doc.body),
                pw.SizedBox(height: _Doc.tight),
              ],
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(_Doc.tight),
                decoration: const pw.BoxDecoration(color: _Doc.headerFill),
                child: _totalRow(view.grandTotal, _Doc.subtitle, bold: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _notes(DocumentText notes) => _text(notes, _Doc.small);

  // ----------------------------------------------------------------- pieces

  /// A label and its value, as **two widgets** — D-070 contract rule 2.
  ///
  /// Never `'$label: $value'`. Probe 3 measured that shape reversing the groups
  /// of a phone number, because the neutral characters inside the value resolve
  /// against the Persian label sharing their run. Two widgets have no shared
  /// run to resolve against, which is why the rule makes finding 2 disappear
  /// rather than needing a remedy for it.
  ///
  /// **[fill] decides whether the value may wrap, and it is not cosmetic.**
  /// Without it the row is `mainAxisSize: min` with no flexible child, so the
  /// value takes its intrinsic width and **overflows its container silently**:
  /// a نشانی in a party block ran off the edge of the box and was clipped
  /// mid-word — «...پلاک ۴۵۶، واح» — with no overflow, no error and no failing
  /// test. Read off the rendered page, which is the only thing that showed it,
  /// and it is the same class as D-065's 21.6-point column.
  ///
  /// The default stays `false`, because the two callers that want the old
  /// behaviour genuinely want it: the invoice number in the page header and
  /// the dates in the meta row sit beside a `Spacer` and must take their
  /// natural width. A field that is the whole width of its block wants the
  /// opposite.
  pw.Widget _field(DocumentField field, double size, {bool fill = false}) {
    final pw.Widget value = _text(field.value, size, bold: true);

    return pw.Row(
      mainAxisSize: fill ? pw.MainAxisSize.max : pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _text(field.label, size, color: _Doc.muted),
        pw.SizedBox(width: _Doc.tight),
        if (fill) pw.Expanded(child: value) else value,
      ],
    );
  }

  /// Digits and unit, also two widgets, for the same reason.
  pw.Widget _amount(DocumentAmount amount, double size, {bool bold = false}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: <pw.Widget>[
        _text(amount.digits, size, bold: bold),
        if (amount.unit.isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(width: _Doc.hair),
          _text(amount.unit, size * _Doc.unitScale, color: _Doc.muted),
        ],
      ],
    );
  }

  pw.Widget _totalRow(DocumentAmountRow row, double size, {bool bold = false}) {
    return pw.Row(
      children: <pw.Widget>[
        _text(row.label, size, color: bold ? null : _Doc.muted, bold: bold),
        pw.Spacer(),
        _amount(row.amount, size, bold: bold),
      ],
    );
  }

  pw.Widget _cell(pw.Widget child) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(
      horizontal: _Doc.tight,
      vertical: _Doc.hair,
    ),
    child: child,
  );

  /// The only door text enters the layout by.
  pw.Widget _text(
    DocumentText text,
    double size, {
    bool bold = false,
    PdfColor? color,
  }) {
    return typeface.safe.paragraph(
      text,
      style: pw.TextStyle(
        font: bold ? typeface.bold : typeface.regular,
        fontSize: size,
        color: color,
        lineSpacing: _Doc.lineSpacing,
      ),
    );
  }
}

/// The page's design tokens.
///
/// Named for the same reason `AppSpacing` and `AppTypography` are (§10): a
/// layout with numbers scattered through it cannot be adjusted coherently, and
/// every size on a printed page is a decision about how it reads at arm's
/// length.
abstract final class _Doc {
  static const double pageMargin = 32;

  static const double title = 20;
  static const double band = 16;
  static const double subtitle = 12;
  static const double body = 10;
  static const double small = 8.5;
  static const double caption = 8;

  /// The unit is set smaller than its figure, as `AmountText` does on screen:
  /// the amount is the thing being read and «تومان» is what it is measured in.
  static const double unitScale = 0.85;

  static const double lineSpacing = 1.6;
  static const double hair = 2;
  static const double tight = 4;
  static const double gap = 8;
  static const double blockGap = 14;
  static const double radius = 3;

  /// The rule under the page header, and the hairline every box and table cell
  /// is drawn with. Tokenised rather than written at the call site for §10's
  /// reason and because `theme_tokens_only_test.dart` catches it: a `width: 1`
  /// here was the one literal that got past review, in the header, on the rule
  /// the whole page hangs from.
  static const double ruleWidth = 1;
  static const double hairline = 0.5;

  static const PdfColor rule = PdfColor.fromInt(0xFFBFBFBF);
  static const PdfColor muted = PdfColor.fromInt(0xFF666666);
  static const PdfColor headerFill = PdfColor.fromInt(0xFFEFEFEF);
  static const PdfColor bandFill = PdfColor.fromInt(0xFF1F2933);
  static const PdfColor bandInk = PdfColor.fromInt(0xFFFFFFFF);

  /// A4 minus both margins.
  static const double contentWidth = 595.28 - pageMargin * 2;

  static const double totalsWidth = 240;

  /// What each party block gets when both are printed: half the content width
  /// less half the gap between them.
  ///
  /// Declared rather than left to `Expanded` to work out, for D-065's reason:
  /// a block laid out at a width nothing asserts is a block that can be
  /// crushed silently. `invoice_document_view_test.dart` asserts this stays
  /// wide enough for the longest word a party block can hold.
  static const double partyBlockWidth = (contentWidth - gap) / 2;

  /// Buyer, gap, seller -- **in left-to-right page order**.
  ///
  /// `pw.Table` places column 0 at the left of the page regardless of
  /// `textDirection`, which was established by rendering the page and looking
  /// at it, not from the API. So the column a reader meets first is the last
  /// one declared. Fixed widths rather than flexed, per D-065.
  static const Map<int, pw.TableColumnWidth> partyColumnWidths =
      <int, pw.TableColumnWidth>{
        0: pw.FixedColumnWidth(partyBlockWidth),
        1: pw.FixedColumnWidth(gap),
        2: pw.FixedColumnWidth(partyBlockWidth),
      };

  /// Five declared money and count columns; the description takes the rest.
  static const double rowWidth = 26;
  static const double quantityWidth = 62;
  static const double moneyWidth = 88;

  static const Map<int, pw.TableColumnWidth> columnWidths =
      <int, pw.TableColumnWidth>{
        0: pw.FixedColumnWidth(rowWidth),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(quantityWidth),
        3: pw.FixedColumnWidth(moneyWidth),
        4: pw.FixedColumnWidth(moneyWidth),
        5: pw.FixedColumnWidth(moneyWidth),
      };

  /// What the fixed columns take, so a test can assert the description column
  /// is left a workable width rather than the 21.6 points D-065 found.
  static const double fixedColumnsWidth =
      rowWidth + quantityWidth + moneyWidth * 3;

  static const double descriptionWidth = contentWidth - fixedColumnsWidth;
}

/// The declared table geometry, exposed for the layout guard.
abstract final class InvoiceDocumentLayout {
  static const double contentWidth = _Doc.contentWidth;
  static const double fixedColumnsWidth = _Doc.fixedColumnsWidth;
  static const double descriptionWidth = _Doc.descriptionWidth;
  static const double moneyColumnWidth = _Doc.moneyWidth;

  /// The width of one party block when both are printed (D-077).
  static const double partyBlockWidth = _Doc.partyBlockWidth;

  /// The type size a party block sets its field values in, which is what the
  /// width above has to be checked against.
  static const double partyFontSize = _Doc.body;
  static const double lineFontSize = _Doc.small;
  static const double unitScale = _Doc.unitScale;
}
