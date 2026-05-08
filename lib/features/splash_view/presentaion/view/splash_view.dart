import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/splash_view/presentaion/manger/cubit/splash_view_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    context.read<SplashCubit>().initApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyColors.navy,
              MyColors.primary,
              MyColors.blue,
            ],
          ),
        ),
        child: Stack(
          children: [
            // ━━ دائرة زخرفية أعلى اليمين ━━
            Positioned(
              top: -80.h,
              right: -80.w,
              child: Container(
                width: 250.w,
                height: 250.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // ━━ دائرة زخرفية أسفل اليسار ━━
            Positioned(
              bottom: -100.h,
              left: -100.w,
              child: Container(
                width: 300.w,
                height: 300.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MyColors.accent.withValues(alpha: 0.07),
                ),
              ),
            ),

            // ━━ المحتوى الرئيسي ━━
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ━━ اللوغو مع glow ━━
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: MyColors.accent.withValues(
                                alpha: 0.15 + (_pulseController.value * 0.25),
                              ),
                              blurRadius: 30 + (_pulseController.value * 25),
                              spreadRadius: 4 + (_pulseController.value * 6),
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1, 1),
                        duration: 700.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 400.ms),

                  SizedBox(height: 36.h),

                  // ━━ اسم التطبيق ━━
                  Text(
                    'عطريقك',
                    style: TextStyle(
                      fontSize: 38.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 450.ms, duration: 500.ms)
                      .slideY(
                        begin: 0.4,
                        end: 0,
                        delay: 450.ms,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),

                  SizedBox(height: 10.h),

                  // ━━ الشعار المرافق ━━
                  Text(
                    'رفيقك في كل رحلة',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 0.8,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 650.ms, duration: 500.ms)
                      .slideY(
                        begin: 0.4,
                        end: 0,
                        delay: 650.ms,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),

                  SizedBox(height: 16.h),

                  // ━━ خط accent ━━
                  Container(
                    width: 40.w,
                    height: 3,
                    decoration: BoxDecoration(
                      color: MyColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 400.ms)
                      .scaleX(
                        begin: 0,
                        end: 1,
                        delay: 800.ms,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),

                  SizedBox(height: 70.h),

                  // ━━ نقاط التحميل ━━
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.symmetric(horizontal: 5.w),
                        decoration: const BoxDecoration(
                          color: MyColors.accent,
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .fadeIn(
                            delay: Duration(milliseconds: 900 + i * 180),
                            duration: 350.ms,
                          )
                          .then()
                          .fadeOut(duration: 350.ms)
                          .then()
                          .fadeIn(duration: 350.ms);
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
