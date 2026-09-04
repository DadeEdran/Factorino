import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/localization/generated/app_strings.dart';
import '../../../core/pdf/document_typeface.dart';
import '../../../core/security/app_log.dart';
import '../../../data/backup/backup_file_gateway.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/models/invoice_detail.dart';
import '../../../data/providers.dart';
import '../domain/invoice_document_file_name.dart';
import '../document/invoice_document_view.dart';
import '../document/invoice_document_view_builder.dart';
import '../document/pdf_invoice_document_generator.dart';

part 'invoice_document_controller.g.dart';

/// What an export attempt ended as.
///
/// A sealed result rather than a thrown exception or a bare `bool`, for the
/// reason the backup controller uses one: **cancelling is an ordinary
/// outcome**, not a failure, and a user who opened the save dialog and thought
/// better of it must not be told something went wrong.
sealed class InvoiceExportOutcome {
  const InvoiceExportOutcome();
}

/// Saved, where the user chose.
///
/// [hadSeller] is carried out of the render rather than re-derived by the
/// screen, because it is a fact about **the document that was produced** — the
/// settings could change between the render and the message, and the sentence
/// the user reads has to be true of the file they now hold (D-077).
class InvoiceExportSaved extends InvoiceExportOutcome {
  const InvoiceExportSaved({
    required this.hadSeller,
    required this.file,
    this.opened = false,
  });

  final bool hadSeller;

  /// Whether the document was handed to a viewer straight after saving
  /// (D-100).
  ///
  /// A fact about what happened, not a request: the controller attempts it and
  /// reports, so the screen's message describes the file the user is now
  /// looking at rather than promising something that may not have worked. False
  /// on a device with nothing that reads PDFs, which is a real device.
  final bool opened;

  /// Where the user put it, so the message about it can offer to open it.
  ///
  /// Carried rather than re-derived for the same reason [hadSeller] is: it is a
  /// fact about **this** delivery. There is no second way to find it out — on
  /// Android the destination is a SAF URI that exists nowhere else — and a
  /// screen that had to ask the gateway again would be asking a question the
  /// save dialog answered and threw away.
  final DeliveredFile file;
}

/// The user closed the save dialog. Nothing to report and nothing to fix.
class InvoiceExportCancelled extends InvoiceExportOutcome {
  const InvoiceExportCancelled();
}

class InvoiceExportFailed extends InvoiceExportOutcome {
  const InvoiceExportFailed();
}

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
@Riverpod(keepAlive: true)
Future<DocumentTypeface> documentTypeface(Ref ref) async {
  final ByteData regular = await rootBundle.load(
    'assets/fonts/Vazirmatn-Regular.ttf',
  );
  final ByteData bold = await rootBundle.load(
    'assets/fonts/Vazirmatn-Bold.ttf',
  );

  return DocumentTypeface.fromBytes(
    regular: regular.buffer.asUint8List(
      regular.offsetInBytes,
      regular.lengthInBytes,
    ),
    bold: bold.buffer.asUint8List(bold.offsetInBytes, bold.lengthInBytes),
  );
}

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
@riverpod
class InvoiceDocumentController extends _$InvoiceDocumentController {
  @override
  void build() {}

  /// Renders [detail] and offers it to the user to save.
  Future<InvoiceExportOutcome> export({
    required InvoiceDetail detail,
    required AppStrings strings,
  }) async {
    // The render and the save dialog both outlive the menu that started them
    // (D-045): the widget is gone the moment the menu closes.
    final link = ref.keepAlive();
    File? working;
    try {
      final DocumentTypeface typeface = await ref.read(
        documentTypefaceProvider.future,
      );
      // **The repository rather than `appSettingsProvider`**, and not a
      // preference: that provider is a `StreamProvider` and auto-disposes, so a
      // one-shot `read` of its future is created and torn down before the
      // stream emits — *"disposed during loading state, yet no value could be
      // emitted"*. An export wants the settings **as they are at this instant**
      // anyway, not a subscription: the document is a snapshot, and §3 already
      // says a controller talks to a repository.
      final AppSettings settings = await ref
          .read(settingsRepositoryProvider)
          .read();

      // **Wired deliberately**, per the (d) plan: `buildInvoiceDocumentView`
      // defaults `seller` to `SellerIdentity.none`, so a call site that forgets
      // it produces a document with no فروشنده block and no error at all.
      final InvoiceDocumentView view = buildInvoiceDocumentView(
        detail: detail,
        strings: strings,
        boundary: typeface.boundary,
        seller: settings.seller,
        // The same row the screen reads its unit from, so a document says the
        // unit the user was looking at when they asked for it (D-117).
        unit: settings.displayUnit,
      );

      final Uint8List bytes = await PdfInvoiceDocumentGenerator(typeface)
          .render(view);

      working = await _workingFile();
      await working.writeAsBytes(bytes, flush: true);

      final DeliveredFile? delivered = await ref
          .read(backupFileGatewayProvider)
          .deliver(
            source: working,
            // **`DateTime.now()`, deliberately, and not `nowProvider`.** That
            // provider is frozen for the life of the process on purpose (see
            // `core/utils/clock.dart`): it exists so that every *figure on
            // screen* answers against one instant and a dashboard cannot
            // straddle midnight. A file name is not a figure on screen, and it
            // needs the reading that makes two exports different files -- with
            // the frozen clock, every export in a session would propose the
            // same name and D-099 would buy nothing. The backup's own suggested
            // name reads the wall clock for exactly this reason.
            suggestedName: invoiceDocumentFileName(
              detail.invoice,
              DateTime.now().toUtc(),
            ),
          );

      if (delivered == null) return const InvoiceExportCancelled();

      // **Opened straight away, unless the document is missing its seller**
      // (D-100). Saving is a deliberate act aimed at a destination the user
      // picked, and looking at what was just produced is the same intent
      // continuing rather than a new one — so it does not need a second tap.
      //
      // The exception is the case D-077 exists for. An invoice with no
      // فروشنده block is one the user should be *fixing*, and its message
      // carries the «تنظیمات» action that fixes it; launching a viewer over
      // that message would bury the one sentence worth reading.
      final bool hadSeller = view.seller != null;
      final bool opened = hadSeller ? await openSaved(delivered) : false;

      return InvoiceExportSaved(
        hadSeller: hadSeller,
        file: delivered,
        opened: opened,
      );
    } on Object catch (error, stackTrace) {
      // No invoice number, no customer, no amount, no path: §7 keeps all of it
      // out of logs. The scope is enough to find the call site.
      AppLog.error(
        () => 'generating an invoice document failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'document',
      );
      return const InvoiceExportFailed();
    } finally {
      if (working != null && working.existsSync()) working.deleteSync();
      link.close();
    }
  }

  /// Asks the platform to open a document this controller delivered.
  ///
  /// **Here rather than in the widget**, because it is the data layer that
  /// [DeliveredFile] belongs to and §3 keeps a screen away from it — the same
  /// reason the export itself is here. The screen holds the outcome and taps
  /// the action; what a content URI is remains this side of the boundary.
  ///
  /// Returns whether it opened. A phone with nothing that reads PDFs is a real
  /// phone, and the screen says so in Persian rather than failing.
  Future<bool> openSaved(DeliveredFile file) =>
      ref.read(savedFileOpenerProvider).open(file);

  Future<File> _workingFile() async {
    final Directory support = await getApplicationSupportDirectory();
    return File('${support.path}${Platform.pathSeparator}invoice.working.pdf');
  }
}
