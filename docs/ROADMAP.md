# Roadmap

> Status values: `NOT_STARTED` · `IN_PROGRESS` · `BLOCKED` · `COMPLETED`
> Every phase carries a **security note**: what new data is stored, what new inputs
> are accepted, what new permissions or platform surfaces are touched, and whether the threat model
> changes.
>
> A phase is only `COMPLETED` when `flutter analyze` is clean and `flutter test` passes.

---

## Phase 0 — Environment and Setup

**Status:** `IN_PROGRESS` — decisions settled and the AndroidX probe passed; **blocked** on the
D-020 encryption proof, which needs Windows Developer Mode and an Android device or emulator.

**Goal.** Establish the toolchain, verify every target platform builds, document the architecture and
seed `docs/`.

**Completed**

- Inspected the repository: a stock `flutter create` scaffold for android/web/windows, untouched
  except for the project spec.
- Recorded Flutter 3.47.1 (stable) / Dart 3.13.1; `flutter doctor` reviewed.
- Verified baseline build status on **all three** target platforms (see `CURRENT_STATE.md`).
- Verified SQLCipher availability empirically on Windows rather than assuming it — SQLite 3.53.4,
  `cipher_version 4.18.0 community`, encrypted file header confirmed, unkeyed reopen rejected.
- Resolved the full Phase 1 dependency set and pinned concrete versions (D-015).
- Discovered that `sqlcipher_flutter_libs` and `sqlite3_flutter_libs` are **end-of-life** and
  established the maintained replacement path (D-010).
- Discovered that pub.dev and Google-hosted infrastructure are unreachable from this machine, and
  identified working mirrors (D-014).
- Created `docs/` — `PROJECT.md`, `ROADMAP.md`, `CURRENT_STATE.md`, `ARCHITECTURE.md`,
  `DECISIONS.md`.

**Completed 2026-08-23**

- All four owner decisions settled and recorded: **D-014** (pub.dev only, VPN locally),
  **D-010** (encrypted SQLite via `package:sqlite3` build hooks, **`sqlite3mc`** by owner override —
  SQLCipher has no Web support and Web is a target), **D-015 / D-016** (drop `custom_lint`,
  `riverpod_lint`, `drift_flutter`), **D-019** (`git init` + commit policy).
- Three new decisions appended: **D-020** (`PRAGMA key` ordering), **D-021** (گزارش‌ها omitted from
  Phase 1 navigation), **D-022** (Vazirmatn standard variant, 400/500/700).
- The project spec reworded away from the SQLCipher brand to "encrypted SQLite".
- Git initialized on `main` with a hardened `.gitignore` and a versioned, verified pre-commit gate.
- Vazirmatn `v33.003` standard static TTFs (400/500/700) + `OFL.txt` committed to `assets/fonts/`,
  provenance and sha256 recorded in `docs/ENVIRONMENT.md`.
- `docs/ENVIRONMENT.md` created.
- **Build hooks need no experimental flag** on Flutter 3.47.1 — `enable-native-assets` defaults to on.
- Flutter 3.47.1 / Dart 3.13.1 pairing confirmed correct against the release cadence.

**Completed later on 2026-08-23**

- Mirrors configured user-globally (D-014 amendment); nothing mirror-related in the repository.
- `tools/sanitize_lockfile` written and verified; lockfile regenerated and canonical.
- Application ID set to `io.github.erysaw.factorino`.
- First three commits made; working tree clean.
- `.gitattributes` added after CRLF/LF churn was found corrupting diffs.
- **AndroidX resolution probe PASSED** — `flutter build apk --debug` succeeds with
  `flutter_secure_storage`; the APK carries `libdartjni.so`, so the native path is exercised.
  Required installing `android-35` and `cmake;3.22.1` by hand from the Tencent SDK mirror
  (SHA-1 verified), because `dl.google.com` is fully blocked.
- `compileSdk` pinned to 37 for `flutter_secure_storage`.
- `sqlite3mc` encryption verified on the Dart VM, and the D-020 ordering hazard **empirically
  confirmed** — a statement before `PRAGMA key` yields a plaintext file plus a misleading
  "file is not a database" error.

**Remaining (blocking Phase 1)**

- **Windows Developer Mode** — administrator required. Without it no plugin-using Windows build
  runs at all.
- **An Android device or emulator** — none currently available.
- **End-to-end encryption proof** — a real Flutter app, Drift, Android **and** Windows: write, close,
  reopen without the key, confirm rejection (D-020). Blocked on the two items above.

**Known issues**

- Windows Developer Mode is off; no plugin-using Windows build is possible until an administrator
  enables it.
- No Android device or emulator is available.
- Every `flutter pub get` re-contaminates `pubspec.lock` with the mirror host. `sanitize_lockfile`
  must be run after each resolve; the pre-commit hook is the backstop.
- `flutter doctor`'s "Android license status unknown" is a **stale check, not a failure**: the
  `--licenses` option is removed from the new Android CLI, the canonical licence hash file is
  present, and `flutter build apk --debug` succeeds. No licence files were fabricated to silence it.
- Web has not been rebuilt since plugins were added.

**Security note.** No user data is stored yet and no new inputs are accepted. The threat model is
nonetheless affected in three ways, all now closed or explicitly bounded:

- The encryption package named in the project spec was end-of-life. Resolved by D-010 — encryption now
  comes from the maintained `package:sqlite3` build hooks, whose downloads are sha256-pinned and
  carry SLSA level 3 attestations from 3.5.2 onward.
- The dependency supply chain briefly routed through a third-party mirror — precisely the
  "dependency supply-chain drift" risk the project spec names. **Closed by D-014**: `pub.dev` is the
  only permitted host, the mirror-derived lockfile is to be destroyed rather than kept, and the
  pre-commit hook fails any commit that reintroduces another host.
- Repository hygiene now precedes the first commit rather than following it: the hardened
  `.gitignore` and the pre-commit secrets gate exist before any secret, keystore or local database
  could plausibly be created (D-019).

---

## Phase 1 — Foundation and Architecture

**Status:** `NOT_STARTED` — decisions are settled; blocked on the Phase 0 verifications above
(pub.dev reachability, the AndroidX probe, and the encryption proof).

**Goal.** The complete skeleton — structure, theme, localization, database, repositories, routing,
money engine, responsive shell, and four screens reading real data. No feature depth.

**Tasks**

1. Feature-based project structure under `lib/`.
2. Riverpod setup with code generation.
3. Drift database with encrypted SQLite (`sqlite3mc`, D-010), the D-020 PRAGMA ordering, and secure key management.
4. Initial tables carrying the sync-ready columns (D-011).
5. Repository layer exposing domain models, never Drift rows.
6. `go_router` configuration with real URLs on Web.
7. Theme system and design tokens, light and dark.
8. Persian localization, RTL, Vazirmatn, digit normalization utilities.
9. Money engine in `core/money/`, pure Dart, **with unit tests**.
10. Jalali date utilities including Jalali-period boundary helpers.
11. Responsive app shell (mobile / tablet / desktop).
12. Dashboard, Customers, Products, Invoices screens — real data, no mocks.
13. `docs/` fully populated and kept current.

**Explicitly out of scope.** Supabase, authentication, cloud sync, PDF generation, AI features,
payment gateways, subscriptions, push notifications, advanced analytics.

**Security note.** This is the phase where the threat model becomes real. New at rest: the encrypted
SQLite database and the encryption key in platform secure storage. New inputs: all customer and
product free-text fields, plus every numeric field — each requiring boundary validation, length and
character-class limits, and digit normalization. New platform surfaces: Android Keystore / Windows
DPAPI via `flutter_secure_storage`, filesystem access under `%APPDATA%` on Windows. Android manifest
hardening (`allowBackup=false`, `usesCleartextTraffic=false`) and the Web CSP land here, as does the
logging wrapper that keeps national IDs, phone numbers, names and amounts out of every log.

---

## Phase 2 — Customers

**Status:** `NOT_STARTED`

**Goal.** Full customer management: list with search, create, edit, soft delete, detail view.

Includes normalization-insensitive Persian search (ی/ي, ک/ك, ZWNJ), Iranian mobile validation with
`+98` / `0098` handling, and national-ID checksum validation.

**Security note.** First storage of third-party personal identifiers — national ID, economic ID,
phone numbers. These are the highest-sensitivity fields in the product and must never appear in any
log or error message. Field-level length and character-class limits are enforced at the boundary.

---

## Phase 3 — Products and Services

**Status:** `NOT_STARTED`

**Goal.** Product and service catalogue: list, create, edit, soft delete, units, pricing.

**Security note.** No new sensitive data classes; commercial pricing only. Numeric input validation
against the `kMaxAmountRial` ceiling begins here.

---

## Phase 4 — Invoice Creation

**Status:** `NOT_STARTED`

**Goal.** The core flow: build an invoice from customers and products, per-line and invoice-level
discounts, tax resolution, live totals, transactional invoice-number allocation.

This phase consumes the Phase 1 money engine; it must not reimplement any part of it. The money
engine unit tests from the project spec must all pass before this phase can be marked complete.

**Security note.** No new data classes; the risk here is correctness rather than confidentiality. The
invoice-number sequence allocation must be transactional to avoid a race.

---

## Phase 5 — Invoice Management and Payments

**Status:** `NOT_STARTED`

**Goal.** Invoice list with filters, detail view, status lifecycle, cancellation, and payment
recording with derived `partiallyPaid` / `paid` status recomputed on every payment write.

**Security note.** Payment records add amounts and dates but no new identifiers. Editing rules become
a data-integrity control: only `draft` invoices are editable or deletable.

---

## Phase 6 — Backup and Restore

**Status:** `NOT_STARTED` — required in the MVP.

**Goal.** Encrypted export to a user-chosen location (Android SAF, Windows native dialog, Web
download), transactional import with version compatibility checking, and a last-backup reminder in
settings.

Deferred to later: scheduled backups, CSV export, cloud backup.

**Security note.** The highest-risk phase in the MVP. A backup file is the entire customer and
invoice database in one portable artifact. It must be encrypted with a user-supplied password via a
KDF (never the raw password as a key), carry a format version and an HMAC integrity check so a
tampered or corrupted file is rejected rather than partially applied, and import must be
all-or-nothing. The UI must state in Persian that losing the password means losing the backup.
Exported files must be covered by `.gitignore`.

---

## Phase 7 — PDF Generation

**Status:** `NOT_STARTED` — interface only in Phase 1.

**Goal.** Implement `InvoiceDocumentGenerator` with Persian shaping, RTL layout, Jalali dates,
Toman/Rial and a professional invoice layout. The renderer receives a fully computed, already
formatted view model and never recomputes totals.

**Security note.** Generated PDFs contain full customer and financial data and are written to
user-accessible storage. Temporary files must be cleaned up, and any share/print intent on Android is
a new outbound data surface.

---

## Phase 8 — Dashboard and Reports

**Status:** `NOT_STARTED`

**Goal.** Real aggregates over Jalali periods, computed in SQL rather than Dart loops.

**This is where "گزارش‌ها" enters the product.** Per D-021 it is omitted from navigation entirely
until this phase — no disabled item, no coming-soon placeholder, and no registered route. Adding the
destination here also means adding it to the navigation shell and the router for the first time.

**Security note.** No new data. Aggregation queries must remain parameterized (D-018) and must not
leak amounts into logs.

---

## Phase 9 — Security Hardening and Audit

**Status:** `NOT_STARTED`

**Goal.** App lock (PIN + biometric via `local_auth`), idle auto-lock and lock on resume, PIN stored
only as a salted KDF hash, `FLAG_SECURE` on financial screens, R8 and resource shrinking, release
signing from a gitignored properties file, and a full pass over the §7 checklist.

**Security note.** Adds the biometric permission and a new authentication surface. Revisit the Web
in-memory-key question deferred in D-012.

---

## Phase 10 — Authentication · Phase 11 — Supabase Cloud Sync

**Status:** `NOT_STARTED`

Sync is where D-013 (invoice-number collisions across devices) must finally be solved, and where the
`sync_status` columns shipped in Phase 1 come into use.

**Security note.** The first outbound network surface in the product. Only the anon key ships in the
client; Row Level Security is enabled on every table from the first migration. The threat model gains
a server and a transport.

---

## Phase 12 — Web and Windows Optimization · Phase 13 — Performance · Phase 14 — Testing · Phase 15 — Release

**Status:** `NOT_STARTED`

Phase 12 includes the Drift-on-Web setup (`sqlite3.wasm` + worker in `web/`) and the Persian font
preload/subset work. Phase 13 covers query indexing and startup time against realistic data volumes.
Phase 14 broadens coverage to repository and widget tests. Phase 15 covers store metadata, signing,
and the release checklist.

**Security note.** Phase 15 is the last point at which the §7 checklist can be verified end to end
before real user financial data exists on real devices.
