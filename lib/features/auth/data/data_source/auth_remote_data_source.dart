
import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/auth/domain/usecase/params/reset_password_params.dart';
import 'package:alatarekak/features/auth/domain/usecase/params/sing_up_params.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRemoteDataSource {
  final ApiConSumer api;
   AuthRemoteDataSource({
    required this.api,
  });

  Future<UserModel> signInWithEmail(String email, String password);
  Future<Unit> singIn(SignUpParams params);
  Future<UserModel> singInWithGoogle();
  Future<Unit> forgotPassword(String email);
  Future<Unit>resetPassword(ResetPasswordParams params);
  Future<UserModel>verifyEmail(String email , String otp);
  Future<Unit> logout();
}

class AuthRemoteDataSourceIM extends AuthRemoteDataSource {
  AuthRemoteDataSourceIM({required super.api});
  
  @override
  Future<Unit> forgotPassword(String email) async{
        await api.post(ApiEndPoint.forgetPassword, data: {ApiKey.email: email});
    return unit;
  }
  
    @override
  Future<Unit> logout() async {
     await api.post(ApiEndPoint.logout,
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});
    return unit;
  } 

  
  @override
  Future<Unit> resetPassword(ResetPasswordParams params) {
    // TODO: implement resetPassword
    throw UnimplementedError();
  }
  
  @override
  Future<UserModel> signInWithEmail(String email, String password)async {
    final response = await api.post(ApiEndPoint.login,
        data: {ApiKey.email: email, ApiKey.password: password});
    final user = UserModel.fromjson(response);
    HiveBoxes.authBox.put(HiveKeys.user, user);
    return user;
  }
  
  @override
  Future<Unit> singIn(SignUpParams params)async {
     await api.post(ApiEndPoint.singin, data: {
      ApiKey.firstName:params.firstName,
      ApiKey.lastName: params.lastName,
      ApiKey.email:    params.email,
      ApiKey.password: params.password,
      ApiKey.passwordConfirm: params.confirmPassword,
      ApiKey.gender: params.gender,
      ApiKey.address:params.address,
    });
    return unit;
  }
  
  @override
  Future<UserModel> singInWithGoogle() {
    // TODO: implement singInWithGoogle
    throw UnimplementedError();
  }
  
  @override
  Future<UserModel> verifyEmail(String email, String otp)async {
    final response =await api.post(ApiEndPoint.baserUrl ,data: { 
     ApiKey.email :email ,
      ApiKey.otpCode :otp
    });
    final user = UserModel.fromjson(response);
    HiveBoxes.authBox.put(HiveKeys.user, user);
    return user;
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
