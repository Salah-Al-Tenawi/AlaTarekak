import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/notifications/data/data_source/notifications_local_data_source.dart';
import 'package:alatarekak/features/notifications/data/data_source/notifications_remote_data_source.dart';
import 'package:alatarekak/features/notifications/domain/entity/notification_entity.dart';
import 'package:alatarekak/features/notifications/domain/repo/notifications_repo.dart';

class NotificationsRepoIm extends NotificationsRepo {
  final NotificationsRemoteDataSource remoteDataSource;
  final NotificationsLocalDataSource localDataSource;

  NotificationsRepoIm({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  Future<Either<Filuar, T>> _guard<T>(Future<T> Function() task) async {
    try {
      return right(await task());
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  NotificationsPageEntity? getCachedFirstPage() =>
      localDataSource.getFirstPage();

  @override
  Future<void> cacheFirstPage(
          List<NotificationEntity> items, int unreadCount) =>
      localDataSource.saveFirstPage(items, unreadCount);

  @override
  Future<Either<Filuar, NotificationsPageEntity>> getNotifications({
    int page = 1,
    int perPage = 15,
    String? category,
    bool? isRead,
  }) async {
    // الكاش للصفحة الأولى غير المفلترة فقط (الشكل الافتراضي للشاشة)
    final isCacheable = page == 1 && category == null && isRead == null;

    try {
      final result = await remoteDataSource.getNotifications(
        page: page,
        perPage: perPage,
        category: category,
        isRead: isRead,
      );
      if (isCacheable) {
        await localDataSource.saveFirstPage(
            result.items, result.unreadCount);
      }
      return right(result);
    } on ServerExpcptions catch (e) {
      if (isCacheable) {
        final cached = localDataSource.getFirstPage();
        if (cached != null) return right(cached);
      }
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, int>> getUnreadCount() =>
      _guard(remoteDataSource.getUnreadCount);

  @override
  Future<Either<Filuar, int>> markAllRead() =>
      _guard(remoteDataSource.markAllRead);

  @override
  Future<Either<Filuar, void>> markRead(int id) =>
      _guard(() => remoteDataSource.markRead(id));

  @override
  Future<Either<Filuar, void>> markUnread(int id) =>
      _guard(() => remoteDataSource.markUnread(id));

  @override
  Future<Either<Filuar, void>> deleteNotification(int id) =>
      _guard(() => remoteDataSource.deleteNotification(id));

  @override
  Future<Either<Filuar, int>> bulkAction({
    required String action,
    required List<int> ids,
  }) =>
      _guard(() => remoteDataSource.bulkAction(action: action, ids: ids));
}
