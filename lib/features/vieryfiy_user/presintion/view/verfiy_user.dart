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
    userType = (Get.arguments as String).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = userType == "driver";
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BlocConsumer<VerifyUserCubit, VerfiyUserState>(
        listener: (context, state) {
          if (state is VerfiyError) {
            AppSnackBar.error(state.message);
          } else if (state is VerfiySuccess) {
            AppSnackBar.success('تم إرسال المستندات بنجاح');
            Get.offAllNamed(RouteName.home);
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
              // ━━ Header gradient ━━
              Container(
                height: screenHeight * 0.36,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [MyColors.navy, MyColors.primary, MyColors.blue],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // ━━ زر الرجوع ━━
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white, size: 20),
                            onPressed: () => Get.back(),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ━━ أيقونة ━━
                      Container(
                        width: 68.w,
                        height: 68.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isDriver
                              ? Icons.badge_outlined
                              : Icons.person_pin_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      SizedBox(height: 14.h),

                      Text(
                        'توثيق الهوية',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 6.h),

                      // ━━ شارة النوع ━━
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: MyColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: MyColors.accent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          isDriver ? 'توثيق كسائق' : 'توثيق كمستخدم',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),

              // ━━ البطاقة البيضاء ━━
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: MyColors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32.r)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('المستندات المطلوبة',
                            style: AppTextStyles.titleLarge),
                        SizedBox(height: 4.h),
                        Text(
                          isDriver
                              ? 'ارفع صورة الهوية ورخصة القيادة وفحص السيارة'
                              : 'ارفع صورة الهوية الشخصية وجهين',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: MyColors.textSecondary),
                        ),

                        SizedBox(height: 24.h),

                        // ━━ صور الهوية ━━
                        _SectionLabel(label: 'الهوية الشخصية'),
                        SizedBox(height: 12.h),

                        Row(
                          children: [
                            Expanded(
                              child: _ImageCard(
                                label: 'الوجه الأمامي',
                                icon: Icons.credit_card,
                                image: frontImage,
                                onTap: cubit.pickFrontId,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _ImageCard(
                                label: 'الوجه الخلفي',
                                icon: Icons.credit_card_outlined,
                                image: backImage,
                                onTap: cubit.pickBackId,
                              ),
                            ),
                          ],
                        ),

                        if (isDriver) ...[
                          SizedBox(height: 20.h),
                          _SectionLabel(label: 'مستندات السائق'),
                          SizedBox(height: 12.h),

                          Row(
                            children: [
                              Expanded(
                                child: _ImageCard(
                                  label: 'رخصة القيادة',
                                  icon: Icons.drive_eta_outlined,
                                  image: licenseImage,
                                  onTap: cubit.pickDriverLicense,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _ImageCard(
                                  label: 'فحص السيارة',
                                  icon: Icons.car_repair_outlined,
                                  image: mechanicImage,
                                  onTap: cubit.pickMechanic,
                                ),
                              ),
                            ],
                          ),
                        ],

                        SizedBox(height: 32.h),

                        // ━━ زر الإرسال ━━
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
                              backgroundColor: MyColors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('إرسال للمراجعة',
                                    style: AppTextStyles.buttonLarge),
                          ),
                        ),
                      ],
                    ),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: MyColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8.w),
        Text(label,
            style: AppTextStyles.labelLarge
                .copyWith(color: MyColors.textPrimary)),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final XFile? image;
  final Future<void> Function() onTap;

  const _ImageCard({
    required this.label,
    required this.icon,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130.h,
        decoration: BoxDecoration(
          color: hasImage ? Colors.transparent : MyColors.background,
          border: Border.all(
            color: hasImage ? MyColors.accent : MyColors.primary.withValues(alpha: 0.3),
            width: hasImage ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(image!.path), fit: BoxFit.cover),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: MyColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 32, color: MyColors.primary.withValues(alpha: 0.5)),
                  SizedBox(height: 8.h),
                  Text(
                    label,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: MyColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: MyColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'اضغط للرفع',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: MyColors.accent),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
