import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// رمز حالة HTTP في النصّ المعروض.
///
/// الرسائل العربية واضحة، لكنها لا تقول للدعم أين فشل الطلب. فيُذيَّل بها
/// الرمز — **للأخطاء وحدها**: 2xx نجاحٌ لا يُذيَّل، وما لا رمز له (انقطاع
/// شبكة، مهلة، إلغاء) لا يُختلق له رقم.
void main() {
  group('التذييل نفسه', () {
    test('خطأ الخادم يحمل رمزه', () {
      expect(HandelErorrMessage.withStatus('تعذّر الحفظ', 500),
          'تعذّر الحفظ (500)');
    });

    test('و422 كذلك', () {
      expect(HandelErorrMessage.withStatus('الحجز غير مؤكد', 422),
          'الحجز غير مؤكد (422)');
    });

    test('النجاح لا يُذيَّل — 200 و201', () {
      expect(HandelErorrMessage.withStatus('تم', 200), 'تم');
      expect(HandelErorrMessage.withStatus('تم الإنشاء', 201), 'تم الإنشاء');
      expect(HandelErorrMessage.withStatus('تم', 204), 'تم');
    });

    test('ما لا رمز له يبقى بلا رقم مختلَق', () {
      expect(
          HandelErorrMessage.withStatus(HandelErorrMessage.errNetwork, null),
          HandelErorrMessage.errNetwork,
          reason: 'انقطاع الشبكة لا يصل من الخادم أصلاً');
    });

    test('التحويلات والأخطاء دون 400 تُذيَّل أيضاً', () {
      expect(HandelErorrMessage.withStatus('تعذّر', 302), 'تعذّر (302)');
    });
  });

  group('الفشل يحمل الرمز من طبقة الشبكة', () {
    Filuar failureOf(int status, dynamic body) {
      try {
        handelDioExcptions(DioException(
          requestOptions: RequestOptions(path: '/rides'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/rides'),
            statusCode: status,
            data: body,
          ),
        ));
      } on ServerExpcptions catch (e) {
        return e.error;
      }
      fail('كان يجب أن يُرمى ServerExpcptions');
    }

    test('مغلّف {success:false,message}', () {
      final f = failureOf(422, {
        'success': false,
        'message': 'Only pending bookings can be accepted.',
      });

      expect(f.statusCode, 422);
      expect(f.message, contains('pending'),
          reason: 'الرسالة الخام تبقى نقيّة للمطابقة البرمجية');
    });

    test('مغلّف {status:"error"} — بلاغ الغياب وغيره', () {
      final f = failureOf(422, {
        'status': 'error',
        'message': "Booking #14 is not in 'confirmed' status.",
      });

      expect(f.statusCode, 422);
    });

    test('ردّ بلا جسم: الرمز يبقى', () {
      expect(failureOf(500, null).statusCode, 500);
    });

    test('عطل شبكة: لا رمز', () {
      Filuar? failure;
      try {
        handelDioExcptions(DioException(
          requestOptions: RequestOptions(path: '/rides'),
          type: DioExceptionType.connectionTimeout,
        ));
      } on ServerExpcptions catch (e) {
        failure = e.error;
      }

      expect(failure?.statusCode, isNull);
    });
  });

  group('التعريب والرمز في نداء واحد', () {
    test('الرسالة تُعرَّب ثم تُذيَّل', () {
      const failure = Filuar(
          message: 'Only the ride driver can accept bookings',
          statusCode: 403);

      expect(failure.arabic(HandelErorrMessage.acceptPassanger),
          'متاح لسائق الرحلة فقط (403)');
    });

    test('والرسالة المجهولة تسقط إلى العامّة ومعها رمزها', () {
      const failure =
          Filuar(message: 'Something nobody mapped', statusCode: 500);

      expect(failure.arabic(HandelErorrMessage.showOneRide),
          '${HandelErorrMessage.errServer} (500)',
          reason: 'وهي أحوج ما تكون إلى الرمز: النصّ وحده لا يدلّ الدعم');
    });

    test('فشلٌ بلا رمز يُعرَّب بلا تذييل', () {
      const failure = Filuar(message: 'Invalid credentials');

      expect(failure.arabic(HandelErorrMessage.login),
          'البريد الإلكتروني أو كلمة المرور غير صحيحة');
    });
  });
}
