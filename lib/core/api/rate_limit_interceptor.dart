import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// معالجة 429 Too Many Requests مركزياً (باك-إند v5.8.0).
///
/// الخادم يضع مُحدِّد معدّل على كل المسارات، ويرد بجسم لا يحوي `success`
/// ولا `status` ولا `code` — بل `message` وحدها — مع ترويسة `Retry-After`
/// بالثواني.
///
/// ثلاث قواعد يفرضها هذا الاعتراض:
///   • 429 ليست خطأ جلسة: لا تسجيل خروج ولا شاشة حظر.
///   • مدة الانتظار تُقرأ من الترويسة لا تُفترض.
///   • إعادة المحاولة التلقائية لطلبات GET وحدها — إعادة POST قد تُنشئ
///     حجزاً أو حركة مالية مكرّرة.
class RateLimitInterceptor extends Interceptor {
  final Dio dio;

  /// أطول انتظار نقبله قبل إعادة محاولة تلقائية. ما زاد عليه يُعاد
  /// للمستخدم برسالة بدل تجميد الشاشة.
  final int maxAutoRetrySeconds;

  RateLimitInterceptor({required this.dio, this.maxAutoRetrySeconds = 15});

  static const _kRetried = 'rate_limit_retried';

  /// نص يلتقطه [HandelErorrMessage] ليعرض رسالة عربية بعدد الثواني.
  static String messageFor(int seconds) =>
      'Too Many Attempts. retry after $seconds seconds';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 429) return handler.next(err);

    final seconds = _retryAfter(err.response);
    final isGet = err.requestOptions.method.toUpperCase() == 'GET';
    final alreadyRetried = err.requestOptions.extra[_kRetried] == true;

    debugPrint('[RateLimit] 429 على ${err.requestOptions.path} '
        '— انتظار $seconds ثانية');

    // محاولة واحدة تلقائية، للقراءة فقط، وبانتظار معقول
    if (isGet && !alreadyRetried && seconds > 0 && seconds <= maxAutoRetrySeconds) {
      await Future.delayed(Duration(seconds: seconds));
      final options = err.requestOptions..extra[_kRetried] = true;
      try {
        return handler.resolve(await dio.fetch(options));
      } on DioException catch (retryErr) {
        return handler.next(_withArabicHint(retryErr, seconds));
      }
    }

    return handler.next(_withArabicHint(err, seconds));
  }

  /// الترويسة هي المصدر الوحيد للمدة؛ 60 احتياطي إن غابت أو فسدت.
  int _retryAfter(Response? response) {
    final raw = response?.headers.value('retry-after');
    return int.tryParse(raw?.trim() ?? '') ?? 60;
  }

  /// نُثبّت عدد الثواني داخل نصّ الرسالة لأن طبقة الأخطاء تنقل الرسالة
  /// وحدها إلى المترجم، فلا تصل الترويسات إلى الواجهة.
  DioException _withArabicHint(DioException err, int seconds) {
    final response = err.response;
    if (response == null) return err;

    final data = response.data;
    final body = data is Map<String, dynamic>
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    body['message'] = messageFor(seconds);
    body['retry_after'] = seconds;

    return err.copyWith(
      response: Response(
        requestOptions: response.requestOptions,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        headers: response.headers,
        data: body,
      ),
    );
  }
}
