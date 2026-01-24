import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/functions/input_valid.dart';
import 'package:alatarekak/core/utils/widgets/custom_text_form.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/features/auth/presentation/manger/login_cubit/login_cubit.dart';

class TextFiledsLogin extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController password;

  const TextFiledsLogin({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextformfild(
          validator: (val) => inputvaild(val!, "email", 20, 10),
          keyboardType: TextInputType.emailAddress,
          icon: const Icon(Icons.email_outlined),
          hint: "example@gamil.com",
          title: "البريد الإلكتروني",
          controller: email,
        ),
        SizedBox(height: 20.h),
        CustomTextformfild(
          validator: (val) => inputvaild(val!, "password", 35, 8),
          keyboardType: TextInputType.visiblePassword,
          scureText: true,
          icon: const Icon(Icons.lock_clock_outlined),
          title: "كلمة المرور",
          controller: password,
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: MyButton(
                onPressed: () {
                  context.read<LoginCubit>().emitGotoForgetPassword();
                },
                child: const Text(
                  "هل نسيت كلمة المرور؟",
                  style: font16blacknormal,
                )),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
