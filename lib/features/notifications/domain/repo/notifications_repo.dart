import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/notifications/domain/entity/notification_entity.dart';

abstract class NotificationsRepo {
  /// آخر صفحة أولى مخزنة محلياً (للعرض الفوري) — null إن لم تُخزن
  NotificationsPageEntity? getCachedFirstPage();

  /// حفظ الحالة الحالية في الكاش بعد التعديلات المحلية
  /// (حذف/تعليم كمقروء) حتى لا يُحيي الكاشُ القديم عناصرَ محذوفة
  Future<void> cacheFirstPage(
      List<NotificationEntity> items, int unreadCount);

  /// §10.1 — قائمة الإشعارات مع فلاتر اختيارية و pagination
  /// (الصفحة الأولى بلا فلاتر تُخزن تلقائياً وتسقط للكاش عند فشل الشبكة)
  Future<Either<Filuar, NotificationsPageEntity>> getNotifications({
    int page = 1,
    int perPage = 15,
    String? category,
    bool? isRead,
  });

  /// §10.2 — عدد غير المقروء فقط (خفيف، مناسب للـ badge)
  Future<Either<Filuar, int>> getUnreadCount();

  /// §10.4 — تحديد الكل كمقروء، يرجع unread_count الجديد (صفر)
  Future<Either<Filuar, int>> markAllRead();

  /// §10.5 — تحديد إشعار واحد كمقروء / غير مقروء
  Future<Either<Filuar, void>> markRead(int id);
  Future<Either<Filuar, void>> markUnread(int id);

  /// §10.5 — حذف إشعار
  Future<Either<Filuar, void>> deleteNotification(int id);

  /// §10.6 — عملية جماعية، ترجع unread_count الجديد
  Future<Either<Filuar, int>> bulkAction({
    required String action, // mark_read | mark_unread | delete
    required List<int> ids,
  });
}
