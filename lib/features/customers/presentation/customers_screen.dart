import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_strings.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';

/// The customer list.
///
/// **No data layer is attached yet.** The repository exists (increment d) and
/// the empty state below is the real one this screen will keep -- it is shown
/// unconditionally here because nothing queries yet. Wiring it to
/// `customerRepositoryProvider`, and adding the call to action that opens the
/// create form, is increment (f).
class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return PageBody(
      title: strings.customersTitle,
      child: EmptyState(
        icon: Icons.people_outline,
        title: strings.emptyCustomersTitle,
        body: strings.emptyCustomersBody,
      ),
    );
  }
}
