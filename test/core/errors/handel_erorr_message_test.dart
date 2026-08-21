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

  // ─────────────────────────────────────────────────────────────────────
  // §5 نقاط الثقة — مساران للقراءة، فقيمة المترجم في _common لا في خريطة
  // ─────────────────────────────────────────────────────────────────────

  group('HandelErorrMessage — نقاط الثقة', () {
    test('جلسة منتهية تُقال كما هي لا «خطأ غير متوقع»', () {
      expect(HandelErorrMessage.score('Unauthenticated.'),
          HandelErorrMessage.errSession);
      expect(HandelErorrMessage.score('Unauthenticated.'),
          isNot(HandelErorrMessage.errServer));
    });

    test('تجاوز حدّ الطلبات يقول كم ينتظر', () {
      final message =
          HandelErorrMessage.score('Too Many Attempts. Retry in 30 seconds');
      expect(message, contains('30 ثانية'));
      expect(message, isNot(HandelErorrMessage.errServer));
    });

    test('رسالة لا نعرفها → الاحتياطي العام لا نصّ الخادم', () {
      const raw = 'Score service unavailable';
      expect(HandelErorrMessage.score(raw), HandelErorrMessage.errServer);
      expect(HandelErorrMessage.score(raw), isNot(contains(raw)));
    });

    test('رسالة فارغة (فشل بلا نصّ) لا ترمي', () {
      expect(HandelErorrMessage.score(''), HandelErorrMessage.errServer);
    });
  });

  group('HandelErorrMessage — البحث عن الرحلات', () {
    test('راكب غير موثَّق: رسالة تمهّد لشاشة التوثيق', () {
      const raw = 'You must be verified as a passenger to search rides';
      expect(HandelErorrMessage.search(raw),
          'يجب توثيق حسابك كراكب قبل البحث عن الرحلات');
      expect(HandelErorrMessage.isPassengerNotVerified(raw), isTrue);
    });

    test('كاشف التوثيق لا يُطلق على أخطاء أخرى', () {
      expect(HandelErorrMessage.isPassengerNotVerified('Search failed'),
          isFalse);
      expect(
          HandelErorrMessage.isPassengerNotVerified(
              'You must be verified as a driver'),
          isFalse);
    });

    test('جلسة منتهية في البحث لا تسقط إلى «فشل البحث»', () {
      expect(HandelErorrMessage.search('Unauthenticated.'),
          HandelErorrMessage.errSession);
    });

    test('تاريخ ماضٍ يُقال صراحةً', () {
      expect(
          HandelErorrMessage.search(
              'The departure_date must be a date after or equal to today'),
          'يرجى اختيار تاريخ اليوم أو تاريخ لاحق');
    });
  });

  group('HandelErorrMessage — التقييم والتعليق: الرحلة مرّة واحدة', () {
    // 409 على المسارين: الخادم يحرس أن تُقيَّم الرحلة مرّة وأن يُترك
    // عليها تعليق واحد. وكانت الرسالتان تسقطان إلى «حدث خطأ غير
    // متوقع» — فلا يعرف المستخدم أن تقييمه الأول قائم أصلاً.

    // بلا رموز جديدة: يسقط هذان على الشيفرة القديمة سقوطاً حقيقياً لا
    // بفشل ترجمة — فيبقيان حارسَين على السلوك لا على أسماء الثوابت.
    test('التقييم المكرّر لا يسقط إلى الرسالة العامة', () {
      final text =
          HandelErorrMessage.rateUser('You have already rated this ride.');

      expect(text, isNot(HandelErorrMessage.errServer));
      expect(text, contains('سبق أن قيّمت هذه الرحلة'));
    });

    test('والتعليق المكرّر كذلك', () {
      final text = HandelErorrMessage.commet(
          'You have already left a comment for this ride.');

      expect(text, isNot(HandelErorrMessage.errServer));
      expect(text, contains('سبق أن علّقت على هذه الرحلة'));
    });

    test('تقييم ثانٍ لنفس الرحلة → السبب صريح لا «خطأ غير متوقع»', () {
      expect(HandelErorrMessage.rateUser('You have already rated this ride.'),
          HandelErorrMessage.alreadyRatedRide);
      expect(HandelErorrMessage.alreadyRatedRide,
          isNot(HandelErorrMessage.errServer));
    });

    test('تعليق ثانٍ لنفس الرحلة → السبب صريح كذلك', () {
      expect(
          HandelErorrMessage.commet(
              'You have already left a comment for this ride.'),
          HandelErorrMessage.alreadyCommentedRide);
    });

    test('«تعليق مكرّر» لا يسقط في فخّ مفتاح «comment» العام', () {
      expect(
          HandelErorrMessage.commet(
              'You have already left a comment for this ride.'),
          isNot('التعليق مطلوب (بحد أقصى 500 حرف)'),
          reason: 'الرسالة تحوي كلمة comment، والأسبقية للمفتاح الأدقّ');
    });

    test('التمييز البرمجي: 409 يُعرف قبل أن يُعرَّب', () {
      expect(
          HandelErorrMessage.isAlreadyRated('You have already rated this ride.'),
          isTrue);
      expect(HandelErorrMessage.isAlreadyCommented(
              'You have already left a comment for this ride.'),
          isTrue);
    });

    test('وأخطاء التقييم الأخرى تبقى على حالها', () {
      expect(HandelErorrMessage.isAlreadyRated('The rating field is required'),
          isFalse);
      expect(HandelErorrMessage.rateUser('The rating must be between 1 and 5'),
          'يرجى اختيار تقييم من 1 إلى 5');
    });
  });

  group('HandelErorrMessage — تسجيل الخروج', () {
    test('فشل غير معروف → رسالة الخروج لا الرسالة العامة', () {
      expect(HandelErorrMessage.logout('Logout failed unexpectedly'),
          'فشل تسجيل الخروج، حاول مجدداً');
    });

    test('جلسة منتهية أثناء الخروج تُترجَم أيضاً', () {
      expect(HandelErorrMessage.logout('Unauthenticated.'),
          HandelErorrMessage.errSession);
    });
  });
}
