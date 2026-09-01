// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_payments.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The two payment writes, and nothing else.
///
/// **The screen never touches a repository** (§3). This is the whole of the
/// widget-facing surface for recording and removing a payment, and it is
/// deliberately thin: the derived status is recomputed inside the repository's
/// own transaction (§6), so there is no state to keep here and nothing to
/// invalidate — `invoiceDetailProvider` is a live query and the recomputed row
/// arrives on its own.
///
/// **Both methods return a bool rather than throwing** (§7). A failed write is
/// a friendly Persian message on the screen, never a stack trace or a raw
/// exception string in front of the user; the detail goes through [AppLog] and
/// carries no amount, no name and no identifier.
///
/// **`PaymentNotAccepted` is not treated as a special case here**, and that is
/// deliberate. The repository is the authority on which invoices may take a
/// payment (D-013's shape, applied to payments): a draft is not yet a claim on
/// anyone and a cancelled invoice is not one any more. The screen hides the
/// control for both and explains why, so a user cannot reach the refusal
/// through the UI — but a deep link, a second window or a future sync path can,
/// and when they do the write fails cleanly rather than being prevented by a
/// widget that happened to be on screen.

@ProviderFor(InvoicePayments)
final invoicePaymentsProvider = InvoicePaymentsFamily._();

/// The two payment writes, and nothing else.
///
/// **The screen never touches a repository** (§3). This is the whole of the
/// widget-facing surface for recording and removing a payment, and it is
/// deliberately thin: the derived status is recomputed inside the repository's
/// own transaction (§6), so there is no state to keep here and nothing to
/// invalidate — `invoiceDetailProvider` is a live query and the recomputed row
/// arrives on its own.
///
/// **Both methods return a bool rather than throwing** (§7). A failed write is
/// a friendly Persian message on the screen, never a stack trace or a raw
/// exception string in front of the user; the detail goes through [AppLog] and
/// carries no amount, no name and no identifier.
///
/// **`PaymentNotAccepted` is not treated as a special case here**, and that is
/// deliberate. The repository is the authority on which invoices may take a
/// payment (D-013's shape, applied to payments): a draft is not yet a claim on
/// anyone and a cancelled invoice is not one any more. The screen hides the
/// control for both and explains why, so a user cannot reach the refusal
/// through the UI — but a deep link, a second window or a future sync path can,
/// and when they do the write fails cleanly rather than being prevented by a
/// widget that happened to be on screen.
final class InvoicePaymentsProvider
    extends $NotifierProvider<InvoicePayments, void> {
  /// The two payment writes, and nothing else.
  ///
  /// **The screen never touches a repository** (§3). This is the whole of the
  /// widget-facing surface for recording and removing a payment, and it is
  /// deliberately thin: the derived status is recomputed inside the repository's
  /// own transaction (§6), so there is no state to keep here and nothing to
  /// invalidate — `invoiceDetailProvider` is a live query and the recomputed row
  /// arrives on its own.
  ///
  /// **Both methods return a bool rather than throwing** (§7). A failed write is
  /// a friendly Persian message on the screen, never a stack trace or a raw
  /// exception string in front of the user; the detail goes through [AppLog] and
  /// carries no amount, no name and no identifier.
  ///
  /// **`PaymentNotAccepted` is not treated as a special case here**, and that is
  /// deliberate. The repository is the authority on which invoices may take a
  /// payment (D-013's shape, applied to payments): a draft is not yet a claim on
  /// anyone and a cancelled invoice is not one any more. The screen hides the
  /// control for both and explains why, so a user cannot reach the refusal
  /// through the UI — but a deep link, a second window or a future sync path can,
  /// and when they do the write fails cleanly rather than being prevented by a
  /// widget that happened to be on screen.
  InvoicePaymentsProvider._({
    required InvoicePaymentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'invoicePaymentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$invoicePaymentsHash();

  @override
  String toString() {
    return r'invoicePaymentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  InvoicePayments create() => InvoicePayments();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InvoicePaymentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$invoicePaymentsHash() => r'5c714c84a1e13bdae8510d5fdae4d4ef10f5621d';

/// The two payment writes, and nothing else.
///
/// **The screen never touches a repository** (§3). This is the whole of the
/// widget-facing surface for recording and removing a payment, and it is
/// deliberately thin: the derived status is recomputed inside the repository's
/// own transaction (§6), so there is no state to keep here and nothing to
/// invalidate — `invoiceDetailProvider` is a live query and the recomputed row
/// arrives on its own.
///
/// **Both methods return a bool rather than throwing** (§7). A failed write is
/// a friendly Persian message on the screen, never a stack trace or a raw
/// exception string in front of the user; the detail goes through [AppLog] and
/// carries no amount, no name and no identifier.
///
/// **`PaymentNotAccepted` is not treated as a special case here**, and that is
/// deliberate. The repository is the authority on which invoices may take a
/// payment (D-013's shape, applied to payments): a draft is not yet a claim on
/// anyone and a cancelled invoice is not one any more. The screen hides the
/// control for both and explains why, so a user cannot reach the refusal
/// through the UI — but a deep link, a second window or a future sync path can,
/// and when they do the write fails cleanly rather than being prevented by a
/// widget that happened to be on screen.

final class InvoicePaymentsFamily extends $Family
    with $ClassFamilyOverride<InvoicePayments, void, void, void, String> {
  InvoicePaymentsFamily._()
    : super(
        retry: null,
        name: r'invoicePaymentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The two payment writes, and nothing else.
  ///
  /// **The screen never touches a repository** (§3). This is the whole of the
  /// widget-facing surface for recording and removing a payment, and it is
  /// deliberately thin: the derived status is recomputed inside the repository's
  /// own transaction (§6), so there is no state to keep here and nothing to
  /// invalidate — `invoiceDetailProvider` is a live query and the recomputed row
  /// arrives on its own.
  ///
  /// **Both methods return a bool rather than throwing** (§7). A failed write is
  /// a friendly Persian message on the screen, never a stack trace or a raw
  /// exception string in front of the user; the detail goes through [AppLog] and
  /// carries no amount, no name and no identifier.
  ///
  /// **`PaymentNotAccepted` is not treated as a special case here**, and that is
  /// deliberate. The repository is the authority on which invoices may take a
  /// payment (D-013's shape, applied to payments): a draft is not yet a claim on
  /// anyone and a cancelled invoice is not one any more. The screen hides the
  /// control for both and explains why, so a user cannot reach the refusal
  /// through the UI — but a deep link, a second window or a future sync path can,
  /// and when they do the write fails cleanly rather than being prevented by a
  /// widget that happened to be on screen.

  InvoicePaymentsProvider call(String invoiceId) =>
      InvoicePaymentsProvider._(argument: invoiceId, from: this);

  @override
  String toString() => r'invoicePaymentsProvider';
}

/// The two payment writes, and nothing else.
///
/// **The screen never touches a repository** (§3). This is the whole of the
/// widget-facing surface for recording and removing a payment, and it is
/// deliberately thin: the derived status is recomputed inside the repository's
/// own transaction (§6), so there is no state to keep here and nothing to
/// invalidate — `invoiceDetailProvider` is a live query and the recomputed row
/// arrives on its own.
///
/// **Both methods return a bool rather than throwing** (§7). A failed write is
/// a friendly Persian message on the screen, never a stack trace or a raw
/// exception string in front of the user; the detail goes through [AppLog] and
/// carries no amount, no name and no identifier.
///
/// **`PaymentNotAccepted` is not treated as a special case here**, and that is
/// deliberate. The repository is the authority on which invoices may take a
/// payment (D-013's shape, applied to payments): a draft is not yet a claim on
/// anyone and a cancelled invoice is not one any more. The screen hides the
/// control for both and explains why, so a user cannot reach the refusal
/// through the UI — but a deep link, a second window or a future sync path can,
/// and when they do the write fails cleanly rather than being prevented by a
/// widget that happened to be on screen.

abstract class _$InvoicePayments extends $Notifier<void> {
  late final _$args = ref.$arg as String;
  String get invoiceId => _$args;

  void build(String invoiceId);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
