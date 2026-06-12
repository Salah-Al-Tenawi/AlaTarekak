import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/support/presantion/manger/contact_support_cubit/contact_support_cubit.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'مرحباً! أنا مساعدك في منصة عطريقك.\nكيف يمكنني مساعدتك اليوم؟',
      isSupport: true,
    ),
  ];
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _messages.add(_ChatMessage(text: text, isSupport: false)));
    _controller.clear();
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add(const _ChatMessage(
          text: 'شكراً على رسالتك. سيرد عليك فريق الدعم في أقرب وقت.',
          isSupport: true,
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContactSupportCubit, ContactSupportState>(
      listener: (context, state) {
        if (state is ContactSupportAgentRequested) {
          setState(() {
            _messages.add(const _ChatMessage(
              text:
                  'تم استلام طلبك! سيتواصل معك أحد أعضاء فريق الدعم في أقرب وقت ممكن.',
              isSupport: true,
            ));
          });
          _scrollToBottom();
        } else if (state is ContactSupportFailure) {
          AppSnackBar.error(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: MyColors.background,
        appBar: AppBar(
          backgroundColor: MyColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_ios_rounded,
                color: MyColors.primary, size: 20),
            onPressed: () => Get.back(),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: MyColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.support_agent_rounded,
                    color: MyColors.primary, size: 18),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('دعم العملاء', style: AppTextStyles.titleMedium),
                  Text(
                    'متاح للمساعدة',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: MyColors.success, fontSize: 10.sp),
                  ),
                ],
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 12.h),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _ChatBubble(message: _messages[i]),
              ),
            ),
            BlocBuilder<ContactSupportCubit, ContactSupportState>(
              builder: (context, state) {
                final isDone = state is ContactSupportAgentRequested;
                final isLoading = state is ContactSupportRequesting;
                if (isDone) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 6.h),
                  child: OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => context
                            .read<ContactSupportCubit>()
                            .requestAgent(),
                    icon: isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: MyColors.primary))
                        : const Icon(Icons.person_add_alt_1_rounded,
                            size: 16),
                    label: Text('تواصل مع موظف دعم',
                        style: AppTextStyles.labelMedium),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MyColors.primary,
                      side: BorderSide(color: MyColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size(double.infinity, 40.h),
                    ),
                  ),
                );
              },
            ),
            _InputBar(controller: _controller, onSend: _sendMessage),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isSupport;
  const _ChatMessage({required this.text, required this.isSupport});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSupport = message.isSupport;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isSupport ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isSupport) ...[
            CircleAvatar(
              radius: 14.r,
              backgroundColor: MyColors.primary.withValues(alpha: 0.1),
              child: Icon(Icons.support_agent_rounded,
                  color: MyColors.primary, size: 14),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isSupport ? MyColors.surface : MyColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(isSupport ? 0 : 14),
                  bottomRight: Radius.circular(isSupport ? 14 : 0),
                ),
                boxShadow: [
                  BoxShadow(
                      color: MyColors.shadowLight,
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Text(
                message.text,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSupport ? MyColors.textPrimary : Colors.white,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          if (!isSupport) SizedBox(width: 8.w),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 16.h),
      color: MyColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: MyColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: MyColors.border),
              ),
              child: TextField(
                controller: controller,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: AppTextStyles.bodySmall
                      .copyWith(color: MyColors.textHint),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 10.h),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: MyColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
