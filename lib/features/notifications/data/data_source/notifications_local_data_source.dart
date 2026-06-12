import 'dart:convert';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/notifications/data/model/notification_model.dart';
import 'package:alatarekak/features/notifications/domain/entity/notification_entity.dart';

/// يخزن الصفحة الأولى فقط (أحدث 15 إشعاراً) + عداد غير المقروء —
/// كافية للعرض الفوري عند فتح الشاشة، والباقي يُجلب من الشبكة.
abstract class NotificationsLocalDataSource {
  NotificationsPageEntity? getFirstPage();
  Future<void> saveFirstPage(
      List<NotificationEntity> items, int unreadCount);
  Future<void> clear();
}

class NotificationsLocalDataSourceIm extends NotificationsLocalDataSource {
  @override
  NotificationsPageEntity? getFirstPage() {
    final raw = HiveBoxes.cacheBox.get(HiveKeys.notifications);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final items = (json['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
      return NotificationsPageEntity(
        items: items,
        currentPage: 1,
        // الكاش لا يعرف عدد الصفحات — التحديث الشبكي يصحح hasMore
        lastPage: 1,
        total: items.length,
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveFirstPage(
      List<NotificationEntity> items, int unreadCount) {
    final json = {
      'items': items
          .map((e) => NotificationModel.fromEntity(e).toJson())
          .toList(),
      'unread_count': unreadCount,
    };
    return HiveBoxes.cacheBox.put(HiveKeys.notifications, jsonEncode(json));
  }

  @override
  Future<void> clear() => HiveBoxes.cacheBox.delete(HiveKeys.notifications);
}
