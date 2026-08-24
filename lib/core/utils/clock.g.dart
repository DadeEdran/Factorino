// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The instant the application treats as "now".
///
/// A provider rather than a bare `DateTime.now()` at each call site, for one
/// reason that is not testing convenience: **two readings of the clock inside
/// one frame can straddle midnight.** The dashboard resolves a Jalali month
/// from now, and the invoice list decides which invoices are overdue from now;
/// if those were separate readings, a tile could report Shahrivar while the
/// list beneath it aged an invoice into Mehr. One value, read once, keeps every
/// derived thing on screen internally consistent.
///
/// **It does not tick.** Resolved once and kept, so a Jalali month boundary or
/// a due date crossing midnight while the app sits open does not update until
/// the next launch or an explicit `invalidate`. That is a deliberate limit
/// rather than an oversight: a clock that rebuilt every screen showing a date
/// would be a timer running for the life of the process to fix a wrong figure
/// nobody is looking at. If a later phase needs a live boundary, it can
/// invalidate this provider on resume — which is one call, in one place,
/// precisely because the reading is not scattered.
///
/// UTC, like every instant in this application (D-005). Jalali conversion
/// applies the Iran offset itself.

@ProviderFor(now)
final nowProvider = NowProvider._();

/// The instant the application treats as "now".
///
/// A provider rather than a bare `DateTime.now()` at each call site, for one
/// reason that is not testing convenience: **two readings of the clock inside
/// one frame can straddle midnight.** The dashboard resolves a Jalali month
/// from now, and the invoice list decides which invoices are overdue from now;
/// if those were separate readings, a tile could report Shahrivar while the
/// list beneath it aged an invoice into Mehr. One value, read once, keeps every
/// derived thing on screen internally consistent.
///
/// **It does not tick.** Resolved once and kept, so a Jalali month boundary or
/// a due date crossing midnight while the app sits open does not update until
/// the next launch or an explicit `invalidate`. That is a deliberate limit
/// rather than an oversight: a clock that rebuilt every screen showing a date
/// would be a timer running for the life of the process to fix a wrong figure
/// nobody is looking at. If a later phase needs a live boundary, it can
/// invalidate this provider on resume — which is one call, in one place,
/// precisely because the reading is not scattered.
///
/// UTC, like every instant in this application (D-005). Jalali conversion
/// applies the Iran offset itself.

final class NowProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// The instant the application treats as "now".
  ///
  /// A provider rather than a bare `DateTime.now()` at each call site, for one
  /// reason that is not testing convenience: **two readings of the clock inside
  /// one frame can straddle midnight.** The dashboard resolves a Jalali month
  /// from now, and the invoice list decides which invoices are overdue from now;
  /// if those were separate readings, a tile could report Shahrivar while the
  /// list beneath it aged an invoice into Mehr. One value, read once, keeps every
  /// derived thing on screen internally consistent.
  ///
  /// **It does not tick.** Resolved once and kept, so a Jalali month boundary or
  /// a due date crossing midnight while the app sits open does not update until
  /// the next launch or an explicit `invalidate`. That is a deliberate limit
  /// rather than an oversight: a clock that rebuilt every screen showing a date
  /// would be a timer running for the life of the process to fix a wrong figure
  /// nobody is looking at. If a later phase needs a live boundary, it can
  /// invalidate this provider on resume — which is one call, in one place,
  /// precisely because the reading is not scattered.
  ///
  /// UTC, like every instant in this application (D-005). Jalali conversion
  /// applies the Iran offset itself.
  NowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nowHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return now(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$nowHash() => r'957d213b3f6ccb8e4f132467416984c14cb0f66e';
