import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';

abstract class AuthLocalDataSource {
  UserModel? fetchUser();
  String? fetchAccessToken();
  String? fetchRefreshToken();
  Future<void> saveUser(UserModel user);
  Future<void> updateTokens(String accessToken, String refreshToken);
  Future<void> clearAll();
}

class AuthLocalDataSourceIm extends AuthLocalDataSource {
  @override
  UserModel? fetchUser() => HiveBoxes.authBox.get(HiveKeys.user);

  @override
  String? fetchAccessToken() => fetchUser()?.accessToken;

  @override
  String? fetchRefreshToken() => fetchUser()?.refreshToken;

  @override
  Future<void> saveUser(UserModel user) =>
      HiveBoxes.authBox.put(HiveKeys.user, user);

  @override
  Future<void> updateTokens(String accessToken, String refreshToken) async {
    final user = fetchUser();
    if (user == null) return;
    await HiveBoxes.authBox.put(
      HiveKeys.user,
      user.copyWith(accessToken: accessToken, refreshToken: refreshToken),
    );
  }

  @override
  Future<void> clearAll() => HiveBoxes.authBox.clear();
}
