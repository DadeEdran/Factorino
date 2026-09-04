import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/localization/generated/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/money_display_scope.dart';
import 'data/models/app_settings.dart';
import 'data/models/app_theme_mode.dart';
import 'data/models/money_display_unit.dart';
import 'features/settings/application/settings_providers.dart';

/// The application root.
///
/// Three things are settled here and nowhere else:
///
/// * **Persian is the locale, and it is the only one.** `supportedLocales` has
///   one entry and `locale` pins it, so the app does not follow the device
///   language: a user whose phone is in English still gets a Persian invoice
///   application, because that is what the product is (§1).
/// * **RTL is set once at the root** (§9). The Persian locale already gives
///   every descendant `TextDirection.rtl` through `Localizations`; the explicit
///   [Directionality] below makes it true for anything that renders outside
///   that subtree — overlays, dialogs and route transitions built from the
///   navigator — so no widget ever has to fight direction locally.
/// * **`themeMode` is the user's, and follows the system until they say
///   otherwise** (D-087). Both themes are designed (§10), so either is a
///   first-class result rather than a fallback — and so is following the
///   device, which is why that is a stored value rather than the absence of
///   one. This is the only screen-level widget that watches the settings row
///   for it; the setting is written by the settings screen and reaches here as
///   a live query, so the theme changes under the user's finger.
///
/// * **The display unit is the user's too, and it is installed here for the
///   same reason** (D-117). [MoneyDisplayScope] wraps the whole application
///   from inside `builder`, so every amount — including one drawn in a dialog
///   or a route overlay, which build outside the router's subtree — reads the
///   one unit in force. Toman until the row says otherwise, which is what the
///   application did for its whole life before the setting existed.
///
///   **While the row is loading, the system's choice stands.** A first frame
///   painted in the wrong theme and corrected a frame later is a flash on every
///   cold start, and the system value is what the application did for its whole
///   life before this setting existed — so it is the honest default rather than
///   a guess.
class FactorinoApp extends ConsumerStatefulWidget {
  const FactorinoApp({super.key});

  @override
  ConsumerState<FactorinoApp> createState() => _FactorinoAppState();
}

class _FactorinoAppState extends ConsumerState<FactorinoApp> {
  /// Built once and kept: a router rebuilt on every frame would discard the
  /// navigation state it exists to hold.
  late final GoRouter _router = createRouter();

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);
    final AppThemeMode mode = settings.maybeWhen(
      data: (AppSettings value) => value.themeMode,
      orElse: () => AppThemeMode.system,
    );
    final MoneyDisplayUnit unit = settings.maybeWhen(
      data: (AppSettings value) => value.displayUnit,
      orElse: () => MoneyDisplayUnit.toman,
    );

    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) =>
          AppStrings.of(context).appTitle,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (mode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },

      locale: const Locale('fa'),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routerConfig: _router,
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: MoneyDisplayScope(
            unit: unit,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
