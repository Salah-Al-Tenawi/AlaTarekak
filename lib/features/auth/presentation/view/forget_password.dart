import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/auth/presentation/manger/forget_password_cubit/forget_password_cubit.dart';
import 'package:alatarekak/features/auth/presentation/view/verfiy_otp_forget_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';


class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPassword> {
  final TextEditingController _email = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgetPasswordCubit, ForgetPasswordState>(
      listener: (context, state) {
        if (state is ForgetPasswordGoToOtp) {
          Get.to(
            () => BlocProvider.value(
              value: context.read<ForgetPasswordCubit>()..startOtpTimer(),
              child: VerifyOtpForgetPassword(email: state.email),
            ),
          );
        }
        if (state is ForgetPasswordErorr) {
          AppSnackBar.error(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is ForgetPasswordLoading;

        return Scaffold(
          
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ━━ أيقونة ━━
                  Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: const BoxDecoration(
                      color: MyColors.accentLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: MyColors.accent,
                      size: 32,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  Text(
                    "نسيت كلمة المرور؟",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  SizedBox(height: 8.h),

                  Text(
                    "أدخل بريدك الإلكتروني وسنرسل لك رمز التحقق",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MyColors.textSecondary,
                        ),
                  ),

                  SizedBox(height: 32.h),

                  // ━━ حقل الإيميل ━━
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) =>
                        val == null || val.isEmpty ? "أدخل البريد الإلكتروني" : null,
                    decoration: const InputDecoration(
                      hintText: "البريد الإلكتروني",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // ━━ زر الإرسال ━━
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context
                                    .read<ForgetPasswordCubit>()
                                    .sendEmail(_email.text.trim());
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("إرسال رمز التحقق"),
                    ),
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