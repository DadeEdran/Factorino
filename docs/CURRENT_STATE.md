# Current State

> The continuity file. A fresh session reads this first and continues from the Next Action.
> Last updated: **2026-08-23**

---

## Phase

**Phase 0 — Environment and Setup · `COMPLETED`**
**Phase 1 — Foundation and Architecture · `IN_PROGRESS`**

Phase 1 is being delivered in six reviewable increments at the owner's instruction, each reported
and **stopped for review** rather than landing as one pile:

| # | Increment | Status |
|---|---|---|
| a | Drift schema, migration setup, soft-delete helper | `COMPLETED` — awaiting review |
| b | `core/money/` engine + unit tests (§4) | ← **next** |
| c | Jalali date layer and digit normalization + tests | `NOT_STARTED` |
| d | Repositories and domain models | `NOT_STARTED` |
| e | Theme, localization, routing, responsive shell | `NOT_STARTED` |
| f | The four screens, on real data | `NOT_STARTED` |

(a) and (b) precede all UI work: everything else reads from the schema and the money engine.

## Verification status

```
flutter analyze:            PASS   (No issues found)
flutter test:               PASS   (69/69)
Android build (plugins):    PASS   debug APK carries lib/arm64-v8a/libsqlite3mc.so (1.9 MB)
Windows build (plugins):    PASS
Web build:                  NOT_RETESTED since plugins were added
D-020 proof - Windows:      PASS   5/5
D-020 proof - Android:      PASS   5/5 on a Redmi Note 8 Pro, Android 11 (API 30, arm64)
Startup path - Windows:     PASS   six tables created through the keyed connection
Startup path - Android:     PASS   same, at /data/user/0/io.github.erysaw.factorino/files
```

## What was completed this session

**Phase 0 (earlier):** the D-020 encryption proof on both platforms, the corrected pragma ordering,
the three named sqlite3mc traps, and the encryption slice as production code. See `DECISIONS.md`
D-020 and D-023.

**Phase 1 increment (a) — the schema.**

Six tables, each mixing in `SyncColumns`, so the six D-011 columns (`id` UUID v4, `created_at`,
`updated_at`, `deleted_at`, `sync_status`, `last_synced_at`) **cannot be omitted by construction**
rather than by convention. `schema_shape_test.dart` verifies it per table, so the seventh table gets
the same treatment automatically.

| Guarantee | How it is held |
|---|---|
| Every table has the sync columns, keyed on a text UUID | `SyncColumns` mixin + `schema_shape_test.dart` |
| `deleted_at IS NULL` on every read | `selectAlive` / `countAlive`, with `soft_delete_usage_test.dart` failing the build on an unexplained raw `select(` in `lib/` |
| Invoice items and payments never outlive their invoice | `ON DELETE CASCADE`, tested |
| A customer with invoices cannot be hard-deleted | SQLite `NO ACTION` — the delete throws, tested |
| An issued invoice number is never reused | unique index that **covers soft-deleted rows**, tested |
| Money never becomes floating point | integer columns, checked by `_rial` / `_bp` / `_milli` suffix across the whole schema |
| Foreign keys are actually on | `beforeOpen` reads the pragma back and throws if it is not `1` |
| Configuration is never missing | settings row seeded in `onCreate`, kept single by `CHECK (singleton = 1)` |

**Startup is wired** (`main.dart` → `openAppDatabase`): key from the OS keystore → keyed open →
first statement, which runs the migration → **`assertDatabaseFileIsEncrypted`**. The assertion must
come last: before the first write the file may not exist, and "no file" must never read as
"encrypted". `main.dart` renders an empty `Scaffold` — a temporary English placeholder would violate
§1 on its way to being deleted, and Persian strings belong to increment (e).

**Verified on the real targets, not only in unit tests.** `integration_test/startup_test.dart`
creates the six tables through the keyed connection and reopens with the keystore key, on the Redmi
and on Windows both.

**Decisions recorded:** D-024 (UUID generated in-repo, no `package:uuid`), D-025 (denormalized
`search_name` for Persian-insensitive search), plus an implementation note on D-013 (numbering
stored as `number_year` + `number_sequence`, not parsed back out of the formatted string).

**Notable:** the encrypted `sqlite3mc` library loads under `flutter test` on the Dart VM, so schema
and repository tests run against a **real encrypted database file**, not an in-memory stand-in.
Referential integrity, cascades and CHECK constraints are properties of the real file.

## Known issues

| # | Issue | Impact |
|---|---|---|
| 1 | `onUpgrade` throws by design — no v1→v2 path exists | The first schema change must add a migration step **and** a migration test (§6, §14). A build is already installed on the device, so its database needs migrating rather than reinstalling. |
| 2 | The database opens on the main isolate | Phase 13 moves it to `createInBackground`. Until then the `setup` closure must stay isolate-sendable — recorded in `ARCHITECTURE.md` §B.5. |
| 3 | `search_name` is empty | Filled once the normalizer lands in (c) and repositories write it in (d). |
| 4 | MIUI re-blocks `flutter test`'s install on a *fresh* install | `adb install -r` once by hand, then `flutter test -d <device>` works. Setting: Developer options → Install via USB. |
| 5 | `pub.dev` 403; `dl.google.com` blocked | Mirrors (D-014). Run `sh tools/sanitize_lockfile` after **every** resolve — 97 URLs this session. |
| 6 | `flutter doctor` "Android license status unknown" | Stale check, not a failure. See `ENVIRONMENT.md`. |
| 7 | Release builds signed with debug keys | Phase 15. |
| 8 | Web not retested; Web gets **no** encryption at rest (D-012) | Phase 12 must supply a separate Web path. |

## Important context for a future session

- **The cipher pragmas come BEFORE `pragma key`.** Reversing them is silent (D-020).
- **Never assert encryption with `PRAGMA cipher_version` or `PRAGMA cipher`** — both are false
  witnesses. Assert on the file header.
- **Do not open a database anywhere but `openEncryptedDatabase`**, and **do not read rows without
  `selectAlive`**. Both are enforced by tests that scan `lib/`; if one fails, route through the
  helper rather than relaxing the test. The soft-delete guard has a deliberate escape hatch:
  `// soft-delete-exempt: <reason>` on or above the line.
- **`sh tools/sanitize_lockfile` after every `flutter pub get`.**
- **Run `dart run build_runner build` after touching any table**, or `app_database.g.dart` goes
  stale. The generated file resolves `uuidV4`, `nowMillis` and the enums through `app_database.dart`'s
  imports, which is why that file imports things it does not appear to use.
- Mirror configuration is **user-global only** and must never enter the repository.

## Recently changed files

```
pubspec.yaml / pubspec.lock                       + drift_dev, build_runner (pinned)
lib/core/utils/uuid.dart                          NEW
lib/data/database/tables/*.dart                   NEW  six tables + SyncColumns mixin
lib/data/database/app_database.dart (+ .g.dart)   NEW  schemaVersion 1, migration, seeding
lib/data/database/soft_delete.dart                NEW  the single deleted_at helper
lib/data/database/database_bootstrap.dart         NEW  key -> open -> migrate -> assert
lib/main.dart                                     REWRITTEN  bootstraps; renders nothing yet
drift_schemas/drift_schema_v1.json                NEW  migration-test baseline
test/core/utils/uuid_test.dart                    NEW
test/data/database/schema_shape_test.dart         NEW
test/data/database/app_database_test.dart         NEW
test/data/database/soft_delete_usage_test.dart    NEW
test/data/database/single_open_path_test.dart     matcher fixed (false positive on @DriftDatabase)
test/widget_test.dart                             REMOVED  tested the deleted counter template
integration_test/startup_test.dart                NEW
docs/*                                            D-013 note, D-024, D-025; ROADMAP; ARCHITECTURE
```

## Last completed action

Delivered Phase 1 increment (a): the six-table schema behind the proven encrypted opener, migration
setup with the v1 schema dump, the soft-delete helper with build-failing enforcement, startup wired
through `assertDatabaseFileIsEncrypted`, and the startup path verified on Android and Windows.
69/69 tests pass, analyzer clean.

## Next action

**Stop for owner review of increment (a). Then build increment (b): `core/money/`.**

The money engine is pure Dart with **zero Flutter imports** so it is unit-testable without a widget
binding (§3). Implement the project spec exactly, in this order, and do not let the schema's stored
totals tempt a shortcut — the engine computes, the schema records:

1. `lineGross = unitPriceRial × quantityMilli ÷ 1000`, half-up.
2. `lineNet = lineGross − lineDiscount`, clamped at ≥ 0.
3. Invoice discount allocated across items **proportionally by `lineNet`**, remainders distributed
   by the **largest-remainder method** so the allocations sum to the invoice discount exactly.
4. `lineTax = round(lineNetAfterInvoiceDiscount × taxRateBp ÷ 10000)`, half-up; rate resolved
   item → invoice → settings default, first non-null wins, and the resolved rate is recorded.
5. Totals, plus optional `roundingUnitRial` with the delta kept as `roundingAdjustmentRial`.

Tests must cover, at minimum: zero quantity, fractional quantity, an item discount exceeding the
line total, invoice-discount allocation remainders, mixed tax rates, rounding boundaries, the
`kMaxAmountRial` ceiling guard (D-002, the Web 53-bit limit), and the invariant
`grandTotal == subtotal − invoiceDiscount + totalTax`.
