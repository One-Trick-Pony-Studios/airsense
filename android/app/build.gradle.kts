plugins {
    id("com.android.application")
    // kotlin-android is no longer applied here; Flutter injects it via
    // the built-in Kotlin support (android.builtInKotlin=true in gradle.properties).
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.airsense"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.airsense"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    applicationVariants.all {
        outputs.all {
            val apkOutput = this as? com.android.build.gradle.api.ApkVariantOutput
            if (apkOutput != null) {
                val isRelease = name.contains("release", ignoreCase = true)
                apkOutput.outputFileName = if (isRelease) "airsense.apk" else "airsense-debug.apk"
            }
        }
    }
}

flutter {
    source = "../.."
}
