import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';

abstract class AuthLocalDataSource {
  UserModel? fetchUser();
  String? fetchAccessToken();
  String? fetchRefreshToken();
  Future<void> clearAll();
}

class AuthLocalDataSourceIm extends AuthLocalDataSource {
  @override
  UserModel? fetchUser() {
    final user = HiveBoxes.authBox.get(HiveKeys.user);
    return user;
  }

  @override
  String? fetchAccessToken() {
    final user = HiveBoxes.authBox.get(HiveKeys.user);
    return user?.accessToken;
  }

  @override
  String? fetchRefreshToken() {
    final user = HiveBoxes.authBox.get(HiveKeys.user);
    return user?.refreshToken;
  }

  @override
  Future<void> clearAll() async {
    await HiveBoxes.authBox.clear();
  }
}