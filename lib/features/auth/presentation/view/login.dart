import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
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
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ━━ Header gradient ━━
          Container(
            height: screenHeight * 0.34,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [MyColors.navy, MyColors.primary, MyColors.blue],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ━━ اللوغو ━━
                  Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MyColors.accent.withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  Text(
                    'مرحباً بعودتك',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 6.h),

                  Text(
                    'سعداء بعودتك، لنكمل رحلتك معنا',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ━━ البطاقة البيضاء ━━
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: MyColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(32.r)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24.w,
                  28.h,
                  24.w,
                  MediaQuery.of(context).viewInsets.bottom + 24.h,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تسجيل الدخول', style: AppTextStyles.titleLarge),
                      SizedBox(height: 4.h),
                      Text(
                        'أدخل بياناتك للمتابعة',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: MyColors.textSecondary),
                      ),
                      SizedBox(height: 24.h),

                      TextFiledsLogin(email: email, password: password),
                      SizedBox(height: 24.h),

                      ColumnButtonsLogin(
                        phone: email,
                        password: password,
                        formKey: formKey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
