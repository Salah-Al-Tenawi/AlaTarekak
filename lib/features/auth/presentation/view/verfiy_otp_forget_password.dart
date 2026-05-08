import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/auth/presentation/manger/forget_password_cubit/forget_password_cubit.dart';
import 'package:alatarekak/features/auth/presentation/view/reset_password.dart';
import 'package:alatarekak/features/auth/presentation/view/widget/otp_text_form_filed.dart';

class VerifyOtpForgetPassword extends StatelessWidget {
  final String email;
  const VerifyOtpForgetPassword({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocConsumer<ForgetPasswordCubit, ForgetPasswordState>(
      listener: (context, state) {
        if (state is ForgetPasswordOtpVerified) {
          Get.to(
            () => BlocProvider.value(
              value: context.read<ForgetPasswordCubit>(),
              child: ResetPasswordScreen(
                email: state.email,
                otp: state.otp,
              ),
            ),
          );
        }
        if (state is ForgetPasswordErorr) {
          AppSnackBar.error(state.message);
        }
      },
      builder: (context, state) {
        final secondsLeft = state is ForgetPasswordOtpTimerTick
            ? state.secondsLeft
            : 60;
        final canResend = state is ForgetPasswordOtpTimerTick
            ? state.canResend
            : false;
        final isLoading = state is ForgetPasswordLoading;
        final otpComplete = state is ForgetPasswordOtpChanged
            ? state.otp.length == 6
            : false;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              // ━━ Header gradient ━━
              Container(
                height: screenHeight * 0.38,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [MyColors.navy, MyColors.primary, MyColors.blue],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // ━━ زر الرجوع ━━
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white, size: 20),
                            onPressed: () => Get.back(),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ━━ أيقونة ━━
                      Container(
                        width: 68.w,
                        height: 68.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      Text(
                        'تحقق من بريدك',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 6.h),

                      Text(
                        'أرسلنا رمز التحقق إلى',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),

                      SizedBox(height: 4.h),

                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: MyColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 28.h),
                    ],
                  ),
                ),
              ),

              // ━━ البطاقة البيضاء ━━
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: MyColors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32.r)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24.w,
                      32.h,
                      24.w,
                      MediaQuery.of(context).viewInsets.bottom + 24.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('رمز التحقق', style: AppTextStyles.titleLarge),
                        SizedBox(height: 4.h),
                        Text(
                          'أدخل الرمز المكون من 6 أرقام',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: MyColors.textSecondary),
                        ),

                        SizedBox(height: 28.h),

                        // ━━ OTP ━━
                        OtpTextform(
                          onChanged: (otp) => context
                              .read<ForgetPasswordCubit>()
                              .onOtpChanged(otp),
                          onCompleted: (otp) => context
                              .read<ForgetPasswordCubit>()
                              .onOtpChanged(otp),
                        ),

                        SizedBox(height: 28.h),

                        // ━━ زر التحقق ━━
                        SizedBox(
                          width: double.infinity,
                          height: 52.h,
                          child: ElevatedButton(
                            onPressed: isLoading || !otpComplete
                                ? null
                                : () => context
                                    .read<ForgetPasswordCubit>()
                                    .verifyOtp(email),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('تحقق من الرمز',
                                    style: AppTextStyles.buttonLarge),
                          ),
                        ),

                        SizedBox(height: 20.h),

                        // ━━ إعادة الإرسال ━━
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'لم تستلم الرمز؟ ',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: MyColors.textSecondary),
                              ),
                              GestureDetector(
                                onTap: canResend
                                    ? () => context
                                        .read<ForgetPasswordCubit>()
                                        .resendOtp(email)
                                    : null,
                                child: Text(
                                  'إعادة الإرسال',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: canResend
                                        ? MyColors.accent
                                        : MyColors.textHint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (!canResend) ...[
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: MyColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$secondsLeft ث',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: MyColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
      },
    );
  }
}
