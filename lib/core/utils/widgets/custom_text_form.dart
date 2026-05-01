import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';

// ignore: must_be_immutable
class CustomTextformfild extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final String title;
  final Icon? icon;
  final bool? fill;
  final Widget? suffix;
  final bool scureText;
  final TextInputType? keyboardType;
  final String? hint;
  final double? height;
  final double? width;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final Color? fillColor;
  final Widget? prefix;

  const CustomTextformfild(
      {super.key,
      this.height,
      this.width,
      required this.title,
      this.onChanged,
      this.controller,
      this.icon,
      this.suffix,
      this.onFieldSubmitted,
      this.validator,
      this.keyboardType,
      this.scureText = false,
      this.maxLines = 1,
      this.minLines,
      this.expands = false,
      this.textInputAction,
      this.hint,
      this.fill,
      this.fillColor,
      this.prefix});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: TextFormField(
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        keyboardType: keyboardType,
        obscureText: scureText,
        maxLines: expands ? null : maxLines,
        minLines: expands ? null : minLines,
        expands: expands,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          prefix: prefix,
          labelText: title,
          labelStyle: const TextStyle(
            fontSize: 14,
            color: MyColors.navy,
          ),
          hintText: hint,
          suffix: suffix,
          prefixIcon: icon,
          prefixIconColor: MyColors.accent,
          filled: fill,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: MyColors.primary),
          ),
        ),
      ),
    );
  }
}
