import 'package:alatarekak/core/service/local_notifications_service.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

/// نصّ الإشعار — من أين يُقرأ.
///
/// أندرويد **لا يرسم شيئاً** لرسالة FCM بلا كتلة `notification`: لا صوت،
/// ولا شريط منبثق، ولا سطر في ستارة الإشعارات — مهما كانت حالة التطبيق.
/// وكثير من الخوادم ترسل `data` وحدها ليتحكّم العميل بالعرض، فيصل
/// الإشعار صامتاً ولا يعلم به المستخدم.

RemoteMessage _msg({
  String? nTitle,
  String? nBody,
  Map<String, dynamic> data = const {},
}) =>
    RemoteMessage(
      notification: (nTitle == null && nBody == null)
          ? null
          : RemoteNotification(title: nTitle, body: nBody),
      data: data,
    );

void main() {
  group('كتلة notification حين يرسلها الخادم', () {
    test('العنوان والنصّ منها', () {
      final (title, body) =
          LocalNotificationsService.textOf(_msg(nTitle: 'حجز جديد', nBody: 'من دمشق'));

      expect(title, 'حجز جديد');
      expect(body, 'من دمشق');
    });

    test('تسبق data حين يرسل الخادم الاثنتين', () {
      final (title, _) = LocalNotificationsService.textOf(
        _msg(nTitle: 'من notification', data: {'title': 'من data'}),
      );
      expect(title, 'من notification');
    });
  });

  group('رسالة data خالصة — الحالة التي لم تكن تظهر', () {
    test('العنوان والنصّ من data', () {
      final (title, body) = LocalNotificationsService.textOf(
        _msg(data: {'title': 'تم إنشاء الرحلة', 'body': 'دمشق ← حمص'}),
      );

      expect(title, 'تم إنشاء الرحلة');
      expect(body, 'دمشق ← حمص');
    });

    test('«message» تُقبل كاسم للنصّ — هو ما يرسله الباك إند في قائمته', () {
      final (_, body) = LocalNotificationsService.textOf(
        _msg(data: {'title': 'x', 'message': 'رحلتك جاهزة'}),
      );
      expect(body, 'رحلتك جاهزة');
    });

    test('القيم غير النصّية تُقرأ ولا ترمي', () {
      final (title, _) =
          LocalNotificationsService.textOf(_msg(data: {'title': 12}));
      expect(title, '12');
    });
  });

  group('ما لا يُعرض', () {
    test('رسالة بلا نصّ في أيّهما — تحديث صامت لا تنبيه', () {
      final (title, body) = LocalNotificationsService.textOf(
        _msg(data: {'type': 'ride_created', 'ride_id': '12'}),
      );

      expect(title, isEmpty);
      expect(body, isEmpty);
    });

    test('نصّ فراغات وحدها لا يُعدّ نصّاً', () {
      final (title, body) =
          LocalNotificationsService.textOf(_msg(data: {'title': '   '}));
      expect(title, isEmpty);
      expect(body, isEmpty);
    });
  });
}
