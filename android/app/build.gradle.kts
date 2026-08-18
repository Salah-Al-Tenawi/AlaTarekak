import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// FCM: مُلحق google-services يفشل البناء إن غاب google-services.json،
// والملف يُنزَّل من وحدة تحكم Firebase ولا يدخل git. فيُطبَّق متى وُجد
// فقط — كما يُقرأ key.properties أدناه — ليبقى البناء عاملاً لمن لم
// يضعه بعد، وتُفعَّل الإشعارات لحظة وضعه بلا تعديل شيفرة.
val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.lifecycle(
        "[FCM] google-services.json غير موجود في android/app — " +
            "إشعارات Firebase معطّلة في هذا البناء.",
    )
}

// بيانات توقيع الإصدار — تُقرأ من android/key.properties (خارج git).
// انظر docs/release_signing.md لتفاصيل النسخ الاحتياطي.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "me.onwayride.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // يلزمه flutter_local_notifications 10+ حتى لو لم نستعمل
        // الإشعارات المجدولة — انظر dependencies في آخر الملف.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // ⚠️ مؤقّت — يُعاد إلى "me.onwayride.app" قبل النشر على Google Play.
        //
        // سجّل الباك-إند تطبيق أندرويد في مشروع Firebase باسم الحزمة
        // GRADUATION.PROJECT بدل اسمنا، ومُلحق google-services يفشل البناء
        // إن لم يطابق applicationId مدخلاً في الملف. غُيّر هنا لفكّ الحصار
        // عن اختبار الإشعارات ريثما يُرسلون ملفاً مصحَّحاً.
        //
        // **applicationId هوية دائمة على Google Play لا تُغيَّر بعد أول
        // نشر.** فقبل النشر: اطلب google-services.json لحزمة
        // me.onwayride.app، أعِد السطر أدناه، وأعِد تثبيت التطبيق على
        // أجهزة المجرِّبين (أندرويد يعتبره تطبيقاً آخر).
        applicationId = "GRADUATION.PROJECT"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // مثبتة صراحة وفق الـ SRS: يدعم التطبيق Android 8.0 (API 26) أو أحدث.
        // لا تُترك للقيمة الضمنية flutter.minSdkVersion لأنها تتغير مع ترقيات Flutter.
        minSdk = 26
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
            // توقيع حقيقي عند توفر key.properties، وإلا نعود لمفاتيح debug
            // حتى يبقى `flutter run --release` يعمل لبقية الفريق دون الـ keystore.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
