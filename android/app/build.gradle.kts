plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

apply(plugin = "com.google.gms.google-services")

dependencies {

  implementation(platform("com.google.firebase:firebase-bom:34.9.0"))

  // Required by flutter_local_notifications (medication reminders) —
  // desugaring backports java.time APIs it depends on to older Android
  // versions. See android { compileOptions { isCoreLibraryDesugaringEnabled } } below.
  coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

}

android {
    namespace = "com.example.medilink"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.medilink"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters.add("arm64-v8a")  // Build only for arm64 to reduce memory usage
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false  // Disable R8 minification to reduce memory usage
            isShrinkResources = false // Disable resource shrinking since minification is disabled
        }
    }
}

flutter {
    source = "../.."
}
