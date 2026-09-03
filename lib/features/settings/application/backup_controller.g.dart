// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The backup writes, and nothing else.
///
/// **The screen never touches the service, the gateway or a repository** (§3).
/// This is the whole widget-facing surface for taking and restoring a backup.
///
/// **Every path deletes the working file.** The container is built in
/// app-private storage and moved from there (D-071); leaving one behind would
/// mean the entire customer and invoice database sitting in the application's
/// own directory, encrypted but unasked for, after an operation the user may
/// well have cancelled.

@ProviderFor(BackupController)
final backupControllerProvider = BackupControllerProvider._();

/// The backup writes, and nothing else.
///
/// **The screen never touches the service, the gateway or a repository** (§3).
/// This is the whole widget-facing surface for taking and restoring a backup.
///
/// **Every path deletes the working file.** The container is built in
/// app-private storage and moved from there (D-071); leaving one behind would
/// mean the entire customer and invoice database sitting in the application's
/// own directory, encrypted but unasked for, after an operation the user may
/// well have cancelled.
final class BackupControllerProvider
    extends $NotifierProvider<BackupController, void> {
  /// The backup writes, and nothing else.
  ///
  /// **The screen never touches the service, the gateway or a repository** (§3).
  /// This is the whole widget-facing surface for taking and restoring a backup.
  ///
  /// **Every path deletes the working file.** The container is built in
  /// app-private storage and moved from there (D-071); leaving one behind would
  /// mean the entire customer and invoice database sitting in the application's
  /// own directory, encrypted but unasked for, after an operation the user may
  /// well have cancelled.
  BackupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupControllerHash();

  @$internal
  @override
  BackupController create() => BackupController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$backupControllerHash() => r'096f1e02d3c6797dd2870776aa5966dc86a5e623';

/// The backup writes, and nothing else.
///
/// **The screen never touches the service, the gateway or a repository** (§3).
/// This is the whole widget-facing surface for taking and restoring a backup.
///
/// **Every path deletes the working file.** The container is built in
/// app-private storage and moved from there (D-071); leaving one behind would
/// mean the entire customer and invoice database sitting in the application's
/// own directory, encrypted but unasked for, after an operation the user may
/// well have cancelled.

abstract class _$BackupController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
