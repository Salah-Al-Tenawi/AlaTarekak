import 'package:alatarekak/core/them/my_colors.dart';
import 'package:flutter/material.dart';
import 'package:alatarekak/core/utils/functions/input_valid.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class TextFieldsSingin extends StatelessWidget {
  final TextEditingController firstname;
  final TextEditingController lastname;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController passwordConfirm;

  const TextFieldsSingin({
    super.key,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.password,
    required this.passwordConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return _TextFieldsSinginBody(
      firstname: firstname,
      lastname: lastname,
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
    );
  }
}

class _TextFieldsSinginBody extends StatefulWidget {
  final TextEditingController firstname;
  final TextEditingController lastname;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController passwordConfirm;

  const _TextFieldsSinginBody({
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.password,
    required this.passwordConfirm,
  });

  @override
  State<_TextFieldsSinginBody> createState() =>
      _TextFieldsSinginBodyState();
}

class _TextFieldsSinginBodyState
    extends State<_TextFieldsSinginBody> {
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// الاسم الأول + الأخير
        Row(
  children: [
    Expanded(
      child: TextFormField(
        controller: widget.firstname,
        validator: (val) =>
            inputvaild(val!, "username", 15, 2),
        decoration: const InputDecoration(
          hintText: "الأسم الأول",
        ),
      ),
    ),
    SizedBox(width: 12.w),
    Expanded(
      child: TextFormField(
        controller: widget.lastname,
        validator: (val) =>
            inputvaild(val!, "username", 15, 2),
        decoration: const InputDecoration(
          hintText: "الأسم الأخير",
        ),
      ),
    ),
  ],
),

        SizedBox(height: 14.h),

        /// البريد الإلكتروني
        TextFormField(
          controller: widget.email,
          keyboardType: TextInputType.emailAddress,
          validator: (val) =>
              inputvaild(val!, "email", 30, 5),
          decoration: const InputDecoration(
            hintText: "البريد الإلكتروني",
          ),
        ),

        SizedBox(height: 14.h),

        /// كلمة المرور
        TextFormField(
          controller: widget.password,
          obscureText: obscurePassword,
          validator: (val) =>
              inputvaild(val!, "password", 35, 8),
          decoration: InputDecoration(
            hintText: "كلمة المرور",
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: MyColors.textHint,
              ),
              onPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
            ),
          ),
        ),

        SizedBox(height: 14.h),

        /// تأكيد كلمة المرور
        TextFormField(
          controller: widget.passwordConfirm,
          obscureText: obscureConfirm,
          validator: (val) =>
              inputvaild(val!, "password", 35, 8),
          decoration: InputDecoration(
            hintText: "تأكيد كلمة المرور",
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: MyColors.textHint,
              ),
              onPressed: () {
                setState(() {
                  obscureConfirm = !obscureConfirm;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}