import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/core/theme/app_dimensions.dart';
import 'package:factorino/core/widgets/amount_text.dart';
import 'package:factorino/core/widgets/app_table.dart';
import 'package:factorino/core/widgets/stat_tile.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_list_item.dart';
import 'package:factorino/data/models/invoice_status.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/core/utils/clock.dart';
import 'package:factorino/features/invoices/domain/invoice_summary_figures.dart';
import 'package:factorino/features/invoices/presentation/invoices_screen.dart';
import 'package:factorino/features/invoices/presentation/widgets/invoice_totals_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/invoices/fake_invoice_repository.dart';
import '../../features/screen_harness.dart';
import '../../support/money_magnitudes.dart';

/// The sweep D-057 requires: every fixed-width money container, at every rung of
/// the amount ladder.
///
/// **This file exists because a measurement is not a check.** The desktop
/// summary panel's overflow was measurable for a whole increment before anybody
/// measured it, and the phase it belonged to closed on a device report saying
/// zero layout errors — truthfully, about the one tier it ran on, at whatever
/// amounts the flow happened to produce. A `RenderFlex` overflow fails a widget
/// test on its own, so a container rendered at its real width with a real
/// magnitude in it is the whole assertion.
///
/// **A new fixed-width money site is added here.** Not to a screen's own test
/// file: the point of one sweep is that the ladder is the same everywhere, and a
/// per-screen ladder is a ladder chosen to pass.
///
/// The metrics are the fallback test font's, whose glyphs are much wider than
/// Vazirmatn's, so passing here means margin in the shipped layout rather than
/// sitting on the limit. What the font cannot change is that a money width is
/// **magnitude-dependent** — which is the property the ladder holds down, and
/// the one a device pass at a single amount can never see.
void main() {
  Money toman(int value) => Money.rial(value * 10);

  /// The width each [AmountSize] is allowed to need at the top of the ladder.
  const Map<AmountSize, double> budget = <AmountSize, double>{
    AmountSize.small: AppLayout.amountWidthSmall,
    AmountSize.medium: AppLayout.amountWidthMedium,
    AmountSize.large: AppLayout.amountWidthLarge,
  };

  group('an amount never outgrows the width its size is budgeted', () {
    for (final AmountSize size in AmountSize.values) {
      for (final int value in kMoneyStressToman) {
        testWidgets('$size at $value toman', (WidgetTester tester) async {
          await pumpScreen(
            tester,
            Align(
              alignment: Alignment.topRight,
              child: Builder(
                builder: (BuildContext context) =>
                    AmountText(toman(value), size: size),
              ),
            ),
            size: kDesktopSize,
          );

          // Laid out unconstrained, so this is the width the figure *wants* --
          // which is the number every fixed-width container has to be sized
          // against. A container narrower than this clips a figure, and a
          // clipped figure on a document is the one failure money may not have.
          expect(
            tester.getSize(find.byType(AmountText)).width,
            lessThanOrEqualTo(budget[size]!),
            reason:
                'AppLayout.amountWidth${size.name} no longer covers $value '
                'toman. Widen the token and re-check every container sized '
                'from it -- do not narrow the ladder.',
          );
        });
      }
    }
  });

  group('the summary panel, at the width the desktop composes it into', () {
    for (final bool dense in <bool>[false, true]) {
      for (final int value in kMoneyStressToman) {
        testWidgets('${dense ? "dense" : "panel"} at $value toman', (
          WidgetTester tester,
        ) async {
          // Overflowed by 30 pixels at 1,000,000 and 58 at 10,000,000 while the
          // grand total was `AmountSize.large` -- on every invoice a real
          // business issues. No `expect`: an overflow fails this on its own.
          await pumpScreen(
            tester,
            Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: AppLayout.detailPanelWidth,
                child: Builder(
                  builder: (BuildContext context) => InvoiceTotalsSummary(
                    dense: dense,
                    strings: AppStrings.of(context),
                    totals: InvoiceSummaryFigures(
                      grossTotal: toman(value),
                      totalDiscount: toman(value ~/ 10),
                      totalTax: toman(value ~/ 10),
                      roundingAdjustment: Money.zero,
                      grandTotal: toman(value),
                    ),
                  ),
                ),
              ),
            ),
            size: kDesktopSize,
          );
          await tester.pumpAndSettle();
        });
      }
    }
  });

  group('a money table cell, at the column width the spec gives it', () {
    for (final int value in kMoneyStressToman) {
      testWidgets('$value toman', (WidgetTester tester) async {
        // `AppTableRow` spends `AppSpacing.md` of the column on the gap to the
        // next one, so the amount never had the whole `tablePriceWidth`. At 232
        // this overflowed by 9 pixels at the top rung; the token is derived from
        // the amount width plus that gap now, which is what stops the two
        // drifting apart again.
        await pumpScreen(
          tester,
          Builder(
            builder: (BuildContext context) => AppTableRow(
              columns: const <TableColumnSpec>[
                TableColumnSpec.fixed(
                  label: 'X',
                  width: AppLayout.tablePriceWidth,
                ),
              ],
              cells: <Widget>[AmountText(toman(value), size: AmountSize.small)],
            ),
          ),
          size: kDesktopSize,
        );
        await tester.pumpAndSettle();
      });
    }
  });

  group('a stat tile scales rather than clipping', () {
    for (final int value in kMoneyStressToman) {
      testWidgets('four to a row at $value toman', (WidgetTester tester) async {
        // The dashboard puts four `AmountSize.large` figures across a desktop
        // row, which leaves each about 240 pixels -- far under
        // `amountWidthLarge`. It does not overflow because `StatTile` wraps its
        // value in a `FittedBox`, a decision made when the tile was built and
        // worth a test of its own: it is the one money site in the application
        // where a figure may change size, and what makes that acceptable is that
        // a tile is a headline rather than a column to align down.
        await pumpScreen(
          tester,
          Builder(
            builder: (BuildContext context) => TileGrid(
              columns: 4,
              tiles: <Widget>[
                for (int i = 0; i < 4; i++)
                  StatTile(
                    label: AppStrings.of(context).dashboardSalesThisMonth,
                    caption: AppStrings.of(context).dashboardOutstandingCaption,
                    value: AmountText(toman(value), size: AmountSize.large),
                  ),
              ],
            ),
          ),
          size: kDesktopSize,
        );
        await tester.pumpAndSettle();
      });
    }
  });

  group('the invoice list, at every tier, over the whole ladder', () {
    // **The surface Phase 5 (e) changed, swept the way D-057 asks for.**
    //
    // The list already had a tier sweep and an amount somewhere in the middle
    // of the ladder, which is two half-checks: the tier sweep renders no money
    // ("what varies across tiers is where the control sits"), and the money
    // assertions render one magnitude. A card that fits at 1,200,000 تومان and
    // breaks at 100,000,000 would pass both, and that is precisely the shape of
    // known issue 18 — measured on a widget that had a page to itself, at
    // whatever amount the fixture happened to hold.
    //
    // Here the whole screen is composed at each tier's real width with every
    // rung of the ladder on it at once, so the mobile card, the tablet card and
    // the desktop table row are each checked at the width they are actually
    // given (§10: a widget tested only at its own full width has not been
    // tested at the width it is composed into). A `RenderFlex` overflow fails
    // the test on its own; there is nothing else to assert.
    final DateTime now = DateTime.utc(2026, 8, 24, 6);

    InvoiceListItem row(int index, int rialValue) {
      final DateTime issued = DateTime.utc(2026, 8, 20, 6);
      return InvoiceListItem(
        // A long Persian name and a company, because the amount is not the only
        // thing competing for a row's width.
        liveCustomerName: 'شرکت مهندسی و بازرگانی نمونهٔ ایرانیان',
        invoice: Invoice(
          id: 'i$index',
          number: 'INV-1405-${(index + 1).toString().padLeft(4, '0')}',
          numberYear: 1405,
          numberSequence: index + 1,
          customerId: 'c1',
          issueDate: issued,
          dueDate: issued.add(const Duration(days: 30)),
          status: InvoiceStatus.unpaid,
          discount: Money.zero,
          grossTotal: Money.rial(rialValue),
          subtotal: Money.rial(rialValue),
          totalDiscount: Money.zero,
          totalTax: Money.zero,
          roundingAdjustment: Money.zero,
          grandTotal: Money.rial(rialValue),
          createdAt: issued,
          updatedAt: issued,
        ),
      );
    }

    for (final MapEntry<String, Size> tier in kAllTierSizes.entries) {
      testWidgets('every rung at once, at ${tier.key}', (
        WidgetTester tester,
      ) async {
        await pumpScreen(
          tester,
          const InvoicesScreen(),
          overrides: <Override>[
            invoiceRepositoryProvider.overrideWithValue(
              FakeInvoiceRepository(<InvoiceListItem>[
                for (int i = 0; i < kMoneyStressRial.length; i++)
                  row(i, kMoneyStressRial[i]),
              ]),
            ),
            nowProvider.overrideWithValue(now),
          ],
          size: tier.value,
        );
        await tester.pumpAndSettle();

        // Every rung is on screen rather than merely in the repository: a lazy
        // list that never built the widest row would report no overflow about
        // a row it never laid out.
        expect(
          find.byType(AmountText),
          findsNWidgets(kMoneyStressRial.length),
          reason:
              'each rung must actually be laid out, or the sweep is checking '
              'rows that were never built',
        );
      });
    }
  });
}
