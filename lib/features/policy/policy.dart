import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:alatarekak/features/policy/text/pollicy_text.dart';
import 'package:alatarekak/features/policy/widget/policy_section_view.dart';

/// شاشة سياسات التطبيق: الخصوصية والإلغاء في تبويبين.
///
/// [initialTab] يفتح التبويب المطلوب مباشرة (0 خصوصية، 1 إلغاء) —
/// يُمرَّر عبر Get.arguments.
class Policy extends StatelessWidget {
  const Policy({super.key});

  @override
  Widget build(BuildContext context) {
    final initialTab = Get.arguments is int ? Get.arguments as int : 0;

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.clamp(0, 1),
      child: Scaffold(
        backgroundColor: MyColors.background,
        appBar: AppBar(
          backgroundColor: MyColors.primary,
          foregroundColor: MyColors.textOnDark,
          elevation: 0,
          centerTitle: true,
          // bodyLarge يحمل لون النصّ الداكن، فيتجاوز foregroundColor أعلاه
          title: Text(
            'سياسات التطبيق',
            style: AppTextStyles.bodyLarge
                .copyWith(color: MyColors.textOnDark),
          ),
          bottom: TabBar(
            indicatorColor: MyColors.accent,
            indicatorWeight: 3,
            labelColor: MyColors.textOnDark,
            unselectedLabelColor: MyColors.textOnDark.withValues(alpha: 0.6),
            labelStyle: AppTextStyles.labelLarge,
            tabs: const [
              Tab(text: 'الخصوصية'),
              Tab(text: 'الإلغاء والاسترداد'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PolicyTab(
              sections: PolicyText.privacy,
              footer:
                  'تسري هذه السياسة على كل من يستخدم تطبيق «${PolicyText.appName}». '
                  'لأي استفسار راسلنا على ${PolicyText.contactEmail}.',
            ),
            _PolicyTab(sections: PolicyText.cancellation),
          ],
        ),
      ),
    );
  }
}

class _PolicyTab extends StatelessWidget {
  final List<PolicySection> sections;
  final String? footer;

  const _PolicyTab({required this.sections, this.footer});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 32.h),
        children: [
          _LastUpdatedChip(),
          SizedBox(height: 18.h),
          ...sections.asMap().entries.map(
                (e) => PolicySectionView(
                  section: e.value,
                  index: e.key + 1,
                ),
              ),
          if (footer != null) ...[
            Divider(color: MyColors.divider, height: 24.h),
            Text(
              footer!,
              style: AppTextStyles.labelSmall.copyWith(
                color: MyColors.textSecondary,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _LastUpdatedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: MyColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: MyColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.update_rounded, size: 14.sp, color: MyColors.accent),
            SizedBox(width: 6.w),
            Text(
              'آخر تحديث: ${PolicyText.lastUpdated}',
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
