import 'package:flutter/material.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/features/auth/presentation/manger/login_cubit/login_cubit.dart';

/// الدخول بحسابٍ اجتماعي — **مخفيّ لا محذوف**.
///
/// زرّ Google كان معروضاً و`onPressed` فارغة: يضغطه المستخدم فلا يقع
/// شيء، فيظنّ العطل في حسابه أو في التطبيق. وخلفه لا يوجد شيء أصلاً —
/// `loginWithGoogle` في الكيوبت معلَّقة، ولا مسار عند الخادم.
///
/// أُخفي هو وفاصلُه: فاصلٌ يقول «أو عبر الوسائل الاجتماعي» ولا شيء تحته
/// أسوأ من غيابه. والزرّ باقٍ في الشيفرة — يُعاد بتحويل هذه إلى `true`
/// يوم يصير خلفه مسار يعمل.
const bool kSocialLoginEnabled = false;

class ColumnButtonsLogin extends StatelessWidget {
  final TextEditingController phone;
  final TextEditingController password;
  final GlobalKey<FormState> formKey;

  const ColumnButtonsLogin({
    super.key,
    required this.phone,
    required this.password,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          Get.offAllNamed(RouteName.home);
        } else if (state is LoginNavigateToSignup) {
          Get.toNamed(RouteName.singin);
        } else if (state is LoginNavigationToForgetPassword) {
          Get.toNamed(RouteName.forgetpassword);
        } else if (state is LoginEmailNotVerified) {
          // ينقصه رمز التحقق لا كلمة مرور — ننقله إلى الشاشة التي تُتمّه
          // بدل تركه أمام رسالة خطأ لا مخرج منها
          Get.toNamed(RouteName.verfiyEmailSingin, arguments: state.email);
          showMySnackBar(
            context,
            'لم يتم تأكيد بريدك بعد — أدخل الرمز المُرسل إليك، '
            'أو اطلب رمزاً جديداً',
            duration: const Duration(seconds: 4),
          );
        } else if (state is LoginError) {
          final message = HandelErorrMessage.withStatus(
              HandelErorrMessage.login(state.message), state.statusCode);
          showMySnackBar(context, message,
              duration: const Duration(seconds: 3));
        }
      },
      builder: (context, state) {
        return Column(
          children: [

            // ━━━━━━━━━━━━━━━━━━━━━━━━
            // ✅ زر تسجيل الدخول مع سهم
            // ━━━━━━━━━━━━━━━━━━━━━━━━
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton.icon(
                // ✅ لا style — يأخذ من Theme
                onPressed: state is LoginLoading
                    ? null
                    : () {
                        if (formKey.currentState!.validate()) {
                          context.read<LoginCubit>().login(
                            phone.text.trim(),
                            password.text.trim(),
                          );
                        }
                      },
                // ✅ السهم من الواجهة
                icon: state is LoginLoading
                    ? const AppLoader.onButton()
                    : const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text("تسجيل الدخول"),
              ),
            ),

            SizedBox(height: 24.h),

            // ━━━━━━━━━━━━━━━━━━━━━━━━
            // ✅ فاصل بنص أطول
            // ━━━━━━━━━━━━━━━━━━━━━━━━
            // الفاصل والأزرار الاجتماعية — انظر [kSocialLoginEnabled]
            if (kSocialLoginEnabled) ...[
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      "أو عبر الوسائل الاجتماعي",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MyColors.textHint,
                          ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MyColors.textPrimary,
                        side: BorderSide(color: MyColors.border),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      icon: Image.asset(ImagesUrl.imagegoogle,
                          width: 20, height: 20),
                      label: Text(
                        "Google",
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
              ),
              SizedBox(height: 24.h),
            ],

            // ━━━━━━━━━━━━━━━━━━━━━━━━
            // ✅ سجل الآن
            // ━━━━━━━━━━━━━━━━━━━━━━━━
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "ليس لديك حساب؟ ",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MyColors.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.read<LoginCubit>().emitgotoSingin(),
                  child: Text(
                    "سجل الآن",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MyColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
