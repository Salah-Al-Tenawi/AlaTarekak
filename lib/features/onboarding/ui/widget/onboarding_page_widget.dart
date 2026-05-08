import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/features/onboarding/data/onboarding_data.dart';

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  const OnboardingPageWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Image.asset(
        page.imagePath,
        fit: BoxFit.contain,
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.88, 0.88),
          end: const Offset(1, 1),
          duration: 450.ms,
          curve: Curves.easeOut,
        );
  }
}
