plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read Flutter's SDK values after applying the Flutter Gradle plugin.
val flutterCompileSdk = flutter.compileSdkVersion
val flutterMinSdk = flutter.minSdkVersion
val flutterTargetSdk = flutter.targetSdkVersion

// Use the public AGP API. The legacy Project.android(BaseAppModuleExtension)
// accessor is deprecated on AGP 9.
extensions.configure<com.android.build.api.dsl.ApplicationExtension> {
    namespace = "com.bagisto.bagisto_flutter"
    compileSdk = flutterCompileSdk
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.webkul.bagisto.mobikul"
        minSdk = flutterMinSdk
        targetSdk = flutterTargetSdk
        versionCode = 246
        versionName = "2.4.6"
    }

    buildTypes {
        getByName("release") {
            // Debug signing is retained only for the installable CI test APK.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// kotlinOptions is deprecated in Kotlin Gradle Plugin 2.4; use compilerOptions.
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

configurations.all {
    exclude(group = "com.google.firebase", module = "firebase-iid")
}

dependencies {
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("com.google.android.material:material:1.12.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
