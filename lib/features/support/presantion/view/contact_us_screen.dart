import 'package:flutter/material.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/support/presantion/manger/contact_support_cubit/contact_support_cubit.dart';

/// شاشة التواصل مع الدعم — تستدعي POST /api/contact ثم تفتح
/// شاشة الشات الحقيقية بـ conversation_id (المحادثة عادية تماماً).
/// هذه الشاشة تعمل حتى أثناء الحظر (قناة الاعتراض المصممة).
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContactSupportCubit, ContactSupportState>(
      listener: (context, state) {
        if (state is ContactSupportReady) {
          // 200 و201 سيّان — افتح الشات (استبدال الشاشة الحالية)
          Get.offNamed(
            RouteName.chatScreen,
            arguments: {
              'conversationId': state.conversationId,
              'title': 'الدعم الفني',
              'avatar': null,
              'isSupport': true,
            },
          );
        } else if (state is ContactSupportFailure) {
          AppSnackBar.error(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: MyColors.background,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_ios_rounded,
                size: 20),
            onPressed: () => Get.back(),
          ),
          title: Text('الدعم الفني', style: AppTextStyles.titleMedium.copyWith(color: MyColors.textOnDark)),
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 96.w,
                height: 96.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MyColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.support_agent_rounded,
                    size: 52, color: MyColors.primary),
              ),
              SizedBox(height: 24.h),
              Text(
                'تحدث مع فريق الدعم',
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              Text(
                'سيتم فتح محادثة مباشرة مع أحد موظفي الدعم '
                'للإجابة عن استفساراتك ومساعدتك في حل أي مشكلة.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: MyColors.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              BlocBuilder<ContactSupportCubit, ContactSupportState>(
                builder: (context, state) {
                  final isLoading = state is ContactSupportRequesting;
                  return SizedBox(
                    height: 52.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isLoading
                          ? null
                          : () => context
                              .read<ContactSupportCubit>()
                              .openSupportChat(),
                      icon: isLoading
                          ? const AppLoader.onButton()
                          : const Icon(Icons.chat_bubble_outline_rounded,
                              color: Colors.white, size: 20),
                      label: Text(
                        isLoading ? 'جارٍ فتح المحادثة...' : 'بدء المحادثة',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
