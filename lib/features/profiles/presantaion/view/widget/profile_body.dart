import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is! ProfileLoadedState) {
          return const Scaffold(
            body: Center(child: LoadingWidgetSize150()),
          );
        }

        final profile = state.profileEntity!;
        final isMyProfile = state.mode != ProfileMode.otherView;

        return Scaffold(
          backgroundColor: MyColors.background,
          appBar: _buildAppBar(isMyProfile, profile),
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // ━━ Header: صورة + اسم + شارة التوثيق ━━
                _ProfileHeader(profile: profile),

                SizedBox(height: 16.h),

                // ━━ بطاقة التقييم ━━
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _RatingCard(profile: profile),
                ),

                SizedBox(height: 16.h),

                // ━━ قائمة الخيارات ━━
                if (isMyProfile) _MenuSection(profile: profile),

                SizedBox(height: 32.h),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(bool isMyProfile, ProfileEntity profile) {
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
      title: Text("الملف الشخصي", style: AppTextStyles.titleMedium),
      centerTitle: true,
      actions: [
        if (isMyProfile)
          TextButton(
            onPressed: () => Get.toNamed(RouteName.profilePersonalInfo, arguments: profile),
            child: Text(
              "عدّل بياناتك",
              style: AppTextStyles.labelMedium.copyWith(color: MyColors.accent),
            ),
          ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Profile Header
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _ProfileHeader extends StatelessWidget {
  final ProfileEntity profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: MyColors.surface,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
      child: Row(
        children: [
          // ━━ الاسم والعنوان ━━
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.fullname, style: AppTextStyles.titleLarge),
                SizedBox(height: 4.h),
                if (profile.address.isNotEmpty)
                  Text(
                    profile.address,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: MyColors.textSecondary),
                  ),
              ],
            ),
          ),

          SizedBox(width: 16.w),

          // ━━ الصورة مع شارة التوثيق ━━
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: MyColors.primary.withValues(alpha: 0.15),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 38.r,
                  backgroundColor: MyColors.background,
                  backgroundImage: profile.profilePhoto != null
                      ? NetworkImage(profile.profilePhoto!) as ImageProvider
                      : const AssetImage(ImagesUrl.profileImage),
                ),
              ),
              if (profile.verification == 'verified')
                Positioned(
                  bottom: 2,
                  left: 0,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: MyColors.success,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: MyColors.surface, width: 1.5),
                    ),
                    child: Text(
                      "موثق",
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 9.sp,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
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
              Text("معدل المواطبة", style: AppTextStyles.labelSmall),
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
                    child: Text("/ 5", style: AppTextStyles.bodySmall),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // ━━ Bar Chart ━━
          _MiniBarChart(average: profile.averageRating),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Mini Bar Chart
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _MiniBarChart extends StatelessWidget {
  final double average;
  const _MiniBarChart({required this.average});

  @override
  Widget build(BuildContext context) {
    final bars = [0.3, 0.5, 0.4, 0.7, (average / 5).clamp(0.1, 1.0)];
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
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Menu Section
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _MenuSection extends StatelessWidget {
  final ProfileEntity profile;
  const _MenuSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isVerified = profile.verification == 'verified';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // ━━ بطاقة القائمة ━━
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
                  onTap: () => Get.toNamed(RouteName.profilePersonalInfo, arguments: profile),
                ),
                _divider(),
                _MenuItem(
                  icon: Icons.directions_car_outlined,
                  label: "مركباتي",
                  onTap: () => Get.toNamed(RouteName.profileMyCars),
                ),
                _divider(),
                _MenuItem(
                  icon: Icons.verified_outlined,
                  label: "توثيق السائق",
                  badge: isVerified ? "مكتمل" : null,
                  onTap: () =>
                      Get.toNamed(RouteName.profileDriverVerification),
                ),
                _divider(),
                _MenuItem(
                  icon: Icons.settings_outlined,
                  label: "الإعدادات",
                  onTap: () => Get.toNamed(RouteName.profileSettings),
                ),
                _divider(),
                _MenuItem(
                  icon: Icons.support_agent_outlined,
                  label: "الدعم الفني",
                  onTap: () => Get.toNamed(RouteName.profileSupport),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // ━━ زر تسجيل الخروج ━━
          _LogoutButton(),
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
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: MyColors.accentLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: MyColors.accent),
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

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Logout Button
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: clear session + navigate to login
        // HiveService.clearAll();
        // Get.offAllNamed(RouteName.login);
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
            const Icon(Icons.logout_rounded, color: MyColors.error, size: 20),
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
    );
  }
}
