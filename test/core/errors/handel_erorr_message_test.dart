import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبارات تعريب رسائل الباك إند — القاعدة: لا تُعرض رسالة إنجليزية للمستخدم.
void main() {
  group('HandelErorrMessage — الأخطاء العامة المشتركة', () {
    test('unauthenticated → رسالة انتهاء الجلسة (في أي نقطة)', () {
      expect(HandelErorrMessage.login('Unauthenticated.'),
          HandelErorrMessage.errSession);
      expect(HandelErorrMessage.bookingMe('Unauthenticated.'),
          HandelErorrMessage.errSession);
    });

    test('validation failed → رسالة التحقق من المدخلات', () {
      expect(HandelErorrMessage.singin('Validation failed'),
          HandelErorrMessage.errValidation);
    });

    test('المطابقة غير حساسة لحالة الأحرف والفراغات', () {
      expect(HandelErorrMessage.login('  INVALID CREDENTIALS  '),
          'البريد الإلكتروني أو كلمة المرور غير صحيحة');
    });

    test('رسالة غير معروفة → الرسالة الاحتياطية العامة', () {
      expect(HandelErorrMessage.login('Something very unexpected'),
          HandelErorrMessage.errServer);
    });
  });

  group('HandelErorrMessage — المصادقة', () {
    test('invalid credentials → رسالة الدخول الخاطئ', () {
      expect(HandelErorrMessage.login('Invalid credentials'),
          'البريد الإلكتروني أو كلمة المرور غير صحيحة');
    });

    test('already registered → بريد مسجل مسبقاً', () {
      expect(HandelErorrMessage.singin('Email already registered'),
          'هذا البريد الإلكتروني مسجل مسبقاً، يرجى تسجيل الدخول');
    });
  });

  group('HandelErorrMessage — الحجز', () {
    test('trust score مع رقم متغير داخل الرسالة → رسالة نقاط الثقة', () {
      expect(
        HandelErorrMessage.bookAset(
            'Your trust score (35) is too low to book rides'),
        'نقاط الثقة لديك غير كافية لحجز الرحلات (الحد الأدنى 40)',
      );
    });

    test('not enough seats → عدد المقاعد غير كافٍ', () {
      expect(HandelErorrMessage.bookAset('Not enough seats available'),
          'عدد المقاعد المتاحة غير كافٍ');
    });

    test('bookAset لها fallback خاص بالحجز وليس العام', () {
      expect(HandelErorrMessage.bookAset('weird unknown error'),
          'تعذر إتمام الحجز، حاول مجدداً');
    });

    test('cancelBooking: less than 2 hours → منع الإلغاء المتأخر', () {
      expect(
        HandelErorrMessage.cancelBooking(
            'Cannot cancel less than 2 hours before departure'),
        'لا يمكن إلغاء الحجز قبل أقل من ساعتين من موعد الانطلاق',
      );
    });
  });

  group('HandelErorrMessage — الرحلات', () {
    test('إنشاء رحلة بدون توثيق سائق', () {
      expect(
        HandelErorrMessage.createWithRoute(
            'You must be verified as a driver to create rides'),
        'يجب توثيق حسابك كسائق قبل إنشاء الرحلات',
      );
    });

    test('إلغاء رحلة قبل أقل من ساعة', () {
      expect(
        HandelErorrMessage.cancelRide(
            'Cannot cancel less than 1 hour before departure'),
        'لا يمكن إلغاء الرحلة قبل أقل من ساعة من موعد الانطلاق',
      );
    });
  });

  group('HandelErorrMessage — المحفظة', () {
    test('insufficient balance → الرصيد غير كافٍ', () {
      expect(HandelErorrMessage.requestWithdraw('Insufficient balance'),
          'الرصيد غير كافٍ');
    });

    test('wallet not found → دعوة لإنشاء محفظة', () {
      expect(HandelErorrMessage.checkbalance('Wallet not found'),
          'لا تملك محفظة بعد، أنشئ واحدة الآن');
    });
  });
}
