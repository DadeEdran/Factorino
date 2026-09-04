import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/number_display.dart';
import '../../../core/formatting/number_input.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/router/destinations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/form_scaffold.dart';
import '../../../core/widgets/money_display_scope.dart';
import '../../../data/models/field_limits.dart';
import '../../../data/models/money_display_unit.dart';
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
/// * The value is entered in **the unit the user chose** — Toman by default
///   (§9), Rial if they said so (D-117) — and converted to Rial storage by
///   [MoneyDisplayUnitConversion.moneyOf], which is `Money`'s own constructor
///   and the one place that conversion is allowed to happen.
/// * An amount past `kMaxAmountRial` is **rejected with a Persian message**
///   rather than truncated (D-002). The engine already refuses it; this is the
///   screen that explains the refusal instead of letting an exception surface.
///
/// Every field is an [AppTextField], whose `maxLength` is required and comes
/// from [ProductLimits] — the same numbers the columns carry (§7, D-042).
class ProductFormScreen extends ConsumerWidget {
  const ProductFormScreen({this.productId, super.key});

  /// Null for a new product.
  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);

    // Read where there is a context to read it from, and handed to the form:
    // the controllers are seeded before the form's own first build, and a
    // field seeded in one unit and labelled in another is the ambiguity
    // D-117 exists to close.
    final MoneyDisplayUnit unit = MoneyDisplayScope.of(context);

    if (productId == null) {
      return _ProductForm(strings: strings, existing: null, unit: unit);
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
            return _ProductForm(
              strings: strings,
              existing: product,
              unit: unit,
            );
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
  const _ProductForm({
    required this.strings,
    required this.existing,
    required this.unit,
  });

  final AppStrings strings;
  final Product? existing;

  /// The unit the price is shown and entered in (D-117).
  final MoneyDisplayUnit unit;

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
    // Seeded grouped, in the same shape the field keeps while it is typed in:
    // an existing price that appeared ungrouped until the first keystroke
    // would read as a different kind of value than the one being entered.
    text: widget.existing == null
        ? ''
        : formatGroupedPersian(widget.unit.amountOf(widget.existing!.price)),
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
            AppTextField(
              controller: _name,
              label: strings.productFieldName,
              maxLength: ProductLimits.name,
              autofocus: true,
              textInputAction: TextInputAction.next,
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
            AppTextField(
              controller: _price,
              label: strings.productFieldPrice,
              // No column length to match -- money is an integer (D-002) --
              // but there is still a ceiling, and stopping entry at the widest
              // amount that can exist says so before the validator has to.
              maxLength: AmountLimits.tomanDigits,
              // The unit is always shown beside an amount (§9): a bare number
              // here is ambiguous by a factor of ten.
              suffixText: moneyUnitLabel(widget.unit, strings),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              textInputAction: TextInputAction.next,
              groupDigits: true,
              validator: _validatePrice,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _unit,
              label: strings.productFieldUnit,
              maxLength: ProductLimits.unit,
              hintText: strings.productFieldUnitHint,
              textInputAction: TextInputAction.next,
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty)
                  ? strings.validationRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _description,
              label: strings.productFieldDescription,
              maxLength: ProductLimits.description,
              helperText: strings.fieldOptional,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  /// Parses in the unit on the label, checks the ceiling for that unit.
  ///
  /// `tryParseIntInput` folds the digit sets and returns null rather than
  /// throwing, so malformed input is an ordinary form state instead of an
  /// error path that might surface a raw exception (§7).
  String? _validatePrice(String? value) {
    final AppStrings strings = widget.strings;
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return strings.validationRequired;

    final int? entered = tryParseIntInput(text);
    if (entered == null || entered < 0) return strings.validationAmountInvalid;

    // Checked here rather than caught at save time: the ceiling rejects
    // instead of truncating (D-002), and the user should learn that while the
    // field is still in front of them.
    if (entered > widget.unit.maxEnterableValue) {
      return strings.validationAmountTooLarge;
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final int? amount = tryParseIntInput(_price.text.trim());
    if (amount == null) return;

    final ProductDraft draft = ProductDraft(
      name: _name.text.trim(),
      type: _type,
      // The one place entry becomes Rial storage. Both constructors behind
      // `moneyOf` are overflow-checked, and the field already refused anything
      // past the ceiling (D-002).
      price: widget.unit.moneyOf(amount),
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
