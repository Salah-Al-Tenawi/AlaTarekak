import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/onboarding/data/list_onboarding.dart';
import 'package:alatarekak/features/onboarding/ui/manger/cubit/onboarding_cubit.dart';
import 'package:alatarekak/features/onboarding/ui/widget/onboarding_page_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingFinished) {
          Get.offAllNamed(RouteName.login);
        }
      },
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();
        final currentPage = cubit.currentPage;
        final isLast = currentPage == pages.length - 1;

        return Scaffold(
          body: Stack(
            children: [
              // ━━ خلفية gradient ━━
              Container(
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
              ),

              // ━━ دوائر زخرفية ━━
              Positioned(
                top: -60.h,
                right: -60.w,
                child: Container(
                  width: 200.w,
                  height: 200.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                top: 80.h,
                left: -40.w,
                child: Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MyColors.accent.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // ━━ المحتوى الرئيسي ━━
              Column(
                children: [
                  // ━━ شريط علوي ━━
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // رقم الصفحة
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${currentPage + 1} / ${pages.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // زر تخطي
                          if (!isLast)
                            GestureDetector(
                              onTap: cubit.finishOnboarding,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'تخطي',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(),
                        ],
                      ),
                    ),
                  ),

                  // ━━ الصور ━━
                  Expanded(
                    flex: 5,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: cubit.changePage,
                      itemBuilder: (context, index) =>
                          OnboardingPageWidget(page: pages[index]),
                    ),
                  ),

                  // ━━ البطاقة البيضاء السفلية ━━
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: MyColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32.r),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(28.w, 28.h, 28.w,
                        MediaQuery.of(context).padding.bottom + 24.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ━━ العنوان ━━
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: Text(
                            pages[currentPage].title,
                            key: ValueKey('title_$currentPage'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontSize: 20.sp,
                              height: 1.4,
                            ),
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // ━━ الوصف ━━
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                          child: Text(
                            pages[currentPage].description,
                            key: ValueKey('desc_$currentPage'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: MyColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // ━━ نقاط التنقل ━━
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              width: currentPage == index ? 22 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: currentPage == index
                                    ? MyColors.accent
                                    : MyColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // ━━ زر التالي / ابدأ الآن ━━
                        SizedBox(
                          width: double.infinity,
                          height: 52.h,
                          child: ElevatedButton(
                            onPressed: () {
                              if (isLast) {
                                cubit.finishOnboarding();
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColors.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLast ? 'ابدأ الآن' : 'التالي',
                                  style: AppTextStyles.buttonLarge,
                                ),
                                if (!isLast) ...[
                                  SizedBox(width: 8.w),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                            .animate(key: ValueKey(isLast))
                            .fadeIn(duration: 300.ms)
                            .scaleX(
                              begin: 0.95,
                              end: 1,
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
