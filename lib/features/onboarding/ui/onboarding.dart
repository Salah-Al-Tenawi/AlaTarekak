// ━━━━━━━━━━━━━━━━━━━━━━━━
// onboarding_screen.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/onboarding/data/list_onboarding.dart';
import 'package:alatarekak/features/onboarding/ui/manger/cubit/onboarding_cubit.dart';
import 'package:alatarekak/features/onboarding/ui/widget/onboarding_page_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';

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
          body: SafeArea(
            child: Column(
              children: [

                // ━━ PageView ━━
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: cubit.changePage,
                    itemBuilder: (context, index) =>
                        OnboardingPageWidget(page: pages[index]),
                  ),
                ),

                // ━━ Dots ━━
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: currentPage == index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: currentPage == index
                            ? MyColors.accent
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // ━━ أزرار التنقل ━━
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      // ━━ تخطي ━━
                      if (!isLast)
                        GestureDetector(
                          onTap: cubit.finishOnboarding,
                          child: Text(
                            "تخطي",
                            style: AppTextStyles.bodyLarge
                                .copyWith(
                                  color: MyColors.primary,
                                  fontWeight: FontWeight.bold,
                                
                                ),
                          ),
                        )
                      else
                        const SizedBox(),

                      // ━━ التالي / ابدأ الآن ━━
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyColors.accent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          if (isLast) {
                            cubit.finishOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLast ? "ابدأ الآن" : "التالي",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (!isLast) ...[
                              SizedBox(width: 6.w),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),
              ],
            ),
          ),
        );
      },
    );
  }
}