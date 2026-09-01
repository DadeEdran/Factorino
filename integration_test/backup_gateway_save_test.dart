import 'dart:io';

import 'package:factorino/data/backup/backup_file_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// The **completed** save — the one link in the chain a user actually walks
/// that nothing else exercises (D-071).
///
/// `backup_gateway_probe_test.dart` proves the dialog opens with the right
/// intent and that cancelling is an ordinary outcome. It cannot prove that
/// confirming writes the file, because that needs a tap and MIUI refuses `adb`
/// input injection. So this test is **interactive on purpose**: it opens the
/// dialog and waits for a human.
///
/// Not part of any automated suite. Run it deliberately, tap through it, and
/// then verify the bytes from the host — the test asserts the call succeeded,
/// the host checks that what landed is what was sent.
///
/// Android:  save into **Downloads**, keeping the offered name.
/// Windows:  save into the folder the run tells you, keeping the offered name.
///
///   flutter test integration_test/backup_gateway_save_test.dart -d `device`
///   flutter test integration_test/backup_gateway_save_test.dart -d windows

/// A recognisable pattern rather than zeroes: a truncated or empty write would
/// otherwise be indistinguishable from a correct one at a glance.
const int _probeSize = 4096;

const String _probeName = 'factorino-save-probe.$kBackupFileExtension';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a confirmed save writes the file the user chose', (
    WidgetTester tester,
  ) async {
    final Directory support = await getApplicationSupportDirectory();
    final File source = File(
      '${support.path}${Platform.pathSeparator}save_probe_source',
    );
    await source.writeAsBytes(
      List<int>.generate(_probeSize, (int i) => (i * 7 + 13) % 256),
      flush: true,
    );
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    debugPrint('=== GATEWAY SAVE (D-071) on ${Platform.operatingSystem} ===');
    debugPrint('source bytes  : ${source.lengthSync()}');
    debugPrint('offered name  : $_probeName');
    if (Platform.isAndroid) {
      debugPrint('ACTION NEEDED : save into Downloads, keep the offered name');
    } else {
      debugPrint('ACTION NEEDED : save into ${Directory.current.path}');
    }
    debugPrint('WAITING-FOR-TAP');

    const BackupFileGateway gateway = PlatformBackupFileGateway();

    final bool delivered = await gateway.deliver(
      source: source,
      suggestedName: _probeName,
    );

    debugPrint('SAVE-RESULT delivered=$delivered');

    expect(
      delivered,
      isTrue,
      reason:
          'the save was cancelled or failed. If you cancelled deliberately, '
          'this failure is correct and the run proved nothing -- re-run it and '
          'confirm the dialog.',
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
