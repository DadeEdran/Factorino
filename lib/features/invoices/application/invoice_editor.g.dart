// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_editor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The invoice being edited, and every intent that changes it.
///
/// **The controller holds the state; the engine holds the arithmetic.** Every
/// method here rebuilds [InvoiceEditorState], whose constructor runs
/// `calculateInvoice` — so the totals on screen are recomputed from the entries
/// on every single edit and can never belong to an earlier version of them.
/// Nothing in this file adds two amounts together.
///
/// **Settings are watched, not captured.** The tax default and the rounding
/// unit are the last step of §4's resolution chain, and they live in settings.
/// Watching means that changing the VAT rate while a form is open updates the
/// preview instead of leaving it describing a rule that no longer applies. The
/// repository re-reads settings inside the write transaction anyway — that
/// resolution is the authoritative one — so the two can differ for at most the
/// frame in which the change lands.
///
/// Keyed by the clock reading the form opened with, so `issueDate` is settled
/// once rather than drifting while the user types (D-041's reasoning, one
/// screen along).

@ProviderFor(InvoiceEditor)
final invoiceEditorProvider = InvoiceEditorFamily._();

/// The invoice being edited, and every intent that changes it.
///
/// **The controller holds the state; the engine holds the arithmetic.** Every
/// method here rebuilds [InvoiceEditorState], whose constructor runs
/// `calculateInvoice` — so the totals on screen are recomputed from the entries
/// on every single edit and can never belong to an earlier version of them.
/// Nothing in this file adds two amounts together.
///
/// **Settings are watched, not captured.** The tax default and the rounding
/// unit are the last step of §4's resolution chain, and they live in settings.
/// Watching means that changing the VAT rate while a form is open updates the
/// preview instead of leaving it describing a rule that no longer applies. The
/// repository re-reads settings inside the write transaction anyway — that
/// resolution is the authoritative one — so the two can differ for at most the
/// frame in which the change lands.
///
/// Keyed by the clock reading the form opened with, so `issueDate` is settled
/// once rather than drifting while the user types (D-041's reasoning, one
/// screen along).
final class InvoiceEditorProvider
    extends $AsyncNotifierProvider<InvoiceEditor, InvoiceEditorState> {
  /// The invoice being edited, and every intent that changes it.
  ///
  /// **The controller holds the state; the engine holds the arithmetic.** Every
  /// method here rebuilds [InvoiceEditorState], whose constructor runs
  /// `calculateInvoice` — so the totals on screen are recomputed from the entries
  /// on every single edit and can never belong to an earlier version of them.
  /// Nothing in this file adds two amounts together.
  ///
  /// **Settings are watched, not captured.** The tax default and the rounding
  /// unit are the last step of §4's resolution chain, and they live in settings.
  /// Watching means that changing the VAT rate while a form is open updates the
  /// preview instead of leaving it describing a rule that no longer applies. The
  /// repository re-reads settings inside the write transaction anyway — that
  /// resolution is the authoritative one — so the two can differ for at most the
  /// frame in which the change lands.
  ///
  /// Keyed by the clock reading the form opened with, so `issueDate` is settled
  /// once rather than drifting while the user types (D-041's reasoning, one
  /// screen along).
  InvoiceEditorProvider._({
    required InvoiceEditorFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'invoiceEditorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$invoiceEditorHash();

  @override
  String toString() {
    return r'invoiceEditorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  InvoiceEditor create() => InvoiceEditor();

  @override
  bool operator ==(Object other) {
    return other is InvoiceEditorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$invoiceEditorHash() => r'cd3d98ef40a5b57389fa6756ae6881bded8fcc36';

/// The invoice being edited, and every intent that changes it.
///
/// **The controller holds the state; the engine holds the arithmetic.** Every
/// method here rebuilds [InvoiceEditorState], whose constructor runs
/// `calculateInvoice` — so the totals on screen are recomputed from the entries
/// on every single edit and can never belong to an earlier version of them.
/// Nothing in this file adds two amounts together.
///
/// **Settings are watched, not captured.** The tax default and the rounding
/// unit are the last step of §4's resolution chain, and they live in settings.
/// Watching means that changing the VAT rate while a form is open updates the
/// preview instead of leaving it describing a rule that no longer applies. The
/// repository re-reads settings inside the write transaction anyway — that
/// resolution is the authoritative one — so the two can differ for at most the
/// frame in which the change lands.
///
/// Keyed by the clock reading the form opened with, so `issueDate` is settled
/// once rather than drifting while the user types (D-041's reasoning, one
/// screen along).

final class InvoiceEditorFamily extends $Family
    with
        $ClassFamilyOverride<
          InvoiceEditor,
          AsyncValue<InvoiceEditorState>,
          InvoiceEditorState,
          FutureOr<InvoiceEditorState>,
          DateTime
        > {
  InvoiceEditorFamily._()
    : super(
        retry: null,
        name: r'invoiceEditorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The invoice being edited, and every intent that changes it.
  ///
  /// **The controller holds the state; the engine holds the arithmetic.** Every
  /// method here rebuilds [InvoiceEditorState], whose constructor runs
  /// `calculateInvoice` — so the totals on screen are recomputed from the entries
  /// on every single edit and can never belong to an earlier version of them.
  /// Nothing in this file adds two amounts together.
  ///
  /// **Settings are watched, not captured.** The tax default and the rounding
  /// unit are the last step of §4's resolution chain, and they live in settings.
  /// Watching means that changing the VAT rate while a form is open updates the
  /// preview instead of leaving it describing a rule that no longer applies. The
  /// repository re-reads settings inside the write transaction anyway — that
  /// resolution is the authoritative one — so the two can differ for at most the
  /// frame in which the change lands.
  ///
  /// Keyed by the clock reading the form opened with, so `issueDate` is settled
  /// once rather than drifting while the user types (D-041's reasoning, one
  /// screen along).

  InvoiceEditorProvider call(DateTime openedAt) =>
      InvoiceEditorProvider._(argument: openedAt, from: this);

  @override
  String toString() => r'invoiceEditorProvider';
}

/// The invoice being edited, and every intent that changes it.
///
/// **The controller holds the state; the engine holds the arithmetic.** Every
/// method here rebuilds [InvoiceEditorState], whose constructor runs
/// `calculateInvoice` — so the totals on screen are recomputed from the entries
/// on every single edit and can never belong to an earlier version of them.
/// Nothing in this file adds two amounts together.
///
/// **Settings are watched, not captured.** The tax default and the rounding
/// unit are the last step of §4's resolution chain, and they live in settings.
/// Watching means that changing the VAT rate while a form is open updates the
/// preview instead of leaving it describing a rule that no longer applies. The
/// repository re-reads settings inside the write transaction anyway — that
/// resolution is the authoritative one — so the two can differ for at most the
/// frame in which the change lands.
///
/// Keyed by the clock reading the form opened with, so `issueDate` is settled
/// once rather than drifting while the user types (D-041's reasoning, one
/// screen along).

abstract class _$InvoiceEditor extends $AsyncNotifier<InvoiceEditorState> {
  late final _$args = ref.$arg as DateTime;
  DateTime get openedAt => _$args;

  FutureOr<InvoiceEditorState> build(DateTime openedAt);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<InvoiceEditorState>, InvoiceEditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<InvoiceEditorState>, InvoiceEditorState>,
              AsyncValue<InvoiceEditorState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
