import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/home/preantion/manger/cubit/home_nav_cubit_cubit.dart';

class ModernBottomNavBar extends StatelessWidget {
  final PageController pageController;
  const ModernBottomNavBar({super.key, required this.pageController});

  static const _navIcons = [
    Icons.home_rounded,
    Icons.directions_car_rounded,
    Icons.confirmation_number_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.person_rounded,
  ];

  static const _titles = [
    "الرئيسية",
    "رحلاتي",
    "حجوزاتي",
    "الدردشة",
    "حسابي",
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeNavCubit, int>(
      builder: (context, currentIndex) {
        return Container(
          margin: EdgeInsets.only(bottom: 12.h, right: 20.w, left: 20.w),
          height: 80.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: const [
              BoxShadow(
                color: MyColors.shadowLight,
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_navIcons.length, (index) {
              final isSelected = index == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    context.read<HomeNavCubit>().changePage(index);
                    pageController.jumpToPage(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? MyColors.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Icon(
                            _navIcons[index],
                            size: 22,
                            color: isSelected
                                ? MyColors.primary
                                : MyColors.textHint,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _titles[index],
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? MyColors.primary
                                : MyColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
