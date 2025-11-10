plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.vidyapith.vidyapith_hybrid_app"
    compileSdk = 36 // or flutter.compileSdkVersion
    ndkVersion = "29.0.14206865" // or flutter.ndkVersion

    defaultConfig {
        applicationId = "com.vidyapith.vidyapith_hybrid_app"
        minSdk = flutter.minSdkVersion // or flutter.minSdkVersion
        targetSdk = 36 // or flutter.targetSdkVersion
        versionCode = 3 // or flutter.versionCode
        versionName = "1.0.2" // or flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

flutter {
    source = "../.."
}
