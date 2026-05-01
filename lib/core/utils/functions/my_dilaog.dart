import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';

Future<bool?> myConfirmDilaogWithPolicy(
  BuildContext context,
  String message, {
  String title = "تأكيد",
  String confirmText = "نعم",
  String cancelText = "لا",
  Function()? onConfirm,
  Function()? onCancel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 10.h),
            child: const Center(
              child: Icon(
                Icons.error,
                size: 50,
                color: MyColors.accent,
              ),
            ),
          ),
          Text(message),
          Padding(
            padding:
                EdgeInsetsGeometry.symmetric(horizontal: 35.w, vertical: 10.h),
            child: GestureDetector(
              onTap: () {
                Get.toNamed(RouteName.policy);
              },
              child: const Text(
                "تعرف على سياسية التطبيق",
                style: TextStyle(
                  color: MyColors.accent,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          )
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: 100,
          height: 40,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              onCancel?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              cancelText,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        SizedBox(width: 12.h),
        SizedBox(
          width: 100,
          height: 40,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );
}
