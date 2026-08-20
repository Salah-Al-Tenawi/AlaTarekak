import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// نوع الشكوى `no_show` — للقراءة لا للإرسال.
///
/// حين يبلّغ الطرفان كلٌّ عن غياب الآخر يفتح الخادم شكوى من صنعه بهذا
/// النوع. و`POST /complaints` **لا يقبله** (422)، فعرضه في شبكة اختيار
/// الأنواع كان سيقدّم للمستخدم خياراً يفشل عند الإرسال. وفي المقابل
/// `GET /complaints` يُرجعه، فلا بدّ أن تعرفه شاشة العرض وإلا انكسرت
/// القائمة.
void main() {
  group('تُقرأ من الخادم', () {
    test('«no_show» تُطابَق ولا تسقط إلى «أخرى»', () {
      expect(ComplaintType.fromString('no_show'), ComplaintType.noShow);
    });

    test('لها تسمية الباك إند نفسها', () {
      expect(ComplaintType.noShow.label, 'تعارض تقارير الغياب');
    });

    test('قيمتها في الـ API كما يرسلها الخادم', () {
      expect(ComplaintType.noShow.apiValue, 'no_show');
    });

    test('قيمة مجهولة ما زالت تسقط إلى «أخرى» — لا رمي', () {
      expect(ComplaintType.fromString('teleported'), ComplaintType.other);
      expect(ComplaintType.fromString(null), ComplaintType.other);
    });
  });

  group('ولا تُرسَل', () {
    test('خارج قائمة ما يختاره المستخدم', () {
      expect(ComplaintType.userSubmittable, isNot(contains(ComplaintType.noShow)));
    });

    test('وبقيّة الأنواع الثمانية كلها فيها', () {
      expect(ComplaintType.userSubmittable.length,
          ComplaintType.values.length - 1);

      for (final type in ComplaintType.values) {
        if (type == ComplaintType.noShow) continue;
        expect(ComplaintType.userSubmittable, contains(type),
            reason: '${type.apiValue} يجب أن يبقى قابلاً للإرسال');
      }
    });

    test('الأنواع الثمانية المقبولة عند الخادم بأسمائها', () {
      expect(
        ComplaintType.userSubmittable.map((t) => t.apiValue).toSet(),
        {
          'trip_safety',
          'driver_behavior',
          'passenger_behavior',
          'ride_cancellation',
          'financial_issue',
          'account_issue',
          'technical_issue',
          'other',
        },
      );
    });
  });

  test('لكل نوع تسمية وأيقونة ولونان — لا حالة ناقصة تُسقِط العرض', () {
    for (final type in ComplaintType.values) {
      expect(type.label, isNotEmpty);
      expect(() => type.icon, returnsNormally);
      expect(() => type.color, returnsNormally);
      expect(() => type.bgColor, returnsNormally);
    }
  });
}
