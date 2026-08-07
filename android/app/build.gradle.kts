 import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.app.networthtracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }
    
    signingConfigs {
        create("release") {
            keyAlias = "key0"
            keyPassword = "networth_tracker"
            storeFile = rootProject.file("networth_tracker.jks")
            storePassword = "networth_tracker"
        }
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.app.networthtracker"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Add core library desugaring dependency
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.biometric:biometric:1.1.0")
    implementation("androidx.appcompat:appcompat:1.6.1")


    //MANDATORY for App Inbox
    implementation("androidx.appcompat:appcompat:1.3.1")
    implementation("androidx.recyclerview:recyclerview:1.2.1")
    implementation("androidx.viewpager:viewpager:1.0.0")
    implementation("com.google.android.material:material:1.4.0")
    implementation("com.github.bumptech.glide:glide:4.12.0")
        
    //For CleverTap Android SDK v3.6.4 and above, add the following line of code
    implementation("com.android.installreferrer:installreferrer:2.2")

    //Optional AndroidX Media3 Libraries for Audio/Video Inbox Messages. Audio/Video messages will be dropped without these dependencies
    implementation("androidx.media3:media3-exoplayer:1.1.1")
    implementation("androidx.media3:media3-exoplayer-hls:1.1.1")
    implementation("androidx.media3:media3-ui:1.1.1")
}

// Fix for Gradle incremental build issue with Branch SDK
afterEvaluate {
    tasks.matching { it.name.contains("merge") && it.name.contains("Assets") }.configureEach {
        doFirst {
            // Ensure the output directory exists
            val outputDir = outputs.files.files.firstOrNull()
            outputDir?.mkdirs()
        }
        // Disable up-to-date checking to avoid incremental build issues
        outputs.upToDateWhen { false }
    }
}
