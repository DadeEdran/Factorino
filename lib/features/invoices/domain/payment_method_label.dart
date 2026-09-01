import '../../../core/localization/generated/app_strings.dart';
import '../../../data/models/payment_method.dart';

/// The one place a stored [PaymentMethod] becomes Persian.
///
/// On `invoiceStatusLabel`'s precedent: the enum is storage and the label is
/// presentation, and keeping the mapping in one function is what stops the
/// payment sheet and the payment list disagreeing about what `cardTransfer` is
/// called. It also keeps the strings in the localization layer, where §1
/// requires them, rather than in a `switch` inside a widget.
///
/// The enum is stored **as its index** — never reorder it, only append — so a
/// method added here is a new case at the end and nothing already written
/// changes meaning.
String paymentMethodLabel(PaymentMethod method, AppStrings strings) {
  return switch (method) {
    PaymentMethod.cash => strings.paymentMethodCash,
    // Named as people name it rather than as a bank would: «کارت به کارت» is
    // the everyday Iranian transfer and «انتقال بانکی» is not what anyone calls
    // it.
    PaymentMethod.cardTransfer => strings.paymentMethodCardTransfer,
    PaymentMethod.bankTransfer => strings.paymentMethodBankTransfer,
    PaymentMethod.cheque => strings.paymentMethodCheque,
    PaymentMethod.other => strings.paymentMethodOther,
  };
}
