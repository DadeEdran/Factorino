import 'dart:io';

import '../../core/security/app_log.dart';
import 'backup_file_gateway.dart';

/// Hands a file the user has just saved to whatever opens it on their device.
///
/// **The counterpart to [BackupFileGateway], and deliberately a separate
/// interface.** The gateway's whole job is getting a file *out* of app-private
/// storage and into a place the user chose; this one does nothing to the file
/// at all, and can only act on a [DeliveredFile] the gateway already produced.
/// Keeping them apart is what stops "open it" from becoming a way to reach the
/// filesystem generally: there is no path parameter here to pass anything else
/// through.
///
/// ## What this does and does not do to §7's threat model
///
/// D-071's property was that the application never sends a customer's records
/// to another application: the save dialog writes where the user pointed it,
/// and there is no share intent. That property is unchanged. **This is not a
/// share.** It acts only when the user taps «باز کردن» on a message about a
/// file they have just deliberately saved, on a handle they themselves chose
/// the destination of, and it opens it with the device's own viewer rather than
/// offering it to a chooser of applications.
///
/// What it does add, honestly stated: on Android the document is read by
/// whichever application handles PDFs, which is a third-party application
/// receiving a page carrying a customer's کد ملی. That is what "open this
/// document" means on a phone and there is no version of it that does not. The
/// difference from a share intent is that it happens once, on an explicit tap,
/// on a file that already exists at a location the user picked — not as a step
/// on the way to saving. See D-091.
abstract interface class SavedFileOpener {
  /// Asks the platform to open [file]. Returns whether it could.
  ///
  /// `false` is an ordinary answer — a phone with no PDF viewer installed is a
  /// real phone — and never an exception the caller has to catch.
  Future<bool> open(DeliveredFile file);
}

/// The real one.
///
/// Two platforms, two mechanisms, because a [DeliveredFile] is two different
/// things (see its own note).
class PlatformSavedFileOpener implements SavedFileOpener {
  const PlatformSavedFileOpener();

  /// A method channel implemented in this application's own `MainActivity`
  /// rather than a package, and that is a dependency decision rather than
  /// laziness: every package that opens a file wants a `FileProvider` and a
  /// path, and what SAF hands back is a URI the application already holds a
  /// grant for. `ACTION_VIEW` on that URI is a dozen lines of Kotlin and pulls
  /// in nothing. See D-091.
  ///
  /// [kDocumentsChannel] is the same channel the save goes out on, and they are
  /// deliberately one: since D-103 the save is first-party too, and nothing on
  /// this channel can be asked to open a file it did not itself write.
  @override
  Future<bool> open(DeliveredFile file) async {
    try {
      if (Platform.isAndroid) {
        final bool? opened = await kDocumentsChannel.invokeMethod<bool>(
          'openUri',
          <String, String>{'uri': file.location},
        );
        return opened ?? false;
      }

      if (Platform.isWindows) {
        // `explorer.exe <path>` opens a file with its registered handler. Not
        // `cmd /c start`, which would put the path through a shell that treats
        // `&` and `^` as syntax — a filename the user is free to choose.
        // Arguments here are passed to the process directly, never parsed.
        //
        // **Its exit code is not the answer.** `explorer.exe` returns 1 on a
        // perfectly successful open, so reading it would report failure every
        // time. Starting the process without an error is what "could open it"
        // means on Windows.
        await Process.start('explorer.exe', <String>[
          file.location,
        ], runInShell: false);
        return true;
      }

      return false;
    } on Object catch (error, stackTrace) {
      // No path and no URI: §7 keeps the user's directory structure out of
      // logs as firmly as it keeps their customers out.
      AppLog.error(
        () => 'opening a saved file failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'document',
      );
      return false;
    }
  }
}
