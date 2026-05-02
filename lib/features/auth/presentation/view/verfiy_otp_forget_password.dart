import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/features/auth/presentation/view/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/auth/presentation/manger/forget_password_cubit/forget_password_cubit.dart';
import 'package:alatarekak/features/auth/presentation/view/widget/otp_text_form_filed.dart';


class VerifyOtpForgetPassword extends StatelessWidget {
  final String email;
  const VerifyOtpForgetPassword({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
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
          AppSnackBar.error( state.message);
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
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w ,vertical: 120.h ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: const BoxDecoration(
                      color: MyColors.accentLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      color: MyColors.accent,
                      size: 32,
                    ),
                  ),
            
                  SizedBox(height: 20.h),
            
                  Text(
                    "تحقق من بريدك",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
            
                  SizedBox(height: 8.h),
            
                  Text(
                    "أرسلنا رمز التحقق إلى",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MyColors.textSecondary,
                        ),
                  ),
            
                  SizedBox(height: 4.h),
            
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MyColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
            
                  SizedBox(height: 32.h),
            
                  OtpTextform(
                    onChanged: (otp) =>
                        context.read<ForgetPasswordCubit>().onOtpChanged(otp),
                    onCompleted: (otp) =>
                        context.read<ForgetPasswordCubit>().onOtpChanged(otp),
                  ),
            
                  SizedBox(height: 32.h),
            
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: isLoading || !otpComplete
                          ? null
                          : () => context
                              .read<ForgetPasswordCubit>()
                              .verifyOtp(email),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("تحقق"),
                    ),
                  ),
            
                  SizedBox(height: 20.h),
            
                  // ━━ إعادة الإرسال ━━
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "لم تستلم الرمز؟ ",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MyColors.textSecondary,
                            ),
                      ),
                      GestureDetector(
                        onTap: canResend
                            ? () => context
                                .read<ForgetPasswordCubit>()
                                .resendOtp(email)
                            : null,
                        child: Text(
                          "إعادة الإرسال",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: canResend
                                    ? MyColors.accent
                                    : MyColors.textHint,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (!canResend) ...[
                        SizedBox(width: 4.w),
                        Text(
                          "${secondsLeft}s",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: MyColors.textHint,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}