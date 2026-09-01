import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/security/app_log.dart';
import '../../../data/backup/backup_service.dart';
import '../../../data/providers.dart';

part 'backup_controller.g.dart';

/// What a backup attempt ended as.
///
/// A sealed result rather than an exception, for the reason `InvoicePayments`
/// returns a bool: a failed backup is a friendly Persian message, never a
/// stack trace in front of the user (§7). It carries the *error object* rather
/// than a message, so the copy stays in `describeFailure` where every other
/// failure's copy lives.
sealed class BackupOutcome {
  const BackupOutcome();
}

class BackupSucceeded extends BackupOutcome {
  const BackupSucceeded(this.summary);
  final BackupSummary summary;
}

/// The user dismissed the file picker.
///
/// **Not a failure and not shown as one.** Backing out of a save dialog is an
/// ordinary thing to do, and an error toast for it would teach the user that
/// the app complains when they change their mind.
class BackupCancelled extends BackupOutcome {
  const BackupCancelled();
}

class BackupFailed extends BackupOutcome {
  const BackupFailed(this.error);
  final Object error;
}

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
@riverpod
class BackupController extends _$BackupController {
  @override
  void build() {}

  /// Builds a container keyed by [passphrase] and offers it to the user.
  ///
  /// `markBackedUp` runs **only after the file has actually been delivered**,
  /// not after it was written. A reminder that reset itself when the user
  /// opened the save dialog and thought better of it would be worse than no
  /// reminder: it would say a backup exists when none does.
  Future<BackupOutcome> export({
    required String passphrase,
    required String suggestedName,
  }) async {
    // The write outlives the sheet that started it (D-045).
    final link = ref.keepAlive();
    File? working;
    try {
      working = await _workingFile('export');

      final BackupSummary summary = await ref
          .read(backupServiceProvider)
          .exportTo(file: working, passphrase: passphrase);

      final bool delivered = await ref
          .read(backupFileGatewayProvider)
          .deliver(source: working, suggestedName: suggestedName);

      if (!delivered) return const BackupCancelled();

      await ref.read(settingsRepositoryProvider).markBackedUp(DateTime.now());
      return BackupSucceeded(summary);
    } on Object catch (error, stackTrace) {
      // No passphrase, no path, no row counts: nothing about a backup is
      // logged (D-069). The scope is enough to find the call site.
      AppLog.error(
        () => 'exporting a backup failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'backup',
      );
      return BackupFailed(error);
    } finally {
      if (working != null) _discard(working);
      link.close();
    }
  }

  /// Asks the user for a file and copies it into app-private storage.
  ///
  /// Returns the local copy, or null if the user cancelled. Split from
  /// [inspect] and [restore] because the password is asked for **after** the
  /// file is chosen, and because `sqlite3` cannot open a content URI (D-071).
  Future<File?> pickFile() async {
    final link = ref.keepAlive();
    try {
      final File destination = await _workingFile('import');
      final bool received = await ref
          .read(backupFileGatewayProvider)
          .receive(destination: destination);

      if (!received) {
        _discard(destination);
        return null;
      }
      return destination;
    } on Object catch (error, stackTrace) {
      AppLog.error(
        () => 'choosing a backup file failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'backup',
      );
      return null;
    } finally {
      link.close();
    }
  }

  /// Reads what [file] holds, without touching live data.
  ///
  /// Every refusal a restore can raise is raised here, so the confirmation the
  /// user is about to be shown describes a backup already proved readable.
  Future<BackupOutcome> inspect({
    required File file,
    required String passphrase,
  }) async {
    final link = ref.keepAlive();
    try {
      return BackupSucceeded(
        await ref
            .read(backupServiceProvider)
            .inspect(file: file, passphrase: passphrase),
      );
    } on Object catch (error, stackTrace) {
      AppLog.error(
        () => 'inspecting a backup failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'backup',
      );
      return BackupFailed(error);
    } finally {
      link.close();
    }
  }

  /// **Replaces** the live database with [file]. Not a merge.
  Future<BackupOutcome> restore({
    required File file,
    required String passphrase,
  }) async {
    final link = ref.keepAlive();
    try {
      return BackupSucceeded(
        await ref
            .read(backupServiceProvider)
            .importFrom(file: file, passphrase: passphrase),
      );
    } on Object catch (error, stackTrace) {
      AppLog.error(
        () => 'restoring a backup failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'backup',
      );
      return BackupFailed(error);
    } finally {
      _discard(file);
      link.close();
    }
  }

  Future<File> _workingFile(String kind) async {
    final Directory support = await getApplicationSupportDirectory();
    return File('${support.path}${Platform.pathSeparator}$kind.working');
  }

  void _discard(File file) {
    for (final String path in <String>[
      file.path,
      '${file.path}-wal',
      '${file.path}-shm',
    ]) {
      final File f = File(path);
      if (f.existsSync()) f.deleteSync();
    }
  }
}
