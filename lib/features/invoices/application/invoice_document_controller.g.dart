// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_document_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The document fonts, loaded once for the life of the app.
///
/// `keepAlive` because parsing two TTFs and deriving [FontGlyphSafety] from the
/// regular face is real work to repeat every time someone taps a menu item, and
/// the bytes never change. The safety analysis in particular walks the whole
/// glyph table (D-073).
///
/// Loaded from `rootBundle` rather than from the filesystem so the same asset
/// the screen renders with is the one the page embeds — the two must not be
/// able to drift, since the safety analysis is only true of the file actually
/// embedded.

@ProviderFor(documentTypeface)
final documentTypefaceProvider = DocumentTypefaceProvider._();

/// The document fonts, loaded once for the life of the app.
///
/// `keepAlive` because parsing two TTFs and deriving [FontGlyphSafety] from the
/// regular face is real work to repeat every time someone taps a menu item, and
/// the bytes never change. The safety analysis in particular walks the whole
/// glyph table (D-073).
///
/// Loaded from `rootBundle` rather than from the filesystem so the same asset
/// the screen renders with is the one the page embeds — the two must not be
/// able to drift, since the safety analysis is only true of the file actually
/// embedded.

final class DocumentTypefaceProvider
    extends
        $FunctionalProvider<
          AsyncValue<DocumentTypeface>,
          DocumentTypeface,
          FutureOr<DocumentTypeface>
        >
    with $FutureModifier<DocumentTypeface>, $FutureProvider<DocumentTypeface> {
  /// The document fonts, loaded once for the life of the app.
  ///
  /// `keepAlive` because parsing two TTFs and deriving [FontGlyphSafety] from the
  /// regular face is real work to repeat every time someone taps a menu item, and
  /// the bytes never change. The safety analysis in particular walks the whole
  /// glyph table (D-073).
  ///
  /// Loaded from `rootBundle` rather than from the filesystem so the same asset
  /// the screen renders with is the one the page embeds — the two must not be
  /// able to drift, since the safety analysis is only true of the file actually
  /// embedded.
  DocumentTypefaceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentTypefaceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentTypefaceHash();

  @$internal
  @override
  $FutureProviderElement<DocumentTypeface> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DocumentTypeface> create(Ref ref) {
    return documentTypeface(ref);
  }
}

String _$documentTypefaceHash() => r'e3b3d9c5f21c68745d861fa318ad93182a266b47';

/// Generates an invoice PDF and hands it to the user to save.
///
/// **The whole widget-facing surface for the document** (§3). The screen does
/// not touch the generator, the typeface, the gateway or a repository.
///
/// ## Where the file lands, and who deletes it — the §7 answer
///
/// A generated invoice carries the customer's full record — name, کد ملی, کد
/// اقتصادی, telephone, نشانی — beside the financial detail of a transaction.
/// After a backup it is **the most sensitive artifact this application
/// produces**, and unlike a backup it is not encrypted, because a document the
/// customer has to be able to open cannot be.
///
/// So it follows the backup's shape exactly (D-071), and for the same reasons:
///
/// 1. **It is written to app-private storage**, never to a shared directory.
///    On Android that is the application's own `files` directory, unreadable by
///    other apps; on Windows it is under `%APPDATA%`. It is never written to
///    `Downloads`, to external storage, or beside the executable.
/// 2. **It leaves only through the gateway**, which opens SAF's
///    `ACTION_CREATE_DOCUMENT` on Android and the native save dialog on
///    desktop. The user picks the destination on their own device. There is no
///    share intent, so no third-party application receives a page carrying a
///    customer's national ID.
/// 3. **Every path deletes the working file**, in a `finally` — delivered,
///    cancelled, or failed. This is the part that would rot quietly: a
///    cancelled export that left the file behind would accumulate unencrypted
///    customer records inside the app's own directory, and nothing in the UI
///    would ever mention them. The app-private directory is not world-readable,
///    but "not readable by other apps" is not a reason to keep an artifact
///    nobody asked for.
///
/// **What is deliberately not claimed.** Once the user picks a destination the
/// file is theirs and its lifetime is theirs — if they save it to a synced
/// folder it will be synced. That is the point of a save dialog, and §7's
/// threat model already excludes a compromised OS. What this owns is that the
/// application itself leaves no copy behind.

@ProviderFor(InvoiceDocumentController)
final invoiceDocumentControllerProvider = InvoiceDocumentControllerProvider._();

/// Generates an invoice PDF and hands it to the user to save.
///
/// **The whole widget-facing surface for the document** (§3). The screen does
/// not touch the generator, the typeface, the gateway or a repository.
///
/// ## Where the file lands, and who deletes it — the §7 answer
///
/// A generated invoice carries the customer's full record — name, کد ملی, کد
/// اقتصادی, telephone, نشانی — beside the financial detail of a transaction.
/// After a backup it is **the most sensitive artifact this application
/// produces**, and unlike a backup it is not encrypted, because a document the
/// customer has to be able to open cannot be.
///
/// So it follows the backup's shape exactly (D-071), and for the same reasons:
///
/// 1. **It is written to app-private storage**, never to a shared directory.
///    On Android that is the application's own `files` directory, unreadable by
///    other apps; on Windows it is under `%APPDATA%`. It is never written to
///    `Downloads`, to external storage, or beside the executable.
/// 2. **It leaves only through the gateway**, which opens SAF's
///    `ACTION_CREATE_DOCUMENT` on Android and the native save dialog on
///    desktop. The user picks the destination on their own device. There is no
///    share intent, so no third-party application receives a page carrying a
///    customer's national ID.
/// 3. **Every path deletes the working file**, in a `finally` — delivered,
///    cancelled, or failed. This is the part that would rot quietly: a
///    cancelled export that left the file behind would accumulate unencrypted
///    customer records inside the app's own directory, and nothing in the UI
///    would ever mention them. The app-private directory is not world-readable,
///    but "not readable by other apps" is not a reason to keep an artifact
///    nobody asked for.
///
/// **What is deliberately not claimed.** Once the user picks a destination the
/// file is theirs and its lifetime is theirs — if they save it to a synced
/// folder it will be synced. That is the point of a save dialog, and §7's
/// threat model already excludes a compromised OS. What this owns is that the
/// application itself leaves no copy behind.
final class InvoiceDocumentControllerProvider
    extends $NotifierProvider<InvoiceDocumentController, void> {
  /// Generates an invoice PDF and hands it to the user to save.
  ///
  /// **The whole widget-facing surface for the document** (§3). The screen does
  /// not touch the generator, the typeface, the gateway or a repository.
  ///
  /// ## Where the file lands, and who deletes it — the §7 answer
  ///
  /// A generated invoice carries the customer's full record — name, کد ملی, کد
  /// اقتصادی, telephone, نشانی — beside the financial detail of a transaction.
  /// After a backup it is **the most sensitive artifact this application
  /// produces**, and unlike a backup it is not encrypted, because a document the
  /// customer has to be able to open cannot be.
  ///
  /// So it follows the backup's shape exactly (D-071), and for the same reasons:
  ///
  /// 1. **It is written to app-private storage**, never to a shared directory.
  ///    On Android that is the application's own `files` directory, unreadable by
  ///    other apps; on Windows it is under `%APPDATA%`. It is never written to
  ///    `Downloads`, to external storage, or beside the executable.
  /// 2. **It leaves only through the gateway**, which opens SAF's
  ///    `ACTION_CREATE_DOCUMENT` on Android and the native save dialog on
  ///    desktop. The user picks the destination on their own device. There is no
  ///    share intent, so no third-party application receives a page carrying a
  ///    customer's national ID.
  /// 3. **Every path deletes the working file**, in a `finally` — delivered,
  ///    cancelled, or failed. This is the part that would rot quietly: a
  ///    cancelled export that left the file behind would accumulate unencrypted
  ///    customer records inside the app's own directory, and nothing in the UI
  ///    would ever mention them. The app-private directory is not world-readable,
  ///    but "not readable by other apps" is not a reason to keep an artifact
  ///    nobody asked for.
  ///
  /// **What is deliberately not claimed.** Once the user picks a destination the
  /// file is theirs and its lifetime is theirs — if they save it to a synced
  /// folder it will be synced. That is the point of a save dialog, and §7's
  /// threat model already excludes a compromised OS. What this owns is that the
  /// application itself leaves no copy behind.
  InvoiceDocumentControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoiceDocumentControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoiceDocumentControllerHash();

  @$internal
  @override
  InvoiceDocumentController create() => InvoiceDocumentController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$invoiceDocumentControllerHash() =>
    r'3c0ad46f41642004826e30db7547215a8690f40c';

/// Generates an invoice PDF and hands it to the user to save.
///
/// **The whole widget-facing surface for the document** (§3). The screen does
/// not touch the generator, the typeface, the gateway or a repository.
///
/// ## Where the file lands, and who deletes it — the §7 answer
///
/// A generated invoice carries the customer's full record — name, کد ملی, کد
/// اقتصادی, telephone, نشانی — beside the financial detail of a transaction.
/// After a backup it is **the most sensitive artifact this application
/// produces**, and unlike a backup it is not encrypted, because a document the
/// customer has to be able to open cannot be.
///
/// So it follows the backup's shape exactly (D-071), and for the same reasons:
///
/// 1. **It is written to app-private storage**, never to a shared directory.
///    On Android that is the application's own `files` directory, unreadable by
///    other apps; on Windows it is under `%APPDATA%`. It is never written to
///    `Downloads`, to external storage, or beside the executable.
/// 2. **It leaves only through the gateway**, which opens SAF's
///    `ACTION_CREATE_DOCUMENT` on Android and the native save dialog on
///    desktop. The user picks the destination on their own device. There is no
///    share intent, so no third-party application receives a page carrying a
///    customer's national ID.
/// 3. **Every path deletes the working file**, in a `finally` — delivered,
///    cancelled, or failed. This is the part that would rot quietly: a
///    cancelled export that left the file behind would accumulate unencrypted
///    customer records inside the app's own directory, and nothing in the UI
///    would ever mention them. The app-private directory is not world-readable,
///    but "not readable by other apps" is not a reason to keep an artifact
///    nobody asked for.
///
/// **What is deliberately not claimed.** Once the user picks a destination the
/// file is theirs and its lifetime is theirs — if they save it to a synced
/// folder it will be synced. That is the point of a save dialog, and §7's
/// threat model already excludes a compromised OS. What this owns is that the
/// application itself leaves no copy behind.

abstract class _$InvoiceDocumentController extends $Notifier<void> {
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
