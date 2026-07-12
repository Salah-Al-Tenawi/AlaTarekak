import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/locator_ser.dart';
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

    // تجديد التوكن تلقائياً لدى الباك إند عند تغيره
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _currentToken = token;
      if ((mytoken() ?? '').isNotEmpty) _registerWithBackend(token);
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

  /// إشعارات الشات تحمل conversation_id في الـ data — نفتح المحادثة مباشرة
  void _handleNotificationTap(RemoteMessage message) {
    final conversationId =
        int.tryParse('${message.data['conversation_id'] ?? ''}');
    if (conversationId != null) {
      Get.toNamed(RouteName.chatScreen,
          arguments: {'conversationId': conversationId});
    }
  }
}
