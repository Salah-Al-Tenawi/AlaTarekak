import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/service/local_notifications_service.dart';
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
      debugPrint('[Push] الحالة — Firebase: ✗ فشلت التهيئة · $e');
      return;
    }

    // رسائل الخلفية والتطبيق مغلق — يجب تسجيله قبل أي استعمال آخر
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // تجديد التوكن تلقائياً لدى الباك إند عند تغيره
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _currentToken = token;
      if ((mytoken() ?? '').isNotEmpty) _registerWithBackend(token);
    });

    // إشعارات المقدمة نرسمها بأنفسنا — أندرويد لا يعرض إشعار النظام
    // ما دام التطبيق مفتوحاً
    await LocalNotificationsService.instance.init();

    // إشعار يصل والتطبيق مفتوح: يُعرض منبثقاً كما لو كان خارج التطبيق،
    // ويُضاء الجرس معه — والقائمة نفسها تُحدَّث من Pusher.
    //
    // `refresh()` لا `+1`: الإشعار الواحد قد يصل من المسارين معاً (FCM
    // وPusher)، وقراءة العدد من الخادم تُصحّح الزيادة المكرّرة بدل أن
    // تُراكمها.
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[Push] رسالة في المقدمة — '
          'notification: ${message.notification != null} · '
          'data: ${message.data}');
      LocalNotificationsService.instance.showFromMessage(message);
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

  /// POST /push-tokens — تُستدعى بعد الدخول وبعد إنشاء الحساب وعند كل إقلاع.
  ///
  /// تطبع سطر حالة واحداً مهما كانت النتيجة. تشخيص «لماذا لا تصل
  /// الإشعارات» كان يتطلّب تتبّع أسطر متفرّقة في سجلّ طويل، وغياب السطر
  /// يُلبِس: أهو فشلٌ أم أن الدالة لم تُستدعَ أصلاً؟
  Future<void> registerToken() async {
    if (!_firebaseReady) {
      debugPrint('[Push] الحالة — Firebase: ✗ غير مهيأ · لا تسجيل');
      return;
    }

    final signedIn = (mytoken() ?? '').isNotEmpty;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();

      if (token == null) {
        debugPrint('[Push] الحالة — Firebase: ✓ · التوكن: ✗ لم يصدر '
            '(الإذن: ${settings.authorizationStatus.name})');
        return;
      }
      _currentToken = token;

      if (!signedIn) {
        debugPrint('[Push] الحالة — التوكن: ${_short(token)} · '
            'التسجيل: مؤجَّل (لا جلسة)');
        return;
      }

      await _registerWithBackend(token);
      debugPrint('[Push] الحالة — Firebase: ✓ · التوكن: ${_short(token)} · '
          'الإذن: ${settings.authorizationStatus.name} · التسجيل: ✓');
    } catch (e) {
      debugPrint('[Push] الحالة — التوكن: '
          '${_currentToken == null ? "✗" : _short(_currentToken!)} · '
          'التسجيل: ✗ — $e');
    }
  }

  /// أول التوكن وآخره — يكفي للمطابقة مع ما عند الخادم بلا نشره كاملاً
  /// في سجلّ قد يُشارَك.
  static String _short(String token) => token.length <= 16
      ? token
      : '${token.substring(0, 8)}…${token.substring(token.length - 4)}';

  Future<void> _registerWithBackend(String token) async {
    final platform = kIsWeb
        ? 'web'
        : Platform.isIOS
            ? 'ios'
            : 'android';
    await getit.get<DioConSumer>().post(
      ApiEndPoint.pushTokens,
      data: {'token': token, 'platform': platform},
    );
  }

  /// DELETE /push-tokens — تُستدعى قبل مسح جلسة المستخدم عند تسجيل الخروج.
  ///
  /// الفعل `delete` لا `post`: الباك إند سجّل الإزالة على المسار نفسه
  /// بطريقة مختلفة، فإرسالها POST يُسجّل التوكن من جديد بدل حذفه.
  Future<void> removeToken() async {
    if (!_firebaseReady) return;
    try {
      final token =
          _currentToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await getit
            .get<DioConSumer>()
            .delete(ApiEndPoint.pushTokens, data: {'token': token});
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
/// **يرسم الإشعار حين لا يرسم النظام:** أندرويد يعرض الإشعار من كتلة
/// `notification` وحدها. أما رسالة الـ `data` الخالصة فلا يعرض لها شيئاً
/// إطلاقاً — لا صوت ولا شريط ولا سطر في الستارة — فيصل الإشعار صامتاً
/// ولا يعلم به المستخدم.
///
/// ولا يرسم حين يرسم النظام: وجود `notification` يعني أنه تولّاها، ورسمُ
/// نسخة ثانية يُظهر الإشعار مرتين.
///
/// لا يفتح شاشة ولا يلمس الواجهة — العزلة هنا بلا شجرة ودجت، والفتح يقع
/// عند الضغط في [PushTokenService._handleNotificationTap].
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[Push] رسالة في الخلفية — '
      'notification: ${message.notification != null} · data: ${message.data}');

  if (message.notification != null) return; // النظام يتولّاها

  await LocalNotificationsService.instance.init();
  await LocalNotificationsService.instance.showFromMessage(message);
}
