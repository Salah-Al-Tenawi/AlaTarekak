import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';

class ApiInterCeptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept'] = "application/json";

    if (options.path.contains('/v2/directions/driving-car/geojson')) {
      options.headers['Accept'] = "application/geo+json";
    }

    // أضف التوكن تلقائياً لكل طلب إذا لم يكن مضاف يدوياً بقيمة صحيحة
    final existingAuth = options.headers['Authorization'] as String?;
    final hasValidAuth =
        existingAuth != null && existingAuth.length > 'Bearer '.length;

    if (!hasValidAuth) {
      final token = _getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // توكن منتهي أو مفقود ← امسح البيانات وأعد للـ login
      HiveBoxes.authBox.clear();
      Get.offAllNamed(RouteName.login);
    }
    super.onError(err, handler);
  }

  String? _getToken() {
    final UserModel? user = HiveBoxes.authBox.get(HiveKeys.user);
    return user?.accessToken;
  }
}
