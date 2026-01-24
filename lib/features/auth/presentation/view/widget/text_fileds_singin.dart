import 'package:flutter/material.dart';
import 'package:alatarekak/core/utils/functions/input_valid.dart';
import 'package:alatarekak/core/utils/widgets/custom_text_form.dart';

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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextformfild(
                title: "الأسم الأخير",
                validator: (val) => inputvaild(val!, "username", 15, 2),
                controller: lastname,
                icon: const Icon(Icons.person_outline),
              ),
            ),
            Expanded(
              child: CustomTextformfild(
                title: "الأسم الأول",
                validator: (val) => inputvaild(val!, "username", 15, 2),
                controller: firstname,
                icon: const Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        CustomTextformfild(
          validator: (val) => inputvaild(val!, "email", 20, 10),
          keyboardType: TextInputType.emailAddress,
          icon: const Icon(Icons.email_outlined),
          title: "البريد الإلكتروني",
          controller: email,
        ),
        CustomTextformfild(
          validator: (val) => inputvaild(val!, "password", 35, 9),
          keyboardType: TextInputType.visiblePassword,
          scureText: true,
          icon: const Icon(Icons.lock_outline),
          title: "كلمة المرور",
          controller: password,
        ),
        CustomTextformfild(
          validator: (val) => inputvaild(val!, "password", 35, 9),
          keyboardType: TextInputType.visiblePassword,
          scureText: true,
          icon: const Icon(Icons.verified_user_outlined),
          title: "تأكيد كلمة المرور",
          controller: passwordConfirm,
        ),
      ],
    );
  }
}
