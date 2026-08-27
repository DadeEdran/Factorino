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
  ///
  /// v3 (D-052): five `customer_*_snapshot` columns on `invoices`, so an issued
  /// invoice keeps the party it was issued to, and `settings.payment_term_days`,
  /// so the default due date stops being a constant in the source.
  @override
  int get schemaVersion => 3;

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
      //
      // Each step is also bounded above by `to`. In the application `to` is
      // always `schemaVersion`, so this changes no production path -- it is
      // what lets a test migrate a v1 database to v2 *and stop there*, and
      // compare the result against the v2 schema dump. Without it the ladder
      // would run every step regardless of the target and the intermediate
      // shape would be unobservable.
      if (from < 2 && to >= 2) {
        await _migrateV1ToV2(m);
      }
      if (from < 3 && to >= 3) {
        await migrateV2ToV3(m);
      }

      // Fail loud on a version this ladder does not cover, rather than
      // opening a database whose shape is not the one the code expects.
      if (from < 1 || to > 3) {
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

/// Refuses to run a 12-step table rebuild on a connection that cannot actually
/// turn foreign keys off.
///
/// `Migrator.alterTable` drops and recreates the table, and it defends the
/// `DROP` against `ON DELETE CASCADE` by issuing `PRAGMA foreign_keys = OFF`
/// first. That pragma is a **no-op inside a transaction**, and SQLite reports
/// no error when it ignores it — so a rebuild that runs inside one cascades
/// through every child row and still produces exactly the right schema.
///
/// This is not a heuristic for "am I in a transaction". It observes the single
/// property the rebuild depends on, by doing what `alterTable` is about to do
/// and reading the result back: ask for foreign keys off, and see whether they
/// went off. If they did not, the pragma was ignored — because of a
/// transaction, a batch, or some future change in how drift invokes
/// `onUpgrade` — and the rebuild is not safe to run here.
///
/// It costs two pragmas and it runs before anything destructive, and it is
/// public so `invoice_number_migration_test.dart` can call it from inside a
/// `db.transaction` and watch it refuse. Call it from every future migration
/// that rebuilds a table with children.
Future<void> assertForeignKeysCanBeDisabled(AppDatabase db) async {
  Future<int?> readForeignKeys() async {
    // soft-delete-exempt: a connection pragma, not a read of user rows.
    final row = await db.customSelect('pragma foreign_keys').getSingle();
    return row.data.values.first as int?;
  }

  final wasEnabled = await readForeignKeys();

  await db.customStatement('pragma foreign_keys = off');
  final wentOff = await readForeignKeys() == 0;
  // Restore whatever the connection had, whether or not the probe succeeded.
  if (wasEnabled == 1) {
    await db.customStatement('pragma foreign_keys = on');
  }

  if (!wentOff) {
    throw StateError(
      'refusing to rebuild a table on a connection where '
      '`PRAGMA foreign_keys = OFF` is ignored — almost certainly because the '
      'migration is running inside a transaction. `Migrator.alterTable` would '
      'drop the parent table with foreign keys still on, and ON DELETE '
      'CASCADE would silently delete every invoice line and every payment in '
      'the database. Run the migration outside any transaction. See D-048 and '
      'D-049.',
    );
  }
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
/// this file, and nothing about it is visible at the call site.
///
/// So it is defended three ways (D-049): [assertForeignKeysCanBeDisabled]
/// refuses to run the rebuild at all on a connection where the pragma is
/// ignored, the call site says so in as many words, and
/// `invoice_number_migration_test.dart` migrates a database holding real items
/// and payments and counts them afterwards.
///
/// **A second thing about `alterTable`, which only bites once there is a third
/// version.** It builds the replacement table from the table as it is
/// *currently declared in this file*, not as v2 declared it — and then copies
/// every one of those columns across from the old table with an
/// `INSERT ... SELECT`. A column added in a later version does not exist in the
/// v1 table, so the copy fails outright: `no such column:
/// customer_name_snapshot`, on open, for every user who had not updated since
/// the first release. Measured, not reasoned about — it is what the v1 -> v3
/// tests reported the moment the v3 columns were declared.
///
/// `TableMigration.newColumns` is the answer: it tells drift which columns to
/// leave out of the copy and let take their default. **The list is computed
/// from the database rather than written down**, by asking the old table what
/// columns it actually has — because a hand-maintained list is one that the
/// next person to add a column to `invoices` does not know exists, and the
/// failure would again reach only the users furthest behind. Computed, this
/// step needs no edit for any future column.
///
/// The consequence for the step after it: a v1 database arrives at
/// [migrateV2ToV3] with the snapshot columns already present (empty, which is
/// exactly right for a pre-v3 invoice) while a v2 database arrives without
/// them. That is why the later step adds each column only if absent.
///
/// [otheralter]: https://www.sqlite.org/lang_altertable.html#otheralter
Future<void> _migrateV1ToV2(Migrator m) async {
  final db = m.database as AppDatabase;

  // DO NOT WRAP THIS FUNCTION, OR THE CALL BELOW, IN A TRANSACTION.
  //
  // It reads as a safety improvement. It destroys data. `alterTable` protects
  // step 6's `DROP TABLE invoices` from `ON DELETE CASCADE` by issuing
  // `PRAGMA foreign_keys = OFF` *outside* its own transaction; SQLite silently
  // ignores that pragma inside a transaction, so wrapping this deletes **every
  // `invoice_items` row and every `payments` row in the user's database** --
  // every line of every invoice and the entire payment history -- with no
  // error, and leaves a schema that compares as correct.
  //
  // Measured, not reasoned: wrapping this line in `db.transaction` leaves
  // `invoice_items` at zero rows while the schema-comparison test still
  // passes. Five of the six tests over this migration stay green, because only
  // the child rows die.
  //
  // The guard above turns that into a loud failure, and
  // `invoice_number_migration_test.dart` counts the surviving lines and
  // payments. Neither is decoration; do not remove either to make a wrapper
  // work.
  await assertForeignKeysCanBeDisabled(db);

  // Everything the table on disk does not have yet -- see the note above.
  // These are columns from later schema versions, and drift must not try to
  // copy them out of a table that predates them.
  final Set<String> existing = await _columnNames(db, 'invoices');
  final List<GeneratedColumn<Object>> fromLaterVersions = db.invoices.$columns
.where(
        (GeneratedColumn<Object> column) => !existing.contains(column.name),
      )
.toList();

  await m.alterTable(
    TableMigration(db.invoices, newColumns: fromLaterVersions),
  );

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

/// v2 -> v3 (D-052): the customer snapshot on `invoices`, and the payment term
/// in `settings`.
///
/// **Six `ALTER TABLE ... ADD COLUMN`s, and deliberately not a table rebuild.**
/// Every new column is nullable or carries a non-null default, which is
/// precisely what SQLite requires to add one in place. Nothing is dropped,
/// nothing is copied, and no row is rewritten.
///
/// **Which is why [assertForeignKeysCanBeDisabled] is not called here, and its
/// absence is not an oversight.** That guard checks one property: that
/// `PRAGMA foreign_keys = OFF` actually takes effect on this connection. A
/// rebuild needs that because its step 6 is `DROP TABLE invoices`, which with
/// foreign keys on cascades through every line and every payment (D-048,
/// D-049). `ADD COLUMN` drops nothing, so it has no such precondition, and
/// calling the guard anyway would teach the next reader that it is a ritual
/// performed before migrations rather than a check on a property the migration
/// depends on — which is how a guard stops being read.
///
/// That claim is not left as prose. `customer_snapshot_migration_test.dart`
/// runs this step **inside a transaction**, with foreign keys on and children
/// present, and asserts every row survives: the exact condition under which
/// the v1 -> v2 rebuild destroys data, and under which this one does not. The
/// step is public for that test, on D-049's precedent.
///
/// **Why each column is added only if absent.** A database arriving from v1
/// runs [_migrateV1ToV2] first, and `alterTable` there rebuilds `invoices` from
/// the table as this file declares it *today* — so by the time control reaches
/// here, a v1 database already has all five snapshot columns and a v2 database
/// has none. A plain `addColumn` would fail with `duplicate column name` for
/// every user still on v1, on open, with their database unopenable. The
/// existence check is what makes both arrival paths land on the same shape, and
/// the v1 -> v3 test is what proves it rather than asserting it.
///
/// `settings.payment_term_days` is absent on both paths: `settings` is not
/// rebuilt by any earlier step.
Future<void> migrateV2ToV3(Migrator m) async {
  final db = m.database as AppDatabase;

  for (final GeneratedColumn<Object> column in <GeneratedColumn<Object>>[
    db.invoices.customerNameSnapshot,
    db.invoices.customerCompanySnapshot,
    db.invoices.customerNationalIdSnapshot,
    db.invoices.customerEconomicIdSnapshot,
    db.invoices.customerAddressSnapshot,
  ]) {
    await _addColumnIfAbsent(m, db, db.invoices, column);
  }

  await _addColumnIfAbsent(m, db, db.settings, db.settings.paymentTermDays);

  // Nothing here can create a dangling reference -- no row is moved and no key
  // is touched -- but the check costs one pragma while we can still refuse to
  // open, and a migration that silently left the database inconsistent is the
  // failure mode this whole file is arranged against.
  // soft-delete-exempt: an integrity pragma, not a read of user rows.
  final violations = await db.customSelect('pragma foreign_key_check').get();
  if (violations.isNotEmpty) {
    throw StateError(
      'the v2 -> v3 customer-snapshot migration left ${violations.length} '
      'foreign-key violation(s); refusing to open. See D-052.',
    );
  }
}

/// Adds [column] to [table] unless the table already has it.
///
/// Asks the database rather than reasoning about which earlier steps ran:
/// `PRAGMA table_info` is what the table actually looks like on this device,
/// and the reason a column may already be there ([_migrateV1ToV2] rebuilding at
/// the current declaration) is exactly the kind of coupling that is easy to get
/// wrong from the source alone.
Future<void> _addColumnIfAbsent(
  Migrator m,
  AppDatabase db,
  TableInfo<Table, dynamic> table,
  GeneratedColumn<Object> column,
) async {
  final Set<String> present = await _columnNames(db, table.actualTableName);
  if (present.contains(column.name)) return;

  await m.addColumn(table, column);
}

/// The columns [table] actually has on this device.
///
/// The table name is interpolated because `PRAGMA` arguments cannot be bound
/// as parameters in SQLite — there is no `pragma table_info(?)`. That is the
/// one thing D-018 forbids, so it is worth being exact about why it is safe
/// here: the only values ever passed are `TableInfo.actualTableName` and a
/// literal, both compile-time constants from generated code. No user input
/// reaches this string, and none can.
Future<Set<String>> _columnNames(AppDatabase db, String table) async {
  final String pragma = 'pragma table_info($table)';
  // soft-delete-exempt: a schema pragma, not a read of user rows.
  final List<QueryRow> rows = await db.customSelect(pragma).get();
  return rows.map((QueryRow row) => row.read<String>('name')).toSet();
}
