import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/api_interceptor.dart';
import 'package:alatarekak/core/api/rate_limit_interceptor.dart';
import 'package:alatarekak/core/api/retry_interceptor.dart';
import 'package:alatarekak/core/errors/excptions.dart';

class DioConSumer extends ApiConSumer {
  late Dio dio;

  DioConSumer() {
    dio = Dio();
    dio.options.baseUrl = ApiEndPoint.baserUrl;
    // NFR-17: مهلات صريحة حتى لا يعلق أي طلب إلى ما لا نهاية
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 25);

    // 429 أولاً: تُعالَج وتُترجم قبل أن تصل إلى منطق الجلسة أو إعادة
    // المحاولة العامة، فلا تُفهم خطأ توكن ولا خطأ شبكة عابراً
    dio.interceptors.add(RateLimitInterceptor(dio: dio));
    // NFR-17: إعادة محاولة تلقائية لطلبات GET عند أخطاء الشبكة العابرة
    dio.interceptors.add(RetryInterceptor(dio: dio));
    dio.interceptors.add(ApiInterCeptor());
    // في وضع التطوير فقط — الترويسات تحوي توكن الجلسة والأجساد تحوي
    // بيانات المستخدم، وطباعتها في release تسرّبها لسجل النظام.
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
          request: true,
          responseBody: true,
          requestBody: true,
          requestHeader: true,
          responseHeader: true,
          error: true,
          logPrint: _logInChunks));
    }
  }

  /// سجلّ أندرويد يقصّ السطر الواحد عند نحو ألف محرف، فتصل أجسام الردود
  /// الطويلة مبتورة في منتصف حقل — وهو ما يجعل تشخيص اختلاف شكل الرد
  /// عن النموذج تخميناً. التقسيم هنا يضمن وصول الجسم كاملاً.
  static void _logInChunks(Object? line) {
    final text = line?.toString() ?? '';
    const limit = 800;
    if (text.length <= limit) {
      debugPrint(text);
      return;
    }
    for (var i = 0; i < text.length; i += limit) {
      final end = i + limit < text.length ? i + limit : text.length;
      debugPrint(text.substring(i, end));
    }
  }

  @override
  Future post(
    String path, {
    dynamic data,
    Map<String, dynamic>? header,
    Map<String, dynamic>? queryParameters,
    bool isFomrData = false,
  }) async {
    try {
      final response = await dio.post(
        path,
        data: isFomrData == true ? FormData.fromMap(data) : data,
        queryParameters: queryParameters,
        options: Options(headers: header),
      );

      return response.data;
    } on DioException catch (e) {
      handelDioExcptions(e);
    }
  }

  @override
  Future delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? header,
    Map<String, dynamic>? queryParameters,
    bool isFomrData = false,
  }) async {
    try {
      final response = await dio.delete(path,
          data: isFomrData == true ? FormData.fromMap(data) : data,
          queryParameters: queryParameters,
          options: Options(headers: header));
      return response.data;
    } on DioException catch (e) {
      handelDioExcptions(e);
    }
  }

  @override
  Future get(
    String path, {
    dynamic data,
    Map<String, dynamic>? header,
    Map<String, dynamic>? queryParameters,
    bool isFomrData = false,
  }) async {
    try {
      final response = await dio.get(path,
          data: isFomrData == true ? FormData.fromMap(data) : data,
          queryParameters: queryParameters,
          options: Options(headers: header));
      return response.data;
    } on DioException catch (e) {
      handelDioExcptions(e);
    }
  }

  @override
  Future patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
  bool isFormData = false,
  }) async {
    try {
      final response = await dio.patch(path,
          data: isFormData == true ? FormData.fromMap(data) : data,
          queryParameters: queryParameters,
          options: Options(headers: header));
      return response.data;
    } on DioException catch (e) {
      handelDioExcptions(e);
    }
  }

  @override
  Future put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
    bool isFormData = false,
  }) async {
    try {
      final response = await dio.put(path,
          data: isFormData == true ? FormData.fromMap(data) : data,
          queryParameters: queryParameters,
          options: Options(headers: header));
      return response.data;
    } on DioException catch (e) {
      handelDioExcptions(e);
    }
  }
}
