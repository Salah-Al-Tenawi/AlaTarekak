import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';
import 'package:alatarekak/features/support/presantion/view/complaint_status_helper.dart';

class ComplaintDetailScreen extends StatelessWidget {
  const ComplaintDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final complaint = Get.arguments as ComplaintEntity;
    final sCfg = complaintStatusConfig(complaint.status);
    final type = complaint.type;

    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded,
              color: MyColors.primary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text('تفاصيل الشكوى', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ━━ بطاقة الحالة ━━
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: sCfg.bg,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: sCfg.color.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: sCfg.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(sCfg.icon, color: sCfg.color, size: 22),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('حالة الشكوى',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: MyColors.textHint)),
                      SizedBox(height: 4.h),
                      Text(sCfg.label,
                          style: AppTextStyles.titleMedium
                              .copyWith(color: sCfg.color)),
                    ],
                  ),
                ],
              ),
            ),

            // تنبيه الحالة unread
            if (complaint.status == 'unread') ...[
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF1565C0), size: 17),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'شكواك وصلت بنجاح ولم يطّلع عليها أحد بعد. سيبدأ فريق الدعم مراجعتها قريباً.',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFF1565C0), height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // تنبيه pending
            if (complaint.status == 'pending') ...[
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: MyColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: MyColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.hourglass_top_rounded,
                        color: MyColors.warning, size: 17),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'شكواك قيد المراجعة من قِبل فريق الدعم. سيتم إشعارك عند اتخاذ قرار.',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: MyColors.warning, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 16.h),

            // ━━ بطاقة الوصف ━━
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: MyColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: MyColors.shadowLight,
                      blurRadius: 8,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 12.h),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: MyColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                              Icons.report_problem_outlined,
                              color: MyColors.primary,
                              size: 17),
                        ),
                        SizedBox(width: 8.w),
                        Text('وصف المشكلة',
                            style: AppTextStyles.labelLarge),
                      ],
                    ),
                  ),
                  const Divider(height: 0, thickness: 0.5),
                  Padding(
                    padding: EdgeInsets.all(14.w),
                    child: Text(
                      complaint.description,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // ━━ بطاقة المعلومات ━━
            Container(
              decoration: BoxDecoration(
                color: MyColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: MyColors.shadowLight,
                      blurRadius: 8,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.tag_rounded,
                    label: 'رقم الشكوى',
                    value: '#${complaint.id}',
                  ),
                  const Divider(
                      height: 0,
                      thickness: 0.5,
                      indent: 16,
                      endIndent: 16),
                  _InfoRow(
                    icon: type.icon,
                    label: 'نوع الشكوى',
                    value: type.label,
                    valueColor: type.color,
                  ),
                  const Divider(
                      height: 0,
                      thickness: 0.5,
                      indent: 16,
                      endIndent: 16),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'تاريخ التقديم',
                    value: complaint.createdAt,
                  ),
                  const Divider(
                      height: 0,
                      thickness: 0.5,
                      indent: 16,
                      endIndent: 16),
                  _InfoRow(
                    icon: sCfg.icon,
                    label: 'الحالة',
                    value: sCfg.label,
                    valueColor: sCfg.color,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Info Row
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: MyColors.textHint),
          SizedBox(width: 10.w),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: MyColors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
                color: valueColor ?? MyColors.textPrimary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
