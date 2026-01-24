// ignore_for_file: must_be_immutable

import 'package:alatarekak/core/them/my_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyButton extends StatelessWidget {
  void Function()? onPressed;
  Widget child;
  Color? color;
  double? width;
  double? height;
  Color? splashcolor;
  bool? borderRadius = false;
  MyButton(
      {super.key,
      required this.onPressed,
      required this.child,
      this.color,
      this.width,
      this.height,
      this.borderRadius,
      this.splashcolor});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      shape: borderRadius == true
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
          : null,
      onPressed: onPressed,
      splashColor: splashcolor ?? MyColors.greyTextColor,
      minWidth: width ?? 100.h,
      height: height ?? 40.h,
      color: color,
      elevation: 20,
      child: child,
    );
  }
}
