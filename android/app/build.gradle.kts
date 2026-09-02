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
            // **Fails rather than falling back to the debug key** (known issue
            // 13). A debug-signed release APK is undistributable and, worse,
            // cannot be replaced by a properly signed build without every user
            // uninstalling first -- so the failure has to happen here, at build
            // time, and not after the thing has been handed to someone.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                throw GradleException(
                    "Release build requires android/key.properties, which is " +
                        "absent. Copy android/key.properties.example, create a " +
                        "keystore, and fill it in -- see docs/RELEASE.md. " +
                        "Refusing to sign a release build with the debug key: " +
                        "the result cannot be distributed and cannot later be " +
                        "replaced by a properly signed build."
                )
            }
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
