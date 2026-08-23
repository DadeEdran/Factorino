import 'dart:io';

import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The Phase 1 startup path, on the real target.
///
/// The unit tests cover the same ground on the Dart VM, but the schema now
/// runs behind the encrypted opener at app launch, and "the migration creates
/// six tables through a keyed connection on a real device" is the claim worth
/// checking where it will actually happen.
///
/// Uses a probe filename rather than `factorino.db`, so running the tests does
/// not leave a half-real application database on the device -- which would
/// then need a migration the moment the schema changes.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens an encrypted database with the v1 schema', (_) async {
    final file = await defaultDatabaseFile(name: 'startup_probe.db');
    for (final suffix in <String>['', '-wal', '-shm']) {
      final stale = File('${file.path}$suffix');
      if (stale.existsSync()) stale.deleteSync();
    }

    final AppDatabase database = await openAppDatabase(file: file);

    try {
      final tables = await database
          .customSelect(
            "select name from sqlite_master where type = 'table' "
            "and name not like 'sqlite_%'",
          )
          .get();
      final names = tables.map((r) => r.data['name'] as String).toSet();

      debugPrint('=== STARTUP on ${Platform.operatingSystem} ===');
      debugPrint('database file : ${file.path}');
      debugPrint('tables        : ${names.toList()..sort()}');
      debugPrint('file state    : ${inspectDatabaseFile(file).name}');

      expect(
        names,
        containsAll(<String>[
          'customers',
          'products',
          'invoices',
          'invoice_items',
          'payments',
          'settings',
        ]),
      );

      // The startup assertion already ran inside openAppDatabase; this repeats
      // it here so the failure, if any, names this test.
      expect(inspectDatabaseFile(file), DatabaseFileState.encrypted);

      final settings = await database.select(database.settings).get();
      expect(settings, hasLength(1));
      expect(settings.single.invoiceNumberPrefix, 'INV');
      debugPrint(
        'settings row  : seeded, prefix=INV, '
        'taxRateBp=${settings.single.defaultTaxRateBp}',
      );

      // Reopening with the key held in the OS keystore must return the same
      // database -- the case that breaks if the key is not stable across
      // connections (D-023).
      await database.close();
      final reopened = await openAppDatabase(file: file);
      expect(await reopened.select(reopened.settings).get(), hasLength(1));
      await reopened.close();
      debugPrint('reopen        : keystore key still opens the database');
    } finally {
      // `database` is closed inside the body; closing again is harmless but
      // the file cleanup is what matters here.
      for (final suffix in <String>['', '-wal', '-shm']) {
        final leftover = File('${file.path}$suffix');
        if (leftover.existsSync()) leftover.deleteSync();
      }
    }
  });
}
