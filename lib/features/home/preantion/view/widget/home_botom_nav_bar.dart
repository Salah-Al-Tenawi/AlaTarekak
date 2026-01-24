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
    Icons.directions_car,
    Icons.search_rounded,
    Icons.list_alt_rounded,
    Icons.event_note

  ];

  final List<String> _titles = const [
    "الرحلات",
    "بحث",
    "رحلاتي", 
    "حجوزاتي"
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeNavCubit, int>(
      builder: (context, currentIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _navIcons.asMap().entries.map((entry) {
                    final index = entry.key;
                    final icon = entry.value;
                    final isSelected = index == currentIndex;

                    return GestureDetector(
                      onTap: () {
                        context.read<HomeNavCubit>().changePage(index);
                        pageController.jumpToPage(index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? 16 : 0,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? MyColors.accent.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: isSelected ? 28 : 24,
                              color: isSelected
                                  ? MyColors.accent
                                  : Colors.white.withOpacity(0.7),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Text(
                                _titles[index],
                                style: TextStyle(
                                  color: MyColors.accent,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ]
                          ],
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
