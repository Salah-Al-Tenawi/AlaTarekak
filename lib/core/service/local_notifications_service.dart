import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:alatarekak/core/service/notification_router.dart';

/// عرض الإشعار **والتطبيق مفتوح**.
///
/// أندرويد لا يرسم إشعار النظام ما دام التطبيق في المقدمة — يسلّم الرسالة
/// إلى `FirebaseMessaging.onMessage` ويترك العرض للتطبيق. فمن يستعمل
/// «عطريقك» حين يُقبل حجزه لا يرى شيئاً، بينما يراه من كان خارجه.
///
/// هذه الخدمة ترسم الإشعار بنفسها في تلك الحالة، على **القناة نفسها**
/// التي يستعملها النظام خارج التطبيق (`atariqak_default`، أهمية عالية)
/// فيبدو الإشعار واحداً في الحالتين: الصوت نفسه والشكل نفسه.
///
/// **لا ازدواج:** `onMessage` لا يُطلق إطلاقاً والتطبيق في الخلفية أو
/// مغلق — تلك حالة النظام وحده.
class LocalNotificationsService {
  LocalNotificationsService._();
  static final LocalNotificationsService instance =
      LocalNotificationsService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// يجب أن يطابق `default_notification_channel_id` في strings.xml،
  /// والقناة التي تُنشئها MainActivity.
  static const String channelId = 'atariqak_default';

  Future<void> init() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          // الأيقونة نفسها التي يستعملها FCM خارج التطبيق
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onTap,
      );
      _ready = true;
    } catch (e) {
      // تعذّرت التهيئة — يبقى الإشعار خارج التطبيق يعمل، وتُفقد
      // نسخة المقدمة وحدها بدل أن ينهار التطبيق
      debugPrint('[Push] تعذّرت تهيئة إشعارات المقدمة: $e');
    }
  }

  /// يعرض رسالة FCM.
  ///
  /// **النصّ من مصدرين:** كتلة `notification` إن أرسلها الخادم، وإلا من
  /// `data` نفسها. كثير من الخوادم ترسل `data` وحدها ليتحكّم العميل
  /// بالعرض — وأندرويد **لا يرسم شيئاً** لرسالة بلا كتلة `notification`
  /// مهما كانت حالة التطبيق، فلا يرى المستخدم إشعاراً إطلاقاً: لا صوت،
  /// ولا شريط منبثق، ولا سطر في ستارة الإشعارات.
  ///
  /// ولا نعرض شيئاً حين لا يرسل الخادم نصّاً في أيّهما: تلك رسالة
  /// **صامتة** لتحديث الواجهة، واختراع عنوان لها يُظهر إشعارات لم يقصدها.
  Future<void> showFromMessage(RemoteMessage message) async {
    if (!_ready) return;

    final (title, body) = textOf(message);
    if (title.isEmpty && body.isEmpty) return;

    try {
      await _plugin.show(
        // معرّف الإشعار الواصل يمنع تكديس نسخ من الحدث نفسه
        id: _idOf(message),
        title: title.isEmpty ? null : title,
        body: body.isEmpty ? null : body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'إشعارات الرحلات والحجوزات',
            channelDescription:
                'تنبيهات إنشاء الرحلات وقبول الحجوزات والرسائل',
            importance: Importance.high, // منبثق فوق الشاشة
            priority: Priority.high,
            icon: 'ic_notification',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint('[Push] تعذّر عرض إشعار المقدمة: $e');
    }
  }

  /// نصّ الإشعار: كتلة `notification` أولاً ثم `data`.
  ///
  /// أسماء الحقول في `data` تتبع ما يرسله الباك إند في قائمة الإشعارات
  /// (`title` و`message`)، ونقبل `body` معها لأنها الاسم الشائع في FCM.
  static (String, String) textOf(RemoteMessage message) {
    final n = message.notification;
    final d = message.data;

    final title = (n?.title ?? d['title'] ?? '').toString().trim();
    final body =
        (n?.body ?? d['body'] ?? d['message'] ?? '').toString().trim();
    return (title, body);
  }

  /// معرّف ثابت للحدث الواحد: إشعار الحجز نفسه لا يظهر مرتين لو وصل
  /// مرتين. وعند غيابه نعود إلى معرّف متغيّر بدل تصفير كل الإشعارات.
  int _idOf(RemoteMessage message) {
    final raw = message.data['id'] ?? message.data['notification_id'];
    final parsed = int.tryParse('${raw ?? ''}');
    if (parsed != null) return parsed;
    return DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
  }

  /// الضغط على إشعار رسمناه نحن — يمرّ على الموجّه نفسه الذي يستعمله
  /// إشعار النظام وقائمة الإشعارات.
  static void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map) {
        NotificationRouter.openFromPush(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      debugPrint('[Push] حمولة إشعار غير صالحة: $e');
    }
  }
}
