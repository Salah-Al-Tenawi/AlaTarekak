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

    test('محفظة موجودة أصلاً تُكتشف ولا تُعامل كخطأ', () {
      const raw = 'You already have a wallet.';
      expect(HandelErorrMessage.isWalletAlreadyExists(raw), isTrue);
      expect(HandelErorrMessage.createWalletDirect(raw), 'لديك محفظة بالفعل');
    });

    test('رقم المحفظة مستخدم مسبقاً → رسالة الرقم المستخدم', () {
      expect(
        HandelErorrMessage.createWalletDirect(
            'This phone number is already linked to another wallet.'),
        'هذا الرقم مستخدم في محفظة أخرى',
      );
    });

    test('فشل غير معروف في إنشاء المحفظة → احتياطي خاص بالمحفظة', () {
      expect(
        HandelErorrMessage.createWalletDirect('Something exploded'),
        'تعذر إنشاء المحفظة، حاول مجدداً',
      );
    });
  });

  group('HandelErorrMessage — رسوم الرحلات النقدية (5%)', () {
    test('لا محفظة للسائق → رسالة إنشاء محفظة + كاشف مخصص', () {
      const raw = 'You must create a wallet before creating a cash ride.';
      expect(HandelErorrMessage.isCashRideWalletMissing(raw), isTrue);
      expect(HandelErorrMessage.isCashRideFeeError(raw), isTrue);
      expect(HandelErorrMessage.createWithRoute(raw),
          'يجب إنشاء محفظة إلكترونية قبل إنشاء رحلة بالدفع النقدي');
    });

    test('دين متراكم → توجيه إلى المحفظة بلا استخراج المبلغ من النصّ', () {
      final message = HandelErorrMessage.createWithRoute(
          'You have an outstanding debt of 2,500.00 SYP from previous cash '
          'rides. Please top up your wallet to clear it before creating '
          'another ride.');
      expect(message, contains('رسوم مستحقّة'));
      expect(message, contains('محفظتك'));
      // المبلغ صار يُقرأ من meta.cash_ride_debt في كشف الحساب وتعرضه
      // شاشة المحفظة، فلا يُستخرج من نصّ الخطأ — الاستخراج النصّي هشّ
      // وينكسر بأي تغيير في صياغة الخادم.
      expect(message, isNot(contains('2,500')));
    });

    test('رصيد غير كافٍ → الرسالة تحتفظ بالرسوم والرصيد بالترتيب', () {
      final message = HandelErorrMessage.createWithRoute(
          'Insufficient wallet balance. The creation fee for this ride is '
          '1,000 SYP. Current balance: 250 SYP.');
      expect(message, contains('1,000 ل.س'));
      expect(message, contains('250 ل.س'));
    });

    test('رصيد غير كافٍ خارج سياق الرحلات النقدية يبقى على الرسالة العامة', () {
      expect(HandelErorrMessage.createWithRoute('Insufficient wallet balance'),
          'لا يوجد رصيد كافٍ في المحفظة');
      expect(
          HandelErorrMessage.isCashRideFeeError('Insufficient wallet balance'),
          isFalse);
    });

    test('خطأ رحلة غير نقدي لا يُصنَّف كخطأ رسوم', () {
      expect(
          HandelErorrMessage.isCashRideWalletMissing(
              'You must be verified as a driver'),
          isFalse);
    });
  });
}
