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
}
class HiveBoxes {
 
  static const String authBoxName = 'authBox';
  static Box<UserModel> get authBox =>
      Hive.box<UserModel>(authBoxName);



  static const String profileBoxName = 'profileBox';
  static Box<String> get profileBox =>
      Hive.box<String>(profileBoxName);

  // 🚗 Trips
  static const String tripBoxName = 'tripBox';
  static Box get tripBox =>
      Hive.box(tripBoxName);
}