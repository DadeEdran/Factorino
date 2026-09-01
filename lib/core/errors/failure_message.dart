import '../../data/backup/backup_service.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../localization/generated/app_strings.dart';

/// What the user is told when something fails.
///
/// the project spec: *"User-facing errors are friendly Persian messages. Never
/// surface a stack trace, SQL statement, file path, or raw exception string to
/// the user."*
///
/// The rule is easy to state and easy to break, because the convenient thing to
/// write is `Text('$error')` and it looks fine in every test where the error is
/// a `StateError('not found')`. It stops looking fine when the error is a
/// `SqliteException` carrying the statement and the database path, on a user's
/// phone, in Persian-language UI, in Latin script.
///
/// So the only way an error reaches the screen is through this function, which
/// cannot return anything but ARB copy.
class FailureMessage {
  const FailureMessage({required this.title, required this.body});

  final String title;
  final String body;
}

/// Maps [error] to Persian copy.
///
/// Domain exceptions the user can act on get their own message; everything else
/// gets the generic one. That fallback is deliberate rather than lazy: an
/// exception this function does not recognise is by definition one nobody has
/// decided how to explain, and inventing an explanation from its class name
/// would be worse than admitting the app could not do the thing.
///
/// The raw error is not lost — it goes to [AppLog] at the point the failure is
/// displayed, where it is scrubbed and stripped from release builds.
FailureMessage describeFailure(Object error, AppStrings strings) {
  return switch (error) {
    InvoiceNotEditable() => FailureMessage(
      title: strings.errorInvoiceNotEditableTitle,
      body: strings.errorInvoiceNotEditableBody,
    ),
    PaymentNotAccepted() => FailureMessage(
      title: strings.errorPaymentNotAcceptedTitle,
      body: strings.errorPaymentNotAcceptedBody,
    ),
    // Each backup refusal gets its own copy rather than sharing one. "Could
    // not restore" tells a user nothing about whether to retype the password,
    // pick a different file, or update the app -- and every one of these
    // bodies also states that the existing data is untouched, because that is
    // the thing the user most needs to know and cannot check for themselves.
    BackupExportFailure() => FailureMessage(
      title: strings.errorBackupExportFailedTitle,
      body: strings.errorBackupExportFailedBody,
    ),
    BackupImportFailure(problem: BackupImportProblem.cannotOpen) =>
      FailureMessage(
        title: strings.errorBackupCannotOpenTitle,
        body: strings.errorBackupCannotOpenBody,
      ),
    BackupImportFailure(problem: BackupImportProblem.notABackup) =>
      FailureMessage(
        title: strings.errorBackupNotABackupTitle,
        body: strings.errorBackupNotABackupBody,
      ),
    BackupImportFailure(problem: BackupImportProblem.fromNewerVersion) =>
      FailureMessage(
        title: strings.errorBackupFromNewerVersionTitle,
        body: strings.errorBackupFromNewerVersionBody,
      ),
    BackupImportFailure(problem: BackupImportProblem.countMismatch) =>
      FailureMessage(
        title: strings.errorBackupCountMismatchTitle,
        body: strings.errorBackupCountMismatchBody,
      ),
    BackupImportFailure(problem: BackupImportProblem.restoreFailed) =>
      FailureMessage(
        title: strings.errorBackupRestoreFailedTitle,
        body: strings.errorBackupRestoreFailedBody,
      ),
    _ => FailureMessage(
      title: strings.errorGenericTitle,
      body: strings.errorGenericBody,
    ),
  };
}
