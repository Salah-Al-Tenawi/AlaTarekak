import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/auth/presentation/manger/forget_password_cubit/forget_password_cubit.dart';
import 'package:alatarekak/features/auth/presentation/view/verfiy_otp_forget_password.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocConsumer<ForgetPasswordCubit, ForgetPasswordState>(
      listener: (context, state) {
        if (state is ForgetPasswordGoToOtp) {
          final cubit = context.read<ForgetPasswordCubit>()..startOtpTimer();
          Get.to(
            () => BlocProvider.value(
              value: cubit,
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
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              // ━━ Header gradient ━━
              Container(
                height: screenHeight * 0.36,
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
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      Text(
                        'نسيت كلمة المرور؟',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 6.h),

                      Text(
                        'سنرسل لك رمز التحقق على بريدك',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withValues(alpha: 0.7),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('البريد الإلكتروني',
                              style: AppTextStyles.titleLarge),
                          SizedBox(height: 4.h),
                          Text(
                            'أدخل بريدك لاستعادة كلمة المرور',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: MyColors.textSecondary),
                          ),
                          SizedBox(height: 28.h),

                          // ━━ حقل الإيميل ━━
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            validator: (val) => val == null || val.isEmpty
                                ? 'أدخل البريد الإلكتروني'
                                : null,
                            decoration: const InputDecoration(
                              hintText: 'user@gmail.com',
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: MyColors.primary),
                            ),
                          ),

                          SizedBox(height: 28.h),

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
                                  : Text('إرسال رمز التحقق',
                                      style: AppTextStyles.buttonLarge),
                            ),
                          ),
                        ],
                      ),
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
