import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/route_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/vieryfiy_user/presintion/manger/cubit/verfiy_user_cubit.dart';

class VerfiyUser extends StatefulWidget {
  const VerfiyUser({super.key});

  @override
  State<VerfiyUser> createState() => _VerfiyUserState();
}

class _VerfiyUserState extends State<VerfiyUser> {
  late final String userType;

  @override
  void initState() {
    super.initState();
    // `as String` كان تحويلاً غير محروس: فتحُ الشاشة بلا وسيط — من إشعار
    // أو رابط عميق أو استدعاء نسي تمريره — يرمي TypeError في initState
    // فتنهار الشاشة قبل أن تُرسم. والافتراض الأضيق (راكب) أسلم: يطلب
    // صورتي الهوية وحدهما لا رخصةً وفحصَ مركبة لا يملكهما.
    final raw = Get.arguments;
    userType = raw is String ? raw.toLowerCase() : 'passenger';
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = userType == 'driver';

    return Scaffold(
      backgroundColor: MyColors.background,
      body: BlocConsumer<VerifyUserCubit, VerfiyUserState>(
        listener: (context, state) {
          if (state is VerfiyError) {
            AppSnackBar.error(state.message);
          } else if (state is VerfiySuccess) {
            // الانتقال أولاً: offAllNamed يزيل كل المسارات ومنها مسار الإشعار
            Get.offAllNamed(RouteName.home);
            AppSnackBar.success('تم إرسال المستندات بنجاح');
          }
        },
        builder: (context, state) {
          final cubit = context.read<VerifyUserCubit>();

          XFile? frontImage = cubit.frontIdImage;
          XFile? backImage = cubit.backIdImage;
          XFile? licenseImage = cubit.driverLicenseImage;
          XFile? mechanicImage = cubit.mechanicImage;

          if (state is VerfiyUserImagesUpdated) {
            frontImage = state.frontIdImage ?? frontImage;
            backImage = state.backIdImage ?? backImage;
            licenseImage = state.driverLicenseImage ?? licenseImage;
            mechanicImage = state.mechanicImage ?? mechanicImage;
          }

          final isLoading = state is VerfiyLoading;

          return Column(
            children: [
              _Header(isDriver: isDriver),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── وصف ──
                      _InfoNote(
                        icon: Icons.info_outline_rounded,
                        color: MyColors.primary,
                        bgColor: MyColors.primary.withValues(alpha: 0.07),
                        text: isDriver
                            ? 'يرجى رفع صورة واضحة للمستندات التالية لإتمام عملية التوثيق وتفعيل حسابك كسائق.'
                            : 'يرجى رفع صورة واضحة للهوية الشخصية وجهين لإتمام عملية التوثيق.',
                      ),

                      SizedBox(height: 20.h),

                      // ── بطاقات المستندات ──
                      Container(
                        decoration: BoxDecoration(
                          color: MyColors.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                                color: MyColors.shadowLight,
                                blurRadius: 8,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          children: [
                            _DocRow(
                              title: 'بطاقة الهوية الوطنية',
                              subtitle: 'الوجه الأمامي',
                              icon: Icons.credit_card_rounded,
                              image: frontImage,
                              onTap: cubit.pickFrontId,
                              isFirst: true,
                            ),
                            const _RowDivider(),
                            _DocRow(
                              title: 'بطاقة الهوية الوطنية',
                              subtitle: 'الوجه الخلفي',
                              icon: Icons.credit_card_outlined,
                              image: backImage,
                              onTap: cubit.pickBackId,
                            ),
                            if (isDriver) ...[
                              const _RowDivider(),
                              _DocRow(
                                title: 'رخصة القيادة',
                                subtitle: 'صورة الرخصة الحالية',
                                icon: Icons.drive_eta_outlined,
                                image: licenseImage,
                                onTap: cubit.pickDriverLicense,
                              ),
                              const _RowDivider(),
                              _DocRow(
                                title: 'فحص السيارة',
                                subtitle: 'بطاقة الفحص الميكانيكي',
                                icon: Icons.car_repair_outlined,
                                image: mechanicImage,
                                onTap: cubit.pickMechanic,
                                isLast: true,
                              ),
                            ] else ...[
                              // close card when passenger
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // ── ملاحظة وقت المراجعة ──
                      _InfoNote(
                        icon: Icons.access_time_rounded,
                        color: MyColors.warning,
                        bgColor: MyColors.warningLight,
                        text:
                            'يستغرق الأمر مراجعة المستندات ما بين 24 إلى 48 ساعة عمل. ستتلقى إشعاراً عند اكتمال المراجعة.',
                      ),

                      SizedBox(height: 28.h),

                      // ── زر الإرسال ──
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (isDriver) {
                                    if (cubit.allImagesSelected(true)) {
                                      cubit.submitDriverImages();
                                    } else {
                                      AppSnackBar.error(
                                          'الرجاء رفع جميع المستندات');
                                    }
                                  } else {
                                    if (cubit.allImagesSelected(false)) {
                                      cubit.submitPassengerImages();
                                    } else {
                                      AppSnackBar.error(
                                          'الرجاء رفع صورتي الهوية');
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 22.r,
                                  height: 22.r,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded, size: 18.sp),
                                    SizedBox(width: 8.w),
                                    Text('إرسال للمراجعة',
                                        style: AppTextStyles.buttonLarge),
                                  ],
                                ),
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // ── إلغاء ──
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            'إلغاء',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: MyColors.textSecondary),
                          ),
                        ),
                      ),

                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Header gradient ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isDriver;
  const _Header({required this.isDriver});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MyColors.navy, MyColors.primary, MyColors.blue],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 28.h),
          child: Column(
            children: [
              // back button
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white, size: 20.sp),
                  onPressed: () => Get.back(),
                ),
              ),
              SizedBox(height: 8.h),

              // icon
              Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: Icon(
                  isDriver
                      ? Icons.badge_outlined
                      : Icons.person_pin_outlined,
                  color: Colors.white,
                  size: 30.sp,
                ),
              ),
              SizedBox(height: 12.h),

              Text(
                'رفع المستندات',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6.h),

              // badge
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: MyColors.accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                      color: MyColors.accent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  isDriver ? 'توثيق كسائق' : 'توثيق كراكب',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Document row ─────────────────────────────────────────────────────────────

class _DocRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final XFile? image;
  final Future<void> Function() onTap;
  final bool isFirst;
  final bool isLast;

  const _DocRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.image,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = image != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? Radius.circular(16.r) : Radius.zero,
          bottom: isLast ? Radius.circular(16.r) : Radius.zero,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              // thumbnail or icon box
              Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  color: uploaded
                      ? null
                      : MyColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                clipBehavior: Clip.antiAlias,
                child: uploaded
                    ? Image.file(File(image!.path), fit: BoxFit.cover)
                    : Icon(icon,
                        size: 26.sp,
                        color: MyColors.primary.withValues(alpha: 0.6)),
              ),

              SizedBox(width: 14.w),

              // text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLarge),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: MyColors.textHint),
                    ),
                    SizedBox(height: 5.h),
                    _StatusBadge(uploaded: uploaded),
                  ],
                ),
              ),

              SizedBox(width: 10.w),

              // action icon
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: uploaded
                      ? MyColors.successLight
                      : MyColors.background,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  uploaded
                      ? Icons.check_circle_rounded
                      : Icons.upload_file_outlined,
                  size: 20.sp,
                  color:
                      uploaded ? MyColors.success : MyColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool uploaded;
  const _StatusBadge({required this.uploaded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: uploaded ? MyColors.successLight : MyColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        uploaded ? 'تم الرفع' : 'لم يتم الرفع بعد',
        style: AppTextStyles.labelSmall.copyWith(
          color: uploaded ? MyColors.success : MyColors.textHint,
          fontSize: 10.sp,
        ),
      ),
    );
  }
}

// ─── Info note box ────────────────────────────────────────────────────────────

class _InfoNote extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String text;
  const _InfoNote({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: MyColors.divider,
          indent: 16.w, endIndent: 16.w);
}
