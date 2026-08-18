import 'dart:io';

import 'package:alatarekak/core/service/local_notifications_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// إشعار المقدمة.
///
/// أندرويد لا يرسم إشعار النظام ما دام التطبيق مفتوحاً — يسلّم الرسالة
/// إلى `onMessage` ويترك العرض للتطبيق. فمن يستعمل «عطريقك» حين يُقبل
/// حجزه لم يكن يرى شيئاً، بينما يراه من كان خارجه.

void main() {
  test('قناة المقدمة هي قناة النظام نفسها', () {
    // لو اختلفتا لظهر إشعاران بشكلين وصوتين في إعدادات النظام،
    // ولاختلف سلوكهما حين يغيّر المستخدم إعدادات إحداهما.
    expect(LocalNotificationsService.channelId, 'atariqak_default');
  });

  test('المعرّف يطابق ما في strings.xml وما تُنشئه MainActivity', () async {
    // مصدر الحقيقة الأصلي — لو غُيّر أحدهما دون الآخر لتراجع FCM إلى
    // قناته الاحتياطية «Miscellaneous» بلا ظهور منبثق
    final strings =
        await _read('android/app/src/main/res/values/strings.xml');
    final activity = await _read(
        'android/app/src/main/kotlin/me/onwayride/app/MainActivity.kt');

    expect(strings,
        contains('>${LocalNotificationsService.channelId}<'));
    expect(activity, contains('default_notification_channel_id'));
    expect(activity, contains('IMPORTANCE_HIGH'),
        reason: 'الأهمية العالية هي ما يعطي الصوت والظهور المنبثق');
  });

  test('البيان يشير إلى القناة والأيقونة', () async {
    final manifest =
        await _read('android/app/src/main/AndroidManifest.xml');

    expect(manifest,
        contains('com.google.firebase.messaging.default_notification_channel_id'));
    expect(manifest,
        contains('com.google.firebase.messaging.default_notification_icon'));
    expect(manifest, contains('POST_NOTIFICATIONS'),
        reason: 'أندرويد 13 فأحدث لا يعرض إشعاراً بلا هذا الإذن');
  });

  test('أيقونة الإشعار موجودة — وإلا ظهر مربّع أبيض', () async {
    final icon =
        await _read('android/app/src/main/res/drawable/ic_notification.xml');
    expect(icon, contains('<vector'));
  });
}

Future<String> _read(String path) async => File(path).readAsString();
