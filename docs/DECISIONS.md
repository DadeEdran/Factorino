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


---

## D-068 — The plan is cut to Phase 6 and Phase 7, at standards reduced on purpose

**Date:** 2026-09-01
**Status:** ACCEPTED (project owner)
**Supersedes, in scope only:** the phase ladder in the project spec and `ROADMAP.md`
**Reduces, for these two phases only:** D-057 (three tiers × four rungs), D-064 (every device suite at
every target)

**Decision.** The owner's development window for this project ends 2026-09-04. From this point the project targets
**usable and shippable, not complete**. Only two phases remain in the plan:

- **Phase 6 — Backup and Restore**
- **Phase 7 — PDF Generation**

**Phases 8 through 15 are deferred indefinitely** — not "next", not "later in the MVP", not scheduled.
`ROADMAP.md` states this in each of their entries rather than leaving them reading as if they are
coming. Deferring them is a scope decision, not a judgement that the work is unnecessary: Phase 9's
release signing and manifest hardening in particular remain the difference between an APK that can be
distributed and one that cannot, and the roadmap says so where it defers them.

**The reduced standards, stated so they do not read as sloppiness later.** Each of these is a
deliberate trade with a named cost, in force for Phases 6 and 7 only:

| Standard | Full form (D-057, D-064, §15) | In force for 6 and 7 | Cost accepted |
|---|---|---|---|
| Device pass | 3 tiers × 4 rungs of `money_magnitudes.dart`, every suite at every target | **Phone tier, one large realistic amount** | A desktop-only or tablet-only layout fault ships unseen. This is exactly the fault class D-057 was written after — accepted knowingly, because a document renderer's hard cases are Persian shaping and page breaks rather than tier widths |
| Tests | Exhaustive layout coverage plus correctness | **Correctness of the data only** — a backup round-trips to the Rial, PDF figures equal stored figures | Layout regressions in the new surfaces are caught by eye, not by suite |
| PDF | Templates, logo, customisation | **One template.** No choice, no logo upload, no customisation | Every user gets the same document. Branding is a Phase 7+ idea that no longer exists |
| Backup | Export, import, scheduling, cloud, CSV | **Export and import, encrypted, with the integrity check** | No automatic backups: the user must remember. The settings reminder is the whole mitigation |

**What is not reduced, because these are why the figures on a document can be trusted.** These four
hold at full strength and a shortcut against any of them is a defect, not a trade:

1. **`core/money/` stays the only calculator.** No read site, no renderer, no export path multiplies,
   divides or rounds anything (D-046, D-047).
2. **The renderer receives a fully computed, already formatted view model and computes nothing**
. A PDF that recalculates is a second implementation of §4.
3. **Encryption and key handling stay exactly as they are** (D-010, D-012, D-020). The backup format
   may reuse them; it may not weaken them, and no path may put the database key or a user password in
   a log, an error string or a temporary file.
4. **Persian correctness is not negotiable in a document handed to a customer** — digits, Jalali
   dates, RTL, and bidi isolation on invoice numbers, phone numbers and national IDs.

**Reason.** Three days is not enough for eight more phases, and pretending otherwise produces eight
half-phases instead of two finished ones. Cutting the scope explicitly, and writing down which
standards were lowered and which were not, is what keeps a later reader from mistaking a deliberate
trade for a lapse — and keeps the four load-bearing invariants from being traded away in the same
breath as the layout sweep.

**Alternatives considered.** Keeping the full ladder for Phases 6 and 7 (rejected: the sweep is
roughly a third of an increment's time and its highest-value target, money widths at three tiers, is
already covered by the existing suite for every screen these phases touch). Cutting to one phase
(rejected: an invoice app that cannot produce a document and an invoice app that cannot be backed up
are both unshippable, for different reasons — §8 says the first outright). Deferring the standards
question and deciding per-increment (rejected: a standard lowered silently at the moment it is
inconvenient is indistinguishable from one nobody held).

---

## D-069 — The backup is an encrypted SQLite database keyed by the user's password

**Date:** 2026-09-01
**Status:** ACCEPTED (project owner, with the split for Phase 6)
**Builds on:** D-010 (sqlite3mc is the encryption provider), D-020 (`PRAGMA key` is the first
statement on every connection), D-068 (the reduced scope these two phases run at)

**Decision.** A Factorino backup file **is an SQLite database** — written by the same
SQLite3 Multiple Ciphers library the live database already uses, under the same SQLCipher-compatible
configuration (`PRAGMA cipher = 'sqlcipher'; PRAGMA legacy = 4;`), but keyed by a **password the user
supplies** rather than by the device key in `flutter_secure_storage`.

It carries a `backup_meta` table: the backup format version, the application schema version, the
creation instant in UTC epoch milliseconds, and a **row count per table**.

### Why the container is the format, rather than an encrypted serialization

The alternative was a JSON or binary serialization encrypted with AES-GCM, keyed through a PBKDF2 or
Argon2 derivation. It was rejected, and the reason is not convenience.

**Every cryptographic primitive §8 asks for is already shipping in this application, tested, and on
the correctness path of the live database.** SQLCipher-compatible mode at `legacy = 4` derives the key
from the passphrase with **PBKDF2-HMAC-SHA512 at 256,000 iterations** and authenticates **every page
with HMAC-SHA512**. Choosing the serialization route means writing a key derivation and an
authenticated-encryption path by hand, against a dependency this project does not yet have, in the one
phase of the project where a subtle mistake **fails silently** — a backup that encrypts wrongly, or
authenticates nothing, looks exactly like a backup that works, right up to the day someone needs it.

**Using the library already shipping is the security-correct answer here, not the expedient one.**
The expedient answer and the correct one coincide, which is worth stating plainly because the reverse
inference — that reusing what is present must be a shortcut — is the one a later reader is likely to
draw. It also adds **no new cryptographic dependency**: the local pub cache holds `crypto` and
`archive` and nothing else usable, so the serialization route would have meant taking a fresh
dependency for the primitives as well as writing the code around them.

Two further properties fall out of the container that the serialization route would have had to build:

- **Version compatibility is the migration ladder.** The backup file is a Drift-openable database, so
  an **older** backup migrates itself up the existing, tested ladder when it is opened. A **newer**
  one is refused, because this build has no step to run.
- **A wrong password fails at the first page read**, loudly and before any data is touched — not
  after a decrypt that produced plausible-looking garbage.

### Integrity: the per-page HMAC and the row counts, and deliberately nothing else

§8 requires "a format version and an integrity check (e.g. HMAC)". Both are present:

| Requirement | Met by |
|---|---|
| Format version | `backup_meta.format_version`, plus the application schema version beside it |
| Cryptographic integrity | The container's **per-page HMAC-SHA512** — tampering fails authentication at the page that was touched |
| Logical completeness | **Row counts per table** in `backup_meta`, compared on import |

**No whole-file HMAC is added on top, and its absence is a decision rather than an omission**
(project owner, 2026-09-01). A second integrity check over the same bytes can **disagree** with the
first, and then the import path has to decide which one it believes — a question with no good answer
that only exists because the second check was added. One authenticated container, plus a logical
check that answers a different question (*is this backup complete?* rather than *has this backup been
altered?*), is the whole of it.

### What the backup is not keyed by

**The backup password is not the database key, and the database key never leaves the device.** A
backup keyed by the device key would be unreadable on the replacement device — which is the only
device that will ever need to read it. The user-supplied password is what makes the file portable,
and it is also why §8 requires the UI to say in Persian that losing the password loses the backup:
there is no recovery path and no one who can help.

### The three constraints this carries into every increment

1. **Nothing about a backup is logged** — not the password, not the destination path, not a row count
   that implies how much business the user does (§7).
2. **The container is built in app-private storage and deleted on every exit path**, including the
   failing ones. Delivery to a user-chosen location is a separate step over the finished bytes, which
   is also what keeps `sqlite3` on a real filesystem path and the service testable without plugins.
3. **The import confirmation states in Persian that existing data is replaced, not merged** (project
   owner). A user who expects a merge and receives a replacement loses everything entered since the
   backup was taken, and has no reason to expect it — the word "restore" implies addition to most
   people. This is a copy requirement with the weight of a data-loss guard, because that is what it
   is.

---

## D-070 — The Phase 7 shaping probe: `pdf` renders Persian, and two characters must never reach it

**Date:** 2026-09-01
**Status:** ACCEPTED
**Gate for:** Phase 7. Run before Phase 6 (b) at the owner's direction, because a failure here would
have replanned the phase rather than been discovered on the last day.

**Result: Phase 7 is viable.** `pdf` 3.13.0 with `bidi` 2.0.13, rendering bundled Vazirmatn, shapes
and joins Persian correctly, lays RTL out correctly, renders Persian digits (U+06F0–U+06F9) and the
Arabic thousands separator (U+066C), and puts a Latin invoice number in the right place inside an RTL
sentence **with no isolation marks at all** — «فاکتور INV-1405-0001 صادر شد» comes out in that order.
The probe drew a realistic invoice: header, party block, a four-column table with two money columns,
tax line and grand total. No new information changes the plan.

**Two findings that do change the renderer's contract.**

### 1. U+2068 / U+2069 must never reach the PDF — they eat the last character of the run

The probe put `INV-1405-0001` between FSI and PDI, as the project spec requires **on screen**. It came
out as `▯INV-1405-000▯` — two missing-glyph boxes, **and the trailing `1` gone**. A national ID
`0069543210` came out with nine digits. `ABCDEFGHIJ` came out as `ABCDEFGHI`. The loss is silent and
the result is plausible, which is the worst possible shape for a defect on a document a customer
reconciles by hand.

**Cause, checked rather than guessed.** Vazirmatn's `cmap` was parsed directly: **U+2068 and U+2069
map to glyph 0**, while U+200C, U+200E, U+066C and U+06F0 all map to real glyphs. So the boxes are
genuinely absent glyphs, and the swallowed character is an index fault in the shaper when a run
contains an unmapped control.

**The rule.** The PDF view model carries **no isolation controls**. This is not theoretical: the
application already wraps invoice numbers, phone numbers and national IDs in FSI/PDI for the Flutter
UI, where they are correct and necessary. **If a formatted string is passed from the screen layer to
the renderer verbatim, invoice numbers and national IDs print with a character missing.** Stripping
them is a step at the view-model boundary, and it needs a test, not a comment.

**What to use instead**, all three verified working: nothing at all (the bidi algorithm handles a
Latin or Persian-digit run inside RTL on its own), U+200E LRM (in the font, glyph 319, renders
invisibly), or an explicit `pw.Directionality(textDirection: ltr)` around the run.

> **Withdrawn 2026-09-02 (D-073). Adopted on inference, withdrawn on measurement — that is the
> lesson, not the character.**
>
> The recommendation above says "all three verified working". Two of them were: they were rendered
> and the pixels were read. **U+200E was not.** What was actually checked was Vazirmatn's `cmap` —
> U+200E is in it, at glyph 319 — and "so it renders invisibly" was then inferred from that and
> written down in the same sentence as the two that had been seen. The inference is wrong twice
> over: the renderer **deletes** the LRM before shaping (Unicode Bidi rule X9), so the letters
> either side **join** and the string silently becomes a misspelling; and glyph 319 is zero-length,
> so on any path where it did survive it would draw «₪» rather than nothing.
>
> Neither failure is visible in the output. A misspelled Persian word still looks like a word, so no
> reviewer, no test and no proofread would have caught it — this was on its way into every printed
> document.
>
> **A `cmap` reading is not a page.** A `cmap` says which glyph a rune selects; it says nothing
> about whether that glyph is what gets drawn, nothing about whether the rune survives the shaper,
> and nothing about what the shaping does to its neighbours. D-070's own method note already
> required rendering pages and reading pixels; this line is where that rule was relaxed for one
> item because the font table seemed to settle it, and it is the one item that was wrong.
>
> "Nothing at all" and the explicit LTR `Directionality` stand — both were rendered.

### 2. A number containing spaces or a `+` still scrambles, and that is the real isolation case

`+98 912 123 4567` rendered, left to right, as `۴۵۶۷ ۱۲۳ ۹۱۲ ۹۸+` — the groups reversed. Space and
`+` are bidi-neutral, so the number breaks into runs that take the paragraph direction. The unbroken
form `09121234567` renders correctly with no help at all.

**The rule.** Any number that is not a single unbroken run of digits is wrapped in an explicit LTR
`Directionality` in the renderer. Formatting that introduces spaces into a phone number is a decision
the view model makes and the renderer must then protect.

### 3. Open, and owned by Phase 7: ZWNJ draws a box

> **Closed 2026-09-02 by D-073, and the diagnosis below is wrong in its cause.** It is not a
> missing-glyph box: `TtfParser.readGlyph` does not check whether a glyph is empty, so U+200C draws
> the **next glyph in the font**, which in Vazirmatn is «à». The remedy is to cut the run at the
> ZWNJ and send no control character at all. Read D-073 instead of this section and its D-072
> amendment.

U+200C renders as a missing-glyph box: «پیش‌نویس» prints as «پیش▯نویس». This matters — ZWNJ is
ordinary Persian, it is in this application's own status labels, and it is in customer-entered product
descriptions.

**It is not the font.** U+200C **is** in Vazirmatn's `cmap`, at glyph 322. And the shaping around it
is already right: the join is correctly broken, with ش in final form and ن in initial form. Only the
control's own glyph is wrong. Deleting the ZWNJ is **not** the fix — that yields «پیشنویس», joined
across a boundary that must not join.

Left open deliberately: it is a Phase 7 implementation question with a working shape already visible
(the substitution happens inside the package's shaper, so the remedy is at the glyph-mapping layer,
not in our strings), and the probe's job was to decide whether the phase is viable. It is. **This is
the first thing Phase 7 fixes**, and it is a correctness item under D-068's "Persian correctness is
not negotiable", not a polish item.

### Method note

The probe rendered actual pages and read the pixels — `pdf.js` to a canvas, screenshotted, zoomed —
rather than inspecting content streams, and then confirmed each cause against the font's `cmap`.
Nothing here rests on what the library is documented to do. It ran in a throwaway package in the
scratchpad, so **the dependency never entered `pubspec.yaml`** and the Phase 7 entry-gate baseline
below still sits on a commit with no PDF dependency in it.

### Amendment, 2026-09-01, after the owner reviewed the rendered pages

**The ZWNJ box is in the application's own strings, not only in test data or customer input.** The
owner spotted it in a place the report had read straight past: the probe's **own section heading**,
«نیم‌فاصله», printed «نیم▯فاصله». ZWNJ is ordinary Persian and it is already in this project's ARB —
«پیش‌نویس», «پرداخت‌نشده», «وب‌سایت» among others. **A document with boxes through its own labels is
not deliverable**, so this is the **highest-priority item in Phase 7, ahead of layout**, and it is a
correctness item under D-068 rather than a polish one.

**Three requirements the remedy must meet** (owner):

1. **It must preserve the join break.** «پیشنویس» joined across that boundary is a misspelling, not a
   near-miss. Whatever the substitution turns out to be — a zero-width space, splitting the run at the
   boundary, a glyph-mapping fix — the shaping either side must be **verified** the way the probe
   verified it: ش in final form, ن in initial form, read off the rendered page.
2. **It must be tested over the real ARB, not over examples.** Scan every ARB entry for U+200C and
   assert each one renders through the PDF path with no missing glyph. A handful of hand-picked
   strings is not the coverage this needs.
3. **It must not be mistaken for the whole answer.** Stripping control characters fixes finding 1. It
   does **not** fix finding 2, and the remedy must not read as "remove the controls and you are done".

### The print contract, measured rather than reasoned — probe 3

The owner asked whether the print path can simply default to **LTR `Directionality` with no control
characters**, since three of the four cases in probe 2 rendered correctly bare. It is the right
question and the answer is **no — that specific rule is destructive.** Probe 3 rendered thirteen field
shapes twice, once bare in the RTL page and once wrapped in LTR `Directionality`.

**Identical and correct in both columns**, so the wrapper is a **no-op** for all of these: invoice
number `INV-1405-0001`, national ID, a fourteen-digit economic ID, the unbroken phone
`۰۹۱۲۱۲۳۴۵۶۷`, the hyphenated phone `۰۹۱۲-۱۲۳-۴۵۶۷`, **the spaced `+۹۸ ۹۱۲ ۱۲۳ ۴۵۶۷`**, the Jalali
date `۱۴۰۵/۰۶/۱۰`, the amount `۸۳٬۸۷۵٬۰۰۰` with U+066C, the percent `۱۰٪` with U+066A, the negative
`−۱٬۰۰۰` with U+2212, and a parenthesised `(INV-1405-0001)`.

**Different, and the wrapper destroys the Persian** wherever the value carries any:

| Value | Bare, in the RTL page | Wrapped in LTR `Directionality` |
|---|---|---|
| `فاکتور INV-1405-0001 صادر شد` | correct | **`دش رداص INV-1405-0001 روتکاف`** |
| `۸۳٬۸۷۵٬۰۰۰ تومان` | correct | **`۸۳٬۸۷۵٬۰۰۰ ناموت`** |

The words are not merely misplaced — «فاکتور» comes out «روتکاف» and «تومان» comes out «ناموت». LTR
wrapping reverses the visual order of any RTL run inside it. **So it cannot be the default: it does
nothing wherever it is safe and corrupts the text wherever it is not.**

**And the spaced phone resolved the apparent contradiction with probe 2.** There it scrambled to
`۴۵۶۷ ۱۲۳ ۹۱۲ ۹۸+`; here it is correct bare. The difference is the surrounding run: in probe 2 the
value shared one `Text` with its Persian label, `'تلفن: ' + number`. Alone in its own cell it is
fine. **The trigger is not the `+` or the spaces by themselves — it is a value carrying internal
bidi-neutral characters sharing a single run with RTL text.**

### The contract, stated

Simpler than either candidate, and structural rather than per-string:

1. **No control characters reach the renderer.** No FSI, no PDI. Stripped at the view-model boundary,
   with a test.
2. **The label and the value are separate widgets — never concatenated into one string.** This is what
   makes finding 2 *disappear* instead of needing a remedy: every field measured above renders
   correctly bare once it is not sharing a run with its own label.
3. **LTR `Directionality` is not the default.** It is a no-op on every field that already works and
   destructive on any value containing Persian. After this measurement, **no field a document prints
   needs it** — including the amount-with-unit, which must be composed as two widgets or left bare,
   never wrapped.

Rules 1 and 2 together are the whole contract, and rule 2 is a composition rule the renderer would
want anyway. There is no per-field special-casing left in it.

---

## D-071 — The backup file gateway: two packages, split by the one thing Android cannot do

**Date:** 2026-09-01
**Status:** ACCEPTED
**Part of:** Phase 6 (a). **Implements** the delivery half of D-069.

**Decision.** Getting a backup file out to, and back from, a location the user chose is a **separate
thin gateway**, not part of `BackupService`. The service produces and consumes a path in app-private
storage; the gateway moves the finished bytes.

| Target | Export (save) | Import (open) |
|---|---|---|
| Windows | `file_selector` — `getSaveLocation` | `file_selector` — `openFile` |
| Android | **`flutter_file_dialog`** — SAF create-document | `file_selector` — `openFile` |

**Why the split, checked in the source rather than assumed.** `file_selector_android` implements
**only** `openFile`, `openFiles` and `getDirectoryPath` — read directly from
`flutter/packages/…/file_selector_android/lib/src/file_selector_android.dart`. There is no
`getSaveLocation` on Android. `file_selector_windows` does implement it. So one package covers three
of the four cells and cannot cover the fourth, and the fourth is the one that writes the user's only
copy of their business records.

**Why `flutter_file_dialog` for that cell, over the alternatives.**

- **vs. `share_plus`:** a share intent hands the file to a third-party application of the user's
  choosing. That is a **new outbound data surface for the most sensitive artifact this application
  produces** (§7) — the entire customer and invoice database in one file. `flutter_file_dialog`'s
  `saveFileToDirectory` uses SAF `ACTION_CREATE_DOCUMENT`: the file goes where the user picked, on
  the device, without passing through another app. The container is encrypted either way; the point
  is that the encrypted-file-in-someone-else's-app surface does not need to exist at all.
- **vs. `getDirectoryPath` + `dart:io`:** SAF returns a tree URI, not a filesystem path that
  `dart:io` can write to.
- **vs. app-external storage** (`path_provider`, no dependency at all): works and needs no permission
  on any API level, but there is no dialog — the user must go hunting in a file manager for a path
  like `Android/data/<package>/files`. Kept as the **documented floor** if the dependency has to be
  dropped, precisely because it costs nothing to fall back to.

**Dependency justification (§2).** `flutter_file_dialog` 3.3.2, published 2026-07-24, Android and iOS
only, and **zero transitive dependencies beyond `flutter`** — it is a thin platform-channel wrapper
over one Android intent. `file_selector` 1.1.0 (flutter.dev, published 2025-11-21) brings its
federated implementations. Both resolve on this machine; verified with `pub add --dry-run` against
`https://pub.dev` directly, since the configured mirror has been intermittently unreachable (known
issue 11).

**If either becomes unmaintained.** Both sit behind our own `BackupFileGateway`, whose whole surface
is "put these bytes somewhere the user chose" and "give me back bytes from a file the user chose".
`flutter_file_dialog` is one intent behind that interface; the app-external-storage floor above is
dependency-free and already specified. This is a small, well-bounded surface deliberately.

**Why the gateway is separate from the service at all.** Three reasons, and the third is the one that
matters most:

1. `sqlite3` needs a **real filesystem path**. A SAF content URI or an `XFile`'s bytes cannot be
   opened as a database, so import must land the bytes in app-private storage before opening them
   regardless.
2. `BackupService` stays testable on the Dart VM with **no plugins** — which is where the
   round-trip-to-the-Rial test lives.
3. **Phase 7 inherits it.** A PDF has the same problem — bytes that must reach a place the user
   chose — and D-068's ordering was decided on exactly this: the phase that cannot avoid the gateway
   builds it, and the phase that could dodge it gets it for free.

**Not yet exercised on a device.** The packages are chosen and resolve; **no Android save dialog has
been raised on real hardware**, because the phone has been disconnected since before D-065. That run
is owed alongside the Android container proof and the Phase 7 cold-start baseline — all three want
the same cable, and D-064 is explicit that a target with no run is a target with no evidence.


### Amendment, 2026-09-01 — the gateway is proved on hardware, and it has a stated expiry

**The Android save dialog opens.** `integration_test/backup_gateway_probe_test.dart`, run on the
Redmi Note 8 Pro (Android 11, MIUI). The evidence is the intent itself, read out of
`dumpsys activity activities` while the picker was in the foreground:

```
Intent { act=android.intent.action.CREATE_DOCUMENT cat=[android.intent.category.OPENABLE]
         typ=*/* cmp=com.google.android.documentsui/com.android.documentsui.picker.PickActivity }
```

That is SAF's create-document flow and **not** a share intent — the property D-071 chose this package
for, now demonstrated rather than argued. Cancelling returns `false`, so a cancellation is reported
as the ordinary outcome it is instead of surfacing as a failed backup.

**Driving it needed a workaround worth recording.** `adb shell input keyevent` is refused on this
device — *"Injecting to another application requires INJECT_EVENTS permission"* — because MIUI gates
simulated input behind its **USB debugging (Security settings)** toggle. `am force-stop
com.google.android.documentsui` cancels the picker just as well and needs no device setting changed.

**`flutter_file_dialog` has an expiry date, and it is now known rather than assumed.** The build
warns:

> *Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): `flutter_file_dialog`.
> Future versions of Flutter will fail to build if your app uses plugins that apply KGP.*

It builds today and it is not a failure today. It is a **dated dependency**: unless the author
migrates to Built-in Kotlin, a future Flutter upgrade stops building this application. That does not
change the choice — the alternative was a share intent handing the entire customer database to
another app — but it raises the value of the escape route D-071 already specified, and the escape
route is the reason this is a note rather than a reversal. **If the plugin expires, the fallback is
app-external storage via `path_provider`: no dependency, no permission on any API level, and a path
the user can reach with a file manager.** The gateway interface is what makes that a one-file change.

**Still untested, and stated rather than implied:** the **completed** save. Choosing a location and
confirming needs a human tap, which no automated run on this device can supply while MIUI refuses
input injection. What is proved is that the dialog opens, resolves the right intent, and that
cancelling is handled. The Windows save dialog is likewise unexercised — lower risk, since
`file_selector_windows` is flutter.dev's own, but unexercised is unexercised (D-064).


### Amendment, 2026-09-01 (second) — the completed save is proved, and the dependency gets a review trigger

**Both targets now write the file, verified byte for byte.**
`integration_test/backup_gateway_save_test.dart` is **interactive on purpose** — it opens the dialog
and waits for a human, because MIUI refuses `adb` input injection and no automated run can supply the
tap. It is not part of any suite; it is run deliberately.

| Target | Result |
|---|---|
| Android (Redmi Note 8 Pro, MIUI, API 30) | Saved to Downloads. **4,096 bytes, byte-identical** to the source, pulled back and compared against the generating pattern |
| Windows | Saved through `file_selector_windows`. **4,096 bytes, byte-identical** |

The comparison is against a generated pattern (`(i * 7 + 13) % 256`) rather than zeroes, so a
truncated or empty write could not pass by looking plausible.

**`flutter_file_dialog` is a dated dependency with a review trigger, not merely a caveat**
(project owner, 2026-09-01).

- **The fact.** It applies the Kotlin Gradle Plugin. Flutter has announced that future versions will
  **fail to build** applications using plugins that do.
- **The trigger.** The **first Flutter upgrade that warns about it more loudly or fails outright.**
  At that point: check whether the author has migrated to Built-in Kotlin; if yes, upgrade; if no,
  take the fallback below. Do not wait for the build to break in a release window.
- **The fallback, already specified and unchanged.** App-external storage via `path_provider`:
  no dependency, no permission on any API level, and a path reachable with a file manager. The cost
  is the dialog — the user must go and find the file rather than choose where it lands.
- **What makes the fallback a one-file change**, and the reason this is survivable rather than
  merely noted: `test/data/backup/gateway_boundary_test.dart` fails if anything in `lib/` outside
  `backup_file_gateway.dart` imports `flutter_file_dialog` or `file_selector`. It also fails if the
  gateway *stops* importing them, so it cannot pass vacuously after a rename or a well-meaning
  tidy-up. A note in this log would not have made that true; the guard does.

### Amendment, 2026-09-01 (third) — what a restore does to the encryption key

Raised by the project owner as something that should be **stated rather than implied by the code
path**, and they are right: it is a security property, and a reader who infers it from two call sites
can infer it wrongly in either direction.

**A restore is a decrypt under one key and a re-encrypt under another.**

| | Keyed by | Held where |
|---|---|---|
| The backup container | the **user's password** | nowhere — the user remembers it, and §8 says losing it loses the backup |
| The live database | **this device's random key** | `flutter_secure_storage` — Android Keystore / Windows DPAPI (D-010) |

Rows are read out of the container decrypted under the password, and written into the live database
encrypted under the device key. Two consequences worth naming:

1. **The backup password never becomes the database key.** A restored database is protected by the
   receiving device from the moment the transaction commits — not by a password the user chose months
   ago and may have written down.
2. **The device key is never written into a backup.** A backup carries no key material at all, which
   is what lets it be restored onto a device that has never seen the original. It also means a stolen
   backup file is worth exactly what its password is worth, and nothing more.

The device key is neither read nor handled by the import path. It is already applied to the live
connection before drift issues anything (D-020); import only writes rows through that connection.
**Restoring onto a new device therefore needs no key export, and there is deliberately no mechanism
to move a device key anywhere** — adding one would turn the strongest part of D-010 into a file.

---

## D-072 — A guard that cannot fail is not a guard: the keyboard rule gets a negative control

**Date:** 2026-09-01
**Status:** ACCEPTED
**Closes:** Phase 6 (d)
**Extends:** D-062 (a check must reproduce the conditions the user is in)

**Two findings from the Phase 6 (d) phone-tier pass, one small and one that matters.**

### 1. A password field raises a bigger keyboard, and it was measured

On the Redmi the ordinary text keyboard takes **254.9** logical pixels. The one a **password** field
raises takes **284.0** — a different IME layout, 29 pixels taller. `sheet_keyboard_test.dart` had been
checking the backup password sheet against 255, which is a friendlier keyboard than that sheet ever
actually meets. It now uses the measured number for that sheet.

The sheet passes either way, with the action at 503.6 against a limit of 519.6 — **16 pixels of
margin**, on the tightest sheet in the application, whose §8 warning is the tallest thing anything
puts above a pinned action. Recorded because that margin is the number worth watching if the copy
ever grows.

### 2. The inset was never what made the check bite

Raising the inset **does not fail these assertions**, and that was discovered by trying it: the backup
password sheet passed against an invented **560**-pixel keyboard. The reason is `EditorSheet` working
exactly as designed — it puts the `viewInsets` padding inside its own height cap, so the action lands
on top of whatever keyboard exists, by construction.

**Which means the file was measuring a property it could not fail.** Every assertion in it would have
gone on passing if `EditorSheet` itself regressed, and nothing would have said so. The claim in
`CURRENT_STATE.md` that the guard was "verified to bite" was true of the moment it was written —
against the pre-fix payment sheet — and had no standing proof afterwards.

**The fix is a negative control**: a sheet built the way the defect was, fields and commit action
together in one scroll view, asserted to put its action **below** the fold. It is the same
both-directions design as `gateway_boundary_test.dart` — that one fails if the forbidden import
appears *and* if the sanctioned one disappears, so a rename cannot quietly retire it.

**The general rule, which is the part to keep.** *Verified to bite* is a claim with a shelf life
unless something in the suite keeps proving it. A guard whose subject has since been made correct **by
construction** is the most dangerous kind: it passes, it looks like coverage, and the thing it was
watching moved out from under it. Where a check protects a shape rather than a value, the suite needs
an example of the wrong shape, permanently.

### Amendment, 2026-09-01 — the guard audit D-072 prompted

Every guard in the suite was re-read with this lens: *could this pass while the thing it protects has
regressed?*

**Already falsifiable, no change needed.** All eleven source-scanning guards —
`single_normalizer_path`, `no_hardcoded_strings`, `no_flutter_imports`, `single_calculation_path`,
`logging_path`, `theme_tokens_only`, `field_limit_path`, `domain_boundary`, `single_open_path`,
`soft_delete_usage`, `gateway_boundary` — already carry **two** self-tests each: a matcher control
("the scan would catch a real violation") and an existence control ("the subject is where this test
expects it"). That pairing is the same both-directions design as D-071's gateway guard, and it was
already the house style. `app_table_test` asserts **one pixel either side** of its threshold.
`money_layout_test` compares a measured width against a token, so a wrong token fails it.

**The contrast probe was suspected and cleared, by experiment rather than by reading.** A
deliberately pale label (#9E9E9E on white, independently computed at 2.68:1) was handed to the real
`contrastOfLabel`: it reported **2.68:1 and failed**. The instrument is accurate. It now carries that
case as a **standing control**, so a probe that later drifted onto a border or a shadow — reporting a
healthier ratio than the glyph has — would be caught rather than believed.

**A correction worth recording, because it is the same mistake in miniature.** A first attempt at that
control **reimplemented** the measurement instead of calling the real one, and reported 5.66:1 for the
same label. The reimplementation sampled the whole repaint boundary rather than the label's rect, so
it found a darker pixel elsewhere in the tree. Had it shipped, the suite would have contained a
"control" that certified a number the real probe never produces. **A control that does not exercise
the real instrument is not a control** — it is a second instrument, with its own faults, asserting
about nothing.

**Corollary to D-072, named so it can be cited: a control must call the real instrument, never a
copy of it.** The reimplementation is the dangerous shape precisely because it is easy and looks
diligent — writing the measurement out a second time feels like independent confirmation and is the
opposite. Whenever a check needs a known-answer case, hand that case to the production code path;
if the production path is awkward to call, that is a fact about the design worth fixing, not a
reason to write a second one. Cited since by **D-073**, where a sanity check comparing split
shaping against a hand-rebuilt concatenation reported 62 of 68 strings "differing" — all 62 of them
faults in the rebuild, none in the subject.

**`expectNoCrushedText` was the one guard with nothing proving it could fire**, and every device suite
calls it. Its precondition — `softWrap && !truncatesOnPurpose` — is exactly the kind of thing a future
change to how this application sets `maxLines` could make permanently false, at which point it would
report clean everywhere. `guard_controls_test.dart` now asserts each of its three conditions
individually against a deliberately crushed paragraph.

**And the 16 pixels are now written where the risk lives.** The measurement that matters — a password
field raises a **284.0**-pixel keyboard against an ordinary field's 254.9, leaving the pinned save
button about **16 logical pixels** of slack — is recorded in the **ARB description of
`backupPasswordWarning` itself**, not only here. The person who lengthens that warning is editing a
`.arb` file and has no reason to be reading a decision log.

### Amendment, 2026-09-01 — the ZWNJ cause, corrected: it is the subsetting, not the glyph

> **Superseded 2026-09-02 by D-073.** It is not the subsetting either. The glyph is already wrong
> when `TtfParser.readGlyph` returns it, one stage before the writer — and points 3 and 4 below are
> both mistaken: the outline is not acquired during subsetting, and `arabic.convert` never runs
> (`useArabic` defaults to `!useBidi`, so `bidi.logicalToVisual` does the shaping). The
> "pre-shape and strip" candidate this amendment left open had been tested against a shaper the
> renderer does not call, which is why it appeared to be re-shaped. Kept for the record.

Phase 7 opened on the ZWNJ remedy. **The cause recorded above is wrong in its second half and the
correction matters, because it rules out the obvious fix.**

What D-070 said: *"It is not the font. U+200C is in Vazirmatn's `cmap` at glyph 322 … Only the
control's own glyph is wrong."* The first sentence holds. The second does not.

**What was established mechanically, without rendering anything:**

1. **Vazirmatn's ZWNJ glyph is genuinely blank.** Parsed from `loca`/`glyf`: glyph 322 has length 0,
   as do `.notdef`, space and ZWSP, while alef (681) and Persian zero (901) carry real outlines. The
   parser was validated against those letters rather than trusted.
2. **The `pdf` package's placeholder path is never reached for U+200C.** That path prints a
   diagnostic under asserts, and a probe that renders «پیش‌نویس» prints nothing. So the box is not
   "no font can draw this".
3. **The box is a real glyph in the finished document.** Rendering `ش‌ن` emits **three** glyphs where
   `شن` emits two, and in the embedded subset **all three carry outlines** — 24 bytes each, the same
   size as the letters beside them. A blank source glyph comes out of the package's subsetting with
   an outline on it.
4. **`arabic.convert` has no concept of ZWNJ.** It is not in its alphabet, which is *why* the join
   breaks: an unknown character between two letters stops them joining. That is accidental
   correctness, and it is also why simply deleting the ZWNJ re-joins them into «پیشنویس», a
   misspelling rather than a near-miss.

**So the remedy cannot be a substitution.** Every zero-width candidate either fails to break the join
(U+FEFF re-joins the letters, verified) or is itself a character that must survive subsetting — and
point 3 says a blank character does not survive it. Sending *any* invisible character through this
renderer is unsafe.

**The candidate that remains** is to shape the text ourselves with the ZWNJ present, then strip it and
hand the renderer already-shaped presentation forms. A first mechanical check is **not encouraging**:
the prepared string emits two glyphs, correctly one fewer, but their outlines match neither the
ZWNJ version's letters nor the joined version's — so the package appears to re-shape text that is
already shaped. **Unverified either way**, and it must be verified on a rendered page, not inferred
from glyph counts: the owner's first requirement on this remedy is that the join break be confirmed
visually, ش in final form and ن in initial form.

**Blocked on a renderer.** The browser extension that rasterised probes 1–4 disconnected mid-session,
and every remaining question about this is a question about what the page *looks like*. The glyph-level
work above is what could be settled without one, and it is worth the correction on its own: it moves
the fault from "a wrong control character" to "a blank glyph does not survive subsetting", which is a
different problem with a different set of fixes.

---

## D-073 — The ZWNJ mark is `readGlyph` reading the *next* glyph, and the remedy is to cut the run

**Date:** 2026-09-02
**Status:** ACCEPTED
**Corrects:** D-070 finding 3 (twice — the original text and its D-072 amendment), and D-070's
"what to use instead" list.
**Gates:** Phase 7's first commit.

Phase 7's blocking item — «پیش‌نویس» printing with a mark where the ZWNJ is — is now understood at
the byte level, confirmed on a rendered page, and fixed. **The cause is not the font, not the
character, and not the subsetting.** It is a missing emptiness check in the package's glyph reader,
and it is a **class** of fault rather than one character.

### The cause, proven

`TtfParser.readGlyph(index)` computes `start = glyfTableOffset + glyphOffsets[index]` and parses the
outline there. **It never checks whether the glyph is empty** — that is, whether
`glyphOffsets[i] == glyphOffsets[i + 1]`. For a zero-length glyph, `start` is the offset of the
**next** glyph, so the reader returns that glyph's outline under this glyph's index.

Measured in Vazirmatn, printed by `bin/probe10.dart`:

| glyph | own length | what `readGlyph` returns | so the character draws |
|---|---|---|---|
| 322 ← **U+200C ZWNJ** | 0 | 24 bytes, **byte-identical to glyph 323** | **U+00E0 «à»** |
| 320 ← U+200D ZWJ | 0 | 90 bytes, glyph 321 | U+20AA «₪» |
| 319 ← U+200E LRM | 0 | 90 bytes, glyph 321 | U+20AA «₪» |
| 318 ← U+200F RLM | 0 | 90 bytes, glyph 321 | U+20AA «₪» |
| 0 ← `.notdef` | 0 | 56 bytes, glyph 3 | whatever glyph 3 is |

`readGlyph(322)` and `readGlyph(323)` compare **equal byte for byte**, and glyph 323 is the glyph
for `U+00E0`. On the rendered page the mark between ش and ن is an **a with a grave accent**, and a
control page printing `aàa` in the same font at the same size shows the same shape. It is not a
missing-glyph box and never was.

**Why nobody hit this with spaces.** `TtfWriter` special-cases exactly one character —
`if (char == 32)` — and hands the subsetter a genuinely empty glyph for it. That is the workaround
for the only zero-length glyph anyone had run into. It is also why the "blank glyphs come through
subsetting fine, look at spaces" objection is not an objection: `RichText` splits on `\s` and
advances `offsetX` for spaces, so **a space is never drawn as a glyph at all**.

### Three corrections to what is written above in D-070 and D-072

1. **D-072's amendment said the subsetting gives a blank glyph an outline.** It does not. The
   outline is already wrong when `readGlyph` returns it, before the writer sees it. The observation
   that fed that conclusion — "in the embedded subset all three carry outlines, 24 bytes each" — was
   correct, and was read one stage too late in the pipeline.

2. **D-072's amendment said `arabic.convert` breaks the join, and called that accidental
   correctness.** `arabic.convert` **never runs.** `options.dart` defines
   `useArabic = bool.fromEnvironment('use_arabic', defaultValue: !useBidi)` and `useBidi` defaults
   to `true`, so the widget path is `bidi.logicalToVisual` — the `bidi` package's Unicode
   Bidirectional Algorithm, which does the shaping. This is not pedantry: **the "pre-shape and
   strip" candidate D-072 left open was built on `arabic.convert`**, so it pre-shaped with a
   function the renderer does not use and then had its output reshaped by the one it does. That is
   why probe 8's prepared word came out reversed and garbled. The candidate was not defeated by the
   package "re-shaping already-shaped text"; it was tested against the wrong shaper.

3. **D-070's "what to use instead" list names U+200E LRM as verified working. Withdraw it.**
   Measured three ways — the `ToUnicode` tables of three uncompressed documents, identical `Td`
   offsets, and a **zero-pixel** raster diff — `pw.Text` given «پیش‎نویس» renders **identically to
   «پیشنویس»**: the LRM is deleted (the Unicode Bidi Algorithm's rule X9 removes explicit
   formatting characters) and the letters then **join across the boundary**. So LRM is not a
   join-breaker, and the mechanism that makes it look harmless — silent deletion — is the same one
   that makes it useless as an isolation mark. Nothing had been verified about LRM on a page; the
   earlier entry recorded an inference from the `cmap`.

### The rule that replaces "do not send a ZWNJ"

**No rune whose glyph is zero-length in the bundled font may be handed to the renderer.** In
Vazirmatn that is every zero-width control this application might reach for — U+200C, U+200D,
U+200E, U+200F — and the failure mode is *drawing a different letter*, silently, with zero advance
width so it does not even disturb the layout. Stated per-character, the rule would have to be
restated for the next font and the next control.

### The remedy: cut the run at the ZWNJ; substitute nothing

The ZWNJ's only job in the shaping is to stop two letters joining. A run that **ends** stops them
joining just as well, and costs no character:

```
'پیش‌نویس'  ->  ['پیش', 'نویس']   each shaped on its own
```

`bidi.logicalToVisual` is applied **per span**, so the two pieces never meet a shaper together:

```
'پیش‌نویس'  whole  ->  FEB2 FBFE FEEE FEE7 [200C] FEB6 FBFF FB58
'پیش'       alone  ->                              FEB6 FBFF FB58
'نویس'      alone  ->  FEB2 FBFE FEEE FEE7
```

The pieces reproduce the ZWNJ shaping **exactly** — ش in final form (FEB6), ن in initial form
(FEE7) — with the control character gone. D-070's requirement 1 is met by construction and
confirmed on the page: ش carries its final tail and ن its initial form, and the joined control
«پیشنویس» is visibly a different word.

**And it is a `WidgetSpan` atom, not a bare span split.** Both forms were rendered and compared at
seven column widths:

| form | glyphs | order | line break at the ZWNJ |
|---|---|---|---|
| two `TextSpan`s | correct | correct | **splits the word across lines at 4 of 7 widths** |
| `WidgetSpan(Row(pieces))` | correct | correct once a reversal was dropped | **never** |

A bare span split makes the ZWNJ a permitted break point, and a word broken across lines at its
half-space is a misspelling of a different kind. The `WidgetSpan` holds the word together and
overflows its box instead when it genuinely cannot fit, which is what any unbreakable word does.
Note that `pw.Row` has no `textDirection` and the line's RTL mirroring does **not** reach inside a
`WidgetSpan` child, so the pieces go in **logical** order inside the `Row` — reversing them, which
looked obviously right, produced «نویس‌پیش».

### Tested over the real ARB, not over examples — D-070 requirement 2

`bin/probe18.dart` reads `lib/core/localization/arb/app_fa.arb` and takes **every** entry
containing U+200C. There are **68 of 356** — 19% of the application's strings.

```
unsafe through the current path : 68 / 68
unsafe through the split path:  0 / 68
```

where *unsafe* is the class rule above — the entry shapes to at least one rune whose glyph is
zero-length — not "contains a ZWNJ". Both variants were then rendered and rasterised and the pages
read side by side: «پرداخت‌نشده», «همین‌جا», «مشتری‌ای», «می‌کنید» each carry an **à** in the current
path and are correct in the fixed one, with every other word on the page in the same place.

**One check written for this was wrong, and is recorded because of D-072.** A first sanity control
compared the split shaping against a hand-rebuilt concatenation of the whole, and reported 62 of 68
"differing" — because it had reimplemented the renderer's word-order handling, badly. That is
exactly D-072's corollary about the contrast control: *a control that does not exercise the real
instrument is a second instrument, with its own faults.* It was replaced by rendering both pages and
diffing the pixels.

### Requirement 3: this is not the answer to finding 2

Finding 2 — a value carrying internal bidi-neutral characters sharing one run with RTL text — is
untouched by any of this. It is answered by **D-070's contract rule 2** (the label and the value are
separate widgets, never concatenated into one string), which is still owed and is a separate piece
of Phase 7. The ZWNJ remedy removes control characters that were never the subject of finding 2.

### What Phase 7 must carry out of this

1. A ZWNJ-safe text builder in the renderer, taking a string and producing the atom described above.
   **Every** Persian string the document draws goes through it — labels, statuses, party fields,
   line titles, notes — because 19% of the ARB and an unknown share of customer input contain a ZWNJ.
2. **The class guard, falsifiable**: over the bundled font, assert that no rune the renderer is
   handed maps to a zero-length glyph. Fed a raw ZWNJ it must fail, and that negative control ships
   with it (D-072).
3. The ARB sweep above as a test rather than a probe: all 68 entries, asserted through the real
   renderer path.

### Method note

Rendered locally with `Windows.Data.Pdf` — see `tools/pdf_raster/`, added here so this loop never
again depends on a browser connection. D-070's rule that the probe reads the pixels rather than the
content stream held, and paid twice: the à was identified by looking at it, and the LRM deletion was
found by a raster diff that came back zero after the source had been read three times without
finding it. The dependency still has not entered `pubspec.yaml`; all of this ran in the scratchpad
probe package.

---

## D-074 — Phase 7 (a): the `pdf` dependency, what it costs, and the two boundaries it needs

**Date:** 2026-09-02
**Status:** ACCEPTED
**Opens:** Phase 7
**Implements:** D-073's remedy, and D-070's contract rules 1 and 2 at the view-model boundary.

### The dependency, and the entry-gate measurement

`pdf: 3.13.0` is in `pubspec.yaml` with the §2 justification, including — unusually, and
deliberately — a written record of the **two faults in it that this application works around**, so
that a future reader does not remove a workaround they cannot explain.

It pulls **ten** transitive packages: `archive`, `barcode`, `bidi`, `image`, `path_parsing`,
`petitparser`, `posix`, `qr`, `xml`, and `crypto` (already present). That is a wide addition for one
feature and is accepted because the alternative — a platform renderer per target — is three
implementations of the thing §12 exists to keep single.

The Phase 7 gate requires the size baseline to be taken **before** the dependency and re-taken
after. Baseline on `60b5cd5`, this measurement on the working tree with `pdf` resolved:

| Measurement | Baseline (`60b5cd5`) | With `pdf` | Δ |
|---|---|---|---|
| Android APK, arm64-v8a, release | 21,520,524 | **21,653,926** | **+133,402** (+0.62%) |
| Android APK, armeabi-v7a, release | 19,096,744 | **19,230,142** | +133,398 (+0.70%) |
| Android APK, x86_64, release | 23,138,664 | **23,272,066** | +133,402 (+0.58%) |
| Windows release bundle | 32,876,606 (17 files) | **33,116,830** (18 files) | **+240,224** (+0.73%), +1 file |
| Android cold start | ~~1,401 ms median~~ **WITHDRAWN, D-078** | **TAKEN** | HEAD 343 ms vs the baseline commit's own 352 ms, measured paired in one session. The stored 1,401 ms does not reproduce on the commit it was taken on |

**This delta is a floor, not the cost, and the difference matters.** Nothing reachable from
`main()` imports `core/pdf/` yet — the renderer does not exist — so Dart's AOT compiler tree-shakes
almost all of `package:pdf` out of the snapshot. What is measured here is the cost of the
dependency being *resolved and present*. The number the gate actually asks for is the one taken
**on the commit immediately after the renderer works**, and it is still owed. Recording this
interim point anyway, because a third of a megabyte of unexplained growth six commits from now
would otherwise be attributed to the renderer.

**Method note, worth more than the numbers.** The first Windows measurement came back at
**120,286,782 bytes over 19 files** — a 3.7× jump that no pure-Dart package could cause. The
Release directory held a stale **`data/flutter_assets/kernel_blob.bin` of 87,169,952 bytes**, a
JIT artifact left over from an earlier debug build, because `flutter build` does not clean the
output directory. **A bundle size taken without `flutter clean` first is not a measurement.** The
figure above is from a clean rebuild, verified by asserting `kernel_blob.bin` is absent. The
baseline was evidently taken clean, since it is in the same range; had it not been, the comparison
would have been meaningless in the other direction.

The one extra file is not attributed: the baseline recorded a count and not a listing, so saying
which file appeared would be a guess.

### Two boundaries, because there are two faults

D-073 and D-070 finding 1 look like the same problem — "a control character breaks the document" —
and have opposite remedies. Conflating them was going to produce a fix that half-worked.

| | D-073, the font fault | D-070 finding 1, the shaper fault |
|---|---|---|
| the characters | U+200C and friends: **mapped, but the glyph is empty** | U+2068/U+2069: **not in the `cmap` at all** |
| what goes wrong | draws the *next* glyph — `à`, at zero advance | the run loses its **last character**, silently |
| can a font-derived set see it? | yes, that is exactly what it derives | **no** — nothing empty to find |
| the remedy | **cut** the run there; the character meant something | **delete** it; the document has no use for it |
| where it lives | `core/pdf/safe_text.dart` | `core/pdf/document_text.dart` |

Neither remedy fixes the other's fault. Cutting at a U+2068 would break a join that should not
break; deleting a U+200C yields «پیشنویس», a misspelling.

### `FontGlyphSafety` — the class guard, derived from the font

Reads `head`, `maxp`, `loca`, `cmap` and `hhea` out of the bundled font and answers one question:
which runes select a glyph with no outline of its own.

**Derived rather than listed, at the owner's direction, and it immediately paid.** Every written
account of this fault — D-070, D-072, D-073 — named four characters: ZWNJ, ZWJ, LRM, RLM. The
derivation over Vazirmatn returns **eleven**:

```
U+0000  U+200B  U+200C  U+200D  U+200E  U+200F  U+202A  U+202B  U+202C  U+202D  U+202E
```

ZWSP and the five bidi embedding and override controls were in the hazard the whole time and nobody
wrote them down. A hardcoded list would have been wrong on the day it was committed, and wrong
again the day the font is updated. `font_glyph_safety_test.dart` asserts the four *and* the seven,
under a test named for the argument.

**Whitespace is excluded, and that exclusion is the reason the fault survived so long.** U+0020 has
an empty glyph in most fonts and renders perfectly — because `RichText` splits every span on
`RegExp(r'\s')` and advances the pen for the empty pieces, so a space's glyph is never read at all.
"Empty glyphs are fine, look at spaces" is the natural inference and it is wrong.

**It parses the font itself rather than reusing `package:pdf`'s parser**, which looks like
duplication and is the opposite: a guard derived from the reading it is guarding agrees with it by
construction (D-072). The agreement is asserted instead — every one of the **811** runes the
package's `charToGlyphIndexMap` holds maps identically here, expressed as `unknown.isEmpty` rather
than as a threshold somebody chose. The file also carries a **subject control**: it asserts that
`readGlyph` still returns the following glyph for an empty one, so if a future `pdf` fixes the bug,
the suite says so rather than carrying a workaround for a defect that no longer exists.

### `SafeText` — the remedy, as an atom

Cuts a string at every unsafe rune and emits the affected **word** as a
`WidgetSpan(Row(pieces))` — indivisible, so a line break cannot land inside it (D-073 measured a
bare span split breaking «پیش‌نویس» at four of seven column widths). Only words that carry a
control become atoms; everything else stays ordinary, wrappable text.

**The atom's vertical placement is read from the font, not tuned by eye.** A `WidgetSpan` is
positioned by its box and surrounding text by its baseline, so the box drops by the font's
descent — `hhea.descender / head.unitsPerEm`, **−985 / 2048 = −0.4810** for Vazirmatn. An earlier
probe had guessed −0.22 and it looked acceptable at one size; the rendered check at 9, 12, 18 and
28 pt shows the derived value sitting the atom exactly on the line, with «قبل» and «بعد» either
side of it as the control.

### `DocumentText` — the view-model boundary, as a type

D-070's contract rule 1 says no control characters reach the renderer. A `stripControls(…)` helper
would enforce that only where somebody remembered to call it, so it is a **type** instead:
`SafeText` accepts `DocumentText` and nothing else, and the only way to obtain one is through
`DocumentTextBoundary`. A raw `String` from the screen layer cannot reach the renderer.

The removal set is `FontGlyphSafety`'s derived set **minus the join-breakers** — U+200C and U+200B,
which mean "do not join" and are honoured by cutting rather than deleting — **plus** the isolates
and `U+061C`, which a font-derived set cannot see because Vazirmatn does not map them. The
two-character exception is the one hardcoded list in any of this, and it is hardcoded because it is
a fact about Unicode semantics rather than about which glyphs happen to be empty. No amount of
reading `loca` produces it.

`document_text_test.dart` exercises **the application's own formatters** rather than imitating
them: it takes `formatIdentifierForDisplay('0069543210')` — the real §9 screen formatter — asserts
that its output really does carry U+2068/U+2069, and then asserts all ten digits survive the
boundary. That is the D-072 corollary applied: the control calls the real instrument.

### Rule 2, as far as a type can carry it

D-070's contract rule 2 — the label and the value are separate widgets, never concatenated — is
what makes finding 2 *disappear* rather than need a remedy, since every field in probe 3 rendered
correctly bare and scrambled only when sharing a run with its own Persian label. `'تلفن: ' + number`
is the whole bug, and `'$label: $value'` is one keystroke away at every call site.

Dart cannot forbid interpolation, so it is made **loud**: `DocumentText.toString()` returns
`DocumentText(11 chars)` rather than the text. A page built by concatenation shows a wrapper — wrong
immediately and wrong in the proof — instead of a phone number that is subtly reordered and only
for values containing a space or a `+`.

**This is half of rule 2 and is stated as half.** The other half is the field-rendering helper that
emits label and value as two widgets, and it lands with the document layout rather than now: a
field widget with no document to sit in is the speculative abstraction §15 forbids.

### What this increment does not contain

No document. No `InvoiceDocumentGenerator`, no page layout, no view model, no generated file. This
is the text layer and its two boundaries, which is what D-073 said Phase 7's first commit should
be. **`ARCHITECTURE.md` §B.13 claimed the `InvoiceDocumentGenerator` interface was defined in
Phase 1; it never was** — `grep` finds it in the documentation and nowhere in `lib/`. Corrected
there rather than quietly satisfied here, per §17's rule against documenting architecture that does
not exist.

**1137 tests pass**, was 1092 (+45). `flutter analyze` clean.

---

## D-075 — What a draft prints, what a pre-snapshot invoice prints, and why both were chosen against the house style

**Date:** 2026-09-02
**Status:** ACCEPTED (owner, both as recommended)
**Decides:** the two product questions Phase 7 (b) could not be built without.

Two cases where the document has to state something the data does not fully support. Both were put
to the owner as proposals with recommendations, and both were accepted as recommended.

### 1. A draft prints, and is marked unmissably

A draft has neither of the things that make a document a document: **no invoice number** (D-048
allocates on issue, so that abandoning a draft does not spend one) and **no party snapshot** (D-052
— a draft deliberately follows the live customer record). Its totals can also still change.

An **unmarked** draft is therefore the failure D-004 and D-052 exist to prevent, arriving in a new
place: the customer holds a document that later disagrees with the invoice, under a number they
never saw.

**Refusing to print one was the safer and cheaper option and was rejected.** پیش‌فاکتور is an
ordinary, common document in this market. Refusing would push the user to issue an invoice and then
cancel it — **spending a number permanently** — which is a worse outcome forced on them by our
convenience (owner).

**The marking is a filled band, not a line of prose.** The requirement the owner set is that
somebody *holding* the page knows it is not final **without reading it closely**. A sentence in the
body text does not do that. `invoiceDocumentDraftBanner` — «پیش‌نویس — سند نهایی نیست» — is set at
16 pt bold, reversed out of a solid dark band running the full content width, directly under the
header rule. The number field reads «بدون شماره», reusing `invoiceNumberPending`, which already
exists for exactly this absence and is deliberately not a repeat of the status badge.

*(It also happens to be the hardest test of the D-073 atom on the page: «پیش‌نویس» carries a ZWNJ
and is the largest type the document sets.)*

### 2. A pre-snapshot invoice prints the live record, with one factual line

For an invoice issued before schema v3, the application genuinely **does not know** who the
document was addressed to. Printing today's record silently is a fabrication: rename the customer,
reprint, and the document names a different party than the original did.

**Refusing was again the house-style option and was again rejected.** It would mean a user simply
cannot print their older invoices — and that data is real and correct. What is unknown is only
whether the customer's details have changed since (owner).

**The renderer computes nothing new.** `partyProvenanceOf` already derives four cases and is tested
(D-052). They map to the document at one line:

| provenance | what the document prints | says |
|---|---|---|
| `snapshotMatchesRecord` | the snapshot | nothing |
| `snapshotDivergedFromRecord` | the snapshot | nothing — the document is right, and the divergence is the app user's business, not the reader's |
| `draftFollowsRecord` | the live record | nothing — the draft band has already said nothing is final |
| `issuedWithoutSnapshot` | the live record | **one line** |

The line is `invoiceDocumentPartyFromRecord`: «مشخصات خریدار از پروندهٔ فعلی مشتری خوانده شده است.»
Set as a muted caption at the foot of the party block. It is not an apology and not a warning — it
states where the details came from, which is true, and which is the thing a reader would otherwise
assume wrongly.

### Why both went against the house style, recorded because the pattern is otherwise consistent

This project refuses rather than invents, repeatedly and deliberately: «ثبت‌نشده» where a figure was
never recorded (D-055), the money engine surfacing a clamp rather than absorbing it (D-027), the
backup import refusing a container it cannot verify (D-069). Both answers here go the other way, and
the owner asked for the reason to be written down rather than left as an exception nobody can
account for.

**The reason is that refusing costs the user a document they legitimately need, and neither answer
invents anything.** That second half is what distinguishes these from the cases above. «ثبت‌نشده»
exists because printing a zero would be a *claim about the sale* that the data does not support. A
marked draft claims nothing — the band says exactly what the document is. A pre-snapshot invoice
claims nothing either — the line says exactly where the details came from. In both cases the
document is telling the truth about its own limits, which is what the refusals were protecting in
the first place.

Refusing would have been the *cheaper* option in both cases. That is worth stating plainly: the
house style is not "refuse", it is "never assert what you do not know", and refusing is only its
cheapest implementation.

---

## D-076 — Phase 7 (b): the one template, and where the seller block is not

**Date:** 2026-09-02
**Status:** ACCEPTED
**Implements:** §12's boundary, D-075's two answers, and D-068's one-template reduction.

The invoice prints. Header, party block, lines table, totals — on A4, RTL, in Vazirmatn, at every
rung of the D-057 ladder, over one page and over two.

### The shape

```
features/invoices/document/
  invoice_document_view.dart          the view model: DocumentText and nothing else
  invoice_document_view_builder.dart  InvoiceDetail + AppStrings -> the view
  invoice_document_generator.dart     the interface, and the failure type
  pdf_invoice_document_generator.dart the one template
```

The flow is one-way and each step drops something: `InvoiceDetail` (models, `Money`, `DateTime`) →
the builder → `InvoiceDocumentView` (`DocumentText` only) → the generator (layout only). The
renderer never sees a `Money`, so it **cannot** recompute a total, and never sees a raw `String`, so
it **cannot** print an `à`.

### `InvoiceDocumentGenerator` exists now, and is the interface §B.13 wrongly claimed

D-074 withdrew the ARCHITECTURE claim that Phase 1 had defined it rather than quietly writing the
file to make the claim true. It is written here because there is now a renderer to put behind it. It
throws `InvoiceDocumentFailure` with a **reason code rather than a message**, because §7 forbids a
raw exception string reaching the user and the Persian sentence is the presentation layer's choice.
§12's rule that the boundary fails loudly rather than silently producing nothing is the reason it
throws at all: a zero-byte file that a save dialog happily writes is a defect the user discovers
days later, opening the attachment they sent.

### What the page decides, and what it does not

**Decided in the builder, once:** which figure is printed, which row is omitted, which date format,
which digits, whether the party note appears. **Decided in the renderer:** where things sit. There
is no arithmetic in either file; the summary rows come from `InvoiceSummaryFigures`, which D-056
already described as "the beginning of" this view model.

Three rules the page follows, each with a reason that has already cost this project something:

* **A zero row is omitted, not printed as «۰».** A discount line reading zero invites the reader to
  look for a discount that was never given; a tax line reading zero is a statement about the
  business's VAT registration rather than about this sale.
* **An unrecorded gross is an admission, never a zero** (D-055), and carries **no unit** —
  «ثبت‌نشده تومان» is nonsense, because there is no amount for the unit to qualify.
* **Every money column carries «تومان».** §9 is explicit that the unit is always shown and never a
  bare number. The first draft had `gross` as a bare `DocumentText` and the rendered page showed it
  immediately: one column of figures with no unit, between two columns that had it. The alternative
  — the unit once in the column heading, bare digits in the cells — is conventional on Iranian
  invoices and costs less ink; it is **not** taken, because it is a reinterpretation of §9 rather
  than a reading of it, and that is the owner's call and not the renderer's.

### The table geometry is declared, per D-065

531 pt of content width, of which the five fixed columns take 350 (ردیف 26, تعداد 62, three money
columns at 88) and the description takes the remaining **181**. Declared as tokens and asserted:
`invoice_document_view_test.dart` fails if the fixed columns ever grow past the content width or the
description falls below 120 pt. D-065's lesson is that a crushed column **lays out successfully and
reports no error** — the on-screen document table shipped one at 21.6 pt — so the only thing that
catches it is asserting the number.

### Two things the rendered page corrected that no test had caught

Recorded because both were invisible until the pixels were read, which is the method D-070
established and this phase keeps being paid by:

1. **The `مبلغ کل` column printed bare digits** while the two money columns either side printed
   «تومان». A type error in the view model, not a layout bug: `gross` was a `DocumentText` because
   the admission case made a bare string look reasonable while writing it.
2. **The demonstration invoice did not reconcile.** The fixture set the grand total and the tax and
   discount rows independently, so the page showed a summary that did not add up. Nothing was wrong
   with the renderer — which is exactly the problem: **a demonstration page that cannot be checked
   with a pencil is one where a real reconciliation defect would look like more of the same.** The
   fixture now satisfies `gross − discount + tax == grandTotal`, and the two-page render shows
   ۲٬۵۰۰٬۰۰۰ − ۱۲۵٬۰۰۰ + ۲۳۷٬۵۰۰ = ۲٬۶۱۲٬۵۰۰.

### The gap: there is no seller block, because there is no seller

**`AppSettings` and the `settings` table hold no business identity at all** — no name, no address,
no کد اقتصادی, no phone. `grep` for `businessName`, `sellerName` or `فروشنده` across `lib/` returns
nothing. A conventional Iranian فاکتور فروش carries both فروشنده and خریدار blocks, and this
document carries only the buyer.

**Nothing is invented to fill it.** A placeholder seller block on a customer-facing document would
be the one thing this phase must not do. The scope the owner set for (b) was "header, party block,
lines table, totals", which this delivers exactly; the seller block was never in it.

**Closing it is a schema change**, and is therefore a decision rather than an oversight: four
nullable text columns on `settings` (name, economic ID, address, phone), schema v5 with its
migration test, four fields on the settings form, and the device proof D-055's ladder pattern
requires. Raised with the owner rather than absorbed.

### Verification

`flutter analyze` clean. **1159 tests pass**, was 1137 (+22).

Rendered and read at: the ladder ceiling (۱۰۰٬۰۰۰٬۰۰۰ تومان), all four rungs, a draft, a
pre-snapshot invoice, and a 28-line invoice over two pages — where the repeated header carries the
invoice number and the footer counts `2 / 2`. The RTL column order came out right without
intervention: `pw.Table` places its cells in the page's direction, which was checked on the page
rather than assumed, because the wrong order would also have looked deliberate.

**The theme guard caught the one literal that got past review** — `width: 1` on the header rule the
whole page hangs from. Tokenised. `theme_tokens_only_test.dart` scans this folder like every other
one, which is the argument for the guard scanning by directory rather than by allow-list.

### Still owed, and not owed to (b)

* **The real size measurement.** Nothing reachable from `main()` imports `core/pdf/` yet, so the
  AOT compiler still shakes the renderer out and D-074's +133 KB remains a floor. Confirmed rather
  than assumed: (b) adds the whole document layer and the arm64 release APK is **byte-identical at 21,653,926**.
* **The Android cold-start re-measurement**, which needs the Redmi on the cable.
* Both land with **(d)**, which is what makes the document reachable.

## D-077 — Schema v5 and the seller block: what an empty seller prints, and what it blocks

**Date:** 2026-09-02
**Status:** ACCEPTED
**Closes:** D-076's gap. **Supersedes** nothing; D-068's one-template reduction still stands.

An invoice with no seller is not an invoice — the user cannot hand it to a customer, which made
the whole phase undeliverable. That outweighed the risk of a schema change with two days left,
against three successful migrations and a settled pattern (owner).

### The scope, as set and as delivered

Four nullable text columns, the migration with its test, the four settings fields, the device
proof. **No logo, no registration number, no customisation** — D-068's reduction is untouched.

```
settings.seller_name         TEXT(160) NULL
settings.seller_economic_id  TEXT(20)  NULL
settings.seller_address      TEXT(500) NULL
settings.seller_phone        TEXT(20)  NULL
```

The lengths are their customer-side counterparts' exactly (`SellerLimits`, checked by
`field_limits_test.dart` at the column). A seller whose نشانی had to be shorter than their
customer's would be an arbitrary asymmetry, met only by the users whose own address is longest.

### The migration writes nothing, and that is the decision

`migrateV4ToV5` is four `_addColumnIfAbsent` calls and a `foreign_key_check`. **No backfill and no
`withDefault`.** D-055's step filled its columns because they were arithmetic over figures the row
already carried, so leaving them empty would have lost information the database held. These are the
opposite: the database has never been told anything about the user's business, so there is nothing
to compute and nothing to copy — D-052's reasoning, reached again from the other direction.

**A `withDefault` was the one available option that would have produced a document**: a fabricated
seller block, on the page the customer keeps, that nobody would ever question because it looks
exactly like a real one. The migration suites assert the **absence** as hard as the earlier ones
assert their figures.

`_addColumnIfAbsent` is used although `settings` is rebuilt by no step and a plain `addColumn` would
work today. It costs a pragma here; the step that eventually rebuilds this table would otherwise
turn a v1 upgrade into `duplicate column name` **on open**, for the users furthest behind and for
nobody else.

### Question 1 — what the document prints when the seller is empty

**Omit the block entirely, and make it impossible to be surprised by.** The owner's view, adopted,
with the second half made concrete.

A heading over four blank lines is worse than no heading: on a printed page a labelled empty line
reads as data that *failed to print*, not as data that was never given — so it converts an
unconfigured application into an apparently broken one. When there is no seller the buyer block
takes the full content width rather than sitting in half a page with a hole beside it; the layout
**changes shape rather than leaving a gap**, which is D-065's rule applied to a block.

The "without being told" half is answered where the user can act on it, not on the document:

* The settings screen carries the seller section **first**, above invoicing and backup. Every
  database reaches v5 with it empty, so it is the one section of that screen every existing user
  has something to do in.
* One sentence states the consequence — «تا زمانی که نام کسب‌وکار را وارد نکنید، بخش «فروشنده» روی
  فاکتور چاپ نمی‌شود.» — hung off the **name row**, so filling the field removes the sentence. A
  notice that stays put after it has been answered is one the user learns to read past.
* `InvoiceDocumentView.seller` is null in exactly this case, so **(d)'s print path can see it**
  without re-reading the settings row. That is where a print-time notice belongs, and (d) is where
  printing becomes reachable.

### Question 2 — whether an empty seller blocks issuing or printing

**No, neither.** The owner's lean, agreed without reservation. It is the user's document and their
call; a پیش‌فاکتور or an invoice from a sole trader who has not filled a form in is still the
document they meant to produce, and blocking issue over a settings field would strand them mid-flow
in the one place the application must not. D-075 already refused to withhold a draft for the
analogous reason.

What replaces a block is the prompt above, which is why the prompt is a requirement rather than a
courtesy.

### The one rule that *is* enforced: a name, or nothing

**The block prints if and only if there is a business name.** `SellerIdentity.isPrintable`, not
`isNotEmpty`, and the difference is the ruling: an identity carrying a کد اقتصادی and a telephone
has something in it and still cannot head a block. «فروشنده» over an economic ID alone identifies
nobody and gives the reader nothing to act on.

So the form **requires the name as soon as any other seller field carries a value** — reported,
never clamped (D-027) — and the error says how to get out of the rule as well as into it:
«...برای حذف کامل این بخش، همهٔ فیلدها را خالی بگذارید.» A required-field rule with no stated way
out is a trap, and a user who wants no seller block must be able to empty one.

The builder re-checks anyway. A value that arrived before the rule existed, through a restored
backup, or through a future sync never met the form, and that is not the document layer's to assume
away.

### `SellerIdentity` is a value object because `copyWith` cannot clear a field

Not tidiness. With `String? sellerName` on `AppSettings`, `copyWith(sellerName: null)` is
indistinguishable from *leave it alone* — so a user who emptied the name would have the old one
written straight back, **silently**, and would discover it on the next document they printed.
Replacing the whole object makes clearing the ordinary case rather than a special one. Pinned by
test at the column, on the VM and on the device, because that is where the old value would survive.

Blanks fold to null in `normalized()`, called at the sheet and again at the repository: a name of
three spaces satisfies every `isNotEmpty` check on the way in and prints as a blank line.

### Two things the rendered page corrected that no test had caught

The phase's method paying for itself a third time. Both looked entirely fine in the source.

1. **Both نشانی lines ran off their block and were clipped mid-word** — «...پلاک ۴۵۶، واح». `_field`
   was a `mainAxisSize: min` row with no flexible child, so the value took its intrinsic width and
   **overflowed with no overflow, no error and no failing test**. It was invisible while the buyer
   block had the full 531 pt and appeared the moment it had 261.5. Fixed with a `fill` flag putting
   the value in an `Expanded`; the default stays off, because the header number and the meta dates
   sit beside a `Spacer` and must take their natural width. Same class as D-065's 21.6-point column.
2. **`pw.Table` lays column 0 out at the LEFT even under `textDirection: rtl`.** The first attempt
   declared the seller first, intending the right-hand side, and printed it on the left — where it
   looks entirely deliberate. The blocks are now declared buyer-then-seller so the reader meets the
   seller first. **This also means D-076's claim that "the RTL column order came out right" is
   wrong about the lines table**, which prints ردیف at the far left and جمع سطر at the far right —
   the reverse of the Iranian convention. Recorded as known issue 24 rather than fixed: it is an
   accepted increment and outside the scope the owner set.

### Why the blocks are side by side, and why it is a `Table`

Side by side costs no page height on a page whose whole job is to show the lines, and is how an
Iranian invoice is conventionally set. That trade is only sound if each half is genuinely wide
enough, so `InvoiceDocumentLayout.partyBlockWidth` is **declared and asserted** against the longest
unbreakable run a block can hold — a fourteen-digit کد اقتصادی beside its label — rather than left
to `Expanded` to work out. D-065's lesson is that a block laid out too narrow does not overflow or
report anything; it renders one glyph per line.

A `pw.Row` of two `Expanded`s with `crossAxisAlignment: stretch` gives the row an **unbounded
height** and `MultiPage` refuses the page outright — *"Widget won't fit into the page as its height
(Infinity) exceed a page height"*. Found by rendering, not by reading. Dropping `stretch` compiles,
renders, and looks wrong: two bordered boxes of different heights side by side read as one of them
having failed to finish. `package:pdf` has no `IntrinsicHeight`, so the pair is a one-row
`pw.Table` with `TableCellVerticalAlignment.full` and fixed column widths.

### A fixture standing in for a document a human checks must be internally consistent

Generalised from D-076's second finding, at the owner's direction, and **now a rule in the project spec** rather than an observation about one page.

The demonstration invoice did not reconcile: the fixture set the grand total and the tax and
discount rows independently. Nothing was wrong with the renderer, **which is exactly the problem** —
a page that cannot be checked with a pencil is one where a real reconciliation defect would look
like more of the same, so the fault the fixture hides is the fault the fixture exists to expose.

This is not a fact about invoices. It applies to any fixture standing in for an artifact a human
inspects: a seeded database a screen is judged from, a backup summary, a rendered page. The seller
fixture in the render suite follows it — a fourteen-digit کد اقتصادی because that is the real
length and the run that would wrap first, Persian at the length real data reaches, and a ZWNJ in the
address because 19% of this application's own strings carry one.

### The APK size figure is a size, not a fingerprint — a correction

D-074 and D-076 recorded the arm64 release APK as **byte-identical** at 21,653,926, offered as proof
that nothing from `main()` imports `core/pdf/`. The seller block reproduces the number exactly:
21,653,926 again, after schema v5, a new model, a new sheet, a new settings section and 30 new tests.

**That is a weaker result than it sounds, and it was checked rather than repeated.** A deliberate
throwaway change to a reachable widget was compiled and measured: `libapp.so` changed content
(SHA-256 `a4c8c84f…` → `e0256500…`) while its size stayed at 7,078,792 and the APK stayed at
21,653,926. So the measurement is **quantised** — page padding in the AOT snapshot and alignment
padding in the zip absorb changes of this size — and an equal figure does **not** establish equal
content.

The floor claim itself still holds, on the argument rather than on the number: nothing reachable
from `main()` imports `core/pdf/`, which is a fact about the import graph. But "byte-identical"
overstates the evidence and should read **"identical in size, at a resolution that does not
distinguish changes of this magnitude"**. The real cost of the renderer is still owed, and still
lands with (d).

### Verification

`flutter analyze` clean. **1189 tests pass**, was 1159 (+30).

Migration proof on **Windows**, both ladders — v4 → v5 and v1 → v5 — through the real production
path on an encrypted file with foreign keys on: `user_version` 4 → 5 and 1 → 5, one settings row,
four nulls, the user's own tax rate and prefix untouched, still encrypted, and the columns written
and cleared back through the real repository.

**The Android leg is owed to (d)**, and for a mechanical reason rather than a doubt: the Redmi is on
the cable and enumerated, but asleep and keyguarded, MIUI refuses `adb` input injection (a known
constraint), and `install` returns `INSTALL_FAILED_USER_RESTRICTED` until someone taps the on-device
prompt. It goes in (d)'s cable session with the cold-start measurement.

Rendered and read at the ladder ceiling with both blocks, and with no seller at all. Both defects
above were found that way and re-read after the fix.

---

## D-078 — The Phase 7 cold-start baseline is retired, and a startup number is only ever a paired measurement

**Date:** 2026-09-02 (evening, the (d) cable session)

**Decision.** The recorded Phase 7 cold-start baseline of **1,401 ms** is **withdrawn**. It must not
be quoted, and no conclusion may rest on a comparison against it. Startup cost is from now on
established by **measuring both builds in the same session on the same device**, never by comparing
a fresh measurement against a stored one.

**What happened.** HEAD (`f71791c`, after the whole PDF increment) measured **343 ms** median over
ten steady-state runs — **four times faster** than the stored baseline. A change that only adds code
does not make startup four times faster, so the result was treated as a symptom rather than as a
finding.

The control: commit **`60b5cd5`** — the exact commit the baseline was recorded on — was checked out
into a worktree, rebuilt as a release arm64 APK, installed on the same Redmi in the same session,
and measured identically.

| Build | Median of 10 steady-state runs | Range |
|---|---|---|
| `f71791c` (HEAD) | 343 ms | 317–395 |
| `60b5cd5` (the baseline commit, today) | 352 ms | 345–366 |
| `60b5cd5` (**as recorded 2026-09-01**) | 1,401 ms | 1,330–1,465 |

**With the code held exactly constant, the same phone gives 352 ms against 1,401 ms recorded.** The
stored figure is therefore a property of that session, not of the application.

**Reason.**

1. **The comparison the baseline invited was false and flattering.** Reporting 343 against 1,401
   would have credited the PDF increment with a 4x startup improvement it did not produce. This is
   the same failure mode as the "byte-identical APK" claim corrected in D-077, arriving from the
   opposite direction: there a number was too weak to carry a claim, here a number was wrong in a
   way that made the claim spectacular. Both are cases of a measurement that agrees with what you
   hoped, and the response is the same — control it before reporting it.
2. **The paired measurement answers the question that was actually being asked.** The gate wants to
   know what Phase 7 cost at startup. 343 vs 352, taken minutes apart with overlapping ranges, says
   **nothing measurable** — and says it without depending on any stored figure at all.
3. **A stored startup number has no error bar and no conditions attached.** Size figures survive
   storage because a build is deterministic enough to re-derive; a launch time is a measurement of a
   phone in a state, and the state is not in the record.

**The cause of the 1,401 ms is NOT established, and is recorded as unexplained.** Checked and
excluded: storage pressure (96% full then, 96% full now), Android dexopt (a release build is AOT, so
the Java shim is all dexopt touches), and power source (USB in both sessions). Writing "device
conditions" would be naming a category and calling it an explanation. Anyone who works out what it
actually was should append it here.

**Alternatives considered.**

* **Report 343 ms against the 1,401 ms baseline and note the improvement.** Rejected — it is the
  false claim above, and it is exactly what the correction culture in this project exists to catch.
* **Re-take the baseline and store the new number instead.** Rejected as insufficient on its own: it
  repeats the mistake with fresher digits. A stored number is only safe when the thing measured is
  reproducible from the record, and this one demonstrably is not.
* **Discard the whole startup measurement as unreliable.** Rejected — it is measurable, and the
  paired form measures it well. What is unreliable is comparing across sessions, not the metric.
* **Keep 1,401 ms with a caveat.** Rejected. A retired number with a footnote still gets quoted; the
  footnote does not travel with it. It is struck out in `CURRENT_STATE.md` and replaced by the
  paired figures.

**Consequence for the phase.** The startup half of Phase 7's gate is **satisfied**: the PDF work
costs nothing measurable at cold start. The size half is still a floor, and the floor claim rests on
the **import graph** — nothing reachable from `main()` imports `core/pdf/` — rather than on the APK
byte count, which D-077 proved is quantised past the point of usefulness at this magnitude. It
becomes a real measurement the moment (d)'s provider makes `core/pdf/` reachable.

**A note on method, since it generalises.** The worktree control cost about fifteen minutes: one
`git worktree add` at the old commit, `flutter pub get --offline`, one release build, one install.
For any measurement whose result would be surprising, rebuilding the old commit and measuring both
in one sitting is available and cheap, and it is the only thing that separates *the code changed*
from *the conditions changed*.

---

## D-079 — The RTL table is a wrapper, not a reversed argument list; and D-072's 16 pixels were never margin

**Date:** 2026-09-02 (evening, continuing the (d) cable session)

Three things settled together, because they were found together and the second two are corrections
to entries this project already had.

### 1. Known issue 24: `rtlTable`, and why not the one-line reversal

**Decision.** `pw.Table` is never used directly for a table a Persian reader reads. All such tables
go through `rtlTable` (`lib/core/pdf/rtl_table.dart`), which takes rows **and** `columnWidths` in
**reading order** — the column the reader meets first is index 0 — and performs the reversal itself.

**Why the wrapper rather than reversing the list at the call site**, which is what the plan said and
what the owner overruled. `pw.Table` places column 0 at the left of the page and walks rightwards:
`Table.layout` starts at `x = 0.0` and adds each width in turn, and neither `Table` nor `TableRow`
takes a `textDirection` — a `Directionality` above them changes nothing. Verified in the package
source (`pdf` 3.13.0), not inferred. So a right-to-left table must be built rather than requested,
and the only question is *where the reversal lives*.

Handing `pw.Table` a backwards list produces a correct page and leaves a trap: the next person to add
a column writes it where it reads, into a list that is secretly reversed, and gets a wrong page that
nothing states is wrong. Worse, `columnWidths` is keyed by index, so a hand-reversed cell list needs
a hand-reversed width map kept in step with it — **two reversals that must agree, with nothing
checking that they do**, and a disagreement *mislabels* every column rather than merely reordering
them, which is strictly worse than the fault being fixed.

So the reversal happens once, in one function, and callers write columns where they belong. The
invariants that make the reversal meaningful are **assertions**, for the same reason: rows of unequal
length, or a width map that does not cover every column, cannot be reversed correctly, and guessing
would produce exactly the mislabelled table the wrapper exists to prevent.

**The party blocks moved onto it too.** They carried the same trap in a milder form — a comment
reading *"Buyer, gap, seller — left to right on the page"* and a width map documented as being in
page order rather than reading order. Correct output, backwards source. They are now declared seller
first, like a reader meets them.

**Verified by rendering, not by reading the source** — which is the point, since D-076 recorded this
column order as correct having only looked at a page and found every column plausible where it sat.
`build/document_pages/seller_ceiling.pdf` now reads, right to left: ردیف · شرح · تعداد · قیمت واحد ·
مبلغ کل · جمع سطر, with فروشنده on the right and خریدار on the left. `rtl_table_test.dart` pins the
contract and says in its own header that it does **not** settle the page.

### 2. D-072's "16 pixels of margin" is not margin — it is the primitive's padding

**The correction.** D-072 recorded that the backup password sheet clears the keyboard by 16 logical
pixels and called that *the margin to watch if the §8 warning copy grows*. Both halves are wrong.

Every sheet measured on the phone reports the same number — payment 532.7/548.7, line editor the
same, backup password 503.6/519.6, seller 576.0/592.0 — all exactly **16.0**. That is not four
coincidences and it is not headroom: `EditorSheet` pads below its action by `AppSpacing.lg`, which is
16, inside a `SafeArea`. The distance is a property of the primitive, and **copy growth cannot touch
it**: `EditorSheet` caps the field area and scrolls it while the action stays pinned, however tall
the content above becomes. The number moves only if `AppSpacing.lg` or the primitive changes.

**Decision.** The number lives where it governs every sheet at once rather than as a note about one.
Both keyboard guards — `sheet_keyboard_test.dart` (widget, runs on every commit) and
`device_assertions.dart` (device) — now assert that the action clears the keyboard by **at least
`AppSpacing.lg`**, referencing the primitive's own constant rather than a literal.

A **floor, not an equality**, deliberately: a phone with gesture navigation adds its own bottom safe
area, and more clearance is never the defect. The picker sheets, which are outside `EditorSheet` by
design (D-062), clear by more and pass.

**Verified to bite**: raised to `AppSpacing.lg * 2`, five of the six guarded sheets fail. The picker
passes, which is the floor behaving as a floor.

### 3. A new finding: the lines table has never crossed a page break

Reading the multi-page fixture to check the column order showed something else. `multipage.pdf` is
the "enough lines to need a second page" case — and all **28 rows fit on page 1**. Page 2 carries
only the totals block. So the lines table has never spanned a page boundary in any fixture, and the
header row is `repeat: false`, meaning **if a table ever did span pages the header would not repeat**.

D-076 recorded "the repeated header" as read off rendered pages. The header appears once because the
table appears once; that observation could not have distinguished a repeating header from a
non-repeating one. Same failure as the column order, on the same page, found the same way.

**Not fixed here.** Setting `repeat: true` is one word, but it is untested until a fixture actually
spans, and the fixture that claims to span does not. Both belong together and both belong to whoever
takes it, with the fixture first. Recorded as **known issue 25**.

**Alternatives considered.**

* **The one-line reversal of `lineColumns` and the cell list** (the original plan). Rejected by the
  owner and rightly: correct output from a backwards source, with the width map as an unguarded
  second reversal.
* **Subclassing `pw.Table` to lay out from the right.** Rejected. `Table` implements `SpanningWidget`
  for multi-page flow and its layout is entangled with that; reimplementing it to change the sign of
  one accumulator risks the page-breaking behaviour for no gain the wrapper does not already give.
* **Asking the `pdf` package for `textDirection`.** Not available, and an upstream change is not a
  plan for a phase closing in two days.
* **Leaving the 16 pixels as a note on the one sheet.** Rejected — that is how it got rediscovered on
  a second sheet, and it would have been rediscovered on a third.

---

## D-080 — Phase 7 (d): the document becomes reachable, and where a generated PDF lives

**Date:** 2026-09-02 (evening)

### The §7 question, answered

**A generated invoice is the second most sensitive artifact this application produces**, after a
backup. It carries the customer's full record — name, کد ملی, کد اقتصادی, telephone, نشانی — beside
the financial detail of a transaction, and **unlike a backup it is not encrypted**, because a
document the customer has to be able to open cannot be.

**Decision.** It follows the backup's shape exactly (D-071), which was designed for this and says so
in its own header:

1. **Written to app-private storage.** The application's `files` directory on Android, `%APPDATA%`
   on Windows — via `getApplicationSupportDirectory`. Never a shared directory, never `Downloads`,
   never external storage, never beside the executable.
2. **Leaves only through the gateway.** SAF's `ACTION_CREATE_DOCUMENT` on Android, the native save
   dialog on desktop. The user picks the destination on their own device. **No share intent**, so no
   third-party application is handed a page carrying a customer's national ID.
3. **Every path deletes the working file** — delivered, cancelled, or failed — in a `finally`.

**Point 3 is the one that would have rotted quietly**, and it is why it has a test rather than a
comment. A cancelled export that left its file behind would accumulate unencrypted customer records
inside the application's own directory, and **nothing in the interface would ever mention them
again**: the user believes no file was produced. "Not readable by other apps" is not a reason to keep
an artifact nobody asked for.

**What is deliberately not claimed.** Once the user picks a destination the file is theirs and its
lifetime is theirs; save it into a synced folder and it syncs. That is what a save dialog is for, and
§7's threat model already excludes a compromised OS. What this owns is that **the application leaves
no copy behind**.

**How it is held down.** `integration_test/invoice_export_test.dart`, on **both** targets. The fake
gateway checks the file **exists at the moment it is offered** and the test checks it is gone
afterwards — both halves, because asserting only the second would pass just as well if the controller
had never written a file at all, and the cleanup would be trivially correct about nothing. The
cancelled path gets its own test for the reason above. It also asserts the file is a real PDF by its
`%PDF-` header rather than by a byte count, and that its path is under the app-private directory.

### What (d) built

* **`documentTypefaceProvider`** — `keepAlive`, loads both Vazirmatn faces from `rootBundle`. Loaded
  from the bundle rather than the filesystem so the face the safety analysis is derived from is the
  face actually embedded (D-073); they must not be able to drift.
* **`InvoiceDocumentController.export`** — the whole widget-facing surface. Renders through the real
  view builder with `seller:` **wired deliberately**, since `buildInvoiceDocumentView` defaults it to
  `SellerIdentity.none` and a call site that forgets it produces a document missing half its identity
  with no error at all.
* **The action**, in the title row's existing menu — the slot `InvoiceCancelAction`'s own header had
  already reserved for it. §10's rule: a card here would be the fourth block added above the invoice
  lines on this family of screens.
* **The empty-seller notice** (D-077's other half), as a `SnackBar` **after** the save with a
  «تنظیمات» action. Never a dialog and never before: D-077 ruled that an empty seller blocks nothing,
  and a modal asking the user to approve their own document is that refusal wearing a different hat.
  It reports what the file they now hold contains, and offers the fix.

**The export is offered on every invoice, including a draft and a cancelled one.** D-075 settled that
a draft prints, marked with its band; D-061 that a cancelled invoice is still a document. A user who
could not produce a PDF of what is on their screen would have to ask why. The two existing tests that
asserted the *menu* disappears for those states now assert the *cancel item* does — asserting the
button's absence would have passed only by accident of what else the menu happened to hold.

### `hadSeller` comes out of the render, not out of settings

The outcome carries whether the document actually printed a فروشنده block, rather than the screen
re-reading `settings.seller` to decide what to say. The settings can change between the render and
the message, and **the sentence the user reads has to be true of the file they are now holding**.

### One defect found by wiring it up

`ref.read(appSettingsProvider.future)` fails: the provider is a `StreamProvider` and auto-disposes,
so a one-shot read creates and tears it down before the stream emits — *"disposed during loading
state, yet no value could be emitted"*. It would have been invisible in any test that overrode the
provider with a value. The controller reads `settingsRepositoryProvider` instead, which is also the
more correct thing: an export wants the settings **at this instant**, not a subscription, and §3
already says a controller talks to a repository.

### The size figure, which finally means something

D-074 recorded **+133,402 bytes** and called it a floor, with the floor claim resting on the import
graph — nothing reachable from `main()` imported `core/pdf/`. Step 1 of (d) connected it, and the
real cost is now measurable for the first time:

| ABI | Before (c) | After (d) | Cost of the document feature |
|---|---|---|---|
| arm64-v8a | 21,653,926 | **23,423,398** | **+1,769,472** (+1.69 MiB) |
| armeabi-v7a | 19,262,910 | 21,343,678 | +2,080,768 |
| x86_64 | 23,337,602 | 24,976,002 | +1,638,400 |

**The floor understated the cost by a factor of thirteen**, which is exactly what "a floor, and the
claim rests on the import graph rather than on the number" was warning about. The difference is the
`pdf` package's own code, which the AOT tree-shaker discarded entirely while nothing reachable
imported it. No new assets: both Vazirmatn faces were already bundled for the screen.

**1.7 MiB for the feature the phase exists to deliver is accepted**, and there is no decision to take
about it — but it is recorded as measured rather than as estimated, because D-074's estimate was
wrong by more than an order of magnitude and the next person to reason about binary size from an
import-graph argument should see how that went.

---

## D-081 — The desktop breakpoint was wrong by 288 pixels, and the window is not the width the table gets

**Date:** 2026-09-02 (late evening)

**Reported by the owner**, resizing the Windows build: correct at phone width, correct maximised, **a
red error box somewhere in the middle**.

### What it was

`Breakpoints.desktop` was **1024**, and its own doc-comment justified the number: *"1024 is where a
data table has room for the five columns an invoice list needs (number, customer, date, status,
amount) without truncation."* **That was never measured and it is false.** At a 1024-wide window the
invoice list's table is laid out at **695** logical pixels and its columns need **880**.

The error is in what the number is compared against. **A window's width is not the width its table
gets.** The navigation rail, the page padding, and — on `/customers/:id` — a side panel all come out
of it first. Measured at a 1024 window:

| Screen | Table laid out at | Columns need |
|---|---|---|
| dashboard | 695 | 880 |
| invoice list | 695 | 880 |
| customer list | 695 | 696 |
| customer detail | **351** | 636 |

Four screens, from 1024 up to roughly 1300.

### Why it was a red box, and why that was the lucky outcome

`AppTableHeader`'s D-065 guard throws a `FlutterError` when a table is laid out narrower than its
columns need — but it is inside `assert(...)`, so **it exists only in debug builds**. What the owner
saw was that guard doing its job.

**In a release build the assert is compiled out**, and those same widths would have shipped the
silent failure instead: flexible columns handed nothing, laid out successfully at nothing, and
Persian rendered **one glyph per row** — the exact defect D-065 was written for, on four screens, at
every window width in a 280-pixel band that includes very common ones.

So the severity is the opposite of how it looked, and the owner put it better than this entry
originally did:

> **I didn't find a bug; I found the only build in which it was visible.**

That sentence is the argument for `width_sweep_test.dart` existing at all, and it generalises past
this defect. Every guard in this project that lives inside `assert` — the table minimum, and any that
follow it — is **absent from the artifact users receive**. A debug run is therefore not a check on
the release build; it is a check on a *different* build that happens to be noisier. What makes a
guard count is a test that runs it, because the test is the only place the assert is guaranteed to
be live and the only place a failure is recorded rather than merely displayed to whoever happened to
be dragging a window at the time.

### Decision

`Breakpoints.desktop` becomes **1312**, and its doc-comment now records what the number is and how it
was obtained rather than asserting something nobody checked.

**Measured, not chosen.** At 1280 one screen still fails the sweep; at 1304 every screen is clean at
every swept width. 1312 is the next multiple of 16 above the measured boundary.

**The consequence is accepted:** a window between 1024 and 1312 now gets the tablet layout — rail plus
cards — instead of tables. That is the correct behaviour rather than a compromise: the table did not
fit, and cards are what this application already shows when a table will not fit. Density is lost
where correctness was previously being lost silently.

### What is NOT fixed, and is the better shape

**The decision is still made from the window's width, not from the table's.** That is the same class
of mistake as the number that was wrong: `/customers/:id` needs a wider *window* than the lists do
purely because a panel eats its width first, and one global number cannot express that. The right
shape is a `LayoutBuilder` at each table site choosing cards when `constraints.maxWidth <
tableMinimumWidth(columns)` — `tableMinimumWidth` is already public and already computes exactly that
figure for the guard.

It was not done now, and the reason is the calendar rather than the design: it is ten call sites the
day before the remaining access ends, against a one-line change that is measured, tested, and
correct for every layout that exists today. **The debt is real and is recorded here**: if any of these
screens changes how much width it takes before its table, this number needs re-measuring, and
`width_sweep_test.dart` is what will say so.

### The check that would have caught it, which now exists

`test/features/width_sweep_test.dart` renders **every screen inside the real `AdaptiveScaffold`** at
every width from 328 to 1600 and fails on any thrown exception.

Two things it makes explicit:

* **The three named tier sizes are three points on a continuum.** D-057 established that a pass at one
  tier is a pass at one tier; this is the same argument applied to the widths *between* the tiers,
  which a dragged window passes through and no test had ever visited.
* **The app shell had no widget test at all.** `pumpScreen` renders a bare screen, so the navigation
  chrome — and the bottom-bar/rail and compact/extended switches — had never been pumped by anything.
  Composing the screens inside the real shell is what makes the sweep measure the width the table
  actually gets rather than the width of the window.

**Verified to bite:** at the old 1024 it reports four failing screens; at 1280, one.

### One coverage consequence, stated rather than left to be discovered

The Windows device suites run at **1264 × 681**, which is now the **tablet** tier — `invoice_form_device_test`
duly reports `tier : tablet` where it used to report desktop. So the **desktop tier no longer has any
device coverage**; it is held by the widget sweep at 1400 and by `width_sweep_test.dart`. Getting it
back means running those suites in a window at least 1312 wide.

---

## D-082 — A saved draft had no way forward, and the printed line total could not be checked

**Date:** 2026-09-02 (night). Three findings from the owner's first real use of the app on a phone.

### 1. A saved draft could never be issued — and it explains a second report

**Issuing existed in exactly one place: the editor screen, at the moment of creation.**
`InvoiceEditor` is keyed by the `DateTime` it was opened (`build(DateTime openedAt)`) and its
`issue()` calls `save()`, which calls `create` — a *new* invoice, every time. Nothing anywhere loaded
an existing invoice into the editor, and no other screen offered issuing.

So a user who saved a draft intending to issue it later had made a document that **could never become
an invoice**. Half the workflow the application exists for was unreachable.

**And it accounts for the separate report that the record-payment action was missing.** It was not
missing. `acceptsPayments` is false for a draft, so the floating action is correctly absent and the
payments card explains why in Persian. But if every invoice a user owns is a draft — because they
cannot be issued — then the payment action is never seen, and the page reads as inert. **One cause,
two reports.** Nothing was changed for the second one, and the device suite already proves the
payment action works on an issued invoice on that exact phone.

**The fix.** `InvoiceCancellation.issue()`, and two entry points that mirror how recording a payment
is already offered (D-060): the **floating action on a phone**, where a draft's slot was empty
precisely because it accepts no payments, and an **inline button under the summary** on the wider
tiers, so the two are never on screen together. The confirmation is the editor's copy **verbatim** —
the consequences (a number spent permanently, D-013; editability ended, §6) do not depend on where
issuing was started from, and two wordings of one irreversible act is how they drift apart.

**Still not possible: editing a saved draft.** `updateDraft` exists in the repository and nothing
calls it. Issuing was the blocking half — a draft that can be issued is a workflow; a draft that can
be edited is a convenience — but it is a real gap and is now known issue 29.

### 2. «جمع سطر» was the one figure on the page a reader could not arrive at

**Reported as: the line-total column does not add up.** It did add up — Σ lineTotal *is* the grand
total — but not in any way a person holding the page could verify.

`lineTotal` is the line's own net **after its share of the invoice-level discount**, plus its tax.
The share comes from the largest-remainder allocation in §4 step 4, which the document never shows.
So the reader sees `قیمت واحد × تعداد = مبلغ کل`, and then a `جمع سطر` that is neither of those and
cannot be derived from anything printed.

**Decision: the column is removed.** Not either of the two repairs the owner offered, and here is why
each was rejected:

* **Show the line's own total before the invoice discount** (i.e. `lineNet`). It sums to the
  *subtotal*, which this page does not print — the summary's first row is `grossTotal`. So the column
  still would not tie to anything, and where no line carries its own discount it is an exact
  duplicate of `مبلغ کل`.
* **Show the allocated share on its own line.** It adds a sixth money-bearing column to a table whose
  description column D-065 already found crushed to 21.6 points, in order to expose an internal
  apportionment the customer cannot independently check and has no reason to care about. The
  invoice-level discount is already stated once, in the summary, as a single number that *is*
  checkable against the total.

**What removing it leaves is a page that reconciles end to end:**

```
قیمت واحد × تعداد            = مبلغ کل        (per row, by hand)
Σ مبلغ کل                    = جمع سطرها      (column to summary)
جمع سطرها − کسر تخفیف + مالیات = مبلغ قابل پرداخت (summary chain)
```

Every printed number is either computed by the reader or labelled in the summary. It also returns 88
points to the description column, which is the one that was crushed.

**One residual, stated rather than papered over.** Amounts are computed in Rial and displayed in
Toman, so a row can be off by a Toman or two against a hand multiplication when the Rial figure is
not a round number of Toman — on the ceiling fixture, `۱۳٬۳۳۳٬۳۳۲ × ۲٫۵` reads as 33,333,330 while
the row prints 33,333,333, and the three rows sum to 99,999,999 against a stated 100,000,000. The
summary chain is exact. This is inherent to displaying a unit coarser than the one the arithmetic
uses; with ordinary prices it does not arise. Not fixed, and not hidden.

**The on-screen table keeps its `جمع سطر` column**, deliberately. §4's requirement is about *the
document a customer keeps*. On screen the reader is the business owner, who can see the
invoice-level discount field that produced the allocation, and the per-line contribution is
information they may legitimately want.

### 3. A guard that broke every debug build, caught by running the thing

The release-signing refusal added earlier the same night was written as a `throw` inside
`buildTypes { release { ... } }`. **Gradle configures every build type regardless of which one is
being assembled**, so `assembleDebug` threw as well — breaking `flutter run`, `flutter test -d
<device>` and every integration suite.

It was caught within minutes, by running the device suite rather than by reading the diff, and it is
recorded because the shape recurs: **a guard placed at configuration time fires for builds it was
never meant to judge.** It now attaches to the release assemble/bundle *tasks*, and only when the
keystore is absent, so a debug build never sees it. Both directions re-verified: `--debug` builds,
`--release` refuses with the written message.

---

## D-083 — A guard placed at configuration time fires for builds it was never meant to judge

**Date:** 2026-09-02 (night). Lifted out of D-082 into its own entry at the owner's direction,
because the lesson is not about signing.

**What happened.** The release-signing refusal (D-081's companion work) was written as a `throw`
inside `buildTypes { release { ... } }` in `android/app/build.gradle.kts`. **Gradle configures every
build type on every invocation, regardless of which one is being assembled**, so `assembleDebug` ran
straight into it. That broke `flutter run`, `flutter test -d <device>`, and every integration suite —
i.e. the entire ability to put the application on a phone — for a guard that was only ever meant to
stop an unsigned *release*.

**How it was caught: by running the thing.** The next action after adding it was the phone device
suite, which failed immediately with the guard's own message. Reading the diff would not have found
it; the code says "release" three times and looks exactly like what was intended. The build log said
`Build file 'build.gradle.kts' line: 79` while assembling **debug**, and that line is the whole
diagnosis.

**The fix.** The refusal now attaches to the *tasks that emit a release artifact*, and only when the
keystore is absent:

```kotlin
if (!keystorePropertiesFile.exists()) {
    tasks.matching { task ->
        task.name.contains("Release") &&
            (task.name.startsWith("assemble") || task.name.startsWith("bundle"))
    }.configureEach { doFirst { throw GradleException(...) } }
}
```

`signingConfig` is simply `null` when there is no keystore — never the debug key, which was the
original point.

**Both directions re-verified**, which is the standing rule for a guard in this project: `--debug`
builds and installs; `--release` refuses with the written message; and with a throwaway keystore the
release APK is signed with it and not with `CN=Android Debug`.

### Why this is its own entry

**It is the resize defect's lesson from the other direction, and together they make a rule.**

* D-081: a guard that lives inside `assert` **does not exist** in the artifact users receive, so a
  debug run is not a check on the release build.
* D-083: a guard that runs at Gradle **configuration** time exists in *every* build, including the
  ones it was never meant to judge.

The general form: **a check is only as good as the conditions it actually runs in, and both failures
were invisible to reading and immediate on running.** Neither a unit test nor a careful diff review
would have surfaced either one; a debug run surfaced this in seconds and a dragged window surfaced
the other.

The practical consequence for whoever works on this next: after touching the build files, the
verification is not "the release build still works" — it is **build a debug APK, build a release
one, and confirm each does what it should**, because the two share configuration and a change aimed
at one lands on both.

---

## D-084 — A settled invoice, an editable draft, and numbers that replace themselves

**Date:** 2026-09-03. Findings 5, 29 and 6 from the owner's phone testing.

### Finding 5 — a fully paid invoice went on offering «ثبت پرداخت» as its primary action

**Wrong twice over:** nothing is owed, and the floating slot is for the thing the user came to do.

**But hiding it outright is not available**, because money genuinely arriving twice is a fact the
record has to be able to hold — a duplicate transfer, a customer paying an invoice they had already
settled. Refusing to record that would make the ledger unable to describe what happened, which is a
worse fault than an unnecessary button.

**Decision: the action moves rather than closes.** Once `isFullyPaid`, the floating action is
withdrawn and the **payments card carries it instead**, beside the payments already listed — which is
where an exceptional addition belongs. On the phone that is a change to the existing rule that the
card omits the action (D-060), and the rule it was protecting still holds: the two are never on
screen together.

**And the withdrawal is said, not left to be inferred.** `invoiceDetailPaymentsSettled` states that
the invoice is settled and that a further receipt can still be recorded here. Removing a control
silently is precisely what made a draft's page read as broken in D-082, and a settled invoice is the
happier version of the same silence.

The alternative — keep the button and refuse with copy — was rejected: a control whose only purpose
is to explain why it does nothing is the affordance-leading-nowhere D-021 rules out, and it would
have left overpayment unrecordable anyway.

### Finding 29 — a saved draft could not be edited

The same shape as the two before it: **`updateDraft` had existed and been tested in the repository
since Phase 4, and nothing called it** — exactly where issuing was before D-082 and deletion was
before known issue 27. Three separate holes, all of them a repository method with no way in.

Now that a draft can be issued, a draft is a workflow, and a workflow where correcting a typo means
deleting the invoice and retyping every line is not one.

**The id lives on `InvoiceEditorState`, not in the provider's family key.** `invoiceEditorProvider`
is keyed by the instant the form opened and that key is threaded through four widgets; a second key
would have touched every one of them and their tests to express something only `save` reads. Carrying
it on the state also means it survives the rebuild a settings change causes — which goes through
`copyWith`, and would otherwise have dropped it and **turned an edit into a second invoice silently**.

**`loadDraft` is idempotent**, and that is load-bearing rather than defensive: the screen loads after
the first frame, and a settings change rebuilds the provider and would load again, discarding
everything typed since.

**One reconstruction is a judgement call.** §4 snapshots the *resolved* tax rate onto every item, so
a line that merely inherited the invoice's rate is indistinguishable from one explicitly set to the
same number. On reopen, a rate equal to the inherited resolution is treated as inherited (`null`).
The resolved figure is identical either way; the two differ only if the user then changes the invoice
rate, and following it is the likelier intent.

**An issued invoice is refused** rather than loaded — composing a new invoice out of its lines would
be worse than doing nothing — and the repository refuses the write regardless.

**Still not built:** editing an issued invoice, which is not a gap but §6. Correction is by
cancellation.

### Finding 6 — numeric fields now select their contents on focus

Changing a quantity from ۱ to ۳ meant clearing the ۱ first. A number is replaced far more often than
it is edited in place; prose is the opposite, where selecting everything on focus would arm the next
keystroke to destroy an address.

**Implemented in `AppTextField` and derived from the keyboard type**, so it covers every numeric
field in the application at once rather than being applied at nine call sites and forgotten at the
tenth.

**Not `digitsOnly`, which was the obvious marker and is the wrong one.** The quantity field — the one
the behaviour was actually reported against — sets `digitsOnly: false` deliberately, because it has
to accept the Persian decimal separator; so does a discount field in percent mode. Gating on the flag
would have missed the reported case entirely and looked correct in review.

**The selection is applied after the frame**, because the framework sets its own selection while
installing focus. Assigning directly works in a widget test and is overwritten on a device — the
worst of both, and the reason the test asserts after `pumpAndSettle` rather than synchronously.

Phone fields are included: a phone number is a value that gets retyped, not edited mid-string.

---

## D-085 — The payment status on the document, and why a cancelled invoice is banded

**Date:** 2026-09-03. Finding 8.

**Decision.** The printed invoice states its status, in two different weights, and the two can never
collide:

| Status | How it prints |
|---|---|
| `draft` | The full-width filled band already defined by D-075. **No payment status.** |
| `cancelled` | The **same band**, own copy: «باطل شده — این فاکتور اعتبار ندارد». **No payment status.** |
| `unpaid` / `partiallyPaid` / `paid` | «وضعیت پرداخت» and its value, bold, **directly under the payable total**. No band. |

### One field, not two, for the band

`InvoiceDocumentView.banner` replaced `draftBanner` and carries whichever marking applies. **The two
cannot co-occur**: cancellation is refused on a draft (`isCancellable`), and a cancelled invoice was
issued, so it is not a draft. Two nullable fields for one slot would have made a state the domain
forbids expressible in the view, and the renderer would have had to choose between them.

### Cancelled is banded, and that was the question worth asking

A cancelled invoice is **the dangerous document**. A draft looks provisional; a cancelled invoice
looks exactly like a valid claim — it carries a real invoice number, it reconciles, and it may
already have been sent. If any state must be impossible to miss in someone's hand, it is this one.
So it gets the same weight as a draft rather than a quieter treatment.

The copy says «اعتبار ندارد» — *this is not valid* — rather than «لغو شد» — *it was cancelled*. The
reader needs to know what the paper in their hand **is**, not what happened to it.

### A cancelled invoice prints no payment status, and that is not an omission

«پرداخت نشده» printed beside a void band **reads as a demand to pay it**, which is the opposite of
what the band says. A draft prints none either, for the simpler reason that it is not yet a claim on
anyone.

### The status is the stored one

Read from `invoice.status`, which the repository derives from the payments and persists (§6). The
renderer computes nothing — a page with its own opinion about whether a customer has paid is the
worst possible place to find a second one.

**Overdue is deliberately never printed.** It is the one status the screen shows that the document
must not: it is a function of the day the page is *read*, and the whole point of a document is that
it is read later than it was made. `invoiceStatusViewOfStored` — which has no overdue branch — is
what the builder uses, and a test pins that the printed value is never «سررسید گذشته».

### Placement

Under the grand total rather than in a corner: «پرداخت شده» is the answer to the question the reader
brought to that figure, so it belongs where the eye already is. Read off the rendered page, both
cases.

---

## D-086 — The add-line fold, measured rather than guessed, and deliberately not fixed

**Date:** 2026-09-03. Finding 7, reported as *"adding a line is not discoverable; the issue and
save-draft actions sit over it"*.

**Measured on the Redmi at 392.7 × 803.6 before changing anything**, as D-054's fold was. The result
does not say what the report assumed, and is more useful for it:

| State | add-line top | pinned bar top | On screen? |
|---|---|---|---|
| Pristine form, no customer | 586 | 670 | yes |
| **Details folded, customer picked** (how the form opens) | **586** | **670** | **yes** |
| **Details unfolded, customer picked** | **out of the widget tree entirely** | 415 | no — ~400 px of scrolling away |

**So it is not simply below the fold.** In the state the form opens in, «افزودن از فهرست» *is* on
screen — but it sits at 586–611 px of an 804 px viewport, in the bottom sixth, **59 pixels above a
pinned bar carrying two filled buttons**. And the moment the user opens the details section — to set
a date, a discount, a tax rate, which is an ordinary thing to do — it leaves the rendered tree
completely.

**The real fault is hierarchy, not geometry.** The screen's primary action is a low-contrast control
in the last sixth of the page, directly beneath two prominent buttons for actions the user cannot
usefully take yet — issuing an invoice with no lines on it. That is why a first-time user did not
find it, and it is why nudging spacing would not fix it.

**Not fixed, deliberately.** The candidates all need design judgement and a phone to verify:

* put the **lines section above the details section** on the phone, which is §10's own rule (a
  variable-height block above the thing the page is for belongs below it) applied a fourth time;
* promote add-line to a filled action and demote the details;
* keep «صدور» out of the pinned bar until there is at least one line, so the bar stops advertising
  an action that cannot yet succeed.

Each changes the shape of the screen. With the remaining access measured in hours, a recorded number
is worth more than a rushed layout change that nobody can check on hardware — the owner's judgement,
and the right one. **Known issue 30.**

### And the existing check was measuring the wrong state

`invoice_form_device_test` printed `fits unscrolled: true` and had done since Phase 4. It is not
wrong; it is measured on a **pristine** form, with no customer and the details folded — a state
nobody adds a line from. The suite now reports the two states above alongside it, so the reassuring
line no longer stands alone.

That is the third instance of one pattern in as many days: **a check that reports success about
conditions the user is never in** — the assert-only table guard absent from release builds (D-081),
the Gradle guard firing in builds it was never meant to judge (D-083), and now a fold measured on a
form nobody has used yet.
