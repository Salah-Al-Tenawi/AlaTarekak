import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/trip_search/presantion/view/widget/empty_trips_content.dart';

Future<void> showNoTripsDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: MyColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EmptyTripsContent(compact: true),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.primary,
                foregroundColor: MyColors.textOnDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text('حسناً', style: AppTextStyles.buttonLarge),
            ),
          ),
        ],
      ),
    ),
  );
}
