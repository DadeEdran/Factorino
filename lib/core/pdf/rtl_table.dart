import 'package:pdf/widgets.dart' as pw;

/// A [pw.Table] whose columns are laid out **right to left**, for a document
/// an Iranian reader reads right to left.
///
/// **Why this exists rather than a reversed argument list.** `pw.Table` places
/// column 0 at the left of the page and walks rightwards — `Table.layout`
/// starts at `x = 0.0` and adds each column width in turn — and it consults no
/// text direction anywhere: `textDirection` is not a parameter of `Table`,
/// `TableRow` or their layout, and `Directionality` above them changes nothing.
/// That is a property of the package (`pdf` 3.13.0), not a configuration
/// mistake, so a right-to-left table has to be built rather than asked for.
///
/// It was found by rendering a page and looking at it. The printed lines table
/// read, right to left, جمع سطر · مبلغ کل · قیمت واحد · تعداد · شرح · ردیف —
/// every figure correct and correctly labelled, and the whole table back to
/// front, with ردیف as the last column the reader meets instead of the first.
/// That was known issue 24, and D-076 had recorded the order as verified when
/// it had only been looked at.
///
/// **Why a wrapper and not a reversed literal at the call site.** Handing
/// `pw.Table` its columns backwards produces a correct page and leaves a trap:
/// the next person to add a column writes it where it reads, in a list that is
/// secretly reversed, and gets a page that is wrong in a way no test states.
/// Worse, `columnWidths` is keyed by index, so a hand-reversed cell list has to
/// be kept in sync with a hand-reversed width map — two reversals that must
/// agree, with nothing checking that they do, and a disagreement mislabels
/// every column rather than merely reordering them.
///
/// So the reversal lives here, once, and **callers pass everything in reading
/// order**: the first row entry and the `0` key are the column an Iranian
/// reader meets first, on the right of the page. Adding a column is writing it
/// where it belongs.
///
/// The invariants below are assertions rather than silent behaviour for the
/// same reason: a width map that does not cover its columns, or rows of
/// different lengths, cannot be reversed correctly, and guessing would produce
/// exactly the mislabelled table this is here to prevent.
pw.Table rtlTable({
  required List<pw.TableRow> rows,
  required Map<int, pw.TableColumnWidth> columnWidths,
  pw.TableBorder? border,
  pw.TableCellVerticalAlignment defaultVerticalAlignment =
      pw.TableCellVerticalAlignment.top,
}) {
  assert(rows.isNotEmpty, 'an rtlTable needs at least one row');

  final int columnCount = rows.first.children.length;

  assert(
    rows.every((pw.TableRow row) => row.children.length == columnCount),
    'every row must have $columnCount cells: the column at reading position i '
    'is reversed to position (n-1-i), so rows of different lengths would be '
    'reversed onto different columns and the table would be mislabelled '
    'rather than merely misordered',
  );

  assert(
    columnWidths.length == columnCount &&
        columnWidths.keys.every((int i) => i >= 0 && i < columnCount),
    'columnWidths must declare exactly the $columnCount columns, keyed 0..'
    '${columnCount - 1} in reading order. A partial map would leave some '
    'columns on defaultColumnWidth while the declared ones moved, which puts '
    'a width under the wrong column',
  );

  return pw.Table(
    border: border,
    defaultVerticalAlignment: defaultVerticalAlignment,
    columnWidths: <int, pw.TableColumnWidth>{
      for (final MapEntry<int, pw.TableColumnWidth> entry
          in columnWidths.entries)
        columnCount - 1 - entry.key: entry.value,
    },
    children: <pw.TableRow>[
      for (final pw.TableRow row in rows)
        pw.TableRow(
          repeat: row.repeat,
          decoration: row.decoration,
          verticalAlignment: row.verticalAlignment,
          children: row.children.reversed.toList(),
        ),
    ],
  );
}
