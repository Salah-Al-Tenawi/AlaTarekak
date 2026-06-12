import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/service/chat_socket_service.dart';
import 'package:alatarekak/core/service/locator_ser.dart';
import 'package:alatarekak/features/notifications/data/data_source/notifications_local_data_source.dart';
import 'package:alatarekak/features/notifications/data/data_source/notifications_remote_data_source.dart';
import 'package:alatarekak/features/notifications/data/repo/notifications_repo_im.dart';

/// عداد الإشعارات غير المقروءة لشارة الجرس (نمط ChatSocketService).
/// مصدران: polling عند فتح الرئيسية/العودة من الشاشة، وبث لحظي عبر
/// private-user.{id} (يعمل فور إصلاح الباك إند للعيب D2).
class NotificationsBadgeService {
  NotificationsBadgeService._();
  static final NotificationsBadgeService instance =
      NotificationsBadgeService._();

  final ValueNotifier<int> unread = ValueNotifier<int>(0);

  StreamSubscription<Map<String, dynamic>>? _realtimeSub;

  /// يُستدعى مرة عند فتح الرئيسية: اشتراك بالقناة اللحظية + استماع
  void ensureRealtime() {
    ChatSocketService.instance.subscribeUserChannel();
    _realtimeSub ??=
        ChatSocketService.instance.notificationStream.listen((_) {
      // إشعار جديد وصل والتطبيق مفتوح ← +1 فوراً
      unread.value = unread.value + 1;
    });
  }

  NotificationsRepoIm get _repo => NotificationsRepoIm(
        remoteDataSource:
            NotificationsRemoteDataSourceIm(api: getit.get<DioConSumer>()),
        localDataSource: NotificationsLocalDataSourceIm(),
      );

  /// قيمة فورية من الكاش ثم تحديث من الشبكة (فشل الشبكة يُتجاهل بصمت)
  Future<void> refresh() async {
    final cached = _repo.getCachedFirstPage();
    if (cached != null) unread.value = cached.unreadCount;

    final result = await _repo.getUnreadCount();
    result.fold((_) {}, (count) => unread.value = count);
  }

  /// تصفير فوري (عند فتح شاشة الإشعارات)
  void clear() => unread.value = 0;
}
