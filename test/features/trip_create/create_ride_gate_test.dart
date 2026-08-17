import 'package:alatarekak/features/profiles/domain/entity/car_entity.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/trip_create/domain/create_ride_gate.dart';
import 'package:flutter_test/flutter_test.dart';

/// حارس إنشاء الرحلة.
///
/// كان المستخدم يُدخل الرحلة كاملة — المسار والموعد والمقاعد والسعر ورقم
/// التواصل — ثم يرفضها الخادم لأنه غير موثّق أو بلا مركبة. الشرط معلوم قبل
/// أن يبدأ، فيُفحَص عند الضغط على زرّ الإضافة.

ProfileEntity _profile({
  String verification = 'approved',
  CarEntity? car = const CarEntity(type: 'Toyota Corolla', seats: 4),
}) =>
    ProfileEntity(
      fullname: 'أحمد',
      profilePhoto: null,
      numberOfides: 0,
      totalRating: 0,
      averageRating: 0,
      verification: verification,
      description: '',
      address: 'دمشق',
      gender: 'M',
      car: car,
      comments: const [],
      documents: null,
    );

void main() {
  group('يُسمح بالمتابعة', () {
    test('موثّق ولديه مركبة', () {
      expect(CreateRideGate.check(_profile()), CreateRideBlock.none);
    });

    test('حالة التوثيق بأحرف كبيرة تُقبل', () {
      expect(CreateRideGate.check(_profile(verification: 'APPROVED')),
          CreateRideBlock.none);
    });

    test('ملف غير محمَّل (null) لا يمنع — الخادم يحسم', () {
      expect(CreateRideGate.check(null), CreateRideBlock.none,
          reason: 'منع مستخدم مستوفٍ للشرط أسوأ من تركه يحاول');
    });
  });

  group('يُمنع بسبب التوثيق', () {
    test('لم يبدأ التوثيق', () {
      expect(CreateRideGate.check(_profile(verification: 'none')),
          CreateRideBlock.notVerified);
    });

    test('حالة فارغة أو مجهولة تُعامَل كغير موثّق', () {
      expect(CreateRideGate.check(_profile(verification: '')),
          CreateRideBlock.notVerified);
      expect(CreateRideGate.check(_profile(verification: 'whatever')),
          CreateRideBlock.notVerified);
    });

    test('قيد المراجعة', () {
      expect(CreateRideGate.check(_profile(verification: 'pending')),
          CreateRideBlock.verificationPending);
    });

    test('مرفوض', () {
      expect(CreateRideGate.check(_profile(verification: 'rejected')),
          CreateRideBlock.verificationRejected);
    });

    test('التوثيق يُفحَص قبل المركبة — الرسالة تخصّ الأهم', () {
      // غير موثّق وبلا مركبة: يُبلَّغ بالتوثيق أولاً لا بالمركبة
      expect(CreateRideGate.check(_profile(verification: 'none', car: null)),
          CreateRideBlock.notVerified);
    });
  });

  group('يُمنع بسبب المركبة', () {
    test('موثّق بلا مركبة', () {
      expect(CreateRideGate.check(_profile(car: null)),
          CreateRideBlock.noCar);
    });

    test('مركبة بنوع فارغ ليست مركبة', () {
      expect(CreateRideGate.check(_profile(car: const CarEntity(type: ''))),
          CreateRideBlock.noCar);
      expect(CreateRideGate.check(_profile(car: const CarEntity(type: '   '))),
          CreateRideBlock.noCar);
      expect(CreateRideGate.check(_profile(car: const CarEntity(type: null))),
          CreateRideBlock.noCar);
    });

    test('نوع موجود ولو بلا بقية الحقول يكفي', () {
      expect(CreateRideGate.check(_profile(car: const CarEntity(type: 'كيا'))),
          CreateRideBlock.none);
    });
  });

  group('نصوص الحوار', () {
    test('كل مانع له عنوان وشرح بالعربية', () {
      for (final block in CreateRideBlock.values) {
        if (block == CreateRideBlock.none) continue;
        expect(CreateRideGate.title(block), isNotEmpty,
            reason: 'العنوان ناقص لـ $block');
        expect(CreateRideGate.message(block).length, greaterThan(30),
            reason: 'الشرح ناقص لـ $block');
      }
    });

    test('المراجعة بلا زرّ إجراء — لا شيء يملكه المستخدم', () {
      expect(
          CreateRideGate.actionLabel(CreateRideBlock.verificationPending),
          isNull);
    });

    test('بقية الموانع لها زرّ يوجّه إلى ما ينقص', () {
      expect(CreateRideGate.actionLabel(CreateRideBlock.notVerified),
          'ابدأ التوثيق');
      expect(CreateRideGate.actionLabel(CreateRideBlock.verificationRejected),
          'إعادة التقديم');
      expect(CreateRideGate.actionLabel(CreateRideBlock.noCar), 'أضف مركبتك');
    });

    test('حالة السماح بلا نصوص', () {
      expect(CreateRideGate.title(CreateRideBlock.none), isEmpty);
      expect(CreateRideGate.message(CreateRideBlock.none), isEmpty);
      expect(CreateRideGate.actionLabel(CreateRideBlock.none), isNull);
    });
  });
}
