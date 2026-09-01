import 'dart:io';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/encrypted_database.dart';

/// The backup file format version.
///
/// Independent of [AppDatabase.schemaVersion], which travels beside it: the
/// schema says what shape the *data* is in, this says what shape the
/// *container* is in. They move for different reasons, so conflating them
/// would mean bumping one every time the other changed.
const int kBackupFormatVersion = 1;

/// The tables a backup carries, in **foreign-key-safe insert order**.
///
/// Reversed for deletion. Getting this wrong is not subtle — the container has
/// `foreign_keys = on` like every other connection (D-017) — but it is worth
/// naming once rather than being implicit in the order six calls happen to
/// appear in.
const List<String> kBackupTableOrder = <String>[
  'customers',
  'products',
  'invoices',
  'invoice_items',
  'payments',
  'settings',
];

/// Why an export failed.
///
/// Machine-readable; the Persian copy is `FailureMessage`'s job (§7).
enum BackupExportProblem {
  /// The finished container could not be reopened with the passphrase that
  /// wrote it. See [BackupService.exportTo] — this is the failure the
  /// verification reopen exists to catch.
  verificationReopenFailed,

  /// The reopened container did not hold what was written to it.
  verificationCountMismatch,

  /// The container was written but is not encrypted on disk. Should be
  /// unreachable — [openPassphraseKeyedDatabase] refuses an empty passphrase
  /// and D-020's ordering is asserted — and checked anyway, because the cost
  /// of being wrong is the entire customer database in the clear.
  notEncrypted,
}

/// Raised when an export could not be completed.
///
/// Carries no passphrase and no path: nothing about a backup is logged
/// (D-069).
class BackupExportFailure implements Exception {
  const BackupExportFailure(this.problem);

  final BackupExportProblem problem;

  @override
  String toString() => 'BackupExportFailure: ${problem.name}';
}

/// What an export produced, read back from the finished file.
///
/// The counts are the ones **verified in the reopened container**, not the ones
/// counted on the way in — otherwise the summary would describe the intent
/// rather than the artifact.
class BackupSummary {
  const BackupSummary({
    required this.formatVersion,
    required this.appSchemaVersion,
    required this.createdAt,
    required this.rowCounts,
    required this.sizeBytes,
  });

  final int formatVersion;
  final int appSchemaVersion;
  final DateTime createdAt;

  /// Table name to row count, **including soft-deleted rows**.
  final Map<String, int> rowCounts;

  final int sizeBytes;

  int get totalRows => rowCounts.values.fold<int>(0, (int a, int b) => a + b);

  @override
  String toString() =>
      'BackupSummary(v$formatVersion, schema v$appSchemaVersion, '
      '$totalRows rows, $sizeBytes bytes)';
}

/// Writes an encrypted backup container (D-069).
abstract interface class BackupService {
  /// Writes a backup of the live database to [file], keyed by [passphrase].
  ///
  /// [file] is a path in **app-private storage**. Delivering it to a location
  /// the user chose is the gateway's job, not this one (D-071).
  Future<BackupSummary> exportTo({
    required File file,
    required String passphrase,
  });
}

class DriftBackupService implements BackupService {
  DriftBackupService(this._live);

  final AppDatabase _live;

  @override
  Future<BackupSummary> exportTo({
    required File file,
    required String passphrase,
  }) async {
    // A stale container at this path would be opened and **added to**, not
    // replaced: the export would silently carry rows from a previous run.
    _discard(file);

    final DateTime createdAt = DateTime.now().toUtc();
    Map<String, int> written;

    try {
      written = await _write(file, passphrase, createdAt);
    } catch (_) {
      // Never leave a half-written container behind. A partial backup is worse
      // than none: it looks like a backup.
      _discard(file);
      rethrow;
    }

    try {
      return await _verify(file, passphrase, written);
    } catch (_) {
      _discard(file);
      rethrow;
    }
  }

  /// Creates the container and copies every row into it.
  Future<Map<String, int>> _write(
    File file,
    String passphrase,
    DateTime createdAt,
  ) async {
    final AppDatabase container = AppDatabase(
      openPassphraseKeyedDatabase(file: file, passphrase: passphrase),
    );

    try {
      // Constant DDL, not interpolated (D-018). Two tables rather than one:
      // the counts are a per-table logical completeness check, which answers a
      // different question from the container's per-page HMAC (D-069).
      await container.customStatement(
        'create table if not exists backup_meta ('
        'format_version integer not null, '
        'app_schema_version integer not null, '
        'created_at integer not null)',
      );
      await container.customStatement(
        'create table if not exists backup_table_counts ('
        'table_name text not null primary key, '
        'row_count integer not null)',
      );

      final Map<String, int> counts = <String, int>{};

      await container.transaction(() async {
        // `onCreate` seeds a settings row, and the copy below brings the live
        // one. Clearing first is what makes the container an exact copy rather
        // than a copy plus a default.
        for (final String name in kBackupTableOrder.reversed) {
          await container.customStatement('delete from ${_tableSql(name)}');
        }

        counts['customers'] = await _copy(
          container,
          (AppDatabase db) => db.customers,
        );
        counts['products'] = await _copy(
          container,
          (AppDatabase db) => db.products,
        );
        counts['invoices'] = await _copy(
          container,
          (AppDatabase db) => db.invoices,
        );
        counts['invoice_items'] = await _copy(
          container,
          (AppDatabase db) => db.invoiceItems,
        );
        counts['payments'] = await _copy(
          container,
          (AppDatabase db) => db.payments,
        );
        counts['settings'] = await _copy(
          container,
          (AppDatabase db) => db.settings,
        );

        await container.customInsert(
          'insert into backup_meta '
          '(format_version, app_schema_version, created_at) values (?, ?, ?)',
          variables: <Variable<Object>>[
            Variable<int>(kBackupFormatVersion),
            Variable<int>(container.schemaVersion),
            Variable<int>(createdAt.millisecondsSinceEpoch),
          ],
        );

        for (final MapEntry<String, int> entry in counts.entries) {
          await container.customInsert(
            'insert into backup_table_counts (table_name, row_count) '
            'values (?, ?)',
            variables: <Variable<Object>>[
              Variable<String>(entry.key),
              Variable<int>(entry.value),
            ],
          );
        }
      });

      return counts;
    } finally {
      await container.close();
    }
  }

  /// Reopens the finished file and checks it holds what was written.
  ///
  /// **This is part of the success path, not a test.** The key pragma cannot
  /// take a bound variable, so the passphrase reaches SQL as an escaped literal
  /// (D-069). (Spelled out in words here on purpose: `single_open_path_test`
  /// scans `lib/` for that pragma's literal name and does not exempt comments,
  /// and the guard is worth more strict than this sentence is worth verbatim.) If that escaping is ever wrong, the file is keyed with a string
  /// other than the one the user typed — and nothing else in the flow would
  /// notice, because writing succeeds. The user would find out on the day they
  /// needed the backup, having by then deleted the data it was standing in for.
  ///
  /// So an export is not reported successful until the artifact has been opened
  /// again, cold, with the password the user typed (project owner, 2026-09-01).
  Future<BackupSummary> _verify(
    File file,
    String passphrase,
    Map<String, int> written,
  ) async {
    if (inspectDatabaseFile(file) != DatabaseFileState.encrypted) {
      throw const BackupExportFailure(BackupExportProblem.notEncrypted);
    }

    late final AppDatabase reopened;
    try {
      reopened = AppDatabase(
        openPassphraseKeyedDatabase(file: file, passphrase: passphrase),
      );
      // Forces the read: the executor is lazy, so constructing it proves
      // nothing on its own — the same laziness that hid the empty-passphrase
      // defect in (a).
      // soft-delete-exempt: forces the keyed connection to decrypt page 1.
      // Reads no user rows at all.
      await reopened.customSelect('select 1').get();
    } catch (_) {
      throw const BackupExportFailure(
        BackupExportProblem.verificationReopenFailed,
      );
    }

    try {
      final List<QueryRow> metaRows = await reopened
          // soft-delete-exempt: `backup_meta` is the container's own metadata
          // and has no `deleted_at` column.
          .customSelect(
            'select format_version, app_schema_version, created_at '
            'from backup_meta',
          )
          .get();
      final List<QueryRow> countRows = await reopened
          // soft-delete-exempt: `backup_table_counts` is the container's own
          // metadata and has no `deleted_at` column.
          .customSelect('select table_name, row_count from backup_table_counts')
          .get();

      if (metaRows.length != 1) {
        throw const BackupExportFailure(
          BackupExportProblem.verificationCountMismatch,
        );
      }

      final Map<String, int> stored = <String, int>{
        for (final QueryRow row in countRows)
          row.read<String>('table_name'): row.read<int>('row_count'),
      };

      // Compared against what was written AND re-counted from the tables
      // themselves, so a count row that was never updated cannot agree with
      // itself into a pass.
      for (final String name in kBackupTableOrder) {
        final int expected = written[name] ?? -1;
        final List<QueryRow> actual = await reopened
            // soft-delete-exempt: this count must include tombstones, because
            // the backup carries them (see `_copy`). Filtering them here would
            // make the verification disagree with what was written, and would
            // fail every export from a database that has ever had a row
            // deleted.
            .customSelect('select count(*) as c from ${_tableSql(name)}')
            .get();
        final int live = actual.single.read<int>('c');

        if (stored[name] != expected || live != expected) {
          throw const BackupExportFailure(
            BackupExportProblem.verificationCountMismatch,
          );
        }
      }

      final QueryRow meta = metaRows.single;
      return BackupSummary(
        formatVersion: meta.read<int>('format_version'),
        appSchemaVersion: meta.read<int>('app_schema_version'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          meta.read<int>('created_at'),
          isUtc: true,
        ),
        rowCounts: Map<String, int>.unmodifiable(written),
        sizeBytes: file.lengthSync(),
      );
    } finally {
      await reopened.close();
    }
  }

  /// Copies every row of one table, **including soft-deleted ones**.
  ///
  /// A backup that dropped tombstones would resurrect deleted customers and
  /// invoices on restore, and would hand the future sync layer a device whose
  /// deletions never happened (§6).
  // `D extends Insertable<D>` rather than `DataClass`: every drift data class
  // is both, and it is the `Insertable` half that lets a row read out of one
  // database be written straight into the other with no mapping layer in
  // between — which is the property that makes the copy exact by construction
  // rather than by a field list somebody has to keep up to date.
  Future<int> _copy<T extends Table, D extends Insertable<D>>(
    AppDatabase container,
    TableInfo<T, D> Function(AppDatabase db) pick,
  ) async {
    // soft-delete-exempt: a backup must carry tombstones, or a restore
    // resurrects every deleted row. This is the escape hatch's stated case.
    final List<D> rows = await _live.select(pick(_live)).get();
    if (rows.isEmpty) return 0;

    await container.batch((Batch batch) {
      batch.insertAll(pick(container), rows);
    });
    return rows.length;
  }

  /// Guards the table names that reach SQL.
  ///
  /// The names come from [kBackupTableOrder], a constant in this file, so no
  /// user input is involved — but D-018 forbids building SQL by interpolation
  /// and "it is a constant" is exactly the sentence that precedes the first
  /// exception to that. This makes the closed set structural.
  String _tableSql(String name) {
    if (!kBackupTableOrder.contains(name)) {
      throw ArgumentError.value(name, 'name', 'not a backup table');
    }
    return name;
  }

  void _discard(File file) {
    for (final String path in <String>[
      file.path,
      '${file.path}-wal',
      '${file.path}-shm',
    ]) {
      final File f = File(path);
      if (f.existsSync()) f.deleteSync();
    }
  }
}
