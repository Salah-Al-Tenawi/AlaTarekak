// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';

abstract class AuthRemoteDataSource {
  final DioConSumer api;
  const AuthRemoteDataSource({
    required this.api,
  });

  Future<UserModel> login(String email, String password);
  Future<UserModel> singin(String firstName, String lastName, String gender,
      String email, String address, String password, String verfiyPassword);
  Future forgetPassword(String email);
  Future logout();
  // Future<UserModel> singInWithGoogle();
}

class AuthRemoteDataSourceIM extends AuthRemoteDataSource {
  AuthRemoteDataSourceIM({required super.api});

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await api.post(ApiEndPoint.login,
        data: {ApiKey.email: email, ApiKey.password: password});
    final user = UserModel.fromjson(response);
    HiveBoxes.authBox.put(HiveKeys.user, user);
    return user;
  }

  @override
  Future<UserModel> singin(
      String firstName,
      String lastName,
      String gender,
      String email,
      String address,
      String password,
      String verfiyPassword) async {
    final response = await api.post(ApiEndPoint.singin, data: {
      ApiKey.firstName: firstName,
      ApiKey.lastName: lastName,
      ApiKey.email: email,
      ApiKey.password: password,
      ApiKey.passwordConfirm: verfiyPassword,
      ApiKey.gender: gender,
      ApiKey.address: address,
    });
    final user = UserModel.fromjson(response);
    HiveBoxes.authBox.put(HiveKeys.user, user);
    return user;
  }

// to do
  @override
  Future<dynamic> logout() async {
    final response = await api.post(ApiEndPoint.logout,
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});
    return response;
  }

  @override
  Future forgetPassword(String email) async {
    final response =
        await api.post(ApiEndPoint.forgetPassword, data: {ApiKey.email: email});
    return response;
  }

  // Future<UserModel> singInWithGoogle() async {
    // // 1. افتح صفحة تسجيل الدخول
    // final result = await FlutterWebAuth2.authenticate(
    //   url: ApiEndPoint.googleAuth, // http://localhost:8000/auth/google/redirect
    //   callbackUrlScheme: "alatarekak",
    // );

    // // 2. استخرج الـ code من رابط الـ redirect
    // final code = Uri.parse(result).queryParameters['code'];
    // if (code == null) throw Exception("لم يتم العثور على code");

    // // 3. ابعت الـ code للباكند عشان يرجعلك JWT + بيانات المستخدم
    // final response = await api.post(
    //   ApiEndPoint.googleCallback, // http://localhost:8000/auth/google/callback
    //   data: {"code": code},
    // );

    // // 4. حول البيانات لموديل مستخدم وخزنها
    // final user = UserModel.fromjson(response);
    // HiveBoxes.authBox.put(HiveKeys.user, user);

    // return user;
  // }
}
