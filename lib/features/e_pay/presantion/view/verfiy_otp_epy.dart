import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/state_manager.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
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

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفعيل المحفظة الإلكترونية'),
        centerTitle: true,
        backgroundColor: MyColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<VeriyotpEpyCubit, VeriyotpEpyState>(
        listener: (context, state) {
          if (state is VeriyotpEpyErorr) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("حدث خطأ ما "),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is VeriyotpEpySuccInit) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إرسال رمز التحقق إلى هاتفك'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is VeriyotpEpySuccCreate) {
            Get.offAllNamed(RouteName.home);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إنشاء المحفظة الإلكترونية بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: state is VeriyotpEpySuccInit
                ? _buildOtpVerification(context, state)
                : _buildInitialForm(context, state),
          );
        },
      ),
    );
  }

  Widget _buildInitialForm(BuildContext context, VeriyotpEpyState state) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            const Align(
              alignment: Alignment.topCenter,
              child: Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: MyColors.accent,
              ),
            ),
            SizedBox(height: 20.h),
            const Text(
              'إنشاء محفظة إلكترونية',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              textAlign: TextAlign.center,
              'أدخل رقم هاتفك وكلمة المرور الخاصة بحسابك لتفعيل المحفظة الإلكترونية',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            CustomTextformfild(
              controller: _phoneController,
              title: "رقم الهاتف",
              keyboardType: TextInputType.phone,
              icon: const Icon(
                Icons.phone,
                color: MyColors.accent,
              ),
              fill: true,
              fillColor: Colors.grey[50],
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
            const SizedBox(height: 20),
            CustomTextformfild(
              controller: _passwordController,
              title: "كلمة المرور",
              icon: const Icon(
                Icons.lock,
                color: MyColors.accent,
              ),
              scureText: true,
              fill: true,
              fillColor: Colors.grey[50],
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
            const SizedBox(height: 30),
            if (state is VeriyotpEpyLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<VeriyotpEpyCubit>().initialWallet(
                            _phoneController.text,
                            _passwordController.text,
                          );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'تفعيل المحفظة',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpVerification(BuildContext context, VeriyotpEpyState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          const Align(
            alignment: Alignment.topCenter,
            child: Icon(
              Icons.verified_user,
              size: 80,
              color: MyColors.accent,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'التحقق من الرمز',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10.h),
          Text(
            'تم إرسال رمز التحقق إلى الرقم: ${_phoneController.text}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 30.h),
          OTPTextField(
            length: 6,
            width: MediaQuery.of(context).size.width,
            fieldWidth: 45,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textFieldAlignment: MainAxisAlignment.spaceAround,
            fieldStyle: FieldStyle.box,
            outlineBorderRadius: 10,
            onChanged: (pin) {
              _otpCode = pin;
            },
            onCompleted: (pin) {
              _otpCode = pin;
              context.read<VeriyotpEpyCubit>().createWallet(
                    _phoneController.text,
                    pin,
                  );
            },
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'أدخل الرمز المكون من 6 أرقام الذي استلمته على هاتفك',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'لم تستلم الرمز؟',
                style: TextStyle(fontSize: 14, color: MyColors.accent),
              ),
              TextButton(
                onPressed: () {
                  context.read<VeriyotpEpyCubit>().initialWallet(
                        _phoneController.text,
                        _passwordController.text,
                      );
                },
                child: const Text(
                  'إعادة إرسال الرمز',
                  style: TextStyle(color: MyColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          if (state is VeriyotpEpyLoading)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _otpCode.length == 6
                    ? () {
                        context.read<VeriyotpEpyCubit>().createWallet(
                              _phoneController.text,
                              _otpCode,
                            );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'تأكيد الرمز',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
