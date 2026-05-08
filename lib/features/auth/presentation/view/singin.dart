import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/auth/presentation/view/widget/button_singin.dart';
import 'package:alatarekak/features/auth/presentation/view/widget/drop_down_and_gender_sing.dart';
import 'package:alatarekak/features/auth/presentation/view/widget/text_fileds_singin.dart';

class Singin extends StatefulWidget {
  const Singin({super.key});

  @override
  State<Singin> createState() => _SinginState();
}

class _SinginState extends State<Singin> {
  final TextEditingController firstname = TextEditingController();
  final TextEditingController lastname = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController passwordConfirm = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey();

  @override
  void dispose() {
    firstname.dispose();
    lastname.dispose();
    email.dispose();
    password.dispose();
    passwordConfirm.dispose();
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
            height: screenHeight * 0.27,
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
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MyColors.accent.withValues(alpha: 0.25),
                          blurRadius: 16,
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

                  SizedBox(height: 12.h),

                  Text(
                    'أنشئ حسابك',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  Text(
                    'انضم إلى عطريقك وابدأ رحلتك',
                    style: TextStyle(
                      fontSize: 12.sp,
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
                      Text('بيانات الحساب', style: AppTextStyles.titleLarge),
                      SizedBox(height: 4.h),
                      Text(
                        'أدخل معلوماتك لإنشاء حساب جديد',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: MyColors.textSecondary),
                      ),
                      SizedBox(height: 24.h),

                      TextFieldsSingin(
                        firstname: firstname,
                        lastname: lastname,
                        email: email,
                        password: password,
                        passwordConfirm: passwordConfirm,
                      ),

                      SizedBox(height: 14.h),

                      const DropDownAndGenderSing(),

                      SizedBox(height: 28.h),

                      ButtonSingin(
                        firstname: firstname,
                        lastname: lastname,
                        email: email,
                        formKey: formKey,
                        password: password,
                        passwordConfirm: passwordConfirm,
                      ),

                      SizedBox(height: 16.h),
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
