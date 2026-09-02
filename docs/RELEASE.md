# Release

How to produce a build that can be given to another person. Two things must be true, and both are
enforced rather than remembered.

---

## 1. Signing

**A release build will not compile without a keystore.** `android/app/build.gradle.kts` throws:

```
Release build requires android/key.properties, which is absent.
```

This is deliberate. The previous configuration signed release builds with the **debug** key so that
`flutter build --release` would always work, and that is the worst of the available failures: a
debug-signed APK looks like a release build, cannot be distributed, and — the part that cannot be
undone — **cannot later be replaced by a properly signed build**. Android identifies an application
by its signature, so every installed copy would have to be uninstalled first, losing its data. A
build that fails is recoverable; a build that shipped is not.

### Create the keystore, once

From the project root:

```sh
keytool -genkeypair -v -keystore android/app/upload-keystore.jks \
  -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`keytool` lives in the JDK that ships with Android Studio — on this machine,
`C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`.

It asks for a password and for a name and organisation. `-validity 10000` is roughly 27 years;
shorter and the key expires while the application is still being updated.

### Then fill in `android/key.properties`

Copy `android/key.properties.example` to `android/key.properties` and set the four values. That file
is gitignored, as are `*.jks` and `*.keystore`. **None of it may ever be committed**.

### Back both up, off this machine

Losing the keystore or its password means **no further updates can ever be published** for an
application signed with it. There is no recovery and nobody who can help — the same sentence the
backup screen says to the user about their passphrase, and true here for the same reason.

### Verifying a build is signed with the right key

```sh
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

The certificate DN must be yours. If it reads `CN=Android Debug`, something has gone wrong and the
build must not be distributed.

---

## 2. Building

```sh
flutter build apk --release --split-per-abi
```

`--split-per-abi` produces one APK per architecture instead of one fat APK — roughly 22 MB each
rather than 24 MB, and it is what a real distribution wants. For the Play Store, build an app bundle
(`flutter build appbundle --release`) instead; the same signing config applies.

Windows:

```sh
flutter build windows --release
```

**Take the Windows size only after `flutter clean`.** An uncleaned `Release` directory keeps an 87 MB
stale `kernel_blob.bin` and reads about 120 MB rather than the true ~33 MB.

---

## 3. What is hardened, and what is not

Done, in `android/app/src/main/AndroidManifest.xml`:

* **`android:allowBackup="false"`** — the default is `true`, and with it the encrypted database and
  the files beside it can be pulled off some configurations with `adb backup`. That is one of the two
  attacks the project spec's threat model claims to cover, so the default was claiming a protection the
  build did not have. No `fullBackupContent` and no `dataExtractionRules` either: an allowlist is
  still a backup path.
* **`android:usesCleartextTraffic="false"`** — nothing here uses the network at all. Declaring it now
  means a plaintext request added later fails at the point it is added.

**Not done**, and listed so it is not assumed:

* **R8 / minification and resource shrinking**. Not enabled. Costs binary size, and
  enabling it late risks reflection-related breakage that needs its own test pass.
* **`FLAG_SECURE` on financial screens** — §7 ties it to the app lock, and there is no app lock
  (known issue 28).
* **No exported components audit beyond the launcher activity**, which is the only exported one.

---

## 4. Before handing it over

1. `flutter analyze` — clean.
2. `flutter test` — all pass.
3. Build, install on a real device, and cold-start it. Confirm the dashboard renders in Persian,
   right-to-left, and that the navigation bar is there.
4. Create one invoice end to end and save its PDF, which is the path that touches the most machinery
   at once: the encrypted database, the money engine, the Jalali dates, the renderer and the file
   gateway.
5. Take one backup and restore it, on a build you are willing to lose the data of.

Verified this way on 2026-09-02 against a throwaway keystore (since deleted): the signed release APK
installs, cold-starts at a 364 ms median over five runs on a Redmi Note 8 Pro, and renders correctly.
The signature identity does not affect runtime behaviour, so that result stands for a properly signed
build — but repeat step 3 with the real key anyway, because it costs two minutes.
