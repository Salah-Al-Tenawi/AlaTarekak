import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
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
    return BlocConsumer<ForgetPasswordCubit, ForgetPasswordState>(
      listener: (context, state) {
        if (state is ForgetPasswordResetSuccess) {
          AppSnackBar.success(" نجحت ");
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
          appBar: AppBar(
            title: const Text("عطريقك"),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Get.offAllNamed(RouteName.login),
              ),
            ],
          ),
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
                      Icons.lock_open_rounded,
                      color: MyColors.accent,
                      size: 32,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  Text(
                    "كلمة مرور جديدة",
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),

                  SizedBox(height: 8.h),

                  Text(
                    "أدخل كلمة المرور الجديدة وتأكد من حفظها",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MyColors.textSecondary,
                        ),
                  ),

                  SizedBox(height: 32.h),

                  // ━━ كلمة المرور الجديدة ━━
                  TextFormField(
                    controller: _newPassword,
                    obscureText: !isNewVisible,
                    validator: (val) {
                      if (val == null || val.isEmpty) return "أدخل كلمة المرور";
                      if (val.length < 8) return "يجب أن تكون 8 أحرف على الأقل";
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: "كلمة المرور الجديدة",
                      prefixIcon: const Icon(Icons.lock_outline),
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
                      if (val == null || val.isEmpty) return "أكد كلمة المرور";
                      if (val != _newPassword.text) return "كلمتا المرور غير متطابقتين";
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: "تأكيد كلمة المرور",
                      prefixIcon: const Icon(Icons.lock_outline),
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

                  SizedBox(height: 24.h),

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
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("حفظ كلمة المرور"),
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