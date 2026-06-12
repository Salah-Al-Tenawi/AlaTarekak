part of 'notifications_cubit.dart';

sealed class NotificationsState {}

final class NotificationsInitial extends NotificationsState {}

final class NotificationsLoading extends NotificationsState {}

final class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final bool hasMore;
  final bool isLoadingMore;

  NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
    required this.hasMore,
    this.isLoadingMore = false,
  });
}

final class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError({required this.message});
}

/// فشل إجراء (حذف/تحديد كمقروء...) مع بقاء القائمة معروضة
final class NotificationsActionFailed extends NotificationsState {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final bool hasMore;
  final String error;

  NotificationsActionFailed({
    required this.notifications,
    required this.unreadCount,
    required this.hasMore,
    required this.error,
  });
}
