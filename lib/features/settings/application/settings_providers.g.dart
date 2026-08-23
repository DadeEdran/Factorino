// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The application settings, as a live query.
///
/// A feature-level provider over the repository (`ARCHITECTURE.md` §B.1):
/// the screen watches this, never a repository or a database directly.
///
/// Auto-disposed by default -- there is no reason to keep a query alive while
/// the settings screen is not on screen (§3: prefer scoped, auto-disposed
/// providers).

@ProviderFor(appSettings)
final appSettingsProvider = AppSettingsProvider._();

/// The application settings, as a live query.
///
/// A feature-level provider over the repository (`ARCHITECTURE.md` §B.1):
/// the screen watches this, never a repository or a database directly.
///
/// Auto-disposed by default -- there is no reason to keep a query alive while
/// the settings screen is not on screen (§3: prefer scoped, auto-disposed
/// providers).

final class AppSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppSettings>,
          AppSettings,
          Stream<AppSettings>
        >
    with $FutureModifier<AppSettings>, $StreamProvider<AppSettings> {
  /// The application settings, as a live query.
  ///
  /// A feature-level provider over the repository (`ARCHITECTURE.md` §B.1):
  /// the screen watches this, never a repository or a database directly.
  ///
  /// Auto-disposed by default -- there is no reason to keep a query alive while
  /// the settings screen is not on screen (§3: prefer scoped, auto-disposed
  /// providers).
  AppSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSettingsHash();

  @$internal
  @override
  $StreamProviderElement<AppSettings> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AppSettings> create(Ref ref) {
    return appSettings(ref);
  }
}

String _$appSettingsHash() => r'42881025817ecbfbd52e4e563bb80521e3e14d0d';
