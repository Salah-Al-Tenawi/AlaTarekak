import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_edit_button.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_save_button.dart';

class ProfileSaveAndEditButtons extends StatelessWidget {
  final ProfileEntity? profileEntityWithEdit;
  const ProfileSaveAndEditButtons({super.key, this.profileEntityWithEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.only(
          top: 0.h, bottom: 0.h, right: 0.w, left: 260.w),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoadedState) {
            switch (state.mode) {
              case ProfileMode.myView:
                return const ProfileEditButton();
              case ProfileMode.myEdit:
                return ProfileSaveButton(
                    profileEntityWithEdit: profileEntityWithEdit);

              case ProfileMode.otherView:
                return const SizedBox();
            }
          }

          return const SizedBox();
        },
      ),
    );
  }
}
