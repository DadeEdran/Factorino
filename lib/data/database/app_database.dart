import 'package:drift/drift.dart';

// Referenced only by the generated part file, which resolves names through
// this library's imports: `uuidV4` and `nowMillis` back the column defaults.
import '../../core/utils/uuid.dart';
import '../models/invoice_status.dart';
import '../models/payment_method.dart';
import '../models/product_type.dart';
import '../models/sync_status.dart';

import 'tables/customers.dart';
import 'tables/invoice_items.dart';
import 'tables/invoices.dart';
import 'tables/payments.dart';
import 'tables/products.dart';
import 'tables/settings.dart';
import 'tables/sync_columns.dart';

part 'app_database.g.dart';

/// The application database.
///
/// It never opens itself: a [QueryExecutor] is handed in, and the only thing
/// in `lib/` allowed to build one is `openEncryptedDatabase` (D-020). That
/// separation is what keeps the encryption guarantee in one place and makes
/// this class trivially testable against a temporary file.
@DriftDatabase(
  tables: <Type>[
    Customers,
    Products,
    Invoices,
    InvoiceItems,
    Payments,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Set from the first release and never mutated retroactively. Bumping this
  /// requires a migration step **and** a migration test;
  /// the schema dump in `drift_schemas/` is what makes that test possible.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();

      // The single settings row exists from the moment the database does,
      // with the defaults declared on the table. Seeding it here rather
      // than lazily means no read path anywhere has to handle
      // "configuration missing", and the CHECK constraint keeps it single.
      await into(settings).insert(SettingsCompanion.insert());
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // No migrations yet -- v1 is the first schema. When this is no
      // longer true, add steps here and never edit an existing one.
      throw StateError('no migration defined from v$from to v$to');
    },
    beforeOpen: (OpeningDetails details) async {
      // Foreign keys are enabled by the connection opener, before drift
      // issues anything (D-017, D-020). This verifies it took effect
      // rather than assuming it: SQLite silently ignores
      // `PRAGMA foreign_keys` inside a transaction, so a future refactor
      // that moves the pragma into a migration would disable referential
      // integrity without any error at all.
      // soft-delete-exempt: a connection pragma, not a read of user rows.
      final row = await customSelect('pragma foreign_keys').getSingleOrNull();
      final enabled = row?.data.values.first;
      if (enabled != 1) {
        throw StateError(
          'foreign keys are not enabled on this connection '
          '(pragma foreign_keys = $enabled). See D-017 and D-020.',
        );
      }
    },
  );
}
