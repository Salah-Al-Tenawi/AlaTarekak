import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/trip_create/domin/ride_price_rules.dart';

/// معايير ترتيب نتائج البحث كما تُعرض للسائق.
///
/// ⚠️ **مصدر واحد للنصّ**: ما يُذكر هنا يقرؤه المستخدم بصفته وصفاً لما
/// يفعله الخادم فعلاً. أي تغيير في ترتيب `POST /search` يجب أن يقابله
/// تغيير هنا، وإلا صار التطبيق يعِد بما لا يفي به.
const List<(IconData, String, String)> kSearchRankingCriteria = [
  (
    Icons.schedule_rounded,
    'قرب الموعد',
    'الرحلات الأقرب إلى الموعد الذي يبحث عنه الراكب تظهر أولاً.',
  ),
  (
    Icons.route_rounded,
    'مطابقة المسار',
    'كلّما اقتربت نقطتا انطلاقك ووجهتك مما يطلبه الراكب، تقدّمت رحلتك.',
  ),
  (
    Icons.payments_outlined,
    'السعر',
    'السعر الأقرب إلى المعتاد على المسار يتقدّم على السعر المرتفع.',
  ),
  (
    Icons.verified_user_outlined,
    'نقاط الثقة',
    'سائق أتمّ رحلاته ولم يُلغِها متأخّراً تتقدّم رحلاته.',
  ),
];

/// أين يقع سعر السائق من المقترح، وأثر ذلك في ظهور رحلته.
///
/// **لا وعظ ولا منع**: السائق حرّ في سعره — لكنه يستحقّ أن يعرف أن
/// النتائج مرتَّبة لا معروضة كيفما اتفق، وأن سعره أحد ما يرتّبها.
/// وكان يضع سعره ثم يتساءل لماذا لا تصله حجوزات.
class PriceRankingHint extends StatelessWidget {
  final int price;
  final int suggested;

  const PriceRankingHint({
    super.key,
    required this.price,
    required this.suggested,
  });

  /// موضع السعر على شريط من المقترح إلى السقف — بين 0 و1.
  double get _position {
    if (suggested <= 0) return 0;
    final ratio = price / suggested;

    // المقترح عند الثلث، والسقف (1.67× المقترح) عند الطرف
    if (ratio <= 1) return (ratio * 0.33).clamp(0.0, 0.33);
    final over = (ratio - 1) / (RidePriceRules.maxRatePerKm /
            RidePriceRules.suggestedRatePerKm -
        1);
    return (0.33 + over * 0.67).clamp(0.0, 1.0);
  }

  ({Color color, String label, IconData icon}) get _verdict {
    if (suggested <= 0) {
      return (
        color: MyColors.textSecondary,
        label: 'سيُرتَّب ظهور رحلتك مع غيرها',
        icon: Icons.info_outline_rounded
      );
    }

    final ratio = price / suggested;

    if (ratio <= 1.0) {
      return (
        color: MyColors.success,
        label: 'سعرك عند المقترح أو دونه — موضع جيّد بين النتائج',
        icon: Icons.trending_up_rounded
      );
    }
    if (ratio <= 1.15) {
      return (
        color: MyColors.primary,
        label: 'أعلى قليلاً من المقترح — أثره في الترتيب محدود',
        icon: Icons.horizontal_rule_rounded
      );
    }
    if (ratio <= 1.35) {
      return (
        color: MyColors.warning,
        label: 'أعلى من المقترح — قد تظهر بعد رحلات أقرب إليه',
        icon: Icons.trending_down_rounded
      );
    }
    return (
      color: MyColors.error,
      label: 'أعلى بكثير — الأرجح أن تظهر في آخر النتائج',
      icon: Icons.trending_down_rounded
    );
  }

  @override
  Widget build(BuildContext context) {
    final verdict = _verdict;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: MyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard_outlined,
                  size: 16.sp, color: MyColors.textSecondary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'موضع رحلتك في نتائج البحث',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: MyColors.textPrimary),
                ),
              ),
              _WhySheetButton(),
            ],
          ),
          SizedBox(height: 10.h),
          _PositionBar(position: _position, color: verdict.color),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(verdict.icon, size: 15.sp, color: verdict.color),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  verdict.label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: verdict.color, height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شريط متدرّج من الأخضر إلى الأحمر، وعلامة تقف عند موضع السعر.
class _PositionBar extends StatelessWidget {
  final double position;
  final Color color;

  const _PositionBar({required this.position, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const markerSize = 12.0;

        return SizedBox(
          height: 18.h,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Container(
                height: 6.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3.r),
                  // البداية يميناً في العربية: الأفضل موضعاً أولاً
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      MyColors.success.withValues(alpha: 0.55),
                      MyColors.warning.withValues(alpha: 0.55),
                      MyColors.error.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: (position * (width - markerSize)).clamp(
                  0.0,
                  width - markerSize,
                ),
                child: Container(
                  width: markerSize,
                  height: markerSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: MyColors.surface, width: 2),
                    boxShadow: [
                      BoxShadow(color: MyColors.shadowMedium, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WhySheetButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => showRankingCriteriaSheet(context),
      style: TextButton.styleFrom(
        minimumSize: Size(0, 30.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        'ما المعايير؟',
        style: AppTextStyles.labelSmall.copyWith(color: MyColors.primary),
      ),
    );
  }
}

/// شرح معايير الترتيب — يُفتح بطلب السائق لا يُفرض عليه.
Future<void> showRankingCriteriaSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const RankingCriteriaSheet(),
  );
}

class RankingCriteriaSheet extends StatelessWidget {
  const RankingCriteriaSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: MyColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Text('كيف تُرتَّب نتائج البحث؟',
                style: AppTextStyles.titleMedium),
            SizedBox(height: 6.h),
            Text(
              'لا تُعرض الرحلات كيفما اتفق: يرى الراكب أنسبها له أولاً، '
              'بحسب المعايير التالية.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: MyColors.textSecondary, height: 1.7),
            ),
            SizedBox(height: 18.h),
            for (final (icon, title, body) in kSearchRankingCriteria) ...[
              _CriterionRow(icon: icon, title: title, body: body),
              SizedBox(height: 14.h),
            ],
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: MyColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 16.sp, color: MyColors.accent),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'السعر معيار من عدّة معايير — ولك أن تختاره كما تشاء '
                      'ضمن الحدّ المسموح.',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: MyColors.textSecondary, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _CriterionRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MyColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 17.sp, color: MyColors.primary),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: 2.h),
              Text(
                body,
                style: AppTextStyles.labelSmall
                    .copyWith(color: MyColors.textSecondary, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
