// ━━━━━━━━━━━━━━━━━━━━━━━━
// profile_stats_section.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';

/// إحصاءات الرحلات والحجوزات.
///
/// كانت تُعرض كثماني بطاقات ملوّنة في شبكتين، لكل رقم خلفيته الخاصة —
/// فتتنافس الألوان ولا يبرز شيء، وتلتهم الشبكتان ارتفاعاً كبيراً بلا
/// معلومة إضافية. صارت صفَّين مضغوطين بفواصل رفيعة، واللون مقصور على
/// الرقم وحده: نفس لغة [_QuickStatsRow] في الصفحة الرئيسية للملف.
class ProfileStatsSection extends StatelessWidget {
  final ProfileEntity profile;
  const ProfileStatsSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatsCard(
          icon: Icons.route_rounded,
          title: "الرحلات",
          iconColor: MyColors.accent,
          items: [
            _StatData("المنشأة", profile.totalTrips, MyColors.primary),
            _StatData("الناجحة", profile.successfulTrips, MyColors.success),
            _StatData("الملغاة", profile.cancelledTrips, MyColors.error),
            _StatData("عدم حضور", profile.noShowTrips, MyColors.warning),
          ],
        ),
        SizedBox(height: 12.h),
        _StatsCard(
          icon: Icons.calendar_month_outlined,
          title: "الحجوزات",
          iconColor: MyColors.primary,
          items: [
            _StatData("المنشأة", profile.totalBookings, MyColors.primary),
            _StatData("الناجحة", profile.successfulBookings, MyColors.success),
            _StatData("الملغاة", profile.cancelledBookings, MyColors.error),
            _StatData("عدم حضور", profile.noShowBookings, MyColors.warning),
          ],
        ),
      ],
    );
  }
}

class _StatData {
  final String label;
  final int value;
  final Color color;

  const _StatData(this.label, this.value, this.color);
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final List<_StatData> items;

  const _StatsCard({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: MyColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: iconColor, size: 17.sp),
                ),
                SizedBox(width: 8.w),
                Text(title, style: AppTextStyles.labelLarge),
              ],
            ),
          ),
          const Divider(height: 0, thickness: 0.5),
          IntrinsicHeight(
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) _divider(),
                  Expanded(child: _StatCell(data: items[i])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        margin: EdgeInsets.symmetric(vertical: 12.h),
        color: MyColors.border,
      );
}

class _StatCell extends StatelessWidget {
  final _StatData data;
  const _StatCell({required this.data});

  @override
  Widget build(BuildContext context) {
    // القيمة صفر ليست خبراً — نُخفّت لونها حتى لا يصرخ «٠ ملغاة» بالأحمر
    final isZero = data.value == 0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${data.value}',
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: 20.sp,
              color: isZero ? MyColors.textHint : data.color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall
                .copyWith(color: MyColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
