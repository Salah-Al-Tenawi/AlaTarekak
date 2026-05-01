import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/widgets/cricular_decoration.dart';
import 'package:alatarekak/features/onboarding/data/list_onboarding.dart';
import 'package:alatarekak/features/onboarding/ui/manger/cubit/onboarding_cubit.dart';
import 'package:alatarekak/features/onboarding/ui/widget/onboarding_page_widget.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pageController = PageController();

    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingFinished) {
          Get.offAllNamed(RouteName.login);
        }
      },
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    cubit.changePage(index);
                  },
                  itemBuilder: (context, index) =>
                      OnboardingPageWidget(page: pages[index]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.all(4),
                    width: cubit.currentPage == index ? 16 : 8,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: cubit.currentPage == index
                          ? MyColors.accent
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 25.h),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MaterialButton(
                      color: MyColors.primary,
                      onPressed: () {
                        cubit.finishOnboarding();
                      },
                      child: const Text(
                        "تخطي",
                        style: TextStyle(color: MyColors.textLight),
                      ),
                    ),
                    MaterialButton(
                      color: MyColors.textHint,
                      onPressed: () {
                        if (cubit.currentPage == pages.length - 1) {
                          cubit.finishOnboarding();
                        } else {
                          pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(
                        style: const TextStyle(color: MyColors.primary),
                        cubit.currentPage == pages.length - 1
                            ? "ابدأ"
                            : "التالي",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
