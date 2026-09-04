import 'package:drift/drift.dart';

// Referenced only by the generated part file, which resolves names through
// this library's imports: `uuidV4` and `nowMillis` back the column defaults.
import '../../core/utils/uuid.dart';
import '../models/invoice_status.dart';
import '../models/payment_method.dart';
import '../models/product_type.dart';
import '../models/app_theme_mode.dart';
import '../models/money_display_unit.dart';
import '../models/sync_status.dart';

import 'invoice_figures_backfill.dart';
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
  ///
  /// v4 (D-055): `invoices.gross_total_rial`, `invoice_items.line_gross_rial`
  /// and `invoice_items.allocated_invoice_discount_rial`, so that every figure
  /// an Iranian invoice prints is stored rather than re-derived at render
  /// time — and, unlike v3, **backfilled** where the existing row reconciles.
  ///
  /// v5 (D-077): four nullable `settings.seller_*` columns — name, کد اقتصادی,
  /// نشانی, telephone — so the printed invoice can name the business that
  /// issued it. The schema held no business identity at all, so the document
  /// carried a خریدار block and nothing opposite it, which is not a document
  /// anyone can hand to a customer. Nothing is backfilled and nothing is
  /// defaulted: an invented seller on a customer-facing page is the one thing
  /// this phase must not do.
  ///
  /// v6 (D-087): `settings.theme_mode`, the light/dark choice, defaulted to
  /// [AppThemeMode.system] — which is what every existing database was already
  /// doing, so the migration adds a column and changes no behaviour for anyone
  /// who never opens the control.
  ///
  /// v7 (D-106): کد اقتصادی leaves the schema — `customers.economic_id`,
  /// `settings.seller_economic_id` and `invoices.customer_economic_id_snapshot`
  /// are dropped. **The first migration in this application that removes
  /// data**, and the only one whose effect on a user's records cannot be
  /// undone by a later step; it is a deliberate product decision, requested
  /// after use.
  @override
  int get schemaVersion => 8;

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
        await migrateV1ToV2(m);
      }
      if (from < 3 && to >= 3) {
        await migrateV2ToV3(m);
      }
      if (from < 4 && to >= 4) {
        await migrateV3ToV4(m);
      }
      if (from < 5 && to >= 5) {
        await migrateV4ToV5(m);
      }
      if (from < 6 && to >= 6) {
        await migrateV5ToV6(m);
      }
      if (from < 7 && to >= 7) {
        await migrateV6ToV7(m);
      }
      if (from < 8 && to >= 8) {
        await migrateV7ToV8(m);
      }

      // Fail loud on a version this ladder does not cover, rather than
      // opening a database whose shape is not the one the code expects.
      if (from < 1 || to > 8) {
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
/// Public, like [migrateV2ToV3] and for the same reason (D-049, D-052): a test
/// has to be able to run one step at a time and look at what the *next* one is
/// handed. `invoice_figures_migration_test.dart` does exactly that, because the
/// shape this rebuild leaves behind is what makes the v3 -> v4 step's existence
/// checks necessary.
///
/// [otheralter]: https://www.sqlite.org/lang_altertable.html#otheralter
Future<void> migrateV1ToV2(Migrator m) async {
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
/// runs [migrateV1ToV2] first, and `alterTable` there rebuilds `invoices` from
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
    db.invoices.customerAddressSnapshot,
  ]) {
    await _addColumnIfAbsent(m, db, db.invoices, column);
  }

  // The fifth snapshot column, which v7 later drops (D-106). Still created
  // here, and by literal DDL because the Dart declaration is gone -- see
  // [_addRetiredColumnIfAbsent] for why the step is not simply edited to omit
  // it.
  await _addRetiredColumnIfAbsent(
    db,
    'invoices',
    'customer_economic_id_snapshot',
  );

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

/// v3 -> v4 (D-055): the gross on the invoice, and the two per-line figures
/// that make a printed line reconcile.
///
/// **Three `ALTER TABLE ... ADD COLUMN`s, then a backfill**, and the backfill is
/// what makes this step different from either of the two before it. D-052's
/// snapshot columns were left empty on purpose because there was no honest
/// value to write; these are arithmetic over columns the row already carries,
/// so leaving them empty would be an omission rather than an honesty. See
/// [backfillInvoiceFigures] for what it will and will not write.
///
/// **[assertForeignKeysCanBeDisabled] is not called here, for D-052's reason
/// and not by oversight.** That guard checks that `PRAGMA foreign_keys = OFF`
/// takes effect, which a 12-step rebuild needs because its step 6 is
/// `DROP TABLE invoices`. `ADD COLUMN` drops nothing and neither does an
/// `UPDATE`, so neither half of this step has that precondition, and invoking
/// the guard anyway would teach the next reader that it is a rite performed
/// before migrations rather than a check on a property one depends on.
/// `invoice_figures_migration_test.dart` stands in for it the way D-052's suite
/// does: it runs this whole step inside a transaction, with foreign keys on and
/// children present, and counts them afterwards.
///
/// **Why each column is added only if absent, and why the answer differs per
/// table.** [migrateV1ToV2] rebuilds `invoices` from the table as this file
/// declares it *today*, so a database arriving from v1 already has
/// `gross_total_rial` by the time control reaches here — while a v3 database has
/// none of the three. `invoice_items` is rebuilt by no step, so its two columns
/// are absent on **both** paths. That asymmetry is exactly the kind of thing
/// that is easy to get wrong by reading the source, so the v1 -> v4 test
/// observes the arriving shape directly rather than trusting
/// [_addColumnIfAbsent] to have made it not matter.
Future<void> migrateV3ToV4(Migrator m) async {
  final db = m.database as AppDatabase;

  await _addColumnIfAbsent(m, db, db.invoices, db.invoices.grossTotalRial);
  await _addColumnIfAbsent(
    m,
    db,
    db.invoiceItems,
    db.invoiceItems.lineGrossRial,
  );
  await _addColumnIfAbsent(
    m,
    db,
    db.invoiceItems,
    db.invoiceItems.allocatedInvoiceDiscountRial,
  );

  await backfillInvoiceFigures(db);

  // As in the v2 -> v3 step: nothing here can create a dangling reference, but
  // the check costs one pragma while we can still refuse to open.
  // soft-delete-exempt: an integrity pragma, not a read of user rows.
  final violations = await db.customSelect('pragma foreign_key_check').get();
  if (violations.isNotEmpty) {
    throw StateError(
      'the v3 -> v4 invoice-figures migration left ${violations.length} '
      'foreign-key violation(s); refusing to open. See D-055.',
    );
  }
}

/// v4 -> v5 (D-077): the seller, so the printed invoice can name the business
/// that issued it.
///
/// **Four `ALTER TABLE ... ADD COLUMN`s and no backfill**, and the absence of a
/// backfill is the decision rather than the omission. [migrateV3ToV4] filled
/// its columns because they were arithmetic over figures the row already
/// carried, so leaving them empty would have been a loss of information the
/// database held. These four are the opposite: the database has never been told
/// anything about the user's business, so there is nothing to compute and
/// nothing to copy. D-052's snapshot columns were left empty for exactly this
/// reason, and the consequence is stated rather than papered over — until the
/// user fills the settings form in, the document prints no فروشنده block, and
/// the settings screen is what tells them so.
///
/// **A `withDefault` would have been the worst available option.** It is the
/// one shape that produces a document: a fabricated seller block, on the page
/// the customer keeps, that nobody would ever question because it looks exactly
/// like a real one.
///
/// **[assertForeignKeysCanBeDisabled] is not called here**, for the reason
/// [migrateV3ToV4] gives at greater length: that guard checks a precondition of
/// a 12-step table rebuild, whose step 6 is a `DROP TABLE`. `ADD COLUMN` drops
/// nothing. Invoking it anyway would teach the next reader that it is a rite
/// performed before migrations rather than a check on a property one depends
/// on.
///
/// **[_addColumnIfAbsent] rather than [Migrator.addColumn], on a table no step
/// rebuilds.** `settings` is rebuilt by nothing, so on today's ladder every one
/// of these four is absent on every path and a plain `addColumn` would do. It
/// is used all the same, because the next step that rebuilds this table would
/// otherwise turn a v1 upgrade into `duplicate column name` on open — for
/// exactly the users furthest behind, and only for them. Cheap here,
/// unrecoverable there.
Future<void> migrateV4ToV5(Migrator m) async {
  final db = m.database as AppDatabase;

  await _addColumnIfAbsent(m, db, db.settings, db.settings.sellerName);
  await _addColumnIfAbsent(m, db, db.settings, db.settings.sellerAddress);
  await _addColumnIfAbsent(m, db, db.settings, db.settings.sellerPhone);

  // The seller's کد اقتصادی, which v7 later drops (D-106). Literal DDL for the
  // reason [_addRetiredColumnIfAbsent] gives.
  await _addRetiredColumnIfAbsent(db, 'settings', 'seller_economic_id');

  // As in the two steps before it: nothing here can create a dangling
  // reference, but the check costs one pragma while we can still refuse to
  // open.
  // soft-delete-exempt: an integrity pragma, not a read of user rows.
  final violations = await db.customSelect('pragma foreign_key_check').get();
  if (violations.isNotEmpty) {
    throw StateError(
      'the v4 -> v5 seller migration left ${violations.length} '
      'foreign-key violation(s); refusing to open. See D-077.',
    );
  }
}

/// v5 -> v6 (D-087): `settings.theme_mode`, the light/dark choice.
///
/// One column with a default, and **nothing to backfill** — but for the
/// opposite reason to v5's. v5 had nothing honest to write because the
/// application had never been told the answer; here the answer is known and is
/// already in force: every database that reaches this step has been following
/// the device, which is exactly what `AppThemeMode.system` records. The column
/// default states the behaviour rather than changing it, so no user's
/// application looks different the first time they open it after upgrading.
///
/// `addColumn` carries the declared default, so existing rows get `0` rather
/// than a null in a non-nullable column — the failure this step would
/// otherwise produce on the next read, on a table that is read on every frame
/// of the settings screen.
Future<void> migrateV5ToV6(Migrator m) async {
  final db = m.database as AppDatabase;

  await _addColumnIfAbsent(m, db, db.settings, db.settings.themeMode);

  // As in the three steps before it: nothing here can create a dangling
  // reference, but the check costs one pragma while we can still refuse to
  // open.
  // soft-delete-exempt: an integrity pragma, not a read of user rows.
  final violations = await db.customSelect('pragma foreign_key_check').get();
  if (violations.isNotEmpty) {
    throw StateError(
      'the v5 -> v6 theme migration left ${violations.length} '
      'foreign-key violation(s); refusing to open. See D-087.',
    );
  }
}

/// v6 -> v7 (D-106): کد اقتصادی leaves the schema.
///
/// Three `DROP COLUMN`s: the field on the customer record, the seller's copy of
/// it in `settings`, and the snapshot of the customer's on `invoices`. The
/// owner does not use it, and a field nobody fills is not free — it is a
/// mandatory-looking box on two forms, a labelled empty row on two screens, and
/// a third-party national identifier this application had no reason to be
/// storing (§7 counts every one of those as a liability rather than a feature).
///
/// **This is the first migration here that destroys data, and saying so is the
/// point.** Every earlier step added a column, or rebuilt a table while copying
/// every value across; the worst any of them could do was fail. This one throws
/// away whatever the user had typed into those three fields, and no later step
/// can bring it back. It is a product decision taken after use rather than a
/// schema tidy-up, which is why it gets its own version and its own entry
/// rather than riding along with something else.
///
/// **`DROP COLUMN`, not a 12-step rebuild**, and therefore
/// [assertForeignKeysCanBeDisabled] is not called — the same reasoning
/// [migrateV2ToV3] sets out at length. `ALTER TABLE ... DROP COLUMN` drops no
/// table, so `ON DELETE CASCADE` is never armed and there is no precondition to
/// check; invoking the guard anyway would teach the next reader it is a rite
/// rather than a check on a property. SQLite has supported the statement since
/// 3.35 and this application ships 3.53.
///
/// **Dropped only if present.** `customers.economic_id` exists on every
/// database created before this version and on none created after, and the two
/// snapshot columns are added by earlier steps in this same ladder — so a
/// single upgrade can reach here having just created a column it is about to
/// remove. That is deliberate: the alternative is editing [migrateV2ToV3] and
/// [migrateV4ToV5] to skip them, which would make a migrated database a
/// different shape from a freshly created one at v3 and v5 and break the
/// intermediate schema comparisons — the exact "never mutate a shipped
/// migration" failure §6 warns about. The wasted `ADD` costs one statement on
/// one upgrade.
Future<void> migrateV6ToV7(Migrator m) async {
  final db = m.database as AppDatabase;

  await _dropColumnIfPresent(m, db, db.customers, 'economic_id');
  await _dropColumnIfPresent(m, db, db.settings, 'seller_economic_id');
  await _dropColumnIfPresent(
    m,
    db,
    db.invoices,
    'customer_economic_id_snapshot',
  );

  // As in every step before it: nothing here can create a dangling reference —
  // no key is touched — but the check costs one pragma while we can still
  // refuse to open.
  // soft-delete-exempt: an integrity pragma, not a read of user rows.
  final violations = await db.customSelect('pragma foreign_key_check').get();
  if (violations.isNotEmpty) {
    throw StateError(
      'the v6 -> v7 economic-id migration left ${violations.length} '
      'foreign-key violation(s); refusing to open. See D-106.',
    );
  }
}

/// Creates a column that a shipped migration adds but this file no longer
/// declares, so that the historical step still produces its historical shape.
///
/// **The alternative is editing the shipped step to omit the column**, and that
/// is what §6 forbids: a v3 database reached by migration would then differ
/// from the v3 schema dump the migration tests compare against, and every
/// intermediate comparison in `*_migration_test.dart` would fail — correctly,
/// because the two shapes really would have diverged. The column has to exist
/// at v3 and at v5 because it did; [migrateV6ToV7] is where it stops existing.
///
/// Literal DDL, since there is no [GeneratedColumn] left to hand
/// [Migrator.addColumn]. Both retired columns were plain nullable text with no
/// SQL constraint — `withLength` is a Dart-side check that drift emits nothing
/// for — so `TEXT NULL` is exactly what the generator produced. Verified
/// against `drift_schemas/drift_schema_v5.json` rather than assumed.
///
/// The identifiers are interpolated because they name a column that cannot be
/// bound as a parameter in DDL. D-018 forbids user input in SQL strings; the
/// only values that reach here are the two compile-time literals at the call
/// sites in this file, and none can come from anywhere else.
Future<void> _addRetiredColumnIfAbsent(
  AppDatabase db,
  String table,
  String column,
) async {
  final Set<String> present = await _columnNames(db, table);
  if (present.contains(column)) return;

  await db.customStatement('alter table $table add column $column text null');
}

/// Drops [column] from [table] if the table still has it.
///
/// Asks the database rather than reasoning about which earlier steps ran, for
/// the reason [_addColumnIfAbsent] does: a column may be absent because this
/// database was created after it was retired, or present because it was created
/// before — and `DROP COLUMN` on a column that is not there is an error that
/// would leave the database unopenable for exactly one of those populations.
Future<void> _dropColumnIfPresent(
  Migrator m,
  AppDatabase db,
  TableInfo<Table, dynamic> table,
  String column,
) async {
  final Set<String> present = await _columnNames(db, table.actualTableName);
  if (!present.contains(column)) return;

  await m.dropColumn(table, column);
}

/// v7 -> v8 (D-117): the display unit joins the settings row.
///
/// One nullable-free `ADD COLUMN` with a default of `0` —
/// [MoneyDisplayUnit.toman], which is what every database in existence has been
/// doing since the first release. No value is migrated because there is nothing
/// to migrate from and the default is not a guess: it is the behaviour the row
/// already had.
///
/// **It moves no money.** The column decides how an amount is displayed and
/// entered, not how it is stored; every amount column in this schema is integer
/// Rial before this step and after it (§4, D-002). A migration that touched a
/// figure to "convert" it would be the one thing this setting must never do.
///
/// `ADD COLUMN`, so no table is rebuilt, no `ON DELETE CASCADE` is armed, and
/// [assertForeignKeysCanBeDisabled] is not called — the same reasoning
/// [migrateV5ToV6] sets out.
Future<void> migrateV7ToV8(Migrator m) async {
  final db = m.database as AppDatabase;

  await _addColumnIfAbsent(m, db, db.settings, db.settings.displayUnit);

  // As in every step before it: nothing here can create a dangling reference,
  // but the check costs one pragma while we can still refuse to open.
  // soft-delete-exempt: an integrity pragma, not a read of user rows.
  final violations = await db.customSelect('pragma foreign_key_check').get();
  if (violations.isNotEmpty) {
    throw StateError(
      'the v7 -> v8 display-unit migration left ${violations.length} '
      'foreign-key violation(s); refusing to open. See D-117.',
    );
  }
}

/// Adds [column] to [table] unless the table already has it.
///
/// Asks the database rather than reasoning about which earlier steps ran:
/// `PRAGMA table_info` is what the table actually looks like on this device,
/// and the reason a column may already be there ([migrateV1ToV2] rebuilding at
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
