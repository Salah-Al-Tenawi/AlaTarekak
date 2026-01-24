import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/widgets/cricular_decoration.dart';
import 'package:alatarekak/features/auth/presentation/view/widget/buttons_login.dart';
import 'package:alatarekak/features/auth/presentation/view/widget/text_fileds_login.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CricularDecoration(
                    heghit: 100,
                    width: 120,
                    color: MyColors.primary,
                  ),
                  Positioned(
                    top: 40.h,
                    child: Image.asset(
                      "assets/images/iconpng.png",
                      height: 100.h,
                      width: 100.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 50.h),

              TextFiledsLogin(
                email: email,
                password: password,
              ),

              ColumnButtonsLogin(
                email: email,
                password: password,
                formKey: formKey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
