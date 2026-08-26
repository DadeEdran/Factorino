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
  ///
  /// v2 (D-048): `invoices.number`, `number_year` and `number_sequence` became
  /// nullable, so that a draft carries no number and an abandoned one stops
  /// consuming a number permanently.
  @override
  int get schemaVersion => 2;

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
      // A ladder, not a switch on the pair: a database can arrive here from
      // any older version, so each step runs if the database is below it.
      // Append steps; never edit one that has shipped.
      if (from < 2) {
        await _migrateV1ToV2(m);
      }

      // Fail loud on a version this ladder does not cover, rather than
      // opening a database whose shape is not the one the code expects.
      if (from < 1 || to > 2) {
        throw StateError('no migration defined from v$from to v$to');
      }
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

/// v1 -> v2 (D-048): the three invoice-number columns become nullable, so a
/// draft can exist without consuming a number.
///
/// SQLite cannot relax a `NOT NULL` constraint in place, so this is the
/// [12-step table rebuild][otheralter] — create a new table, copy, drop,
/// rename. `Migrator.alterTable` performs it. No `columnTransformer` is
/// needed: the columns keep their names and types and only lose `NOT NULL`,
/// so every existing number, year and sequence copies across untouched, which
/// is the property the migration test pins.
///
/// **The hazard this migration has to survive is `ON DELETE CASCADE`.** Step 6
/// of the rebuild is `DROP TABLE invoices`, and with foreign keys enabled that
/// runs an implicit delete of every row — which would cascade into
/// `invoice_items` and `payments` and silently take the lines and the payment
/// history of every invoice in the database with it. `alterTable` guards
/// against this by issuing `PRAGMA foreign_keys = OFF` **before** it opens its
/// own transaction and restoring it after (SQLite ignores that pragma inside a
/// transaction, which is why the ordering matters and why this migration must
/// not be wrapped in one). Drift invokes `onUpgrade` outside a transaction, so
/// the guard works — but it is a property of two packages agreeing, not of
/// this file, so `invoice_number_migration_test.dart` migrates a database
/// holding real items and payments and counts them afterwards.
///
/// [otheralter]: https://www.sqlite.org/lang_altertable.html#otheralter
Future<void> _migrateV1ToV2(Migrator m) async {
  final db = m.database as AppDatabase;

  // Deliberately NOT wrapped in a transaction, and that is load-bearing:
  // `alterTable` must issue `PRAGMA foreign_keys = OFF` outside one, or SQLite
  // ignores it and step 6's `DROP TABLE invoices` cascades. Verified by doing
  // it -- wrapping this line in `db.transaction` leaves `invoice_items` at
  // zero rows, while the schema-comparison test still passes.
  await m.alterTable(TableMigration(db.invoices));

  // Step 9 of the procedure, which drift's `alterTable` documents that it does
  // not perform ("We don't currently check step 9 and 10"). It is cheap, it
  // runs while we can still refuse to open, and a dangling `invoice_id` here
  // would otherwise surface much later as an invoice whose lines have gone.
  // soft-delete-exempt: an integrity pragma, not a read of user rows.
  final violations = await db.customSelect('pragma foreign_key_check').get();
  if (violations.isNotEmpty) {
    throw StateError(
      'the v1 -> v2 invoice-number migration left ${violations.length} '
      'foreign-key violation(s); refusing to open. See D-048.',
    );
  }
}
