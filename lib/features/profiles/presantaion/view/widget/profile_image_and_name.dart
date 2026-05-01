import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/profiles/data/model/enum/image_mode.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/core/utils/functions/show_image.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/get_profile_image.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_verification_icon.dart';

class ProfileImageAndName extends StatelessWidget {
  final ProfileEntity? profileEntitYEdit;
  final String? imageurl;
  final String name;
  final String verification;
  final ProfileMode mode;

  const ProfileImageAndName({
    super.key,
    required this.imageurl,
    required this.name,
    required this.verification,
    required this.mode,
    this.profileEntitYEdit,
  });

  void _onPickImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (!context.mounted) return;

    if (pickedFile != null) {
      context.read<ProfileCubit>().pickImage(
            pickedFile,
            ProfileImagePicMode.user,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: mode == ProfileMode.myEdit
              ? BlocBuilder<ProfileCubit, ProfileState>(
                  buildWhen: (previous, current) =>
                      current is ProfileLoadedState,
                  builder: (context, state) {
                    final cubit = context.read<ProfileCubit>();

                    final imageProvider = () {
                      if (cubit.userPhoto != null) {
                        return FileImage(File(cubit.userPhoto!.path));
                      }
                      return getProfileImage(
                          context, profileEntitYEdit?.profilePhoto);
                    }();

                    final avatar = CircleAvatar(
                      backgroundColor: MyColors.primary,
                      maxRadius: 45,
                      backgroundImage: imageProvider,
                    );

                    return MyButton(
                      splashcolor: Colors.white,
                      onPressed: () => _onPickImage(context),
                      child: avatar,
                    );
                  },
                )
              : MyButton(
                  splashcolor: Colors.white,
                  onPressed: () {
                    openImage(imageurl ?? ImagesUrl.profileImage);
                  },
                  child: CircleAvatar(
                    backgroundColor: MyColors.primary,
                    maxRadius: 45,
                    backgroundImage: imageurl == null
                        ? const AssetImage(ImagesUrl.profileImage)
                        : NetworkImage(imageurl!) as ImageProvider,
                  ),
                ),
        ),
        const ProfileVerificationIcon(),
        SizedBox(width: 15.w),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: MyColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
