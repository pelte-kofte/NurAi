import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use(::load)
    }
}
val isReleaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}

fun requireSigningProperty(key: String): String {
    val value = keystoreProperties.getProperty(key)?.trim()
    if (value.isNullOrEmpty()) {
        throw GradleException(
            "Missing required key '$key' in android/key.properties. " +
                "Copy android/key.properties.example to android/key.properties and fill it.",
        )
    }
    return value
}

android {
    namespace = "com.example.nurai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.nurai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (!keystorePropertiesFile.exists()) {
                if (isReleaseTaskRequested) {
                    throw GradleException(
                        "Release signing requires android/key.properties, but it was not found. " +
                            "Copy android/key.properties.example to android/key.properties and fill it.",
                    )
                }
                return@create
            }

            val storeFilePath = requireSigningProperty("storeFile")
            storeFile = file(storeFilePath)
            if (!storeFile!!.exists()) {
                throw GradleException(
                    "The keystore file defined by storeFile does not exist: $storeFilePath",
                )
            }
            storePassword = requireSigningProperty("storePassword")
            keyAlias = requireSigningProperty("keyAlias")
            keyPassword = requireSigningProperty("keyPassword")
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
