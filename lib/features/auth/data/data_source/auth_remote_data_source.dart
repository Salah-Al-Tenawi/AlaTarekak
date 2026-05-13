import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/features/auth/data/model/token_model.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/auth/domain/usecase/params/reset_password_params.dart';
import 'package:alatarekak/features/auth/domain/usecase/params/sing_up_params.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRemoteDataSource {
  final ApiConSumer api;
  AuthRemoteDataSource({required this.api});

  Future<UserModel> signInWithEmail(String email, String password);
  Future<Unit> singIn(SignUpParams params);
  Future<UserModel> verifySinginOtp(String email, String otp);
  Future<Unit> resendOtpSinging(String email);

  Future<Unit> forgotPassword(String email);
  Future<String> verfiyOtpResetPassword(String email, String otp);
  Future<Unit> resetPassword(ResetPasswordParams params);

  Future<TokenModel> refreshToken(String token);
  Future<Unit> logout();
}

class AuthRemoteDataSourceIM extends AuthRemoteDataSource {
  AuthRemoteDataSourceIM({required super.api});

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final response = await api.post(
      ApiEndPoint.login,
      data: {ApiKey.email: email, ApiKey.password: password},
    );
    return UserModel.fromjson(response);
  }

  @override
  Future<Unit> singIn(SignUpParams params) async {
    await api.post(ApiEndPoint.singin, data: {
      ApiKey.firstName: params.firstName,
      ApiKey.lastName: params.lastName,
      ApiKey.email: params.email,
      ApiKey.password: params.password,
      ApiKey.passwordConfirm: params.confirmPassword,
      ApiKey.gender: params.gender,
      ApiKey.address: params.address,
    });
    return unit;
  }

  @override
  Future<UserModel> verifySinginOtp(String email, String otp) async {
    final response = await api.post(
      ApiEndPoint.emailVerfivaction,
      data: {ApiKey.email: email, ApiKey.otpCode: otp},
    );
    return UserModel.fromjson(response);
  }

  @override
  Future<Unit> resendOtpSinging(String email) async {
    await api.post(ApiEndPoint.resendOtp, data: {ApiKey.email: email});
    return unit;
  }

  @override
  Future<Unit> forgotPassword(String email) async {
    await api.post(ApiEndPoint.forgetPassword, data: {ApiKey.email: email});
    return unit;
  }
  @override
  Future<String> verfiyOtpResetPassword(String email, String otp) async {
    final response = await api.post(
      ApiEndPoint.verfiyOtpforgetPassword,
      data: {ApiKey.email: email, ApiKey.otpCode: otp},
    );
    final payload = (response is Map && response.containsKey('data'))
        ? response['data'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return payload['reset_token'] as String? ?? '';
  }

  @override
  Future<Unit> resetPassword(ResetPasswordParams params) async {
    await api.post(ApiEndPoint.resetPassword, data: {
      ApiKey.resetToken: params.resetToken,
      
      ApiKey.password: params.newPassword,
      ApiKey.passwordConfirm: params.confirmPassword,
    });
    return unit;
  }

  @override
  Future<TokenModel> refreshToken(String token) async {
    final response = await api.post(
      ApiEndPoint.refreshToken,
      data: {ApiKey.refreshToken: token},
    );
    return TokenModel.fromJson(response['tokens']);
  }

  @override
  Future<Unit> logout() async {
    await api.post(ApiEndPoint.logout);
    return unit;
  }
}
