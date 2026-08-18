import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:alatarekak/features/policy/domain/entity/policy_content.dart';
import 'package:alatarekak/features/policy/presantion/manger/cubit/policy_cubit.dart';
import 'package:alatarekak/features/policy/text/pollicy_text.dart';
import 'package:alatarekak/features/policy/widget/policy_section_view.dart';

/// شاشة سياسات التطبيق: الخصوصية والإلغاء في تبويبين.
///
/// المحتوى يأتي من `GET /policies` — يحرّره الأدمن من لوحته. انظر
/// [PolicyCubit] في ترتيب المصادر الثلاثة وسبب غياب شاشة الخطأ.
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
          elevation: 0,
          centerTitle: true,
          // bodyLarge يحمل لون النصّ الداكن، فيتجاوز foregroundColor أعلاه
          title: Text(
            'سياسات التطبيق',
            style: AppTextStyles.bodyLarge.copyWith(color: MyColors.textOnDark),
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
        body: BlocBuilder<PolicyCubit, PolicyState>(
          builder: (context, state) {
            final loaded = state is PolicyLoaded ? state : null;
            final content = loaded?.content ?? PolicyContent.builtIn;
            final stale = loaded == null || !loaded.fresh;

            return TabBarView(
              children: [
                _PolicyTab(
                  document: content.privacy,
                  stale: stale,
                  footer: 'تسري هذه السياسة على كل من يستخدم تطبيق '
                      '«${content.settings.appName}». لأي استفسار راسلنا على '
                      '${content.settings.contactEmail}.',
                ),
                _PolicyTab(document: content.cancellation, stale: stale),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PolicyTab extends StatelessWidget {
  final PolicyDocument document;
  final String? footer;

  /// النسخة المعروضة ليست من الخادم في هذه الجلسة.
  final bool stale;

  const _PolicyTab({
    required this.document,
    required this.stale,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    // السحب للتحديث: المستخدم الذي يرى تنبيه «نسخة محفوظة» يحتاج سبيلاً
    // لإعادة المحاولة بعد عودة الشبكة.
    return RefreshIndicator(
      onRefresh: () => context.read<PolicyCubit>().load(force: true),
      child: FadeSlideIn(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 32.h),
          children: [
            _LastUpdatedChip(label: document.lastUpdatedLabel),
            if (stale) ...[
              SizedBox(height: 10.h),
              const _StaleNote(),
            ],
            SizedBox(height: 18.h),
            ...document.sections.asMap().entries.map(
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
      ),
    );
  }
}

/// تنبيه هادئ لا شاشة خطأ: المعروض صالح، لكنه قد لا يكون آخر ما نشره
/// الأدمن. إخفاء ذلك يوهم المستخدم أنه يقرأ النسخة السارية.
class _StaleNote extends StatelessWidget {
  const _StaleNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: MyColors.warningLight,
        borderRadius: BorderRadius.circular(12.r),
        border:
            Border.all(color: MyColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 16.sp, color: MyColors.warning),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'تعذّر تحديث السياسة الآن — تعرض نسخة محفوظة. اسحب للتحديث.',
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastUpdatedChip extends StatelessWidget {
  final String label;

  const _LastUpdatedChip({required this.label});

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
              'آخر تحديث: ${label.isEmpty ? PolicyText.lastUpdated : label}',
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
