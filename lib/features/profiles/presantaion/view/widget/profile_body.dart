import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/chat_socket_service.dart';
import 'package:alatarekak/core/service/locator_ser.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/app_dialog.dart';
import 'package:alatarekak/core/utils/functions/show_image.dart';
import 'package:alatarekak/features/score/domain/entity/score_entity.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/features/profiles/domain/entity/car_entity.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_comments.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/verification_type_sheet.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_erorr.dart';

class ProfileBody extends StatelessWidget {
  final VoidCallback onRefresh;
  const ProfileBody({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is ProfileInitialState || state is ProfileLoadingState) {
          return const Scaffold(
            body: Center(child: AppLoader()),
          );
        }

        if (state is ProfileErrorState) {
          return Scaffold(
            body: ProfileErrorWidget(
              onRetry: onRefresh,
              errorMessage: state.message,
            ),
          );
        }

        final loaded = state as ProfileLoadedState;
        final profile = loaded.profileEntity!;
        final isMyProfile = loaded.mode != ProfileMode.otherView;

        return Scaffold(
          backgroundColor: MyColors.background,
          appBar: _buildAppBar(isMyProfile, profile),
          body: isMyProfile
              ? _MyProfileView(profile: profile, onRefresh: onRefresh)
              : _OtherProfileView(profile: profile, onRefresh: onRefresh),
        );
      },
    );
  }

  AppBar _buildAppBar(bool isMyProfile, ProfileEntity profile) {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      // My profile is a bottom-nav tab (no back); other profiles are
      // pushed as a route and need one.
      leading: isMyProfile
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              onPressed: () => Get.back(),
            ),
      title: Text(
        isMyProfile ? "حسابي" : "الملف الشخصي",
        style: AppTextStyles.titleMedium.copyWith(color: MyColors.textOnDark),
      ),
      centerTitle: true,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MY PROFILE VIEW  (dashboard / settings)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _MyProfileView extends StatelessWidget {
  final ProfileEntity profile;
  final VoidCallback onRefresh;
  const _MyProfileView({required this.profile, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // ━━ Header مضغوط: صورة + اسم + شارات ━━
          _MyProfileHeader(profile: profile),

          SizedBox(height: 16.h),

          // ━━ إحصائيات سريعة ━━
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _QuickStatsRow(profile: profile),
          ),

          SizedBox(height: 16.h),

          // ━━ قائمة التنقل ━━
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _MenuCard(profile: profile),
          ),

          SizedBox(height: 16.h),

          // ━━ تسجيل الخروج ━━
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: const _LogoutButton(),
          ),

          SizedBox(height: 32.h),
        ],
      ),
    ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// My Profile Header
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _MyProfileHeader extends StatelessWidget {
  final ProfileEntity profile;
  const _MyProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final verCfg = _verificationConfig(profile.verification);
    final tierCfg = _tierConfig(profile.tier);

    return Container(
      width: double.infinity,
      color: MyColors.surface,
      padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 24.h),
      child: Column(
        children: [
          // ━━ الصورة الكبيرة ━━
          GestureDetector(
            onTap: () => openImage(
                profile.profilePhoto ?? ImagesUrl.profileImage),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
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
                    radius: 50.r,
                    backgroundColor: MyColors.background,
                    backgroundImage: profile.profilePhoto != null
                        ? NetworkImage(profile.profilePhoto!) as ImageProvider
                        : const AssetImage(ImagesUrl.profileImage),
                  ),
                ),
                if (profile.verification == 'approved')
                  Positioned(
                    bottom: 2,
                    left: 0,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: MyColors.success,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: MyColors.surface, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              size: 10, color: Colors.white),
                          SizedBox(width: 2.w),
                          Text("موثَّق",
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white, fontSize: 9.sp)),
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

          if (profile.address.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 13, color: MyColors.textHint),
                SizedBox(width: 2.w),
                Text(profile.address,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: MyColors.textSecondary)),
              ],
            ),
          ],

          SizedBox(height: 14.h),

          // ━━ شارتا التوثيق والدرجة جنباً لجنب ━━
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // التوثيق
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: verCfg.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(verCfg.icon, size: 13, color: verCfg.color),
                    SizedBox(width: 4.w),
                    Text(verCfg.label,
                        style: AppTextStyles.labelSmall.copyWith(
                            color: verCfg.color,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // الدرجة
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: tierCfg.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tierCfg.icon, size: 13, color: tierCfg.color),
                    SizedBox(width: 4.w),
                    Text('${tierCfg.label} • ${profile.scoreValue}/100',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: tierCfg.color,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _BadgeConfig _verificationConfig(String status) {
    switch (status) {
      case 'approved':
        return _BadgeConfig('موثَّق', Icons.verified_rounded,
            MyColors.success, MyColors.successLight);
      case 'pending':
        return _BadgeConfig('قيد المراجعة', Icons.hourglass_empty_rounded,
            MyColors.warning, MyColors.warningLight);
      case 'rejected':
        return _BadgeConfig(
            'مرفوض', Icons.cancel_rounded, MyColors.error, MyColors.errorLight);
      default:
        return _BadgeConfig('غير موثَّق', Icons.person_outline_rounded,
            MyColors.textHint, MyColors.background);
    }
  }

  _BadgeConfig _tierConfig(String tier) {
    switch (tier) {
      case 'Gold':
        return _BadgeConfig('ذهبي', Icons.workspace_premium_rounded,
            const Color(0xFFB8860B), const Color(0xFFFFF8DC));
      case 'Silver':
        return _BadgeConfig('فضي', Icons.shield_rounded,
            const Color(0xFF546E7A), const Color(0xFFECEFF1));
      case 'Bronze':
        return _BadgeConfig('برونزي', Icons.military_tech_rounded,
            const Color(0xFF8D6E63), const Color(0xFFEFEBE9));
      default:
        return _BadgeConfig(
            'محظور', Icons.block_rounded, MyColors.error, MyColors.errorLight);
    }
  }
}

class _BadgeConfig {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const _BadgeConfig(this.label, this.icon, this.color, this.bg);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Quick Stats Row
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _QuickStatsRow extends StatelessWidget {
  final ProfileEntity profile;
  _QuickStatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: MyColors.shadowLight, blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                icon: Icons.directions_car_rounded,
                value: profile.totalTrips.toString(),
                // ثلاث خلايا في صفّ واحد على شاشة هاتف: «رحلات كسائق»
                // تضيق بها فتُقصّ أو تلتفّ. والرقم فوقها يقول «رحلات».
                label: 'ك سائق',
                iconColor: MyColors.primary,
              ),
            ),
            _vDivider(),
            Expanded(
              child: _StatCell(
                icon: Icons.event_seat_rounded,
                value: profile.totalBookings.toString(),
                label: 'ك راكب',
                iconColor: MyColors.accent,
              ),
            ),
            _vDivider(),
            Expanded(
              child: _StatCell(
                icon: Icons.star_rounded,
                value: profile.averageRating.toStringAsFixed(1),
                label: 'التقييم',
                iconColor: MyColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        margin: EdgeInsets.symmetric(vertical: 12.h),
        color: MyColors.border,
      );
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          SizedBox(height: 6.h),
          Text(value,
              style: AppTextStyles.titleMedium
                  .copyWith(color: MyColors.textPrimary, fontSize: 18.sp)),
          SizedBox(height: 2.h),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Menu Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _MenuCard extends StatelessWidget {
  final ProfileEntity profile;
  _MenuCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isVerified = profile.verification == 'approved';
    final verBadge = _verBadgeText(profile.verification);

    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: MyColors.shadowLight, blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.person_outline_rounded,
            label: "المعلومات الشخصية",
            onTap: () async {
              final result = await Get.toNamed(
                RouteName.profilePersonalInfo,
                arguments: profile,
              );
              if (result == true && context.mounted) {
                context.read<ProfileCubit>().showMyProfile();
              }
            },
          ),
          _divider(),
          _MenuItem(
            icon: Icons.account_balance_wallet_outlined,
            label: "محفظتي",
            onTap: () => Get.toNamed(RouteName.wallet),
          ),
          _divider(),
          _MenuItem(
            icon: Icons.directions_car_outlined,
            label: "مركباتي",
            onTap: () async {
              await Get.toNamed(
                RouteName.profileMyCars,
                arguments: profile,
              );
              if (context.mounted) {
                context.read<ProfileCubit>().showMyProfile();
              }
            },
          ),
          _divider(),
          // نقاط الثقة — الشارة تعرض الرقم الواصل من /profile، والشاشة
          // تجلبه من /score مع سجلّ الحركة
          _MenuItem(
            icon: Icons.shield_outlined,
            label: "نقاط الثقة",
            badge: '${profile.scoreValue}',
            badgeColor: _scoreBadgeColor(profile.scoreValue),
            onTap: () => Get.toNamed(RouteName.profileScore),
          ),
          _divider(),
          _MenuItem(
            icon: Icons.verified_outlined,
            label: "توثيق الهوية",
            badge: verBadge,
            badgeColor: isVerified ? MyColors.success : null,
            onTap: () => _onVerificationTap(context),
          ),
          _divider(),
          _MenuItem(
            icon: Icons.settings_outlined,
            label: "الإعدادات",
            onTap: () => Get.toNamed(RouteName.profileSettings),
          ),
          _divider(),
          _MenuItem(
            icon: Icons.help_outline_rounded,
            label: "مركز المساعدة",
            onTap: () => Get.toNamed(RouteName.profileSupport),
          ),
          _divider(),
          _MenuItem(
            icon: Icons.list_alt_rounded,
            label: "الشكاوي الخاصة بي",
            onTap: () => Get.toNamed(RouteName.complaintList),
          ),
          _divider(),
          _MenuItem(
            icon: Icons.report_problem_outlined,
            label: "تقديم شكوى",
            onTap: () => Get.toNamed(RouteName.profileComplaint),
          ),
          _divider(),
          _MenuItem(
            icon: Icons.headset_mic_outlined,
            label: "تواصل مع الدعم",
            onTap: () => Get.toNamed(RouteName.profileContactUs),
          ),
          _divider(),
          // من وافق على السياسة عند التسجيل يجب أن يستطيع مراجعتها لاحقاً
          _MenuItem(
            icon: Icons.privacy_tip_outlined,
            label: "سياسة الخصوصية",
            onTap: () => Get.toNamed(RouteName.policy, arguments: 0),
          ),
        ],
      ),
    );
  }

  /// لون شارة النقاط بحدّي العمل: 50 للإنشاء و40 للحجز.
  Color _scoreBadgeColor(int score) {
    if (score >= ScoreEntity.minScoreToCreate) return MyColors.success;
    if (score >= ScoreEntity.minScoreToBook) return MyColors.warning;
    return MyColors.error;
  }

  String? _verBadgeText(String status) {
    switch (status) {
      case 'approved':
        return 'مكتمل';
      case 'pending':
        return 'قيد المراجعة';
      case 'rejected':
        return 'مرفوض';
      default:
        return null;
    }
  }

  void _onVerificationTap(BuildContext context) {
    final status = profile.verification;
    if (status == 'none') {
      VerificationTypeSheet.show(context);
      return;
    }
    final docs = profile.documents;
    // ترجيح لا قفل: شاشة الحالة تعرضه مُبرزاً وتُبقي الخيار الآخر متاحاً
    final isDriver =
        docs?.licensePic != null || docs?.mechanicCardPic != null;
    Get.toNamed(
      RouteName.profileDriverVerification,
      arguments: {
        'status': status,
        'userType': isDriver ? 'driver' : 'passenger',
        'documents': docs,
      },
    );
  }

  Widget _divider() =>
      const Divider(height: 0, thickness: 0.5, indent: 16, endIndent: 16);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// OTHER PROFILE VIEW  (full public profile)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _OtherProfileView extends StatelessWidget {
  final ProfileEntity profile;
  final VoidCallback onRefresh;
  const _OtherProfileView({required this.profile, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // ━━ Header: صورة + اسم + بيو ━━
            _PublicHeader(profile: profile),

            SizedBox(height: 16.h),

            // ━━ حالة الحساب والدرجة ━━
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _AccountStatusCard(profile: profile),
            ),

            SizedBox(height: 16.h),

            // ━━ التقييم ━━
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _RatingCard(profile: profile),
            ),

            SizedBox(height: 16.h),

            // ━━ السيارة ━━
            if (profile.car != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _CarCard(car: profile.car!),
              ),
              SizedBox(height: 16.h),
            ],

            // ━━ التعليقات ━━
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _CommentsSection(profile: profile),
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Public Header (otherView)
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _PublicHeader extends StatelessWidget {
  final ProfileEntity profile;
  const _PublicHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasBio = profile.description.isNotEmpty;

    return Container(
      width: double.infinity,
      color: MyColors.surface,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => openImage(
                    profile.profilePhoto ?? ImagesUrl.profileImage),
                child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: MyColors.primary.withValues(alpha: 0.15),
                          width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 38.r,
                      backgroundColor: MyColors.background,
                      backgroundImage: profile.profilePhoto != null
                          ? NetworkImage(profile.profilePhoto!) as ImageProvider
                          : const AssetImage(ImagesUrl.profileImage),
                    ),
                  ),
                  if (profile.verification == 'approved')
                    Positioned(
                      bottom: 2,
                      left: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: MyColors.success,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: MyColors.surface, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded,
                                size: 10, color: Colors.white),
                            SizedBox(width: 2.w),
                            Text("موثَّق",
                                style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white, fontSize: 9.sp)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullname, style: AppTextStyles.titleLarge),
                    SizedBox(height: 4.h),
                    if (profile.address.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 13, color: MyColors.textHint),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(profile.address,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: MyColors.textSecondary)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (hasBio) ...[
            SizedBox(height: 12.h),
            const Divider(height: 0, thickness: 0.5),
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote_rounded,
                    size: 16, color: MyColors.textHint),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(profile.description,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: MyColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.5)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Account Status Card (otherView only)
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _AccountStatusCard extends StatelessWidget {
  final ProfileEntity profile;
  _AccountStatusCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: MyColors.shadowLight, blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
                child: _VerificationTile(status: profile.verification)),
            Container(
                width: 1,
                margin: EdgeInsets.symmetric(vertical: 12.h),
                color: MyColors.border),
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

class _VerificationTile extends StatelessWidget {
  final String status;
  const _VerificationTile({required this.status});

  _StatusConfig get _config {
    switch (status) {
      case 'approved':
        return _StatusConfig('موثَّق', Icons.verified_rounded,
            MyColors.success, MyColors.successLight);
      case 'pending':
        return _StatusConfig('قيد المراجعة', Icons.hourglass_empty_rounded,
            MyColors.warning, MyColors.warningLight);
      case 'rejected':
        return _StatusConfig(
            'مرفوض', Icons.cancel_rounded, MyColors.error, MyColors.errorLight);
      default:
        return _StatusConfig('غير موثَّق', Icons.person_outline_rounded,
            MyColors.textHint, MyColors.background);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    return Padding(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('حالة التوثيق',
              style:
                  AppTextStyles.labelSmall.copyWith(color: MyColors.textHint)),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
                color: cfg.bg, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cfg.icon, color: cfg.color, size: 14),
                SizedBox(width: 4.w),
                Text(cfg.label,
                    style: AppTextStyles.labelSmall.copyWith(
                        color: cfg.color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  final int score;
  final String tier;
  final bool canCreate;
  final bool canBook;
  const _ScoreTile(
      {required this.score,
      required this.tier,
      required this.canCreate,
      required this.canBook});

  _StatusConfig get _config {
    switch (tier) {
      case 'Gold':
        return _StatusConfig('ذهبي', Icons.workspace_premium_rounded,
            const Color(0xFFB8860B), const Color(0xFFFFF8DC));
      case 'Silver':
        return _StatusConfig('فضي', Icons.shield_rounded,
            const Color(0xFF546E7A), const Color(0xFFECEFF1));
      case 'Bronze':
        return _StatusConfig('برونزي', Icons.military_tech_rounded,
            const Color(0xFF8D6E63), const Color(0xFFEFEBE9));
      default:
        return _StatusConfig(
            'محظور', Icons.block_rounded, MyColors.error, MyColors.errorLight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    return Padding(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('درجة النشاط',
              style:
                  AppTextStyles.labelSmall.copyWith(color: MyColors.textHint)),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                    color: cfg.bg, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cfg.icon, color: cfg.color, size: 14),
                    SizedBox(width: 4.w),
                    Text(cfg.label,
                        style: AppTextStyles.labelSmall.copyWith(
                            color: cfg.color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              Text('$score/100',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: MyColors.textSecondary)),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
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
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 4.w),
        Text(label,
            style: AppTextStyles.labelSmall
                .copyWith(color: MyColors.textSecondary, fontSize: 10.sp)),
      ],
    );
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatusConfig(this.label, this.icon, this.color, this.bg);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Rating Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _RatingCard extends StatelessWidget {
  final ProfileEntity profile;
  _RatingCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: MyColors.shadowLight, blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("معدل التقييم", style: AppTextStyles.labelSmall),
              SizedBox(height: 4.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(profile.averageRating.toStringAsFixed(1),
                      style: AppTextStyles.displayLarge
                          .copyWith(color: MyColors.primary, fontSize: 36)),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h, right: 4.w),
                    child: Text("/ 5", style: AppTextStyles.bodySmall),
                  ),
                ],
              ),
              Text("بناءً على ${profile.totalRating} تقييم",
                  style: AppTextStyles.labelSmall
                      .copyWith(color: MyColors.textSecondary)),
            ],
          ),
          const Spacer(),
          _MiniBarChart(average: profile.averageRating),
        ],
      ),
    );
  }
}

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
// Car Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _CarCard extends StatelessWidget {
  final CarEntity car;
  _CarCard({required this.car});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: MyColors.shadowLight, blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: MyColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.directions_car_rounded,
                      color: MyColors.primary, size: 17),
                ),
                SizedBox(width: 8.w),
                Text('مركبة السائق', style: AppTextStyles.labelLarge),
              ],
            ),
          ),
          const Divider(height: 0, thickness: 0.5),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          openImage(car.image ?? ImagesUrl.defualtCar),
                      child: CircleAvatar(
                        radius: 30.r,
                        backgroundColor: MyColors.background,
                        backgroundImage: car.image != null
                            ? NetworkImage(car.image!) as ImageProvider
                            : const AssetImage(ImagesUrl.defualtCar),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (car.type != null && car.type!.isNotEmpty)
                            Text(car.type!,
                                style: AppTextStyles.titleMedium),
                          if (car.color != null && car.color!.isNotEmpty)
                            Text(car.color!,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: MyColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                const Divider(height: 0, thickness: 0.5),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _CarInfoChip(
                      icon: Icons.event_seat_rounded,
                      label: '${car.seats ?? '-'} مقاعد',
                    ),
                    SizedBox(width: 8.w),
                    _CarInfoChip(
                      icon: Icons.radio_rounded,
                      label: car.hasRadio ? 'راديو' : 'بدون راديو',
                      active: car.hasRadio,
                    ),
                    SizedBox(width: 8.w),
                    _CarInfoChip(
                      icon: Icons.smoking_rooms_rounded,
                      label: car.allowsSmoking ? 'تدخين' : 'بدون تدخين',
                      active: car.allowsSmoking,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _CarInfoChip(
      {required this.icon, required this.label, this.active = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
          color: MyColors.background,
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: active ? MyColors.primary : MyColors.textHint),
          SizedBox(width: 4.w),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(
                  color:
                      active ? MyColors.textPrimary : MyColors.textHint)),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Comments Section
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _CommentsSection extends StatelessWidget {
  final ProfileEntity profile;
  _CommentsSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final comments = profile.comments ?? [];
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: MyColors.shadowLight, blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: MyColors.accentLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.chat_bubble_outline_rounded,
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
                child: Text('لا توجد تعليقات بعد',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: MyColors.textHint)),
              ),
            )
          else
            ProfileComments(feadBack: comments),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Verify Option
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final bColor = badgeColor ?? MyColors.accent;
    final bBg = badgeColor != null
        ? badgeColor!.withValues(alpha: 0.12)
        : MyColors.accentLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        // الترتيب هنا ترتيب القراءة لا ترتيب البكسل: التطبيق كلّه RTL
        // (main.dart)، و`Row` يوزّع أبناءه من اليمين. كان السطر مكتوباً
        // معكوساً بيده — السهم أولاً والأيقونة آخراً — فوقعت الأيقونة
        // أقصى اليسار والسهم أقصى اليمين، وهو مقلوب عن كل قائمة عربية.
        //
        // وسهم `arrow_forward_ios` يُعكس من تلقائه (`matchTextDirection`)
        // فيشير يساراً — جهة الدخول في RTL.
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: MyColors.background,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: MyColors.primary, size: 20),
            ),
            SizedBox(width: 12.w),
            // Expanded لا Spacer: الاسم الطويل يُقصّ بدل أن يفيض
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null) ...[
              SizedBox(width: 8.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                    color: bBg, borderRadius: BorderRadius.circular(20)),
                child: Text(badge!,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: bColor)),
              ),
            ],
            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: MyColors.textHint),
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

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showAppDialog(
      context,
      icon: Icons.logout_rounded,
      title: 'تسجيل الخروج',
      message: 'ستحتاج إلى إدخال بريدك وكلمة المرور مرة أخرى للدخول. '
          'رحلاتك وحجوزاتك تبقى كما هي.',
      confirmLabel: 'تسجيل الخروج',
      cancelLabel: 'البقاء',
      destructive: true,
    );
    if (confirmed != true) return;
    final result = await getit.get<AuthRepoIm>().logout();
    result.fold(
      (_) => AppSnackBar.error('فشل تسجيل الخروج، حاول مجدداً'),
      (_) async {
        await ChatSocketService.instance.disconnect();
        Get.offAllNamed(RouteName.login);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _logout(context),
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
            Icon(Icons.logout_rounded, color: MyColors.error, size: 20),
            SizedBox(width: 8.w),
            Text("تسجيل الخروج",
                style: AppTextStyles.bodyMedium.copyWith(
                    color: MyColors.error, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
