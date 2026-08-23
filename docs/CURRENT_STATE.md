# Current State

> The continuity file. A fresh session reads this first and continues from the Next Action.
> Last updated: **2026-08-24**

---

## Phase

**Phase 0 — Environment and Setup · `COMPLETED`**
**Phase 1 — Foundation and Architecture · `IN_PROGRESS`** — one increment remains.

| # | Increment | Status |
|---|---|---|
| a | Drift schema, migration setup, soft-delete helper | `COMPLETED` — **accepted** (`5522caf`) |
| b | `core/money/` engine + unit tests (§4) | `COMPLETED` — **accepted** (`aa0be65`) |
| c | Jalali date layer and digit normalization + tests | `COMPLETED` — **accepted** (`b70c1fc`) |
| d | Repositories and domain models | `COMPLETED` — **accepted** (`36493d3`) |
| e | Theme, localization, routing, responsive shell | `COMPLETED` — **awaiting review** |
| f | The four screens, on real data | `NOT_STARTED` |

## Verification status

```
flutter analyze:            PASS   (No issues found)
flutter test:               PASS   (378/378, was 360)
Android build:              PASS   (not re-run this session; manifest label changed only)
Windows build:              PASS   flutter build windows --debug, and RUN and screenshotted
Web build:                  NOT_RETESTED since plugins were added
D-020 proof - Windows:      PASS   5/5
D-020 proof - Android:      PASS   5/5 on a Redmi Note 8 Pro, Android 11 (API 30, arm64)
```

## What was completed this session — increment (e)

The first increment with a user-facing surface, and the first verified **by running it** rather than
only by tests.

**Design tokens** (D-033) in three files that are the only places a colour, size or font size may be
named. One Persian-turquoise accent (`#11726B` light, `#5ED2C5` dark), warm neutrals in light and
slightly cool ones in dark, borders instead of shadows, six semantic status pairs as a theme
extension, and a type scale whose largest style is the financial numeral style. **Light and dark are
built separately, not derived** — every dark value is picked for its own background.

**Colour means status and nothing else.** Money is rendered in the strongest neutral, never in the
accent: prominence comes from the type scale. A green amount beside a green badge is two signals
competing, and the badge loses.

**Tokens are enforced, not offered.** `theme_tokens_only_test.dart` fails the build on a literal
colour or dimension outside the token files. Verified to bite by introducing both kinds of violation
and watching it fail on the exact lines.

**Persian localization** (D-034) through ARB and generated `AppStrings`, locale pinned to `fa` rather
than followed from the device, RTL set once at the root. `no_hardcoded_strings_test.dart` fails the
build on any Arabic-script character in code outside `core/localization/` — and additionally checks
**D-030's national-ID copy mechanically**, so that constraint is no longer only in a decision log.

Three `// l10n-exempt:` entries exist, all in `number_display.dart`: the thousands separator, decimal
separator and percent sign are numeric punctuation, not translatable copy.

**go_router** with a `StatefulShellRoute` so each destination keeps its own stack and scroll
position. Only routes whose screens exist are registered. گزارش‌ها is absent from navigation *and*
the router (D-021).

**Three genuinely different layouts** — bottom bar / compact rail / extended rail, with the desktop
content column capped rather than stretched.

**Two defects found by running the app that no test would have caught:**

1. `محصولات و خدمات`, the longest destination, **overflowed the compact rail at exactly one
   breakpoint**. Fixed by widening the tablet rail to a token width and letting the label wrap to two
   lines.
2. The Windows title bar showed **mojibake**. The platform manifests were still English
   (`factorino`); setting them to `فاکتورینو` fixed Android and web, but MSVC read `main.cpp` with
   the system ANSI codepage and mangled the wide-string literal. Rewritten as `\u` escapes, which
   carry no encoding assumption — the same lesson as the fold tables in `persian_text.dart`.

## Known issues

| # | Issue | Impact |
|---|---|---|
| 1 | `onUpgrade` throws by design — no v1→v2 path exists | The first schema change needs a migration step **and** a test (§6, §14). |
| 2 | The database opens on the main isolate | Phase 13. The `setup` closure must stay isolate-sendable — `ARCHITECTURE.md` §B.5. |
| 3 | The national-ID checksum cannot catch every transposition | Official algorithm, not a defect. **The UI must never call a passing value verified** (D-030) — now enforced by a test over the ARB. |
| 4 | `watchDetail` re-reads on any invoice-table change | Correct but not minimal. Revisit in Phase 13 if a detail screen lags. |
| 5 | The four list screens show their empty state unconditionally | No data layer attached yet — that is increment (f). The repositories and the empty states both exist; they are simply not wired to each other. |
| 6 | Settings is read-only | It shows the real seeded configuration. Editing controls are later feature work; a form that looked editable and discarded input would be worse. |
| 7 | No logging wrapper exists | §7 requires one before any screen displays national IDs, phone numbers or amounts — i.e. **before (f) ships**. |
| 8 | MIUI re-blocks `flutter test`'s install on a *fresh* install | `adb install -r` once by hand. Developer options → Install via USB. |
| 9 | `pub.dev` 403; `dl.google.com` blocked | Mirrors (D-014). See the expanded note in `tools/sanitize_lockfile`: **`build_runner`, `gen-l10n`, `flutter test` and `flutter build` all resolve too**, and all re-contaminate the lockfile. |
| 10 | `flutter doctor` "Android license status unknown" | Stale check, not a failure. See `ENVIRONMENT.md`. |
| 11 | Release builds signed with debug keys | Phase 15. |
| 12 | Web not retested; Web gets **no** encryption at rest (D-012) | Phase 12. |
| 13 | Android manifest hardening not done | `allowBackup=false`, `usesCleartextTraffic=false`, `FLAG_SECURE`, R8 — all Phase 9. |

## Important context for a future session

- **The cipher pragmas come BEFORE `pragma key`** (D-020). Never assert encryption with
  `PRAGMA cipher_version` or `PRAGMA cipher` — assert on the file header.
- **Six rules are enforced by tests that scan `lib/`.** If one fails, route through the helper —
  never weaken the test. Each has a documented escape-hatch comment requiring a reason:
  1. open a database only through `openEncryptedDatabase` (D-020);
  2. read rows only through `selectAlive` / `selectOnlyAlive` / `countAlive` (D-003) —
     `// soft-delete-exempt:`;
  3. normalize text only through `core/formatting/` (D-029) — `// normalizer-exempt:`;
  4. no drift import in `data/models/` or the interfaces in `data/repositories/` (D-031);
  5. no literal colour or dimension outside `core/theme/` (D-033) — `// tokens-exempt:`;
  6. no Arabic-script character in code outside `core/localization/` (D-034) — `// l10n-exempt:`.
- **`searchKey` writes and reads the same column.** Both repositories owning a `search_name` call it
  on create *and* update.
- **Nothing in `core/money/`, `core/date/` or `core/formatting/` may import Flutter.** A Persian
  digit `TextInputFormatter` is a legitimate future need and *does* require Flutter; it belongs in a
  separate file the pure ones do not import.
- **Riverpod 3 wraps a provider's error in `ProviderException`** — assert on the message, not the
  inner type (`ARCHITECTURE.md` §B.3).
- **Sanitize the lockfile after anything that resolves**, which includes `build_runner`, `gen-l10n`,
  `flutter test` and `flutter build` — not just `pub get`. The full list is in
  `tools/sanitize_lockfile`.
- **Run `dart run build_runner build` after touching a table or an `@riverpod`, and
  `flutter gen-l10n` after touching the ARB**, then commit the regenerated files.
- **Where the source encoding is not guaranteed, name characters by code point.** Bitten twice now:
  once by the fold tables, once by the Windows window title.

## Recently changed files (increment e)

```
pubspec.yaml / pubspec.lock            + go_router 17.5.0, flutter_localizations, intl;
                                         Vazirmatn 400/500/700 declared; generate: true
l10n.yaml                              NEW  gen-l10n config; output committed into lib/
lib/core/theme/*.dart                  NEW  colours, dimensions, typography, ThemeData (D-033)
lib/core/localization/arb/app_fa.arb   NEW  every user-facing string (D-034)
lib/core/localization/generated/*      NEW  gen-l10n output, committed
lib/core/router/*.dart                 NEW  destinations + go_router shell
lib/core/responsive/*.dart             NEW  breakpoints + adaptive scaffold
lib/core/widgets/*.dart                NEW  card, badge, empty state, page frame, AmountText
lib/core/formatting/number_display.dart NEW display formatting, out of the widgets
lib/features/*/presentation/*.dart     NEW  five screens
lib/features/settings/application/*    NEW  the first feature provider
lib/app.dart                           NEW  MaterialApp.router: themes, locale, RTL, router
lib/main.dart                          renders the app instead of an empty Scaffold
windows/runner/main.cpp                Persian window title, as \u escapes
android/.../AndroidManifest.xml        Persian android:label
web/index.html, web/manifest.json      Persian title and manifest names
test/core/theme/, test/core/localization/  NEW  the two guards
tools/sanitize_lockfile                documents every command that triggers a resolve
docs/*                                 D-033, D-034; ROADMAP; ARCHITECTURE §A and §B.7-B.10
```

## Last completed action

Delivered Phase 1 increment (e): the design system, the localization layer, the router and the
responsive shell — with both new rules enforced structurally (tokens, Persian literals) rather than
left to discipline, and both guards verified to fail on a real violation before being trusted.

Ran the Windows build and screenshotted three tiers in light plus the settings screen in both
themes, which is what surfaced the two defects above. Also folded the `build_runner` lockfile
finding into `tools/sanitize_lockfile` and the Riverpod `ProviderException` finding into
`ARCHITECTURE.md` §B.3, as the owner asked.

378/378 tests pass, analyzer clean, Windows builds and runs.

## Next action

**Await the owner's review of increment (e).** Then begin increment **(f): the four screens on real
data** — the last increment of Phase 1.

Specifically, (f) is: wire Dashboard, Invoices, Customers and Products to the repositories through
feature providers, replacing the unconditional empty states with real queries. Everything they need
already exists — the repositories, the money engine, the Jalali period helpers, the design-system
components and the empty states themselves.

Constraints carried into (f):

- **The logging wrapper (§7) must exist before any screen displays a national ID, a phone number or
  an amount.** It does not exist yet, and (f) is the increment that makes it load-bearing.
- **Mobile renders invoice lists as cards; desktop renders a real table** (§10). `LayoutTier` already
  exposes `usesTables` for exactly this.
- **The dashboard's "این ماه" is the current *Jalali* month** (D-006) — use `jalaliMonthOf`, never a
  Gregorian boundary.
- **Aggregates run as SQL, not Dart loops** (§13). `totalIssuedRial` and `countAlive` already do.
- **Amounts go through `AmountText`**, which carries the unit label and the Persian digits, so no
  screen can render a bare number.
- **The national-ID field's copy must say the format is valid, never that the ID is confirmed**
  (D-030). The strings and the test already exist.
- Detail routes (`/invoices/:id`, `/customers/:id`) get registered **with** the screens they open,
  not before.

### Standing rules that outlive this handoff

- **The cipher pragmas come before `pragma key`** (D-020); assert encryption on the file header.
- **The six `lib/`-scanning guards** listed above are the project's memory of six silent failure
  modes. Route through the helper; never weaken the test.
- **Sanitize the lockfile after any command that resolves dependencies.** The pre-commit hook is the
  backstop and it does fire.
- **Regenerate and commit** after touching a table, a provider, or the ARB.
- Commit policy (D-019): commit at meaningful milestones, show `git diff --stat` and the message,
  no per-commit approval needed. Never force-push, amend, rebase or reset --hard.
