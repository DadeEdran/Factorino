import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../formatting/persian_text.dart';
import '../localization/generated/app_strings.dart';

/// One Jalali month as a grid of tappable days, and the seven weekday headings
/// above it.
///
/// **Shared rather than owned by the date picker**, which is where it was born.
/// The daily-sales screen needs the same calendar with one addition — a mark on
/// the days that have sales — and a second grid written beside the first would
/// be two places to get the Iranian week wrong. It is extracted rather than
/// copied for the reason the dashboard reuses `InvoiceCard`: a calendar that
/// looks one way here and another way one screen along is two designs to keep
/// in step, and the difference is exactly where a leading blank or a weekend
/// tint quietly diverges.
///
/// **The week starts on Saturday**, because the Iranian week does, and Friday
/// carries the weekend tint. Getting this wrong is not a matter of familiarity
/// — it puts every date in the wrong column.

/// The seven single-letter weekday headings, شنبه first.
class JalaliWeekdayHeadings extends StatelessWidget {
  const JalaliWeekdayHeadings({required this.strings, super.key});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> headings = <String>[
      strings.weekdayShanbeShort,
      strings.weekdayYekshanbeShort,
      strings.weekdayDoshanbeShort,
      strings.weekdaySeshanbeShort,
      strings.weekdayChaharshanbeShort,
      strings.weekdayPanjshanbeShort,
      strings.weekdayJomeShort,
    ];

    return Row(
      children: <Widget>[
        for (int i = 0; i < headings.length; i++)
          Expanded(
            child: Center(
              child: Text(
                headings[i],
                style: theme.textTheme.labelSmall?.copyWith(
                  // Friday, the Iranian weekend.
                  color: i == 6
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The days of [month], seven to a row.
class JalaliMonthGrid extends StatelessWidget {
  const JalaliMonthGrid({
    required this.month,
    required this.selected,
    required this.onPick,
    this.isAllowed,
    this.isMarked,
    this.markedSemanticLabel,
    super.key,
  });

  /// Any day inside the month to draw. Only the year and month are read.
  final Jalali month;

  final Jalali selected;
  final ValueChanged<Jalali> onPick;

  /// Days this returns false for are shown dimmed and cannot be picked. Null
  /// allows every day.
  final bool Function(Jalali day)? isAllowed;

  /// Days this returns true for carry a mark under the numeral.
  ///
  /// **A dot, not a colour.** The distinction has to survive a colour-blind
  /// reader and a dark theme, so what separates a day with sales from a day
  /// without is the presence of a shape rather than the hue of the numeral —
  /// the same reasoning that gives the navigation bar a filled icon rather than
  /// a tinted one.
  final bool Function(Jalali day)? isMarked;

  /// What a marked day announces to a screen reader, since a dot announces
  /// nothing. Required in practice whenever [isMarked] is given; without it the
  /// mark is visual-only.
  final String? markedSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int daysInMonth = month.monthLength;

    // `shamsi_date`'s weekDay is 1 for Saturday through 7 for Friday, which is
    // already the Iranian week — so the leading blanks are simply one less than
    // the first day's weekday. Mapping through DateTime.weekday, which starts
    // at Monday, is the mistake this comment exists to prevent.
    final int leadingBlanks = Jalali(month.year, month.month, 1).weekDay - 1;
    final int cells = leadingBlanks + daysInMonth;
    final int rows = (cells / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int row = 0; row < rows; row++)
          Row(
            children: <Widget>[
              for (int column = 0; column < 7; column++)
                Expanded(
                  child: _cell(
                    theme,
                    dayNumber: row * 7 + column - leadingBlanks + 1,
                    daysInMonth: daysInMonth,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(
    ThemeData theme, {
    required int dayNumber,
    required int daysInMonth,
  }) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: cellHeight);
    }

    final Jalali day = Jalali(month.year, month.month, dayNumber);
    final bool isSelected =
        day.year == selected.year &&
        day.month == selected.month &&
        day.day == selected.day;
    final bool allowed = isAllowed?.call(day) ?? true;
    final bool marked = isMarked?.call(day) ?? false;

    final Color foreground = isSelected
        ? theme.colorScheme.onPrimary
        : allowed
        ? theme.colorScheme.onSurface
        // Shown rather than hidden: a gap where days should be reads as a
        // broken calendar, while a dimmed day reads as one that cannot be
        // chosen.
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    final Widget cell = SizedBox(
      height: cellHeight,
      child: Center(
        child: InkWell(
          onTap: allowed ? () => onPick(day) : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: cellHeight,
            height: cellHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  toPersianDigits('$dayNumber'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
                ),
                // The dot's slot is reserved on every day, marked or not, so a
                // month with sales and a month without draw their numerals on
                // the same baseline. Sizing the cell around the mark only where
                // there is one makes the numerals jump by two pixels as the
                // user steps between months.
                SizedBox(
                  height: _markHeight,
                  child: marked
                      ? Container(
                          width: _markDiameter,
                          height: _markDiameter,
                          margin: const EdgeInsets.only(top: _markGap),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final String? label = markedSemanticLabel;
    if (!marked || label == null) return cell;
    return Semantics(label: label, container: true, child: cell);
  }

  /// The height of one day cell. Public because a caller laying a calendar out
  /// beside other content has to reserve the grid's height without guessing it
  /// — the number that must not be duplicated as a literal at a call site.
  static const double cellHeight = 40;

  static const double _markDiameter = 4;
  static const double _markGap = 2;
  static const double _markHeight = _markDiameter + _markGap;
}

/// The month heading with its two step arrows.
class JalaliMonthHeader extends StatelessWidget {
  const JalaliMonthHeader({
    required this.month,
    required this.monthNames,
    required this.strings,
    required this.onStep,
    super.key,
  });

  final Jalali month;
  final List<String> monthNames;
  final AppStrings strings;

  /// Called with -1 or 1.
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        IconButton(
          // In RTL the "previous" affordance points right. These are
          // directional navigation icons, which §9 says do mirror — and Flutter
          // mirrors them automatically under an RTL Directionality, so the
          // logical names are the correct ones here and reversing them by hand
          // would double the flip.
          icon: const Icon(Icons.chevron_left),
          tooltip: strings.datePickerPreviousMonth,
          onPressed: () => onStep(-1),
        ),
        Expanded(
          child: Text(
            // Month and year of the grid being browsed, named rather than
            // numbered: `۱۴۰۵/۰۶` is a date, not a heading.
            '${monthNames[month.month - 1]} '
            '${toPersianDigits('${month.year}')}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: strings.datePickerNextMonth,
          onPressed: () => onStep(1),
        ),
      ],
    );
  }
}

/// Seven columns of tappable days plus the surrounding padding.
///
/// Fixed, because a calendar that reflows is a calendar whose columns move.
const double kJalaliCalendarWidth = 312;
