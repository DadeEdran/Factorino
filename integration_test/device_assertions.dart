import 'dart:io';

import 'package:factorino/core/theme/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two assertions a device pass needs that a widget test cannot make, and
/// that a device pass written on a desktop will not make either.
///
/// Both come out of the Phase 5 phone-tier pass (D-062), and both are the same
/// lesson: **the check must reproduce the conditions the user is actually in.**
/// A pass that reads the page as a desktop lays it out, or that never raises the
/// keyboard, is measuring a screen the user never sees.

/// Brings [finder] into the tree, scrolling the page if it is not there yet.
///
/// The three tiers are genuinely different layouts, not one
/// layout at three widths: on the narrow tiers the invoice detail page runs
/// summary → lines → payments → party, while the desktop tier puts the party and
/// the summary in a side panel. A position that holds on one tier is a
/// coincidence on the others.
///
/// **Not `ensureVisible`, and the difference is the point.** `ensureVisible`
/// scrolls to an element that already exists and throws when there is none; a
/// `ListView` child past its cache extent is not laid out and not in the tree at
/// all, so the finder reports absence rather than invisibility.
///
/// Rewinds each list it searched, so one assertion does not silently decide
/// where the next one starts from.
Future<void> reach(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;

  for (final Element element in find.byType(ListView).evaluate().toList()) {
    final Finder list = find.byWidget(element.widget);
    if (list.evaluate().isEmpty) continue;

    bool found = false;
    for (int step = 0; step < 24 && !found; step++) {
      await tester.drag(list, const Offset(0, -240));
      await tester.pumpAndSettle();
      found = finder.evaluate().isNotEmpty;
    }
    if (found) return;

    for (int step = 0; step < 30; step++) {
      await tester.drag(list, const Offset(0, 240));
      await tester.pumpAndSettle();
    }
  }
}

/// Raises the real soft keyboard by tapping [field], and waits for it.
///
/// `enterText` injects text straight into the engine and raises nothing, so a
/// device test that only ever calls it is testing a phone that has no keyboard.
/// A real tap on a real text field is what a user does.
///
/// The wait is a poll rather than a fixed delay: how long the keyboard takes to
/// animate in is the device's business, and a sleep long enough for the slowest
/// phone is wasted on every other one.
Future<double> raiseKeyboard(WidgetTester tester, Finder field) async {
  await tester.tap(field);
  await tester.pumpAndSettle();

  for (int step = 0; step < 40; step++) {
    final double inset = MediaQuery.viewInsetsOf(tester.element(field)).bottom;
    if (inset > 0) return inset;
    await tester.pump(const Duration(milliseconds: 100));
  }
  return MediaQuery.viewInsetsOf(tester.element(field)).bottom;
}

/// Asserts that [action] sits inside the region the soft keyboard leaves.
///
/// **Known issue 21, made unrepeatable.** The payment sheet shipped in Phase 5
/// (c) with its «ذخیره» inside its own scroll view; on the Redmi the keyboard
/// took 254.9 of 803.6 logical pixels and left the primary action about 70
/// pixels below the fold. Every widget test passed — the test harness installs a
/// `MediaQueryData` with no insets — and the Windows pass passed, because a
/// desktop has no keyboard.
///
/// On Android the keyboard is **required to be up**: an assertion made against
/// an inset of zero is vacuous, and a vacuous check that reports success is
/// worse than no check. On a desktop target there is no keyboard to raise, and
/// the assertion degrades to "the action is on screen" — which is why D-062
/// requires the phone run rather than accepting the desktop one.
void expectActionAboveKeyboard(
  WidgetTester tester,
  Finder action, {
  required String sheet,
}) {
  expect(action, findsOneWidget, reason: '$sheet must offer its action');

  final BuildContext context = tester.element(action);
  final double inset = MediaQuery.viewInsetsOf(context).bottom;
  final double height = MediaQuery.sizeOf(context).height;
  final Rect rect = tester.getRect(action);

  debugPrint(
    '$sheet: keyboard ${inset.toStringAsFixed(1)} of '
    '${height.toStringAsFixed(1)}, action bottom '
    '${rect.bottom.toStringAsFixed(1)}, limit '
    '${(height - inset).toStringAsFixed(1)}',
  );

  if (Platform.isAndroid) {
    expect(
      inset,
      greaterThan(0),
      reason:
          'the check must reproduce the conditions the user is in: a sheet '
          'with a text field, asserted without a keyboard, asserts nothing',
    );
  }

  expect(
    rect.bottom,
    lessThanOrEqualTo(height - inset),
    reason:
        '$sheet must keep its primary action inside the space the keyboard '
        'leaves. A user who types a value and cannot see the button has to '
        'discover it by scrolling (known issue 21, D-062)',
  );

  // **The floor, and where the number lives.** Every sheet measured on the
  // phone reports the same slack -- the payment sheet, the line editor, the
  // backup password sheet and the seller sheet all clear the keyboard by
  // exactly [AppSpacing.lg]. That is not four coincidences and it is not
  // headroom: `EditorSheet` pads below its action by that constant, inside a
  // `SafeArea`, so the distance is a property of the primitive.
  //
  // **This corrects D-072**, which read those 16 pixels as margin to watch if
  // the §8 warning copy grew. Copy growth cannot touch them -- the primitive
  // caps the field area and scrolls it while the action stays pinned. Asserting
  // the floor against `AppSpacing.lg` puts the number where it governs every
  // sheet at once, so the next tight sheet does not rediscover it.
  //
  // A floor rather than an equality: a phone with gesture navigation adds its
  // own bottom safe area, and more clearance is never the defect.
  expect(
    height - inset - rect.bottom,
    greaterThanOrEqualTo(AppSpacing.lg),
    reason:
        '$sheet clears the keyboard by '
        '${(height - inset - rect.bottom).toStringAsFixed(1)}, under the '
        '${AppSpacing.lg.toStringAsFixed(1)} EditorSheet pads below its '
        'action. Either the sheet is not built on the primitive or the '
        'primitive changed; both are decisions, not accidents',
  );
}

/// Fails if any text on screen was laid out **narrower than its own longest
/// word**, which is text broken inside a word — one Persian glyph per row.
///
/// **This is the check the reported defect walked past.** The invoice document
/// table's fixed money columns took everything, the flexible description was
/// handed what was left, and `Expanded` is a *tight* fit, so it was laid out
/// successfully at 21.6 logical pixels. No overflow, no error, zero layout
/// errors reported by this very suite — and a column of vertical text on the
/// screen the user was looking at (D-065).
///
/// Duplicated from `test/support/text_fit.dart` rather than imported, for the
/// reason the amount ladder is duplicated here too: `integration_test/` cannot
/// see `test/`. If the two ever disagree, this comment is the reason to fix it
/// rather than to shrug.
void expectNoCrushedText(WidgetTester tester, {required String where}) {
  final List<String> crushed = <String>[];

  void visit(RenderObject node) {
    if (node is RenderParagraph) {
      final String text = node.text.toPlainText().trim();
      // Ellipsis and fade are deliberate truncation; `maxLines: 1` with clip is
      // a single-line label whose author accepted the cut.
      final bool truncatesOnPurpose =
          node.overflow != TextOverflow.clip || node.maxLines == 1;

      if (text.isNotEmpty && node.softWrap && !truncatesOnPurpose) {
        final double needed = node.getMinIntrinsicWidth(double.infinity);
        if (node.size.width + 1 < needed) {
          crushed.add(
            '"${text.length > 40 ? '${text.substring(0, 40)}...' : text}" at '
            '${node.size.width.toStringAsFixed(1)} px, needs '
            '${needed.toStringAsFixed(1)}',
          );
        }
      }
    }
    node.visitChildren(visit);
  }

  visit(tester.binding.rootElement!.renderObject!);

  for (final String line in crushed) {
    debugPrint('  ! crushed: $line');
  }
  expect(
    crushed,
    isEmpty,
    reason:
        'text laid out narrower than its own longest word breaks inside the '
        'word and renders vertically in Persian, with no overflow and nothing '
        'raised. In $where',
  );
}
