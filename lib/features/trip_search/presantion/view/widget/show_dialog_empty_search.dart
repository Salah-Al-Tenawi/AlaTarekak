import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';

Future<void> showNoTripsDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.airport_shuttle_outlined,
            size: 60,
            color: MyColors.accent.withOpacity(0.8),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد رحلات متاحة حالياً',
            style: TextStyle(
              color: MyColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'حاول تغيير التاريخ أو الموقع للعثور على رحلات أخرى.',
            style: TextStyle(
              color: MyColors.secondary.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'حسناً',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}
