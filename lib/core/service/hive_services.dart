import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:alatarekak/core/service/secure_key_service.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(UserModelAdapter());

    // NFR-14: صندوق الجلسة (يحوي access/refresh tokens) مشفر AES-256
    // بمفتاح محفوظ في Keystore/Keychain عبر flutter_secure_storage.
    try {
      final (:key, :created) = await SecureKeyService.getOrCreateKey();
      await openAuthBoxEncrypted(HiveAesCipher(key), migrateFromPlain: created);
    } catch (e) {
      // تعذر الوصول للتخزين الآمن — نفتح الصندوق بلا تشفير كي لا يتعطل التطبيق
      debugPrint('[Hive] فشل فتح صندوق الجلسة مشفراً: $e');
      await Hive.openBox<UserModel>(HiveBoxes.authBoxName);
    }

    await Future.wait([
      Hive.openBox<String>(HiveBoxes.profileBoxName),
      Hive.openBox(HiveBoxes.tripBoxName),
      Hive.openBox(HiveBoxes.settingsBoxName),
      Hive.openBox<String>(HiveBoxes.cacheBoxName),
    ]);
  }

  /// يفتح صندوق الجلسة مشفراً. عند أول تشغيل بعد تفعيل التشفير
  /// (migrateFromPlain) تُنقل جلسة المستخدم من الصندوق القديم غير المشفر
  /// ثم يُحذف من القرص، فلا يفقد المستخدمون الحاليون تسجيل دخولهم.
  @visibleForTesting
  static Future<Box<UserModel>> openAuthBoxEncrypted(
    HiveAesCipher cipher, {
    required bool migrateFromPlain,
  }) async {
    if (migrateFromPlain && await Hive.boxExists(HiveBoxes.authBoxName)) {
      UserModel? user;
      try {
        final plain = await Hive.openBox<UserModel>(HiveBoxes.authBoxName);
        user = plain.get(HiveKeys.user);
        await plain.deleteFromDisk();
      } catch (_) {
        // صندوق قديم تالف — نحذفه ونبدأ بصندوق مشفر فارغ
        await Hive.deleteBoxFromDisk(HiveBoxes.authBoxName);
      }
      final box = await Hive.openBox<UserModel>(HiveBoxes.authBoxName,
          encryptionCipher: cipher);
      if (user != null) await box.put(HiveKeys.user, user);
      return box;
    }

    return Hive.openBox<UserModel>(HiveBoxes.authBoxName,
        encryptionCipher: cipher);
  }

  static Future<Box<T>> openBox<T>(String boxName) async {
    return await Hive.openBox<T>(boxName);
  }

  static Future<void> closeBox(String boxName) async {
    await Hive.box(boxName).close();
  }

  static Future<void> clearBox(String boxName) async {
    await Hive.box(boxName).clear();
  }

  static Future<void> deleteBox(String boxName) async {
    await Hive.deleteBoxFromDisk(boxName);
  }
}

class HiveKeys {
  static const String user = "user";

  static const String profile = "profile";
  static const String trip = "trip";

  // مفاتيح صندوق الكاش العام
  static const String score = "score";
  static const String notifications = "notifications";
  static const String complaints = "complaints";
}
class HiveBoxes {
 
  static const String authBoxName = 'authBox';
  static Box<UserModel> get authBox =>
      Hive.box<UserModel>(authBoxName);



  static const String profileBoxName = 'profileBox';
  static Box<String> get profileBox =>
      Hive.box<String>(profileBoxName);

  //  Trips
  static const String tripBoxName = 'tripBox';
  static Box get tripBox =>
      Hive.box(tripBoxName);

  //  App settings (theme mode, ...)
  static const String settingsBoxName = 'settingsBox';
  static Box get settingsBox =>
      Hive.box(settingsBoxName);

  // كاش عام للميزات (score, notifications, complaints) — JSON strings.
  // يُمسح بالكامل عند تسجيل الخروج.
  static const String cacheBoxName = 'cacheBox';
  static Box<String> get cacheBox => Hive.box<String>(cacheBoxName);
}