import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_strings.dart';
import '../application/customers_providers.dart';

/// Asks whether to delete [customerId], and does it.
///
/// One function rather than one per screen, because the list and the detail
/// page both offer this and what it promises the user is load-bearing: the
/// Persian copy says the customer leaves the list while the invoices already
/// issued to them stay untouched and keep their amounts (§6, D-004). Two copies
/// of that promise would eventually say two things, and the one the user
/// happened to read is the one they would hold the app to.
///
/// The delete itself is a **soft** delete (D-003) — a hard delete cannot be
/// propagated to another device, and an invoice's customer must survive so the
/// invoice can still be opened (D-040).
///
/// Returns true when the customer was deleted, so the caller can decide where
/// to go next: the list stays where it is, the detail screen has to leave.
Future<bool> confirmAndDeleteCustomer(
  BuildContext context,
  WidgetRef ref,
  String customerId,
) async {
  final AppStrings strings = AppStrings.of(context);

  final bool confirmed =
      await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(strings.customerDeleteTitle),
          content: Text(strings.customerDeleteBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.actionDelete),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed || !context.mounted) return false;

  final bool deleted = await ref
      .read(customerEditorProvider.notifier)
      .delete(customerId);
  if (!context.mounted) return deleted;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        deleted ? strings.customerDeleted : strings.errorGenericBody,
      ),
    ),
  );
  return deleted;
}
