/// Which of the two designed themes the application shows (§10).
///
/// Stored as the **enum index**, like every other enum this schema holds, so
/// these values must never be reordered and new ones may only be appended.
///
/// [system] is the default and is a real choice rather than an absence: both
/// themes are designed rather than one being an inversion of the other, so
/// following the device is a first-class outcome and not a fallback. It is
/// kept as its own value rather than being represented by a null column, so
/// "the user has never chosen" and "the user chose to follow the device" stay
/// the same fact — which they are, and which a nullable column would invite a
/// later reader to distinguish.
///
/// Lives in `data/models/` rather than beside the table that stores it: the
/// domain layer must not import drift (§3), so every enum a domain model
/// carries has to be declared somewhere drift-free.
enum AppThemeMode {
  /// Follow the device's own light/dark setting.
  system,

  light,

  dark,
}
