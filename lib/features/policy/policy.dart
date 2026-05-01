import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';

class Policy extends StatelessWidget {
  const Policy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("سياسة التطبيق"),
        backgroundColor: MyColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "سياسة الإلغاء",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: MyColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "النص كامل يسيمنتب  ",
              style: TextStyle(
                fontSize: 16,
                color: MyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "بنود السياسة:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MyColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            _buildPolicyItem(
                "1. يمكن إلغاء الحجز قبل 24 ساعة من موعد الرحلة بدون أي رسوم."),
            _buildPolicyItem(
                "2. في حال الإلغاء خلال 24 ساعة من موعد الرحلة، يتم خصم 50% من المبلغ."),
            _buildPolicyItem(
                "3. لا يمكن استرداد المبلغ في حال الإلغاء قبل أقل من ساعتين من موعد الرحلة."),
            // أضف المزيد من البنود حسب الحاجة
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: MyColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: MyColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
