import 'package:factorino/core/pdf/rtl_table.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

/// [rtlTable] — the wrapper that exists because `pw.Table` cannot be told to
/// lay out right to left (known issue 24, D-079).
///
/// **What these tests are for, and what they are not.** They pin the
/// *contract*: everything goes in in reading order and comes out reversed,
/// cells and widths together, with the invariants that make the reversal
/// meaningful enforced rather than assumed. They do **not** establish that the
/// printed page reads correctly — only a rendered page does that, and the page
/// was read (`build/document_pages/`, D-079). A unit test that claimed to
/// settle the column order would be the same mistake D-076 made.
void main() {
  pw.Widget cell(String id) => pw.Text(id);

  String idOf(pw.Widget widget) =>
      ((widget as pw.Text).text as pw.TextSpan).text!;

  const Map<int, pw.TableColumnWidth> widths = <int, pw.TableColumnWidth>{
    0: pw.FixedColumnWidth(10),
    1: pw.FlexColumnWidth(),
    2: pw.FixedColumnWidth(30),
  };

  test('the column read first is laid out last, so it prints on the right', () {
    final pw.Table table = rtlTable(
      columnWidths: widths,
      rows: <pw.TableRow>[
        pw.TableRow(
          children: <pw.Widget>[cell('ردیف'), cell('شرح'), cell('جمع سطر')],
        ),
      ],
    );

    expect(
      table.children.single.children.map(idOf).toList(),
      <String>['جمع سطر', 'شرح', 'ردیف'],
      reason:
          'pw.Table places index 0 at the LEFT of the page, so the column an '
          'Iranian reader meets first must end up last in the list it is '
          'handed. The caller wrote them in reading order',
    );
  });

  test('a width travels with its own column, not with its index', () {
    final pw.Table table = rtlTable(
      columnWidths: widths,
      rows: <pw.TableRow>[
        pw.TableRow(children: <pw.Widget>[cell('a'), cell('b'), cell('c')]),
      ],
    );

    // The reading-order-first column (10 wide) must still be the one that is
    // 10 wide after the reversal — at its new index, 2. A reversal that moved
    // the cells and left the widths behind would mislabel every column, which
    // is worse than the misordering it set out to fix.
    expect(
      (table.columnWidths![2]! as pw.FixedColumnWidth).width,
      10,
      reason: 'the first reading-order column keeps its declared width',
    );
    expect(
      (table.columnWidths![0]! as pw.FixedColumnWidth).width,
      30,
      reason: 'and the last reading-order column keeps its own',
    );
    expect(table.columnWidths![1], isA<pw.FlexColumnWidth>());
  });

  test('row decoration and repeat survive the reversal', () {
    const pw.BoxDecoration fill = pw.BoxDecoration();
    final pw.Table table = rtlTable(
      columnWidths: widths,
      rows: <pw.TableRow>[
        pw.TableRow(
          repeat: true,
          decoration: fill,
          children: <pw.Widget>[cell('a'), cell('b'), cell('c')],
        ),
      ],
    );

    // Rebuilding a TableRow to reverse its children means every other field on
    // it has to be carried across by hand. A dropped `repeat` would silently
    // stop a header repeating across pages, and a dropped `decoration` would
    // lose the header fill — neither would fail anything else.
    expect(table.children.single.repeat, isTrue);
    expect(table.children.single.decoration, same(fill));
  });

  test('rows of unequal length are refused rather than reversed', () {
    expect(
      () => rtlTable(
        columnWidths: widths,
        rows: <pw.TableRow>[
          pw.TableRow(children: <pw.Widget>[cell('a'), cell('b'), cell('c')]),
          pw.TableRow(children: <pw.Widget>[cell('a'), cell('b')]),
        ],
      ),
      throwsA(isA<AssertionError>()),
      reason:
          'position i reverses to (n-1-i), so a short row would land its cells '
          'under the wrong headings — a mislabelled table, not a misordered one',
    );
  });

  test('a width map that does not cover every column is refused', () {
    expect(
      () => rtlTable(
        columnWidths: const <int, pw.TableColumnWidth>{
          0: pw.FixedColumnWidth(10),
        },
        rows: <pw.TableRow>[
          pw.TableRow(children: <pw.Widget>[cell('a'), cell('b'), cell('c')]),
        ],
      ),
      throwsA(isA<AssertionError>()),
      reason:
          'the declared columns would move while the undeclared ones stayed on '
          'defaultColumnWidth, putting a width under the wrong column',
    );
  });
}
