# Decision Log

> Append-only. Each entry records the date, the decision, the reason, and the alternatives
> considered. Do not reverse an established decision without a clear reason and a new appended entry.
>
> **Status legend**
> - `ACCEPTED` — settled; established in the project spec or confirmed by the project owner.
> - `PROPOSED` — recommended by the current session, **awaiting owner confirmation**.
> - `AMENDED` — an accepted decision whose *implementation* changed; the intent still stands.

---

## D-001 — UUID v4 primary keys, never AUTOINCREMENT

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** Every user-data table uses a `TEXT` UUID v4 primary key.

**Reason.** The app is offline-first today and cloud-synced later. Auto-increment integer IDs
allocated independently on two devices collide the moment those devices sync. UUIDs are
collision-free without coordination, so records created offline on a phone and on a desktop can merge
safely.

**Alternatives considered.** Integer autoincrement (rejected: collides across devices);
device-prefixed integers (rejected: still requires coordination and leaks device identity into keys);
ULID (viable and sortable, but adds a dependency for a benefit — index locality — that is not a
measured problem at this scale).

**Cost accepted.** UUID text keys are larger and slightly slower to index than integers. At the
designed scale (thousands of records) this is not material.

---

## D-002 — Money is integer Rial; no floating point in the money path

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** All monetary values are stored as integer Rial in a Dart `int` (64-bit). Percentages
(tax, percent discounts) are stored as basis points (`int`, 10% = `1000`). Quantities are stored
scaled by 1000 (`quantity_milli`, 1.5 becomes `1500`). `double` and `num` are forbidden anywhere in
the money path. Rounding is half-up at the Rial.

**Reason.** Binary floating point cannot represent decimal currency exactly. Accumulated
representation error produces invoices whose lines do not sum to their total — the single most
damaging class of bug this product can ship. Integer arithmetic is exact.

**Alternatives considered.** `double` (rejected outright); a `Decimal` package (rejected: adds a
dependency and allocation overhead to solve a problem that integer Rial already solves exactly,
because Rial has no sub-unit in practice).

**Web caveat.** On the web, Dart `int` compiles to a JS number, exact only to about 9.0e15. This is
far above any realistic invoice amount in Rial, but the money engine must still guard against values
beyond a defined `kMaxAmountRial` ceiling and reject them rather than silently lose precision.

---

## D-003 — Soft deletes on all user data

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** Every user-data table carries `deleted_at INTEGER?`. Deletion sets the timestamp. All
queries filter `deleted_at IS NULL` through a single shared query helper so it cannot be forgotten
per call site.

**Reason.** A hard delete cannot be propagated to another device — the other device has no way to
distinguish "this row was deleted" from "this row has not reached me yet", so the row resurrects on
the next sync. Soft deletes also make accidental deletion recoverable, which matters for financial
records.

**Alternatives considered.** Hard delete plus a tombstone table (rejected: same effect, more schema
and more join complexity).

**Consequence.** Customers and products referenced by any invoice are soft-deleted only, never hard
deleted. The UI must explain this in Persian rather than failing silently.

---

## D-004 — Invoice items snapshot title, unit and price

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** `invoice_items` stores a copy of the product title, unit, unit price (Rial) and the
resolved tax rate at the moment the invoice is created. Invoice pricing is **never** resolved by
joining to the live `products` row at read time.

**Reason.** An invoice is a historical financial document. If a product price changes next month,
every invoice already issued must still show — and total — exactly what it showed when issued.
Joining to live data would silently rewrite financial history.

**Alternatives considered.** Product price-history tables with validity ranges (rejected: correct but
substantially more complex to query and migrate, for no additional benefit here).

**Cost accepted.** The schema looks redundant. That redundancy is the feature.

---

## D-005 — Timestamps stored UTC, displayed Jalali

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** Every timestamp is stored as UTC epoch milliseconds (`INTEGER`). Display converts to
the Jalali (Shamsi) calendar with Persian formatting. A localized Persian date string is **never**
the source of truth.

**Reason.** A stored display string cannot be compared, sorted, ranged, or re-localized, and it bakes
one device timezone into the data permanently. Storing an absolute instant keeps queries correct and
keeps the door open for sync across devices in different timezones.

**Alternatives considered.** Storing Jalali Y/M/D integers (rejected: cannot express an instant,
breaks range queries across month boundaries); storing local time (rejected: ambiguous without an
offset).

---

## D-006 — Business and reporting periods are Jalali

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** "فروش این ماه" means the current **Jalali** month. Period boundaries are computed in
Jalali, converted to UTC instants, and then used as query bounds. Business-day boundaries assume
`Asia/Tehran`, derived explicitly rather than hardcoded as a fixed offset.

**Reason.** The user mental model, their tax year, and their business month are all Jalali. Reporting
on Gregorian month boundaries would produce numbers that do not match anything the user recognises.
This is a correctness requirement, not a nicety.

**Alternatives considered.** Gregorian periods with Jalali labels (rejected: actively misleading).

**Note.** Iran does not currently observe DST, but the implementation must not hardcode +03:30 in a
way that breaks for a user whose device is set to another timezone.

---

## D-007 — Riverpod for state management

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** Riverpod, code-generation flavor (`riverpod_annotation` + `riverpod_generator`).

**Reason.** Compile-time safe dependency injection, no `BuildContext` needed to read state, testable
providers with overridable dependencies, and first-class async and auto-dispose semantics — which
suits a repository-backed, database-driven app.

**Alternatives considered.** `provider` (less type-safe, `BuildContext`-bound); BLoC (more ceremony
per feature than this app size justifies); `setState` only (unworkable at this scale).

**If it becomes unmaintained.** Riverpod provider boundaries are ordinary Dart classes; migration
would be mechanical but wide. Risk accepted given its maturity and adoption.

---

## D-008 — Drift for persistence

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** Drift, with typed table definitions, generated DAOs, and generated migrations.

**Reason.** Compile-time checked SQL, typed row classes, transaction support, reactive query streams,
and — critically — a real migration and schema-dump testing story. Raw SQL string building is
forbidden (see D-018), and the Drift typed API is what makes that practical.

**Alternatives considered.** `sqflite` (no compile-time query checking, weaker migration tooling, no
desktop support without extra packages); raw `sqlite3` FFI (no type safety, hand-written migrations);
Isar/Hive (rejected: not relational — invoices are inherently relational, and a future
Supabase/Postgres sync target is relational).

---

## D-009 — go_router for routing

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** go_router for all navigation.

**Reason.** Real, shareable URLs on Web and working deep links on Windows and Android — both of which
are explicit product requirements. Declarative route definitions also keep navigation out of widget
logic.

**Alternatives considered.** Navigator 1.0 (no URL story on Web); auto_route (comparable, but adds a
second code generator for no benefit Drift and Riverpod generation do not already justify).

---

## D-010 — Encryption at rest via `package:sqlite3` build hooks, using SQLite3 Multiple Ciphers

**Date:** 2026-08-22 · **Amended and confirmed:** 2026-08-23 · **Status:** ACCEPTED

**Decision.** The database is encrypted at rest with SQLCipher on Android and Windows. The encryption
key is a securely generated random key held in `flutter_secure_storage` (Android Keystore / Windows
DPAPI), generated once on first launch, never hardcoded, never logged, never committed.

**Amendment.** the project spec names `sqlcipher_flutter_libs` as the mechanism. **That package was
declared end-of-life on 2026-02-15**, together with `sqlite3_flutter_libs`; both now publish only a
`+eol` version whose description reads *"Not used anymore, update to version 3.x of package:sqlite3
instead."* The native libraries were folded into `package:sqlite3` itself, which since 3.x builds and
bundles them through Dart build hooks.

The equivalent, maintained configuration is a `pubspec.yaml` user-define:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlcipher   # 'sqlite3mc' (SQLite3 Multiple Ciphers) is the alternative
```

**Verified on this machine, 2026-08-22** (Windows, standalone probe): SQLite 3.53.4 with
`cipher_version = 4.18.0 community`; the resulting database file does not begin with the
`SQLite format 3` header, and reopening it without the key is rejected. Encryption at rest is real,
not assumed.

**Sub-decision — `sqlcipher` vs `sqlite3mc`: resolved as `sqlite3mc`.** Both are offered by the same
build hook. This session recommended `sqlcipher` for fidelity to the wording in the project spec. **The
project owner overrode that on 2026-08-23 in favour of `sqlite3mc`**, and the override is better
reasoned than the recommendation it replaced:

1. **Web.** SQLCipher is not available on Web, and Web is a stated target platform. `sqlite3mc`
   works there. The recommendation had silently accepted a target-platform gap.
2. **OpenSSL.** The `sqlcipher` prebuilt links OpenSSL on Windows, Linux and Android — a licensing
   and binary-size cost — and may lag the default SQLite version. `sqlite3mc` needs neither and
   tracks a newer SQLite.
3. **Not locked in.** `sqlite3mc` is SQLCipher-format-compatible via
   `PRAGMA cipher = 'sqlcipher'; PRAGMA legacy = 4;`, so choosing it does not foreclose reading or
   producing SQLCipher-format databases later.

The governing requirement is **encryption at rest, not the SQLCipher brand**. The project spec
were reworded accordingly on 2026-08-23 to say "encrypted SQLite (SQLite3 Multiple Ciphers via
`package:sqlite3` build hooks)".

**How reason 1 interacts with D-012 — read both before changing either.** D-012 says Web data is
*not* meaningfully encrypted at rest, because any key the page can reach an attacker with the browser
profile can also reach. That remains true and is unchanged by this decision. The Web benefit of
`sqlite3mc` is therefore **not** a security claim: it is that one cipher implementation and one code
path cover all three targets, instead of an encrypted build for Android/Windows and a structurally
different unencrypted build for Web. Fewer divergent paths through the connection-open logic — the
exact place where D-020's silent failure modes live. Do not read this entry as softening D-012, and
do not let the Web build claim encryption at rest.

Configuration:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc
```

**Supply-chain note.** The build hook downloads prebuilt binaries from the package GitHub releases,
verified against sha256 hashes shipped inside the pub package, with SLSA level 3 attestations from
version 3.5.2 onward. `github.com` is reachable from this machine (see D-014). Building from source
is available as a fallback if downloading is unacceptable.

**Alternatives considered.** Pinning the EOL packages (rejected: unmaintained from day one, and it
forces `sqlite3` back to 2.x, which in turn forces Drift down to 2.31 — see D-015); application-level
field encryption (rejected: leaves indexes, table structure and query patterns in the clear, and
breaks `LIKE` and `ORDER BY`); no encryption (rejected: violates the threat model).

---

## D-011 — Offline-first, with a sync-ready schema from day one

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** v1 ships with no network dependency and no account. Every user-data table nevertheless
carries `id` (UUID), `created_at`, `updated_at`, `deleted_at`, `sync_status` and `last_synced_at`
from the first migration, even though nothing reads `sync_status` in Phase 1.

**Reason.** These columns are cheap to add now and expensive to add later: retrofitting them means
migrating live financial data on real user devices. Shipping the columns unused is the low-risk order
of operations.

**Alternatives considered.** Adding sync columns when sync is built (rejected for the reason above).

---

## D-012 — Web is the least-trusted target and must say so

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** The Web build does **not** claim encryption at rest. It shows a clear Persian notice
explaining that data stored in the browser is readable by anyone with access to that browser profile.
No sensitive data goes in `localStorage` or `sessionStorage`; a restrictive CSP ships in
`web/index.html`.

**Reason.** Browser storage (IndexedDB) cannot be meaningfully encrypted at rest against someone who
already has the browser profile — any key the page can reach, an attacker with profile access can
also reach. Simulating security we do not have is worse than disclosing the gap, because the user
would make storage decisions based on a false premise.

**Alternatives considered.** Deriving a key from a user password held only in memory (rejected for
v1: meaningfully better, but it forces a password prompt on every load and still exposes plaintext in
memory and in the WASM heap; revisit in the security-hardening phase); dropping the Web target
(rejected: it is a stated platform).

---

## D-013 — Invoice numbering, and the known multi-device collision risk

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** Invoice numbers follow `{prefix}-{jalaliYear}-{sequence:0000}` (for example
`INV-1405-0001`) with a configurable prefix, a unique index on the full number, and sequence
allocation inside a transaction to prevent a local race.

**Known limitation, deliberately not solved now.** Two devices working offline will both allocate the
same next sequence and collide when cloud sync arrives. This is documented rather than pretended
away. A `device_prefix` concept is reserved in the schema as the intended mitigation.

**Reason for deferring.** The correct fix (per-device ranges, or server-side allocation) depends on
the sync design, which does not exist yet. Building a speculative solution now would likely be the
wrong one.

---

## D-014 — pub.dev is the only host named in the lockfile; resolution goes through a mirror

**Date:** 2026-08-22 · **Decided:** 2026-08-23 · **Amended:** 2026-08-23 · **Status:** ACCEPTED (option 2 — see the amendment at the end of this entry; option 1 proved unreachable)

**Context.** Measured on this machine on 2026-08-22:

| Host | Result |
|---|---|
| `pub.dev` | **HTTP 403** |
| `storage.googleapis.com` (Flutter releases) | **HTTP 403** |
| `dl.google.com` / `maven.google.com` (Google Maven) | **HTTP 404** for valid artifact paths |
| `repo.maven.apache.org` | 200 |
| `services.gradle.org` | 200 |
| `github.com` / `api.github.com` | 200 |
| `mirrors.tuna.tsinghua.edu.cn/dart-pub` | 200 |
| `maven.aliyun.com/repository/google` | 200 |

`flutter pub get` fails outright against pub.dev with *"Insufficient permissions to the resource at
the https://pub.dev package repository"* — a geo-block presenting as an authorization error, not a
missing credential. Adding a pub token would not fix it.

**Decision (owner, 2026-08-23): option 1 — a VPN on the developer machine.** `pub.dev` is the
**only** canonical package host. Reachability is a local problem and is solved locally, so that
`pubspec.lock` stays canonical and portable and no other environment inherits this machine's
constraints.

Options as originally presented, for the record:

1. **A VPN or proxy on the developer machine**, leaving `pubspec.lock` pointing at `pub.dev`.
   Cleanest and most portable; keeps the lockfile canonical. ← **chosen**
2. **Environment-scoped mirror** — `PUB_HOSTED_URL` exported in the developer shell profile, plus a
   Gradle `repositories` mirror for `maven.google.com`. Documented in the README, never committed
   into `pubspec.lock` for release builds.
3. **Committed mirror configuration.** Rejected: it pins the project to a third-party mirror
   and makes the lockfile non-portable.

**Consequences, enforced rather than merely documented.**

- The contaminated `pubspec.lock` is **not** to be hand-edited or rewritten. With the VPN up it is
  deleted outright and regenerated by a fresh `flutter pub get` against `pub.dev`. Nothing real
  depends on it yet, so there is no reason to preserve a mirror-derived resolution.
- `pubspec.lock` must contain no `url:` other than `https://pub.dev`. This is enforced by
  `.githooks/pre-commit`, enabled per clone with `git config core.hooksPath .githooks`.
- Mirror configuration is **never** committed — not in `pubspec.yaml`, `pubspec.lock`, Gradle files,
  or CI. The local network situation is documented in `docs/ENVIRONMENT.md` instead.
- `package:sqlite3` build hooks are unaffected: they download prebuilt binaries from GitHub
  releases, which returns 200 from this machine. The hook's `url_pattern` user-define is the
  fallback if that ever changes.

**Superseded.** The VPN never carried this traffic — see the amendment at the end of this entry.
`pub.dev` returned `403` (Google GFE block page) from egress IP `195.74.93.35` throughout, while
`flutter doctor`'s `[✓] Network resources` line passed the whole time and is not a useful signal
for this.

**Current state of the working tree.** The existing `pubspec.lock` was *not* a valid pub lockfile —
it was a 54-line JSON fragment listing five packages as `direct main`, which pub does not produce. It
has been replaced by a valid lockfile generated through the Tsinghua mirror, which is what allowed
`flutter analyze`, `flutter test` and all three platform builds to be verified today. **The mirror
URL is currently written into `pubspec.lock` and must be regenerated once this decision is made.**
The original file is preserved at the session scratchpad as `pubspec.lock.orig`.

**Android-specific risk.** The Android build succeeds today only because a roughly 1 GB Gradle module
cache is already populated locally. Phase 1 adds native plugins (`flutter_secure_storage`, and later
`local_auth`) that pull **new** AndroidX artifacts. With Google Maven unreachable those resolutions
will fail. This must be validated at the very start of Phase 1, before any application code depends
on it.


### Amendment, 2026-08-23 — the VPN is not viable; mirror fallback with guardrails

**Status:** ACCEPTED · supersedes the option-1 choice recorded above, which was never reachable.

**Why option 1 failed.** The owner's VPN routes **per-application** through Proxifier, and `flutter`
and `dart` are not among the routed applications. `flutter pub get` continued to fail with
*"Insufficient permissions to the resource at the https://pub.dev package repository"*, and terminal
egress still showed the original Iranian IP. The option was sound in principle and simply does not
match how this machine's tunnel works.

**Decision: option 2 — the environment-scoped mirror — with guardrails.**

| Concern | Mirror | Verified |
|---|---|---|
| Dart packages | `PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/dart-pub` | 301→200 |
| Google Maven | `https://maven.aliyun.com/repository/google` | 200 |
| Flutter engine artifacts | `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` | 200 |

**Scope is deliberately narrow — only what is actually blocked gets mirrored.** Measured
2026-08-23: `plugins.gradle.org` 200, `repo.maven.apache.org` 200. Neither is mirrored. Redirecting
traffic that is not blocked would enlarge the supply-chain surface for no benefit, which is the
opposite of the point.

**Where the configuration lives — and one correction to the instruction.** All of it is user-global
and outside the repository:

- `PUB_HOSTED_URL` and `FLUTTER_STORAGE_BASE_URL` as **user environment variables** (`setx`), which
  is the Windows equivalent of a shell-profile export and additionally covers IDEs and Android
  Studio, not just an interactive shell.
- The Google Maven mirror in **`~/.gradle/init.d/cn-google-maven-mirror.gradle`**, *not*
  `~/.gradle/gradle.properties` as originally specified. `gradle.properties` holds properties and
  JVM/proxy settings; it has no syntax for substituting a repository. An init script in
  `~/.gradle/init.d/` is the mechanism Gradle actually provides for user-global repository
  policy, and it is applied automatically to every build by this user.
- The init script **rewrites the URL of Google-Maven repositories in place** rather than clearing
  and rebuilding the repository list. Flutter injects its own engine-artifact repository into every
  Android project; clearing the list would silently delete it and produce a confusing failure.

**Nothing goes into the project.** No mirror or proxy setting in `android/gradle.properties`,
`build.gradle.kts`, `settings.gradle.kts`, `pubspec.yaml`, or CI. The governing requirement is that
**this repository must build unmodified on a machine with normal pub.dev access** — so the committed
tree must contain no trace of this machine's network constraints.

**The lockfile rewrite, and a finding that makes it mandatory rather than tidy.**

`pub` writes the mirror host into every hosted entry of `pubspec.lock`. `tools/sanitize_lockfile`
rewrites those `url:` fields back to `https://pub.dev`. This is safe because integrity does not live
in the URL: each hosted entry carries a `sha256` of the package archive, a mirror serves
byte-identical archives, and pub verifies that hash on download whatever the host. Measured on the
first run: 24 URLs rewritten, **all 24 `sha256` lines byte-identical**, file length unchanged, and
a second run reports "already canonical" — the script is idempotent.

**Finding: `flutter pub get` undoes the sanitization every single time.** Running `pub get` against
a sanitized lockfile does not accept it — pub treats a pub.dev-hosted entry as a different source
from a mirror-hosted one, re-resolves, reports *"Changed 24 dependencies"* and writes the mirror
host back. So sanitizing is **not** a one-time cleanup performed before the first commit; it is a
mandatory post-step on every single `pub get` for as long as this machine resolves through a mirror:

```sh
flutter pub get && sh tools/sanitize_lockfile
```

The script only rewrites `url:` fields inside a description block whose `source:` is `hosted`. A
`source: git` entry also carries a `url:`, but a git URL is a real code location rather than a
redistribution host, and rewriting one would point the build at the wrong repository.

**Backstop.** `.githooks/pre-commit` fails any commit whose `pubspec.lock` names a host other than
`pub.dev`. Given the finding above — that the contamination returns automatically on every `pub
get` — this hook is not belt-and-braces. It is the control that actually holds the guarantee, and
the sanitize script is what makes satisfying it a single reproducible command.

**Residual risk, stated plainly.** Packages are now fetched from a third-party mirror rather than
from pub.dev. The mitigation is the `sha256` recorded per package in `pubspec.lock`: a mirror
serving modified content fails verification. That protects against tampering in transit and at the
mirror, but it does not protect against a compromised *upstream* package, and it means the first
resolution of any newly added dependency establishes its hash from mirror-served content. When the
dependency set changes materially, re-resolving once from a machine with genuine pub.dev access and
diffing `pubspec.lock` is the cheap way to confirm the hashes agree.

**`package:sqlite3` is unaffected.** Its build hooks download prebuilt native binaries from GitHub
releases (200 from this machine), sha256-pinned inside the pub package, with SLSA level 3
attestations from 3.5.2 onward. The encryption path never touches the mirror. If GitHub becomes
unreachable, the `url_pattern` user-define is the fallback.

---

## D-015 — Omit `custom_lint` / `riverpod_lint` so the modern Drift and sqlite3 stack resolves

**Date:** 2026-08-22 · **Confirmed:** 2026-08-23 · **Status:** ACCEPTED

**Owner ruling (2026-08-23).** Approved. *"Lint tooling must never dictate the native stack."*

**Context.** Measured by dependency-resolution probe on 2026-08-22:

- Including `custom_lint` + `riverpod_lint` pins `analyzer` to 8.x, which forces `drift_dev` down to
  **2.31.0**, which forces `sqlite3` to **2.x**, which requires the **end-of-life**
  `sqlite3_flutter_libs` / `sqlcipher_flutter_libs` packages (see D-010).
- Omitting them resolves cleanly to `analyzer` 13.3.0, **drift 2.34.3 / drift_dev 2.34.5**,
  **sqlite3 3.5.2**, `flutter_riverpod` 3.4.2, `riverpod_generator` 4.0.8, `go_router` 17.5.0,
  `flutter_secure_storage` 11.0.0, `shamsi_date` 1.1.1.

**Decision proposed.** Ship Phase 1 without `custom_lint` and `riverpod_lint`, and revisit once
`custom_lint` supports analyzer 13.

**Reason.** The cost is a set of Riverpod-specific lint hints. The benefit is not depending on two
end-of-life packages for the app **encryption layer** — the one dependency where being unmaintained
is least acceptable. This is not a close call.

**Alternatives considered.** Keeping the lints and accepting drift 2.31 plus the EOL native libs
(rejected for the reason above); keeping the lints in a separate analysis-only package workspace
(viable, but adds workspace complexity for a linting convenience — reconsider later).

---

## D-016 — `drift_flutter` is not used

**Date:** 2026-08-22 · **Confirmed:** 2026-08-23 · **Status:** ACCEPTED

**Owner ruling (2026-08-23).** Approved, together with D-015.

**Decision.** Open the database directly with `drift` + `sqlite3` + `path_provider` rather than using
the `drift_flutter` convenience package.

**Reason.** Two reasons, both concrete. First, `drift_flutter` 0.3.1 still depends on the end-of-life
`sqlite3_flutter_libs` and `sqlcipher_flutter_libs` (see D-010), which would reintroduce exactly what
D-015 avoids. Second, the app needs explicit control over the database path (`%APPDATA%` on Windows
per the security requirements), over the order in which `PRAGMA key` is applied, and over
`PRAGMA foreign_keys = ON` — all of which `drift_flutter` abstracts away. The convenience it offers is
roughly thirty lines of setup we want to own anyway.

---

## D-017 — Foreign keys enforced explicitly

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** `PRAGMA foreign_keys = ON` is set on every connection open. `invoice_items.invoice_id`
and `payments.invoice_id` cascade on delete.

**Reason.** SQLite does not enable foreign key enforcement by default, and the setting is per
connection. Without it the constraints in the schema are documentation, not integrity — and an
orphaned invoice item is a silently wrong invoice total.

---

## D-018 — No raw SQL built by string interpolation

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** All queries use the Drift typed, parameterized API. Where `customStatement` is genuinely
unavoidable it must use bound variables and be reviewed.

**Reason.** Free-text fields in this app include customer names and notes, which will contain
apostrophes and Persian text; interpolating them into SQL is both an injection vector and a
correctness bug waiting to happen.

---

## D-019 — Git initialization and commit policy

**Date:** 2026-08-22 · **Decided:** 2026-08-23 · **Status:** ACCEPTED

**Context.** `git status` reports *"not a git repository"*. There is no version control on this
project at all, and the project spec assumes there is.

**Decision.** `git init` was run on 2026-08-23. The default branch is **`main`**, and
`core.autocrlf` is set to `false` so that line endings are not rewritten on this Windows checkout.
`.gitignore` was hardened **before** initialization, and the first commit captures the scaffold plus
`docs/` before any Phase 1 code — so that Phase 1 is reviewable as a diff rather than as an
undifferentiated pile of new files.

**Commit policy (owner, 2026-08-23).**

- Commit at the **end of each phase** and at meaningful milestones.
- Commit messages in **English**.
- Show `git diff --stat` and the proposed message, then commit. **No per-commit approval needed.**
- **Never** force-push, amend, rebase, or `reset --hard`.
- No remote configured yet.

**Gitignore hardening.** Beyond the `flutter create` defaults, `.gitignore` now covers signing
material (`*.jks`, `*.keystore`, `*.p12`, `*.pfx`, `key.properties`), local secrets (`.env*`,
`dart_define.json`, `config/*.json` — each with an `*.example` escape hatch), exported backups
(`*.factorino-backup`, `backups/`, `exports/`), and local database files (`*.db`, `*.sqlite`, and
the `-wal`/`-shm`/`-journal` siblings). A backup is the entire customer and invoice database in one
portable artifact, and a local `.db` is real user financial data; neither may ever be committed.

**Pre-commit hook.** `.githooks/pre-commit` is versioned in the repository (not `.git/hooks/`, which
does not survive a clone) and is enabled with `git config core.hooksPath .githooks`. It fails the
commit on three conditions: a `pubspec.lock` referencing any host other than `pub.dev` (D-014);
staged signing material, secrets or local databases; and the template application ID
`com.example.factorino` still present in `android/app/build.gradle.kts`.

---

## D-020 — `PRAGMA key` must be the first statement on every connection

**Date:** 2026-08-23 · **Status:** ACCEPTED

**Decision.** On every database connection open, in this exact order:

1. `PRAGMA key = '<key from secure storage>'` — **first, before anything else**
2. `PRAGMA cipher = 'sqlcipher'; PRAGMA legacy = 4;` — SQLCipher-compatible format (D-010)
3. `PRAGMA foreign_keys = ON` (D-017)
4. Only then may Drift issue any statement of its own

Drift's `LazyDatabase` / `NativeDatabase.opened` setup callback is the single place this ordering is
implemented, so no call site can open a connection any other way.

**Reason.** SQLite applies the key to the connection, not the file. If any statement executes before
`PRAGMA key`, the outcome is one of two silent failures rather than a loud one:

- On a **new** database file, the first statement creates an unencrypted database, and every
  subsequent write lands in plaintext. Encryption at rest is simply absent, with nothing in the
  application's behaviour to indicate it.
- On an **existing** encrypted file, the read fails with `file is not a database` — an error whose
  text points at corruption rather than at key ordering, and which is therefore easy to misdiagnose
  and "fix" by deleting the user's financial records.

The failure mode is silent and the data loss is total, which is why this is a decision of record
rather than an implementation detail.

**Verification requirement.** This ordering is not considered proven by code review. It must be
demonstrated end to end inside a real Flutter app on **both** Android and Windows: open through
Drift, write a row, close, reopen **without** the key, and confirm the reopen is rejected. A
standalone native probe does not count — it does not exercise Flutter's asset, plugin and
packaging path, which is where the native library actually has to be found at runtime.

---

## D-021 — "گزارش‌ها" is omitted from navigation entirely in Phase 1

**Date:** 2026-08-23 · **Status:** ACCEPTED

**Decision.** The reports destination does not appear in the navigation shell in Phase 1. It is not
present as a disabled item and not present as a coming-soon placeholder. It arrives in Phase 8, when
it does something.

**Reason.** the project spec permits either omission or a designed coming-soon state, and explicitly
forbids a dead nav item. Omission is the stronger of the two permitted options: a placeholder still
occupies a navigation slot, still has to be designed, localized and tested, and still teaches the
user that a destination exists which does not. Adding the destination in Phase 8 is a smaller change
than maintaining a placeholder through seven phases.

**Consequence.** Phase 1 navigation is: داشبورد · فاکتورها · مشتریان · محصولات و خدمات · تنظیمات.
The route itself is also not registered, so no deep link or typed Web URL can reach a screen that
does not exist.

---

## D-022 — Vazirmatn standard variant, static TTFs, weights 400/500/700

**Date:** 2026-08-23 · **Status:** ACCEPTED

**Decision.** Bundle the **standard** Vazirmatn static TTFs at weights 400, 500 and 700 from the
official GitHub release `v33.003`, with `OFL.txt` committed alongside them in `assets/fonts/`.
The Farsi-digit (`FD`) variants are **not** used.

**Reason for the standard variant.** The FD variants substitute Persian digit glyphs at the font
level for ASCII digit codepoints. That moves a display decision into a binary asset where it is
invisible to code review, impossible to unit-test, and impossible to override for the cases that must
render Latin digits. Digit rendering belongs to `core/formatting/`, where it is one
normalizer and one formatter, testable and switchable in a single place.

**Reason for static over variable.** Three fixed weights cover the type scale in the project spec
(body, medium, prominent financial numerals). The variable font carries the full weight axis for a
larger download, and variable-font support in Flutter's text stack is less predictable across the
Android/Windows/Web matrix than static faces.

**Reason for three weights.** 400 body, 500 section titles and emphasis, 700 page titles and the
prominent financial numeral style. Each additional weight is roughly 120 KB per platform bundle for
a distinction the design system does not currently make.

**Licence.** SIL Open Font License 1.1. `OFL.txt` ships in `assets/fonts/` and must remain there;
the licence requires the copyright and licence notice to be distributed with the font.

**Provenance.** Recorded with sha256 hashes in `docs/ENVIRONMENT.md`, because the fonts were fetched
out-of-band from GitHub rather than resolved through a package.
