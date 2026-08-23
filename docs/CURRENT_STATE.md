# Current State

> The continuity file. A fresh session reads this first and continues from the Next Action.
> Last updated: **2026-08-23**

---

## Phase

**Phase 0 — Environment and Setup · `IN_PROGRESS`**

Both blockers from the previous session were cleared by the owner (Windows Developer Mode on; a
Redmi Note 8 Pro attached over USB). The **D-020 encryption proof now passes end to end on Windows**,
and the encryption slice it proves is committed production code, not a throwaway.

One item is left in Phase 0: the same proof on Android. The APK builds and **contains the native
library**, but the device refuses to install it — a MIUI setting, not a project defect.

## Verification status

```
flutter analyze:            PASS   (No issues found)
flutter test:               PASS   (23/23 - 22 new + the template smoke test)
Android build (plugins):    PASS   debug APK carries lib/arm64-v8a/libsqlite3mc.so (1.9 MB)
Windows build (plugins):    PASS   Developer Mode enabled; builds and runs
Web build:                  NOT_RETESTED since plugins were added
AndroidX plugin resolution: PASS
D-020 proof - Windows:      PASS   5/5 integration tests on the real Windows build
D-020 proof - Android:      BLOCKED  builds and packages; install refused by MIUI
```

## What was completed this session (2026-08-23, proof run)

**The ordering in D-020 was wrong, and the way it was wrong is the point.** A cross-open matrix over
three databases showed that `PRAGMA cipher = 'sqlcipher'` is **silently ignored when issued after
`PRAGMA key`**. The earlier probe — and the ordering written into D-020 — had been producing
sqlite3mc-default (ChaCha20) files while every check said "encrypted": correct header, key works,
no plaintext on disk. Only cross-opening the file with a different sequence reveals it. Encryption
at rest still held, but D-010's reason 3 (SQLCipher-format compatibility as the escape hatch from
implementation lock-in) did not. **The cipher pragmas must precede the key.** D-020 is amended,
D-010 carries the caveat, `ARCHITECTURE.md` §B.5 is corrected.

**Two more false witnesses, now named traps in D-020:**

| Pragma | What it reports | Why it is useless as evidence |
|---|---|---|
| `cipher_version` | *empty* under sqlite3mc | Reads as "not encrypted" on a correctly encrypted database |
| `cipher` | the value the connection was **configured** with | Answers `sqlcipher` on an unkeyed in-memory database |
| cipher pragma after key | no error at all | Accepted and ignored; wrong on-disk format |

The only assertion used anywhere is the **file header**: a plaintext SQLite file starts with
`SQLite format 3\0`; an encrypted one does not.

**Built (production code, ~200 lines, not a probe):**

- `lib/data/database/encrypted_database.dart` — `openEncryptedDatabase`, the single opener; the
  ordered setup sequence; `assertKeyPrecedesDatabaseAccess` (runs in production, before the first
  statement executes); `inspectDatabaseFile`; `assertDatabaseFileIsEncrypted`.
- `lib/core/security/database_encryption_key.dart` — 256-bit key from `Random.secure()`, OS
  keystore, `toString()` redacted, **`resetOnError: false`** (D-023 — the package default would have
  deleted the database key on a read error and silently orphaned every invoice).

**The ordering no longer depends on discipline.** 22 unit tests, of which the load-bearing ones are:
a guard that fails if any statement precedes `pragma key` (asserted against the very list the app
executes, not a copy), and `single_open_path_test.dart`, which scans `lib/` and fails the build if
any file other than the sanctioned opener mentions `NativeDatabase(`, `sqlite3.open(`,
`driftDatabase(` or `pragma key`.

**Verified in the Drift source** (`lib/src/sqlite3/database.dart:111`) that `setup` is invoked after
`useNativeFunctions()` — which issues no SQL — and before the version delegate's
`PRAGMA user_version`. The choke point is real, not assumed.

**The proof is an integration test, not a throwaway app** — `integration_test/`, so it is repeatable
on every target and cannot rot. Windows, 5/5:

```
database dir: C:\Users\...\AppData\Roaming\io.github.erysaw\factorino   (%APPDATA%, per §7)
keystore: DPAPI returns a stable 256-bit key across calls
header bytes: c1 51 85 73 60 bd 92 8e bd 32 39 d6 72 34 49 00   -> encrypted
sentinel on disk: absent from a raw byte scan
foreign_keys: 1 (on, for the connection Drift actually uses)
unkeyed reopen: REJECTED  SqliteException(26): file is not a database
wrong-key reopen: REJECTED
keyed reopen: 1 row, value intact
out-of-order: plaintext file + "file is not a database" - hazard reproduced on the real platform
startup assert: caught the plaintext database and refused to open it
```

**Android:** `flutter build apk --debug` succeeds and the APK carries
`lib/arm64-v8a/libsqlite3mc.so` (1.9 MB) — the build hook produces and packages the native library,
which was the main technical risk. Installation is refused identically by `flutter test`,
`adb install` and `adb shell pm install`.

## Known issues

| # | Issue | Impact |
|---|---|---|
| 1 | **MIUI refuses adb installation** (`INSTALL_FAILED_USER_RESTRICTED`) | **Blocks the Android half of the D-020 proof.** Fix on the device: Developer options -> **Install via USB**. Not a project defect. |
| 2 | `pub.dev` 403; `dl.google.com` fully blocked | Worked around by mirrors (D-014 amendment). SDK packages installed by hand from the Tencent mirror with SHA-1 verification. |
| 3 | Every `flutter pub get` re-contaminates `pubspec.lock` | Run `sh tools/sanitize_lockfile` after **every** resolve — 66 URLs were rewritten this session. Pre-commit hook is the backstop. |
| 4 | `flutter doctor` "Android license status unknown" | **Not a real failure — a stale check.** Details in `ENVIRONMENT.md`. No licence files were fabricated. |
| 5 | Release builds signed with debug keys | Template `TODO` in `android/app/build.gradle.kts`. Phase 15. |
| 6 | Web build not retested since plugins were added | Low. Also note Web gets **no** encryption at rest (D-012) — the opener is Android/Windows only and Phase 12 must supply a separate Web path. |
| 7 | The database is opened on the main isolate | `NativeDatabase(file, setup:)` rather than `createInBackground`. Fine for the proof; revisit in Phase 13 (the project spec forbids heavy sync work on the UI thread). Moving it means the setup closure must survive being sent to an isolate. |

## Important context for a future session

- **The cipher pragmas come BEFORE `pragma key`.** Reversing them is silent: the file is still
  encrypted, every check still passes, and the format is quietly not SQLCipher. See the matrix in
  D-020.
- **Never assert encryption with `PRAGMA cipher_version` or `PRAGMA cipher`.** Both are false
  witnesses. Assert on the file header.
- **Do not open a database anywhere but `openEncryptedDatabase`.** A test enforces this; if it fails,
  the fix is to route through the opener, never to relax the test.
- **`sh tools/sanitize_lockfile` after every `flutter pub get`.** Not optional, not one-time.
- **Do not fabricate Android licence-hash files** to make `flutter doctor` green.
- The `sqlite3mc` choice is an owner override of an earlier `sqlcipher` recommendation and is the
  better call (Web support, no OpenSSL). Do not "correct" it back.
- Mirror configuration is **user-global only** and must never enter the repository.
- SDK packages installed by hand, SHA-1 verified: `platforms/android-35`, `cmake/3.22.1`.

## Recently changed files

```
pubspec.yaml                                          + drift, sqlite3, path_provider,
                                                        integration_test, hooks: source sqlite3mc
pubspec.lock                                          regenerated, sanitized
lib/core/security/database_encryption_key.dart        NEW
lib/data/database/encrypted_database.dart             NEW
test/data/database/connection_setup_order_test.dart   NEW
test/data/database/database_file_state_test.dart      NEW
test/data/database/single_open_path_test.dart         NEW
integration_test/d020_encryption_proof_test.dart      NEW
docs/DECISIONS.md                                     D-020 amended; D-023 added; D-010 caveat
docs/ARCHITECTURE.md                                  §A rewritten; §B.5 ordering corrected
docs/ROADMAP.md                                       Phase 0 + Phase 1 status, security note
docs/CURRENT_STATE.md                                 this file
```

`lib/main.dart` is still the untouched template counter app.

## Last completed action

Corrected the D-020 ordering after disproving it empirically, built and committed the encryption
slice with its enforcement tests, and **passed the D-020 proof 5/5 on Windows**. Confirmed the
Android build packages `libsqlite3mc.so`, and found the Android run blocked by MIUI's install
restriction.

## Next action

**Run the Android half of the proof, then start Phase 1.**

1. On the Redmi: Settings -> Additional settings -> Developer options -> enable **Install via USB**
   (and **USB debugging (Security settings)** if present). It may require a signed-in Mi account.
2. `flutter test integration_test/d020_encryption_proof_test.dart -d dmbyayb6rombo7ci` — expect the
   same 5/5, and confirm the database path is under `/data/user/0/io.github.erysaw.factorino`.
3. Record the Android result in D-020 and this file, then begin Phase 1 with the Drift schema:
   define the six tables from the project spec with the sync-ready columns behind the existing
   `openEncryptedDatabase`, and wire `assertDatabaseFileIsEncrypted` into app startup.
