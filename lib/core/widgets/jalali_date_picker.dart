import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../date/jalali_instant.dart';
import '../formatting/jalali_display.dart';
import '../localization/generated/app_strings.dart';
import '../localization/month_names.dart';
import '../theme/app_dimensions.dart';
import 'jalali_month_grid.dart';

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
    final List<String> months = jalaliMonthNames(strings);

    return AlertDialog(
      title: Text(widget.title ?? strings.datePickerTitle),
      content: SizedBox(
        width: _dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            JalaliMonthHeader(
              month: _visibleMonth,
              monthNames: months,
              strings: strings,
              onStep: _showMonth,
            ),
            const SizedBox(height: AppSpacing.sm),
            JalaliWeekdayHeadings(strings: strings),
            const SizedBox(height: AppSpacing.xs),
            JalaliMonthGrid(
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

  static const double _dialogWidth = kJalaliCalendarWidth;
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
