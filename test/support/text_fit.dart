import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Detects text that has been laid out **narrower than its own longest word**,
/// anywhere in the tree.
///
/// **Why this is a shared assertion and not a per-screen one.** The invoice
/// document's description column was laid out at 21.6 logical pixels on the
/// desktop tier — every desktop width, not an edge case — and Persian text
/// rendered one glyph per row, vertically. **Nothing failed.** There is no
/// overflow, because `Expanded` is a *tight* fit: the flexible column is handed
/// whatever is left after the fixed columns take theirs, and if that is nothing
/// then nothing is what it gets, laid out successfully. A `RenderFlex` overflow
/// error is a check for content that is too big for its box; this is content
/// whose box was made too small for it, and it is silent.
///
/// **The detector is the text's own minimum intrinsic width**, which is the
/// width of its widest unbreakable run — one word, for prose. A paragraph
/// narrower than that cannot place its longest word on a line, so it breaks
/// *inside* the word. That is not "tight", it is unreadable, and it is the same
/// judgement the project spec makes about amounts: a container that cannot give
/// its content the width it needs must do something other than crush it.
///
/// **Ellipsised text is not crushed** — it is deliberately truncated, which is a
/// design decision a widget made on purpose, and it stays legible as far as it
/// goes. Only soft-wrapping text that clips is flagged, because that is the
/// state with no author behind it.
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
        // A pixel of slack: intrinsic width and layout width are computed by
        // the same engine but not always to the same rounding.
        if (node.size.width + 1 < needed) {
          crushed.add(
            '"${text.length > 40 ? '${text.substring(0, 40)}…' : text}" '
            'laid out at ${node.size.width.toStringAsFixed(1)} px, '
            'needs ${needed.toStringAsFixed(1)} px for its longest word',
          );
        }
      }
    }
    node.visitChildren(visit);
  }

  visit(tester.binding.rootElement!.renderObject!);

  expect(
    crushed,
    isEmpty,
    reason:
        'text narrower than its own longest word breaks inside the word and '
        'renders one glyph per line — vertically, in Persian. Nothing raises: '
        'a flexible column handed no width is laid out successfully at no '
        'width. In $where:\n  ${crushed.join('\n  ')}',
  );
}

/// Persian content at the length a real user's data reaches.
///
/// **Short fixtures are the small-test-data mistake in another dimension.**
/// D-057 wrote the amount ladder down because a panel that fits at 100,000
/// تومان breaks at 1,000,000 and a dev database only ever holds the first. The
/// same is true of text: «کالا» fits anywhere and tells you nothing about the
/// column, and every screen in this project was built against fixtures a few
/// characters long.
abstract final class PersianFixtures {
  /// A service line as a workshop actually describes one.
  static const String longLineTitle =
      'طراحی و پیاده‌سازی وب‌سایت فروشگاهی به همراه پشتیبانی فنی یک‌ساله';

  /// A company name of the length an Iranian registered entity reaches.
  static const String longCompanyName =
      'شرکت مهندسی و بازرگانی نمونهٔ ایرانیان با مسئولیت محدود';

  /// A person's full name with a compound surname.
  static const String longPersonName = 'محمدحسین رضایی‌نژاد اصفهانی';

  /// An address, which is the longest free-text field in the application.
  static const String longAddress =
      'تهران، خیابان ولیعصر، بالاتر از میدان ونک، کوچهٔ شهید احمدی، '
      'پلاک ۱۲۰، طبقهٔ چهارم، واحد ۴';

  /// A note, which users write as sentences rather than as labels.
  static const String longNote =
      'تحویل تا پایان شهریور انجام می‌شود و پرداخت پس از تأیید نهایی کارفرما '
      'و دریافت تأییدیهٔ فنی صورت می‌گیرد.';

  /// The longest single **word** in the fixtures above, which is what decides
  /// whether a column is crushed. Named so a test can say what it is testing.
  static const String longestWord = 'پیاده‌سازی';
}
