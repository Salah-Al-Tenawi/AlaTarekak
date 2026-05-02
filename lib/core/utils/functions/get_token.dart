import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';

String? mytoken() {
  UserModel? user = HiveBoxes.authBox.get(HiveKeys.user);
  final String? token = user?.accessToken;
  return token;
}