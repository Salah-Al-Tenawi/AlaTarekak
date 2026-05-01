import 'package:alatarekak/core/them/app_spacing.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
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
  final TextEditingController phone = TextEditingController();
  final TextEditingController password = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w ,vertical: 70.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                AppSpacing.h32,
                Center(
                  child: Text(
                    "مرحباً بعودتك",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: MyColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: Text(
                    "سعداء بعودتك مرة أخرى، لنكمل رحلتك معنا",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MyColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                TextFiledsLogin(phone: phone, password: password),
                SizedBox(height: 20.h),
                ColumnButtonsLogin(
                  phone: phone,
                  password: password,
                  formKey: formKey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}