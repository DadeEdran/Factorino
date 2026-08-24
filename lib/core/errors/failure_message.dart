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
    _ => FailureMessage(
      title: strings.errorGenericTitle,
      body: strings.errorGenericBody,
    ),
  };
}
