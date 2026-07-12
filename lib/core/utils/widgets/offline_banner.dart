import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// NFR-17: شريط أحمر أعلى الشاشة يظهر تلقائياً عند انقطاع الاتصال
/// ويختفي عند عودته — يُركّب مرة واحدة فوق كل الشاشات عبر builder
/// في GetMaterialApp.
class OfflineBanner extends StatelessWidget {
  final Widget child;

  /// حالة الاتصال — قابلة للحقن في الاختبارات.
  final ValueListenable<bool> isOffline;

  const OfflineBanner({
    super.key,
    required this.child,
    required this.isOffline,
  });

  static const String offlineMessage =
      'لا يوجد اتصال بالإنترنت، تحقق من الشبكة';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isOffline,
      child: child,
      builder: (context, offline, child) {
        return Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: offline
                  ? Material(
                      color: const Color(0xFFD32F2F),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.wifi_off,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  offlineMessage,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Expanded(child: child!),
          ],
        );
      },
    );
  }
}
