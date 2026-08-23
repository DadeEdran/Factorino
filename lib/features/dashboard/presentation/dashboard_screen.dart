import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_strings.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';

/// The dashboard.
///
/// **No data layer attached yet.** The aggregates it will show -- sales for the
/// current *Jalali* month (D-006), outstanding balance, invoice and customer
/// counts -- all exist as repository queries already, and wiring them is
/// increment (f). Until then this shows the real empty state rather than tiles
/// with placeholder figures: a dashboard with invented numbers on it is the
/// exact thing the project spec prohibits.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return PageBody(
      title: strings.dashboardTitle,
      child: EmptyState(
        icon: Icons.insights_outlined,
        title: strings.emptyDashboardTitle,
        body: strings.emptyDashboardBody,
      ),
    );
  }
}
