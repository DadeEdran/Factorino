import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/iranian_phone.dart';
import '../../../core/formatting/national_id.dart';
import '../../../core/localization/generated/app_strings.dart';
import '../../../core/router/destinations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/form_scaffold.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/field_limits.dart';
import '../application/customers_providers.dart';

/// Create or edit a customer.
///
/// The first screen in the application that **accepts** third-party personal
/// identifiers, which makes it the first place several rules stop being
/// abstract:
///
/// * **D-030.** The national-ID field says the *format* is valid and never that
///   the identity is confirmed. The checksum maps two distinct numbers onto the
///   same check digit, so a passing value narrows the space of typos and
///   proves nothing else. `no_hardcoded_strings_test.dart` checks the ARB copy
///   mechanically; this is the call site that copy now appears on.
/// * **§7.** Nothing here is logged. The one log line records that a save
///   happened and the id it produced — never a field.
/// * **§9.** Every value the user types passes through `core/formatting/`
///   before it is judged, so Persian and Arabic-Indic digits are accepted
///   interchangeably in the mobile and national-ID fields.
/// * **§7's field-level limits.** Every field is an [AppTextField], whose
///   `maxLength` is required and comes from [CustomerLimits] — the same numbers
///   the columns carry. Before this, the form accepted what the column would
///   refuse and the user got the generic «خطایی رخ داد» with no indication of
///   which field or why (D-042).
///
/// Validation is **at the form boundary, not in the repository**. An
/// unrecognised mobile number is stored as typed — a foreign client's number is
/// data the user deliberately entered — so the repository keeps it and this
/// screen is what asks whether they meant it.
class CustomerFormScreen extends ConsumerWidget {
  const CustomerFormScreen({this.customerId, super.key});

  /// Null for a new customer.
  final String? customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);

    if (customerId == null) {
      return _CustomerForm(strings: strings, existing: null);
    }

    return ref
        .watch(customerByIdProvider(customerId!))
        .when(
          loading: () => const FormLoadingScaffold(),
          error: (Object error, StackTrace stack) => FormScaffold(
            title: strings.customerEditTitle,
            onSave: null,
            saveLabel: strings.actionSave,
            cancelLabel: strings.actionCancel,
            onCancel: () => context.go(AppDestination.customers.path),
            child: AsyncErrorView(
              error: error,
              stackTrace: stack,
              scope: 'customer-form',
            ),
          ),
          data: (Customer? customer) {
            if (customer == null) {
              // The row was deleted while the form was opening, or the URL
              // names an id that does not exist. Sending the user back to the
              // list is the honest outcome; an empty form pretending to edit
              // something would not be.
              return FormScaffold(
                title: strings.customerEditTitle,
                onSave: null,
                saveLabel: strings.actionSave,
                cancelLabel: strings.actionCancel,
                onCancel: () => context.go(AppDestination.customers.path),
                child: AsyncErrorView(
                  error: StateError('customer not found'),
                  scope: 'customer-form',
                ),
              );
            }
            return _CustomerForm(strings: strings, existing: customer);
          },
        );
  }
}

class _CustomerForm extends ConsumerStatefulWidget {
  const _CustomerForm({required this.strings, required this.existing});

  final AppStrings strings;
  final Customer? existing;

  @override
  ConsumerState<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<_CustomerForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullName = TextEditingController(
    text: widget.existing?.fullName ?? '',
  );
  late final TextEditingController _companyName = TextEditingController(
    text: widget.existing?.companyName ?? '',
  );
  late final TextEditingController _mobile = TextEditingController(
    text: widget.existing?.mobile ?? '',
  );
  late final TextEditingController _nationalId = TextEditingController(
    text: widget.existing?.nationalId ?? '',
  );
  late final TextEditingController _address = TextEditingController(
    text: widget.existing?.address ?? '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.existing?.notes ?? '',
  );

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _fullName,
      _companyName,
      _mobile,
      _nationalId,
      _address,
      _notes,
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
      title: isEditing
          ? strings.customerEditTitle
          : strings.customerCreateTitle,
      saveLabel: strings.actionSave,
      cancelLabel: strings.actionCancel,
      onCancel: () => context.go(AppDestination.customers.path),
      // Disabled while a save is in flight, so a double tap cannot create two
      // customers. The flag is the controller's `AsyncValue`, not a local
      // bool, so the button and the write cannot disagree about what is
      // happening.
      onSave: ref.watch(customerEditorProvider).isLoading ? null : _save,
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
              controller: _fullName,
              label: strings.customerFieldFullName,
              maxLength: CustomerLimits.fullName,
              autofocus: true,
              textInputAction: TextInputAction.next,
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty)
                  ? strings.validationRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _companyName,
              label: strings.customerFieldCompany,
              maxLength: CustomerLimits.companyName,
              helperText: strings.fieldOptional,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _mobile,
              label: strings.customerFieldMobile,
              maxLength: CustomerLimits.mobile,
              helperText: strings.fieldOptional,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              // Deliberately **not** `digitsOnly`. A mobile number is entered
              // with `+`, and the repository keeps a foreign client's number
              // as typed rather than discarding it -- so the field must accept
              // what the validator below is allowed to reject.
              //
              // Empty is fine; a value that is present must look like a number
              // the user meant. `normalizeIranianMobile` accepts 0..., +98...,
              // 0098... and any digit set (§9), so this rejects only what is
              // genuinely not an Iranian mobile.
              validator: (String? value) {
                final String text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                return normalizeIranianMobile(text) == null
                    ? strings.validationMobileInvalid
                    : null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _nationalId,
              label: strings.customerFieldNationalId,
              maxLength: CustomerLimits.nationalId,
              helperText: strings.fieldOptional,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              // کد ملی is ten digits and nothing else (§7's character-class
              // half). Letting a letter in produces a value the checksum then
              // calls invalid without saying which part was wrong.
              digitsOnly: true,
              // D-030. A failing checksum is genuinely invalid and is called
              // so. A passing one produces **no affirmative message at all** —
              // not a green tick, not "confirmed". The wording is the only
              // thing standing between a probabilistic check and a false
              // assurance, and a user told their entry is verified stops
              // checking it.
              validator: (String? value) {
                final String text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                return isValidNationalId(text)
                    ? null
                    : strings.nationalIdInvalid;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _address,
              label: strings.customerFieldAddress,
              maxLength: CustomerLimits.address,
              helperText: strings.fieldOptional,
              maxLines: 2,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _notes,
              label: strings.customerFieldNotes,
              maxLength: CustomerLimits.notes,
              helperText: strings.fieldOptional,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final CustomerDraft draft = CustomerDraft(
      fullName: _fullName.text,
      companyName: _emptyToNull(_companyName.text),
      mobile: _emptyToNull(_mobile.text),
      nationalId: _emptyToNull(_nationalId.text),
      address: _emptyToNull(_address.text),
      notes: _emptyToNull(_notes.text),
    );

    // The widget hands the draft over and asks nothing else. Writing,
    // logging and error handling all belong to the controller
    // (`ARCHITECTURE.md` §B.1); this method only decides what the user is
    // told and where they go next.
    final Customer? saved = await ref
        .read(customerEditorProvider.notifier)
        .save(id: widget.existing?.id, draft: draft);

    if (!mounted) return;

    if (saved == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.strings.errorGenericBody)));
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(widget.strings.customerSaved)));
    context.go(AppDestination.customers.path);
  }

  String? _emptyToNull(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
