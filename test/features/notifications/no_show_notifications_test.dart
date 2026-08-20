import 'package:alatarekak/features/notifications/domain/entity/notification_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// إشعارات نظام الغياب: تكرارها، ومفاتيح وجهتها.
///
/// الخادم يرسل **إشعارين لكل بلاغ**: واحداً من الخدمة وآخر من
/// الكونترولر، لهما رقمان مختلفان ونصّان متقاربان عن الحدث نفسه. ويقع
/// ذلك حتى في حالة التعارض. فيُعرض أحدهما ويُخفى توأمه.
NotificationEntity _n(
  String type, {
  int id = 1,
  int? rideId,
  int? bookingId,
  bool isRead = false,
}) =>
    NotificationEntity(
      id: id,
      title: 'x',
      message: 'y',
      category: 'ride',
      type: type,
      isRead: isRead,
      data: {
        if (rideId != null) 'ride_id': rideId,
        if (bookingId != null) 'booking_id': bookingId,
      },
    );

void main() {
  group('العائلة — من يُعدّ توأماً لمن', () {
    test('بلاغ السائق عن راكب: الخدمة والكونترولر عائلة واحدة', () {
      expect(
        NotificationEntity.noShowFamily('noshow_driver_reported_you'),
        NotificationEntity.noShowFamily('no_show_recorded'),
      );
    });

    test('بلاغ الراكب عن سائق: كذلك', () {
      expect(
        NotificationEntity.noShowFamily('noshow_passenger_reported_you'),
        NotificationEntity.noShowFamily('driver_no_show_recorded'),
      );
    });

    test('العائلتان مختلفتان — لا يُخفى بلاغ الطرف الآخر', () {
      expect(
        NotificationEntity.noShowFamily('noshow_driver_reported_you'),
        isNot(NotificationEntity.noShowFamily('noshow_passenger_reported_you')),
      );
    });

    test('ما ليس من الازدواج بلا عائلة — فلا يُخفى سهواً', () {
      for (final type in const [
        'noshow_conflict',
        'noshow_penalty_applied',
        'noshow_resolved_in_your_favor',
        'booking_accepted',
        'chat_message',
        null,
      ]) {
        expect(NotificationEntity.noShowFamily(type), isNull,
            reason: '«$type» إشعار مستقلّ');
      }
    });
  });

  group('مفتاح إزالة التكرار', () {
    test('يجمع التوأمين على الحجز نفسه', () {
      final a = _n('noshow_driver_reported_you', id: 1, bookingId: 7);
      final b = _n('no_show_recorded', id: 2, bookingId: 7);

      expect(a.dedupeKey, isNotNull);
      expect(a.dedupeKey, b.dedupeKey);
    });

    test('ولا يجمع بلاغين على حجزين مختلفين', () {
      final a = _n('noshow_driver_reported_you', id: 1, bookingId: 7);
      final b = _n('noshow_driver_reported_you', id: 2, bookingId: 8);

      expect(a.dedupeKey, isNot(b.dedupeKey));
    });

    test('بلاغ السائق يُجمع بالرحلة حين لا حجز', () {
      final a = _n('noshow_passenger_reported_you', id: 1, rideId: 5);
      final b = _n('driver_no_show_recorded', id: 2, rideId: 5);

      expect(a.dedupeKey, b.dedupeKey);
    });

    test('بلا كيان لا مفتاح — لا يُخفى ما لا نعرف إلامَ ينتمي', () {
      expect(_n('no_show_recorded', id: 1).dedupeKey, isNull);
    });

    test('إشعار عادي بلا مفتاح', () {
      expect(_n('booking_accepted', id: 1, rideId: 5).dedupeKey, isNull);
    });
  });

  group('عناوين الأنواع الخمسة الجديدة', () {
    test('كلّها معرَّبة — لا يسقط أحدها إلى عنوان الخادم', () {
      const types = {
        'noshow_driver_reported_you': 'السائق أبلغ عن غيابك',
        'noshow_passenger_reported_you': 'الراكب أبلغ عن غيابك',
        'noshow_conflict': 'تعارض في تقارير الغياب',
        'noshow_penalty_applied': 'طُبّقت عقوبة الغياب',
        'noshow_resolved_in_your_favor': 'حُسم بلاغ الغياب لصالحك',
      };

      types.forEach((type, expected) {
        expect(_n(type).displayTitle, expected);
      });
    });

    // الاشتقاق من النوع هو ما يُختبَر: `displayCategory` يُقدّم حقل
    // الخادم حين يصل بقيمة حقيقية، والاشتقاق شبكة أمان لغيابه.
    test('التعارض والعقوبة قراران إداريان → system', () {
      expect(NotificationEntity.categoryOf('noshow_conflict'), 'system');
      expect(NotificationEntity.categoryOf('noshow_penalty_applied'), 'system');
    });

    test('حين لا يرسل الخادم تصنيفاً يُشتقّ من النوع', () {
      final entity = NotificationEntity(
        id: 1,
        title: 'x',
        message: 'y',
        category: 'general',
        type: 'noshow_conflict',
        isRead: false,
      );

      expect(entity.displayCategory, 'system');
    });

    test('والباقي أحداث رحلة → ride', () {
      for (final type in const [
        'noshow_driver_reported_you',
        'noshow_passenger_reported_you',
        'noshow_resolved_in_your_favor',
      ]) {
        expect(NotificationEntity.categoryOf(type), 'ride');
      }
    });
  });
}
