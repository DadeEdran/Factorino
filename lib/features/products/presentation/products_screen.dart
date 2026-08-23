import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_strings.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';

/// The product and service catalogue.
///
/// No data layer attached yet -- see the note on `CustomersScreen`.
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return PageBody(
      title: strings.productsTitle,
      child: EmptyState(
        icon: Icons.inventory_2_outlined,
        title: strings.emptyProductsTitle,
        body: strings.emptyProductsBody,
      ),
    );
  }
}
