import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alatarekak/core/service/chat_socket_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/notifications_badge_service.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/notifications/domain/entity/notification_entity.dart';
import 'package:alatarekak/features/notifications/presantion/manger/cubit/notifications_cubit.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scroll = ScrollController();
  bool _markedRead = false;
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    // التصفير بعد اكتمال الإطار — استدعاؤه أثناء البناء يفجّر
    // ValueListenableBuilder الخاص بالجرس (setState during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationsBadgeService.instance.clear();
    });
    context.read<NotificationsCubit>().load();
    _scroll.addListener(_onScroll);

    // إشعار لحظي والشاشة مفتوحة ← أعد تحميل القائمة
    _realtimeSub =
        ChatSocketService.instance.notificationStream.listen((_) {
      if (!mounted) return;
      _markedRead = false; // ليُعلَّم الجديد كمقروء بعد التحميل
      NotificationsBadgeService.instance.clear();
      context.read<NotificationsCubit>().load();
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 200) {
      context.read<NotificationsCubit>().loadMore();
    }
  }

  String _relativeTime(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return 'منذ ${(diff.inDays / 7).floor()} أسبوع';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded,
              color: MyColors.primary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text('الإشعارات', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      body: BlocConsumer<NotificationsCubit, NotificationsState>(
        listener: (context, state) {
          // بعد أول تحميل ناجح: علّم الكل كمقروء مرة واحدة
          if (state is NotificationsLoaded &&
              !_markedRead &&
              state.unreadCount > 0) {
            _markedRead = true;
            context.read<NotificationsCubit>().markAllRead();
          }
        },
        builder: (context, state) {
          if (state is NotificationsLoading ||
              state is NotificationsInitial) {
            return Center(
                child: CircularProgressIndicator(color: MyColors.primary));
          }
          if (state is NotificationsError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<NotificationsCubit>().load(),
            );
          }

          final items = switch (state) {
            NotificationsLoaded s => s.notifications,
            NotificationsActionFailed s => s.notifications,
            _ => const <NotificationEntity>[],
          };
          final isLoadingMore =
              state is NotificationsLoaded && state.isLoadingMore;

          if (items.isEmpty) return const _EmptyView();

          return RefreshIndicator(
            color: MyColors.primary,
            onRefresh: () => context.read<NotificationsCubit>().load(),
            child: ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              itemCount: items.length + (isLoadingMore ? 1 : 0),
              separatorBuilder: (context, i) => SizedBox(height: 8.h),
              itemBuilder: (context, i) {
                if (i == items.length) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: MyColors.primary),
                      ),
                    ),
                  );
                }
                final n = items[i];
                return Dismissible(
                  key: ValueKey('notification_${n.id}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => context
                      .read<NotificationsCubit>()
                      .deleteNotification(n.id),
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    padding: EdgeInsetsDirectional.only(end: 20.w),
                    decoration: BoxDecoration(
                      color: MyColors.error,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white),
                  ),
                  child: _NotificationCard(
                    notification: n,
                    time: _relativeTime(n.createdAt),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Notification Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final String time;
  const _NotificationCard({required this.notification, required this.time});

  /// ربط عميق حسب حمولة data (ride_id, complaint_id...) أو التصنيف
  void _onTap() {
    if (notification.conversationId != null) {
      // إشعار chat_message: العنوان الخام = اسم المرسل (من الباك إند)
      Get.toNamed(RouteName.chatScreen, arguments: {
        'conversationId': notification.conversationId,
        'title': notification.title,
        'avatar': null,
      });
    } else if (notification.complaintId != null) {
      Get.toNamed(RouteName.complaintDetail,
          arguments: notification.complaintId);
    } else if (notification.rideId != null) {
      Get.toNamed(RouteName.tripDetails, arguments: notification.rideId);
    } else if (notification.category == 'chat') {
      Get.toNamed(RouteName.chatListScreen);
    }
    // لا وجهة معروفة ← يبقى المستخدم في الشاشة
  }

  IconData get _icon {
    switch (notification.category) {
      case 'ride':
        return Icons.directions_car_rounded;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'profile':
        return Icons.person_outline_rounded;
      case 'system':
        return Icons.settings_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color get _color {
    switch (notification.category) {
      case 'ride':
        return MyColors.primary;
      case 'chat':
        return MyColors.blue;
      case 'profile':
        return MyColors.accent;
      case 'system':
        return MyColors.textSecondary;
      default:
        return MyColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return GestureDetector(
      onTap: _onTap,
      child: Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: unread
            ? Border.all(color: MyColors.accent.withValues(alpha: 0.4))
            : null,
        boxShadow: [
          BoxShadow(
              color: MyColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_icon, color: _color, size: 21),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        // عنوان عربي حسب type (الباك إند يخزنها إنجليزية)
                        notification.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsetsDirectional.only(start: 6.w),
                        decoration: BoxDecoration(
                          color: MyColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  notification.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: MyColors.textSecondary, height: 1.4),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        notification.categoryLabel,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: _color, fontSize: 10.sp),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      time,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: MyColors.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Empty & Error
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: MyColors.textHint.withValues(alpha: 0.5)),
          SizedBox(height: 16.h),
          Text('لا توجد إشعارات',
              style: AppTextStyles.titleMedium
                  .copyWith(color: MyColors.textSecondary)),
          SizedBox(height: 6.h),
          Text('ستظهر إشعارات رحلاتك وحجوزاتك هنا',
              style: AppTextStyles.bodySmall
                  .copyWith(color: MyColors.textHint)),
        ],
      ),
    );
  }
}


class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 52, color: MyColors.error),
            SizedBox(height: 12.h),
            Text(message,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: MyColors.textSecondary),
                textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text('إعادة المحاولة',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
