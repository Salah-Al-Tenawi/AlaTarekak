import 'package:hive_flutter/hive_flutter.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(UserModelAdapter());

    await Future.wait([
      Hive.openBox<String>(HiveBoxes.profileBoxName),
      Hive.openBox<UserModel>(HiveBoxes.authBoxName),
      Hive.openBox(HiveBoxes.tripBoxName),
      Hive.openBox(HiveBoxes.settingsBoxName),
      Hive.openBox<String>(HiveBoxes.cacheBoxName),
    ]);
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