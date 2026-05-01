import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';

class ProfileEditButton extends StatelessWidget {
  const ProfileEditButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: MyButton(
          color: MyColors.textHint,
          borderRadius: true,
          width: 80.w,
          onPressed: () {
            context.read<ProfileCubit>().emiteditMyProfile();
          },
          child: const Text("تعديل", style: AppTextStyles.bodySmall)),
    );
  }
}
