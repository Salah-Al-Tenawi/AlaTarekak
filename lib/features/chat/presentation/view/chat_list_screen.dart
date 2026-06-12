import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/chat_socket_service.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/chat/domain/entity/conversation_entity.dart';
import 'package:alatarekak/features/chat/presentation/manager/conversation_cubit/conversation_cubit.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.surface,
        elevation: 0,
        // Shown as a bottom-nav tab: a back arrow here would pop the whole
        // Home route.
        automaticallyImplyLeading: false,
        title: Text('المحادثات', style: AppTextStyles.titleMedium),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: MyColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<ConversationCubit, ConversationState>(
        builder: (context, state) {
          if (state is ConversationLoading) {
            return Center(
                child: CircularProgressIndicator(color: MyColors.primary));
          }
          if (state is ConversationError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<ConversationCubit>().loadConversations(),
            );
          }
          if (state is ConversationLoaded) {
            if (state.conversations.isEmpty) {
              return const _EmptyView();
            }
            return RefreshIndicator(
              color: MyColors.accent,
              onRefresh: () =>
                  context.read<ConversationCubit>().loadConversations(),
              child: ListView.separated(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                itemCount: state.conversations.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (_, i) =>
                    _ConversationCard(conv: state.conversations[i]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
class _ConversationCard extends StatelessWidget {
  final ConversationEntity conv;
  _ConversationCard({required this.conv});

  @override
  Widget build(BuildContext context) {
    // Backend has no unread count yet — track it locally via the socket
    // service. max() keeps this future-proof: when the backend adds
    // unread_count we won't double-count.
    return StreamBuilder<int>(
      stream: ChatSocketService.instance.unreadStream,
      builder: (context, _) {
        final unread = max(
          conv.unreadCount,
          ChatSocketService.instance.unreadFor(conv.id),
        );
        return InkWell(
          onTap: () => Get.toNamed(
            RouteName.chatScreen,
            arguments: {
              'conversationId': conv.id,
              'title': conv.otherParticipant.name,
              'avatar': conv.otherParticipant.avatar,
            },
          ),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: MyColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                    color: MyColors.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                // ── Avatar ──
                CircleAvatar(
                  radius: 26.r,
                  backgroundColor: MyColors.background,
                  backgroundImage: conv.otherParticipant.avatar != null
                      ? NetworkImage(conv.otherParticipant.avatar!)
                          as ImageProvider
                      : const AssetImage(ImagesUrl.profileImage),
                ),

                SizedBox(width: 12.w),

                // ── Name + last message ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conv.otherParticipant.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight:
                              unread > 0 ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (conv.lastMessage != null) ...[
                        SizedBox(height: 3.h),
                        Text(
                          conv.lastMessage!.isImage
                              ? '📷 صورة'
                              : conv.lastMessage!.content,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: unread > 0
                                ? MyColors.textPrimary
                                : MyColors.textSecondary,
                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // ── Time + unread badge ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (conv.lastMessage != null)
                      Text(
                        _formatTime(conv.lastMessage!.createdAt),
                        style: AppTextStyles.labelSmall.copyWith(
                          color:
                              unread > 0 ? MyColors.accent : MyColors.textHint,
                          fontWeight:
                              unread > 0 ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    if (unread > 0) ...[
                      SizedBox(height: 4.h),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MyColors.accent,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          unread > 99 ? '+99' : '$unread',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return dateStr; // relative string e.g. "5 minutes ago"
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: MyColors.textHint),
          SizedBox(height: 16.h),
          Text('لا توجد محادثات بعد',
              style: AppTextStyles.titleMedium
                  .copyWith(color: MyColors.textSecondary)),
          SizedBox(height: 6.h),
          Text('ابدأ محادثة مع أحد المستخدمين',
              style:
                  AppTextStyles.bodySmall.copyWith(color: MyColors.textHint)),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: MyColors.error),
          SizedBox(height: 12.h),
          Text(message,
              style: AppTextStyles.bodySmall
                  .copyWith(color: MyColors.textSecondary),
              textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.accent, elevation: 0),
            child: Text('إعادة المحاولة',
                style: AppTextStyles.buttonLarge),
          ),
        ],
      ),
    );
  }
}
