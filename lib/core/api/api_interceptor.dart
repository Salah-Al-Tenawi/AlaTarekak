import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/chat_socket_service.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';

/// معالجة الجلسة وفق مستند المواصفات §0.4:
/// - TOKEN_INVALID / TOKEN_MISSING ← جرّب refresh ثم أعد الطلب الأصلي
/// - TOKEN_INVALIDATED / USER_INACTIVE / USER_NOT_FOUND / TOKEN_TYPE_INVALID
///   أو فشل الـ refresh ← خروج إجباري لشاشة الدخول
/// - USER_BANNED (403) ← شاشة الحظر (قد يصل على أي طلب محمي)
class ApiInterCeptor extends QueuedInterceptor {
  /// Dio منفصل لطلب الـ refresh حتى لا يمر على هذا الـ interceptor نفسه.
  static final Dio _refreshDio = Dio(BaseOptions(
    headers: {'Accept': 'application/json'},
  ));

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
      final token = _currentUser()?.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final body = err.response?.data;
    final code = body is Map<String, dynamic> ? body['code']?.toString() : null;

    // حظر الحساب — يصل على أي طلب محمي
    if (status == 403 && code == 'USER_BANNED') {
      final ban = body is Map<String, dynamic> && body['ban'] is Map<String, dynamic>
          ? BanInfo.fromJson(body['ban'] as Map<String, dynamic>)
          : null;
      _goToBanScreen(ban);
      return handler.next(err);
    }

    if (status != 401) return handler.next(err);

    // 401 على نقطة refresh نفسها = REFRESH_TOKEN_INVALID ← خروج
    if (err.requestOptions.path.contains('/auth/refresh')) {
      await _hardLogout();
      return handler.next(err);
    }

    // أكواد توجب الخروج الفوري بلا محاولة refresh
    const fatalCodes = {
      'TOKEN_INVALIDATED',
      'USER_INACTIVE',
      'USER_NOT_FOUND',
      'TOKEN_TYPE_INVALID',
    };
    if (fatalCodes.contains(code)) {
      await _hardLogout();
      return handler.next(err);
    }

    // TOKEN_INVALID / TOKEN_MISSING ← refresh ثم إعادة الطلب
    final user = _currentUser();
    if (user == null || user.refreshToken.isEmpty) {
      await _hardLogout();
      return handler.next(err);
    }

    final newAccessToken = await _refreshTokens(user);
    if (newAccessToken == null) {
      await _hardLogout();
      return handler.next(err);
    }

    try {
      final retried = await _retry(err.requestOptions, newAccessToken);
      return handler.resolve(retried);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }

  /// يجدد التوكنات ويحفظها في Hive. يرجع access token الجديد أو null عند الفشل.
  Future<String?> _refreshTokens(UserModel user) async {
    try {
      final response = await _refreshDio.post(
        ApiEndPoint.refreshToken,
        data: {ApiKey.refreshToken: user.refreshToken},
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) return null;

      final tokens = body['tokens'];
      if (tokens is! Map<String, dynamic>) return null;

      final access = tokens['access_token']?.toString();
      final refresh = tokens['refresh_token']?.toString();
      if (access == null || access.isEmpty) return null;

      await HiveBoxes.authBox.put(
        HiveKeys.user,
        user.copyWith(accessToken: access, refreshToken: refresh),
      );
      return access;
    } catch (_) {
      return null;
    }
  }

  Future<Response<dynamic>> _retry(
      RequestOptions options, String accessToken) {
    options.headers['Authorization'] = 'Bearer $accessToken';
    return _refreshDio.fetch(options);
  }

  Future<void> _hardLogout() async {
    await ChatSocketService.instance.disconnect();
    await HiveBoxes.authBox.clear();
    // كاش الميزات (score, notifications, complaints) خاص بالمستخدم
    await HiveBoxes.cacheBox.clear();
    if (Get.currentRoute != RouteName.login) {
      Get.offAllNamed(RouteName.login);
    }
  }

  void _goToBanScreen(BanInfo? ban) {
    if (Get.currentRoute != RouteName.bannedScreen) {
      Get.offAllNamed(RouteName.bannedScreen, arguments: ban);
    }
  }

  UserModel? _currentUser() => HiveBoxes.authBox.get(HiveKeys.user);
}
