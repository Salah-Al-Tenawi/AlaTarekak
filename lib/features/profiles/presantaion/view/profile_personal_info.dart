import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/utils/functions/show_image.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_comments.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_state_section.dart';

class ProfilePersonalInfoScreen extends StatelessWidget {
  const ProfilePersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileEntity? profile = Get.arguments as ProfileEntity?;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: MyColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded,
                color: MyColors.primary, size: 20),
            onPressed: () => Get.back(),
          ),
          title: Text("المعلومات الشخصية", style: AppTextStyles.titleMedium),
          centerTitle: true,
        ),
        body: const Center(child: Text("تعذّر تحميل البيانات")),
      );
    }

    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: _appBar(profile),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ━━ Header: صورة + اسم + تقييم ━━
            _Header(profile: profile),

            SizedBox(height: 16.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  // ━━ التقييم ━━
                  _RatingCard(profile: profile),

                  SizedBox(height: 16.h),

                  // ━━ نبذة عني ━━
                  _BioCard(bio: profile.description),

                  SizedBox(height: 16.h),

                  // ━━ حالة الحساب والدرجة ━━
                  _AccountStatusCard(profile: profile),

                  SizedBox(height: 16.h),

                  // ━━ المعلومات الشخصية ━━
                  _InfoCard(profile: profile),

                  SizedBox(height: 16.h),

                  // ━━ إحصائيات الرحلات والحجوزات ━━
                  ProfileStatsSection(profile: profile),

                  SizedBox(height: 16.h),

                  // ━━ آراء المستخدمين ━━
                  _CommentsCard(profile: profile),

                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _appBar(ProfileEntity profile) {
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
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined,
              color: MyColors.primary, size: 22),
          tooltip: 'تعديل',
          onPressed: () async {
            final result = await Get.toNamed(
              RouteName.updateprofile,
              arguments: profile,
            );
            if (result == true) Get.back(result: true);
          },
        ),
      ],
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
          GestureDetector(
            onTap: () => openImage(
                profile.profilePhoto ?? ImagesUrl.profileImage),
            child: Stack(
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
              if (profile.verification == 'approved')
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: MyColors.success,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: MyColors.surface, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 11, color: Colors.white),
                        SizedBox(width: 3.w),
                        Text(
                          "موثَّق",
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
          ),

          SizedBox(height: 14.h),

          // ━━ الاسم ━━
          Text(profile.fullname, style: AppTextStyles.titleLarge),

          SizedBox(height: 6.h),

          // ━━ التقييم المختصر ━━
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: MyColors.accent, size: 18),
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
// Account Status Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _AccountStatusCard extends StatelessWidget {
  final ProfileEntity profile;
  const _AccountStatusCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _VerificationTile(status: profile.verification),
            ),
            Container(
              width: 1,
              margin: EdgeInsets.symmetric(vertical: 12.h),
              color: MyColors.border,
            ),
            Expanded(
              child: _ScoreTile(
                score: profile.scoreValue,
                tier: profile.tier,
                canCreate: profile.canCreateRides,
                canBook: profile.canBookRides,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Verification Tile
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _VerificationTile extends StatelessWidget {
  final String status;
  const _VerificationTile({required this.status});

  _StatusConfig get _config {
    switch (status) {
      case 'approved':
        return _StatusConfig(
          label: 'موثَّق',
          icon: Icons.verified_rounded,
          color: MyColors.success,
          bg: MyColors.successLight,
        );
      case 'pending':
        return _StatusConfig(
          label: 'قيد المراجعة',
          icon: Icons.hourglass_empty_rounded,
          color: MyColors.warning,
          bg: MyColors.warningLight,
        );
      case 'rejected':
        return _StatusConfig(
          label: 'مرفوض',
          icon: Icons.cancel_rounded,
          color: MyColors.error,
          bg: MyColors.errorLight,
        );
      default:
        return _StatusConfig(
          label: 'غير موثَّق',
          icon: Icons.person_outline_rounded,
          color: MyColors.textHint,
          bg: MyColors.background,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    return Padding(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // start = يمين في RTL
        children: [
          Text(
            'حالة التوثيق',
            style: AppTextStyles.labelSmall.copyWith(color: MyColors.textHint),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: cfg.bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cfg.icon, color: cfg.color, size: 14),
                SizedBox(width: 4.w),
                Text(
                  cfg.label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: cfg.color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Score Tile
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _ScoreTile extends StatelessWidget {
  final int score;
  final String tier;
  final bool canCreate;
  final bool canBook;
  const _ScoreTile({
    required this.score,
    required this.tier,
    required this.canCreate,
    required this.canBook,
  });

  _StatusConfig get _config {
    switch (tier) {
      case 'Gold':
        return _StatusConfig(
          label: 'ذهبي',
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFFB8860B),
          bg: const Color(0xFFFFF8DC),
        );
      case 'Silver':
        return _StatusConfig(
          label: 'فضي',
          icon: Icons.shield_rounded,
          color: const Color(0xFF546E7A),
          bg: const Color(0xFFECEFF1),
        );
      case 'Bronze':
        return _StatusConfig(
          label: 'برونزي',
          icon: Icons.military_tech_rounded,
          color: const Color(0xFF8D6E63),
          bg: const Color(0xFFEFEBE9),
        );
      default:
        return _StatusConfig(
          label: 'محظور',
          icon: Icons.block_rounded,
          color: MyColors.error,
          bg: MyColors.errorLight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    return Padding(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // start = يمين في RTL
        children: [
          Text(
            'درجة النشاط',
            style: AppTextStyles.labelSmall.copyWith(color: MyColors.textHint),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.start, // start = يمين في RTL
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: cfg.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cfg.icon, color: cfg.color, size: 14),
                    SizedBox(width: 4.w),
                    Text(
                      cfg.label,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: cfg.color, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                '$score/100',
                style: AppTextStyles.labelSmall
                    .copyWith(color: MyColors.textSecondary),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.start, // start = يمين في RTL
            children: [
              _PermissionDot(label: 'نشر رحلة', allowed: canCreate),
              SizedBox(width: 10.w),
              _PermissionDot(label: 'حجز', allowed: canBook),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionDot extends StatelessWidget {
  final String label;
  final bool allowed;
  const _PermissionDot({required this.label, required this.allowed});

  @override
  Widget build(BuildContext context) {
    final color = allowed ? MyColors.success : MyColors.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: MyColors.textSecondary,
            fontSize: 10.sp,
          ),
        ),
        SizedBox(width: 3.w),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatusConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });
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
    final genderIcon = profile.gender.toLowerCase() == 'f' ||
            profile.gender.toLowerCase() == 'female'
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
            icon: genderIcon,
            label: "الجنس",
            value: genderLabel,
          ),
          _divider(),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: "العنوان",
            value: profile.address.isNotEmpty ? profile.address : "لم يُحدَّد بعد",
          ),
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
// Bio Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _BioCard extends StatelessWidget {
  final String bio;
  const _BioCard({required this.bio});

  @override
  Widget build(BuildContext context) {
    final isEmpty = bio.isEmpty;
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: MyColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: MyColors.primary, size: 17),
              ),
              SizedBox(width: 8.w),
              Text("نبذة عني", style: AppTextStyles.labelLarge),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(height: 0, thickness: 0.5),
          SizedBox(height: 12.h),
          Text(
            isEmpty ? "لم تُضَف نبذة بعد" : bio,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isEmpty ? MyColors.textHint : MyColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Info Row
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: MyColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: MyColors.primary, size: 17),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: AppTextStyles.labelSmall
                .copyWith(color: MyColors.textSecondary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
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
              Text("معدل التقييم", style: AppTextStyles.labelLarge),
            ],
          ),

          SizedBox(height: 14.h),

          const Divider(height: 0, thickness: 0.5),

          SizedBox(height: 14.h),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
              _MiniBarChart(average: profile.averageRating),
            ],
          ),

          SizedBox(height: 8.h),

          Text(
            "بناءً على ${profile.totalRating} تقييم",
            style:
                AppTextStyles.labelSmall.copyWith(color: MyColors.textSecondary),
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

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Comments Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _CommentsCard extends StatelessWidget {
  final ProfileEntity profile;
  const _CommentsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final comments = profile.comments ?? [];
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // start = يمين في RTL
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: MyColors.accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded,
                      color: MyColors.accent, size: 17),
                ),
                SizedBox(width: 8.w),
                Text('آراء المستخدمين', style: AppTextStyles.labelLarge),
              ],
            ),
          ),
          const Divider(height: 0, thickness: 0.5),
          if (comments.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: Text(
                  'لا توجد تعليقات بعد',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: MyColors.textHint),
                ),
              ),
            )
          else
            ProfileComments(feadBack: comments),
        ],
      ),
    );
  }
}