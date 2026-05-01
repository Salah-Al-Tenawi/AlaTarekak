import 'package:alatarekak/core/them/app_spacing.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/utils/functions/input_valid.dart';

import 'package:alatarekak/features/auth/presentation/manger/login_cubit/login_cubit.dart';
class TextFiledsLogin extends StatelessWidget {
  final TextEditingController phone;
  final TextEditingController password;

  const TextFiledsLogin({
    super.key,
    required this.phone,
    required this.password,
  });

  // ✅ obscure state
  @override
  Widget build(BuildContext context) {
    return _TextFieldsBody(phone: phone, password: password);
  }
}

// ✅ StatefulWidget منفصل عشان obscureText
class _TextFieldsBody extends StatefulWidget {
  final TextEditingController phone;
  final TextEditingController password;

  const _TextFieldsBody({required this.phone, required this.password});

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
          controller: widget.phone,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: "944 0XX XXX",
            // ✅ prefix من الواجهة: +963 + سهم
            prefixIcon: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "+963",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: MyColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: MyColors.textHint,
                  ),
                ],
              ),
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
            // ✅ أيقونة العين من الواجهة
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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