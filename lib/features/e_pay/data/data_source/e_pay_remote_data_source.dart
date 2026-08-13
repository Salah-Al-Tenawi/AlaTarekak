
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/features/e_pay/data/model/balance_model.dart';

class EPayRemoteDataSource {
  final DioConSumer api;

  EPayRemoteDataSource({required this.api});

  /// إنشاء المحفظة برقم الهاتف بلا رمز تحقق — رقم الهاتف هو رقم المحفظة.
  /// يُستخدم تلقائياً ضمن تدفّق إنشاء الحساب، ويدوياً من شاشة المحفظة لمن
  /// لم تُنشأ محفظته وقتها (فشل عابر، أو حساب أُنشئ قبل هذه الميزة).
  Future<dynamic> createWalletDirect(String phoneNumber) async {
    final response = await api.post(
      ApiEndPoint.createWalletDirect,
      header: {ApiKey.authorization: "Bearer ${mytoken()}"},
      data: {ApiKey.phoneNumber: phoneNumber},
    );
    return response;
  }

  Future<BalanceModel> getBalance() async {
    final response = await api.get(
      ApiEndPoint.getbalance,
      header: {ApiKey.authorization: "Bearer ${mytoken()}"},
    );
    return BalanceModel.fromJson(response);
  }
}
