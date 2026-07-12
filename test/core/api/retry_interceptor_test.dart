import 'dart:typed_data';

import 'package:alatarekak/core/api/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// محول HTTP وهمي: يفشل [failTimes] مرة بخطأ شبكة ثم ينجح.
class _FlakyAdapter implements HttpClientAdapter {
  _FlakyAdapter({required this.failTimes, this.failStatus});

  final int failTimes;

  /// إن حُدد: الفشل يكون برد HTTP بهذا الكود بدل خطأ اتصال.
  final int? failStatus;

  int calls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls++;
    if (calls <= failTimes) {
      if (failStatus != null) {
        return ResponseBody.fromString('{"message":"gateway error"}',
            failStatus!,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            });
      }
      throw DioException.connectionError(
          requestOptions: options, reason: 'connection refused');
    }
    return ResponseBody.fromString('{"ok":true}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// NFR-17: اختبارات آلية إعادة المحاولة.
void main() {
  Dio buildDio(_FlakyAdapter adapter, {int maxRetries = 2}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      maxRetries: maxRetries,
      delays: const [Duration.zero], // بلا انتظار في الاختبارات
    ));
    return dio;
  }

  group('RetryInterceptor', () {
    test('GET يفشل مرتين بخطأ اتصال ثم ينجح — يعاد تلقائياً حتى النجاح',
        () async {
      final adapter = _FlakyAdapter(failTimes: 2);
      final dio = buildDio(adapter);

      final response = await dio.get('/rides');

      expect(response.statusCode, 200);
      expect(adapter.calls, 3, reason: 'محاولة أصلية + إعادتان');
    });

    test('GET يفشل أكثر من الحد الأقصى — يرمي الخطأ بعد استنفاد المحاولات',
        () async {
      final adapter = _FlakyAdapter(failTimes: 10);
      final dio = buildDio(adapter, maxRetries: 2);

      await expectLater(dio.get('/rides'), throwsA(isA<DioException>()));
      expect(adapter.calls, 3, reason: 'محاولة أصلية + إعادتان فقط');
    });

    test('POST لا يُعاد أبداً حتى مع خطأ اتصال (حماية العمليات المالية SAF-04)',
        () async {
      final adapter = _FlakyAdapter(failTimes: 1);
      final dio = buildDio(adapter);

      await expectLater(
        dio.post('/bookings', data: {'seats': 1}),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1, reason: 'لا إعادة لطلبات الكتابة');
    });

    test('GET مع عطل بوابة عابر 503 — يعاد حتى النجاح', () async {
      final adapter = _FlakyAdapter(failTimes: 1, failStatus: 503);
      final dio = buildDio(adapter);

      final response = await dio.get('/rides');

      expect(response.statusCode, 200);
      expect(adapter.calls, 2);
    });

    test('GET مع خطأ منطقي 404 — لا يُعاد (الخطأ ليس عابراً)', () async {
      final adapter = _FlakyAdapter(failTimes: 10, failStatus: 404);
      final dio = buildDio(adapter);

      await expectLater(dio.get('/rides/999'), throwsA(isA<DioException>()));
      expect(adapter.calls, 1);
    });
  });
}
