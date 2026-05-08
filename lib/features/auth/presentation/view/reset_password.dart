import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/auth/presentation/manger/forget_password_cubit/forget_password_cubit.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocConsumer<ForgetPasswordCubit, ForgetPasswordState>(
      listener: (context, state) {
        if (state is ForgetPasswordResetSuccess) {
          AppSnackBar.success('تم تغيير كلمة المرور بنجاح');
          Get.offAllNamed(RouteName.login);
        }
        if (state is ForgetPasswordErorr) {
          AppSnackBar.error(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is ForgetPasswordLoading;
        final isNewVisible = state is ForgetPasswordPasswordVisible
            ? state.isNewVisible
            : false;
        final isConfirmVisible = state is ForgetPasswordPasswordVisible
            ? state.isConfirmVisible
            : false;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              // ━━ Header gradient ━━
              Container(
                height: screenHeight * 0.34,
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
                      // ━━ زر الإغلاق ━━
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 22),
                            onPressed: () => Get.offAllNamed(RouteName.login),
                          ),
                        ),
                      ),

                      const Spacer(),

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
                          Icons.lock_open_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      Text(
                        'كلمة مرور جديدة',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 6.h),

                      Text(
                        'أدخل كلمة المرور الجديدة وتأكد منها',
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
                          Text('تعيين كلمة المرور',
                              style: AppTextStyles.titleLarge),
                          SizedBox(height: 4.h),
                          Text(
                            'يجب أن تكون 8 أحرف على الأقل',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: MyColors.textSecondary),
                          ),

                          SizedBox(height: 28.h),

                          // ━━ كلمة المرور الجديدة ━━
                          TextFormField(
                            controller: _newPassword,
                            obscureText: !isNewVisible,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'أدخل كلمة المرور';
                              }
                              if (val.length < 8) {
                                return 'يجب أن تكون 8 أحرف على الأقل';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'كلمة المرور الجديدة',
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: MyColors.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isNewVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: MyColors.textHint,
                                ),
                                onPressed: () => context
                                    .read<ForgetPasswordCubit>()
                                    .toggleNewPassword(),
                              ),
                            ),
                          ),

                          SizedBox(height: 14.h),

                          // ━━ تأكيد كلمة المرور ━━
                          TextFormField(
                            controller: _confirmPassword,
                            obscureText: !isConfirmVisible,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'أكد كلمة المرور';
                              }
                              if (val != _newPassword.text) {
                                return 'كلمتا المرور غير متطابقتين';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'تأكيد كلمة المرور',
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: MyColors.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isConfirmVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: MyColors.textHint,
                                ),
                                onPressed: () => context
                                    .read<ForgetPasswordCubit>()
                                    .toggleConfirmPassword(),
                              ),
                            ),
                          ),

                          SizedBox(height: 28.h),

                          // ━━ زر الحفظ ━━
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
                                            .resetPassword(
                                              email: widget.email,
                                              otp: widget.otp,
                                              newPassword: _newPassword.text,
                                            );
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
                                  : Text('حفظ كلمة المرور',
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
