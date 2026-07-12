import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// NFR-17: إعادة المحاولة التلقائية لأخطاء الشبكة العابرة
/// (انقطاع اتصال، مهلة، أعطال بوابة 502/503/504).
///
/// تُعاد المحاولة لطلبات GET فقط — طلبات الكتابة (حجز، دفع، إلغاء)
/// لا تُكرر تلقائياً حتى لا تُنفَّذ العملية مرتين (SAF-04).
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  /// مهلة الانتظار قبل كل محاولة (تراجع تصاعدي). قابلة للحقن في الاختبارات.
  final List<Duration> delays;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.delays = const [Duration(seconds: 1), Duration(seconds: 2)],
  });

  static const _kAttempt = 'retry_attempt';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra[_kAttempt] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= maxRetries) {
      return handler.next(err);
    }

    final delay = delays.isEmpty
        ? Duration.zero
        : delays[attempt < delays.length ? attempt : delays.length - 1];
    await Future.delayed(delay);

    debugPrint(
        '[Retry] المحاولة ${attempt + 1}/$maxRetries — ${err.requestOptions.path}');

    final options = err.requestOptions..extra[_kAttempt] = attempt + 1;
    try {
      final response = await dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }

  bool _shouldRetry(DioException err) {
    // GET آمنة التكرار؛ أي method أخرى قد تكرر عملية مالية/حجزاً
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        // أعطال بوابة/تحميل عابرة فقط — 4xx وأخطاء 500 المنطقية لا تُكرر
        return status == 502 || status == 503 || status == 504;
      default:
        return false;
    }
  }
}
