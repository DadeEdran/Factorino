import 'dart:io';

import 'package:factorino/data/backup/backup_file_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// Proves the Android save dialog actually opens (D-071).
///
/// `flutter_file_dialog` was chosen by reading source and package metadata, not
/// from experience with it. The save side of Android is the **only untested
/// link in the chain a user actually walks** — everything else in Phase 6 has
/// a test — and the failure modes are ones no unit test reaches: the plugin
/// failing to register, the Gradle build breaking, or the intent simply not
/// resolving on MIUI.
///
/// The dialog is system UI, so the assertion has two halves and the host drives
/// the second:
///
///   1. This test calls `deliver` and blocks on the picker.
///   2. The host checks `dumpsys activity activities` for DocumentsUI in the
///      foreground — **that** is the evidence the dialog opened — and sends
///      KEYCODE_BACK.
///   3. `deliver` returns `false`, proving a cancellation is reported as an
///      ordinary outcome rather than surfacing as an error.
///
/// Run (and drive the BACK from the host — see `docs/CURRENT_STATE.md`):
///   flutter test integration_test/backup_gateway_probe_test.dart -d `device`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the save dialog opens, and cancelling is not an error', (
    WidgetTester tester,
  ) async {
    final Directory support = await getApplicationSupportDirectory();
    final File source = File(
      '${support.path}${Platform.pathSeparator}gateway_probe.$kBackupFileExtension',
    );
    await source.writeAsBytes(
      List<int>.generate(4096, (int i) => i % 256),
      flush: true,
    );
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    debugPrint('=== GATEWAY PROBE (D-071) on ${Platform.operatingSystem} ===');
    debugPrint('source file   : ${source.lengthSync()} bytes');
    debugPrint('DIALOG-OPENING');

    const BackupFileGateway gateway = PlatformBackupFileGateway();

    // No `await tester.pumpAndSettle()` around this: the picker is another
    // activity, and settling would time out waiting for frames that are not
    // being produced while it is in front.
    final bool delivered = await gateway.deliver(
      source: source,
      suggestedName: 'factorino-probe.$kBackupFileExtension',
    );

    debugPrint('DIALOG-CLOSED delivered=$delivered');

    expect(
      delivered,
      isFalse,
      reason:
          'the host sent BACK, so this must report a cancellation -- if it is '
          'true, something saved without the user choosing a location',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
