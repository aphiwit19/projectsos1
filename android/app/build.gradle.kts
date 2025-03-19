plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // id("com.google.gms.google-services") // คอมเมนต์ไว้ ถ้าจะใช้ Firebase ค่อยเปิด
}

android {
    namespace = "com.example.projectappsos"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.projectappsos"
        minSdk = 23  // เปลี่ยนจาก 21 เป็น 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// dependencies {
//     implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
//     implementation("com.google.firebase:firebase-auth")
//     implementation("com.google.firebase:firebase-firestore")
// }