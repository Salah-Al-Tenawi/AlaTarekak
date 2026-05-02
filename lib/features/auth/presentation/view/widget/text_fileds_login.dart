import 'package:alatarekak/core/them/app_spacing.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/utils/functions/input_valid.dart';

import 'package:alatarekak/features/auth/presentation/manger/login_cubit/login_cubit.dart';
class TextFiledsLogin extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController password;

  const TextFiledsLogin({
    super.key,
    required this.email,
    required this.password,
  });

  // ✅ obscure state
  @override
  Widget build(BuildContext context) {
    return _TextFieldsBody(email: email, password: password);
  }
}

// ✅ StatefulWidget منفصل عشان obscureText
class _TextFieldsBody extends StatefulWidget {
  final TextEditingController email;
  final TextEditingController password;

  const _TextFieldsBody({required this.email, required this.password});

  @override
  State<_TextFieldsBody> createState() => _TextFieldsBodyState();
}

class _TextFieldsBodyState extends State<_TextFieldsBody> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
      
      TextFormField(
  controller: widget.email,
  keyboardType: TextInputType.emailAddress,
  textInputAction: TextInputAction.next,
  textDirection: TextDirection.ltr,
  decoration: InputDecoration(
    hintText: "user@gmail.com",

    prefixIcon: Icon(
      Icons.email_outlined,
      color: MyColors.primary,
    ),
  ),
),
        SizedBox(height: 14.h),

        // ━━━━━━━━━━━━━━━━━━━━━━━━
        // حقل كلمة المرور
        // ━━━━━━━━━━━━━━━━━━━━━━━━
       TextFormField(
  controller: widget.password,
  obscureText: _obscure,
  validator: (val) => inputvaild(val!, "password", 35, 8),
  decoration: InputDecoration(
    hintText: "كلمة المرور",

    prefixIcon: Icon(
      Icons.lock_outline,
      color: MyColors.primary,
    ),

    suffixIcon: IconButton(
      icon: Icon(
        _obscure
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        color: MyColors.textHint,
      ),
      onPressed: () => setState(() => _obscure = !_obscure),
    ),
  ),
),

      AppSpacing.h12,
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              context.read<LoginCubit>().emitGotoForgetPassword();
              
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "نسيت كلمة المرور؟",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MyColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}