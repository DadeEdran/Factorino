# Environment

> Local development environment notes — toolchain versions and the network situation on the
> development machine.
>
> **This file documents a local condition. It is not project configuration.** No mirror URL,
> proxy setting, or alternate package host may ever be committed into `pubspec.yaml`,
> `pubspec.lock`, Gradle files, or CI configuration. See `DECISIONS.md` D-014.

Last verified: **2026-08-23**

---

## 1. Toolchain

Raw `flutter --version` output from this machine:

```
Flutter 3.47.1 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 6655482ec0 (3 days ago) • 2026-08-19 10:07:23 -0700
Engine • hash 11d79658c444477b06513d32b52c8c4ccb7276b0 (revision 5d53178869) (3 days ago) • 2026-08-18 23:36:01.000Z
Tools • Dart 3.13.1 • DevTools 2.60.0
```

`dart --version`: `Dart SDK version: 3.13.1 (stable) (Tue Aug 18 01:00:59 2026 -0700) on "windows_x64"`

**On the Flutter 3.47 / Dart 3.13 pairing.** This was queried as inconsistent. It is not, and the
decisive evidence is direct rather than inferential:

```
$ which -a dart flutter
/c/flutter/bin/dart
/c/flutter/bin/flutter

$ cat /c/flutter/bin/cache/dart-sdk/version
3.13.1
```

The Dart SDK reporting 3.13.1 is the one **bundled inside the Flutter 3.47.1 checkout** — there is no
separately installed Dart on `PATH` shadowing it, so the two cannot be out of step by construction.

The pairing is also what the release cadence predicts. Flutter has shipped roughly three minor
releases per Dart minor for years (3.24 to Dart 3.5, 3.27 to 3.6, 3.29 to 3.7, 3.32 to 3.8, 3.35 to
3.9); continuing that gives 3.38 to 3.10, 3.41 to 3.11, 3.44 to 3.12, and **3.47 to 3.13**.

Dependency resolution targets this SDK: `pubspec.yaml` declares `sdk: ^3.13.1`.

| Item | Version / status |
|---|---|
| Flutter | 3.47.1 · stable · `C:\flutter` |
| Dart | 3.13.1 |
| Android SDK | 36.0.0, platform android-37.0, build-tools 36.0.0 |
| JDK | OpenJDK 25.0.2 (bundled with Android Studio) |
| AGP / Kotlin / Gradle | 9.1.0 / 2.4.0 / 9.3.1 |
| Visual Studio | Enterprise 2026 18.1.0 — "Desktop development with C++" present |
| Windows SDK | 10.0.26100.0 |
| Chrome | 151.0.7922.170 |

### Build hooks do not need an experimental flag

`flutter config --list` reports `enable-native-assets: (Not set)`, and `flutter config` documents that
flag as **`(defaults to on)`** on this version. Native assets / build hooks — the mechanism
`package:sqlite3` 3.x uses to build and bundle its encrypted SQLite native library (D-010) — are
enabled by default on Flutter 3.47.1 stable. No `--enable-experiment` and no `flutter config` change
is required.

### Android SDK licenses — a stale `flutter doctor` check, not a real failure

`flutter doctor` reports:

```
[!] Android toolchain - develop for Android devices (Android SDK version 36.0.0)
    ✗ Android license status unknown.
```

This cannot be cleared by the documented command, and it does not indicate an unaccepted licence:

- `flutter doctor --android-licenses` and `sdkmanager --licenses` both now print
  *"WARNING: The SDK Manager CLI tool (sdkmanager) is deprecated"* and
  *"Warning: The --licenses option is no longer needed."* — `sdkmanager.bat` is a shim over the new
  `android` CLI, which has no `licenses` subcommand at all (`android sdk` offers only
  `install`/`update`/`remove`/`list`; licences are accepted implicitly on install).
- `%LOCALAPPDATA%\Android\Sdk\licenses\android-sdk-license` exists and contains the canonical hash
  `24333f8a63b6825ea9c5514f83c2829b004d1fee`.
- `flutter build apk --debug` succeeds.

So the licence is accepted; `flutter doctor`'s probe is simply stale against SDK 36 tooling. **No
licence-hash files were hand-written to silence the warning** — fabricating licence acceptance files
is not something to do on the owner's behalf. Treat this doctor line as a known false positive.

---

## 2. Network situation on this machine

### Measured reachability

Re-measured 2026-08-23:

| Host | Result | Needed for |
|---|---|---|
| `pub.dev` | **HTTP 403** | Dart/Flutter packages — **canonical host** |
| `storage.googleapis.com` | **HTTP 403** | Flutter SDK release downloads |
| `dl.google.com` / `maven.google.com` | **HTTP 404** on valid artifact paths | AndroidX / Google Maven artifacts |
| `github.com` / `api.github.com` | 200 | `package:sqlite3` prebuilt native binaries, Vazirmatn |
| `repo.maven.apache.org` | 200 | non-Google Maven artifacts |
| `services.gradle.org` | 200 | Gradle distributions |

The `pub.dev` and `storage.googleapis.com` failures return Google's GFE block page
(*"Your client does not have permission to get URL ... from this server"*). This is a **geo-block
presenting as an authorization error**, not a missing credential — adding a pub token does not fix
it, and `flutter pub get` fails outright with *"Insufficient permissions to the resource at the
https://pub.dev package repository"*.

### Resolution: mirrors, configured user-globally (D-014, amended)

A VPN was the first choice and did not work: the tunnel routes **per-application** through
Proxifier and `flutter`/`dart` are not routed, so `pub get` kept failing and terminal egress kept
showing the original IP. Packages are therefore resolved through mirrors.

**Set once, per user account, outside any repository:**

```powershell
setx PUB_HOSTED_URL           "https://mirrors.tuna.tsinghua.edu.cn/dart-pub"
setx FLUTTER_STORAGE_BASE_URL "https://storage.flutter-io.cn"
```

**Google Maven** is mirrored by `~/.gradle/init.d/cn-google-maven-mirror.gradle`, which rewrites
Google-Maven repository URLs to `https://maven.aliyun.com/repository/google` in place. Note this is
an **init script, not `gradle.properties`** — `gradle.properties` has no syntax for substituting a
repository. The script rewrites URLs rather than clearing the repository list, because Flutter
injects its own engine-artifact repository into every Android project and clearing would delete it.

**Only what is blocked is mirrored.** `plugins.gradle.org` and `repo.maven.apache.org` both return
200 and are left alone. Redirecting unblocked traffic would widen the supply-chain surface for
nothing.

**Nothing above is committed.** Not in `android/gradle.properties`, `build.gradle.kts`,
`settings.gradle.kts`, `pubspec.yaml`, or CI. This repository must build unmodified on a machine
with normal pub.dev access.

### The lockfile must be sanitized after *every* pub get

`pub` writes the mirror host into every hosted entry of `pubspec.lock`. Rewrite it back:

```sh
flutter pub get && sh tools/sanitize_lockfile
```

**This is not a one-time cleanup.** Measured 2026-08-23: running `pub get` against an
already-sanitized lockfile does **not** accept it — pub treats a pub.dev entry as a different source
from a mirror entry, re-resolves, reports *"Changed 24 dependencies"*, and writes the mirror host
straight back. Every `pub get` re-contaminates the file.

The rewrite is safe: integrity lives in the per-package `sha256`, not the URL, and a mirror serves
byte-identical archives. Verified on the first run — 24 URLs rewritten, all 24 `sha256` lines
byte-identical, file length unchanged, second run reports "already canonical".

`.githooks/pre-commit` is the backstop and fails any commit whose lockfile names another host.

### `package:sqlite3` build hooks are unaffected

The build hook downloads prebuilt native binaries from **GitHub releases**, which returns 200 from
this machine, verified against sha256 hashes shipped inside the pub package (with SLSA level 3
attestations from 3.5.2 onward). That path does not touch Google infrastructure.

If GitHub ever becomes unreachable too, the hook exposes a `url_pattern` user-define to point at a
different download location, and can build from source as a last resort. Neither is needed today.

---

## 3. Assets obtained out-of-band

### Vazirmatn

Downloaded from the official GitHub release (`github.com` is reachable), **not** via a package.

- Source: `https://github.com/rastikerdar/vazirmatn/releases/download/v33.003/vazirmatn-v33.003.zip`
- Release `v33.003`, archive sha256 `0a9afd41967e6f57096a56a181a23f81a2b999b62f1f2a4e4b26736580854fdb`
- Committed to `assets/fonts/`, **standard variant only** (`fonts/ttf/`), weights 400/500/700:

| File | Weight | sha256 |
|---|---|---|
| `Vazirmatn-Regular.ttf` | 400 | `b69fd4c680b8f3f225feabcc655a2c585d97627b8f5f5c0f9985e894069f3a56` |
| `Vazirmatn-Medium.ttf` | 500 | `b986623e4ddef10755e04be39f8ea7bcb1dc08bfe8dd0aa6af395736f256ad4a` |
| `Vazirmatn-Bold.ttf` | 700 | `f635fdbea28f265de395ba83b4b1570dcf2f58d13c65469e61903b1c2d2ae723` |

`OFL.txt` is committed alongside them, as the SIL Open Font License requires.

**The Farsi-digit (FD) variants under `misc/Farsi-Digits*` are deliberately not used.** Digit
rendering is the formatting layer's job (`core/formatting/`), so that Persian-digit display stays
controlled in exactly one place and remains switchable — a font that silently substitutes glyphs
would make that behaviour invisible and untestable.
