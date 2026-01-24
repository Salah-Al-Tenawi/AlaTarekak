import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';

class LoadingWidgetSize150 extends StatelessWidget {
  const LoadingWidgetSize150({super.key});

  @override
  Widget build(BuildContext context) {
   return Center(
              child: Lottie.asset(
                ImagesUrl.loadinglottie,
                width: 150.w,
                height: 150.h,
                fit: BoxFit.contain,
              ),
            );
  }
}