import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/route_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';

// عدّل هذا المسار إذا كان اسم الملف/المجلد مختلف عندك
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
    // إذا تستخدم Get.arguments لفصل بين driver/passenger فكّد التعليق التالي:
    userType = (Get.arguments as String).toLowerCase();
    // userType = "driver";
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = userType == "driver";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'التحقق من الهوية',
          style: font16boldsky,
        ),
        backgroundColor: MyColors.primary,
      ),
      body: BlocConsumer<VerifyUserCubit, VerfiyUserState>(
        listener: (context, state) {
          if (state is VerfiyError) {
            showMySnackBar(context, state.message);
          } else if (state is VerfiySuccess) {
            showMySnackBar(context, "تم إرسال الصور بنجاح ✅'");
            try {
              Get.offAllNamed(RouteName.home);
            } catch (e) {
              print(e);
            }
          }
        },
        builder: (context, state) {
          final cubit = context.read<VerifyUserCubit>();

          // احصل على الصور من الحالة إذا كانت محدثة وإلا استخدم الحقول في الكيوبت
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

          if (state is VerfiyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildImageTile(
                      context,
                      'صورة الهوية الوجه الأمامي',
                      frontImage,
                      cubit.pickFrontId,
                    ),
                    _buildImageTile(
                      context,
                      'صورة الهوية الوجه الخلفي',
                      backImage,
                      cubit.pickBackId,
                    ),
                    if (isDriver) ...[
                      _buildImageTile(
                        context,
                        'صورة رخصة القيادة',
                        licenseImage,
                        cubit.pickDriverLicense,
                      ),
                      _buildImageTile(
                        context,
                        'صورة ميكانيك السيارة',
                        mechanicImage,
                        cubit.pickMechanic,
                      ),
                    ],
                    SizedBox(height: 20.h),
                    MyButton(
                      onPressed: () {
                        if (isDriver) {
                          if (cubit.allImagesSelected(true)) {
                            cubit.submitDriverImages();
                          } else {
                            _showSnackBar(context);
                          }
                        } else {
                          if (cubit.allImagesSelected(false)) {
                            cubit.submitPassengerImages();
                          } else {
                            _showSnackBar(context);
                          }
                        }
                      },
                      color: MyColors.primary,
                      height: 50.h,
                      width: 100.w,
                      child: const Text("موافق", style: font13NormalGrayText),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('الرجاء اختيار كل الصور')),
    );
  }

  Widget _buildImageTile(
    BuildContext context,
    String label,
    XFile? image,
    Future<void> Function() onTap,
  ) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(label, textAlign: TextAlign.right),
        ),
        SizedBox(height: 10.h),
        InkWell(
          onTap: onTap,
          child: Container(
            width: 250.w,
            height: 250.h,
            decoration: BoxDecoration(
              border: Border.all(color: MyColors.primary),
              borderRadius: BorderRadius.circular(10),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(image.path), fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: MyColors.accent,
                  )),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
