import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

class ProfileDriverVerificationScreen extends StatelessWidget {
  const ProfileDriverVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded,
              color: MyColors.primary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text("توثيق السائق", style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      body: const Center(child: Text("قريباً...")),
    );
  }
}
