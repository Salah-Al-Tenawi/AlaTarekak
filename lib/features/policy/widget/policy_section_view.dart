import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/policy/text/pollicy_text.dart';

/// عرض قسم واحد من السياسة — يشترك فيه شاشة السياسة وحوار الموافقة
/// فلا يختلف شكل النصّ بين الموضعين.
class PolicySectionView extends StatelessWidget {
  final PolicySection section;
  final int index;

  const PolicySectionView({
    super.key,
    required this.section,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 22.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: MyColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: MyColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  section.title,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: MyColors.primary),
                ),
              ),
            ],
          ),
          if (section.intro != null) ...[
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.only(right: 34.w),
              child: Text(
                section.intro!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: MyColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ),
          ],
          if (section.points.isNotEmpty) ...[
            SizedBox(height: 10.h),
            ...section.points.map(
              (p) => Padding(
                padding: EdgeInsets.only(right: 34.w, bottom: 7.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 7.h),
                      child: Icon(Icons.circle,
                          size: 5.sp, color: MyColors.accent),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        p,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: MyColors.textPrimary,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
