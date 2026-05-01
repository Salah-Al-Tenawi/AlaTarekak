import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_car.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_comments.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_contact_me.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_hintline.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_image_and_name.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_rating.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_save_and_edit_buttons.dart';

class ProfileBody extends StatefulWidget {
  final ProfileEntity profileEntity;

  const ProfileBody({super.key, required this.profileEntity});

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  TextEditingController? controllerEditAboutMe;
  ProfileEntity? _profileCopyWithforEdit;

  void _initEditState(ProfileEntity profile) {
    if (_profileCopyWithforEdit == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _profileCopyWithforEdit = profile.copyWith();
        });

        controllerEditAboutMe =
            TextEditingController(text: profile.description);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is! ProfileLoadedState) {
          return const Center(child: LoadingWidgetSize150());
        }

        final mode = state.mode;
        final profile = state.profileEntity!;
        final isEdit = mode == ProfileMode.myEdit;

        if (isEdit) {
          _initEditState(profile);
        }

        final displayCar = _profileCopyWithforEdit?.car ?? profile.car;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: MyColors.primary,
            actions: [
              if (mode == ProfileMode.myView || mode == ProfileMode.myEdit)
                ProfileSaveAndEditButtons(
                  profileEntityWithEdit: _profileCopyWithforEdit,
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileImageAndName(
                      verification: profile.verification,
                      name: profile.fullname,
                      imageurl: profile.profilePhoto,
                      profileEntitYEdit:
                          isEdit ? _profileCopyWithforEdit : null,
                      mode: mode,
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ProfileRating(
                          totalRating: profile.totalRating,
                          averageRating: profile.averageRating,
                          tripsCount: profile.numberOfides,
                        ),
                        Text("العنوان  :${profile.address}",
                            style: AppTextStyles.bodyMedium ,),
                        const ProfileContactMe(),
                      ],
                    ),
                    ProfileHintline(
                      hintLine: profile.description,
                      controllerAboutme: controllerEditAboutMe,
                      mode: mode,
                      onDescriptionChanged: (value) {
                        setState(() {
                          _profileCopyWithforEdit = _profileCopyWithforEdit
                              ?.copyWith(description: value);
                        });
                      },
                    ),
                    ProfileCar(
                      car: displayCar,
                      carWitheidt: _profileCopyWithforEdit?.car,
                      mode: mode,
                      onCarChanged: (newCar) {
                        setState(() {
                          if (_profileCopyWithforEdit != null) {
                            _profileCopyWithforEdit =
                                _profileCopyWithforEdit!.copyWith(car: newCar);
                          } else {
                            _profileCopyWithforEdit =
                                profile.copyWith(car: newCar);
                          }
                        });
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.h),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Icon(Icons.comment_outlined),
                          Text("آراء الناس بي", style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    ProfileComments(
                      feadBack: profile.comments,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    controllerEditAboutMe?.dispose();
    super.dispose();
  }
}
