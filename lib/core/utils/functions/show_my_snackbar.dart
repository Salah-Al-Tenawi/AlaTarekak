import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';

void showMySnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 2),
})
 {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: backgroundColor ?? MyColors.textPrimary,
      duration: duration,
    ),
  );
}
