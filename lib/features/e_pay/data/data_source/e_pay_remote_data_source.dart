
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/features/e_pay/data/model/balance_model.dart';
import 'package:alatarekak/features/e_pay/data/model/wallet_transaction_model.dart';
import 'package:alatarekak/features/e_pay/domain/entity/wallet_transaction.dart';

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

  /// كشف حساب المحفظة — المصدر الوحيد الذي يكشف `cash_ride_debt`.
  ///
  /// رد هذا المسار بلا مغلَّف (`data`+`links`+`meta` مباشرة)، فلا يمرّ
  /// على `ApiEnvelope.isOk`: وصوله بلا استثناء يعني 2xx.
  Future<WalletStatement> getTransactions({
    int page = 1,
    int perPage = 15,
    String? type,
  }) async {
    final response = await api.get(
      ApiEndPoint.walletTransactions,
      header: {ApiKey.authorization: "Bearer ${mytoken()}"},
      queryParameters: {
        'page': page,
        'per_page': perPage.clamp(1, 100),
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    return WalletTransactionModel.statementFromJson(
        response as Map<String, dynamic>);
  }

  Future<BalanceModel> getBalance() async {
    final response = await api.get(
      ApiEndPoint.getbalance,
      header: {ApiKey.authorization: "Bearer ${mytoken()}"},
    );
    return BalanceModel.fromJson(response);
  }
}
