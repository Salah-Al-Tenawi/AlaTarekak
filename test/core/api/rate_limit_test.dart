import 'dart:async';

import 'package:alatarekak/core/api/rate_limit_interceptor.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// جسم 429 كما يرسله الخادم فعلاً: `message` وحدها، بلا success ولا
/// status ولا code.
const _serverBody = {'message': 'Too Many Attempts.'};

DioException _tooManyRequests({
  String method = 'GET',
  String? retryAfter = '47',
  String path = '/rides/search',
}) {
  final options = RequestOptions(path: path, method: method);
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: 429,
      data: _serverBody,
      headers: Headers.fromMap({
        if (retryAfter != null) 'retry-after': [retryAfter],
      }),
    ),
  );
}

void main() {
  group('جسم 429 لا يُسقط طبقة الأخطاء', () {
    test('Filuar تقرأ رسالة بلا success ولا status', () {
      final f = Filuar.fromJson(Map<String, dynamic>.from(_serverBody));
      expect(f.message, 'Too Many Attempts.');
      expect(f.code, isNull);
      expect(f.isValidation, isFalse);
    });

    test('handelDioExcptions لا تنهار على 429', () {
      expect(
        () => handelDioExcptions(_tooManyRequests()),
        throwsA(isA<ServerExpcptions>()),
      );
    });

    test('المغلف الموحّد يعتبرها فشلاً لا نجاحاً', () {
      // الحارس isOk يعتمد success/status وكلاهما غائب
      final json = Map<String, dynamic>.from(_serverBody);
      expect(json['success'] == true || json['status'] == 'success', isFalse);
    });
  });

  group('الرسالة العربية لـ 429', () {
    test('تُكتشف وتحمل عدد الثواني من الترويسة', () {
      final raw = RateLimitInterceptor.messageFor(47);
      expect(HandelErorrMessage.isRateLimited(raw), isTrue);
      expect(HandelErorrMessage.rateLimited(raw), contains('47 ثانية'));
    });

    test('بلا ثوانٍ معروفة تُعرض رسالة عامة لا خطأ سيرفر', () {
      expect(HandelErorrMessage.rateLimited('Too Many Attempts.'),
          HandelErorrMessage.errRateLimited);
    });

    test('كل شاشة محميّة تعرضها بدل «حدث خطأ غير متوقع»', () {
      final raw = RateLimitInterceptor.messageFor(30);
      // عيّنة من خرائط مختلفة تماماً — القاعدة في _common فتسري عليها كلها
      expect(HandelErorrMessage.bookAset(raw), contains('30 ثانية'));
      expect(HandelErorrMessage.notifications(raw), contains('30 ثانية'));
      expect(HandelErorrMessage.complaint(raw), contains('30 ثانية'));
      expect(HandelErorrMessage.checkbalance(raw), contains('30 ثانية'));
    });

    test('شاشات المصادقة تشرح أن الحدّ على الشبكة لا على المستخدم', () {
      final raw = RateLimitInterceptor.messageFor(12);
      final msg = HandelErorrMessage.login(raw);
      expect(msg, contains('الشبكة'));
      expect(msg, contains('12 ثانية'));

      // نفس المعاملة في التسجيل واستعادة كلمة المرور وتأكيد البريد
      expect(HandelErorrMessage.singin(raw), contains('الشبكة'));
      expect(HandelErorrMessage.forgetPassword(raw), contains('الشبكة'));
      expect(HandelErorrMessage.emailVerification(raw), contains('الشبكة'));
    });

    test('429 ليست انتهاء جلسة — لا تُترجم إلى رسالة الخروج', () {
      final msg = HandelErorrMessage.login(RateLimitInterceptor.messageFor(5));
      expect(msg, isNot(HandelErorrMessage.errSession));
    });
  });

  group('RateLimitInterceptor — إعادة المحاولة', () {
    late Dio dio;
    late RateLimitInterceptor interceptor;

    setUp(() {
      dio = Dio();
      interceptor = RateLimitInterceptor(dio: dio, maxAutoRetrySeconds: 15);
    });

    test('POST لا يُعاد تلقائياً مهما قصرت المدة', () async {
      final err = _tooManyRequests(method: 'POST', retryAfter: '1');
      DioException? passed;
      final handler = _CaptureHandler(onNext: (e) => passed = e);

      interceptor.onError(err, handler);
      await handler.done;

      expect(passed, isNotNull,
          reason: 'الحجز والدفع لا يُكرّران تلقائياً');
      expect(passed!.response!.statusCode, 429);
    });

    test('GET بمدة انتظار طويلة لا يُعاد — لا تُجمَّد الشاشة', () async {
      final err = _tooManyRequests(retryAfter: '600');
      DioException? passed;
      final handler = _CaptureHandler(onNext: (e) => passed = e);

      interceptor.onError(err, handler);
      await handler.done;

      expect(passed, isNotNull);
    });

    test('الرسالة المُمرَّرة تحمل ثواني الترويسة', () async {
      final err = _tooManyRequests(method: 'POST', retryAfter: '90');
      DioException? passed;
      final handler = _CaptureHandler(onNext: (e) => passed = e);

      interceptor.onError(err, handler);
      await handler.done;

      final body = passed!.response!.data as Map<String, dynamic>;
      expect(body['retry_after'], 90);
      expect(HandelErorrMessage.rateLimited(body['message'] as String),
          contains('90 ثانية'));
    });

    test('ترويسة مفقودة → 60 ثانية احتياطياً لا انهيار', () async {
      final err = _tooManyRequests(method: 'POST', retryAfter: null);
      DioException? passed;
      final handler = _CaptureHandler(onNext: (e) => passed = e);

      interceptor.onError(err, handler);
      await handler.done;

      expect((passed!.response!.data as Map)['retry_after'], 60);
    });

    test('استجابة غير 429 تمرّ بلا مساس', () async {
      final options = RequestOptions(path: '/rides', method: 'GET');
      final err = DioException(
        requestOptions: options,
        response: Response(
            requestOptions: options,
            statusCode: 500,
            data: {'message': 'Server Error'}),
      );
      DioException? passed;
      final handler = _CaptureHandler(onNext: (e) => passed = e);

      interceptor.onError(err, handler);
      await handler.done;

      expect(passed!.response!.data['message'], 'Server Error');
    });
  });
}

/// يلتقط ما يُمرَّر إلى handler.next دون شبكة حقيقية.
class _CaptureHandler extends ErrorInterceptorHandler {
  final void Function(DioException) onNext;
  final _completer = Completer();

  _CaptureHandler({required this.onNext});

  Future<void> get done => _completer.future;

  @override
  void next(DioException err) {
    onNext(err);
    if (!_completer.isCompleted) _completer.complete();
  }

  @override
  void resolve(Response response) {
    if (!_completer.isCompleted) _completer.complete();
  }

  @override
  void reject(DioException error) {
    onNext(error);
    if (!_completer.isCompleted) _completer.complete();
  }
}
