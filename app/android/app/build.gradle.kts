import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ═══════════════════════════════════════════════════════════════════════
// 릴리즈 서명 설정 (docs/06-안드로이드-출시.md 참고)
//
// android/key.properties 파일이 있으면 릴리즈 키로 서명하고,
// 없으면 디버그 키로 서명해서 로컬 개발이 항상 동작하게 합니다.
// key.properties 는 절대 git에 커밋하지 마세요! (.gitignore에 이미 등록됨)
// ═══════════════════════════════════════════════════════════════════════
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.leeeo.colorrush"
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
        // 스토어에 등록되는 고유 앱 ID. 첫 출시 전에만 변경 가능합니다.
        applicationId = "com.leeeo.colorrush"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // key.properties가 없으면 디버그 서명 (로컬 테스트용)
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
