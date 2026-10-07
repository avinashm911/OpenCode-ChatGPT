plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.niaverp.niaverp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.niaverp.niaverp"
        // NiAvERP G0 baseline: minSdk 26 / Android 8 per O-M04. Pinned explicitly; do not revert to flutter.minSdkVersion.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // D2-F2: the debug key stays for local runs, but a release build
            // refuses to sign with it silently. Supply the release keystore
            // out-of-band, e.g.:
            //   flutter build apk --release `
            //     -PNIAV_RELEASE_STORE_FILE=/secure/path/niav-release.jks `
            //     -PNIAV_RELEASE_STORE_PASSWORD=... `
            //     -PNIAV_RELEASE_KEY_ALIAS=niav `
            //     -PNIAV_RELEASE_KEY_PASSWORD=...
            // Never create or commit keystores (G0-VER-004 pending; the key
            // questions below are owner input, not invented values).
            //
            // The guard below runs ONLY when a release task is requested
            // (task name contains "release", e.g. assembleRelease): plain
            // `flutter build apk --debug` configures and builds with no
            // keystore and no -P flags. A release build without the
            // properties still fails here with a clear message.
            val releaseRequested = gradle.startParameter.taskNames.any { name ->
                name.contains("release", ignoreCase = true)
            }
            if (releaseRequested) {
                val releaseStoreFile =
                    project.findProperty("NIAV_RELEASE_STORE_FILE") as String?
                if (releaseStoreFile == null) {
                    throw GradleException(
                        "NiAvERP release signing is not configured: re-run with " +
                        "-PNIAV_RELEASE_STORE_FILE (plus STORE_PASSWORD, KEY_ALIAS, " +
                        "KEY_PASSWORD). The debug key is never used for releases."
                    )
                }
                if (!file(releaseStoreFile).exists()) {
                    throw GradleException(
                        "NiAvERP release keystore missing: $releaseStoreFile not found. " +
                        "Verify path and permissions (G0-VER-004 / G5 evidence pending)."
                    )
                }
                signingConfig = signingConfigs.create("niavRelease") {
                    storeFile = file(releaseStoreFile)
                    storePassword = project.findProperty("NIAV_RELEASE_STORE_PASSWORD") as String?
                    keyAlias = project.findProperty("NIAV_RELEASE_KEY_ALIAS") as String?
                    keyPassword = project.findProperty("NIAV_RELEASE_KEY_PASSWORD") as String?
                }
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
