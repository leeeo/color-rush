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
    // Optional: keep passwords outside the repo in a KEY=VALUE file (STORE_PASSWORD, KEY_PASSWORD).
    (keystoreProperties["signingEnvFile"] as String?)?.let { envPath ->
        val env = Properties()
        FileInputStream(file(envPath)).use { env.load(it) }
        mapOf("storePassword" to "STORE_PASSWORD", "keyPassword" to "KEY_PASSWORD").forEach { (prop, key) ->
            env.getProperty(key)?.let { keystoreProperties.putIfAbsent(prop, it) }
        }
    }
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
        // AdMob 앱 ID: 기본은 Google 공식 테스트 앱 ID, release만 실제 ID (아래 buildTypes)
        manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
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
            manifestPlaceholders["admobAppId"] = "ca-app-pub-9901401078434900~7873330472"
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
