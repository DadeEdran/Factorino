import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/security/app_log.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/providers.dart';

part 'settings_editor.g.dart';

/// The bounds a settings form must enforce.
///
/// Named here rather than typed into the form, because `AppSettings`
/// deliberately does **not** clamp (D-052): a value that cannot be right is a
/// data-entry error to report, not a number to quietly adjust. The form is
/// where it is reported; these are the numbers it reports against.
class SettingsLimits {
  const SettingsLimits._();

  /// A payment term is days after issue. **Zero is allowed** — plenty of
  /// businesses are paid on delivery — but a negative term produces an invoice
  /// due before it was issued, which is what known issue 6 warned about.
  static const int minPaymentTermDays = 0;

  /// Two years. Not a technical limit: a term beyond this is far more likely a
  /// mistyped digit than a real agreement, and the invoice it produces would
  /// carry a due date nobody checks.
  static const int maxPaymentTermDays = 730;

  /// Basis points. 100% tax is absurd but not impossible to mean; above it is
  /// arithmetic nobody intends.
  static const int maxTaxRateBp = 10000;

  /// Matches the column, which is `withLength(min: 1, max: 12)`.
  static const int minPrefixLength = 1;
  static const int maxPrefixLength = 12;
}

/// The settings write, and nothing else.
///
/// **Editable settings are a defect fix, not a feature** (D-068): The project spec
/// §4 requires the VAT rate to be configurable and never hardcoded, and until
/// this it was hardcoded at whatever the database was seeded with. A business
/// on a different rate met that on its first invoice with no recourse.
///
/// **Changing the rate does not alter existing invoices** and cannot: every
/// item snapshots the rate that applied to it (§4, D-026). That is the property
/// which makes this screen safe to open at all.
@riverpod
class SettingsEditor extends _$SettingsEditor {
  @override
  void build() {}

  /// Persists [settings]. Returns whether it was written.
  Future<bool> save(AppSettings settings) async {
    // The write outlives the sheet that started it (D-045).
    final link = ref.keepAlive();
    try {
      await ref.read(settingsRepositoryProvider).write(settings);
      return true;
    } on Object catch (error, stackTrace) {
      AppLog.error(
        () => 'saving settings failed',
        error: error,
        stackTrace: stackTrace,
        scope: 'settings',
      );
      return false;
    } finally {
      link.close();
    }
  }
}
