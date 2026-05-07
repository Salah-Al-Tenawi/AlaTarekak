// ━━━━━━━━━━━━━━━━━━━━━━━━
// profile_stats_section.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';

class ProfileStatsSection extends StatelessWidget {
  final ProfileEntity profile;
  const ProfileStatsSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ━━ الرحلات ━━
        _StatsCard(
          icon: Icons.route_rounded,
          title: "الرحلات",
          iconBg: MyColors.accentLight,
          iconColor: MyColors.accent,
          items: [
            _StatData(
              label: "المنشأة",
              value: profile.totalTrips,
              bg: MyColors.background,
              valueColor: MyColors.primary,
              dotColor: MyColors.primary,
            ),
            _StatData(
              label: "الناجحة",
              value: profile.successfulTrips,
              bg: MyColors.successLight,
              valueColor: MyColors.success,
              dotColor: MyColors.success,
            ),
            _StatData(
              label: "الملغاة",
              value: profile.cancelledTrips,
              bg: MyColors.errorLight,
              valueColor: MyColors.error,
              dotColor: MyColors.error,
            ),
            _StatData(
              label: "عدم حضور",
              value: profile.noShowTrips,
              bg: MyColors.warningLight,
              valueColor: MyColors.warning,
              dotColor: MyColors.warning,
            ),
          ],
          columns: 2,
        ),

        SizedBox(height: 12.h),

        // ━━ الحجوزات ━━
        _StatsCard(
          icon: Icons.calendar_month_outlined,
          title: "الحجوزات",
          iconBg: const Color(0xFFE8F0F8),
          iconColor: MyColors.primary,
          items: [
            _StatData(
              label: "المنشأة",
              value: profile.totalBookings,
              bg: MyColors.background,
              valueColor: MyColors.primary,
              dotColor: MyColors.primary,
            ),
            _StatData(
              label: "الناجحة",
              value: profile.successfulBookings,
              bg: MyColors.successLight,
              valueColor: MyColors.success,
              dotColor: MyColors.success,
            ),
            _StatData(
              label: "الملغاة",
              value: profile.cancelledBookings,
              bg: MyColors.errorLight,
              valueColor: MyColors.error,
              dotColor: MyColors.error,
            ),
          ],
          columns: 3,
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Data Model
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _StatData {
  final String label;
  final int value;
  final Color bg;
  final Color valueColor;
  final Color dotColor;

  const _StatData({
    required this.label,
    required this.value,
    required this.bg,
    required this.valueColor,
    required this.dotColor,
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Card Widget
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconBg;
  final Color iconColor;
  final List<_StatData> items;
  final int columns;

  const _StatsCard({
    required this.icon,
    required this.title,
    required this.iconBg,
    required this.iconColor,
    required this.items,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: MyColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ━━ Header ━━
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
                SizedBox(width: 8.w),
                Text(title, style: AppTextStyles.labelLarge),
              ],
            ),
          ),

          const Divider(height: 0, thickness: 0.5),

          // ━━ Grid ━━
          Padding(
            padding: EdgeInsets.all(12.w),
            child: GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
              childAspectRatio: columns == 2 ? 1.8 : 1.4,
              children: items.map((item) => _StatItem(data: item)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Item Widget
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _StatItem extends StatelessWidget {
  final _StatData data;
  const _StatItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Row(
        children: [
          // ━━ dot ━━
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: data.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: data.valueColor,
                ),
              ),
              Text(
                data.value.toString(),
                style: AppTextStyles.titleMedium.copyWith(
                  color: data.valueColor,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}