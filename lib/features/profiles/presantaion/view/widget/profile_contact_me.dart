import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:alatarekak/core/them/my_colors.dart';

class ProfileContactMe extends StatelessWidget {
  const ProfileContactMe({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: () {
        // Get.toNamed();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: MyColors.accent,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chat_sharp,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
