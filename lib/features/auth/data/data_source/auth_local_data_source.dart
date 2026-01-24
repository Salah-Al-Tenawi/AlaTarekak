import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';

abstract class AuthLocalDataSource {
  UserModel? featchUser();
  String? featchToken();
  Future clearUser();
}

class AuthLocalDataSourceIm extends AuthLocalDataSource {
  @override
  UserModel? featchUser() {
    final user = HiveBoxes.authBox.get(HiveKeys.user) as UserModel?;
    return user;
  }

  @override
  String? featchToken() {
    final user = HiveBoxes.authBox.get(HiveKeys.user) as UserModel?;
    return user?.token;
  }

  

  @override
  Future clearUser() async {
    await HiveBoxes.authBox.delete(HiveKeys.user);
  }
}
