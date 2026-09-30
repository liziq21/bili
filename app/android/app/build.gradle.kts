import com.android.build.gradle.internal.api.ApkVariantOutputImpl
import org.jetbrains.kotlin.konan.properties.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bili"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "com.example.bili"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packagingOptions.jniLibs.useLegacyPackaging = true

    val keyProperties = Properties().also {
        val properties = rootProject.file("key.properties")
        if (properties.exists())
            it.load(properties.inputStream())
    }

    val config = keyProperties.getProperty("storeFile")?.let {
        signingConfigs.create("release") {
            storeFile = file(it)
            storePassword = keyProperties.getProperty("storePassword")
            keyAlias = keyProperties.getProperty("keyAlias")
            keyPassword = keyProperties.getProperty("keyPassword")
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    // A release build without signing material must not silently fall back to the
    // debug keystore: the resulting APK installs but cannot be uploaded to any store.
    // CI sets BILI_ALLOW_UNSIGNED_RELEASE to verify that the release variant compiles;
    // such artifacts are for verification only and must not be published.
    val allowUnsignedRelease = System.getenv("BILI_ALLOW_UNSIGNED_RELEASE") == "1"

    buildTypes {
        release {
            signingConfig = config ?: if (allowUnsignedRelease) {
                logger.warn(
                    "BILI_ALLOW_UNSIGNED_RELEASE is set and no key.properties was found — " +
                        "signing the release build with the debug keystore. This artifact " +
                        "is for CI verification only and must not be published."
                )
                signingConfigs["debug"]
            } else {
                throw GradleException(
                    "No release signing config. Provide android/key.properties " +
                        "(storeFile, storePassword, keyAlias, keyPassword), or set " +
                        "BILI_ALLOW_UNSIGNED_RELEASE=1 when you only need the release " +
                        "build to compile."
                )
            }
            if (project.hasProperty("dev")) {
                applicationIdSuffix = ".dev"
                resValue(
                    type = "string",
                    name = "app_name",
                    value = "Bili dev",
                )
            }
//            proguardFiles(
//                getDefaultProguardFile("proguard-android-optimize.txt"),
//                "proguard-rules.pro"
//            )
        }
        debug {
            applicationIdSuffix = ".debug"
        }
    }

    applicationVariants.all {
        val variant = this
        variant.outputs.forEach { output ->
            (output as ApkVariantOutputImpl).versionCodeOverride = flutter.versionCode
        }
    }
}

flutter {
    source = "../.."
}
