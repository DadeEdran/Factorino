import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../date/jalali_instant.dart';
import '../formatting/jalali_display.dart';
import '../formatting/persian_text.dart';
import '../localization/generated/app_strings.dart';
import '../localization/month_names.dart';
import '../theme/app_dimensions.dart';

/// Picks a Jalali day and returns the **UTC instant** that day begins at.
///
/// Returns null if dismissed.
///
/// **Why this exists rather than `showDatePicker`.** Material's picker is a
/// Gregorian calendar. Localizing it produces Persian digits over Gregorian
/// month lengths and Gregorian month boundaries — a grid where Farvardin does
/// not exist and where the user counts days in the wrong month. §5 makes the
/// Jalali calendar the display calendar, and a date picker is the one place
/// where "display" means the whole affordance.
///
/// **Why not a package.** `shamsi_date` is already a dependency and already
/// does the conversion; what was missing was a grid. A calendar package would
/// bring its own theming, its own strings and its own opinion about the week,
/// and the project spec asks whether what we have already covers it. It did.
///
/// **The week starts on Saturday**, because the Iranian week does. Friday is
/// the weekend and is tinted accordingly. Getting this wrong is not a matter of
/// familiarity — it puts every date in the wrong column.
///
/// The returned instant is `startOfJalaliDayUtc`: local midnight in Tehran,
/// converted to UTC (D-005). A day is stored as the instant it begins, so a
/// date comparison is an instant comparison and never a string one.
Future<DateTime?> showJalaliDatePicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? firstAllowed,
  String? title,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) => _JalaliDatePickerDialog(
      initial: initial,
      firstAllowed: firstAllowed,
      title: title,
    ),
  );
}

class _JalaliDatePickerDialog extends StatefulWidget {
  const _JalaliDatePickerDialog({
    required this.initial,
    this.firstAllowed,
    this.title,
  });

  final DateTime initial;

  /// Days before this instant are shown but not selectable. Used for a due
  /// date, which may not precede its invoice's issue date.
  final DateTime? firstAllowed;

  /// Overrides «انتخاب تاریخ», for the callers that open this twice in a row.
  ///
  /// **Persian, from the localization layer**, like every other string reaching
  /// this dialog (§1) — passed in rather than selected here from an enum,
  /// because the heading is copy and belongs with the screen that knows what it
  /// is asking for. The invoice filter's custom range is the case: two
  /// identical calendars headed «انتخاب تاریخ» give the user no way to tell
  /// which end of the range they are on.
  final String? title;

  @override
  State<_JalaliDatePickerDialog> createState() =>
      _JalaliDatePickerDialogState();
}

class _JalaliDatePickerDialogState extends State<_JalaliDatePickerDialog> {
  late Jalali _selected = jalaliAt(widget.initial);

  /// The month on screen, which is not the selection: browsing away from the
  /// selected day must not move it.
  late Jalali _visibleMonth = Jalali(_selected.year, _selected.month, 1);

  void _showMonth(int delta) {
    setState(() {
      // Day 1 every time, because month arithmetic on day 31 lands outside a
      // 30-day month and `shamsi_date` would throw rather than clamp.
      final Jalali moved = _visibleMonth.addMonths(delta);
      _visibleMonth = Jalali(moved.year, moved.month, 1);
    });
  }

  bool _isAllowed(Jalali day) {
    final DateTime? floor = widget.firstAllowed;
    if (floor == null) return true;
    return !startOfJalaliDayUtc(day)
.isBefore(startOfJalaliDayUtc(jalaliAt(floor)));
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final List<String> months = jalaliMonthNames(strings);

    return AlertDialog(
      title: Text(widget.title ?? strings.datePickerTitle),
      content: SizedBox(
        width: _dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  // In RTL the "previous" affordance points right. These are
                  // directional navigation icons, which §9 says do mirror —
                  // and Flutter mirrors them automatically under an RTL
                  // Directionality, so the logical names are the correct ones
                  // here and reversing them by hand would double the flip.
                  icon: const Icon(Icons.chevron_left),
                  tooltip: strings.datePickerPreviousMonth,
                  onPressed: () => _showMonth(-1),
                ),
                Expanded(
                  child: Text(
                    // Month and year of the grid being browsed, named rather
                    // than numbered: `۱۴۰۵/۰۶` is a date, not a heading.
                    '${months[_visibleMonth.month - 1]} '
                    '${toPersianDigits('${_visibleMonth.year}')}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: strings.datePickerNextMonth,
                  onPressed: () => _showMonth(1),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _WeekdayHeadings(strings: strings),
            const SizedBox(height: AppSpacing.xs),
            _MonthGrid(
              month: _visibleMonth,
              selected: _selected,
              isAllowed: _isAllowed,
              onPick: (Jalali day) => setState(() {
                _selected = day;
                _visibleMonth = Jalali(day.year, day.month, 1);
              }),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            final Jalali today = jalaliAt(DateTime.now().toUtc());
            setState(() {
              _selected = today;
              _visibleMonth = Jalali(today.year, today.month, 1);
            });
          },
          child: Text(strings.datePickerToday),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.actionCancel),
        ),
        FilledButton(
          onPressed: _isAllowed(_selected)
              ? () => Navigator.of(context).pop(startOfJalaliDayUtc(_selected))
: null,
          child: Text(strings.actionSave),
        ),
      ],
    );
  }

  /// Seven columns of tappable days plus the dialog's own padding. Fixed,
  /// because a calendar that reflows is a calendar whose columns move.
  static const double _dialogWidth = 312;
}

class _WeekdayHeadings extends StatelessWidget {
  const _WeekdayHeadings({required this.strings});

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

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.isAllowed,
    required this.onPick,
  });

  final Jalali month;
  final Jalali selected;
  final bool Function(Jalali day) isAllowed;
  final ValueChanged<Jalali> onPick;

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
      return const SizedBox(height: _cellHeight);
    }

    final Jalali day = Jalali(month.year, month.month, dayNumber);
    final bool isSelected =
        day.year == selected.year &&
        day.month == selected.month &&
        day.day == selected.day;
    final bool allowed = isAllowed(day);

    return SizedBox(
      height: _cellHeight,
      child: Center(
        child: InkWell(
          onTap: allowed ? () => onPick(day) : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: _cellHeight,
            height: _cellHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
            child: Text(
              toPersianDigits('$dayNumber'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
: allowed
                    ? theme.colorScheme.onSurface
                    // Shown rather than hidden: a gap where days should be
                    // reads as a broken calendar, while a dimmed day reads as
                    // one that cannot be chosen.
: theme.colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const double _cellHeight = 40;
}

/// A tappable field showing a Jalali date, for a form.
///
/// Renders through `formatJalaliDateLong`, so the month is named — a date the
/// user is checking rather than scanning, which is what an issue date is.
class JalaliDateField extends StatelessWidget {
  const JalaliDateField({
    required this.label,
    required this.value,
    required this.onPick,
    this.emptyLabel,
    this.onClear,
    super.key,
  });

  final String label;

  /// Null renders [emptyLabel] — used by the due date, which may be absent.
  final DateTime? value;

  final String? emptyLabel;
  final VoidCallback onPick;

  /// Null hides the clear affordance. An issue date cannot be cleared; a due
  /// date can.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final DateTime? current = value;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: current != null && onClear != null
              ? IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: strings.actionCancel,
                  onPressed: onClear,
                )
: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          current == null
              ? (emptyLabel ?? '')
: formatJalaliDateLong(
                  current,
                  monthNames: jalaliMonthNames(strings),
                ),
        ),
      ),
    );
  }
}
