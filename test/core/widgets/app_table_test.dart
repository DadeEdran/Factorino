import 'package:factorino/core/theme/app_dimensions.dart';
import 'package:factorino/core/widgets/app_table.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/screen_harness.dart';
import '../../support/text_fit.dart';

/// The table primitive's own guard (D-065).
///
/// **Why a flexible column has to declare a minimum.** `_cell` lays a flexible
/// column out with `Expanded`, which is a **tight** fit: the column is given
/// whatever the fixed columns leave, and if they leave nothing then nothing is
/// what it is given — laid out successfully, with no overflow and no error. The
/// invoice document's description spent a whole phase at 21.6 logical pixels
/// rendering Persian one glyph per row, and 935 tests could not see it because
/// there was nothing to see: no exception, no red band, no failing assertion.
///
/// So the constructor makes the minimum unskippable, and the header checks it
/// once per table. What a table *does* when the width is not there stays the
/// caller's decision — only the caller knows which of its columns are
/// recoverable somewhere else — but "nothing, silently" is no longer available.
void main() {
  List<TableColumnSpec> columns() => <TableColumnSpec>[
    TableColumnSpec.flexible(
      label: 'شرح',
      flex: 3,
      minWidth: AppLayout.tableMinTextWidth,
    ),
    TableColumnSpec.fixed(label: 'جمع', width: AppLayout.tablePriceWidth),
  ];

  Future<void> pumpAt(WidgetTester tester, double width) => pumpScreen(
    tester,
    Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTableHeader(columns: columns()),
            AppTableRow(
              columns: columns(),
              cells: const <Widget>[
                Text('طراحی و پیاده‌سازی وب‌سایت فروشگاهی'),
                Text('۱۰۰٬۰۰۰٬۰۰۰ تومان'),
              ],
            ),
          ],
        ),
      ),
    ),
    size: const Size(2000, 900),
  );

  test('a flexible column states the width below which it must not be laid out', () {
    // The arithmetic the header checks, stated once so a change to a spacing
    // token has to be acknowledged rather than silently reshaping every table:
    // two edges of row padding, plus each fixed column's width, plus each
    // flexible column's content floor and the gap it also has to pay for.
    expect(
      tableMinimumWidth(columns()),
      AppSpacing.lg * 2 +
          AppLayout.tablePriceWidth +
          AppLayout.tableMinTextWidth +
          AppSpacing.md,
    );
  });

  test('a fixed column is its own minimum', () {
    expect(
      tableMinimumWidth(<TableColumnSpec>[
        TableColumnSpec.fixed(label: 'جمع', width: AppLayout.tablePriceWidth),
      ]),
      AppSpacing.lg * 2 + AppLayout.tablePriceWidth,
    );
  });

  test('room reserved for row actions counts against the width', () {
    expect(
      tableMinimumWidth(columns(), trailingWidth: 144) -
          tableMinimumWidth(columns()),
      144,
    );
  });

  testWidgets('given the width, it lays out and nothing is crushed', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, tableMinimumWidth(columns()) + 1);
    expectNoCrushedText(tester, where: 'a table at exactly its minimum');
  });

  testWidgets('one pixel short, it refuses loudly instead of crushing', (
    WidgetTester tester,
  ) async {
    // **The whole point of the guard**, and the reason it is an assertion
    // rather than a fallback: without it this width produces a description
    // column of about two pixels — a table that looks broken to a user and
    // perfectly healthy to every automated check the project had.
    //
    // Errors are captured through `FlutterError.onError` rather than through
    // `takeException`, which collapses more than one into a summary object that
    // says only "multiple exceptions were detected". There *are* two here: the
    // guard, and then an overflow from Flutter's error widget standing in for
    // the header it refused to build — the second is the framework reporting
    // the first one's consequence, not a defect of its own.
    final List<String> raised = <String>[];
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) =>
        raised.add(details.exceptionAsString());
    addTearDown(() => FlutterError.onError = previous);

    await pumpAt(tester, tableMinimumWidth(columns()) - 1);

    expect(
      raised.join(' | '),
      // 32 of row padding + 244 for the money column + 232 of prose floor +
      // the 12 that column also has to pay for its own gap = 520.
      allOf(contains('its columns need 520.0'), contains('519.0')),
      reason: 'the guard must fire and say what it needed, not crush silently',
    );
  });
}
