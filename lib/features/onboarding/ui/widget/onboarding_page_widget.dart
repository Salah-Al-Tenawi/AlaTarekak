// ━━━━━━━━━━━━━━━━━━━━━━━━
// onboarding_page_widget.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/onboarding/data/onboarding_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  const OnboardingPageWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

         Image.asset(
              page.imagePath,
              fit: BoxFit.contain,
            ),

          SizedBox(height: 48.h),

          // ━━ العنوان ━━
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium
          ),

          SizedBox(height: 16.h),

          // ━━ الوصف ━━
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge
          ),
        ],
      ),
    );
  }
}