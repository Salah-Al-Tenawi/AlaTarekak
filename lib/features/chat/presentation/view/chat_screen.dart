import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';
import 'package:alatarekak/features/chat/domain/entity/message_entity.dart';
import 'package:alatarekak/features/chat/presentation/manager/message_cubit/message_cubit.dart';

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

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    conversationId = args['conversationId'] as int;
    title = args['title'] as String? ?? 'محادثة';
    avatar = args['avatar'] as String?;
    context.read<MessageCubit>().loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
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
                }
              },
              builder: (context, state) {
                if (state is MessageLoading) {
                  return const Center(
                      child: CircularProgressIndicator(color: MyColors.primary));
                }

                List<MessageEntity> messages = [];
                if (state is MessageLoaded) messages = state.messages;
                if (state is MessageSending) messages = state.messages;
                if (state is MessageSent) messages = state.messages;
                if (state is MessageDeleted) messages = state.messages;

                if (messages.isEmpty && state is! MessageLoading) {
                  return const _EmptyMessages();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
        icon: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Get.back(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: Colors.white24,
            backgroundImage:
                avatar != null ? NetworkImage(avatar!) : null,
            child: avatar == null
                ? const Icon(Icons.person, color: Colors.white, size: 18)
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
        content: Text('هل تريد حذف هذه الرسالة؟',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء',
                style: AppTextStyles.labelMedium
                    .copyWith(color: MyColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MessageCubit>().deleteMessage(messageId);
            },
            child: Text('حذف',
                style: AppTextStyles.labelMedium
                    .copyWith(color: MyColors.error)),
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
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14.r,
              backgroundColor: MyColors.background,
              backgroundImage: message.sender.avatar != null
                  ? NetworkImage(message.sender.avatar!)
                  : null,
              child: message.sender.avatar == null
                  ? const Icon(Icons.person,
                      size: 14, color: MyColors.textHint)
                  : null,
            ),
            SizedBox(width: 6.w),
          ],
          GestureDetector(
            onLongPress: isMe ? onLongPress : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 0.72.sw),
              child: Container(
                padding: message.isImage
                    ? EdgeInsets.zero
                    : EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isMe ? MyColors.primary : MyColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                    bottomLeft:
                        isMe ? Radius.circular(16.r) : Radius.circular(4.r),
                    bottomRight:
                        isMe ? Radius.circular(4.r) : Radius.circular(16.r),
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
                              color: isMe
                                  ? Colors.white60
                                  : MyColors.textHint,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
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

  const _ImageBubble(
      {required this.imageUrl, this.caption, required this.isMe});

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
              child: const Icon(Icons.broken_image_outlined,
                  color: MyColors.textHint),
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
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onImage;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12.w, 8.h, 12.w, MediaQuery.of(context).viewInsets.bottom + 12.h),
      decoration: BoxDecoration(
        color: MyColors.surface,
        boxShadow: const [
          BoxShadow(
              color: MyColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          // Image picker
          IconButton(
            onPressed: onImage,
            icon: const Icon(Icons.image_outlined, color: MyColors.primary),
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
                hintStyle: AppTextStyles.bodySmall
                    .copyWith(color: MyColors.textHint),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 10.h),
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
              decoration: const BoxDecoration(
                color: MyColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
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
          Icon(Icons.waving_hand_rounded,
              size: 48, color: MyColors.accent),
          SizedBox(height: 12.h),
          Text('ابدأ المحادثة!',
              style: AppTextStyles.titleMedium
                  .copyWith(color: MyColors.textSecondary)),
        ],
      ),
    );
  }
}
