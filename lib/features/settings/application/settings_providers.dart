import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/app_settings.dart';
import '../../../data/providers.dart';

part 'settings_providers.g.dart';

/// The application settings, as a live query.
///
/// A feature-level provider over the repository (`ARCHITECTURE.md` §B.1):
/// the screen watches this, never a repository or a database directly.
///
/// Auto-disposed by default -- there is no reason to keep a query alive while
/// the settings screen is not on screen (§3: prefer scoped, auto-disposed
/// providers).
@riverpod
Stream<AppSettings> appSettings(Ref ref) {
  return ref.watch(settingsRepositoryProvider).watch();
}
