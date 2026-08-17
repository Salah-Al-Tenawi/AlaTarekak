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
import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:alatarekak/core/utils/class/format_date_time.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/chat/domain/entity/conversation_entity.dart';
import 'package:alatarekak/features/chat/presentation/manager/conversation_cubit/conversation_cubit.dart';
import 'package:alatarekak/features/support/domain/entity/support_conversation.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        elevation: 0,
        // Shown as a bottom-nav tab: a back arrow here would pop the whole
        // Home route.
        automaticallyImplyLeading: false,
        title: Text('المحادثات', style: AppTextStyles.titleMedium.copyWith(color: MyColors.textOnDark)),
        centerTitle: true,
      ),
      body: BlocBuilder<ConversationCubit, ConversationState>(
        builder: (context, state) {
          // الحالة الابتدائية كانت تُرسم `SizedBox.shrink()` — شاشة بيضاء
          // لا محتوى فيها ولا شيء يُسحب، ولا شيء يُطلق التحميل. الإطلاق
          // الوحيد كان `..loadConversations()` في مزوّد المسار، وهو كسول:
          // إن لم يُنشأ الكيوبت بذلك المسار بقيت الشاشة فارغة إلى الأبد.
          // الآن تشفي الشاشة نفسها، كما في «رحلاتي».
          if (state is ConversationInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.read<ConversationCubit>().loadConversations();
              }
            });
            return const Center(child: LoadingWidgetSize150());
          }

          if (state is ConversationLoading) {
            return const Center(child: LoadingWidgetSize150());
          }

          // السحب للتحديث يغطّي **كل** الحالات بعد التحميل. كان محصوراً في
          // فرع القائمة غير الفارغة، فتُحبَس الشاشة على الفراغ أو الخطأ بلا
          // سبيل لإعادة المحاولة بالسحب.
          return RefreshIndicator(
            color: MyColors.accent,
            onRefresh: () =>
                context.read<ConversationCubit>().loadConversations(),
            child: _buildBody(context, state),
          );
        },
      ),
    );
  }

  /// جسم الشاشة بعد التحميل — كل فرع منه **قابل للتمرير** حتى يستجيب
  /// `RefreshIndicator` للسحب، فالمؤشّر لا يعمل على محتوى ثابت.
  Widget _buildBody(BuildContext context, ConversationState state) {
    if (state is ConversationError) {
      return _ErrorView(
        message: state.message,
        onRetry: () => context.read<ConversationCubit>().loadConversations(),
      );
    }

    if (state is ConversationLoaded && state.conversations.isNotEmpty) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: state.conversations.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (_, i) => StaggeredItem(
          index: i,
          child: _ConversationCard(conv: state.conversations[i]),
        ),
      );
    }

    return const _EmptyView();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
class _ConversationCard extends StatelessWidget {
  final ConversationEntity conv;
  _ConversationCard({required this.conv});

  @override
  Widget build(BuildContext context) {
    // محادثة الدعم تُعرض باسم الموظف الشخصي وبلا أي تمييز، فتضيع بين
    // محادثات الرحلات — نميّزها بالاسم والأيقونة والإطار.
    final isSupport = SupportConversation.matches(conv);
    final displayName =
        isSupport ? SupportConversation.displayName : conv.otherParticipant.name;

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
              'title': displayName,
              'avatar': isSupport ? null : conv.otherParticipant.avatar,
              'isSupport': isSupport,
            },
          ),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isSupport
                  ? MyColors.primary.withValues(alpha: 0.05)
                  : MyColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: isSupport
                  ? Border.all(color: MyColors.primary.withValues(alpha: 0.25))
                  : null,
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
                // الدعم مستثنى: لا ملف شخصي لموظّف الدعم يُفتح
                if (isSupport)
                  CircleAvatar(
                    radius: 26.r,
                    backgroundColor: MyColors.primary,
                    child: Icon(Icons.support_agent_rounded,
                        color: MyColors.textOnDark, size: 28.sp),
                  )
                else
                  GestureDetector(
                    onTap: () => Get.toNamed(RouteName.profile,
                        arguments: conv.otherParticipant.id),
                    child: CircleAvatar(
                      radius: 26.r,
                      backgroundColor: MyColors.background,
                      backgroundImage: conv.otherParticipant.avatar != null
                          ? NetworkImage(conv.otherParticipant.avatar!)
                              as ImageProvider
                          : const AssetImage(ImagesUrl.profileImage),
                    ),
                  ),

                SizedBox(width: 12.w),

                // ── Name + last message ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isSupport ? MyColors.primary : null,
                                fontWeight: unread > 0 || isSupport
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSupport) ...[
                            SizedBox(width: 5.w),
                            Icon(Icons.verified_rounded,
                                size: 15.sp, color: MyColors.primary),
                          ],
                        ],
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
                        // `updated_at` تاريخ ISO سليم على المحادثة، بينما
                        // `last_message.created_at` يصل نصّاً نسبياً
                        // إنجليزياً — نُقدّم الأول ونترجم الثاني عند غيابه
                        DateTimeUtils.chatListTime([
                          conv.updatedAt,
                          conv.lastMessage!.createdAt,
                        ]),
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

}

// ━━━━━━━━━━━━━━━━━━━━━━━━
/// يملأ الشاشة **ويقبل التمرير دائماً**، فيستجيب لسحب التحديث فوقه.
class _ScrollableCenter extends StatelessWidget {
  final Widget child;
  const _ScrollableCenter({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return _ScrollableCenter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 60.sp, color: MyColors.textHint),
            SizedBox(height: 16.h),
            Text('لا توجد محادثات بعد',
                style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 17.sp, color: MyColors.textSecondary)),
            SizedBox(height: 6.h),
            Text('ابدأ محادثة مع أحد المستخدمين',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(fontSize: 13.sp, color: MyColors.textHint)),
            SizedBox(height: 10.h),
            Text('اسحب للأسفل للتحديث',
                style: AppTextStyles.labelSmall
                    .copyWith(fontSize: 11.sp, color: MyColors.textHint)),
          ],
        ),
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
    return _ScrollableCenter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 46.sp, color: MyColors.error),
            SizedBox(height: 12.h),
            Text(message,
                style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13.sp,
                    color: MyColors.textSecondary,
                    height: 1.6),
                textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            SizedBox(
              height: 46.h,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('إعادة المحاولة',
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
            SizedBox(height: 10.h),
            Text('أو اسحب للأسفل للتحديث',
                style: AppTextStyles.labelSmall
                    .copyWith(fontSize: 11.sp, color: MyColors.textHint)),
          ],
        ),
      ),
    );
  }
}
