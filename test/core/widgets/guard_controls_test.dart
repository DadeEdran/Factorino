import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/screen_harness.dart';

/// A negative control for the crushed-text detector — D-072's lens applied to
/// the rest of the suite.
///
/// **The rule this exists for.** *Verified to bite* is a claim with a shelf
/// life. `sheet_keyboard_test.dart` was verified against the broken payment
/// sheet, the sheet was then fixed **by construction** via `EditorSheet`, and
/// its assertions quietly became ones that could not fail — passing, looking
/// exactly like coverage, while the thing they watched moved out from under
/// them.
///
/// The audit that followed found the rest of the suite in better shape than
/// that. Every source-scanning guard already carries a matcher self-test ("the
/// scan would catch a real violation") plus an existence test; `app_table_test`
/// asserts one pixel either side of its threshold; and the contrast probe was
/// **proved accurate** — handed a 2.68:1 label it reports 2.68:1 and fails —
/// and now carries its own standing control in `component_contrast_test.dart`.
///
/// `expectNoCrushedText` was the one measurement guard with nothing proving it
/// could fire. Every device suite calls it, and its precondition
/// (`softWrap && !truncatesOnPurpose`) is the kind of thing a future change to
/// how this application sets `maxLines` could quietly make never-true — at
/// which point it would report clean everywhere and say nothing.
void main() {
  group('the crushed-text detector', () {
    testWidgets('the comparison it makes can still fire', (
      WidgetTester tester,
    ) async {
      // 24 logical pixels for a Persian phrase that needs far more — the shape
      // D-065 found in the invoice document table, which was crushed to 21.6.
      await pumpScreen(
        tester,
        const Scaffold(
          body: Center(
            child: SizedBox(
              width: 24,
              child: Text('طراحی و پیاده‌سازی وب‌سایت فروشگاهی'),
            ),
          ),
        ),
      );

      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.byType(Text),
      );

      // The detector's own three conditions, asserted individually, because
      // any one of them going permanently false silences it.
      expect(
        paragraph.softWrap,
        isTrue,
        reason: 'the detector only looks at wrapping text',
      );
      expect(
        paragraph.overflow == TextOverflow.clip && paragraph.maxLines != 1,
        isTrue,
        reason:
            'the detector skips deliberate truncation; if ordinary Text now '
            'counts as deliberate, it examines nothing',
      );
      expect(
        paragraph.size.width + 1,
        lessThan(paragraph.getMinIntrinsicWidth(double.infinity)),
        reason:
            'a 24-pixel column no longer measures as narrower than its own '
            'longest word, so the comparison every device suite relies on can '
            'never fire (D-072)',
      );
    });

    testWidgets('and does not fire on text that fits', (
      WidgetTester tester,
    ) async {
      // The other direction. A guard that fired on everything would be deleted
      // by the next person who hit it, which is its own way of going quiet.
      await pumpScreen(
        tester,
        const Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: Text('طراحی و پیاده‌سازی وب‌سایت فروشگاهی'),
            ),
          ),
        ),
      );

      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.byType(Text),
      );
      expect(
        paragraph.size.width + 1,
        greaterThanOrEqualTo(paragraph.getMinIntrinsicWidth(double.infinity)),
      );
    });
  });
}
