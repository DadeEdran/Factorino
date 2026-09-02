import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/editor_sheet.dart';
import '../../../../data/models/field_limits.dart';
import '../../../../data/models/seller_identity.dart';

/// Edits the four seller fields — the business the invoice is issued **by**.
///
/// Returns the edited [SellerIdentity], or null if dismissed. Like the
/// invoicing sheet beside it, it **builds the value only**; the write is the
/// controller's business.
///
/// **Why it is its own sheet rather than four more fields on the invoicing
/// one.** The two are different kinds of setting — how invoices are numbered
/// and taxed, versus who is issuing them — and seven fields in one sheet on a
/// phone is a sheet the user scrolls rather than reads. The screen already
/// separates them into two sections, and one edit control per section is what
/// makes that separation mean anything.
///
/// **One rule is enforced here and reported, never clamped** (D-027, D-077):
/// the business name is required as soon as any other seller field carries a
/// value. A block headed «فروشنده» carrying a کد اقتصادی and no name is a
/// fragment rather than an identification — it tells the reader nothing they
/// can act on, and on a printed page it reads as a document that failed to
/// print. Emptying **all four** is always allowed and is how a user who wants
/// no seller block gets rid of it; the error message says so, because a
/// required-field rule with no stated way out is a trap.
Future<SellerIdentity?> showSellerEditorSheet(
  BuildContext context, {
  required SellerIdentity seller,
}) {
  return showModalBottomSheet<SellerIdentity>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _SellerEditorSheet(seller: seller),
  );
}

class _SellerEditorSheet extends StatefulWidget {
  const _SellerEditorSheet({required this.seller});

  final SellerIdentity seller;

  @override
  State<_SellerEditorSheet> createState() => _SellerEditorSheetState();
}

class _SellerEditorSheetState extends State<_SellerEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _economicId;
  late final TextEditingController _address;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.seller.name ?? '');
    _economicId = TextEditingController(text: widget.seller.economicId ?? '');
    _address = TextEditingController(text: widget.seller.address ?? '');
    _phone = TextEditingController(text: widget.seller.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _economicId.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// The value as typed, with blanks folded away.
  ///
  /// Built through [SellerIdentity.normalized] rather than by trimming at four
  /// call sites, so the sheet and the repository agree on what "empty" means
  /// by construction rather than by both remembering to trim.
  SellerIdentity get _edited => SellerIdentity(
    name: _name.text,
    economicId: _economicId.text,
    address: _address.text,
    phone: _phone.text,
  ).normalized();

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_edited);
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return EditorSheet(
      title: strings.settingsSellerEditTitle,
      closeTooltip: strings.actionCancel,
      formKey: _formKey,
      action: FilledButton(onPressed: _submit, child: Text(strings.actionSave)),
      children: <Widget>[
        AppTextField(
          controller: _name,
          label: strings.settingsSellerFieldName,
          helperText: strings.settingsSellerFieldNameHint,
          maxLength: SellerLimits.name,
          autofocus: true,
          validator: (String? value) {
            // The whole value, not this field: the name is required only
            // *because* something else was filled in, so the rule cannot be
            // decided from this controller alone.
            final SellerIdentity edited = _edited;
            if (edited.isNotEmpty && !edited.isPrintable) {
              return strings.settingsErrorSellerNameRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: _economicId,
          label: strings.settingsSellerFieldEconomicId,
          maxLength: SellerLimits.economicId,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: _phone,
          label: strings.settingsSellerFieldPhone,
          helperText: strings.settingsSellerFieldPhoneHint,
          maxLength: SellerLimits.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: _address,
          label: strings.settingsSellerFieldAddress,
          maxLength: SellerLimits.address,
          // Last, and multi-line, for the reason the customer form puts it
          // last: it is the one field that grows, and a growing field above
          // short ones pushes them out of reach on a phone with the keyboard
          // up.
          maxLines: 3,
        ),
      ],
    );
  }
}
