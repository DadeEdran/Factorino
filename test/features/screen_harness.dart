import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Pumps one screen with the same locale, direction, theme, localizations and
/// router the real application gives it.
///
/// The harness matters more than it looks, in three ways that each cost a
/// debugging session to learn:
///
/// **Direction.** A screen pumped without `Directionality.rtl` lays out
/// left-to-right, and every alignment assertion is then answering a question
/// about a layout the user never sees — which is worse than no test, because it
/// passes.
///
/// **Size.** `LayoutTier` is read from the width, so a test that does not set
/// one is testing whichever tier the default surface happens to land in.
///
/// **No keyboard, unless one is asked for.** This builder installs a fresh
/// `MediaQueryData`, which means every screen in every test has rendered with
/// `viewInsets: EdgeInsets.zero` — no soft keyboard, ever. That is the right
/// default for a layout test and it is also **why 892 tests could not see known
/// issue 21**: the payment sheet's «ذخیره» was below the fold only once a
/// keyboard took a third of the viewport, and nothing here has ever raised one.
/// Pass [viewInsets] to test a sheet in the state a phone actually opens it in
/// (D-062); `test/core/widgets/sheet_keyboard_test.dart` is where that is done.
///
/// **A router.** These screens navigate: a form calls `context.go` after a
/// successful save, and a list row opens an edit route. Without a `GoRouter` in
/// the tree those calls throw *"No GoRouter found in context"* at the end of an
/// otherwise passing test, which reads as a failure of the thing being tested
/// rather than of the harness. [lastLocation] exposes where the screen asked to
/// go, so navigation can be asserted rather than merely survived.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const <Override>[],
  Size size = kMobileSize,
  bool disableAnimations = false,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _lastLocation = '/';

  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => screen,
      ),
      // Stubs for everywhere a screen under test can navigate to. They render
      // nothing: the assertion is that the app asked to go there, not what is
      // on the other side.
      for (final String path in <String>[
        '/invoices',
        '/invoices/new',
        // After `/invoices/new`, exactly as the real router declares it.
        '/invoices/:id',
        '/customers',
        '/customers/new',
        '/customers/:id/edit',
        // After the two above, exactly as the real router declares it: `:id`
        // would otherwise swallow `/customers/new`.
        '/customers/:id',
        '/products',
        '/products/new',
        '/products/:id/edit',
      ])
        GoRoute(
          path: path,
          builder: (BuildContext context, GoRouterState state) {
            _lastLocation = state.uri.toString();
            return const SizedBox.shrink();
          },
        ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('fa'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQueryData(
              size: size,
              disableAnimations: disableAnimations,
              viewInsets: viewInsets,
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: child ?? const SizedBox.shrink()),
            ),
          );
        },
      ),
    ),
  );
}

String _lastLocation = '/';

/// Where the screen under test last navigated, or `/` if it has not.
String get lastLocation => _lastLocation;

/// The width at which [LayoutTier] becomes desktop, plus room to spare.
const Size kDesktopSize = Size(1400, 900);

/// A phone.
const Size kMobileSize = Size(400, 800);

/// A tablet: past `Breakpoints.tablet` and short of `Breakpoints.desktop`.
///
/// The tier nothing had a size for until D-057, which is a large part of why
/// nothing was checked at it.
const Size kTabletSize = Size(840, 1100);

/// Every tier, named, so a sweep cannot quietly leave one out (D-057).
const Map<String, Size> kAllTierSizes = <String, Size>{
  'mobile': kMobileSize,
  'tablet': kTabletSize,
  'desktop': kDesktopSize,
};

/// Resolves the Persian strings from a pumped widget tree, so a test asserts
/// against the ARB rather than against a Persian literal copied into the test —
/// which would keep passing after the copy changed.
AppStrings stringsOf(WidgetTester tester, Type screenType) {
  return AppStrings.of(tester.element(find.byType(screenType)));
}
