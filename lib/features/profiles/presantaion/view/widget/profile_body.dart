import 'dart:io';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_state_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/profiles/data/model/enum/image_mode.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileErrorState) {
          AppSnackBar.error("context, state.message");
        }
      },
      builder: (context, state) {
        if (state is! ProfileLoadedState) {
          return const Scaffold(
            body: Center(child: LoadingWidgetSize150()),
          );
        }

        final profile = state.profileEntity!;
        final mode = state.mode;
        final isMyProfile = mode != ProfileMode.otherView;

        return Scaffold(
          backgroundColor: MyColors.background,
          appBar: _buildAppBar(context, state, isMyProfile),
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [

                // ━━ Header Card ━━
                // ProfileHeaderCard(
                //   profile: profile,
                //   state: state,
                //   isMyProfile: isMyProfile,
                // ),

                SizedBox(height: 16.h),

                // ━━ Rating ━━
                _RatingCard(profile: profile),

                SizedBox(height: 16.h),

                // ━━ إحصائيات الرحلات والحجوزات ━━
                if (isMyProfile)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: ProfileStatsSection(profile: profile),
                  ),

                SizedBox(height: 16.h),

                // ━━ قائمة الخيارات ━━
                if (isMyProfile)
                  _MenuSection(mode: mode)
                else
                  // _OtherProfileSection(profile: profile),

                SizedBox(height: 24.h),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    ProfileLoadedState state,
    bool isMyProfile,
  ) {
    return AppBar(
      backgroundColor: MyColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: MyColors.primary,
          size: 20,
        ),
        onPressed: () => Get.back(),
      ),
      title: Text(
        "الملف الشخصي",
        style: AppTextStyles.titleMedium,
      ),
      centerTitle: true,
      actions: [
        if (isMyProfile)
          _EditSaveButton(state: state),
      ],
    );
  }
}
// ━━━━━━━━━━━━━━━━━━━━━━━━
// AppBar Edit/Save Button
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _EditSaveButton extends StatelessWidget {
  final ProfileLoadedState state;
  const _EditSaveButton({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.mode == ProfileMode.myEdit) {
      return TextButton(
        onPressed: () => context.read<ProfileCubit>().saveMyProfile(),
        child: Text(
          "حفظ",
          style: AppTextStyles.labelLarge.copyWith(color: MyColors.accent),
        ),
      );
    }
    return TextButton(
      onPressed: () => context.read<ProfileCubit>().enterEditMode(),
      child: Text("تعديل", style: AppTextStyles.labelLarge),
    );
  }
}
// ━━━━━━━━━━━━━━━━━━━━━━━━
// Rating Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _RatingCard extends StatelessWidget {
  final ProfileEntity profile;
  const _RatingCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: MyColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ━━ الرقم ━━
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "معدل المواطبة",
                style: AppTextStyles.labelSmall,
              ),
              SizedBox(height: 4.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    profile.averageRating.toStringAsFixed(1),
                    style: AppTextStyles.displayLarge.copyWith(
                      color: MyColors.primary,
                      fontSize: 36,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h, right: 4.w),
                    child: Text(
                      "/ 5",
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // ━━ Bar Chart ━━
          _MiniBarChart(
            totalRating: profile.totalRating,
            average: profile.averageRating,
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Mini Bar Chart
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _MiniBarChart extends StatelessWidget {
  final int totalRating;
  final double average;

  const _MiniBarChart({required this.totalRating, required this.average});

  @override
  Widget build(BuildContext context) {
    // 5 أعمدة تمثل التقييمات 1-5
    final bars = [0.3, 0.5, 0.4, 0.7, average / 5];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(bars.length, (i) {
        final isActive = i == bars.length - 1;
        return Container(
          margin: EdgeInsets.only(right: 4.w),
          width: 16.w,
          height: (60 * bars[i]).h,
          decoration: BoxDecoration(
            color: isActive ? MyColors.primary : MyColors.surfaceAlt,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}// ━━━━━━━━━━━━━━━━━━━━━━━━
// Menu Section (myProfile)
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _MenuSection extends StatelessWidget {
  final ProfileMode mode;
  const _MenuSection({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [

          // ━━ قائمة الخيارات ━━
          Container(
            decoration: BoxDecoration(
              color: MyColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: MyColors.shadowLight,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: "المعلومات الشخصية",
                  onTap: () => Get.toNamed(RouteName.login),
                ),
                _divider(),
                _MenuItem(
                  icon: Icons.directions_car_outlined,
                  label: "مركباتي",
                  onTap: () => Get.toNamed(RouteName.login),
                ),
                _divider(),
                _MenuItem(
                  icon: Icons.verified_outlined,
                  label: "توثيق السائق",
                  badge: "مكتمل",
                  onTap: () => Get.toNamed(RouteName.login),
                ),
                _divider(),
                _MenuItem(
                  icon: Icons.settings_outlined,
                  label: "الإعدادات",
                  onTap: () => Get.toNamed(RouteName.login),
                ),
                _divider(),
                _MenuItem(
                  icon: Icons.support_agent_outlined,
                  label: "الدعم الفني",
                  onTap: () => Get.toNamed(RouteName.login),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // ━━ زر تسجيل الخروج ━━
          GestureDetector(
            onTap: () {
              // TODO: context.read<AuthCubit>().logout()
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: MyColors.errorLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: MyColors.error,
                    size: 20,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "تسجيل الخروج",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: MyColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 0,
        thickness: 0.5,
        indent: 16,
        endIndent: 16,
      );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Menu Item
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [

            // ━━ سهم ━━
            const Icon(
              Icons.arrow_back_ios_rounded,
              size: 14,
              color: MyColors.textHint,
            ),

            const Spacer(),

            // ━━ badge ━━
            if (badge != null) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: MyColors.accentLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: MyColors.accent,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],

            // ━━ العنوان ━━
            Text(label, style: AppTextStyles.bodyMedium),

            SizedBox(width: 12.w),

            // ━━ الأيقونة ━━
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: MyColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: MyColors.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}