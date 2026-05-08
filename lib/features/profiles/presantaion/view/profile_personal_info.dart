import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_state_section.dart';

class ProfilePersonalInfoScreen extends StatelessWidget {
  const ProfilePersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileEntity? profile = Get.arguments as ProfileEntity?;

    if (profile == null) {
      return Scaffold(
        appBar: _appBar(),
        body: const Center(child: Text("تعذّر تحميل البيانات")),
      );
    }

    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: _appBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ━━ Header: صورة + اسم + شارة التوثيق ━━
            _Header(profile: profile),

            SizedBox(height: 16.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  // ━━ المعلومات الشخصية ━━
                  _InfoCard(profile: profile),

                  SizedBox(height: 16.h),

                  // ━━ التقييم ━━
                  _RatingCard(profile: profile),

                  SizedBox(height: 16.h),

                  // ━━ إحصائيات الرحلات والحجوزات ━━
                  ProfileStatsSection(profile: profile),

                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      backgroundColor: MyColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_forward_ios_rounded,
            color: MyColors.primary, size: 20),
        onPressed: () => Get.back(),
      ),
      title: Text("المعلومات الشخصية", style: AppTextStyles.titleMedium),
      centerTitle: true,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Header
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _Header extends StatelessWidget {
  final ProfileEntity profile;
  const _Header({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: MyColors.surface,
      padding: EdgeInsets.symmetric(vertical: 28.h),
      child: Column(
        children: [
          // ━━ الصورة ━━
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: MyColors.primary.withValues(alpha: 0.15),
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  radius: 55.r,
                  backgroundColor: MyColors.background,
                  backgroundImage: profile.profilePhoto != null
                      ? NetworkImage(profile.profilePhoto!) as ImageProvider
                      : const AssetImage(ImagesUrl.profileImage),
                ),
              ),
              if (profile.verification == 'verified')
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: MyColors.success,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: MyColors.surface, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 11, color: Colors.white),
                        SizedBox(width: 3.w),
                        Text(
                          "موثق",
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 14.h),

          // ━━ الاسم ━━
          Text(profile.fullname, style: AppTextStyles.titleLarge),

          SizedBox(height: 6.h),

          // ━━ التقييم المختصر ━━
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded,
                  color: MyColors.accent, size: 18),
              SizedBox(width: 4.w),
              Text(
                profile.averageRating.toStringAsFixed(1),
                style: AppTextStyles.labelLarge
                    .copyWith(color: MyColors.textPrimary),
              ),
              SizedBox(width: 4.w),
              Text(
                "(${profile.totalRating} تقييم)",
                style: AppTextStyles.labelSmall
                    .copyWith(color: MyColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Info Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _InfoCard extends StatelessWidget {
  final ProfileEntity profile;
  const _InfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final genderLabel = _genderLabel(profile.gender);
    final genderIcon = profile.gender.toLowerCase() == 'female'
        ? Icons.female_rounded
        : Icons.male_rounded;

    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: MyColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: "الاسم الكامل",
            value: profile.fullname,
          ),
          _divider(),
          _InfoRow(
            icon: genderIcon,
            label: "الجنس",
            value: genderLabel,
          ),
          _divider(),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: "العنوان",
            value: profile.address.isNotEmpty
                ? profile.address
                : "لم يُحدَّد بعد",
          ),
          if (profile.description.isNotEmpty) ...[
            _divider(),
            _InfoRow(
              icon: Icons.info_outline_rounded,
              label: "نبذة عني",
              value: profile.description,
              multiLine: true,
            ),
          ],
        ],
      ),
    );
  }

  String _genderLabel(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'm':
        return 'ذكر';
      case 'female':
      case 'f':
        return 'أنثى';
      default:
        return gender;
    }
  }

  Widget _divider() => const Divider(
        height: 0,
        thickness: 0.5,
        indent: 16,
        endIndent: 16,
      );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Info Row
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiLine;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        crossAxisAlignment: multiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          // ━━ القيمة ━━
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.bodyMedium,
                  maxLines: multiLine ? null : 1,
                  overflow: multiLine ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // ━━ العنوان + الأيقونة ━━
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: MyColors.textSecondary),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: MyColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(icon, color: MyColors.primary, size: 17),
                  ),
                ],
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
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ━━ عنوان ━━
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: MyColors.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star_outline_rounded,
                    color: MyColors.accent, size: 17),
              ),
              SizedBox(width: 8.w),
              Text("معدل المواطبة", style: AppTextStyles.labelLarge),
            ],
          ),

          SizedBox(height: 14.h),

          const Divider(height: 0, thickness: 0.5),

          SizedBox(height: 14.h),

          // ━━ الرقم + الشريط ━━
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // الرقم الكبير
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    profile.averageRating.toStringAsFixed(1),
                    style: AppTextStyles.displayLarge.copyWith(
                      color: MyColors.primary,
                      fontSize: 42.sp,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h, right: 4.w),
                    child: Text("/ 5",
                        style: AppTextStyles.bodySmall
                            .copyWith(color: MyColors.textSecondary)),
                  ),
                ],
              ),

              const Spacer(),

              // Bar chart
              _MiniBarChart(average: profile.averageRating),
            ],
          ),

          SizedBox(height: 8.h),

          Text(
            "بناءً على ${profile.totalRating} تقييم",
            style: AppTextStyles.labelSmall
                .copyWith(color: MyColors.textSecondary),
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
