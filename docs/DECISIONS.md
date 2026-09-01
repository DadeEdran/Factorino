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
   **This reason holds only if those two pragmas are issued *before* `PRAGMA key`.** Issued
   afterwards they are silently ignored and the file is written with the sqlite3mc default cipher
   (ChaCha20), which SQLCipher cannot read - the escape hatch would exist on paper only. Proven by
   cross-open matrix on 2026-08-23; see D-020.

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

**Implementation note (2026-08-23, schema v1).** `invoices` stores the formatted `number` *and* the
`number_year` / `number_sequence` it was built from. Allocation is then
`MAX(number_sequence) WHERE number_year = ?` inside a transaction, rather than parsing formatted
strings back apart — a parser that would have to keep working after the prefix is reconfigured.

The unique index on `number` deliberately **covers soft-deleted rows**: an issued number is spent,
and a gap in the sequence is a far better outcome than two different documents sharing one identity.
`settings.device_prefix` is the reserved column named above; it is nullable and unused in Phase 1.

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

## D-020 — The keyed open sequence, its single choke point, and its named traps

**Date:** 2026-08-23 · **Amended:** 2026-08-23 (proof run) · **Status:** ACCEPTED

**Decision.** On every database connection open, in this exact order:

1. `PRAGMA cipher = 'sqlcipher'` and `PRAGMA legacy = 4` - select the SQLCipher-compatible on-disk
   format (D-010). These are connection configuration; they do not touch the database.
2. `PRAGMA key = "x'<64 hex chars>'"` - the raw 256-bit key from secure storage.
3. `PRAGMA foreign_keys = ON` (D-017).
4. `SELECT count(*) FROM sqlite_master` - forces page 1 to be decrypted **now**, so a wrong key or a
   broken order fails at open rather than at some arbitrary later query.
5. Only then may Drift issue any statement of its own.

This lives in exactly one function, `openEncryptedDatabase` in
`lib/data/database/encrypted_database.dart`, passed as Drift's `NativeDatabase(setup:)` callback.
Verified in the Drift source (`lib/src/sqlite3/database.dart:111`): `_setup?.call(database)` runs
after `useNativeFunctions()` - which registers Dart callbacks and issues no SQL - and before the
version delegate's `PRAGMA user_version`. It is a genuine choke point, not merely the first thing we
happen to call.

### Amendment: "key first, unconditionally" was wrong, and wrong in a way that fails silently

The original entry required `PRAGMA key` to be the *first* statement, with the cipher pragmas after
it. That is what the first Dart-VM probe did, and it appeared to work: the file was encrypted, the
unkeyed reopen was rejected. **It was not producing a SQLCipher-format database.** A second probe
created the same database three ways and cross-opened every combination:

| File created with | opened by `key -> cipher` | by `cipher -> key` | by `key` alone |
|---|---|---|---|
| A: `key -> cipher` | yes | **no** | **yes** |
| B: `cipher -> key` | no | yes | no |
| C: `key` alone (sqlite3mc default cipher) | yes | no | yes |

A and C are interchangeable; B is readable only by itself. `PRAGMA cipher` issued *after* the key is
**silently ignored for the on-disk format** - file A was written with the sqlite3mc default cipher
(ChaCha20), not SQLCipher. Nothing reports this: the file is genuinely encrypted, the key works, the
sentinel is absent from the raw bytes. Only a cross-open reveals it.

The consequence is narrow but real. Encryption at rest - the governing requirement - held either
way. What did not hold is D-010's reason 3, that choosing `sqlite3mc` does not lock the project into
one implementation: a ChaCha20 file cannot be read by SQLCipher, so the escape hatch D-010 relies on
would have quietly not existed. **The cipher pragmas must precede the key**, and the rule is
restated accordingly:

> No statement that reads or writes the database may precede `PRAGMA key`. The only statements
> permitted before it are the cipher-configuration pragmas on the allowlist
> (`kPragmasAllowedBeforeKey`).

The original hazard is unchanged and still confirmed, on the Dart VM and on a real Windows build
alike: a *database* statement before the key produces a plaintext file **and** an exception reading
`file is not a database`, which blames corruption and invites deleting the user's records.

### The named traps

Each of these reads as evidence of encryption and is not. All three were observed, not reasoned
about.

**Trap 1 - `PRAGMA cipher_version` returns empty under sqlite3mc.** Under SQLCipher proper it
reports e.g. `4.18.0 community`. Under sqlite3mc it returns an empty result set on a correctly
encrypted database. Code asserting on it concludes "not encrypted" when encryption is fine - and
would just as happily conclude nothing at all on a plaintext file. **Never use it as the runtime
assertion.**

**Trap 2 - `PRAGMA cipher` echoes the configured value, not the file's actual cipher.** Querying it
returns `sqlcipher` on a connection that was told `sqlcipher`, including an **in-memory database
with no key at all**. It reports what was requested, never what is on disk.

**Trap 3 - a cipher pragma issued after the key is accepted and ignored.** No error, no warning; the
setting simply does not apply to the file format. See the matrix above.

**What to assert instead: the file header.** An unencrypted SQLite database begins with the 16 ASCII
bytes `SQLite format 3\0`. An encrypted one does not. This is implementation-independent, cheap, and
cannot be fooled by connection state. `inspectDatabaseFile` and `assertDatabaseFileIsEncrypted`
implement it.

### Enforcement - not developer discipline

The ordering is a property of the codebase, checked by tests that fail on violation:

| Guarantee | Enforced by |
|---|---|
| Nothing precedes the key but allowlisted cipher pragmas | `assertKeyPrecedesDatabaseAccess`, called **in production** inside `applyConnectionSetup` before the first statement is executed, and asserted directly in `test/data/database/connection_setup_order_test.dart` |
| The cipher pragmas precede the key | same test file - the ordering is asserted against the very list the app executes, not a copy of it |
| Only one code path opens a database | `test/data/database/single_open_path_test.dart` scans `lib/` and fails if any file other than the sanctioned opener mentions `NativeDatabase(`, `sqlite3.open(`, `driftDatabase(` or `pragma key` |
| The on-disk file is never a plaintext SQLite database | `assertDatabaseFileIsEncrypted` at startup; `openEncryptedDatabase` additionally refuses to open an existing `SQLite format 3` file rather than writing more data into it |

The startup assertion is deliberately unforgiving: `absent` and `tooShortToJudge` also throw, so
"no file yet" can never be mistaken for "encrypted". There is no Persian user-facing message and no
recovery path, because the only alternative to failing is writing financial records and third-party
national IDs in the clear.

### Verification - the end-to-end proof

The proof is an integration test, `integration_test/d020_encryption_proof_test.dart`, rather than a
throwaway app: it runs on the real target, is repeatable, and cannot silently rot. A Dart-VM test
cannot substitute for it - the open question is whether the native library is found through
Flutter's own packaging path at runtime, which is exactly what a VM probe skips.

**Windows - PASS, 2026-08-23**, `flutter test integration_test/... -d windows`, 5/5:

```
sqlite3 library : 3.53.4 (package:sqlite3 build hooks, source: sqlite3mc)
database dir: C:\Users\...\AppData\Roaming\io.github.erysaw\factorino   (%APPDATA%, per §7)
keystore: DPAPI returns a stable 256-bit key across calls
header bytes: c1 51 85 73 60 bd 92 8e bd 32 39 d6 72 34 49 00   -> encrypted
sentinel on disk: absent from a raw byte scan
foreign_keys: 1 (on, for the connection Drift actually uses)
unkeyed reopen: REJECTED  SqliteException(26): file is not a database
wrong-key reopen: REJECTED
keyed reopen: 1 row, value intact
out-of-order: plaintext file produced + "file is not a database" - hazard reproduced
startup assert: caught the plaintext database and refused to open it
cipher_version: (empty)                                        <- Trap 1 reproduced
cipher echo: 'sqlcipher' on an unkeyed in-memory database   <- Trap 2 reproduced
```

**Android - PASS, 2026-08-23**, Redmi Note 8 Pro, Android 11 (API 30, arm64-v8a),
`flutter test integration_test/... -d dmbyayb6rombo7ci`, 5/5:

```
sqlite3 library : 3.53.4, from lib/arm64-v8a/libsqlite3mc.so (1.9 MB) packaged in the APK
database dir: /data/user/0/io.github.erysaw.factorino/files   (app-private, per §7)
keystore: Android Keystore returns a stable 256-bit key across calls
header bytes: c4 93 43 23 a6 f7 67 27 8a 9a ee af 90 12 49 75   -> encrypted
sentinel on disk: absent from a raw byte scan
unkeyed reopen: REJECTED  SqliteException(26): file is not a database
wrong-key reopen: REJECTED
keyed reopen: 1 row, value intact
out-of-order: plaintext file produced + "file is not a database" - hazard reproduced
startup assert: caught the plaintext database and refused to open it
cipher_version: (empty)                                        <- Trap 1 reproduced
cipher echo: 'sqlcipher' on an unkeyed in-memory database   <- Trap 2 reproduced
```

Both traps and the ordering hazard behave identically on Android and Windows, so they are properties
of sqlite3mc rather than of one platform's build.

The build hook produces and packages the native library for Android with no manual native setup -
the main technical risk this proof existed to settle. Note that the header bytes differ on every
run: the salt is random, as it should be.

**Installation note.** The first attempt was refused by MIUI with
`INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`, identically via `flutter test`,
`adb install` and `adb shell pm install`. That is the device's "Install via USB" developer setting,
not a project defect; once enabled, installation and the run both succeed.

**Alternatives considered.** Asserting on `cipher_version` (rejected: Trap 1 - it is empty under
sqlite3mc, so the assertion would be permanently wrong in the unsafe direction). Documenting the
ordering in a comment and relying on review (rejected: this is the reason the entry exists - the
failure is invisible in behaviour, so review is the only thing that could catch it). A throwaway
proof app (rejected: it verifies once, then rots).

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

---

## D-023 — `flutter_secure_storage` runs with `resetOnError: false`

**Date:** 2026-08-23 · **Status:** ACCEPTED

**Decision.** The `FlutterSecureStorage` instance holding the database key is configured with
`AndroidOptions(resetOnError: false)`. The package default is `true`.

**Reason.** With `resetOnError: true`, a read failure causes the package to **delete the stored
entry** and return null. For an ordinary session token that is a harmless forced re-login. Here the
entry is the only key that can decrypt the user's database: discarding it converts a transient
keystore error - an OS upgrade, a restore onto a new device, a Keystore hiccup - into permanent,
silent loss of every invoice the business has ever issued, and the app would then cheerfully
generate a fresh key and create an empty database on top of the unreadable one.

Failing loudly is correct. The recovery path is the encrypted backup file, which is
why backup is in the MVP rather than a later phase.

**Note.** `encryptedSharedPreferences: true`, named in older guidance, does not exist in
`flutter_secure_storage` 11: AES-GCM with RSA-OAEP key wrapping is now the default and the AndroidX
`EncryptedSharedPreferences` path is gone.

**Alternatives considered.** Accepting the default (rejected: silent total data loss). Catching the
error and re-deriving the key from something stable (rejected: there is nothing stable to derive
from that an attacker holding the device would not also have - that is key-hardcoding with extra
steps).

---

---

## D-024 — UUID v4 comes from `package:uuid`

**Date:** 2026-08-23 · **Reversed the same day by the project owner** · **Status:** ACCEPTED
(supersedes the original entry below)

**Decision.** `lib/core/utils/uuid.dart` is a one-line wrapper over `package:uuid` 4.6.0.

**Reason (owner, overruling this session's original decision).** The original reasoning — that
The project spec asks whether Dart already provides what a dependency would, and `Random.secure()`
does — was sound but landed wrong:

1. **The failure is rare and expensive.** This session's own test notes that a version- or
   variant-masking bug surfaces in roughly one run in sixteen. That is a rare, hard-to-diagnose
   failure on the **primary key of every row in the database**.
2. **It poisons future debugging.** Once sync exists, any strange conflict would put our own ID
   generator first in the suspect list, spending investigation time on something that should be
   settled.
3. **§2 is about gratuitous dependencies.** Unique ID generation for records that must merge across
   devices is not gratuitous — it is exactly the kind of thing worth taking from a maintained,
   widely-audited package.

**How the swap was made.** The generator's property tests were kept and pointed at the wrapper
rather than deleted: format, version and variant bits under all-zero and all-`0xff` random material,
10,000 values checked for collisions, and leading-byte entropy. All four passed against
`package:uuid` unchanged. A dependency swap is precisely when the old guarantees should be
re-checked rather than assumed, and keeping the tests is what made the reversal cheap — the wrapper
means one file changed, because the schema references the tear-off as a column default.

**Original decision, for the record (superseded).** *UUID v4 generated in-repo from
`Random.secure()`, on the grounds that it is a dozen lines, directly unit-testable, and avoids a
supply-chain surface and a version to track for one function.* Rejected for the reasons above.

**Alternatives considered.** Keeping the hand-rolled generator (rejected: see above); a
database-side `randomblob(16)` default (rejected: pushes an identity decision into SQL where it
cannot be unit-tested and would differ on the Web target); timestamp-plus-counter ids (rejected:
predictable, and leaks creation order into a primary key).

---

## D-025 — Denormalized `search_name` columns for Persian-insensitive search

**Date:** 2026-08-23 · **Status:** ACCEPTED

**Decision.** `customers` and `products` each carry a `search_name` column holding a normalized copy
of the display name, written by the repository layer and indexed. Search queries match against it.

**Reason.** the project spec requires that a customer saved as "علي" be found by typing "علی" — Arabic
`ي`/`ك` folded to Persian `ی`/`ک`, ZWNJ handled, digits normalized. Normalizing at query time
(`WHERE normalize(full_name) LIKE ?`) would mean a user-defined function applied to every row of
every search, which cannot use an index and degrades to a full scan — against §13's requirement to
design for thousands of records.

**Consequence, stated plainly.** A denormalized column can drift out of sync with its source. The
mitigation is that the repository is the only writer and sets both in the same statement; the risk
is that a future direct DAO write bypasses it. When repositories land, that gets the same treatment
as the soft-delete helper: a test, not a convention.

**Why the column exists before the normalizer.** Schema is the expensive thing to change once a
build with real data is installed; the normalizer is a pure function that can be written and tested
independently. The column defaults to an empty string until the normalizer increment fills it, and
no user data exists yet.

**Alternatives considered.** SQLite FTS5 (rejected for now: a second index structure to keep in sync
and a larger file, for prefix search over a few thousand short names); normalizing only in Dart after
loading all rows (rejected: that is the O(n) UI-thread work §13 forbids).

---

## D-026 — A tax rate of `0` is a real rate, never "absent"

**Date:** 2026-08-23 · **Status:** ACCEPTED

**Decision.** In the §4 resolution order item → invoice → settings default, the engine takes the
first **non-null** value. A rate of `0` stops the search; only `null` continues it.

**Reason.** A tax-exempt line is expressed as `0`, and the obvious shortcut — treating a falsy or
zero rate as "not set" and falling through — would apply the default VAT rate to a line the user
deliberately marked exempt. That is a wrong total on a tax document, and it would look correct to
everyone except the tax authority.

The distinction is carried in the type: `int?` rather than `int` for the item and invoice
overrides, with `null` meaning "inherit" and `0` meaning "zero percent". The settings default is
non-nullable, because the chain has to terminate.

**Consequence.** The resolved rate is snapshotted onto each invoice item (D-004), so an invoice
issued at 0% stays at 0% no matter what the settings default becomes later.

**Alternatives considered.** A sentinel such as `-1` for "inherit" (rejected: it invites arithmetic
on a value that is not a rate, and `-1` reaching the schema would be silently stored); a separate
`isTaxExempt` boolean (rejected: two fields that can contradict each other, and the exemption is
already expressible as a rate).

---

## D-027 — `totalDiscount` reports the discount actually given, and clamps are surfaced

**Date:** 2026-08-24 · **Status:** ACCEPTED · **Origin:** an ambiguity in the project spec, corrected
by the project owner. Supersedes the literal reading implemented in increment (b).

**Decision.** §4 step 9 becomes
`totalDiscount = Σ effectiveLineDiscount + effectiveInvoiceDiscount`, where the *effective* discount
is the amount actually deducted after clamping — never the amount as entered. The project spec was amended to say so.

Additionally: a clamped discount, at either level, is **reported to the caller as data** on
`CalculatedInvoice.warnings` — not absorbed, and not thrown.

**Reason.** The contract's original wording defined the figure as the sum of what was entered.
Implemented literally in increment (b), that made an item discount larger than its line inflate the
reported total above what was actually given — a line worth 1,000,000 with 1,500,000 entered against
it reported 1,500,000 while deducting 1,000,000. The owner's ruling:

> *"The number printed on an invoice must be the discount actually given, or the customer cannot
> reconcile the document by hand — and 'total discount 150' on a line that only ever gave 100 is a
> defect a user will find before we do."*

The wording was wrong, not the implementation of it. Both figures are kept on the line
(`discountRequested` and `discount`), so the document can still show what was typed and the
difference stays auditable.

**Why the clamp is surfaced rather than absorbed.** An over-large line discount is almost always a
data-entry slip rather than an intent. Absorbing it silently is how a wrong figure reaches a document
nobody questions. It is not an exception, because the totals are correct and the invoice is usable —
what is questionable is the input, and only the user can settle that. So the engine reports and the
UI asks. `InvoiceWarning` carries the kind, the line index, and both amounts, so the UI can state the
difference exactly rather than saying "some discount was ignored". It deliberately carries **no
message**: user-facing text is Persian and belongs to the localization layer (§1), which
`core/money/` may not reach.

**The two clamps are kept, for different reasons.** A *line* discount is capped because a line
cannot give away more than it is worth. An *invoice* discount is capped because it is part of the
reconciliation invariant, and an uncapped one produces a negative grand total, which is never a valid
document. The owner confirmed the invoice-level behaviour is unchanged; only its visibility is new.

**Consequence.** `CalculatedLine.discount` changed meaning — it is now the effective amount, so any
future reader of it gets the figure that belongs on the document. The reconciliation invariant is
untouched: it is built from `subtotal`, never from `totalDiscount`.

**Alternatives considered.** Reporting the entered amount and letting the UI derive the effective one
(rejected: two places would compute the same figure, and the document layer must not recompute —
§12 and D-004 both require the renderer to receive already-computed values). Throwing on an
over-large discount (rejected: the invoice is computable and correct, and refusing to compute would
block a user mid-entry over what may be a deliberate write-off of an entire line). Silently rewriting
the user's input down to the line total (rejected: it discards what they typed with no way to
notice).

---

## D-028 — Iran Standard Time is an explicit parameter, not a timezone database

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** `core/date/` derives Iranian business-day boundaries from a named constant,
`kIranStandardOffset = Duration(hours: 3, minutes: 30)`, which every period function takes as a
**parameter defaulting to that value**. Nothing in `core/date/` reads `DateTime.now()` or the device
timezone. `package:timezone` is not added.

**Reason.** D-006 requires that boundaries be "derived explicitly rather than hardcoded as a fixed
offset" in a way that "would break for a user whose device is set to another timezone". The failure
that requirement guards against is using **device local time** — a laptop in Berlin would then
compute German day boundaries and mis-file every evening sale. Passing the offset explicitly avoids
it completely: the answer does not depend on the device at all, which is also what makes every
boundary testable against fixed values.

Iran abolished daylight saving in 2022, so `Asia/Tehran` has no transitions in any range this
application will handle; a timezone database would add a dependency and a runtime initialization step
to return the same number. The parameter is the seam: if Iran restores DST there is one constant to
replace and one parameter through which a date-dependent rule can be supplied, rather than a search
for `3.5` across the codebase.

**Dependency added: `shamsi_date` 1.1.1** (the project spec names it; this is the phase that needed
it). *What it does:* Jalali↔Gregorian conversion and Jalali calendar arithmetic. *Why it is needed:*
the conversion is on the correctness path for every dashboard figure (D-006), not merely on the
formatting path. *If it becomes unmaintained:* the algorithm is fixed, published arithmetic over a
calendar whose leap rule does not change, and `core/date/` wraps it behind this project's own types
— so a replacement is a single-file swap, and the boundary tests (Nowruz anchors, leap years, month
tiling) are what would confirm it.

**Alternatives considered.** `package:timezone` (rejected for now: correct in general, unnecessary
for a fixed-offset zone, and it requires an initialization step a pure library should not have —
revisit if the app ever serves a second timezone). Reading `DateTime.now().timeZoneOffset`
(rejected: that *is* the bug D-006 names). Hardcoding `+03:30` inline at each call site (rejected:
nothing to change when the assumption changes, and nothing to override in a test).

---

## D-029 — `searchKey` produces an opaque key, and folds further than §9 enumerates

**Date:** 2026-08-24 · **Status:** ACCEPTED · Extends D-025.

**Decision.** One function, `searchKey`, produces both the value stored in `search_name` and the term
queried against it. It folds more aggressively than the project spec lists:

| Fold | Named by §9 | Reason for the extras |
|---|---|---|
| Persian and Arabic-Indic digits → ASCII | yes | |
| `ي`/`ك` → `ی`/`ک` | yes | |
| ZWNJ handled | yes | |
| `ى` (alef maksura) → `ی` | no | the same yeh again, from a third keyboard layout |
| `ة`/`ۀ` → `ه` | no | borrowed names are written both ways by the same person |
| `آ`/`أ`/`إ`/`ٱ` → `ا` | no | the hamza and madda marks are typed inconsistently |
| diacritics, tatweel, bidi controls dropped | no | invisible to the user, so a mismatch caused by one is undiagnosable |
| **all whitespace removed** | no | see below |
| Latin lowercased | no | |

**The result is a key, not a display string.** It is stripped of spacing and case and must never be
shown to the user. The display name is stored separately, exactly as typed.

**Why whitespace is removed.** Persian compounds are written three ways by the same person —
`علی‌رضا` (ZWNJ), `علی رضا` (space), `علیرضا` (joined). Folding ZWNJ alone would still leave the
spaced form unmatched. Removing spacing entirely reduces all three to one key, and a substring `LIKE`
search over a space-free key still matches each individual word of a multi-word name, so nothing is
lost. Tested.

**What is deliberately *not* folded.** `ئ` (U+0626, yeh with hamza above) is a distinct Persian
letter, not a variant: `رئیس` and `رییس` are different spellings, and merging them would make search
answer a question it was not asked. The rule applied is *the same letter written differently*, never
*letters that look similar*.

**Enforced structurally, not by convention.** `test/core/formatting/single_normalizer_path_test.dart`
fails the build if anything in `lib/` outside `core/formatting/` open-codes a character fold, or
references `searchName` without calling `searchKey`. This is the treatment the database opener gets
(D-020), for the same reason: **the failure is silent.** Two call sites that normalize almost the
same way produce no error and no crash — the write succeeds, the index builds, the query runs, and a
customer saved yesterday simply cannot be found. Neither side looks wrong in isolation.

The guard scans code only, not comments: naming کد ملی in a doc comment describes a field, and a
comment cannot execute a fold. It carries a `// normalizer-exempt: <reason>` escape hatch, so the raw
form is a visible, justified choice rather than a forbidden one.

**Verified end to end, not only as a unit.**
`test/data/database/search_name_roundtrip_test.dart` writes through the real encrypted database and
searches with a parameterized `LIKE`, because the normalizer can be perfect and the search still fail
— if one side folds and the other does not, or if SQLite compares the stored bytes differently from
what Dart produced.

**Alternatives considered.** Normalizing at query time with a user-defined function (rejected in
D-025: it cannot use an index and degrades to a full scan). Folding only what §9 enumerates
(rejected: it would leave `علی رضا` unmatchable against `علی‌رضا` — the same failure §9 exists to
prevent, one character over). Unicode NFKC normalization (rejected: it does not fold the
Arabic/Persian letter pairs at all, since they are distinct code points with distinct meanings in
Arabic, and it would fold things this app has no reason to touch).

---

## D-030 — The national-ID checksum validates a format, never an identity

**Date:** 2026-08-24 · **Status:** ACCEPTED · **Owner ruling**, arising from a finding in increment
(c).

**The finding.** The official Iranian national-ID (کد ملی) checksum cannot distinguish every pair of
distinct numbers. The rule takes the weighted sum of the first nine digits modulo 11 and requires the
check digit to be `r` when `r < 2` and `11 − r` otherwise — so remainders **1 and 10 both produce the
check digit 1**. Any data-entry error that moves the weighted sum between those two remainders is
invisible to the check. `0079542311` and `0079542131` differ by a transposition and **both validate**,
under this implementation and under any correct implementation of the published algorithm.

This is a property of the algorithm, not a defect in `core/formatting/national_id.dart`. It is
recorded as a passing test (`national_id_test.dart`, *"a transposition can survive, and that is the
algorithm, not a bug"*) so that nobody later "fixes" it by inventing a stricter rule than the one the
government issues numbers under.

**Decision — a UI constraint that binds increment (f) and every screen after it.**

The Persian copy for this field says that the **format** is valid. It must never say, imply, or be
translated as *confirmed*, *correct*, *verified*, *authenticated*, or *identity established*.

| Acceptable | Not acceptable |
|---|---|
| «فرمت کد ملی معتبر است» — the format is valid | «کد ملی تأیید شد» — the national ID is confirmed |
| «کد ملی نامعتبر است» — invalid, on failure | «کد ملی صحیح است» — the national ID is correct |
| No affirmative message at all on success | Any green "verified" badge or check-mark treated as identity |

**Reason.** A passing checksum narrows the space of typos; it does not close it, and it says nothing
whatever about whether the number belongs to the person named on the invoice. A user told their entry
is "verified" will stop checking it — which is exactly when a transposed digit that happens to
checksum survives onto a tax document. The wording is the only thing standing between a probabilistic
check and a false assurance, and it costs nothing to get right.

Failure messages are unaffected: a value that fails the checksum is genuinely invalid and may be
called so plainly.

**Consequence.** Increment (f), and Phase 2 (Customers), must satisfy this in the ARB strings
themselves, not in a code comment. A reviewer should be able to check compliance by reading the
Persian copy alone.

**Scope.** The same reasoning applies to any future validator that is a checksum rather than a
lookup — the economic ID and IBAN/Sheba being the likely candidates. State the format, never the
identity.

---

## D-031 — The domain boundary is a directory split, not a naming convention

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** the project spec's *"repositories expose domain models, never Drift-generated row
classes"* is enforced by making the drift types **unreachable** from the boundary, rather than by
asking reviewers to notice:

```
lib/data/models/                    domain entities + enums   -- no drift import
lib/data/repositories/*.dart        interfaces                -- no drift import
lib/data/repositories/drift/*.dart  implementations + mapping -- drift lives here
lib/data/providers.dart             composition root          -- sees both
```

A signature cannot name a type its library does not import, so an interface in
`repositories/` **cannot** return a row class. `domain_boundary_test.dart` fails the build if
`package:drift/`, `app_database.dart`, `database/tables/` or a `.g.dart` import appears in either
drift-free directory, and checks that every interface has a `drift_*.dart` implementation beside it.

**Reason.** The rule as written is a code-review rule, and code review is exactly what misses it:
returning `CustomerRow` instead of `Customer` compiles, runs, and reads as ordinary code at the call
site. Nothing goes wrong until row types are threaded through providers and widgets, at which point
the layering is gone and the fix is a refactor rather than an edit. Every other rule in this project
that fails silently is enforced by a test that scans `lib/` — the single database opener (D-020), the
soft-delete filter (D-003), the single normalizer (D-029). This is the same treatment.

**Three supporting changes.**

1. **Row classes are named `*Row`** via `@DataClassName` on every table (`CustomerRow`,
   `ProductRow`, `InvoiceRow`, `InvoiceItemRow`, `PaymentRow`; `SettingsRow` already was). Drift
   otherwise names the row class for `Customers` **`Customer`** — colliding with the domain model of
   the same name, and forcing every file that touches both to disambiguate with an import alias.
   The suffix also makes a leak legible on sight. This is a Dart-level rename only: the generated
   SQL is unchanged, `drift_schemas/drift_schema_v1.json` is byte-identical, and **no migration is
   required**.

2. **The enums moved to `data/models/`** — `SyncStatus`, `ProductType`, `InvoiceStatus`,
   `PaymentMethod`. They were declared beside the tables that store them, which meant a domain model
   carrying one would have had to import a file that imports drift. The tables import the enums now;
   the dependency runs schema → domain, never the reverse.

3. **The soft-delete guard was extended to `selectOnly`**, and `selectOnlyAlive` added beside
   `selectAlive`/`countAlive`. Aggregates were an uncovered gap and the worse half of it: a `select`
   that forgets the filter returns visibly deleted rows, while a `sum` that forgets it just returns a
   larger number on a dashboard, with nothing to compare it against.

**Consequence.** One deliberate exemption exists so far: invoice-number allocation reads
`MAX(number_sequence)` **including** soft-deleted invoices, because a spent number stays spent
(D-013). It carries `// soft-delete-exempt:` and a reason, which is the escape hatch working as
intended rather than being worked around.

**Alternatives considered.** A lint rule (rejected: `custom_lint` is the package D-015 excludes for
dragging the analyzer, and with it drift and sqlite3, backwards). Scanning repository signatures for
`Row` types with a regex (rejected: fragile against generics, typedefs and inference, and it would
police the symptom rather than remove the possibility). Trusting the convention (rejected: that is
what the rule already was).

---

## D-032 — Riverpod composition root, with a synchronous overridden database provider

**Date:** 2026-08-24 · **Status:** ACCEPTED · implements D-007.

**Decision.** `lib/data/providers.dart` is the data layer's composition root. `appDatabaseProvider`
is **synchronous** and its default implementation **throws**; `main()` opens the database and
overrides it with the result. Every repository provider is typed as its **interface**.

**Dependencies added** (the project spec requires each to be justified):

| Package | Version | What it does | If unmaintained |
|---|---|---|---|
| `flutter_riverpod` | 3.4.2 | state management and DI (D-007) | provider boundaries are ordinary Dart classes; migration is mechanical but wide |
| `riverpod_annotation` | 4.0.6 | the annotations for the generator | removed with the generator |
| `riverpod_generator` | 4.0.8 | generates the provider boilerplate | the generated providers can be hand-written; it is boilerplate, not behaviour |

**D-015 was re-verified rather than assumed.** Adding these re-resolved 121 packages, and drift
2.34.3 / drift_dev 2.34.5 / sqlite3 3.5.2 / analyzer 13.3.0 are **unchanged** — the modern native
stack held, because `riverpod_lint` and `custom_lint` are still deliberately absent (D-015). Had they
been included, the analyzer pin would have dragged sqlite3 back to 2.x and reintroduced the
end-of-life native packages D-010 exists to avoid.

**Reason for a synchronous provider with an override.** Opening the database is a fail-loud,
must-succeed step: it derives the key from the OS keystore, opens with the cipher pragmas in the one
correct order, migrates, and asserts against the bytes on disk that the file is really encrypted
(D-020). If any of that fails, the application has no business rendering a partially-working UI while
a `FutureProvider` resolves — and every dependent provider would be `AsyncValue`-wrapped forever
after, for a value that is never legitimately absent.

So `main()` does it first and overrides. The consequences are all in the right direction: dependent
providers are plainly synchronous, the failure is a crash at startup rather than an error state
threaded through the UI, and **the override is the test seam** — `providers_test.dart` swaps the
whole data layer onto a temporary encrypted file in one line, which is exactly what a screen in
increment (f) will need.

**The default throws rather than opening a database itself.** A convenient fallback would give every
call site a way around `openEncryptedDatabase`, which is the single choke point D-020 depends on. The
message names `main()` and the decision, because the developer who hits it is the one who needs it.

**Note for a future session.** Riverpod 3 wraps an error thrown inside a provider in a
`ProviderException`; a test asserting on the inner type directly will not match. Assert on the
message.

**Alternatives considered.** An async `FutureProvider<AppDatabase>` (rejected for the reasons above).
Passing repositories down the widget tree by constructor (rejected: D-007 settled Riverpod, and this
would reintroduce the prop-drilling it exists to avoid). Instantiating repositories inside widgets
(rejected: it is the layering violation §3 forbids, and it would make the data layer untestable
without a widget binding).

---

## D-033 — The design language, and tokens enforced rather than offered

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** The visual language, settled in `core/theme/` and enforced by
`theme_tokens_only_test.dart`.

### One accent: Persian turquoise

`#11726B` in light, `#5ED2C5` in dark. The colour of Isfahan tile work, deepened until it behaves
like a business colour. Chosen over Material blue because a tool for Iranian businesses should not
look like a generic dashboard, and over a saturated turquoise because at full strength that is a
craft-fair colour, not something to look at for eight hours while reconciling invoices.

It appears sparingly: primary actions, the selected navigation destination, focus rings.

### Colour means status, and nothing else means anything

Six semantic pairs — draft, unpaid, partiallyPaid, paid, cancelled, overdue — each a foreground and
a container, exposed as a `StatusPalette` theme extension.

**Money is deliberately *not* accent-coloured.** It is rendered in the strongest neutral. The moment
colour is also used for emphasis, colour stops being legible as meaning: a green amount beside a
green badge is two signals competing, and the badge loses. Prominence for money comes from the type
scale instead, which is what §10 actually asks for.

Individual choices worth defending: unpaid is **amber, not red** — an invoice inside its terms is
the normal state of business, not a problem; red is reserved for overdue, so red in a list means one
thing only. Draft is the quietest of the six, a plain neutral, because a draft should not compete
with a real invoice. Cancelled is a muted mauve-grey: recognisably not the draft neutral, and
without the urgency of red, because a cancelled invoice needs no action.

### Warm neutrals, and dark designed separately

Light neutrals are warm (`#FAFAF8` page, `#FFFFFF` cards): a pure-grey business tool reads as
clinical, and the warmth also stops the turquoise turning green against it. Dark neutrals go the
other way, very slightly cool (`#0F1211` page, `#161A19` surface) — a warm dark surface reads brown
next to a turquoise accent.

Dark is **not an inversion** (§10). Every value is picked for its own background: the accent is
lifted and desaturated so it does not glow, body text is `#E6E9E7` rather than pure white (which is
the usual cause of what people call dark-mode eye strain), the page is not black (halation against a
bright accent, and shimmering scroll edges on OLED), and the six status colours are re-picked at
dark-background contrast rather than lightened mechanically.

### Borders, not shadows

Structure comes from a hairline border plus a surface step. The reason is dark mode: a shadow is
nearly invisible on a dark surface, so a shadow-based hierarchy looks correct in light and collapses
in dark. Elevation is kept for genuine overlays — menus and dialogs — where a shadow is the only cue
that separates layers.

### The type scale

Vazirmatn 400/500/700 (D-022), with a per-platform fallback list for emoji and any glyph it lacks.

| Token | Size / line | Weight | Use |
|---|---|---|---|
| `pageTitle` | 24 / 1.45 | 700 | one per screen |
| `sectionTitle` | 17 / 1.5 | 500 | card and section headings |
| `body` / `bodyStrong` | 15 / 1.65 | 400 / 500 | prose; emphasised values |
| `caption` | 13 / 1.6 | 400 | secondary information |
| `label` | 12 / 1.5 | 500 | field labels, table headers, badges |
| **`amountLarge`** | **28 / 1.35** | **700** | **the prominent financial numeral style (§10)** |
| `amountMedium` | 19 / 1.4 | 700 | the amount in a list row |
| `amountSmall` | 15 / 1.5 | 500 | a table cell or secondary total |
| `identifier` | 14 / 1.5 | 400 | invoice numbers, national IDs, phone numbers |

Two Persian-specific choices. **Line heights are taller than a Latin scale would use** — the script
has deep descenders and stacked diacritics, and at 1.2 the descenders of one line touch the ascenders
of the next, which is the commonest way Persian typography is got wrong in an app built to Latin
defaults. And **every numeral style enables `tnum`**: without tabular figures a column of amounts
jitters by a few pixels per row, which makes a financial table feel unreliable without the reader
being able to say why.

### Enforcement

`theme_tokens_only_test.dart` fails the build on a literal colour (`Color(0x…)`, `Colors.…`) or a
literal size, radius, spacing, font size or duration anywhere outside the three token files.
Verified to bite by introducing both kinds of violation and watching it fail.

This is the rule most likely to erode quietly. Nothing breaks when someone writes
`EdgeInsets.all(14)` — it compiles, it looks fine in the one place they were looking, and the next
person copies it. A hundred screens later the layout is subtly irregular in a way nobody can point
at, and the design system is a folder of constants nothing reads. `// tokens-exempt: <reason>` is
the escape hatch, so an exception is visible and justified rather than forbidden.

**Alternatives considered.** A generated Material colour scheme from a seed (`ColorScheme.fromSeed`)
— rejected: it produces a competent palette nobody chose, and it derives dark from light, which is
exactly what §10 forbids. Shadow-based elevation (rejected above). Enforcing tokens by review
(rejected: that is what the rule already was).

---

## D-034 — Every user-facing string through the ARB, including the ones outside Dart

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** Persian is the only locale, pinned rather than inherited from the device; every
user-facing string comes from `lib/core/localization/arb/app_fa.arb` through the generated
`AppStrings`; and **no Arabic-script character may appear in code anywhere in `lib/`**, enforced by
`no_hardcoded_strings_test.dart`.

**The locale is pinned, not detected.** `supportedLocales` has one entry and `locale` fixes it, so a
user whose phone is in English still gets a Persian invoicing application — because that is what the
product is (§1), not a preference to negotiate.

**RTL is set once at the root.** The Persian locale already gives every descendant
`TextDirection.rtl`; the explicit `Directionality` in the app builder covers what renders outside
that subtree — overlays, dialogs, route transitions built from the navigator — so no widget ever has
to fight direction locally (§9). The navigation rail lands on the right with no positioning code at
all, because `Row` resolves against the ambient direction.

**Why the guard, when the strings are already Persian.** Hardcoding a Persian string in a widget is
not a bug: it renders correctly, in the right language, and looks finished. It becomes a problem
later and all at once — the day a second locale is added, or a wording rule has to be applied
consistently, or someone needs to check every user-facing string against a constraint like D-030's.
By then the strings are scattered across fifty widgets and the localization layer is a fiction. The
guard makes that impossible on the first line rather than expensive on the thousandth.

Comments are exempt — naming کد ملی in a doc comment is documentation, not copy — and
`// l10n-exempt: <reason>` covers the real exceptions. Three exist so far, all in
`core/formatting/number_display.dart`: the thousands separator, the decimal separator and the
percent sign. Those are **numeric punctuation, not copy** — properties of how Persian writes numbers
rather than phrases anyone would translate — and putting them in the ARB would invite someone
editing text to "correct" the separator to a comma.

**D-030 is checked mechanically now.** The same test asserts that `nationalIdFormatValid` names the
format and contains none of تأیید / تایید / صحیح / احراز. The constraint the owner set is no longer
only in a decision log; it fails the build if the copy drifts.

### Strings the ARB cannot reach

The platform manifests are user-facing and are not Dart: the Windows window title, the Android
`android:label`, and the web `<title>` and manifest. All four said `factorino` and now say
`فاکتورینو`, matching `appTitle`.

**The Windows one is written as `\u` escapes, not as glyphs.** MSVC reads the source with the system
ANSI codepage unless told otherwise, and a pasted Persian literal in `L"…"` compiled cleanly and
produced mojibake in the title bar — found by screenshotting the running build, not by any test. The
escapes carry no encoding assumption. This is the same lesson as the fold tables in
`persian_text.dart`: where the encoding of the source is not guaranteed, name the character by code
point.

**Alternatives considered.** Leaving the platform titles in English as a brand name (rejected: the
app already renders its own name in Persian, so the title bar would be the one place it did not).
`intl_utils` or another string-management package (rejected: `gen-l10n` ships with Flutter and does
this, and §2 asks whether the framework already provides it).

---

## D-035 — One logging wrapper: closure messages, nothing in release, and a guard that is the real control

**Date:** 2026-08-24 · **Status:** ACCEPTED · implements the project spec.

**Decision.** All logging goes through `AppLog` in `lib/core/security/app_log.dart`.
`test/core/security/logging_path_test.dart` fails the build if anything in `lib/` writes output
another way, or if a sensitive field name appears inside an `AppLog` call.

**Four properties, in the order they matter.**

1. **Nothing is emitted in a release build — not even an error.** The guard is `kReleaseMode`, a
   `const bool`, so the body is removed by the compiler rather than skipped at runtime. This is
   deliberately stronger than §7's "debug logging is stripped": in a release build the only
   destinations are logcat on Android and stdout on Windows, and both are readable by exactly the
   person the threat model is worried about. A line the developer cannot read but the holder of the
   device can is worse than no line.

2. **The message is a closure.** `AppLog.debug(() => '...')`, not `AppLog.debug('...')`. With an
   eager argument the interpolation runs at the call site *before* the call, so a sensitive value is
   materialized into a string in a release build even though nothing prints it. The closure is never
   invoked when the release guard returns first.

3. **The static guard is the control, not the scrubber.** `logging_path_test.dart` scans every
   `AppLog` call — following it across line breaks by balancing parentheses, because the formatter
   wraps these calls and a line-at-a-time scan would see `AppLog.debug(` on one line and
   `customer.fullName` on the next and match neither. The banned accessors are the §7 list:
   `nationalId`, `economicId`, `mobile`, `fullName`, `companyName`, `address`, `notes`,
   `grandTotal`, `subtotal`, `unitPrice`, `hex`, and their neighbours.

4. **The runtime scrubber is a backstop for shapes only, and says so.** `scrubForLogging` replaces
   runs of ten or more digits (national ID, economic ID, mobile, large amounts), runs of 32 or more
   hex characters (key material), and the wrapped key form the opener builds. It **cannot** catch a
   customer name, a company name, an address, or an amount below ten digits — those have no shape,
   and the entry says so rather than implying coverage it does not have. What it does catch is the
   value that arrives inside something the guard could not see through: a database exception's
   message, most plausibly.

**Two supporting decisions.**

*The framework's own error path is routed through it.* `FlutterError.onError` and
`platformDispatcher.onError` are set in `main()`. This is not hypothetical: a layout overflow dumps
the offending widget subtree, and in this application that subtree contains `Text` widgets holding
customer names and amounts. On the default path it reaches logcat verbatim, on any build.

*`platformDispatcher.onError` returns **false**.* It logs and then lets the platform terminate.
Returning `true` was tried and is recorded here as the mistake it was: a failure inside
`openAppDatabase` was swallowed, `runApp` was never reached, and because the Windows runner shows
its window only after the first frame, the result was a process running forever with no window and
no message anywhere — the exact silent degradation D-020's fail-loud startup exists to prevent.
Found by building and running it.

**Where the guard fired first.** On its own author: a doc comment in `app_log.dart` mentioning
`PRAGMA key` tripped `single_open_path_test.dart`, which scans comments as well as code. The comment
was reworded. The older guard was right to be broad and was not weakened.

**Alternatives considered.** `package:logging` (rejected: §2 asks whether the framework already
provides it, and `dart:developer` does — plus a package would have to be wrapped anyway to hold the
release strip and the scrubber). Relying on review (rejected: the failure is silent by construction —
a logged phone number produces no error, no crash and no visible defect).

---

## D-036 — The create/edit forms move into Phase 1 increment (f)

**Date:** 2026-08-24 · **Status:** ACCEPTED · **Owner ruling.**

**Decision.** Minimal create/edit forms for customers and for products ship in increment (f), rather
than waiting for Phase 2 and Phase 3.

**Reason.** Two requirements already in force could not be met without them, and the conflict was
put to the owner rather than resolved by quietly dropping one:

- **§10 requires every empty state to carry a clear call to action**, and §15 forbids fake
  functionality. A "افزودن مشتری" button that opened nothing would violate the second to satisfy the
  first; omitting it would violate the first. Only a real form satisfies both.
- **D-030 requires the national-ID copy to state the format and never the identity.** That
  constraint was enforced against the ARB by `no_hardcoded_strings_test.dart`, which cannot tell
  whether the copy is *used* correctly — an ARB entry that says the right thing is worthless beside
  a green "verified" tick. The form is the call site that makes the rule checkable against
  behaviour, and `customer_form_screen_test.dart` now checks it there.

There is also a plain practical reason: with no way to enter data, the four screens could only ever
be reviewed empty.

**Scope kept deliberately small.** Required-field validation, Iranian mobile validation accepting
`0`/`+98`/`0098` and any digit set, the national-ID checksum, and Toman-entry money parsing that
never touches a `double`. Detail views, filters, sorting, bulk actions and the rest of Phases 2 and
3 are untouched.

**Consequence for the ROADMAP.** Phases 2 and 3 keep their entries and lose only the form slice.
They are not complete and must not be marked so.

---

## D-037 — The desktop data table is a virtualized list, not `DataTable`

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** `core/widgets/app_table.dart` provides `AppTableHeader` + `AppTableRow`, laid out from
one shared list of `TableColumnSpec`s and rendered over a `ListView.builder`. Material's `DataTable`
and `PaginatedDataTable` are not used.

**Reason.** `DataTable` builds every row it is handed. A list of five thousand invoices would build
five thousand rows of widgets to show twenty — the O(n) UI-thread work §13 forbids, invisible at
fifty rows and fatal at five thousand, which is the definition of a defect shipped rather than
discovered. A header plus a builder-backed list is a real table that is also virtualized, and
`customers_screen_test.dart` asserts that a full page of rows does not build a full page of widgets.

Sharing one column list between the header and every row is the second half: a hand-built table
whose header drifts out of alignment with its columns looks like a data error rather than a layout
one.

**An RTL finding, recorded because it is counter-intuitive.** The amount column must **not** be
end-aligned. `AlignmentDirectional.centerEnd` resolves to the *left* edge in RTL, and numbers render
left-to-right whatever the surrounding direction — so pushing an amount to the trailing edge lines
figures up by their *first* digit and leaves the units digit ragged, which is exactly what tabular
numerals (D-033) exist to prevent. Leading alignment in RTL puts the digits' right edge on a common
line. The flag is documented on `TableColumnSpec.alignEnd` as the trap it is. Found by looking at
the running build; no test would have caught it.

**Alternatives considered.** `DataTable` with pagination controls (rejected: it solves the build
cost by refusing to scroll, and a paged table is a worse reading experience than a scrolling one for
a list the user is scanning). `TwoDimensionalScrollView` (rejected: the extra axis is not needed —
these tables scroll vertically only).

---

## D-038 — Lists page at the query level, through one widening window

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** Every list screen drives its query from a `ListQuery` (`core/utils/list_query.dart`)
carrying the search term and a row limit. The limit reaches SQL. "Load more" widens the window by
one page; **starting a search resets it to one page.**

**Reason.** §13 requires lists to work at thousands of rows. Virtualized rendering alone does not
achieve that: a `ListView.builder` over ten thousand rows builds only the visible widgets, but the
query behind it still loaded ten thousand rows, mapped them all to domain models and holds them in
memory. The limit has to reach the database, and `ListQuery` is what carries it there.

**Why one value rather than two providers.** The term and the limit change together or they are
wrong together: a user who scrolled through two thousand rows and then typed three letters must not
have the app ask for two thousand matches of those letters. Held as two providers they could differ
for a frame, and the symptom would be a needlessly enormous query rather than an error.

**Why a widening window rather than an offset.** The underlying read is a live query. A stream per
offset page would have to be merged and re-merged on every write, with rows able to shift between
pages in between. One widening window over one stream stays consistent with itself.

**Why an explicit control rather than infinite scroll.** A list that keeps loading as you scroll
gives no way to tell a long list from a slow one, and no way to reach the end of anything. On a
financial record, "is that all of them?" is a real question.

---

## D-039 — "Issued" excludes drafts, so a sales figure does not move while the user types

**Date:** 2026-08-24 · **Status:** ACCEPTED · **Corrects (d)**

**Decision.** `InvoiceRepository.totalIssuedRial` and `watchIssuedCountInPeriod` count only invoices
in `unpaid`, `partiallyPaid` or `paid`. Drafts and cancellations are both excluded. The set is named
once, as `kIssuedInvoiceStatuses` in `data/models/invoice_status.dart`.

**What it corrects.** As delivered in increment (d), `totalIssuedRial` excluded only cancelled
invoices, and a test asserted that behaviour explicitly. So a draft counted as revenue. Nothing on
screen depended on it until (f2), which is why it survived review — but the moment the dashboard
existed, "فروش این ماه" would have climbed as the user typed an invoice they had not issued, and
dropped again when they cleared it. A sales figure that moves while nothing has been sold is the
kind of wrong number that gets believed, because it moves for a reason the user can half-explain.

**Reason.** The method already promised this in its name: a draft is by definition not issued. The
codebase says so elsewhere too — `PaymentRepository.record` refuses money against a draft on the
grounds that it is "not yet a claim on anyone". Revenue recognised on a document that is not a claim
on anyone is not revenue.

**Why a positive list rather than "not draft and not cancelled".** The two read identically today and
fail differently tomorrow. If a status is ever appended to the enum, a negation folds it silently
into every revenue figure, while the list silently leaves it out. Of two silent outcomes, an
understated total someone questions beats an overstated one nobody does.

**Consequence for the dashboard.** The count tile counts exactly the population the sales tile sums,
which is why its label is "فاکتورهای صادرشده" and not "فاکتورهای این ماه" — the caption underneath
already names the month, and a count over one population beside a total over another is a pair of
numbers the user cannot reconcile. Reconciling is the only thing a dashboard is for.

**Alternatives considered.** Leave it and filter in the feature layer — rejected: the same wrong
figure would then be one call site away from returning, and the repository would still be answering
a question wrongly. Rename the method to `totalRial` — rejected: the name was right and the
behaviour was wrong.

---

## D-040 — The invoice list resolves its customer name in the query, as `InvoiceListItem`

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** `InvoiceRepository.watchList` returns `InvoiceListItem` — an `Invoice` plus the
customer's name — produced by one joined query. `Invoice` itself is unchanged and still carries only
`customerId`.

**Reason.** A list of invoices showing customer ids is useless, and a list that resolves each id
separately is an N+1 read issued from the presentation layer: invisible at ten invoices, ruinous at
five thousand, and forbidden by §13 and by §3's rule that widgets do not reach the data layer. One
join, one query, one stream.

**Why a new model rather than a field on `Invoice`.** `Invoice` is the header as stored. A customer
name is not stored on it and must not appear to be — the detail aggregate already resolves the
customer separately, and D-004's snapshot rule turns on being able to say precisely which fields are
historical and which are live. A separate list-shaped model keeps that line visible.

**What it deliberately does not carry: payments.** Nothing on `InvoiceListItem` would let a widget
compare payments against a total and decide for itself whether an invoice is paid. That
determination is made in `PaymentRepository` inside the same transaction as the payment write and
persisted (§6); a second, independent answer computed at display time is exactly how a badge comes to
contradict the payments listed beneath it. The UI cannot recompute it because the UI is not given the
inputs — design by impossibility rather than by convention.

**The customer side of the join is not filtered by `deleted_at`.** This is the one place a read
deliberately bypasses D-003, and it corrects a defect found while building (f2): `findDetail` used
`selectAlive` on the customer and returned `null` when the customer had been soft-deleted, so an
invoice became unopenable the moment its customer was removed — and the invoice list would have
dropped it entirely. Meanwhile the delete dialog promises the user, in Persian, that invoices already
issued to that customer "stay untouched and their amounts do not change". §6 guarantees such a
customer is soft-deleted only and never removed, so the row is always there to read. Both call sites
now read it, and a repository test covers the case.

---

## D-041 — One clock reading per frame, and overdue compared on Jalali days

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** "Now" is a Riverpod provider (`core/utils/clock.dart`), read once and passed down.
`overdue` is derived from it at display time by `invoiceStatusViewOf`, and an invoice is overdue only
once the **Jalali day** of its due date has ended in Tehran.

**Why a provider rather than `DateTime.now()` at each site.** Two readings inside one frame can
straddle midnight. The dashboard resolves a Jalali month from now and the invoice list ages invoices
from now; with separate readings a tile could report Shahrivar while the list beneath it aged an
invoice into Mehr. One value keeps everything on screen internally consistent — and makes both
testable against a fixed date, which is what lets the Jalali-boundary tests assert anything at all.

**It does not tick, and that is deliberate.** Resolved once and kept, so a month boundary or a due
date crossing midnight while the app sits open does not update until the next launch. A clock that
rebuilt every screen showing a date would be a timer running for the life of the process to correct a
figure nobody is looking at. A later phase can invalidate the provider on resume — one call, in one
place, precisely because the reading is not scattered.

**Why whole days rather than instants.** `now.isAfter(dueDate)` marks an invoice due at
midnight-Tehran as overdue for the entire day it is actually due. That is a red badge on a document
nobody is late on, and the cost is not cosmetic: it teaches the user that red does not mean anything.
The end of the due date's Jalali day is the first instant at which the invoice genuinely is late, and
`jalaliDayOf(due).end` computes it in the same calendar and the same offset as everything else
(D-006, D-028). The off-by-one is subtle enough to be worth a test at the minute: a due instant of
`2026-08-24T00:00Z` is 03:30 on 2 Shahrivar in Tehran, so its day ends at `2026-08-24T20:30Z` — the
same UTC date, which is exactly what an instant comparison gets wrong.

**Overdue is still never stored** (as `status_badge.dart` already said): a stored `overdue` would be
wrong the moment the clock passed midnight and nothing wrote to the row. And it applies only to
`unpaid` and `partiallyPaid` — a paid or cancelled invoice past its due date is paid or cancelled,
because nobody is late on it.

---

## D-042 — Phases 2 and 3 are re-scoped to what Phase 1 did not already deliver

**Date:** 2026-08-24 · **Status:** ACCEPTED · **Owner's ruling**

**Decision.** `ROADMAP.md`'s entries for **Phase 2 — Customers** and **Phase 3 — Products and
Services** are rewritten to name only the work that genuinely remains. Each now opens with an
explicit "already delivered in Phase 1, and not to be rebuilt" list. Phase 5 and Phase 8 get the same
treatment in one paragraph each, for the same reason.

**Reason.** Increment (f1) built the customer and product screens end to end — list,
normalization-insensitive search, create and edit forms, soft delete with its Persian explanation,
mobile validation, national-ID checksum — because the owner pulled the create/edit forms forward
into Phase 1 (D-036). Phase 2 and Phase 3 were written before that happened and still described all
of it as future work.

A roadmap entry that describes finished work is not merely stale. The project spec tells a fresh
session to read the roadmap and continue from it, and §15 forbids recreating existing architecture —
so an entry saying "build the customer list with search" is an instruction to rebuild a screen that
exists, issued to the one reader least able to tell. The cost is not a wasted afternoon; it is a
second implementation of a screen, diverging from the first, with the guard tests passing on both.

**What actually remains, and why each item is real rather than invented.**

- **The customer detail screen** (`/customers/:id`). The only substantial piece missing. The strongest
  evidence it is real: `InvoiceRepository.watchForCustomer` was built in (d) and **has no call site**
  — it was designed for exactly this screen and nothing else has needed it since.
- **Field-level limits at the form boundary** (§7). Not a formality. The schema carries `withLength`
  on every text column and the forms carry nothing, so an over-long name is accepted by the form,
  rejected by drift, and reported to the user as the generic "خطایی رخ داد" — the failure is real,
  the message is useless, and the user is not told which field. The limits must come from one place
  shared with the table definition, because a schema limit and a form limit that disagree silently is
  the failure worth designing out rather than fixing twice.

**What was removed from Phase 3, and where it went.** Phase 3's original entry is otherwise complete,
including the one requirement in its security note — the `kMaxAmountRial` ceiling is already enforced
on the price field. §11 lists a product-detail route, but the edit form already shows every field a
product has; the only question a detail screen could answer that the form cannot is "where has this
been sold, and at what price", which is a **report**. It moves to Phase 8 with the other reports, and
`/products/:id` gets registered there, with the screen, per D-021. Building a detail page here to
satisfy a route list would produce a page that duplicates the form — fake functionality in the
precise sense §15 prohibits, because it would look finished.

**Alternatives considered.** Leave the entries and rely on `CURRENT_STATE.md` to warn the next
session — rejected: `CURRENT_STATE` is about the current increment and turns over every session,
while the roadmap is the durable record; the warning would be gone in two sessions and the wrong
entry would still be there. Merge Phase 3 into Phase 2, since one item remains — rejected: the phase
numbering is referenced from the project spec and from a dozen cross-references, and renumbering to
save one heading trades a real cost for a cosmetic gain. A phase that is honestly small is better
recorded as small than dissolved.

---

## D-043 — Field limits are named once, and drift cannot be told about it

**Date:** 2026-08-25 · **Status:** ACCEPTED · implements the project spec's field-level limits.

**Decision.** Every free-text field's maximum length is named once, in
`lib/data/models/field_limits.dart`, and read from there by the forms. Every text field in `lib/`
goes through `AppTextField`, whose `maxLength` is a **required** parameter.
`test/core/widgets/field_limit_path_test.dart` fails the build on a raw `TextFormField`/`TextField`
or on a `maxLength` that is a bare number rather than a `*Limits.` reference.
`test/data/database/field_limits_test.dart` asks each generated column where it actually starts
rejecting values and fails if that disagrees with the constant.

**The gap this closes.** The schema has carried `withLength` on every text column since increment
(a); the forms carried nothing. So an over-long name was accepted by the form, sent to the
repository, and refused by drift with an `InvalidDataException` that `describeFailure` does not
recognise — surfacing as the generic «خطایی رخ داد». The user was told something went wrong, not
which field or why, and the value they had typed was still on screen looking perfectly reasonable
(D-042 named this; this entry is its implementation).

### The obvious way to share the constant does not work, and fails silently

The natural design is `withLength(max: CustomerLimits.fullName)`. **It compiles, generates, and
produces a column with no length constraint at all.** `drift_dev` reads that argument with
`readIntLiteral`, which accepts an `IntegerLiteral` and returns `null` for anything else
(`drift_dev-2.34.5/lib/src/analysis/resolver/dart/helper.dart:206`).

This was verified rather than inferred. Changing the one column and regenerating produced:

```
-    additionalChecks: GeneratedColumn.checkTextLength(
-      minTextLength: 1,
-      maxTextLength: 120,
-    ),
+    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
```

`build_runner` reported no error and no warning. Sharing the constant would therefore have left the
schema **weaker** than before the sharing was introduced — the exact shape of failure this project
keeps writing guards against.

**So the tables keep their integer literals, and a test closes the loop instead.** It is the
stronger of the two checks: asking `isAcceptableValue` where the column starts refusing proves the
constraint exists *and* where it bites, rather than proving two source files contain the same token.
Confirmed to bite — with the constant reference in place it failed naming `full_name` and the exact
cause.

### Why a required parameter rather than a lint or a convention

A wrapper whose limit is optional is a wrapper someone omits on the field that needed it. Making
`maxLength` required moves half the rule to the compiler: a new field cannot exist without a limit.
The scan covers the other half — a field that bypasses the wrapper, and a limit written as a number.
Same treatment as the single database opener (D-020), the single normalizer (D-029) and the logging
wrapper (D-035), for the same reason: **the failure is silent**, and review is what missed it for all
of Phase 1.

**One exemption exists**: the search field (`core/widgets/search_field.dart`). A search term is never
stored, so there is no column whose limit it could disagree with; it reaches SQL as a bound parameter
through `searchKey` (D-018, D-029), and a length limit would only decide how much of their own query
the user can see. Marked `// field-limit-exempt:` with that reason, which is the escape hatch working
as intended.

### Three details that are easy to get subtly wrong

**The validator measures what drift measures.** `maxLength` stops the *user* at the limit counting
grapheme clusters; `GeneratedColumn.checkTextLength` counts `String.length`, UTF-16 code units. For
Persian carrying combining marks those differ, so a name of 120 clusters can be 130 code units and
still be refused by the column. `AppTextField`'s validator uses `String.length`, closing the gap in
the column's own unit, and says which field and what the limit is.

**Digits are filtered, not folded.** `digitsOnly` keeps digits in whichever of the three sets the
user typed rather than normalizing under the cursor — a caret that jumps because the text beneath it
changed length is a worse failure than the one being prevented. Folding still happens at parse time,
in `normalizePersianDigits`. The filter itself is `keepDigitsOnly` in `core/formatting/`, because
that is the only directory permitted to know what a digit is (D-029).

**The counter appears only near the limit**, and never on a field shorter than 40 characters. A
permanent «۰/۲۰۰۰» under every field is decoration, which §10 removes; a field that silently stops
accepting keystrokes is worse. A ten-digit کد ملی stops at ten because that is what a کد ملی is, and
counting toward it would be counting something the user is not worried about.

**Alternatives considered.** Referencing the constant from `withLength` (rejected: it silently drops
the constraint — see above). Duplicating the numbers and adding a test that compares the two source
files (rejected: it proves the tokens match, not that the constraint is applied). A lint rule
(rejected: `custom_lint` is the package D-015 excludes for dragging the analyzer, and with it drift
and sqlite3, backwards). Truncating silently with no validator (rejected: the grapheme/code-unit gap
would still reach the database).

---

## D-044 — The customer detail screen composes one view, and shows the record differently per tier

**Date:** 2026-08-25 · **Status:** ACCEPTED

**Decision.** `/customers/:id` renders a single `CustomerDetailView` — the customer, one
`CustomerTotals`, and that customer's invoices — assembled in `customerDetailProvider` and rendered
as one loading state, one error state, one moment.

**Why one value.** The same reason `DashboardSummary` is one value: the totals and the invoice list
sit on the same page and the user reads them together to reconcile. Settled independently they would
occasionally show a balance from before a payment beside the list from after it — a pair that never
existed, which is worse than either figure being late.

**The totals are one SQL statement, using `FILTER`.** Billed and outstanding cover *different*
populations — issued invoices (D-039) and outstanding ones — so they are two aggregates with two
predicates:

```sql
SELECT SUM(grand_total_rial) FILTER (WHERE status IN (issued)),
       SUM(grand_total_rial - COALESCE((SELECT SUM(amount_rial) FROM payments
                                        WHERE deleted_at IS NULL
                                          AND invoice_id = invoices.id), 0))
         FILTER (WHERE status IN (unpaid, partiallyPaid))
FROM invoices WHERE deleted_at IS NULL AND customer_id = ?
```

`FILTER` needs SQLite 3.30; this application ships 3.53.4, and the clause was exercised on the real
Windows build rather than only in tests. The correlated subquery is the one `watchOutstandingRial`
already uses, for the reason recorded there: a join to `payments` multiplies an invoice's grand total
by its number of payment rows, which is invisible until the second instalment.

**Billed excludes drafts and cancellations, and the caption says so.** Without the caption the figure
does not match the rows beneath it — the demo customer's page shows a 55,000,000 draft in the list
and 21,230,000 billed — and a figure the user cannot reconcile is one they learn to distrust (D-039).

**`watchForCustomer` is reused rather than replaced.** It was built in increment (d) and had no call
site until now. The customer's name for each row is the one already loaded above, not a per-row
lookup: this is the one screen where the join `watchList` performs is genuinely unnecessary, because
there is exactly one name and it is in hand.

**`InvoiceCard`/`InvoiceTableRow` gain `showCustomer`, defaulting to true.** On a customer's own page
the name is identical on every row — repetition of something the reader already knows, pushing the
invoice number, which is what identifies the row, into second place. §10 removes what does not aid
comprehension. The widget is otherwise unchanged: same shape, same order, same emphasis, so an
invoice still looks like an invoice wherever it is seen; the heading slot takes the number instead.

**The record card is collapsible on mobile and open on desktop.** Its height has no upper bound the
layout can be designed around — notes run to two thousand characters — so above the invoice list it
can push that list arbitrarily far down the page, on the one screen whose purpose is to show it.
Below the list it would be just as unreachable, past however many invoices the customer has.
Collapsing keeps both answers in reach; desktop has room for a panel and keeps it open.

**Empty fields say «ثبت نشده» rather than being hidden.** A record that omits what is missing looks
complete, and the user cannot tell "no company recorded" from "companies are not shown here" — which
matters when the missing field is the one an invoice needs.

**D-030 binds here too.** This screen *displays* a stored national ID. A passing checksum was never
an identity, so there is no tick, no badge and no affirmative word anywhere near the value, and the
screen test asserts the absence of both the copy and the iconography.

**Invoice rows stay non-tappable**, asserted by a test, until `/invoices/:id` exists in Phase 5
(D-021, one level down).

**On linking an invoice to its customer** — the third item in D-042's Phase 2 scope, left as a design
call for when the screen existed. **Decided: no link.** An invoice row's primary target must be the
invoice, which arrives in Phase 5; making the row open the customer instead would put the wrong
destination on the obvious affordance and then have to be taken away. The customer list is one
navigation click away, and it searches.

---

## D-045 — A write outlives the widget that started it

**Date:** 2026-08-25 · **Status:** ACCEPTED · **Corrects (f1)**

**Decision.** `CustomerEditor` and `ProductEditor` take a `ref.keepAlive()` link for the duration of
`save` and `delete`, and close it in a `finally`.

**What it corrects.** Soft-deleting a customer or a product from a list row threw
`UnmountedRefException`. Nothing on a list screen watches the editor provider — the row reads the
notifier and awaits it — so the auto-disposed controller was collected during the await, and the
`state = ...` write after it threw. **The delete had already happened**: the row left the list on the
next stream emission, but the user was shown no confirmation for something that did occur, and an
unhandled exception reached the zone.

**Why it survived (f1).** The one call site that was exercised was the form, which watches the
controller for its in-flight flag and therefore keeps it alive. The list's delete path shipped
untested; it was found by writing the equivalent test for the detail screen and then, once the cause
was understood, for the list where it originally shipped. Both are now covered.

**Why a scoped link rather than `keepAlive: true` on the provider.** the project spec prefers scoped,
auto-disposed providers. The link expresses exactly what is true — this controller must survive for
as long as its write is in flight, and no longer — rather than keeping a controller alive for the
life of the process to fix a window of a few milliseconds.

**Alternatives considered.** Having every acting widget `ref.watch` the editor (rejected: it is
per-call-site discipline, which is what failed here, and it rebuilds a list row on every state
change). Checking `ref.mounted` after the await and skipping the state write (rejected: it silences
the symptom and still loses the error state that a failed write needs to report). Making the provider
`keepAlive` (rejected above).

---

## D-046 — The invoice editor previews through the engine, and nothing else may calculate

**Date:** 2026-08-25 · **Status:** ACCEPTED · Phase 4 increment (a).

**Decision.** `InvoiceEditorState` (`features/invoices/domain/`) holds an invoice being edited and
exposes `totals`, the `CalculatedInvoice` the money engine produced for it. Every figure a screen
displays comes from there. `test/core/money/single_calculation_path_test.dart` fails the build if
anything in `lib/` outside `core/money/` calls `calculateInvoice` other than that state model and
`DriftInvoiceRepository`.

**Why two callers, and why exactly two.** They exist for different reasons and both are necessary:
the editor computes the **preview** on every edit, and the repository computes the totals again
**inside the write transaction**, because a caller must not be able to supply a total (D-004). The
hazard is that they could be fed slightly different inputs — a preview that passes the invoice
discount but forgets the rounding unit, say. Each answer would look entirely reasonable on its own,
and the user would agree to one number and receive another with nothing in either path looking wrong.

So the two are pinned against each other by
`test/features/invoices/invoice_preview_matches_write_test.dart`, which builds a state, writes its
draft through the **real encrypted database**, and asserts that every stored figure equals the one
the preview showed — the invoice totals, the warnings, and each line's effective discount, resolved
tax rate, net, tax and total. The scan exists because a *third* caller would not be covered by that
test. Verified to bite: a plausible `previewTotal()` helper added to the invoice list screen failed
it naming the file and line.

**The state computes nothing, and is recomputed rather than mutated.** It is immutable; every edit
produces a new state whose constructor runs the engine. Caching the totals would be an optimisation
over a pure integer pass across a handful of lines, with a staleness bug attached.

**Settings are watched, not captured.** `defaultTaxRateBp` and `roundingUnitRial` are the last step
of §4's chain and they live in settings, so the controller watches `appSettingsProvider` and carries
the entries across the rebuild. A preview that captured the rate at open time would keep describing
a rule that no longer applied, and the repository — which re-reads settings inside the transaction —
would then store something the user was never shown.

**`copyWith` needs explicit `clear` flags.** For `taxRateBp`, `discountPercentBp` and `productId`,
`null` is a *meaningful value*: inherit, absolute-not-percentage, freehand. The usual "null means
unchanged" convention would let a caller set those but never unset them, so "inherit" would be
unreachable the moment anything had been chosen — which is D-026's distinction quietly lost at the
UI boundary rather than in the engine.

**A percentage and an amount are alternatives, enforced in the controller.** The engine lets a
percentage win over an absolute amount (§4 step 2), so `setDiscountAmount` clears the percentage and
`setDiscountPercent` zeroes the amount. Left alone, a stale percentage would silently override the
figure the user had just typed.

**Alternatives considered.** Letting the screen hold a mutable list and call the engine itself
(rejected: it is the third caller this decision forbids, and §3 forbids calculation in widgets).
Having the state hold raw text and parse lazily (rejected: parsing belongs at the field boundary
through `core/formatting/`, and a model holding unparsed text makes every reader wonder whether a
value is trustworthy). Computing totals in the repository only and having the screen show nothing
until save (rejected: a user cannot agree to a figure they were never shown).

---

## D-047 — `CalculatedInvoice.grossTotal`, so the printed summary reconciles by hand

**Date:** 2026-08-25 · **Status:** ACCEPTED · extends increment (b)'s engine.
**Its one open question — whether to store the gross — was settled on 2026-08-27 by D-055: store it,
and two per-line figures with it, as `schemaVersion = 4`.**

**Decision.** The engine gained `grossTotal` — `Σ lineGross`, before any discount and before tax —
and a second runtime invariant beside the §4 one:

```
grossTotal − totalDiscount + totalTax + roundingAdjustment == grandTotal
```

**The problem it solves.** §4's invariant is `grandTotal == subtotal − invoiceDiscount + totalTax`.
That proves the engine is *self-consistent*. It does not give a document a set of figures a customer
can check with a pencil, because `subtotal` is already net of the **line** discounts while
`totalDiscount` (D-027) is the sum of the line discounts *and* the invoice discount. A summary
printing subtotal, total discount, tax and total therefore does not add up — the line discounts are
subtracted twice by anyone reconciling it. On a worked example: gross 2,500,000, line discounts
350,000, invoice discount 100,000, tax 184,500 — the subtotal-based arithmetic lands 350,000 short of
the printed total.

Starting from the gross adds up exactly, which is what the new invariant states.

**Why the engine rather than the screen.** The alternative was to sum the line grosses in the summary
widget. That is a second implementation of part of §4 living in a widget, which §3 forbids and which
D-046's scan exists to prevent one level up. The instruction that produced this entry is worth
recording as the general rule: *if a figure is needed that the engine does not produce, extend the
engine.*

**Checked at runtime, not only in tests**, exactly like the §4 invariant and for the same reason: the
alternative to crashing on a summary that does not reconcile is printing one. The engine's own suite
asserts it on every case including the 450-combination sweep, and one test states the trap
explicitly by showing the subtotal-based arithmetic being short.

**Not stored.** `invoices` has no `gross_total_rial` column and does not need one yet — nothing reads
a stored invoice's summary until the invoice detail screen (Phase 5) and the PDF (Phase 7). Both will
need it, and per-line gross is **not** recoverable from what is stored today: `invoice_items` keeps
`unit_price_rial`, `quantity_milli`, the effective `discount_rial` and `line_net_rial`, where
`line_net_rial` is the net *after* the allocated invoice discount. Recomputing gross from price ×
quantity would re-run §4 step 1 outside the engine, which is the thing D-046 forbids. **Phase 5 must
decide** whether to store the gross or to widen what the engine returns for a stored invoice; it is
recorded here rather than solved now because the right answer depends on what the detail screen and
the renderer actually need.

---

## D-048 — Invoice numbers are allocated on issue, not on draft creation

**Date:** 2026-08-25 · **Approved by the owner and implemented:** 2026-08-26 · **Status:** ACCEPTED

The owner approved this on 2026-08-26 and directed that it land as **its own reviewable step before
Phase 4 increment (b)**, rather than inside (c): it is the project's first migration and a build is
already installed on a real device. See the implementation note at the end of this entry.

**The defect, measured.** `DriftInvoiceRepository.create` calls `_allocateNumber` unconditionally,
including for a draft. Verified against the real database rather than inferred:

```
draft #1 number = INV-1405-0001
draft #1 abandoned (softDeleteDraft)
draft #2 number = INV-1405-0002
```

`INV-1405-0001` is gone permanently. The unique index deliberately covers soft-deleted rows, because
a spent number stays spent (D-013) — which is right for an *issued* invoice and wrong for a draft
nobody ever saw. A user who opens a form, changes their mind and closes it has silently consumed an
invoice number, and a business whose numbering has gaps has a conversation to have with an auditor.

**Decision.** A draft carries **no** number. Allocation happens in `issue()`, inside its transaction,
against the Jalali year of the issue date (D-013 unchanged in every other respect).

**What it costs, stated plainly: the first schema migration.** `invoices.number`, `number_year` and
`number_sequence` are all non-null today. They must become nullable, because:

* an empty-string sentinel does not work — SQLite's unique index treats `''` as equal to `''`, so a
  second numberless draft would collide, while **NULLs are distinct in a unique index**, which is
  exactly the behaviour needed;
* the alternative, a separate drafts table, would duplicate every column and every query.

That makes this `schemaVersion = 2`, the first migration in the project, and per §6 and §14 a
migration without a test is not done. Known issue 1 has been waiting for this since increment (a),
and a build is already installed on a real device, so the migration has to run rather than being
skipped by a reinstall.

**Why it is proposed rather than done.** The owner's split puts numbering in increment (c), and this
is a schema change touching a table every other feature reads — it deserves its own reviewable step
rather than being folded into the state model. Recorded now so (c) starts from a measured defect and
a decided shape.

**Consequences to carry into (c).**

* `InvoiceListItem`, the invoice list and the customer detail screen all render `invoice.number`. A
  draft's number becomes null and every one of those needs Persian copy for it — not an empty cell.
* `watchList` orders by `issueDate` then `numberSequence`; a null sequence needs a defined position.
* The status badge already distinguishes پیش‌نویس, so "this document has no number yet" is
  consistent with what the user is already told.

### Implementation note (2026-08-26) — what the migration actually cost

Delivered as its own step at the owner's direction. `schemaVersion = 2`; the three columns are
nullable; `create` allocates nothing for a draft and `issue` allocates inside its own transaction.

**The migration is a 12-step table rebuild, and its real hazard is the cascade.** SQLite cannot
relax `NOT NULL` in place, so `Migrator.alterTable` creates a new table, copies, drops the old one
and renames. **Step 6 is `DROP TABLE invoices`** — and with foreign keys enabled that runs an
implicit delete which cascades into `invoice_items` and `payments`. Drift guards against it by
issuing `PRAGMA foreign_keys = OFF` *before* opening its own transaction and restoring it after,
which works only because drift invokes `onUpgrade` outside a transaction.

**That guard was verified to bite rather than assumed.** Wrapping the `alterTable` call in
`db.transaction` — which reads as a *safety* improvement, and is the obvious "tidy-up" a later
session would make — leaves `invoice_items` at **zero rows**, because SQLite silently ignores
`PRAGMA foreign_keys` inside a transaction. Every line and every payment in the database, gone. The
schema-comparison test still passed, and so did the test asserting the numbers were preserved: the
*invoices* survive, only their children are destroyed. One test out of six noticed.

This is why the data test does not use `SchemaVerifier.testWithDataIntegrity`, which documents that
it disables foreign keys — precisely the condition under which the bug does not reproduce — and why
it runs through `openAppDatabase` against a real encrypted file rather than the verifier's
in-memory one. A `// Deliberately NOT wrapped in a transaction` comment now sits on the call.

The migration also runs `PRAGMA foreign_key_check` afterwards, which is step 9 of SQLite's procedure
and which drift's `alterTable` states in its source that it skips.

**Numbers already spent are not reclaimed.** A draft migrated from v1 keeps the number v1 gave it,
and `issue` allocates only when the column is null. The gap is in the past; rewriting a document's
identity is worse than a gap (D-013).

**Ordering needed a decision the old schema never posed.** `watchList` ordered by `issueDate DESC,
numberSequence DESC`, and a null sequence has no defined position. It is now
`issueDate DESC, numberSequence DESC NULLS FIRST, createdAt DESC, id DESC`: a draft sorts above the
invoices of its own date (nothing was issued after it, because it has not been issued), and the last
two keys make the order **total** — `created_at` is milliseconds and two drafts can be written
inside one, so the unique id is what guarantees the same answer on every read rather than a list
that reshuffles.

**One string, three call sites.** «بدون شماره» — deliberately not a repeat of «پیش‌نویس», which the
status badge already says beside it in all three layouts, and deliberately not blank, because an
empty cell reads as data that failed to load. The wording and the bidi rule live together in
`invoiceNumberLabel` (`features/invoices/domain/`): a real number is isolated because it mixes a
Latin prefix with digits (§9), and the Persian placeholder is not, because there is nothing to
protect and the isolate marks would only be invisible characters in a string tests and screen
readers have to handle.

---

## D-049 — The table rebuild refuses to run where the foreign-key pragma is ignored

**Date:** 2026-08-26
**Status:** ACCEPTED
**Supersedes:** nothing. Extends D-048.

**Decision.** `_migrateV1ToV2` calls `assertForeignKeysCanBeDisabled(db)` before
`Migrator.alterTable`, and the migration aborts with a `StateError` naming the consequence if the
check fails. The call site carries a comment that begins `DO NOT WRAP THIS FUNCTION, OR THE CALL
BELOW, IN A TRANSACTION`, and four tests in `invoice_number_migration_test.dart` pin the guard, its
premise, and the data loss it prevents.

**Reason.** D-048 identified the defect but defended it only with a comment and one test out of six.
That is not enough for this shape of bug. Wrapping the `alterTable` call in `db.transaction` reads
as a safety improvement, is the change a careful reviewer would suggest, and silently deletes every
`invoice_items` row and every `payments` row in the user's database — every line of every invoice
and the whole payment history — while producing exactly the correct schema and leaving five of six
tests green, because only the child rows die. A defect that survives review, survives the type
system and survives most of its own test suite is one that ships.

**How the guard works, and why it is not a heuristic.** It does not try to answer "am I inside a
transaction". It performs the one operation `alterTable` depends on and reads the result back: issue
`PRAGMA foreign_keys = OFF`, then ask what the pragma says. Outside a transaction it reads `0`;
inside one SQLite ignores the write, reports no error, and it still reads `1`. That difference is
the whole bug, observed directly rather than inferred, so the guard catches every route to the
condition — an explicit `db.transaction`, a batch, or a future drift release that begins running
`onUpgrade` inside a transaction — and not merely the one spelling a source scan could match. It
costs two pragmas, it runs before anything destructive, and it restores the connection's prior
state whether or not it passes.

**Verified to bite, by doing it.** Wrapping the real migration in `db.transaction` now fails the
data-survival test at the guard, with the message naming the cascade, instead of passing five of six
tests with an emptied `invoice_items`. The wrapper was then removed.

**Alternatives considered.**

- *A `lib/`-scanning source guard*, in the style of the project's other nine. Rejected: it would
  have to recognise "this call is lexically inside a transaction block" from Dart source with a
  regex, which is fragile in both directions — it cannot see a transaction opened by a caller two
  frames up, and it would misfire on an unrelated nearby `transaction(`. The runtime check is
  strictly stronger and has no false positives.
- *`sqlite3_get_autocommit()`*, the C API's direct answer. Rejected: not reachable through drift's
  `QueryExecutor`, and it would answer a narrower question than the one that matters.
- *Leaving the comment and the test as the only defence*, as D-048 did. Rejected for the reason
  above: the comment is advisory and the test that catches it is outnumbered five to one.

**Where it applies next.** Any future migration that rebuilds a table with children must call it.
The function is named for what it checks rather than for this migration, and it is public so a test
can call it from inside a transaction and watch it refuse.

---

## D-050 — A line's tax is a three-state field, and the picker copies in two steps

**Date:** 2026-08-26
**Status:** ACCEPTED
**Extends:** D-004 (price snapshots), D-026 (zero is not "unset")

**Decision.** Three choices made while building line item entry, recorded because each has a
plausible simpler alternative that is wrong.

**1. The per-line tax control is a mode plus a value, never one field.** `_TaxMode.inherit` and
`_TaxMode.custom` sit above the rate field; inherit sends `null`, custom sends whatever was typed
**including zero**. The obvious simplification — one field where empty means inherit — collapses the
two states D-026 exists to separate, and it fails in the expensive direction: a line the user marked
tax-exempt would silently take the default VAT rate. That is a wrong total on a tax document which
looks right to everyone except the tax authority. Under `inherit` the sheet *shows* the rate the
engine resolved, read off `CalculatedLine.resolvedTaxRateBp`, because "default" is only reassuring
if it names a number — and the widget may not resolve the chain itself, so where there is no
calculated line to read it says nothing rather than guessing.

**2. Picking a product opens the line sheet rather than adding a line directly.** One tap would be
fewer taps. But a picked product still needs a quantity, and it may need a discount or a rate, so a
direct add produces a line the user must immediately open anyway. The sheet is also where the copy
D-004 requires becomes visible: the user sees the title, unit and price that were copied, in fields
they can change, before the line exists. A price the user can edit on the invoice without editing
the catalogue is the honest reading of "the price is a snapshot".

**3. Reordering is two buttons, not a drag.** The lines list lives inside the invoice form's own
scroll view, where a long-press drag competes with the scroll gesture, and on desktop there is no
drag affordance at all. Two taps that always work beat one gesture that sometimes does. The
end-of-list buttons are **disabled rather than hidden**, because a control that vanishes shifts the
two beside it under the user's finger.

**Also settled here.**

- **The percent field is basis points by construction.** Two decimal places of a percent *is* a
  basis point, so `tryParseScaledInput(text, scale: 100)` gives `9.5% → 950` exactly, with no
  rounding step and no `double`. The same parser handles quantity at `scale: 1000`.
- **A fourth decimal place on a quantity is refused with its own message.** `tryParseScaledInput`
  returns null both for "not a number" and for "too precise", which deserve different messages: the
  second is a rule the user could not have known, and «نادرست» would leave them retyping the same
  value. They are told apart by re-parsing at a finer scale.
- **The field's text is not the display format.** `formatQuantityMilli` renders Persian digits and a
  Persian decimal separator, which is right for a label and wrong for an editable field: a field's
  text is re-parsed on submit, and pre-filling it with characters the parser must fold back is how a
  value the user never touched comes out different from the one that went in. The sheet keeps a
  small ASCII pair for that, documented beside the display formatters they deliberately are not.
- **Switching discount mode clears the field.** `10` means ten Toman in one mode and ten percent in
  the other; carrying the text across would silently change what the user entered.
- **`InvoiceLimits` is separate from `ProductLimits`.** A line title may be 200 characters and a
  product name 160, because a free-text line describes a job rather than naming a thing. The
  relationship that matters — every product limit at or below its line counterpart, so a copy can
  never overflow — is asserted in `field_limits_test.dart` rather than left to be noticed.

---

## D-051 — An issued invoice must snapshot its customer, and that is its own increment

**Date:** 2026-08-26
**Status:** ACCEPTED in principle; **implemented in increment (c2)** as schema v3 — see **D-052**
**Extends:** D-004 (price snapshots), D-003 (soft delete)

**The question.** `invoices` stores `customer_id` and nothing else about the customer. Every screen
that shows a name resolves it by joining to the live `customers` row. The project spec does not say
whether that is right; it requires snapshots for `invoice_items` and is silent here.

**The decision: it should snapshot, for the same reason line items do.** An invoice is a document,
and a document does not change after it is issued. Today, renaming a customer — a correction, a
marriage, a company changing its trading name — silently rewrites the name on **every invoice ever
issued to them**, including ones already sent, already paid, and already filed. Reprinting an
invoice from last year would produce a different document from the one the customer holds. That is
the same failure D-004 exists to prevent, and it is worse here than for a price, because the
identity of the party is what an auditor reconciles against.

Two related things make it concrete rather than theoretical:

- **Customers are editable and the app encourages it.** The customer form is Phase 2 and shipped.
- **A soft-deleted customer still has invoices** (D-003), and those invoices still have to print a
  name. Resolving through a deleted row works today only because soft delete keeps it.

**What to snapshot.** Not the whole record — the fields an Iranian invoice prints and an auditor
checks: full name, company name, national ID (کد ملی) and economic ID (شناسه اقتصادی), and the
address. The mobile number is contact detail rather than document content and is deliberately
excluded; it can keep resolving live.

**When to snapshot.** At **issue**, not at draft creation. A draft is not yet a document, and a
draft written before a customer's name was corrected should pick the correction up. `issue()`
already exists and is already the moment the invoice becomes one — the same transaction that
allocates the number.

**Why this is not part of increment (c).** It needs five new columns on `invoices`, which makes it
`schemaVersion = 3` — the project's second migration, on a database that is installed on a real
device. D-049 exists because that migration path is where the most expensive defect in this project
lives, and folding a schema change into an increment about form fields would mean the migration
lands without being the thing under review. (a2) set the precedent: a migration is its own
reviewable step. So this is **increment (c2)**, to be scheduled by the owner.

**What (c) does in the meantime.** The customer field resolves the name live by id, through
`customerByIdProvider`. That is correct for a draft — which is all (c) can produce, since it writes
drafts and issues them in the same session — and it is the behaviour that (c2) will change for
issued invoices only.

**Alternatives considered.**

- *Denormalize the display name only, one column.* Rejected: the national and economic IDs are the
  fields with legal weight on an Iranian invoice, and they are exactly the ones a correction would
  change. A snapshot that captures the name and not the tax identifiers protects the least
  consequential field.
- *Snapshot at draft creation.* Rejected: a draft is not a document, and freezing a name at the
  moment a form opened would make a correction unreachable without deleting and retyping the
  invoice.
- *Do nothing and treat the live join as correct.* Rejected. It is a silent rewrite of issued
  documents, and the user would have no way to notice it had happened.

**Also recorded here: the payment term is not configurable, and should be.** `defaultDueDate` in
`features/invoices/domain/` is a 30-day constant. A payment term belongs in `settings` beside the
VAT rate and the numbering prefix, and putting it there is the same kind of schema change. It is a
**gap, not a decision** — noted so it is scheduled rather than discovered. Until then the user
overrides the due date per invoice, which they can already do.

---

## D-052 — The party snapshot, schema v3, and what a migration may not invent

**Date:** 2026-08-27
**Status:** ACCEPTED — implemented in Phase 4 increment (c2)
**Implements:** D-051 · **Extends:** D-004 (price snapshots), D-048 and D-049 (the first migration)

D-051 decided *that* an issued invoice must snapshot its customer, and deferred the schema change to
its own reviewable increment on (a2)'s precedent. This records what building it settled.

### The columns

Five nullable columns on `invoices` — `customer_name_snapshot`, `customer_company_snapshot`,
`customer_national_id_snapshot`, `customer_economic_id_snapshot`, `customer_address_snapshot` — and
one on `settings`, `payment_term_days`, `INTEGER NOT NULL DEFAULT 30`.

Each snapshot column's length **equals** its source column on `customers` rather than merely being
generous. The direction that matters is the narrow one: a snapshot column shorter than the record it
copies would make a customer with a long address impossible to issue an invoice to — the write
failing inside `issue()`, at the moment the invoice becomes a document, and only for the users whose
records are the fullest. `field_limits_test.dart` asserts the equality.

The mobile number is excluded, as D-051 said: contact detail rather than document content. An
invoice reprinted next year should reach the customer on the number they have now.

### Where the fallback lives, and why there is only one

`Invoice.party(live)` and `Invoice.partyName(liveName)` are the only two places the rule
`snapshot ?? live` is written. `InvoiceDetail.party` and `InvoiceListItem.customerName` are getters
over them, so **there is nowhere for a second answer to be written**: the two sites that construct an
`InvoiceListItem` supply the live name they already have and cannot apply — or forget — the rule.
`liveCustomerName` was renamed from `customerName` for exactly that reason. The field that carries
the live value and the field a row displays are now different names, so reaching for the wrong one
does not quietly compile into a plausible-looking screen.

### What existing invoices display: the live customer, and that is deliberate

**Every invoice issued before v3 has a null snapshot, and the migration writes nothing into it.**
Those invoices fall back to the live customer record — exactly the behaviour they had before this
change, unchanged.

This is a decision, not an omission. The alternative is to backfill the snapshot columns from the
customer rows as they stand on the day the user updates, and that would be **worse than doing
nothing**: it would look like a snapshot while being precisely the live join it replaces, frozen at
an arbitrary moment that corresponds to no document. A customer renamed last year would have last
year's invoices stamped with this year's name, and the record would then assert, permanently, that
this is what those documents said. Leaving the columns null keeps the honest statement — *this
invoice predates the snapshot; here is the customer as they are now* — and it stays recoverable if a
future phase ever finds real history to fill them from. Two tests pin it, one on the migration and
one on the read path.

The consequence to be plain about: for those invoices the defect D-051 names is still present and
cannot be fixed. There is no history to recover.

### `assertForeignKeysCanBeDisabled` is **not** called by this migration

D-049's guard checks exactly one property: that `PRAGMA foreign_keys = OFF` takes effect on this
connection. A table rebuild needs it because its step 6 is `DROP TABLE invoices`, which with foreign
keys on cascades through every line and every payment. This migration is six
`ALTER TABLE ... ADD COLUMN`s. It drops nothing, so it has no such precondition.

Calling the guard anyway was considered and rejected. It costs two pragmas and would have looked
diligent, and that is the objection: it would teach the next reader that the guard is a ritual
performed before migrations rather than a check on a property the migration depends on — which is how
a guard stops being read and starts being copied.

The claim is not left as prose. `customer_snapshot_migration_test.dart` runs the step **inside a
transaction**, with foreign keys on and children present — the exact condition that empties
`invoice_items` and `payments` under the v1 → v2 rebuild — and counts the rows afterwards. If anyone
later converts this step to a rebuild, that test fails on the children, which is the same news the
guard would have delivered.

### The defect the v1 ladder found

`Migrator.alterTable` builds the replacement table from the table **as it is currently declared**,
then copies every one of those columns across with an `INSERT ... SELECT`. The moment the v3 columns
were declared, the shipped v1 → v2 rebuild began failing with `no such column:
customer_name_snapshot` — on open, for every user who had not updated since the first release, and
for nobody else. It was found by writing the v1 → v3 test, not by reasoning about it.

Two consequences, both structural rather than remembered:

1. **The rebuild computes its `newColumns` from the database.** It asks the old table what columns it
   actually has and passes drift everything the current declaration adds. A hand-written list would
   be one the next person to add a column to `invoices` does not know exists, and the failure would
   again reach only the users furthest behind. Computed, the v1 → v2 step needs no edit for any
   future column.
2. **The v2 → v3 step adds each column only if absent.** A v1 database arrives with the snapshot
   columns already present (empty, which is right for a pre-v3 invoice) and a v2 database arrives
   without them; both must land on the same shape. The check is `PRAGMA table_info`, asked of the
   database rather than inferred from which steps ran.

**The ladder's shape test now targets `db.schemaVersion` rather than a literal.** The v2 shape
stopped being independently observable at v3 — `alterTable` rebuilds at the current declaration, so a
v1 database migrated "to v2" comes out carrying the v3 columns too. Pointing the test at the newest
version is also what makes it the test that catches the next column added without the rebuild being
told, so it must stay pointed there.

**The ladder's steps are now bounded above by `to` as well as below by `from`.** In the application
`to` is always `schemaVersion`, so no production path changes; it is what lets a test migrate to an
intermediate version and stop there. The DDL of the shipped step is untouched.

### The payment term

Folded into this migration rather than given its own, at the owner's direction: two migrations for
two columns is worse than one, and a hardcoded term is otherwise discovered by a user whose terms are
45 days. `kDefaultPaymentTermDays` moves to `data/models/app_settings.dart` and names the **seed
default**; the term in force is `AppSettings.paymentTermDays`, read from the row.

`defaultDueDate` now takes the term, and **a derived due date follows the term as well as the issue
date** — by (c)'s own argument, that a derived date is a statement about the term rather than a
commitment to a calendar day. A date the user chose is not moved by either.

The column carries a literal `30` rather than the constant, for the reason `withLength(max:)` does
(D-043): `drift_dev` reads the source expression, and what it makes of a named constant is not
something to find out from a shipped default. `field_limits_test.dart` asserts that the generated
default equals the constant.

**Still to do, recorded rather than assumed:** the settings screen is read-only, so nothing can yet
set a bad term. **When it becomes editable, the form must bound this field** — a negative term
produces an invoice due before it was issued. `AppSettings` deliberately does not clamp it, because a
clamp there would hide the bad value rather than refuse it.

**Alternatives considered.**

- *Backfill the snapshots from today's customer rows.* Rejected — see above. It manufactures history.
- *One migration per column set.* Rejected by the owner, and correctly: each migration is a risk, and
  two of them for two columns on the same open is two risks where one would do.
- *A tenth `lib/` scan asserting that no widget reads `invoice.customerSnapshot` directly.* Rejected:
  the fallback is a getter with no second path, so a scan would have nothing to catch. Each of the
  nine existing scans guards a rule that **can** be broken silently; this one cannot.

---

## D-053 — The desktop invoice form: what the width measurement decided

**Date:** 2026-08-27
**Status:** ACCEPTED — implemented in Phase 4 increment (d)
**Touches:** the project spec ("a sticky invoice summary panel" on desktop), D-037 (money columns)

### The requirement, and the number that would not fit it

§10 asks the desktop tier for a **sticky invoice summary panel** beside the form. It was built that
way first: a 320-pixel panel (`AppLayout.detailPanelWidth`) down one side, the fields and the lines
in the column beside it.

The lines table did not fit. `PageBody` caps content at 1240 logical pixels for readability; minus
the page margins that is 1144, minus the panel and its gutter it is **792** for the main column, and
minus the row padding and the row-actions column, **616 for four cells** — a description, a quantity
and **two money columns**. The amounts overflowed their cells by 58 logical pixels, measured by the
screen's own widget test.

Widening the money columns does not help: a money column is fixed-width by rule (below), and two of
them at `tablePriceWidth` are 464 of the 616. Narrowing them clips a figure at some invoice size,
which is the thing that may never happen on a document. **The panel and the table cannot both have
the width, at any window size**, because the content cap is what bounds them both.

### What was done instead, and why it still meets the requirement

The width goes to the table, and the summary **splits by purpose**:

- the **breakdown** — gross, discount, tax, rounding — sits beside the invoice-level fields at the
  top of the column, which are short and were wasting the width anyway, and scrolls with them;
- the **decision** — the grand total and the two actions — is pinned to the bottom of the window and
  does not scroll.

Detail scrolls; the figure being agreed to does not. That is the requirement met by its purpose
rather than by its silhouette, and it is what makes the desktop arrangement distinct from the
phone's single column and the tablet's two panes rather than a wider version of either.

The grand total therefore appears twice on this tier — once at the end of the breakdown, once in the
pinned bar. That is deliberate: a checkout total restated where the action is, not two answers to one
question, and the panel is the only place the arithmetic is shown.

### Two deviations in the lines table, corrected here

Composing (b)'s table into a narrower column surfaced both:

1. **The money columns were `flex`, not fixed.** A flexed money column is a column whose width
   depends on the window, so the amount that fits at one size clips at another — which is how the
   58-pixel overflow happened at all. They are `AppLayout.tablePriceWidth` now, like every other
   money column in the application.
2. **They were `alignEnd: true`.** D-037's RTL note says a money column is leading-aligned in a
   fixed-width column: `alignEnd` in RTL puts the figure against the wrong edge and breaks the
   vertical alignment of a column of them, which is the only reason to put money in a column.

Neither was visible while that table had a page to itself. This is the general case worth naming: a
widget tested only at its own full width has not been tested at the width it will be composed into.

### The three layouts, stated so they are not collapsed later

- **Mobile** — one column, one field per row, the lines reached by scrolling; the summary and both
  actions in a bar pinned to the bottom, so the figure being decided stays visible while the lines
  that change it are edited.
- **Tablet** — two panes: the document's fields on the leading side, its lines on the other, each
  scrolling independently. A tablet in portrait and a large phone in landscape both have width to
  spend and height to save.
- **Desktop** — fields and breakdown side by side, the table full width beneath, the decision pinned.

### Draft and issue are not two equal buttons

Saving a draft is reversible and costs nothing — no number, still editable (D-048). Issuing spends a
number **permanently**, even if the invoice is later cancelled (D-013), and ends editability: from
then on the document is corrected by cancellation, never by editing (§6). Neither consequence is
visible from a button.

So the draft is a tonal button with a one-line note about what it does *not* do, issue is the filled
one, and issue is behind a confirmation whose Persian copy names **both** consequences and restates
the amount. A confirmation that only asks "are you sure" is one people learn to dismiss; the test
asserts the copy contains both «شماره» and «ویرایش» so it cannot quietly become that.

`issue()` saves first and then allocates, so a confirmation placed after the save would leave a draft
behind on every declined "no" — permanent litter from a question the user answered no to. A test
asserts that declining writes nothing at all.

### Leaving the form asks, when there is something to lose

The editor is auto-disposed and nothing outside the screen watches it, so leaving discards the
invoice — right for something never saved, and stated as intended in (a). But back is one tap away on
every tier, and a typed invoice is the most expensive thing on this screen. A `PopScope` asks first,
and only when there is content: **a customer or a line, not the dates**, because a freshly opened
form already has both and a confirmation triggered on every exit is one nobody reads.

Not requested in the increment brief. Recorded as a judgement call: shipping a form whose back button
destroys work without asking is the kind of thing that is only ever found by losing work.

---

## D-054 — The invoice-level fields fold on a phone, and start folded

**Date:** 2026-08-27
**Status:** ACCEPTED — the owner's ruling on (d)'s device finding, implemented the same day

**The finding.** (d)'s device pass measured the buttons that add a line at **400 logical pixels down**
on a 393 × 804 phone: the invoice-level fields fill the first viewport, so the first thing a user
wants to do on an invoice form — say what is being billed — was below the fold, and so was every line
after the first.

**The owner's ruling: leave the field order alone, and fold.** Customer, then dates, then lines is how
the document reads, and a user picks the customer first anyway. So the fields collapse behind their
heading on the phone, and the two wider tiers — which have room for the fields and the lines at once
— do not fold at all, because a control that saves nothing is a control in the way.

**The heading states the customer, folded or not.** Everything else in that section has a working
default: the dates are filled, the discount and the tax and the notes are optional. The customer is
the one field a save cannot do without, and folding it away would leave «برای ذخیره، مشتری را انتخاب
کنید» under the disabled buttons pointing at something not on screen. Folded with no customer the
heading reads «مشتری انتخاب نشده»; with one, it reads the customer's name through the same provider
the field itself uses, so the two cannot disagree.

**Folded to begin with — measured on the device, as instructed, not decided in the abstract:**

| | folded | unfolded |
|---|---|---|
| add-line buttons | **586 px**, bottom at 611 | 400 px of scrolling away |
| pinned bar begins | 670 px | 670 px |
| fits without scrolling | **yes**, 59 px to spare | no |
| issue date field | in the heading's summary line | 245 px |

So folded, the primary action of the screen is on the first screen with room to spare, and the
customer's state is still visible. Unfolding is one tap on the whole heading row — not on the chevron
alone, which is a control users miss twice before finding.

**The number that surprised the measurement**, worth keeping: folded, the add-line buttons are still
586 px down, because the lines section renders its **designed empty state** — the icon, the title and
the explanation — above them. The fold saves 400 px of scrolling; the empty state costs about 250 of
what is left. If a later phase wants that space, the empty state is where it is, not the fields.

**The empty state stays, and that is the owner's ruling on the number above** (2026-08-27). An empty
lines section that said nothing would be worse than one that costs scroll — the 250 px buys the icon,
the title and the call to action on the screen where a user has nothing yet and needs to be told what
to do next. Recorded here rather than left as an observation so that a later phase hunting for that
space finds the decision beside the measurement: **the space went to the empty state deliberately,
and taking it back means deciding the empty state is worth less than 250 px of scroll.**

**The same shape as the customer detail screen's record card**, deliberately: two disclosure headers
that behaved differently would be worse than one shared idiom.

---

## D-055 — `grossTotal` is stored, and so are two per-line figures

**Date:** 2026-08-27
**Status:** ACCEPTED — settles D-047's open question. **Implementation is `schemaVersion = 4`, its
own reviewable increment**, on (a2)'s and (c2)'s precedent.
**Extends:** D-004 (snapshots), D-046 (one calculation path), D-047, §12 (the PDF contract)

D-047 left this open on purpose: *"the right answer depends on what the detail screen and the PDF
renderer actually need."* Phase 5 opens with both in view, so it is answerable now.

### What the document has to print, and what is stored

An Iranian invoice line prints, in this order: شرح · تعداد · مبلغ واحد · **مبلغ کل** · تخفیف ·
**مبلغ پس از تخفیف** · مالیات · جمع. Of those, `invoice_items` stores the title, the unit, the unit
price, the quantity, the effective discount, the resolved rate, the tax and the total — and for
"مبلغ کل" and the net it stores neither the gross **nor** the line's share of the invoice discount.
`line_net_rial` holds `netAfterInvoiceDiscount`, which is the net *after* a deduction the header also
prints. A document laying those out reconciles nowhere: the line's own gross is missing, and its net
is short by an amount that appears again in the header.

At the invoice level the same gap: the summary panel §12 hands the renderer starts from `grossTotal`
(D-047), and `invoices` has no column for it.

### The decision: store three figures

| Column | Table | Why |
|---|---|---|
| `gross_total_rial` | `invoices` | The first term of the printed summary. Without it the header cannot be assembled from stored data at all. |
| `line_gross_rial` | `invoice_items` | "مبلغ کل" per line, and the term every other line figure is measured from. |
| `allocated_invoice_discount_rial` | `invoice_items` | The line's share of the invoice discount, allocated by largest remainder (§4 step 4). Without it `line_net_rial` is unexplainable. |

With all three, every figure a document prints is **stored**, and every step between them is an
addition or a subtraction of stored figures:

```
line gross            (stored)
− line discount       (stored, effective — D-027)
− allocated share     (stored)
= line net            (stored)
+ line tax            (stored)
= line total          (stored)

Σ line gross = gross total (stored)   Σ allocated share = invoice discount (stored)
```

No multiplication, no rounding, no re-derivation, at any read site.

### Why not recompute, which would cost nothing to store

Gross *is* arithmetically recoverable — `unitPrice × quantityMilli ÷ 1000`, both operands stored — and
the allocated share follows from it by subtraction. Three reasons that is the wrong answer:

1. **It re-runs §4 step 1 outside the engine**, which is what D-046 exists to prevent. The guard scans
   for `calculateInvoice` calls and would not catch an open-coded multiply-and-round in a renderer,
   which makes it *more* dangerous, not less.
2. **Step 1 carries a rounding rule** — half-up at the Rial. A recomputed gross is a figure produced
   by today's rule applied to a document issued under an earlier one. That is exactly the failure
   D-004 exists to prevent, applied to arithmetic rather than to price.
3. **§12 requires the renderer to receive a fully-computed view model.** A view model assembled by
   computing anything is not that, and the PDF layer is the one place where the computation would be
   both invisible and permanent.

The general rule, already stated in D-047 and now applied in the other direction: *if a figure is
needed that the engine does not produce, extend the engine* — and if a figure is needed that the
**schema** does not keep, store it. A derived figure that a document prints is not derived data; it
is part of the document.

### What the migration must do about invoices that already exist

**Backfill, unlike D-052 — and the difference is worth stating, because the two look alike and are
not.** A party snapshot could not be backfilled because the migration cannot know what the customer
record said on the day the document was printed; the value it would have written would be a fabricated
history. These three figures are not history: they are **arithmetic over columns the row already
carries**, and the arithmetic is the one the invoice was issued under, because the rounding rule has
not changed since v1. `line_gross_rial = line_net_rial + discount_rial + allocated`, and the
allocation is recoverable per invoice from the stored invoice discount and the stored line nets.

Where a pre-v4 row cannot be reconciled to the Rial, the migration must **leave the columns null
rather than write a figure that does not add up**, and the read path must say so rather than print a
summary that fails its own invariant. The migration test is where that case gets its fixture.

`NOT NULL DEFAULT 0` is refused for exactly this reason: zero is a number a document would print, and
a gross of zero beside a total of 21,230,000 is worse than an admission that the figure is unknown.

### Consequences to carry into the increment

- `InvoiceRepository.create` and `updateDraft` write the three new figures from the `CalculatedInvoice`
  they already have. Nothing new is computed anywhere.
- `Invoice` gains `grossTotal`; `InvoiceItem` gains `gross` and `allocatedInvoiceDiscount`.
- `invoice_preview_matches_write_test.dart` extends to the three: the preview and the write must agree
  on them like every other figure.
- The **runtime invariant becomes checkable against storage**, not only against the engine's output.
  A stored invoice whose figures do not reconcile is a defect that should be found on read.

---

## D-056 — The v4 backfill checks the rule rather than assuming it, and the copy for what it cannot fill

**Date:** 2026-08-27
**Status:** ACCEPTED — implemented as Phase 5 increment (a2), `schemaVersion = 4`
**Implements:** D-055. **Extends:** D-046 (one calculation path), D-027, D-052, D-048

D-055 settled *what* to store and that pre-v4 rows are backfilled where they reconcile. Building it
raised three questions D-055 did not answer, and this records the answers.

### 1. The backfill runs the engine — it does not re-derive anything

The obvious implementation opens step 1 and the largest-remainder allocation into
`lib/data/database/`: multiply price by milli-quantity, round half-up, divide the invoice discount by
line net. **That is a second implementation of §4 in the data layer**, which is precisely what D-046's
scan exists to prevent, and it would sit where nobody would think to look for a money bug.

So `backfillInvoiceFigures` reconstructs an `InvoiceInput` from the row's own stored columns — unit
price, milli-quantity, effective line discount, effective invoice discount, resolved per-line tax rate
— and calls **`calculateInvoice`**. It is the **third sanctioned caller** in
`single_calculation_path_test.dart`, listed rather than exempted, and the test's doc comment says why
it is a different kind of caller from the other two.

**It is a comparison, not a producer.** Nothing is written unless the engine's output reproduces
*every figure already on the row*: each line's effective discount, net, tax and total, and the
invoice's subtotal, total discount, total tax, and grand total less its stored rounding adjustment.
The preview and the write are checked against each other by
`invoice_preview_matches_write_test.dart`; this one is checked against the database, which is why a
third caller needed no third comparison test.

**Which turns D-055's weakest assumption into a check.** D-055 argues the backfill is honest because
"the rounding rule has not changed since v1". The migration does not take that on trust: if the rule
had changed, the recomputation would not match, and the invoice would be **refused** — per invoice,
automatically, with no one having to remember the argument.

Four consequences worth stating:

- **The stored effective discount is fed back, never the entered percentage** (D-027). The amount is
  what the document printed; re-resolving the percentage would be a re-derivation. A line clamped when
  it was written stays clamped to the same number.
- **`defaultTaxRateBp: 0` and `taxRateBp: null` at the invoice level.** Every line carries its own
  resolved rate, so item-level resolution wins at §4 step 6 and neither is ever consulted. Passing the
  settings default would make what the migration accepts depend on a value the user can change after
  the fact.
- **`roundingUnitRial: 0`, and the stored adjustment added back.** Rounding moves the grand total and
  nothing else, so a user who has since changed the rounding unit does not thereby make their old
  invoices unreconcilable.
- **Any throw from the engine is a refusal, never an exception.** A migration that throws leaves the
  user with an application that will not start, over one invoice that was already unprintable.

### 2. The unit of refusal is the invoice, and lines are read alive and in order

**Per invoice, never per line.** An invoice with a gross on three lines and a null on the fourth is a
document that reconciles nowhere *and* admits nothing. One line out and the whole invoice keeps its
nulls; the invoices beside it are unaffected.

**Only alive lines take part.** `updateDraft` soft-deletes the lines it replaces (D-003), so a real
database holds superseded lines beside the live ones. They took no part in the stored totals, so
counting them would make every edited invoice unreconcilable — and they belong to no document, so they
get no figures of their own. They are read in `position` order because largest-remainder allocation
breaks ties toward the earlier line: a different read order is a different allocation.

**An invoice with no lines gets a real zero**, not a null. Nothing was billed, so the sum over no
lines is zero and the document can say so. This is the one place the two meanings — "unknown" and
"nothing" — have to be told apart, and the nullable column is what lets them be.

**Paged, 100 invoices at a time.** A migration that needs the whole table resident is one that fails
on the largest install rather than the smallest (§13). A test seeds 250 invoices, because a paging bug
is invisible on a fixture of three and shows up only as the invoices past the first page silently
keeping their nulls.

### 3. «ثبت‌نشده» — what a read path shows where a figure was never recorded

On «بدون شماره»'s principle (D-048): **not a blank cell**, which reads as data that failed to load,
and **not a zero**, which is a figure a document prints. Chosen over «نامشخص» because
«ثبت‌نشده» states a fact about the record — it was never written down — where «نامشخص» claims
uncertainty about the world. Short enough for a fixed-width table cell as well as the summary panel.

Beneath the panel, where there is room, a second string says the part «ثبت‌نشده» alone cannot:
«جمع سطرهای این فاکتور هنگام صدور ثبت نشده است. مبلغ قابل پرداخت آن درست و بدون تغییر است.» Without
it, an admission beside a payable amount reads as a fault in the invoice rather than a gap in what was
stored about it.

**The absence is carried in the type, not remembered by each read site.**
`InvoiceSummaryFigures` — the view model the detail screen and the future document renderer will both
be handed (§12) — has `Money? grossTotal` and two named constructors, `ofCalculation` for the live
preview (never null) and `ofStored` for a stored invoice (may be). `InvoiceTotalsSummary` now takes
that instead of `CalculatedInvoice`, so **the form and the detail screen render the same panel through
the same rows** and there is exactly one place the absence is worded. A read site that wanted to print
a zero would have to write the code to do it.

### 4. Alternatives rejected

- **`NOT NULL DEFAULT 0`.** Refused by D-055 and confirmed here by the fixture: a gross of zero beside
  a grand total of 21,230,000 is a document contradicting itself, where an admission is only one that
  is incomplete.
- **Backfilling per line, filling what can be filled.** Rejected above: a partly-filled invoice is
  worse than an empty one, because it looks complete.
- **Open-coding §4 in the migration.** Rejected in §1. It is faster to write and it is a second
  answer to the question the engine exists to answer once.
- **Making the backfill's counts a log line.** Rejected: §7 forbids logging figures, and the counts
  are the migration's own result. `InvoiceFiguresBackfillReport` returns them, and the tests assert on
  them.

---

## D-057 — A phase closes on a layout pass at all three tiers, with the amounts written into the check

**Date:** 2026-09-01
**Status:** ACCEPTED — a **process** change, binding on every remaining phase
**Prompted by:** the desktop summary panel overflow found in Phase 5 (a2) (known issue 18)
**Extends:** D-053 (a widget tested at its own width has not been tested at the width it is composed
into), and the project spec

### What went wrong, stated plainly

Phase 4 closed on (d)'s device pass, which reported **zero layout errors**, and the phase was accepted
on that report. The report was true and the conclusion drawn from it was not:

- the pass ran on the Redmi, so it exercised the **phone tier only**;
- the Windows check for that phase was *"the app starts and renders at the desktop tier"*;
- the amounts it exercised were whatever the flow happened to produce.

Under those three conditions a defect that fires on essentially **every realistic Iranian invoice** —
a grand total above one million Toman, on desktop — passed through a phase close and was found two
increments later, by a migration, by accident. The `dense` phone variant of the same widget never
overflows at any magnitude, which is exactly why the phone pass was silent.

**That is a gap in how a phase is verified, not a widget to fix.** The widget is fixed in (b); this
entry fixes the verification, because the next such defect will be in a different widget and the same
pass would miss it again.

### The rule

**A phase is not `COMPLETED` until its layout check has run at all three tiers — mobile, tablet and
desktop — over a written ladder of amounts.** Both halves are load-bearing:

**All three tiers.** A tier that is not exercised is not verified, and "the app starts" is not a
layout check — it is a check that the app starts. Where a real device is available for one tier, the
other two are covered by the widget-level tier check; where no device is available at all, the widget
check covers all three and the device pass is recorded as outstanding rather than assumed.

**The amounts are written into the check, never taken from whatever the dev database holds.** A
summary panel that fits at 100,000 Toman and breaks at 1,000,000 is a defect that hides behind small
test data, and the Windows dev database's twelve demo invoices are small test data. The ladder is
named once, in `test/support/money_magnitudes.dart`, so a check cannot quietly exercise a friendlier
one:

| Toman | Rial | Why this rung |
|---|---|---|
| 100,000 | 1,000,000 | A small invoice; the rung everything already passed |
| 1,000,000 | 10,000,000 | Where the summary panel first overflowed |
| 10,000,000 | 100,000,000 | An ordinary invoice for a workshop or a contractor |
| 100,000,000 | 1,000,000,000 | A large project invoice, and a plausible lifetime total for one customer |

The ladder is a **ceiling to design against**, not a prediction. `kMaxAmountRial` is far above its top
rung; the point is that every fixed-width money site states the magnitude it holds and is tested at
it, so the width is a decision somebody made rather than one the demo data made for them.

### What a layout check is

A widget test that renders the **real** composed screen at a tier's real width with a rung's amount in
it, and lets a `RenderFlex` overflow fail the test on its own. A measurement printed into a log is not
a check — the previous overflow was measurable for a whole increment before anybody measured it.

`test/core/widgets/money_layout_test.dart` is the first of these and is where a new fixed-width money
site is added to the sweep. A device pass, where one runs, is *additional* to it and not a substitute:
synthetic taps at the device's own metrics in Vazirmatn prove something the fallback test font cannot,
and the fallback test font — whose glyphs are much wider than Vazirmatn's — proves something a single
device cannot.

### Alternatives rejected

- **"Run the device pass on three devices."** There is one device. The rule would be aspirational,
  and an aspirational gate is a gate that gets waived at the moment it would have caught something.
- **A ladder per screen, chosen for each.** Every screen would end up with the ladder that passes.
  One ladder, named once, is what makes an exception visible as an exception.
- **Testing at `kMaxAmountRial`.** Sizing a column for 9×10¹⁵ Rial would give every money column the
  width of half a table for a figure no Iranian invoice will carry. The ladder's top rung is chosen to
  be large and real, which is the property that makes the width defensible.

---

## D-058 — The invoice detail screen: what fits, what is said, and where the party goes

**Date:** 2026-09-01
**Status:** ACCEPTED — implemented as Phase 5 increment (b)
**Implements:** D-055, D-056 (the first read site for what v4 stored) and D-052 (the party
distinction made visible). **Extends:** D-053, D-044, D-021, D-037. **Applies:** D-057.

### 1. Known issue 18 is fixed by taking a size off the figure, not by widening the panel

`AmountSize.large` needs **376** logical pixels at the top of the ladder. `detailPanelWidth` is 320,
which leaves 288 inside the card. So the grand total overflowed at **1,000,000 تومان by 30 pixels**,
at **10,000,000 by 58**, and at **100,000,000 by 86** — every invoice above the smallest rung.

Three fixes were available and two were refused:

- **Widen the panel to ~404.** Refused: the panel is narrow *by design* — it holds label-and-value
  pairs read down a column, and every pixel it gains comes off the table beside it, which is the trade
  D-053 already measured and refused once. Widening a shared token to accommodate one widget's font
  size is the tail wagging the dog.
- **Wrap the unit onto its own line at `large`.** Refused twice over. It still overflows at the top
  rung (308 against 288 for the digits alone), and it makes the panel change height as the user types
  — jumping the figure they are reading, which is the thing the stacked layout was introduced to stop.
- **Take the grand total to `AmountSize.medium`, on every tier.** Taken. It needs 276 and fits every
  rung with room. §10 asks the amount to be *the most salient element on its card*, which is a claim
  about the card: bold 19 against the 15 of the rows above it and the 14 of their labels is the most
  salient thing on this panel. `large` is for a surface with real width — the desktop sticky bar, a
  `StatTile` — and `dense` now controls spacing only, which is what it was for.

**The general rule, made checkable.** `AppLayout.amountWidthSmall / Medium / Large` are the measured
widths each size needs at the ladder's ceiling, and `money_layout_test.dart` fails if a figure outgrows
the number beside it. A container that cannot give an amount the width its size needs takes a **smaller
size**, never a clipped figure.

### 2. `tablePriceWidth` was wrong by exactly the padding it forgot

It read `232` with a comment claiming a ten-digit Toman figure fit. `AppTableRow` spends
`AppSpacing.md` of every column on the gap to the next one, so the amount only ever had 220 — and
100,000,000 تومان overflowed by 9 pixels. It is now `amountWidthSmall + AppSpacing.md`, **derived
rather than chosen**, so the column and the figure it holds cannot drift apart again. This is the
audit the owner asked for after known issue 18: every fixed-width money site checked at the same
magnitudes, not only the one that was found.

**The dashboard and customer tiles were checked and are fine**, for a reason worth writing down:
`StatTile` wraps its value in a `FittedBox`, so four `large` figures in 274-pixel tiles scale instead
of clipping. That is the one money site in the application where a figure may change size, and what
makes it acceptable is that a tile is a headline rather than a column to align down.

### 3. Eight document columns do not fit, so the table carries five and the rest are lines

The printed Iranian line is شرح · تعداد · مبلغ واحد · مبلغ کل · تخفیف · مبلغ پس از تخفیف · مالیات ·
جمع — **six money columns**. At `tablePriceWidth` that is 1464 logical pixels before the description
gets any, against the **1144** a desktop content column has at `maxContentWidth`. Eight columns do not
fit at any window size.

Same shape of answer as D-053: state the constraint rather than squeeze the layout. The three figures
that vary independently keep columns — قیمت واحد, مبلغ کل, جمع سطر — and the deductions between them
run under the description as labelled detail lines, which is the shape the editor's table and every
card on the narrow tiers already use. **Every stored figure is on the row**; what changes is whether it
is a column or a line. The eight-column layout is the renderer's problem (§12), on a page rather than
in a viewport, and it now has every figure it needs.

**Nothing on the screen computes.** Not `unitPrice × quantity`, not the sum of two deductions. A read
site that multiplied would be applying *today's* rounding rule to *yesterday's* document, and it would
do it where `single_calculation_path_test.dart` cannot see it, because it never calls the engine.

### 4. The party notice: four cases, and one of them is silence

`InvoicePartyProvenance` decides what the screen owes the user about the name it is showing:

| Case | What is said |
|---|---|
| Snapshot still matches the record | **Nothing** |
| Snapshot differs from the record | The document is right, and here is what the record says now |
| Draft | It follows the record on purpose, and freezes at issue |
| Issued before v3, no snapshot | The party was never recorded; the live record is standing in |

**The silent case is the load-bearing one.** A panel that explained itself on every invoice would train
the user to skip the explanation on the one invoice where it matters. The comparison is over the whole
snapshot rather than the name, because D-052 chose those fields precisely as the ones a correction
touches — a corrected کد ملی moves a document as much as a rename does, and it is the field an auditor
reconciles against.

**Soft deletion is orthogonal and stacks.** A customer can be both renamed and deleted, and the two are
separately actionable: one is about which name is right, the other about why they are not in the list.
That needed a new fact on the aggregate — `InvoiceDetail.customerIsDeleted` — because the customer
behind an invoice is read **soft-delete-exempt** (§6 promises it is never hard-deleted), so
`detail.customer` is a live record that may no longer be in the customer list. `Customer` itself
deliberately carries no delete state: everywhere else in the application a deleted customer simply is
not returned, and a flag on the model would invite a screen to check what the query already answered.

### 5. The party goes **below** the lines on a narrow screen

Written the other way round first, and the phone-height test found it: a party card has no upper bound
on its height — five fields, up to three notices, a contact block — so above the lines it pushed the
first line off a 400 × 800 phone entirely. That is D-044's finding about the customer record card,
rediscovered on the one screen whose purpose is to show the lines. Order is now summary → lines →
party → dates → notes, which is also the order the desktop tier reads in.

Every other test on that screen uses a tall viewport, so content assertions are about the page rather
than about scroll position; **one test keeps the real phone height** and asserts the first line is
reachable without scrolling. Without it that ordering could regress silently.

### 6. Read-only, deliberately

Recording a payment is (c) and cancelling is (d). There is no control here that pretends to do either:
an affordance leading nowhere is worse than its absence (D-021), and that applies to a button on a page
as much as to an item in a nav rail. What the screen does show is `amountPaid` and `amountDue` — reads,
not writes — with the overpayment called out, because `amountDue` clamps at zero (an invoice cannot owe
money) and an overpayment is therefore invisible in the figure while usually being a data-entry error.

### 7. `/invoices/:id` and the row, in one change

D-021 read the other way: the rows were inert and the route unregistered until the screen existed, so
the affordance and its destination arrive together. **The two tests asserting the absence were
inverted, not deleted** — one on the invoice list, one on the customer detail screen. Deleting them
would have left the tap untested at exactly the moment it started doing something.

### 8. `RecordField` was promoted out of the customer screen

Label above value, «ثبت نشده» where the value is empty, an identifier style for a کد ملی. The invoice
detail screen needs precisely that for the party, and a second copy would have been the third way this
application renders a missing field. The stacked layout came with it, along with the reason it exists:
a Persian label and a left-to-right identifier on one row put two directions in one line and make the
value's position depend on the label's length.

---

## D-059 — The invoice discount is allocated exactly, because the wide value was never a figure

**Date:** 2026-09-01
**Status:** ACCEPTED — implemented before Phase 5 increment (c), at the owner's direction
**Fixes:** known issue 19. **Extends:** D-002 (the 2⁵³ parity guarantee), §4 step 4.
**Found by:** D-057, one increment after D-057 was written.

### What was wrong

`allocateByLargestRemainder` computed each line's share as
`checkedMultiply(amount, weights[i]) ~/ totalWeight`, and recovered the remainder as
`exact − share × totalWeight`. Both of those products are **an invoice discount times a line's net** —
two figures that each scale with the invoice total, so the product is **quadratic in it**.

`checkedMultiply` rejects a product past 2⁵³, which put the ceiling at:

| invoice-level discount | largest invoice that could be entered |
|---|---|
| 1% | ≈ 95,000,000 تومان |
| 5% | ≈ 42,000,000 تومان |
| 10% | ≈ 30,000,000 تومان |
| 25% | ≈ 19,000,000 تومان |

A 30-million-Toman invoice with a 10% discount is ordinary Iranian business, not an edge case.

**This is the only place in §4 where two amounts are multiplied together.** Every other step multiplies
an amount by a *small factor* — a milli-quantity, a basis-point rate, a rounding unit — so its product
is linear in the invoice and stays inside 2⁵³ until the amount itself is near `kMaxAmountRial`. That is
why one site needed changing and the rest did not, and it is the test to apply to any future step: if
both operands scale with the invoice, the intermediate has to be exact.

### The guard was working, and that matters as much as the defect

`InvoiceEditorState`'s constructor runs the engine, so the throw landed on the **preview**, as the user
typed — `InvoiceEditor.build` failed and the screen rendered `AsyncErrorView` in place of the form.
That reads as the worst possible place, and it is in fact the right one: **the invoice was blocked, and
no wrong total ever reached a document.** Had `checkedMultiply` not been there, the product would have
lost its low digits on the Web and quietly produced an allocation that did not sum to the discount —
an invoice whose lines disagree with its header, which is the failure §4 exists to prevent.

So the fix removes the **intermediate**, not the guard. D-002's parity guarantee is untouched:
`Money.rial` still refuses an amount past `kMaxAmountRial`, `checkedMultiply` still refuses a wide
product everywhere it is still used, and `mulDivFloor` refuses any operand or result that could not
survive a round trip through a JS number. The VM and the Web still reject identically. What changed is
that a value nobody ever sees is no longer required to be a figure.

### The fix

`mulDivFloor(a, b, c)` in `core/money/rounding.dart` returns `(quotient, remainder)` for
`a × b ÷ c` floored, computing the product in **`BigInt`**. The allocation calls it once per line and
takes both results, which also retires the second wide product — `exact − share × totalWeight` — since
the remainder now comes back from the division that produced it.

**`BigInt` is compatible with §4, and the distinction is worth stating because a reader will stop on
it.** §4 forbids `double` and `num` in the money path because they *lose digits*. `BigInt` is an exact
integer type that loses none; it is `dart:core` on every target, so the VM and the Web run the same
arithmetic; and nothing stores, returns or compares one — it exists for the width of a single
multiply-and-divide and both results are checked back into the exactly-representable range before they
leave. Every value that crosses the boundary of this function is an `int`, as before.

Cost: one `BigInt` multiply and divide per line, on a code path that runs per keystroke in the preview.
For any invoice a person will type this is microseconds, and correctness at every magnitude is not
tradeable against it.

### What did not change, and is pinned

**The allocation is unchanged as arithmetic.** Same proportions, same floor, same largest-remainder
distribution, same tie-break toward the earlier line — the property that makes two devices produce
identical output for the same invoice, which is why the method was written this way and what a sync
phase depends on. The claim that only the *range* moved is asserted rather than asserted-in-a-comment:
`discount_allocation_test.dart` runs a **plain-`int` reference implementation of the old algorithm** on
every input where plain `int` is still exact, and requires the new implementation to match it share for
share. `rounding_test.dart` does the same for `mulDivFloor` itself.

**The regression is pinned at the magnitudes it broke at**, over the D-057 ladder rather than over
numbers chosen here: every rung of `kMoneyStressToman` × 1%, 5%, 10% and 25%, in the allocation, in the
whole engine through `calculateInvoice`, and in `InvoiceEditorState` — the last of these because the
preview is where a user actually met it. A separate test asserts the sweep **still reaches** a product
the old code refused, so if the ladder is ever lowered below the old boundary, that is noticed rather
than silently turning the group into decoration. And the boundary itself has its own case: 94906265 and
94906266, the last invoice the old code could allocate and the first it could not, derived from 2⁵³
rather than picked.

**Verified to bite**, the way D-049's guard was: the old implementation was put back and the new tests
run against it. It fails exactly four — the top rung at 5%, 10% and 25%, and the boundary case — while
the plain-`int` equivalence tests stay green, which is the evidence that they are checking agreement
rather than accidentally catching the bug. Restored afterwards. The device pass at the top rung, which
had needed a special case to avoid the throw, now issues and renders that invoice with its discount.

### How it was found, which is the part worth keeping

**It surfaced from writing the D-057 device fixture at the ladder's top rung — one increment after
D-057 was written.** Nothing in the codebase pointed at it; no test failed; the invoice list, the
editor and the dashboard had run for two phases without anybody meeting it, because the demo data never
went above a few million Toman. It appeared because a rule was written down that says the amounts must
be named in the check rather than taken from whatever the dev database holds, and then that rule was
followed once.

That is D-057 paying for itself inside a single increment, and it is the argument for the rule that no
amount of reasoning about the rule could have produced.

### Alternatives rejected

- **State the ceiling as a business limit and refuse politely**, surfacing it as data the way D-027's
  clamps are. Refused by the owner, and the reasoning is worth keeping: the 2⁵³ bound exists to keep the
  VM and the Web rejecting identically at `kMaxAmountRial`, which is a real bound on a real figure. This
  was a bound on an **intermediate the user never sees**, at a magnitude far below it. Stating it as a
  limit would be inventing a business rule out of an implementation detail — and D-027 is the wrong
  precedent, because D-027's clamps describe *something the user actually did*.
- **Reduce by `gcd(amount, totalWeight)` first.** Helps enormously on round numbers — a 10% discount
  reduces to 1/10 — and not at all on coprime ones, which are exactly what a discount entered as an
  absolute Rial amount produces. An optimisation that fixes the common case and leaves the defect in
  place is worse than the defect, because it makes it rare enough to reach a user rather than a test.
- **Hand-rolled 128-bit arithmetic over 26-bit limbs.** Avoids `BigInt` and stays in `int`. Rejected:
  it is forty lines of subtle shifting in the one function in this application where a silent error
  becomes a wrong invoice total, to save microseconds on a path that runs a handful of times per
  keystroke. The Euclidean reduction that looks like the cheap alternative does not terminate usefully
  here either — it bottoms out at a product of two values each below `totalWeight`, which is precisely
  the case that overflows.
- **Widen only the remainder and keep `checkedMultiply` for the share.** The two come from the same
  division; splitting them would leave the second product to overflow at the same magnitude and would
  put two answers where there is one question.

---

## D-060 — Payments: where the guard lives, what the copy admits, and what moved off the phone's first screen

**Date:** 2026-09-01
**Status:** ACCEPTED — implemented as Phase 5 increment (c)
**Extends:** §6 (derived status recomputed on every payment write), D-013, D-021, D-044, D-057, D-058

### 1. The write side already existed, so (c) is a guard, a screen and a confirmation

`PaymentRepository.record` and `softDelete` landed in Phase 4 (d), both recomputing the derived status
inside their own transaction. What (c) adds is the way in, and three things worth recording.

### 2. The rule is the repository's; the screen explains it and does not enforce it

`Invoice.acceptsPayments` is false for a draft and for a cancelled invoice, and the repository throws
`PaymentNotAccepted` for both. The screen **hides the control and says why in Persian** — «برای ثبت
پرداخت، ابتدا فاکتور را صادر کنید…» and «این فاکتور باطل شده است…» — rather than merely omitting it.
A user who arrives at a draft and finds nothing has to guess what changed.

But hiding a control is not a guard. A deep link, a second window and a future sync path never pass
through this screen, so the tests for the refusal call the **repository directly**, on the precedent
Phase 4 (c) set for `updateDraft` — and each one asserts what the refusal *left behind*, not only that
it threw: the status unmoved, the total paid unmoved, no stray row. **A guard that throws after writing
half the change is worse than no guard.** The harder case is deliberately included: a cancelled invoice
that already has a payment on it, where a write-then-check implementation would show up as a changed
total rather than only as an orphan.

Two refusals were missing entirely and are now covered: deleting a payment that does not exist, and
deleting the same payment twice — the double-tap, and the stale second window.

### 3. Deleting says what it does, including the part that is not about money

Removing a payment moves the derived status back by the same rule that moved it forward, in the same
transaction (§6). So the confirmation names the amount being removed and, **only where it is true**,
adds that this takes the invoice out of «پرداخت شده». A warning shown on every deletion is one nobody
reads on the occasion that matters.

The screen decides whether to show that sentence from the row's own numbers, before opening the dialog.
That is **not a second derivation of the status** — it is a claim about what the user is about to
cause, and the status itself is still recomputed by the repository inside the delete. The badge at the
top of the page changes because `invoiceDetailProvider` is a live query and the row changed, never
because the payments card told it to; a display-time determination is how a badge comes to contradict
the payments listed underneath it.

### 4. An overpayment is warned about before the write, never refused

The repository accepts one, and `InvoiceDetail.amountDue` clamps at zero because an invoice cannot owe
a negative amount — so an overpayment is invisible in the balance by design. It is also usually a
data-entry error. The sheet says so **as the amount is typed**, which is D-027's principle (surface a
clamp, do not absorb it) applied to an input rather than to a calculation, and the detail screen keeps
saying it afterwards.

**The sheet computes nothing.** `amountDue` arrives already worked out by the aggregate and is used for
two things: the «مانده» line under the amount field, and the button that fills it. A balance worked out
here would be a second answer to a question the card above has already answered, and the two would
eventually disagree in favour of whichever the user happened to be looking at.

### 5. The payments card went below the lines, and the phone's action went to the floating slot

**Measured, not argued.** On a 400 × 800 phone the payments card costs **182 logical pixels with
nothing in it** — a section header, one sentence and a button — and placed between the summary and the
lines it pushed the first line off the bottom, exactly as the party card had in (b). That is D-044's
finding about the customer record card, met for the third time: *a card whose height has no upper bound
does not belong above the thing the page exists to show.*

So the order on the narrow tiers is **summary → lines → payments → party → dates → notes**, which is
also the order the desktop tier reads in — the document in the main column, and who, when and what has
been paid beside it.

That leaves the record action at the bottom of a long page on a phone, so on mobile it moves to
`PageBody.floatingAction` and **the inline button in the card is omitted there**. This is the invoice
list's own rule, applied again: its empty state drops its button on mobile because the floating one is
already on screen, and two controls saying the same thing is one too many. The two are never visible
together, and each tier offers the action exactly once.

**The test that caught it is the one (b) wrote for exactly this**, at the real phone height while every
other test on that screen uses a tall viewport. It has now earned its keep twice, on two different
cards, which is the argument for keeping a deliberately awkward test.

### 6. Smaller decisions

- **`paymentMethodLabel` in `domain/`**, on `invoiceStatusLabel`'s precedent: the enum is storage, the
  label is presentation, and one mapping is what stops the sheet and the list disagreeing about what
  `cardTransfer` is called. «کارت به کارت» is what people call it; «انتقال بانکی» is not.
- **A `Wrap` of `ChoiceChip`s rather than a `SegmentedButton`** for the method. Five Persian labels of
  unequal length do not fit across a phone in one row; wrapping costs a line and cannot clip.
- **The sheet's submit says «ذخیره»**, as the invoice line sheet's does, rather than repeating the
  sheet's own title. A button and the heading above it saying the same three words reads as two
  controls to anyone scanning for one.
- **`PaymentLimits.note` is 500**, matching the column and deliberately shorter than
  `InvoiceLimits.notes`. An invoice's note is a clause on a document; a payment's note is an identifier
  for a transaction, and a field that invites an essay against a single receipt is one nobody will scan
  later.
- **The controller returns `bool`, not a result.** The screen reads the invoice from the live detail
  query, never from the write's return value, so there is nothing to thread back — and a failed write
  becomes a Persian line rather than an exception in front of a user (§7), logged through the wrapper
  with no amount, name or identifier in it.

### 7. Verified on the target as well as at every tier

The widget sweep covers all three tiers over D-057's ladder. The device pass now goes further than
rendering: on Windows it opens the **real** sheet, fills the balance through the sheet's own control,
picks a method, writes through the real repository into the real encrypted database, and reads the
status back **from the database rather than from the screen** — because the screen believing it is not
the claim. Then it deletes the payment, confirms the status warning appears exactly where it should,
and reads the status back again.

```
payment: 2117500 rial recorded, status paid
deletion : status unpaid
layout errors : 0
```

**The Android phone tier is still outstanding** and is carried forward to (f), per D-057: no device was
attached for either (b) or (c).

---

## D-061 — Cancellation keeps the money it was paid, and says so three times

**Date:** 2026-09-01
**Status:** ACCEPTED — implemented as Phase 5 increment (d)
**Extends:** §6 (cancellation is the correction path; `cancelled` is set by hand and never derived),
D-013, D-021, D-027, D-044, D-057, D-060
**Resolves:** known issue 20

### 1. The ruling: a cancelled invoice keeps its payments

`_recomputeStatus` returns early for a cancelled invoice, so cancelling has always left the payments
on record and the total paid where it was. **That is correct, and it is now a decision rather than an
early return nobody chose.** The money did change hands. A cancellation is a statement about the
*claim* — this document is no longer one — and not a statement about the *cash*. Deleting the
payments with the invoice would falsify the financial record in the one direction a financial record
must never move: it would make received money disappear.

What was wrong was that it was **implicit**. A user cancelling a part-paid invoice was told nothing,
and then met a void document showing «پرداخت‌شده: ۵۰۰٬۰۰۰ تومان» with no explanation — which reads as
a bug in the software rather than as a fact about the record. So the rule is now said in three places,
and pinned in tests so it cannot decay:

- **Before the commitment**, in the confirmation: the number stays spent, the record is kept, editing
  is still not the way back — and, where the invoice actually carries payments, that they are neither
  erased nor refunded.
- **On the page afterwards**: the payments card says the payments below it were really received, and
  the paid/due card says the remaining balance is not a claim on anyone any more.
- **In `invoice_repository.dart`, `drift_payment_repository.dart` and this entry**, so the next reader
  of that early return finds a ruling instead of an accident.

### 2. What the two payment operations do on a cancelled invoice, decided rather than inherited

**Recording is refused** (`PaymentNotAccepted`, unchanged from (c)) — and the copy now names the way
forward instead of only stating the refusal. A cancelled invoice is not a claim on anyone, so money
genuinely received belongs on the invoice that replaced it, which is the correction path §6 already
prescribes. «… اگر مبلغی دریافت کرده‌اید، آن را روی فاکتور جایگزین ثبت کنید.» A refusal that names no
alternative leaves the user stuck with real money and nowhere to put it.

**Deleting stays allowed**, and stays allowed deliberately. A mis-entered receipt is a fault in the
money record, and the money record must be correctable whether or not the document still stands; the
early return means it does not resurrect the invoice into `unpaid`. But the ordinary confirmation was
**false** there: «مانده به همان اندازه افزایش می‌یابد» describes money becoming owed again, and
nothing is owed on a void document. So a cancelled invoice gets its own sentence — the invoice stays
cancelled, and only the payment record is being corrected. This is D-060's "only where it is true"
applied to a *replacement* rather than to an addition.

### 3. Only an issued invoice may be cancelled, and the rule is the repository's

`cancel` accepted any status. It now throws `InvoiceNotCancellable` for a draft and for an invoice
already cancelled, checked **inside the same transaction as the write** — (c)'s precedent, because a
guard that refuses after writing half the change is worse than no guard.

- **A draft is withdrawn by deleting it** (`softDeleteDraft`). It has no number, nobody has seen it,
  and there is nothing to correct; marking it «باطل شده» would void a document that never existed and
  would put two ways out of one state in front of the user. The screen offers neither for a draft
  rather than offering the wrong one.
- **An invoice already cancelled** has nothing left to cancel. The write would change no fact while
  bumping `updated_at` — a sync-pending row for a change that never happened.

`InvoiceNotCancellable` is a **separate type** from `InvoiceNotEditable` rather than a reuse. They are
opposite refusals: one guards the edit path against issued invoices, the other guards the correction
path against invoices that were never issued. Collapsed into one exception the UI could not say which
of two contradictory things the user should do instead.

Both refusals are tested at the repository, in every status, asserting what the refusal *left behind*:
the draft still a draft, still editable, still numberless, with `updatedAt` unmoved; the cancelled
invoice with `updatedAt` unmoved. And the ruling itself is pinned — cancel a part-paid invoice, then
read the payments, the aggregate's `amountPaid` and `totalPaidRial` back out.

### 4. The confirmation copy is pinned, on the issue confirmation's precedent

`invoice_editor_screen_test.dart` asserts that the issue confirmation names **both** of its
irreversible consequences, so it cannot decay into «مطمئن هستید؟». The cancellation confirmation gets
the same treatment: `invoiceCancelBody` must contain «حذف نمی‌شود», «شماره» and «ویرایش», and
`invoiceCancelPaymentsNote` must contain both «حذف نمی‌شود» and «بازگردانده نمی‌شود» — because the two
halves are separate claims (the payment is not erased *from the record*, and it is not returned *to
the customer*), and a copy edit that dropped either would leave the sentence looking fine.

**The payments sentence is conditional**, on D-060's rule: a warning printed on every cancellation is
one nobody reads on the cancellation where it matters. An invoice with no payments has nothing to say
about payments, and saying it anyway is how the sentence becomes furniture.

**The amount is named rather than described.** "Payments are kept" is a policy; «۵٬۰۰۰٬۰۰۰ تومان …
بازگردانده نمی‌شود» is the figure the user is about to leave sitting on a void document, which is the
thing they would otherwise query afterwards.

### 5. «مانده» is explained on a cancelled invoice, not hidden

The remaining balance is a real figure — it is what was never paid — and it is still shown. On a void
document it would otherwise read as money the customer still owes, which is the one thing a
cancellation means it is not. Removing the row instead was considered and refused: it would leave the
page silently missing a number that every other invoice shows, and a figure that disappears by status
is harder to trust than a figure that explains itself.

### 6. The action went in the title row, because §10 now has a rule about that

Every obvious home for a cancel control is a block of content — an actions card at the foot, a button
under the summary, a bar above the lines — and all of them add height. The payments card in (c) was
the **third** time a card added to this family of screens pushed the first invoice line off a
400 × 800 phone, after the customer record card (D-044) and the party card in (b).

That finding is now a rule in the project spec with all three instances named, so the fourth is
prevented rather than caught, and **this increment is the first thing the rule applied to**:
cancellation is a `PopupMenuButton` in the page's title row, which costs no vertical space at any
tier and is where the customer and product screens already put exactly this pair of actions.

A menu of one item is deliberate. A bare icon would put an irreversible, destructive action behind a
glyph nobody can name; a menu item is a Persian phrase read before anything is committed, and it is
the slot a draft's deletion and the Phase 7 export will join.

**The page does not navigate away afterwards**, unlike the customer screen's delete. A cancelled
invoice is still a document, still numbered, still the thing the user was looking at — and the state
they have just created is precisely the one that needs explaining.

### 7. Verified at every tier and on the target

The confirmation prints an amount, and a dialog is the narrowest surface in the app that does, so it
goes through D-057's ladder: three tiers × four magnitudes, with the payments note rendered at each.
The new sentences land in the summary card, which is **above** the lines on a phone, so a cancelled
invoice carrying payments also goes through the 400 × 800 fold test that caught (b) and (c).

The device pass now writes a cancellation as well as a payment. On Windows, at the desktop tier, in
Vazirmatn: the real menu, the real confirmation with money on the invoice, the write through the real
repository into the real encrypted database, and every status read back **from the database** rather
than from the screen.

```
payment: 2117500 rial recorded, status paid
deletion: status unpaid
cancellation: status cancelled, 705833 rial still on record, number INV-1405-0001
correction: status cancelled          (payment deleted off the cancelled invoice)
layout errors : 0
```

**The Android phone tier is still outstanding** for (b), (c) and now (d): no device has been attached
in any of the three sessions. Carried to (f), per D-057 and the owner's standing instruction that the
phase does not close without it.

---

## D-062 — A check must reproduce the conditions the user is in: the tier, and the keyboard

**Date:** 2026-09-01
**Status:** ACCEPTED — arising from the Phase 5 phone-tier pass for (b), (c) and (d)
**Extends:** D-057, D-053, D-044, §10's unbounded-card rule
**Resolves:** known issue 21

### 1. What the phone pass actually found

Three sessions of device debt were cleared in one run, and **the product had no defects on the phone
tier**: 0 layout errors at all four rungs of the ladder, every (b), (c) and (d) behaviour correct,
statuses read back from the encrypted database. What failed twice was **the check**.

`integration_test/invoice_detail_device_test.dart` had only ever run on Windows, and it had quietly
encoded the desktop layout as if it were *the* layout:

- **It asserted on the party card immediately after pumping.** On the desktop tier the party sits in
  a side panel visible in the first frame. On the narrow tiers it is the **fourth** block —
  summary → lines → payments → party — because a card whose height has no upper bound does not go
  above the thing the page exists to show (§10, D-044). A `ListView` child past its cache extent is
  **not laid out and not in the tree**, so the finder reported absence, not invisibility, and
  `ensureVisible` could not have helped: it needs an element that already exists.
- **It tapped «ذخیره» in the payment sheet where a desktop puts it.** On a real phone the amount
  field's `autofocus: true` raises the soft keyboard before the user does anything, and the tap
  landed on the sheet's Material instead of the button.

Both are the D-057 lesson **one level up**. D-057 says a phase closes on a layout check run at all
three tiers, because a check run at one tier is evidence about one tier. The device test is that
check — and it was itself single-tier, which is exactly the shape of defect it exists to catch.

### 2. The rule

**An integration test reaches what it asserts; it does not assume where it is.** The three tiers are
genuinely different layouts (§10), not one layout at three widths, so a position that holds on one is
a coincidence on the others. `reach(tester, finder)` scrolls the page until the finder matches,
rewinding each list it searched so one assertion does not silently decide where the next one starts.

This is not the same as `ensureVisible`, and the difference is the point: `ensureVisible` scrolls to an
element **already in the tree** and throws when there is none. Off-screen content in a lazy list is not
in the tree at all.

### 3. The keyboard is a tier difference too, and it is now measured

Nothing in the widget sweep has a soft keyboard. On the Redmi, measured rather than estimated:

```
logical size: 392.7 x 803.6
keyboard: 254.9        (32% of the viewport)
«ذخیره» centre: 618.6        visible area ends at 548.7
after scroll: 500.7
```

So the payment sheet's primary action sits about **70 logical pixels below the fold** the moment the
sheet opens. It is *reachable* — the sheet is a `SingleChildScrollView` under `isScrollControlled` with
`viewInsets` padding, which is what those are for — and it is **not** an overflow: the run reported 0
layout errors. But a user has to scroll a sheet to save, and nothing on the desktop tier would ever
show that.

Recorded as **known issue 21** rather than fixed here. The fix is a design decision with a precedent
already in this project — D-053 split the invoice summary by purpose, letting the breakdown scroll and
pinning the total with its actions — and applying it to the sheet is the owner's call, not a
correction to smuggle into a device pass.

### 4. What did not recur

Known issue 10 (MIUI blocking `flutter test`'s install on a fresh install) **did not happen**: the APK
installed first try, three times. Known issue 10b (the device out of internal storage) is cleared —
4.9 GB free, and the D-020 and startup proofs that it blocked in the (a2) session both pass now. Both
entries stay in the table as history, since neither is fixed so much as currently absent.

*(Amended the same day, after known issue 21 was fixed: known issue 10 **did** recur on the fourth
install of the session — `INSTALL_FAILED_USER_RESTRICTED` — and the documented remedy worked
unchanged: build the debug APK, `adb install -r` it by hand once, then `flutter test -d` installs on
its own again. The entry stays.)*

### 5. The keyboard rule, and what the survey found

Known issue 21 is fixed rather than carried, at the owner's direction, and the rule generalised: **a
sheet's primary action is pinned above the keyboard; its fields are what scroll.** That is D-053
applied to sheets — the thing being agreed to must not scroll away from the person agreeing to it.

**The survey mattered more than the fix.** Four sheets and two form screens use text fields:

| Surface | Shape before | Verdict |
|---|---|---|
| `FormScaffold` (customer, product forms) | fixed action bar | **already correct** — and its doc comment has said *why* since Phase 2: "with the keyboard up it is off screen entirely" |
| invoice line editor sheet | header, `Expanded` scroll, pinned `SafeArea` action | **already correct**, arrived at independently |
| payment editor sheet | one `SingleChildScrollView`, action inside it | **the defect** |
| customer picker, product picker | pinned title + search, `Expanded` list, **no commit button** | **does not apply, and is not forced** — a picker commits by tapping a row, so its list *is* its action; adding a pinned button would duplicate the list |

So the rule was already stated in one place and independently rediscovered in a second, and the third
surface still got it wrong. **A rule stated in a file is not a rule.** The shape is now a primitive,
`core/widgets/editor_sheet.dart`, and a sheet built through it does not get to say where its action
goes. The line editor moved onto it unchanged — not because it was broken, but because leaving one
correct implementation outside the primitive is how the next sheet learns the wrong pattern from the
nearest example.

`EditorSheet` caps its height rather than fixing it: a three-field sheet hugs its content on a desktop
window instead of standing 90% tall over a gap, and a ten-field one stops growing and scrolls. The
`viewInsets` padding sits **inside** the cap, so the keyboard takes the fields' room and the action
lands exactly on top of it.

### 6. Why 892 tests could not have caught it, which is the more useful finding

`pumpScreen`, the shared widget-test harness, installs its own `MediaQueryData(size:, disableAnimations:)`
— so **every screen test this project has ever run had `viewInsets: EdgeInsets.zero`.** No test could
raise a keyboard; the capability did not exist. That is not a bug in any one test, it is the harness
quietly guaranteeing that a whole class of defect is invisible.

The harness now takes `viewInsets`, defaulting to zero so nothing else changes, and
`test/core/widgets/sheet_keyboard_test.dart` asserts every sheet that can raise a keyboard with the
**measured** inset — 255 logical pixels, what a Redmi Note 8 Pro actually takes, not a round number
chosen to pass. **Verified to bite**: restoring the (c) shape puts the action at 591 against a limit
of 545 and fails both sheet assertions.

### 7. And the device check now reproduces the keyboard

A widget test with a synthetic inset is a fast guard, not proof. `integration_test/device_assertions.dart`
adds two shared helpers:

- **`raiseKeyboard`** taps the field and polls for the inset. `enterText` injects straight into the
  engine and raises nothing, so a device test built on it exercises a phone that has no keyboard —
  which is exactly what the form pass had been doing.
- **`expectActionAboveKeyboard`** asserts the action is inside `height - viewInsets.bottom`, and **on
  Android additionally requires the inset to be non-zero**. An assertion made against a keyboard that
  never came up is vacuous, and a vacuous check reporting success is worse than no check. On a desktop
  target it degrades to "the action is on screen" — which is why D-062 requires the phone run and does
  not accept the Windows one in its place.

The detail pass no longer calls `ensureVisible` before tapping «ذخیره», deliberately: scrolling to the
button first would hide a regression of the very defect being guarded.

**On the Redmi, after the fix:**

```
payment sheet: keyboard 254.9 of 803.6, action bottom 532.7, limit 548.7
line editor sheet: keyboard 254.9 of 803.6, action bottom 532.7, limit 548.7
layout errors: 0
```

Before it, the payment sheet's «ذخیره» sat at 618.6 against the same 548.7 limit. The rule is now the
same in three places — the primitive, the widget sweep and the device pass — and **the check
reproduces the conditions the user is actually in**, which is the whole of D-062 stated once.

---

## D-063 — Invoice filters are a value the repository turns into SQL, and «overdue» is deliberately not one

**Date:** 2026-09-01
**Status:** ACCEPTED — implemented as Phase 5 increment (e)
**Extends:** D-038 (one value, not two providers), D-006 (Jalali periods), D-040, §13
**Resolves:** known issue 16

### 1. One value, and it reaches SQL

`InvoiceFilter` — a set of statuses, an optional customer id, an optional
`InstantRange` — is handed to `InvoiceRepository.watchList` and applied as `WHERE` clauses on the
statement that already carries the ordering, the soft-delete filter and the `LIMIT`.

**Filtering in Dart would be the paging defect one step later.** The limit would apply to the rows
*before* narrowing, so a filter matching three invoices out of ten thousand would return whichever of
them fell in the first page and the screen would report "no results" about data that is right there.
That is not a hypothetical: the repository test `the filter reaches SQL, so the page is of matches`
builds twelve invoices with the single match sorting last, asks for a page of five, and requires the
match back.

`_applyFilter` is one method, so the three predicates cannot drift apart between the list and whatever
asks next. An **empty status set means every status** — the unfiltered list is the default and has to
be the cheapest thing to say — and it is written as an early skip rather than `IN (all five)`, which
is a clause the planner would still evaluate for a filter nobody set.

### 2. The window and the filter are one value, because changing one must reset the other

`InvoiceQuery` holds a `ListQuery` and an `InvoiceFilter`. A user who has loaded eight pages and then
narrows to «پرداخت نشده» should not have the application ask for three hundred and twenty unpaid
invoices. Held as two providers that is a rule somebody has to remember; held as one value it is
`filtering()`, which builds the new state from the first page. `loadingMore()` keeps the filter, and a
test pins that widening the window does not quietly drop the predicate.

### 3. «سررسید گذشته» is not a filter, and that is the interesting decision

Overdue is **derived at display time** from the due date against one clock instant (D-041), by
`invoiceStatusViewOf`, on whole Jalali days. A SQL predicate for it — `due_date < now AND status IN
(unpaid, partiallyPaid)` — would be a **second implementation of that rule**, in a different language,
with a different notion of "today". The two would eventually disagree, and the visible form of that
disagreement is a badge saying «سررسید گذشته» on an invoice the «سررسید گذشته» filter does not return.

Nothing becomes unreachable: an overdue invoice **is** `unpaid` or `partiallyPaid` and appears under
those. The five stored statuses are offered; the derived one is not. If a dedicated overdue filter is
ever wanted, the honest way to build it is to make the SQL predicate and `invoiceStatusViewOf` agree
by test over a fixture that straddles the boundary — the shape D-056's backfill and D-059's reference
implementation both use — not to write the predicate and hope.

**Ruled by the owner, 2026-09-01, at the Phase 5 review, and recorded here so it is not reopened as
an oversight.** The described approach *is* the accepted one: «سررسید گذشته» stays out of the filter
set. In the owner's words, a SQL predicate would be "a second implementation of a rule
`invoiceStatusViewOf` owns, and their disagreement would surface as a badge the filter doesn't
return — the same class of defect as two normalizer call sites drifting apart." A future session that
sees five chips where six statuses appear on badges is looking at a decision, not a gap. The only
sanctioned way to add it is the one the paragraph above names, and adding it without that is a
regression even if it compiles.

### 4. What the UI had to say, and where it had to not add height

- **The control is in the title row on every tier**, which costs no vertical space — §10's rule about
  what may sit above the thing a page exists to show, applied for the second time since it was
  written. A filter bar above the list was the obvious alternative and was refused on exactly that
  ground.
- **It shows a count when filters are on.** A control that looks identical filtered and unfiltered is
  how a user returns tomorrow, finds four invoices where there were four hundred, and concludes the
  application lost them.
- **A filtered empty list is a different state from an empty account.** «هنوز فاکتوری ثبت نشده» is
  *false* for a user with four hundred invoices and one filter, and it sends them looking for lost
  data instead of at the chips they just tapped. The filtered state offers «پاک کردن همه», not "make
  an invoice" — the invoices exist; the filter is hiding them.
- **The period presets are Jalali** and resolve through `core/date/`. «ماه گذشته» is
  `jalaliMonthShifted(now, -1)`, new in this increment, because the one-liner at a call site is wrong
  in a way that only shows in some months: Jalali months are 31, 30 or 29 days, and stepping back
  thirty days from the last day of a 31-day month lands in the *same* month. The helper shifts the
  month **number** and lets `jalaliMonth` resolve the boundaries. A test stands on that exact day and
  shows the subtraction failing.
- **The customer is chosen through the picker the invoice form already uses**, so there is one place
  the search normalization (D-029) and the soft-delete rule can be got wrong instead of two.

### 5. Known issue 16 closed: one customer's invoices are paged

`watchForCustomer` took a flat cap of 1000 rows that nothing could ask past. It takes `limit`/`offset`
like every sibling, driven by a per-customer `ListQuery` family so a second customer's page does not
inherit how far the first was scrolled. `CustomerDetailView` carries `hasMoreInvoices` in the same
value as the list, so the control and the rows describe one moment.

**Paging this list is only safe because the totals are not a sum of it.** Billed and outstanding are
one SQL aggregate over every invoice the customer has (D-044); a total computed from the loaded rows
would change every time the user pressed «بیشتر». There is now a test that says so.

### 6. Two of the project's own scanners fired, and one of them was wrong

Worth recording, because the resolution differed each time.

- **`theme_tokens_only_test` caught `const Duration(milliseconds: 1)`** in the filter sheet — the
  millisecond-step trick for finding the previous month. The scanner was **right**, and the fix was
  not an exemption but `jalaliMonthShifted`, which removes the arithmetic from the widget entirely.
  §5 already said calendar arithmetic belongs in `core/date/`; the token scanner is what noticed it
  had leaked out.
- **`soft_delete_usage_test` caught Riverpod's `provider.select((q) => q.filter)`** as a raw database
  read. The scanner was **wrong**: `.select` on a provider is not a query, and it is the narrowing
  §13 asks for by name. It could not be excluded by the existing lookbehind, because drift's own
  `_db.select(table)` is also preceded by a dot — what separates them is that a provider selector is
  handed a *function literal*, so `select(` is followed by `(`. The scanner now excludes that one
  form and has a test pinning it in both directions, so the exclusion narrows it rather than blinding
  it. Marking the line `soft-delete-exempt:` was the alternative and was refused: the comment would
  have claimed a database read was deliberate when there is no database read.

### 7. And the keyboard sweep found a real defect on its first outing

Adding the picker sheets to `sheet_keyboard_test.dart` — they are exempt from `EditorSheet` by design,
but the *rule* still applies to them in its own form — failed immediately. The customer picker's empty
state **overflowed by 24 pixels** with the keyboard up: 238 logical pixels of room against the 262 it
needs, on a 400 × 800 phone. That is a yellow-and-black band across the exact moment a user is typing a
search that matches nothing, which is when that empty state exists to be read.

`EmptyState` now scrolls instead of overflowing. Clipping was refused: the part that would be cut is
the sentence explaining the state, and an empty state with no explanation is the blank screen the
widget exists to prevent. On a page with room the column is `MainAxisSize.min` and measures exactly as
before, so nothing else changes.

**This is D-062 paying for itself inside one increment**, the same way D-057 paid for itself by
surfacing known issue 19. The rule was written for sheets with commit actions; the first thing it
caught was an empty state in a sheet that has neither.

---

## D-064 — A device suite runs at every tier it can be given, and the phase close is what runs it there

**Date:** 2026-09-01
**Status:** ACCEPTED — arising from Phase 5 increment (f), the phase close
**Extends:** D-062 (a check must reproduce the conditions the user is in), D-057 (all three tiers,
over the written ladder)

### 1. What the close found, which is D-062 one level up again

(f) had one job beyond paperwork: cover the invoice **list**, which had no `integration_test/`
coverage at all. Writing that suite was uneventful — it passed on the Redmi first try, 0 layout
errors, and on Windows the same. What was **not** uneventful was running the *existing* suites
somewhere they had never been run.

- **`invoice_form_device_test.dart` had never run at the desktop tier**, in two phases of existing.
  Pointed at Windows it failed on its **first measurement**: `find.text(invoiceLineAddFromCatalogue)`
  matched nothing. Not a product defect — `_DesktopLayout` is a single `ListView` whose second child
  is the entire lines section, and at a 1264 × 681 window that child sits past the cache extent and
  is therefore **not in the tree**. Absence, not invisibility, exactly as D-062 §2 describes it.
- **It also carried a fold measurement that only means something on a phone.** D-054 ruled that the
  invoice-level fields fold on the narrow tier and that *the wider tiers do not fold*. The suite
  measured the fold unconditionally, so at any other tier it was about to report a number for a
  layout that has no fold.
- **And a tap aimed at a label rather than a control.** `tap(find.text(invoiceFieldIssueDate))`
  warned that the derived offset "would not hit test on the specified widget" and opened the date
  picker **anyway**: once the field has a value its label floats up inside the decoration, and the
  tap landed on the `InputDecorator` under it, which happens to sit in the same `InkWell`. It worked
  by geometry. A warning is not a failure, so this had been passing, in green, for two phases.

So D-062 was written after the detail suite proved to be single-tier, and the fix was applied to the
detail suite. The **form** suite was the same defect, sitting one file away, and it survived because
nothing made anyone point it at a second tier.

### 2. The rule

**Every device suite runs on every target the project has, and a phase closes only after it has.**
Not "the suite is tier-aware" — that is a property nobody can check by reading — but the run itself,
on both targets, with its output in `CURRENT_STATE.md`. The Windows run is the desktop tier and the
Redmi is the phone tier; a suite that has only ever seen one of them is evidence about one of them,
which is D-057's sentence with "tier" replaced by "target".

**Where a measurement belongs to one tier, the suite says so and skips it elsewhere rather than
printing it anyway.** A device report carrying a fold measurement for a layout with no fold is a
report about a screen that does not exist — D-062's mistake in its reporting form, and worse than
silence because it reads as evidence.

**A tap names the control, never its label.** `JalaliDateField` carries the `onTap`; the label is
decoration that happens to sit over it. A tap that lands on the right thing by accident stops doing
so the moment the decoration is restyled, and it stops silently, because a hit-test warning does not
fail a run.

### 3. What it cost, and what it did not find

Three edits to one file, one new helper (`_rewind`, because `_scrollTo` only ever searched
downwards and the desktop tier parks the page below the fields after a line is added), and the suite
now passes on **both** targets with identical D-054 numbers on the phone — 586 / 670 / fits, and 245
after unfolding, the same figures it reported before the change.

**No product defect was found by any of it.** Both new tiers, all four rungs, both new suites: 0
layout errors. That is the outcome to expect from a close and it is not an argument against running
it — known issue 18 shipped through a phase that reported the same thing about one tier.
---

## D-065 — A flexible column declares its minimum, and a table that cannot meet it changes shape

**Date:** 2026-09-01
**Status:** ACCEPTED — arising from a defect reported off the Windows build after the Phase 5 close
**Extends:** D-037 (money columns are fixed-width), D-058 (which five columns fit), the project spec
(a widget measured at its own full width has not been measured at the width it is composed into)

### 1. The defect, and why nothing saw it

On the invoice detail screen at the desktop tier, the document table's **description column was laid
out at 21.6 logical pixels**. Persian rendered one glyph per row, vertically. The money columns beside
it held their width perfectly.

The arithmetic is not marginal and it is not an edge case:

```
AppLayout.maxContentWidth                    1240
  less PageBody's desktop padding, 2 x 48    1144   <- the number D-058 checked against
  less the side panel and its gap, 320 + 24   800
  less AppTableRow's own padding, 2 x 16      768   <- the width the table actually gets
three money columns at tablePriceWidth        732
                                        ------------
left for شرح (flex 3) and تعداد (flex 2)        36
```

The page is capped at `maxContentWidth`, so **768 is the table's width at every desktop window size**.
This was not a narrow-window failure; it was every user, every time.

**Nothing failed, and that is the substance of this decision.** `_cell` lays a flexible column out with
`Expanded`, which is a **tight** fit: the column is given what the fixed columns leave, and if that is
nothing, nothing is what it is given — laid out successfully. There is no `RenderFlex` overflow,
because nothing is too big for its box; the box was made too small for its content. The device suite
for this exact screen reported **0 layout errors**, truthfully. 935 widget tests passed. It took a
person looking at the screen.

**And D-058 did the sum with the right method and the wrong number.** It compared six columns against
1144 — the *full* desktop content column — in a file whose own doc comment quotes §10's rule about
composed width. The rule was known, written down, and applied to the wrong figure one paragraph later.

### 2. What was decided: the table gives up columns, not width

The description gets a floor. Where the table cannot meet it, it drops a money column and says that
figure as a labelled detail line under the description instead — the shape D-058 already chose when it
moved تخفیف, مبلغ پس از تخفیف and مالیات out of the columns.

```
                                              needs
شرح · تعداد · مبلغ واحد · مبلغ کل · جمع        1130
شرح · تعداد · مبلغ واحد · جمع                   886
شرح · تعداد · جمع                               648   <- what the detail screen selects, at 768
شرح · جمع                                       520
below that: the card layout
```

**مبلغ کل goes first** because it is the one figure on the row that is a *step in the arithmetic*
rather than a term of the agreement: the customer checks the unit price they agreed and the total they
owe, and the gross between them is working. It has been a sentence on every card for that same reason
since the cards were built.

**Nothing is lost when a column goes.** Each dropped figure reappears through the string the card
already uses, so the wide table, the narrow table and the card say the same things in the same words.
Only `invoiceLineLabelUnitPrice` is new, worded to match `invoiceLineLabelGross`.

**The two alternatives were refused, and the reasons are the requirement stated properly:**

- **Horizontal scrolling.** A document is read by carrying the description across to the total. A
  scroll that puts those on different screens breaks the one comparison the page exists for, and it
  hides figures sideways where nothing suggests they are there.
- **Wrapping the row.** A row that takes two lines has stopped being a table — and the application
  already has a shape for a line that is not a table row. It is the card, and it is what the narrow
  tiers use. So *that* is the floor: below the width شرح · جمع needs, the desktop tier renders cards.

### 3. Why the fix is in the primitive, not in the screen

`TableColumnSpec` has two constructors now, and **a flexible column cannot be declared without a
`minWidth`**. This is D-043's shape — a required parameter rather than a lint or a convention — for
the same reason: the failure is silent, so the only reliable moment to catch it is the one where the
code will not compile without an answer.

`AppTableHeader` checks the total once per table and **asserts** rather than falling back. Only the
caller knows which of its columns are recoverable somewhere else, so the primitive's job is to make the
failure loud, not to guess a remedy.

**Making the parameter required immediately found the other four tables.** Customers, products,
invoices and the invoice editor all had flexed prose columns with no stated floor. None of them was
crushed at any width the application reaches — checked, not assumed — but all four were one layout
change away from it, and none of them could have told anybody.

### 4. The checks, and what each one is for

- **`tableMinimumWidth` + the header's assertion** — the structural guard. `app_table_test.dart` pins
  it one pixel either side of the threshold.
- **`invoice_document_lines_test.dart`** — the ladder, rung by rung, at widths that select each, plus
  every threshold minus one. The screen test could only ever reach one rung, because the page cap fixes
  the table's region at 768; three of the four would have been untested, and an untested rung is a rung
  that will be wrong when something finally selects it.
- **`expectNoCrushedText`** (`test/support/text_fit.dart`, duplicated into
  `integration_test/device_assertions.dart`) — the general detector, and the one that generalises past
  tables. A `RenderParagraph` laid out narrower than its own `getMinIntrinsicWidth` cannot place its
  longest word, so it breaks *inside* the word. That is precisely "renders vertically", stated in a
  way a machine can check anywhere in any tree. Ellipsised text is excluded: truncation is a decision
  somebody made, crushing is not.
- **`persian_content_sweep_test.dart`** — every screen, every tier, real Persian at the length real
  data reaches, over the real repositories. This is the answer to "what else": not a list of places to
  go and look, but a check that looks at all of them. It found nothing further, which is the outcome to
  expect and not a reason the sweep was unnecessary.
- **The three device suites** now run the detector too, and the detail suite's fixture carries a
  *long* line title, because «مشاورهٔ فنی و مهندسی» is short enough to survive a crushed column and
  that is what it had been proving.

**Verified to bite at the device tier**, in Vazirmatn, on the screen as reported: forcing the old
single-shape behaviour, the Windows run reports the description at **9.6 px needing 62.7** and the
quantity at **2.4 px** — from the suite that used to say "0 layout errors" about that exact frame.

---

## D-066 — A component's foreground is a token somebody chose, and it is checked in pixels

**Date:** 2026-09-01
**Status:** ACCEPTED — arising from a defect reported off the Windows build after the Phase 5 close
**Extends:** D-033 (tokens enforced rather than offered)

### 1. The defect: not a wrong colour, an absent one

The payment sheet's method selector — نقدی, کارت به کارت and the rest — had unreadable labels. The
cause was one line in `chipTheme`:

```dart
labelStyle: AppTypography.label.copyWith(fontFamily: AppTypography.fontFamily),
```

`AppTypography.label` names **no colour**, and Material's `RawChip` uses the theme's `labelStyle` *in
place of* its own state-dependent default rather than merging over it. So the label was painted with no
colour at all and fell through to the engine's fallback, which is **white**. Measured off the rendered
pixels:

| | background | painted | ratio |
|---|---|---|---|
| light, unselected | `#f3f2ef` | `#ffffff` | **1.12:1** |
| light, selected | `#cfebe7` | `#ffffff` | **1.26:1** |
| dark, unselected | `#1d2220` | `#ffffff` | 16.1:1 |
| dark, selected | `#0b554f` | `#ffffff` | 8.7:1 |

**It survived because the accident ran the right way in one place.** White on the dark theme's surfaces
is perfectly readable, so dark mode looked deliberate. And the *checkmark* on a selected chip takes its
colour from a separate default the flat `labelStyle` never touched — so a selected chip showed a
correctly-coloured tick beside an invisible word, which is exactly the kind of half-right rendering
that reads as "fine" in a screenshot.

### 2. The fix, and the second half of it that only pixels found

Both the background and the foreground are named, together, as a state-resolved pair — `RawChip`
resolves `labelStyle.color` as a widget-state property, which is the supported mechanism:

```
unselected  surfaceContainer     / onSurfaceVariant
selected    secondaryContainer   / onSecondaryContainer
```

**And `ChoiceChip` reads its selected label from `secondaryLabelStyle`, not from `labelStyle`.**
Fixing `labelStyle` alone left a selected chip in dark mode at **3.75:1** — still failing, still
looking plausible, and invisible to any amount of reading. One shared resolver now feeds both, so the
two cannot be right and wrong at the same time.

Result: 6.3:1 to 11.4:1 across all ten combinations.

### 3. Why the check reads pixels rather than tokens

A test that compared theme tokens would have had **nothing to compare**. The whole failure is that the
token is absent, and the value that reached the screen came from neither the theme nor the scheme — it
came from the engine. Only the rendered output knows.

`component_contrast_test.dart` renders each component under each theme in each state, captures it, and
computes the WCAG ratio between what it painted its label in and what it painted that on. Threshold
4.5:1, the AA floor for body text; chip labels are 12px, so the 3:1 large-text allowance does not
apply.

Two things about the sampler are worth keeping, because both were wrong first:

- **It samples inside the label's own box.** Sampling the whole component and taking the colour
  furthest from the background finds the *checkmark*, which is correctly coloured, and reports a
  healthy ratio for a chip whose label is invisible beside it.
- **It looks for the extreme in either direction.** "The darkest colour, because text is dark" is an
  assumption a broken foreground breaks: looking only downwards for a white-on-pale label finds nothing
  and returns the background as its own foreground — a ratio of exactly 1.00, which reads as a broken
  measurement rather than as the defect it is.

**The table is the generalisation.** Every chip variant the application uses is a row in it —
`ChoiceChip` (payment methods, filter periods), `FilterChip` (filter statuses), `ActionChip` (the
customer picker) — so "check the same component everywhere else it is used" is not something to
remember next time.

**Verified to bite:** restoring the old `chipTheme` fails four of the ten at 1.12:1 and 1.26:1.

---

## D-067 — Widget tests render in Vazirmatn

**Date:** 2026-09-01
**Status:** ACCEPTED
**Extends:** D-022 (the bundled font), D-062 (a check reproduces the conditions the user is in)

Flutter's test environment substitutes a fallback font whose glyphs are far wider than Vazirmatn's, and
this project carried that as a known caveat from Phase 1: *"a fixed-width column that passes a widget
test has margin in the shipped layout."*

**That caveat is only comforting in one direction.** It makes every *maximum*-width assertion
conservative — and it makes every *minimum*-width assertion wrong the other way. The first run of the
crushed-text detector under the fallback font reported four failures on the invoice detail screen, of
which one was real and three were the font: a bidi-isolated invoice number, a Jalali date and a status
badge, all of them fine in Vazirmatn and all of them "too narrow" in a font 40% wider. Noise that
cannot be told from signal is worse than no check.

`pumpScreen` now loads the three real weights through `FontLoader` before pumping — the font is a
declared asset, so `rootBundle` has it in tests. Loaded once per process and cached.

**It broke nothing.** All 940 tests that existed at the time passed unchanged, which is what the
direction of the caveat predicts: narrower glyphs mean more room, so every assertion written against
the wider font still holds. What changes is that a width assertion now means what it says, and the
project no longer has a standing reason to discount its own layout measurements.

