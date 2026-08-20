import 'package:alatarekak/features/notifications/domain/entity/notification_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// تغطية أنواع الإشعارات التي يرسلها الباك إند.
///
/// المرجع: `docs/back_end/ride_notifications_reference.pdf` — يُعدّد كل
/// موضع يُطلق إشعاراً في `RideService` و`BookingService` و`RideController`
/// ونوعه ومُستقبِله.
///
/// النوع الذي لا نعرفه يسقط إلى عنوان الخادم — وهو **إنجليزي** (العيب D5)،
/// فيقرأ المستخدم العربي «Ride created» في قائمته.

/// كل الأنواع في المرجع، بترتيب صفحاته.
const _referenceTypes = <String>[
  // RideService.php
  'ride_created',
  'ride_cancelled_driver',
  'ride_finished_no_passengers',
  'ride_completed',
  'driver_no_show_reported',
  'driver_no_show_refund',
  'confirm_completion_needed',
  'ride_cancelled_by_driver',
  // BookingService.php
  'booking_accepted',
  'booking_rejected',
  'passenger_no_show',
  'ride_booked',
  'booking_requested',
  'booking_confirmed',
  'booking_request_sent',
  'booking_cancelled',
  'passenger_cancelled',
  // RideController.php — المسار الموازي بالعربية
  'booking_cancelled_by_passenger',
  'ride_finished',
  'passenger_confirmed',
  'seats_partially_cancelled',
  'no_show_recorded',
  'driver_no_show_recorded',
  // نظام الغياب (تحديث الباك إند c1c0513)
  'noshow_driver_reported_you',
  'noshow_passenger_reported_you',
  'noshow_conflict',
  'noshow_penalty_applied',
  'noshow_resolved_in_your_favor',
];

NotificationEntity _n(String type, {String category = 'general'}) =>
    NotificationEntity(
      id: 1,
      title: 'Ride created',
      message: 'x',
      category: category,
      type: type,
      isRead: false,
    );

void main() {
  group('كل نوع في المرجع له عنوان عربي', () {
    for (final type in _referenceTypes) {
      test('«$type» لا يسقط إلى عنوان الخادم الإنجليزي', () {
        final title = _n(type).displayTitle;

        expect(title, isNot('Ride created'),
            reason: 'غير مغطّى — يُعرض نصّ الخادم كما هو');
        expect(title, isNot(matches(RegExp(r'^[A-Za-z ]+$'))),
            reason: 'العنوان يجب أن يكون عربياً');
      });
    }
  });

  group('التصنيف يُشتقّ من النوع', () {
    // category غير موجود في قاعدة بيانات الباك إند إطلاقاً (يُمرَّر إلى
    // FCM فقط) فيسقط كل إشعار إلى general: أيقونة واحدة ولون واحد للجميع.
    /// قرارا التعارض والعقوبة إداريّان لا حدثا رحلة — يصنّفهما الباك إند
    /// `system` (تحديث c1c0513)، وبقيّة إشعارات الغياب `ride`.
    const systemTypes = {'noshow_conflict', 'noshow_penalty_applied'};

    test('إشعارات الرحلات والحجوزات تُصنَّف ride', () {
      for (final type in _referenceTypes) {
        if (systemTypes.contains(type)) continue;
        expect(NotificationEntity.categoryOf(type), 'ride',
            reason: '«$type» من مرجع الرحلات والحجوزات');
      }
    });

    test('قرارا التعارض والعقوبة يُصنَّفان system', () {
      for (final type in systemTypes) {
        expect(NotificationEntity.categoryOf(type), 'system',
            reason: '«$type» قرار إداري لا حدث رحلة');
      }
    });

    test('الرسائل تُصنَّف chat', () {
      expect(_n('chat_message').displayCategory, 'chat');
    });

    test('التوثيق يُصنَّف profile', () {
      expect(_n('verification_approved').displayCategory, 'profile');
      expect(_n('verification_rejected').displayCategory, 'profile');
    });

    test('المحفظة والشكاوى والحظر تُصنَّف system', () {
      for (final t in const [
        'wallet_charged',
        'charge_request_received',
        'withdraw_request_received',
        'complaint_resolved',
        'account_banned',
      ]) {
        expect(_n(t).displayCategory, 'system', reason: t);
      }
    });

    test('تصنيف حقيقي من الخادم يسود على الاشتقاق', () {
      // إن عرّبه الباك إند لاحقاً فلا نتجاهله
      expect(_n('ride_created', category: 'system').displayCategory, 'system');
    });

    test('نوع مجهول لا يُخترع له تصنيف', () {
      expect(NotificationEntity.categoryOf('something_new'), isNull);
      expect(_n('something_new').displayCategory, 'general');
    });

    test('نوع فارغ أو غائب لا يرمي', () {
      expect(NotificationEntity.categoryOf(null), isNull);
      expect(NotificationEntity.categoryOf('  '), isNull);
    });
  });
}
