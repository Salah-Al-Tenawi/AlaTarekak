import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/api_envelope.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/policy/data/model/policy_content_model.dart';
import 'package:alatarekak/features/policy/domain/entity/policy_content.dart';

abstract class PolicyRemoteDataSource {
  Future<PolicyContent> getPolicies();
}

class PolicyRemoteDataSourceIm extends PolicyRemoteDataSource {
  final ApiConSumer api;

  PolicyRemoteDataSourceIm({required this.api});

  /// `GET /policies` — مسار عام لا يشترط تسجيل دخول: شاشة إنشاء الحساب
  /// تعرض السياسة قبل أن يكون للمستخدم حساب أصلاً.
  @override
  Future<PolicyContent> getPolicies() async {
    final json = await api.get(ApiEndPoint.policies);
    if (!ApiEnvelope.isOk(json)) {
      throw ServerExpcptions(
        error: json is Map<String, dynamic>
            ? Filuar.fromJson(json)
            : const Filuar(message: 'حدث خطأ غير متوقع'),
      );
    }
    final data = ApiEnvelope.data(json);
    if (data is! Map) {
      throw ServerExpcptions(
          error: const Filuar(message: 'حدث خطأ غير متوقع'));
    }
    return PolicyContentModel.fromJson(Map<String, dynamic>.from(data));
  }
}
