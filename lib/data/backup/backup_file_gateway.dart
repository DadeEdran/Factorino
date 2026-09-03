import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

/// Moves a finished backup file between app-private storage and a location the
/// user chose (D-071).
///
/// Deliberately the whole of its own layer. `BackupService` produces and
/// consumes a **path in app-private storage** and knows nothing about pickers;
/// this knows nothing about SQLite. Three reasons, and the third is why the
/// seam is here rather than inside the service:
///
/// 1. `sqlite3` needs a real filesystem path, and a SAF content URI is not one.
/// 2. `BackupService` stays testable on the Dart VM with no plugins.
/// 3. **Phase 7 inherits this.** A PDF has the same problem, and D-068's
///    ordering was chosen on exactly that.
abstract interface class BackupFileGateway {
  /// Offers [source] to the user to save where they choose.
  ///
  /// Returns `null` if the user cancelled — a cancellation is an ordinary
  /// outcome, not an error, and must not be reported as a failed backup.
  ///
  /// Returns where it landed otherwise, which is what lets a caller offer to
  /// open it. The caller does not have to use that, and the backup path does
  /// not: an encrypted container is not a thing to open.
  Future<DeliveredFile?> deliver({
    required File source,
    required String suggestedName,
  });

  /// Asks the user for a backup file and copies it to [destination].
  ///
  /// Returns `false` if the user cancelled. The bytes are copied into
  /// app-private storage because the file must be **opened as a database**,
  /// which a content URI cannot be.
  Future<bool> receive({required File destination});
}

/// Where a delivered file ended up on the user's own device.
///
/// **Not a `File`, and deliberately not a path**, because on Android it is not
/// one: the save dialog is SAF's `ACTION_CREATE_DOCUMENT` and what comes back
/// is a `content://` URI, which nothing in `dart:io` can open. On Windows it is
/// an ordinary filesystem path. The two are the same *kind* of thing — a handle
/// the platform can act on — and this type says exactly that and no more.
///
/// It exists so the application can offer to **open** what it just saved
/// without pretending to know what the string is. `SavedFileOpener` is the only
/// thing that interprets it, and it does so per platform.
class DeliveredFile {
  const DeliveredFile(this.location);

  /// The platform's own handle: a filesystem path on Windows, a SAF content
  /// URI on Android.
  ///
  /// **Never logged and never shown to the user** (§7). A path carries the
  /// user's account name and the folder structure of their device.
  final String location;

  /// Deliberately says nothing. See the note on [location].
  @override
  String toString() => 'DeliveredFile(${location.length} chars)';
}

/// The extension a Factorino backup carries.
///
/// Not `.db`: a backup is not a database the user should be tempted to open
/// with something else, and the distinct extension is what lets the import
/// picker filter sensibly.
const String kBackupFileExtension = 'factorino';

class PlatformBackupFileGateway implements BackupFileGateway {
  const PlatformBackupFileGateway();

  @override
  Future<DeliveredFile?> deliver({
    required File source,
    required String suggestedName,
  }) async {
    if (Platform.isAndroid) {
      // `file_selector_android` implements no `getSaveLocation` (D-071,
      // verified in its source), so the save side of Android is this package
      // and only this package. It opens SAF's ACTION_CREATE_DOCUMENT, so the
      // file goes where the user picked **on the device** -- no share intent,
      // and therefore no third-party application receiving the entire customer
      // and invoice database.
      // The SAF content URI of the document the user created, or null if they
      // backed out of the dialog.
      final String? saved = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: source.path,
          fileName: suggestedName,
        ),
      );
      return saved == null ? null : DeliveredFile(saved);
    }

    final FileSaveLocation? location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: <XTypeGroup>[_typeGroup],
    );
    if (location == null) return null;

    await source.copy(location.path);
    return DeliveredFile(location.path);
  }

  @override
  Future<bool> receive({required File destination}) async {
    final XFile? picked = await openFile(
      acceptedTypeGroups: <XTypeGroup>[_typeGroup],
    );
    if (picked == null) return false;

    await destination.writeAsBytes(await picked.readAsBytes(), flush: true);
    return true;
  }

  static const XTypeGroup _typeGroup = XTypeGroup(
    label: 'Factorino backup',
    extensions: <String>[kBackupFileExtension],
  );
}
