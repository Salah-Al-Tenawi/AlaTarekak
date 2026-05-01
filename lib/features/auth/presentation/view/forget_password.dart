import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:lottie/lottie.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/functions/input_valid.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/core/utils/widgets/custom_text_form.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/features/auth/presentation/manger/forget_password_cubit/forget_password_cubit.dart';
class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final TextEditingController email = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 120.h),

                  /// العنوان
                  Center(
                    child: Text(
                      "استعادة كلمة المرور",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: MyColors.primary,
                          ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  Text(
                    "أدخل بريدك الإلكتروني لإرسال رابط إعادة التعيين",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MyColors.textHint,
                        ),
                  ),

                  SizedBox(height: 40.h),

                  /// Email Field
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) =>
                        inputvaild(val!, "email", 40, 6),
                    decoration: InputDecoration(
                      hintText: "البريد الإلكتروني",
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  /// Button
                  BlocConsumer<ForgetPasswordCubit, ForgetPasswordState>(
                    listener: (context, state) {
                      if (state is ForgetPasswordSuccsess) {
                        Get.offAllNamed(RouteName.login);
                        showMySnackBar(
                          context,
                          "تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني",
                        );
                      }

                      if (state is ForgetPasswordErorr) {
                        showMySnackBar(context, state.message);
                      }
                    },
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton.icon(
                          onPressed: state is ForgetPasswordLoading
                              ? null
                              : () {
                                  if (formKey.currentState!.validate()) {
                                    context
                                        .read<ForgetPasswordCubit>()
                                        .sendEmail(email.text.trim());
                                  }
                                },

                          icon: state is ForgetPasswordLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),

                          label: const Text("إرسال الرابط"),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}