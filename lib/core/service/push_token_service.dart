import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/service/locator_ser.dart';
import 'package:alatarekak/core/service/notification_router.dart';
import 'package:alatarekak/core/service/notifications_badge_service.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';

/// تسجيل/إزالة توكن FCM لدى الباك إند + فتح المحادثة عند الضغط على إشعار.
///
/// يعمل فقط بعد إعداد Firebase للمشروع (google-services.json عبر
/// `flutterfire configure`). إن لم يكن Firebase مهيأً تفشل التهيئة بصمت
/// ويبقى التطبيق يعمل بشكل طبيعي بدون إشعارات push.
class PushTokenService {
  PushTokenService._();
  static final PushTokenService instance = PushTokenService._();

  bool _firebaseReady = false;
  String? _currentToken;

  /// تُستدعى مرة واحدة من main()
  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (e) {
      debugPrint('[Push] Firebase غير مهيأ — إشعارات push معطلة: $e');
      return;
    }

    // رسائل الخلفية والتطبيق مغلق — يجب تسجيله قبل أي استعمال آخر
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // تجديد التوكن تلقائياً لدى الباك إند عند تغيره
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _currentToken = token;
      if ((mytoken() ?? '').isNotEmpty) _registerWithBackend(token);
    });

    // إشعار يصل والتطبيق مفتوح: أندرويد لا يعرض إشعار النظام في المقدمة،
    // فيكفي أن يُضاء الجرس — والقائمة نفسها تُحدَّث من Pusher.
    //
    // `refresh()` لا `+1`: الإشعار الواحد قد يصل من المسارين معاً (FCM
    // وPusher)، وقراءة العدد من الخادم تُصحّح الزيادة المكرّرة بدل أن
    // تُراكمها.
    FirebaseMessaging.onMessage.listen((_) {
      NotificationsBadgeService.instance.refresh();
    });

    // الضغط على إشعار والتطبيق بالخلفية
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    // الضغط على إشعار والتطبيق مغلق كلياً
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);

    // مستخدم مسجل دخوله مسبقاً؟ سجّل التوكن مباشرة
    if ((mytoken() ?? '').isNotEmpty) await registerToken();
  }

  /// POST /push/register — تُستدعى بعد نجاح تسجيل الدخول وعند إقلاع التطبيق
  Future<void> registerToken() async {
    if (!_firebaseReady) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      _currentToken = token;
      await _registerWithBackend(token);
    } catch (e) {
      debugPrint('[Push] فشل تسجيل التوكن: $e');
    }
  }

  Future<void> _registerWithBackend(String token) async {
    final platform = kIsWeb
        ? 'web'
        : Platform.isIOS
            ? 'ios'
            : 'android';
    await getit.get<DioConSumer>().post(
      ApiEndPoint.pushRegister,
      data: {'token': token, 'platform': platform},
    );
    debugPrint('[Push] تم تسجيل توكن FCM لدى الباك إند');
  }

  /// POST /push/remove — تُستدعى قبل مسح جلسة المستخدم عند تسجيل الخروج
  Future<void> removeToken() async {
    if (!_firebaseReady) return;
    try {
      final token =
          _currentToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await getit
            .get<DioConSumer>()
            .post(ApiEndPoint.pushRemove, data: {'token': token});
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('[Push] فشل إزالة التوكن: $e');
    } finally {
      _currentToken = null;
    }
  }

  /// الضغط على إشعار النظام.
  ///
  /// كان يفتح المحادثة وحدها ويتجاهل كل نوع آخر، فيضغط المستخدم إشعار
  /// «قُبل حجزك» أو «رُدَّ على شكواك» فلا يحدث شيء. صار يمرّ على
  /// [NotificationRouter] — الموجّه نفسه الذي تستعمله قائمة الإشعارات.
  void _handleNotificationTap(RemoteMessage message) {
    NotificationRouter.openFromPush(_payloadOf(message));
  }

  /// حمولة الإشعار: `data` أساساً، ويُكمَّل منها العنوان من كتلة
  /// `notification` حين لا يرسله الخادم داخل `data`.
  static Map<String, dynamic> _payloadOf(RemoteMessage message) => {
        ...message.data,
        if (message.data['title'] == null && message.notification?.title != null)
          'title': message.notification!.title,
      };
}

/// معالج رسائل الخلفية — **يجب أن يكون دالة عليا** (`top-level`) موسومة
/// بـ `@pragma('vm:entry-point')`: أندرويد يوقظ عزلة Dart جديدة لا تعرف
/// شيئاً عن حالة التطبيق، وبدونه تُسقَط رسائل الـ data الواصلة والتطبيق
/// مغلق ويطبع Flutter تحذيراً.
///
/// لا يفتح شاشة ولا يلمس الواجهة: العزلة هنا بلا شجرة ودجت. عرض الإشعار
/// يتولاه النظام من كتلة `notification`، والفتح يقع عند الضغط في
/// [PushTokenService._handleNotificationTap].
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[Push] رسالة في الخلفية: ${message.messageId}');
}
