import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  final String policyText;

  const PrivacyPolicyDialog({super.key, required this.policyText});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Icon(Icons.privacy_tip, color: MyColors.accent),
          SizedBox(width: 8),
          Text(
            "سياسة الخصوصية",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: MyColors.primary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        height: 400,
        child: Scrollbar(
          thumbVisibility: true,
          thickness: 4,
          radius: const Radius.circular(8),
          child: SingleChildScrollView(
            child: Text(
              policyText,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.red.shade400,
          ),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("رفض"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: MyColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("أوافق"),
        ),
      ],
    );
  }
}
