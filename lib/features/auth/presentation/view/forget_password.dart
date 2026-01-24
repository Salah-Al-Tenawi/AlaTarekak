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
  final GlobalKey<FormState> fomrKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
          key: fomrKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 300.h,
                ),
                CustomTextformfild(
                  title: "البريد الإلكتروني",
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  icon: const Icon(Icons.email_outlined),
                  validator: (val) => inputvaild(val!, "email", 40, 6),
                ),
                SizedBox(
                  height: 50.h,
                ),
                BlocConsumer<ForgetPasswordCubit, ForgetPasswordState>(
                  listener: (context, state) {
                    if (state is ForgetPasswordSuccsess) {
                      Get.offAllNamed(RouteName.login);
                      showMySnackBar(context,
                          "تحقق من الرسائل الواردة على بريدك الإلكتروني");
                    }
                    if (state is ForgetPasswordErorr) {
                      showMySnackBar(context, state.message);
                    }
                  },
                  builder: (context, state) {
                    return state is ForgetPasswordLoading
                        ? LottieBuilder.asset(
                            ImagesUrl.loadinglottie,
                            height: 60,
                            width: 60,
                          )
                        : MyButton(
                            onPressed: () {
                              if (fomrKey.currentState!.validate()) {
                                context
                                    .read<ForgetPasswordCubit>()
                                    .sendEmail(email.text.trim());
                              }
                            },
                            borderRadius: true,
                            color: MyColors.primaryText,
                            splashcolor: MyColors.primary,
                            width: 140.w,
                            child: const Text(
                              "تأكيد",
                              style: TextStyle(color: MyColors.greyTextColor),
                            ),
                          );
                  },
                ),
              ],
            ),
          )),
    );
  }
}
