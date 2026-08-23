import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/localization/generated/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

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
/// * **`themeMode` follows the system.** Both themes are designed (§10), so
///   either is a first-class result rather than a fallback.
class FactorinoApp extends StatefulWidget {
  const FactorinoApp({super.key});

  @override
  State<FactorinoApp> createState() => _FactorinoAppState();
}

class _FactorinoAppState extends State<FactorinoApp> {
  /// Built once and kept: a router rebuilt on every frame would discard the
  /// navigation state it exists to hold.
  late final GoRouter _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) =>
          AppStrings.of(context).appTitle,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

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
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
