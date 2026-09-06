// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_editor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The settings write, and nothing else.
///
/// **Editable settings are a defect fix, not a feature** (D-068): The project spec
/// §4 requires the VAT rate to be configurable and never hardcoded, and until
/// this it was hardcoded at whatever the database was seeded with. A business
/// on a different rate met that on its first invoice with no recourse.
///
/// **Changing the rate does not alter existing invoices** and cannot: every
/// item snapshots the rate that applied to it (§4, D-026). That is the property
/// which makes this screen safe to open at all.

@ProviderFor(SettingsEditor)
final settingsEditorProvider = SettingsEditorProvider._();

/// The settings write, and nothing else.
///
/// **Editable settings are a defect fix, not a feature** (D-068): The project spec
/// §4 requires the VAT rate to be configurable and never hardcoded, and until
/// this it was hardcoded at whatever the database was seeded with. A business
/// on a different rate met that on its first invoice with no recourse.
///
/// **Changing the rate does not alter existing invoices** and cannot: every
/// item snapshots the rate that applied to it (§4, D-026). That is the property
/// which makes this screen safe to open at all.
final class SettingsEditorProvider
    extends $NotifierProvider<SettingsEditor, void> {
  /// The settings write, and nothing else.
  ///
  /// **Editable settings are a defect fix, not a feature** (D-068): The project spec
  /// §4 requires the VAT rate to be configurable and never hardcoded, and until
  /// this it was hardcoded at whatever the database was seeded with. A business
  /// on a different rate met that on its first invoice with no recourse.
  ///
  /// **Changing the rate does not alter existing invoices** and cannot: every
  /// item snapshots the rate that applied to it (§4, D-026). That is the property
  /// which makes this screen safe to open at all.
  SettingsEditorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsEditorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsEditorHash();

  @$internal
  @override
  SettingsEditor create() => SettingsEditor();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$settingsEditorHash() => r'0a1de5eb34c34c9331ada23b92ba5845ae001791';

/// The settings write, and nothing else.
///
/// **Editable settings are a defect fix, not a feature** (D-068): The project spec
/// §4 requires the VAT rate to be configurable and never hardcoded, and until
/// this it was hardcoded at whatever the database was seeded with. A business
/// on a different rate met that on its first invoice with no recourse.
///
/// **Changing the rate does not alter existing invoices** and cannot: every
/// item snapshots the rate that applied to it (§4, D-026). That is the property
/// which makes this screen safe to open at all.

abstract class _$SettingsEditor extends $Notifier<void> {
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
