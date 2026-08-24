import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/number_input.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/money/money.dart';
import '../../../core/router/destinations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/form_scaffold.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_type.dart';
import '../application/products_providers.dart';

/// Create or edit a product or service.
///
/// The first form in the application that accepts **money**, which is where the
/// §4 rules start applying to user input rather than to stored values:
///
/// * The amount is parsed by `core/formatting/number_input.dart`, so Persian
///   and Arabic-Indic digits are accepted, and **no `double` is involved at any
///   point** (D-002).
/// * The value is entered in **Toman**, the primary display unit (§9), and
///   converted to Rial by `Money.toman` — the one place that conversion is
///   allowed to happen.
/// * An amount past `kMaxAmountRial` is **rejected with a Persian message**
///   rather than truncated (D-002). The engine already refuses it; this is the
///   screen that explains the refusal instead of letting an exception surface.
class ProductFormScreen extends ConsumerWidget {
  const ProductFormScreen({this.productId, super.key});

  /// Null for a new product.
  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);

    if (productId == null) {
      return _ProductForm(strings: strings, existing: null);
    }

    return ref
        .watch(productByIdProvider(productId!))
        .when(
          loading: () => const FormLoadingScaffold(fieldCount: 4),
          error: (Object error, StackTrace stack) =>
              _FormFailure(strings: strings, error: error, stackTrace: stack),
          data: (Product? product) {
            if (product == null) {
              return _FormFailure(
                strings: strings,
                error: StateError('product not found'),
              );
            }
            return _ProductForm(strings: strings, existing: product);
          },
        );
  }
}

class _FormFailure extends StatelessWidget {
  const _FormFailure({
    required this.strings,
    required this.error,
    this.stackTrace,
  });

  final AppStrings strings;
  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: strings.productEditTitle,
      onSave: null,
      saveLabel: strings.actionSave,
      cancelLabel: strings.actionCancel,
      onCancel: () => context.go(AppDestination.products.path),
      child: AsyncErrorView(
        error: error,
        stackTrace: stackTrace,
        scope: 'product-form',
      ),
    );
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({required this.strings, required this.existing});

  final AppStrings strings;
  final Product? existing;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _unit = TextEditingController(
    text: widget.existing?.unit ?? '',
  );
  late final TextEditingController _price = TextEditingController(
    text: widget.existing == null ? '' : '${widget.existing!.price.toman}',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );

  late ProductType _type = widget.existing?.type ?? ProductType.product;

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _name,
      _unit,
      _price,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = widget.strings;
    final bool isEditing = widget.existing != null;

    return FormScaffold(
      title: isEditing ? strings.productEditTitle : strings.productCreateTitle,
      saveLabel: strings.actionSave,
      cancelLabel: strings.actionCancel,
      onCancel: () => context.go(AppDestination.products.path),
      // The controller's own state is the in-flight flag, so the button and
      // the write cannot disagree about whether a save is running.
      onSave: ref.watch(productEditorProvider).isLoading ? null : _save,
      child: Form(
        key: _formKey,
        child: ListView(
          // Room above the first field for its floating label.
          //
          // An outlined field's label floats *outside* the field's own box,
          // onto the top border. The first field sits flush against the top of
          // this scroll viewport, and a viewport clips its children -- so the
          // label of whichever field is autofocused had its upper half sliced
          // off. In Persian that is worse than it sounds: the letter bodies
          // survive and only the ascenders and the dots above them vanish, so
          // it reads as a subtly misspelled word rather than as a layout fault.
          // Found by screenshotting the running form and zooming in.
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          children: <Widget>[
            TextFormField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: strings.productFieldName),
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty)
                  ? strings.validationRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            // A segmented control rather than a dropdown: there are exactly two
            // values, both are short, and showing both at once means the user
            // reads the choice instead of opening it.
            SegmentedButton<ProductType>(
              segments: <ButtonSegment<ProductType>>[
                ButtonSegment<ProductType>(
                  value: ProductType.product,
                  label: Text(strings.productTypeProduct),
                  icon: const Icon(Icons.inventory_2_outlined),
                ),
                ButtonSegment<ProductType>(
                  value: ProductType.service,
                  label: Text(strings.productTypeService),
                  icon: const Icon(Icons.handyman_outlined),
                ),
              ],
              selected: <ProductType>{_type},
              onSelectionChanged: (Set<ProductType> selection) =>
                  setState(() => _type = selection.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: strings.productFieldPrice,
                // The unit is always shown beside an amount (§9): a bare
                // number here is ambiguous by a factor of ten.
                suffixText: strings.unitToman,
              ),
              validator: _validatePrice,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _unit,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: strings.productFieldUnit,
                hintText: strings.productFieldUnitHint,
              ),
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty)
                  ? strings.validationRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: strings.productFieldDescription,
                helperText: strings.fieldOptional,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  /// Parses in Toman, checks the ceiling in Rial.
  ///
  /// `tryParseIntInput` folds the digit sets and returns null rather than
  /// throwing, so malformed input is an ordinary form state instead of an
  /// error path that might surface a raw exception (§7).
  String? _validatePrice(String? value) {
    final AppStrings strings = widget.strings;
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return strings.validationRequired;

    final int? toman = tryParseIntInput(text);
    if (toman == null || toman < 0) return strings.validationAmountInvalid;

    // Checked here rather than caught at save time: the ceiling rejects
    // instead of truncating (D-002), and the user should learn that while the
    // field is still in front of them.
    if (toman > kMaxAmountRial ~/ 10) return strings.validationAmountTooLarge;
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final int? toman = tryParseIntInput(_price.text.trim());
    if (toman == null) return;

    final ProductDraft draft = ProductDraft(
      name: _name.text.trim(),
      type: _type,
      // The one place Toman entry becomes Rial storage. `Money.toman` is
      // overflow-checked, and the field already refused anything past the
      // ceiling (D-002).
      price: Money.toman(toman),
      unit: _unit.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
    );

    final Product? saved = await ref
        .read(productEditorProvider.notifier)
        .save(id: widget.existing?.id, draft: draft);

    if (!mounted) return;

    if (saved == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.strings.errorGenericBody)));
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(widget.strings.productSaved)));
    context.go(AppDestination.products.path);
  }
}
