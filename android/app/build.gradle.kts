plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.projectappsos"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.projectappsos"
        minSdk = 24 // เพิ่มจาก 23 เป็น 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        
        // เพิ่ม core library desugaring ตามที่ flutter_local_notifications ต้องการ
        multiDexEnabled = true
    }

    compileOptions {
        // เพิ่ม desugaring options
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        jvmToolchain(17)
    }

    kotlinOptions {
        freeCompilerArgs = freeCompilerArgs + listOf("-Xjvm-default=all")
        apiVersion = "2.0"
        languageVersion = "2.0"
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

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.android.gms:play-services-safetynet:18.1.0") // เพิ่ม SafetyNet
    
    // เพิ่ม dependency สำหรับ desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // เพิ่ม multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}