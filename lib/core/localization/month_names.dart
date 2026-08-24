import 'generated/app_strings.dart';

/// The twelve Jalali month names, in order, ready for
/// `core/formatting/jalali_display.dart`.
///
/// That file takes the names as a parameter rather than holding them, because
/// D-034 puts every user-facing word in the ARB and month names are copy like
/// any other. This is the adapter between the two, and it lives here — in the
/// localization layer — because it is the only place allowed to know that
/// `monthFarvardin` is the first one.
///
/// Assembled per call rather than cached: twelve string reads cost nothing next
/// to laying out the text they end up in, and a cache keyed on the wrong thing
/// would be the sort of bug that only appears once a second locale exists.
List<String> jalaliMonthNames(AppStrings strings) => <String>[
  strings.monthFarvardin,
  strings.monthOrdibehesht,
  strings.monthKhordad,
  strings.monthTir,
  strings.monthMordad,
  strings.monthShahrivar,
  strings.monthMehr,
  strings.monthAban,
  strings.monthAzar,
  strings.monthDey,
  strings.monthBahman,
  strings.monthEsfand,
];
