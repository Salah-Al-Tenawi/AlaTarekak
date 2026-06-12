import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/otp_field_style.dart';
import 'package:otp_text_field/style.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/custom_text_form.dart';
import 'package:alatarekak/features/e_pay/presantion/manger/cubit/veriyotp_epy_cubit.dart';

class VerifyOtpEPay extends StatefulWidget {
  const VerifyOtpEPay({super.key});

  @override
  State<VerifyOtpEPay> createState() => _VerifyOtpEPayScreenState();
}

class _VerifyOtpEPayScreenState extends State<VerifyOtpEPay> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _otpCode = '';

  // مرحلة OTP محفوظة محلياً حتى لا ترتد الشاشة لنموذج البداية
  // إذا فشل التحقق من الرمز (حالة الخطأ ليست SuccInit).
  bool _otpStage = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded,
              color: MyColors.primary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text('تفعيل المحفظة', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      body: BlocConsumer<VeriyotpEpyCubit, VeriyotpEpyState>(
        listener: (context, state) {
          if (state is VeriyotpEpyErorr) {
            AppSnackBar.error(state.message);
          } else if (state is VeriyotpEpySuccInit) {
            setState(() => _otpStage = true);
            AppSnackBar.success('تم إرسال رمز التحقق إلى هاتفك');
          } else if (state is VeriyotpEpySuccCreate) {
            AppSnackBar.success('تم تفعيل محفظتك الإلكترونية بنجاح');
            Get.back(result: true);
          }
        },
        builder: (context, state) {
          final isLoading = state is VeriyotpEpyLoading;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
            child: _otpStage
                ? _buildOtpVerification(context, isLoading)
                : _buildInitialForm(context, isLoading),
          );
        },
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // المرحلة الأولى: رقم الهاتف + كلمة المرور
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildInitialForm(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            icon: Icons.account_balance_wallet_outlined,
            title: 'إنشاء محفظة إلكترونية',
            subtitle:
                'أدخل رقم هاتفك وكلمة المرور الخاصة بحسابك لتفعيل المحفظة الإلكترونية',
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: MyColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: MyColors.shadowLight,
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                CustomTextformfild(
                  controller: _phoneController,
                  title: "رقم الهاتف",
                  keyboardType: TextInputType.phone,
                  icon: Icon(Icons.phone_rounded, color: MyColors.accent),
                  fill: true,
                  fillColor: MyColors.background,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال رقم الهاتف';
                    }
                    if (value.length < 10) {
                      return 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل';
                    }
                    return null;
                  },
                ),
                CustomTextformfild(
                  controller: _passwordController,
                  title: "كلمة المرور",
                  icon: Icon(Icons.lock_rounded, color: MyColors.accent),
                  scureText: true,
                  fill: true,
                  fillColor: MyColors.background,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          _SubmitButton(
            label: 'تفعيل المحفظة',
            isLoading: isLoading,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                context.read<VeriyotpEpyCubit>().initialWallet(
                      _phoneController.text,
                      _passwordController.text,
                    );
              }
            },
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // المرحلة الثانية: رمز التحقق
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildOtpVerification(BuildContext context, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          icon: Icons.sms_outlined,
          title: 'التحقق من الرمز',
          subtitle:
              'أدخل الرمز المكون من 6 أرقام المرسل إلى الرقم ${_phoneController.text}',
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: MyColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: MyColors.shadowLight,
                  blurRadius: 10,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: OTPTextField(
              length: 6,
              width: MediaQuery.of(context).size.width,
              fieldWidth: 42,
              style: AppTextStyles.titleMedium,
              textFieldAlignment: MainAxisAlignment.spaceAround,
              fieldStyle: FieldStyle.box,
              outlineBorderRadius: 12,
              otpFieldStyle: OtpFieldStyle(
                backgroundColor: MyColors.background,
                borderColor: MyColors.border,
                enabledBorderColor: MyColors.border,
                focusBorderColor: MyColors.accent,
              ),
              onChanged: (pin) {
                setState(() => _otpCode = pin);
              },
              onCompleted: (pin) {
                _otpCode = pin;
                context.read<VeriyotpEpyCubit>().createWallet(
                      _phoneController.text,
                      pin,
                    );
              },
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('لم تستلم الرمز؟',
                style: AppTextStyles.bodySmall
                    .copyWith(color: MyColors.textSecondary)),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<VeriyotpEpyCubit>().initialWallet(
                            _phoneController.text,
                            _passwordController.text,
                          );
                    },
              child: Text('إعادة الإرسال',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: MyColors.accent)),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        _SubmitButton(
          label: 'تأكيد الرمز',
          isLoading: isLoading,
          onPressed: _otpCode.length == 6
              ? () {
                  context.read<VeriyotpEpyCubit>().createWallet(
                        _phoneController.text,
                        _otpCode,
                      );
                }
              : null,
        ),
        SizedBox(height: 8.h),
        TextButton.icon(
          onPressed:
              isLoading ? null : () => setState(() => _otpStage = false),
          icon: Icon(Icons.edit_rounded, size: 16, color: MyColors.primary),
          label: Text('تعديل رقم الهاتف',
              style:
                  AppTextStyles.labelMedium.copyWith(color: MyColors.primary)),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Header (أيقونة + عنوان + وصف)
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _Header extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Header(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: MyColors.accentLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: MyColors.accent, size: 38),
        ),
        SizedBox(height: 16.h),
        Text(title, style: AppTextStyles.titleLarge),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: MyColors.textSecondary, height: 1.6),
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// زر الإرسال مع حالة التحميل
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _SubmitButton(
      {required this.label, required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: MyColors.primary,
          disabledBackgroundColor: MyColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(label, style: AppTextStyles.buttonLarge),
      ),
    );
  }
}
