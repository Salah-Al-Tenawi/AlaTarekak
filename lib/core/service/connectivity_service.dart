import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// NFR-17: مراقبة حالة الاتصال بالشبكة — تغذي شريط "لا يوجد اتصال"
/// المعروض فوق كل الشاشات في [OfflineBanner].
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  /// true عندما لا يوجد أي وسيلة اتصال (WiFi/بيانات/إيثرنت)
  final ValueNotifier<bool> isOffline = ValueNotifier<bool>(false);

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// تُستدعى مرة واحدة من main(). تفشل بصمت إن لم تتوفر الإضافة
  /// (مثلاً على منصة غير مدعومة) فيبقى التطبيق يعمل بلا الشريط.
  Future<void> init() async {
    try {
      _update(await Connectivity().checkConnectivity());
      _subscription = Connectivity().onConnectivityChanged.listen(_update);
    } catch (e) {
      debugPrint('[Connectivity] تعذر تفعيل مراقبة الاتصال: $e');
    }
  }

  void _update(List<ConnectivityResult> results) {
    isOffline.value =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
