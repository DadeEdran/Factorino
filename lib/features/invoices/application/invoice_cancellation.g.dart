// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_cancellation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The one write cancellation needs, and nothing else.
///
/// **The screen never touches a repository** (§3). Like `InvoicePayments` this
/// is deliberately thin: `cancel` is a status write the repository performs
/// inside its own transaction, and `invoiceDetailProvider` is a live query — so
/// the badge, the payments card and the summary all follow the row on their
/// own. There is no state to hold here and nothing to invalidate.
///
/// **It returns a bool rather than throwing** (§7). A failed write is a
/// friendly Persian line on the screen, never a stack trace or a raw exception
/// string; the detail goes through [AppLog] and carries no amount, no name and
/// no identifier.
///
/// **`InvoiceNotCancellable` is not a special case here**, on the precedent
/// `InvoicePayments` set for `PaymentNotAccepted`. The repository is the
/// authority on which invoices may be cancelled — a draft is withdrawn by
/// deleting it, and an invoice already cancelled has nothing left to cancel.
/// The screen omits the action for both, so a user cannot reach the refusal
/// through the UI; a deep link, a second window or a future sync path can, and
/// when they do the write fails cleanly rather than being prevented by a widget
/// that happened to be on screen.

@ProviderFor(InvoiceCancellation)
final invoiceCancellationProvider = InvoiceCancellationFamily._();

/// The one write cancellation needs, and nothing else.
///
/// **The screen never touches a repository** (§3). Like `InvoicePayments` this
/// is deliberately thin: `cancel` is a status write the repository performs
/// inside its own transaction, and `invoiceDetailProvider` is a live query — so
/// the badge, the payments card and the summary all follow the row on their
/// own. There is no state to hold here and nothing to invalidate.
///
/// **It returns a bool rather than throwing** (§7). A failed write is a
/// friendly Persian line on the screen, never a stack trace or a raw exception
/// string; the detail goes through [AppLog] and carries no amount, no name and
/// no identifier.
///
/// **`InvoiceNotCancellable` is not a special case here**, on the precedent
/// `InvoicePayments` set for `PaymentNotAccepted`. The repository is the
/// authority on which invoices may be cancelled — a draft is withdrawn by
/// deleting it, and an invoice already cancelled has nothing left to cancel.
/// The screen omits the action for both, so a user cannot reach the refusal
/// through the UI; a deep link, a second window or a future sync path can, and
/// when they do the write fails cleanly rather than being prevented by a widget
/// that happened to be on screen.
final class InvoiceCancellationProvider
    extends $NotifierProvider<InvoiceCancellation, void> {
  /// The one write cancellation needs, and nothing else.
  ///
  /// **The screen never touches a repository** (§3). Like `InvoicePayments` this
  /// is deliberately thin: `cancel` is a status write the repository performs
  /// inside its own transaction, and `invoiceDetailProvider` is a live query — so
  /// the badge, the payments card and the summary all follow the row on their
  /// own. There is no state to hold here and nothing to invalidate.
  ///
  /// **It returns a bool rather than throwing** (§7). A failed write is a
  /// friendly Persian line on the screen, never a stack trace or a raw exception
  /// string; the detail goes through [AppLog] and carries no amount, no name and
  /// no identifier.
  ///
  /// **`InvoiceNotCancellable` is not a special case here**, on the precedent
  /// `InvoicePayments` set for `PaymentNotAccepted`. The repository is the
  /// authority on which invoices may be cancelled — a draft is withdrawn by
  /// deleting it, and an invoice already cancelled has nothing left to cancel.
  /// The screen omits the action for both, so a user cannot reach the refusal
  /// through the UI; a deep link, a second window or a future sync path can, and
  /// when they do the write fails cleanly rather than being prevented by a widget
  /// that happened to be on screen.
  InvoiceCancellationProvider._({
    required InvoiceCancellationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'invoiceCancellationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$invoiceCancellationHash();

  @override
  String toString() {
    return r'invoiceCancellationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  InvoiceCancellation create() => InvoiceCancellation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InvoiceCancellationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$invoiceCancellationHash() =>
    r'c0501774a1147945c994368451466c933c7d95ba';

/// The one write cancellation needs, and nothing else.
///
/// **The screen never touches a repository** (§3). Like `InvoicePayments` this
/// is deliberately thin: `cancel` is a status write the repository performs
/// inside its own transaction, and `invoiceDetailProvider` is a live query — so
/// the badge, the payments card and the summary all follow the row on their
/// own. There is no state to hold here and nothing to invalidate.
///
/// **It returns a bool rather than throwing** (§7). A failed write is a
/// friendly Persian line on the screen, never a stack trace or a raw exception
/// string; the detail goes through [AppLog] and carries no amount, no name and
/// no identifier.
///
/// **`InvoiceNotCancellable` is not a special case here**, on the precedent
/// `InvoicePayments` set for `PaymentNotAccepted`. The repository is the
/// authority on which invoices may be cancelled — a draft is withdrawn by
/// deleting it, and an invoice already cancelled has nothing left to cancel.
/// The screen omits the action for both, so a user cannot reach the refusal
/// through the UI; a deep link, a second window or a future sync path can, and
/// when they do the write fails cleanly rather than being prevented by a widget
/// that happened to be on screen.

final class InvoiceCancellationFamily extends $Family
    with $ClassFamilyOverride<InvoiceCancellation, void, void, void, String> {
  InvoiceCancellationFamily._()
    : super(
        retry: null,
        name: r'invoiceCancellationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The one write cancellation needs, and nothing else.
  ///
  /// **The screen never touches a repository** (§3). Like `InvoicePayments` this
  /// is deliberately thin: `cancel` is a status write the repository performs
  /// inside its own transaction, and `invoiceDetailProvider` is a live query — so
  /// the badge, the payments card and the summary all follow the row on their
  /// own. There is no state to hold here and nothing to invalidate.
  ///
  /// **It returns a bool rather than throwing** (§7). A failed write is a
  /// friendly Persian line on the screen, never a stack trace or a raw exception
  /// string; the detail goes through [AppLog] and carries no amount, no name and
  /// no identifier.
  ///
  /// **`InvoiceNotCancellable` is not a special case here**, on the precedent
  /// `InvoicePayments` set for `PaymentNotAccepted`. The repository is the
  /// authority on which invoices may be cancelled — a draft is withdrawn by
  /// deleting it, and an invoice already cancelled has nothing left to cancel.
  /// The screen omits the action for both, so a user cannot reach the refusal
  /// through the UI; a deep link, a second window or a future sync path can, and
  /// when they do the write fails cleanly rather than being prevented by a widget
  /// that happened to be on screen.

  InvoiceCancellationProvider call(String invoiceId) =>
      InvoiceCancellationProvider._(argument: invoiceId, from: this);

  @override
  String toString() => r'invoiceCancellationProvider';
}

/// The one write cancellation needs, and nothing else.
///
/// **The screen never touches a repository** (§3). Like `InvoicePayments` this
/// is deliberately thin: `cancel` is a status write the repository performs
/// inside its own transaction, and `invoiceDetailProvider` is a live query — so
/// the badge, the payments card and the summary all follow the row on their
/// own. There is no state to hold here and nothing to invalidate.
///
/// **It returns a bool rather than throwing** (§7). A failed write is a
/// friendly Persian line on the screen, never a stack trace or a raw exception
/// string; the detail goes through [AppLog] and carries no amount, no name and
/// no identifier.
///
/// **`InvoiceNotCancellable` is not a special case here**, on the precedent
/// `InvoicePayments` set for `PaymentNotAccepted`. The repository is the
/// authority on which invoices may be cancelled — a draft is withdrawn by
/// deleting it, and an invoice already cancelled has nothing left to cancel.
/// The screen omits the action for both, so a user cannot reach the refusal
/// through the UI; a deep link, a second window or a future sync path can, and
/// when they do the write fails cleanly rather than being prevented by a widget
/// that happened to be on screen.

abstract class _$InvoiceCancellation extends $Notifier<void> {
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
