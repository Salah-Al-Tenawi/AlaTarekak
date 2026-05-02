
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/auth/presentation/manger/singin_cubit/singin_cubit.dart';
import 'package:alatarekak/features/auth/presentation/view/widget/otp_text_form_filed.dart';

class VerfiyEmailSingin extends StatefulWidget {
  const VerfiyEmailSingin({super.key});

  @override
  State<VerfiyEmailSingin> createState() => _VerfiyEmailSinginState();
}

class _VerfiyEmailSinginState extends State<VerfiyEmailSingin> {
  late final String email;

  @override
  void initState() {
    super.initState();
    email = Get.arguments as String;
    
    
    context.read<SinginCubit>().startOtpTimer();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SinginCubit, SinginState>(
     listener: (context, state) {
  if (state is SinginSuccess) {
    AppSnackBar.success("تم انشاء الحساب");
    Get.offAllNamed(RouteName.home);
    
  }
  if (state is SinginErorre) {
    AppSnackBar.error("خطأ ");
  }
},
      builder: (context, state) {
        final secondsLeft =
            state is SinginOtpTimerTick ? state.secondsLeft : 60;
        final canResend =
            state is SinginOtpTimerTick ? state.canResend : false;
        final isLoading = state is SinginLoading;
        final otpComplete =
            state is SinginOtpChanged ? state.otp.length == 6 : false;

        return Scaffold(
          
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ━━ أيقونة البريد ━━
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
                  "لقد أرسلنا رمز التحقق إلى",
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

                // ━━ OTP ━━
                OtpTextform(
                  onCompleted: (otp) {
                    context.read<SinginCubit>().onOtpChanged(otp);
                  },
                  onChanged: (otp) {
                    context.read<SinginCubit>().onOtpChanged(otp);
                  },
                ),

                SizedBox(height: 32.h),

                // ━━ زر التحقق ━━
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                   onPressed: isLoading
    ? null
    : () => context.read<SinginCubit>().checkOtp(email),
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
                          ? () =>
                              context.read<SinginCubit>().sendOtpAgain()
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
        );
      },
    );
  }
}