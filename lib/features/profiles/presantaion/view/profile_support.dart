import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:alatarekak/features/policy/domain/entity/policy_content.dart';
import 'package:alatarekak/features/policy/presantion/manger/cubit/policy_cubit.dart';
import 'package:alatarekak/features/support/domain/entity/faq_entry.dart';

/// مركز المساعدة: الأسئلة الشائعة، ومنها طريق مباشر إلى الدعم البشري.
class ProfileSupportScreen extends StatelessWidget {
  const ProfileSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "مركز المساعدة",
          style: AppTextStyles.titleMedium.copyWith(color: MyColors.textOnDark),
        ),
        centerTitle: true,
      ),
      // الأسئلة يحرّرها الأدمن مع السياسات على `GET /policies` — انظر
      // PolicyCubit في ترتيب المصادر وسبب غياب شاشة الخطأ.
      body: BlocBuilder<PolicyCubit, PolicyState>(
        builder: (context, state) {
          final content = state is PolicyLoaded
              ? state.content
              : PolicyContent.builtIn;

          return RefreshIndicator(
            onRefresh: () => context.read<PolicyCubit>().load(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
              children: [
                ...content.faq.asMap().entries.map(
                  (e) => StaggeredItem(
                    index: e.key,
                    child: _FaqGroupCard(group: e.value),
                  ),
                ),
                SizedBox(height: 8.h),
                const _StillNeedHelp(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FaqGroupCard extends StatelessWidget {
  final FaqGroup group;
  const _FaqGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    // Material لا Container: صندوق ملوَّن فوق ExpansionTile يحجب تموّج
    // لمسه — ونبّه عليه Flutter 3.47 بتأكيد صريح.
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MyColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: MyColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 6.h),
              child: Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: MyColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Icon(
                      group.icon,
                      size: 17.sp,
                      color: MyColors.primary,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(group.title, style: AppTextStyles.labelLarge),
                ],
              ),
            ),
            ...group.entries.map((e) => _FaqTile(entry: e)),
            SizedBox(height: 6.h),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final FaqEntry entry;
  const _FaqTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Theme(
      // إزالة الخطوط الافتراضية فوق العنصر وتحته داخل البطاقة
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 14.w),
        childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: MyColors.primary,
        collapsedIconColor: MyColors.textHint,
        title: Text(
          entry.question,
          style: AppTextStyles.bodySmall.copyWith(
            color: MyColors.textPrimary,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        children: [
          Text(
            entry.answer,
            style: AppTextStyles.bodySmall.copyWith(
              color: MyColors.textSecondary,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// مخرج للمستخدم حين لا يجد سؤاله — يمنع أن يصبح مركز المساعدة طريقاً مسدوداً.
class _StillNeedHelp extends StatelessWidget {
  const _StillNeedHelp();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MyColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MyColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.headset_mic_outlined,
            size: 28.sp,
            color: MyColors.primary,
          ),
          SizedBox(height: 10.h),
          Text(
            'لم تجد إجابتك؟',
            style: AppTextStyles.labelLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            'راسل فريق الدعم مباشرة، أو أرسل شكوى إن كانت المشكلة تخصّ رحلة '
            'أو مبلغاً محدداً.',
            style: AppTextStyles.bodySmall.copyWith(
              color: MyColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed(RouteName.profileContactUs),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.primary,
                    foregroundColor: MyColors.textOnDark,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(Icons.chat_outlined, size: 17.sp),
                  label: Text(
                    'تواصل مع الدعم',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: MyColors.textOnDark,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed(RouteName.profileComplaint),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MyColors.primary,
                    side: BorderSide(color: MyColors.primary),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Icon(Icons.report_problem_outlined, size: 17.sp),
                  label: Text(
                    'تقديم شكوى',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: MyColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
