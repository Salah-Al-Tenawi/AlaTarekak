import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';

int? myid() {
  UserModel? user = HiveBoxes.authBox.get(HiveKeys.user);
  final int? id = user?.id;
  return id;
}


