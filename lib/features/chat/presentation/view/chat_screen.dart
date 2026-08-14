import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';
import 'package:alatarekak/features/chat/domain/entity/message_entity.dart';
import 'package:alatarekak/features/chat/domain/entity/quick_messages.dart';
import 'package:alatarekak/features/chat/presentation/manager/message_cubit/message_cubit.dart';
import 'package:alatarekak/features/support/domain/entity/support_conversation.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  late final int conversationId;
  late final String title;
  String? avatar;

  /// محادثة الدعم: أيقونة سمّاعة بدل صورة شخصية، ولا رسائل تنسيق لقاء.
  late final bool isSupport;
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    conversationId = args['conversationId'] as int;
    title = args['title'] as String? ?? 'محادثة';
    avatar = args['avatar'] as String?;
    isSupport =
        args['isSupport'] as bool? ??
        SupportConversation.rememberedId == conversationId;
    // رسالة مقترحة تُكتب في الحقل ولا تُرسَل — القرار للمستخدم
    _controller.text = args['draft'] as String? ?? '';
    _scrollController.addListener(_onScroll);
    context.read<MessageCubit>().loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Load older messages when the user scrolls near the top, then restore
  // the scroll offset so the list doesn't jump.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels > 80) return;
    final before = _scrollController.position.maxScrollExtent;
    context.read<MessageCubit>().loadMore().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final delta = _scrollController.position.maxScrollExtent - before;
        if (delta > 0) {
          _scrollController.jumpTo(_scrollController.position.pixels + delta);
        }
      });
    });
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) {
      context.read<MessageCubit>().sendImage(File(file.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<MessageCubit, MessageState>(
              listener: (context, state) {
                if (state is MessageSent || state is MessageDeleted) {
                  _scrollToBottom();
                } else if (state is MessageLoaded && !_didInitialScroll) {
                  _didInitialScroll = true;
                  _scrollToBottom(animated: false);
                } else if (state is MessageActionFailed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: MyColors.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is MessageLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: MyColors.primary),
                  );
                }

                List<MessageEntity> messages = [];
                if (state is MessageLoaded) messages = state.messages;
                if (state is MessageSending) messages = state.messages;
                if (state is MessageSent) messages = state.messages;
                if (state is MessageDeleted) messages = state.messages;
                if (state is MessageActionFailed) messages = state.messages;

                if (messages.isEmpty && state is! MessageLoading) {
                  return const _EmptyMessages();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _MessageBubble(
                    message: messages[i],
                    isMe: messages[i].sender.id == (myid() ?? 0),
                    onLongPress: () => _showDeleteDialog(messages[i].id),
                  ),
                );
              },
            ),
          ),

          // ── Quick replies ──
          // تُعرض في بداية المحادثة فقط — حين يكون التنسيق على نقطة اللقاء
          // هو الغرض، ثم تختفي لتفسح المجال للمحادثة الطبيعية.
          // لا معنى لها في محادثة الدعم: نصوصها كلها عن لقاء السائق.
          if (!isSupport)
            BlocBuilder<MessageCubit, MessageState>(
              builder: (context, state) {
                final count = switch (state) {
                  MessageLoaded(:final messages) => messages.length,
                  MessageSent(:final messages) => messages.length,
                  MessageSending(:final messages) => messages.length,
                  _ => -1,
                };
                if (count < 0 || count > 4) return const SizedBox.shrink();
                return _QuickReplies(
                  onTap: (text) => context.read<MessageCubit>().sendText(text),
                );
              },
            ),

          // ── Input Bar ──
          _InputBar(
            controller: _controller,
            onSend: () {
              if (_controller.text.trim().isEmpty) return;
              context.read<MessageCubit>().sendText(_controller.text);
              _controller.clear();
            },
            onImage: _pickImage,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: MyColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Get.back(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: Colors.white24,
            backgroundImage: avatar != null ? NetworkImage(avatar!) : null,
            child: avatar == null
                ? Icon(
                    isSupport ? Icons.support_agent_rounded : Icons.person,
                    color: Colors.white,
                    size: 18,
                  )
                : null,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int messageId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('حذف الرسالة', style: AppTextStyles.titleMedium),
        content: Text(
          'هل تريد حذف هذه الرسالة؟',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: AppTextStyles.labelMedium.copyWith(
                color: MyColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MessageCubit>().deleteMessage(messageId);
            },
            child: Text(
              'حذف',
              style: AppTextStyles.labelMedium.copyWith(color: MyColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Message Bubble
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        // الواجهة عربية (RTL) فـ start هي الحافة اليمنى: رسائلي يميناً
        // ورسائل الطرف الآخر يساراً. كان معكوساً لأن end في RTL = اليسار.
        mainAxisAlignment:
            isMe ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onLongPress: isMe ? onLongPress : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 0.72.sw),
              child: Container(
                padding: message.isImage
                    ? EdgeInsets.zero
                    : EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isMe ? MyColors.primary : MyColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                    bottomLeft: isMe
                        ? Radius.circular(16.r)
                        : Radius.circular(4.r),
                    bottomRight: isMe
                        ? Radius.circular(4.r)
                        : Radius.circular(16.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: message.isImage
                    ? _ImageBubble(
                        imageUrl: message.image ?? '',
                        caption: message.caption,
                        isMe: isMe,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            message.content,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isMe ? Colors.white : MyColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _formatTime(message.createdAt),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isMe ? Colors.white60 : MyColors.textHint,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          // الصورة بعد الفقاعة لا قبلها: في RTL يُرسم أول عنصر في الصف
          // على اليمين، فوضعها أولاً كان يضعها بين الفقاعة ووسط الشاشة.
          // ترتيبها أخيراً يدفعها إلى الحافة اليسرى حيث ينتمي الطرف الآخر.
          if (!isMe) ...[
            SizedBox(width: 6.w),
            GestureDetector(
              // صورة المرسِل تفتح ملفه الشخصي
              onTap: () => Get.toNamed(RouteName.profile,
                  arguments: message.sender.id),
              child: CircleAvatar(
                radius: 14.r,
                backgroundColor: MyColors.background,
                backgroundImage: message.sender.avatar != null
                    ? NetworkImage(message.sender.avatar!)
                    : null,
                child: message.sender.avatar == null
                    ? Icon(Icons.person, size: 14, color: MyColors.textHint)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Image Bubble
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _ImageBubble extends StatelessWidget {
  final String imageUrl;
  final String? caption;
  final bool isMe;

  const _ImageBubble({
    required this.imageUrl,
    this.caption,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            imageUrl,
            width: 0.6.sw,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 0.6.sw,
              height: 120.h,
              color: MyColors.surfaceAlt,
              child: Icon(
                Icons.broken_image_outlined,
                color: MyColors.textHint,
              ),
            ),
          ),
          if (caption != null && caption!.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 8.h),
              child: Text(
                caption!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isMe ? Colors.white : MyColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Input Bar
// ━━━━━━━━━━━━━━━━━━━━━━━━
/// شريط رسائل جاهزة يُرسل بضغطة — يختصر التنسيق على نقطة اللقاء.
class _QuickReplies extends StatelessWidget {
  final void Function(String text) onTap;
  const _QuickReplies({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.h,
      color: MyColors.background,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        itemCount: QuickMessages.coordination.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final text = QuickMessages.coordination[i];
          return ActionChip(
            label: Text(
              text,
              style: TextStyle(fontSize: 12.sp, color: MyColors.primary),
            ),
            backgroundColor: MyColors.surface,
            side: BorderSide(color: MyColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () => onTap(text),
          );
        },
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onImage;

  _InputBar({
    required this.controller,
    required this.onSend,
    required this.onImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12.w,
        8.h,
        12.w,
        MediaQuery.of(context).viewInsets.bottom + 12.h,
      ),
      decoration: BoxDecoration(
        color: MyColors.surface,
        boxShadow: [
          BoxShadow(
            color: MyColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image picker
          IconButton(
            onPressed: onImage,
            icon: Icon(Icons.image_outlined, color: MyColors.primary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),

          SizedBox(width: 8.w),

          // Text field
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: MyColors.textHint,
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 10.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: MyColors.background,
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // Send button
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: MyColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.waving_hand_rounded, size: 48, color: MyColors.accent),
          SizedBox(height: 12.h),
          Text(
            'ابدأ المحادثة!',
            style: AppTextStyles.titleMedium.copyWith(
              color: MyColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
