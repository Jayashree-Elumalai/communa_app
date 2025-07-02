plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // google services
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.communa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.communa"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase BoM - keeps all Firebase libs in sync
    implementation(platform("com.google.firebase:firebase-bom:33.16.0"))

    // ✅ Firebase services — add more here as needed
    implementation("com.google.firebase:firebase-analytics")
    // Later you can add:
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
}

