plugins {
    id("com.android.application")
    
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.waka_demo"
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
        applicationId = "com.example.waka_demo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // App ID của Facebook là dữ liệu công khai nhưng tuỳ theo môi trường.
        // Đặt FACEBOOK_APP_ID trong android/gradle.properties trước khi build Android.
        val facebookAppId = providers.gradleProperty("FACEBOOK_APP_ID")
            .orElse("")
            .get()
        val facebookClientToken = providers.gradleProperty("FACEBOOK_CLIENT_TOKEN")
            .orElse("")
            .get()
        resValue("string", "facebook_app_id", facebookAppId)
        resValue("string", "facebook_client_token", facebookClientToken)
        resValue("string", "fb_login_protocol_scheme", "fb$facebookAppId")
    }

    signingConfigs {
        // Keystore debug dùng chung, được commit vào repo.
        //
        // Mặc định Android SDK tự sinh `~/.android/debug.keystore` riêng cho từng
        // máy, nên mỗi người clone repo về lại có một SHA-1 khác nhau và Google
        // Sign-In báo ApiException: 10 (DEVELOPER_ERROR) vì SHA-1 đó chưa đăng ký
        // trên Firebase. Ký bằng keystore cố định này thì mọi máy đều ra cùng một
        // SHA-1 (EB:9F:61:6F:80:90:DB:CE:27:75:40:64:8D:7C:E0:60:FF:F5:42:CB),
        // chỉ cần đăng ký đúng một lần là ai cũng đăng nhập Google được.
        //
        // Đây là khoá debug, không dùng để phát hành lên Play Store.
        getByName("debug") {
            storeFile = file("shared-debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
