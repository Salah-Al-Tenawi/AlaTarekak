import 'dart:convert';

import 'package:alatarekak/features/notifications/domain/entity/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.message,
    required super.category,
    super.type,
    super.priority,
    required super.isRead,
    super.createdAt,
    super.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // الباك إند قد يرجع صف user_notifications ومحتوى الإشعار متداخل
    // داخل مفتاح notification — نقرأ المحتوى من الداخل والحالة من الخارج
    final inner = json['notification'] is Map<String, dynamic>
        ? json['notification'] as Map<String, dynamic>
        : json;

    // data قد تصل Map أو JSON string (حسب مصدرها: REST أو broadcast)
    Map<String, dynamic>? data;
    final rawData = inner['data'] ?? json['data'];
    if (rawData is Map<String, dynamic>) {
      data = rawData;
    } else if (rawData is String && rawData.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {}
    }

    return NotificationModel(
      id: json['id'] as int,
      title: (inner['title'] ?? json['title'])?.toString() ?? '',
      message: (inner['message'] ?? json['message'])?.toString() ?? '',
      category:
          (inner['category'] ?? json['category'])?.toString() ?? 'general',
      type: (inner['type'] ?? json['type'])?.toString(),
      priority: (inner['priority'] ?? json['priority'])?.toString(),
      // حالة القراءة على الصف الخارجي: الباك إند لا يرسل is_read إطلاقاً —
      // المصدر الوحيد هو read_at (null تعني غير مقروء). أما is_read فيأتي
      // من كاش Hive المحلي فقط (انظر toJson أدناه) لذا نقبله كمصدر ثانوي.
      isRead: json['read_at'] != null ||
          json['is_read'] == true ||
          json['is_read'] == 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      data: data,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'category': category,
        'type': type,
        'priority': priority,
        'is_read': isRead,
        'created_at': createdAt?.toIso8601String(),
        'data': data,
      };

  factory NotificationModel.fromEntity(NotificationEntity e) =>
      NotificationModel(
        id: e.id,
        title: e.title,
        message: e.message,
        category: e.category,
        type: e.type,
        priority: e.priority,
        isRead: e.isRead,
        createdAt: e.createdAt,
        data: e.data,
      );
}

class NotificationsPageModel extends NotificationsPageEntity {
  const NotificationsPageModel({
    required super.items,
    required super.currentPage,
    required super.lastPage,
    required super.total,
    required super.unreadCount,
  });

  /// §10.1 — data هو Laravel paginator: العناصر في data.data
  factory NotificationsPageModel.fromJson(Map<String, dynamic> json) {
    final paginator = json['data'] as Map<String, dynamic>? ?? {};
    final rawItems = paginator['data'] as List? ?? [];

    return NotificationsPageModel(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList(),
      currentPage: (paginator['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (paginator['last_page'] as num?)?.toInt() ?? 1,
      total: (paginator['total'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}
