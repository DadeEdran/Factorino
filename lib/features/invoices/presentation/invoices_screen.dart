import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_strings.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';

/// The invoice list.
///
/// No data layer attached yet -- see the note on `CustomersScreen`. When it is,
/// this is the screen where the tier split matters most: mobile renders cards,
/// desktop renders a real table (§10).
class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return PageBody(
      title: strings.invoicesTitle,
      child: EmptyState(
        icon: Icons.receipt_long_outlined,
        title: strings.emptyInvoicesTitle,
        body: strings.emptyInvoicesBody,
      ),
    );
  }
}
