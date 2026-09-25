import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { load(it) }
    }
}

val mapsApiKey: String =
    localProperties.getProperty("MAPS_API_KEY")
        ?: System.getenv("MAPS_API_KEY")
        ?: ""

android {
    namespace = "com.pulmocare.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.pulmocare.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
        manifestPlaceholders["USES_CLEARTEXT_TRAFFIC"] = "false"
    }

    buildTypes {
        debug {
            // Local development talks to the gateway over HTTP on the emulator.
            manifestPlaceholders["USES_CLEARTEXT_TRAFFIC"] = "true"
        }
        release {
            // Release artifacts are intentionally not signed with the debug key.
            // Configure a proper upload/release keystore in CI before publishing.
            manifestPlaceholders["USES_CLEARTEXT_TRAFFIC"] = "false"
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
}

flutter {
    source = "../.."
}
