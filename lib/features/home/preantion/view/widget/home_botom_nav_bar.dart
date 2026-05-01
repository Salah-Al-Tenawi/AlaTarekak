import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/home/preantion/manger/cubit/home_nav_cubit_cubit.dart';

class ModernBottomNavBar extends StatelessWidget {
  final PageController pageController;
  const ModernBottomNavBar({super.key, required this.pageController});

  final List<IconData> _navIcons = const [
  Icons.home,            // الرئيسية
  Icons.directions_car,  // رحلاتي
  Icons.credit_card,     // حجوزاتي / المحفظة
  Icons.chat_bubble,     // الدردشة / بحث (حسب استخدامك)
  Icons.person,          // حسابي
];

final List<String> _titles = const [
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
        return Padding(
          padding:  EdgeInsets.only(top: 0 ,bottom: 12.h ,right: 20.w,left: 20.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 75.h,
                decoration: BoxDecoration(
                  color: MyColors.primary,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: MyColors.primary.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child:  Row(
  children: _navIcons.asMap().entries.map((entry) {
    final index = entry.key;
    final icon = entry.value;
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<HomeNavCubit>().changePage(index);
          pageController.jumpToPage(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? MyColors.accent
                      : Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: isSelected ? 1 : 0.7,
                child: Text(
                  _titles[index],
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isSelected
                        ? MyColors.accent
                        : Colors.white.withOpacity(0.7),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }).toList(),
),
              ),
            ),
          ),
        );
      },
    );
  }
}
