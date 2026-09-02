import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing material, read from a file that is never committed.
//
// `android/key.properties` is gitignored, as are `*.jks` and `*.keystore`;
// `key.properties.example` documents the four keys with placeholder values.
// See `docs/RELEASE.md` for how to create the keystore.
//
// **Absent is not an error here, but it IS an error at release build time.**
// The old configuration signed release builds with the DEBUG key so that
// `flutter run --release` would work, which is the silent-failure shape this
// project keeps finding: a debug-signed APK looks like a release build, and it
// cannot be distributed, cannot be updated by a properly signed one, and cannot
// be discovered to be wrong until someone tries to install the real thing over
// it. The release build now fails loudly instead (see `signingConfig` below).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "io.github.erysaw.factorino"
    // Pinned above flutter.compileSdkVersion (36) because flutter_secure_storage
    // requires compileSdk 37. AGP 9.1.0 warns that 36 is its maximum *recommended*
    // value; the warning is suppressed in gradle.properties. compileSdk only
    // controls which APIs are compilable — targetSdk and minSdk are unchanged.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.erysaw.factorino"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Empty when `key.properties` is absent. The `release` build type
            // below refuses to use it in that state rather than falling back.
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storePassword = keystoreProperties.getProperty("storePassword")
            keystoreProperties.getProperty("storeFile")?.let {
                storeFile = rootProject.file(it)
            }
        }
    }

    buildTypes {
        release {
            // **Never the debug key** (known issue 13). Null when there is no
            // keystore; the task guard below is what turns that into a clear
            // failure at the moment a release artifact is actually requested.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                null
            }
        }
    }
}

// Refuse to produce a release artifact without a real keystore.
//
// **On the task, not in the `release { }` block, and that distinction cost a
// broken build.** Throwing inside `buildTypes { release { ... } }` fires during
// *configuration*, which Gradle performs for every build type regardless of
// which one is being assembled — so `assembleDebug` threw too, and with it
// `flutter run`, `flutter test -d <device>` and every integration suite. Caught
// 2026-09-02 by a device run, immediately after the guard was added.
//
// Attached only when the keystore is missing, and only to the tasks that
// actually emit a release artifact, so a debug build never sees it.
if (!keystorePropertiesFile.exists()) {
    tasks.matching { task ->
        task.name.contains("Release") &&
            (task.name.startsWith("assemble") || task.name.startsWith("bundle"))
    }.configureEach {
        doFirst {
            throw GradleException(
                "Release build requires android/key.properties, which is " +
                    "absent. Copy android/key.properties.example, create a " +
                    "keystore, and fill it in -- see docs/RELEASE.md. " +
                    "Refusing to sign a release build with the debug key: the " +
                    "result cannot be distributed and cannot later be replaced " +
                    "by a properly signed build."
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
