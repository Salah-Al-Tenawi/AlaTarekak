import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/api_envelope.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/notifications/data/model/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<NotificationsPageModel> getNotifications({
    int page,
    int perPage,
    String? category,
    bool? isRead,
  });
  Future<int> getUnreadCount();
  Future<int> markAllRead();
  Future<void> markRead(int id);
  Future<void> markUnread(int id);
  Future<void> deleteNotification(int id);
  Future<int> bulkAction({required String action, required List<int> ids});
}

class NotificationsRemoteDataSourceIm extends NotificationsRemoteDataSource {
  final ApiConSumer api;

  NotificationsRemoteDataSourceIm({required this.api});

  /// الباك إند قد يرجع success=false مع HTTP 200 — نتحقق دائماً بالمغلف الموحد
  Never _throwFrom(dynamic json) {
    throw ServerExpcptions(
      error: json is Map<String, dynamic>
          ? Filuar.fromJson(json)
          : const Filuar(message: 'حدث خطأ غير متوقع'),
    );
  }

  @override
  Future<NotificationsPageModel> getNotifications({
    int page = 1,
    int perPage = 15,
    String? category,
    bool? isRead,
  }) async {
    final json = await api.get(
      ApiEndPoint.notifications,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (category != null) 'category': category,
        if (isRead != null) 'is_read': isRead ? 1 : 0,
      },
    );
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);
    return NotificationsPageModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<int> getUnreadCount() async {
    final json = await api.get(ApiEndPoint.notificationsUnreadCount);
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);
    return ((json as Map<String, dynamic>)['unread_count'] as num?)?.toInt() ??
        0;
  }

  @override
  Future<int> markAllRead() async {
    final json = await api.post(ApiEndPoint.notificationsReadAll);
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);
    return ((json as Map<String, dynamic>)['unread_count'] as num?)?.toInt() ??
        0;
  }

  @override
  Future<void> markRead(int id) async {
    final json = await api.post("${ApiEndPoint.notifications}/$id/read");
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);
  }

  @override
  Future<void> markUnread(int id) async {
    final json = await api.post("${ApiEndPoint.notifications}/$id/unread");
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);
  }

  @override
  Future<void> deleteNotification(int id) async {
    final json = await api.delete("${ApiEndPoint.notifications}/$id");
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);
  }

  @override
  Future<int> bulkAction(
      {required String action, required List<int> ids}) async {
    final json = await api.post(
      ApiEndPoint.notificationsBulkAction,
      data: {'action': action, 'notification_ids': ids},
    );
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);
    return ((json as Map<String, dynamic>)['unread_count'] as num?)?.toInt() ??
        0;
  }
}
