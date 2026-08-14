import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';
import 'package:alatarekak/features/support/presantion/manger/complaint_detail_cubit/complaint_detail_cubit.dart';

class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({super.key});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  @override
  void initState() {
    super.initState();
    final id = Get.arguments as int;
    context.read<ComplaintDetailCubit>().loadComplaint(id);
  }

  String _formatDate(DateTime date) =>
      DateFormat('d MMMM yyyy - hh:mm a', 'ar').format(date.toLocal());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded,
              size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text('تفاصيل الشكوى', style: AppTextStyles.titleMedium.copyWith(color: MyColors.textOnDark)),
        centerTitle: true,
      ),
      body: BlocConsumer<ComplaintDetailCubit, ComplaintDetailState>(
        listener: (context, state) {
          // 404 — غير موجودة أو تخص مستخدماً آخر ← ارجع للقائمة
          if (state is ComplaintDetailNotFound) {
            // الرجوع أولاً وإلا ابتلع Get.back() مسارَ الإشعار
            Get.back();
            AppSnackBar.error('الشكوى غير موجودة');
          }
        },
        builder: (context, state) {
          if (state is ComplaintDetailLoading ||
              state is ComplaintDetailInitial) {
            return Center(
                child: CircularProgressIndicator(color: MyColors.primary));
          }
          if (state is ComplaintDetailFailure) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 52, color: MyColors.error),
                    SizedBox(height: 12.h),
                    Text(state.message,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: MyColors.textSecondary),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          if (state is! ComplaintDetailLoaded) return const SizedBox.shrink();

          final complaint = state.complaint;
          final status = complaint.status;
          final type = complaint.type;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ━━ بطاقة الحالة ━━
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: status.bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: status.color.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: status.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(status.icon, color: status.color, size: 22),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('حالة الشكوى',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: MyColors.textHint)),
                          SizedBox(height: 4.h),
                          Text(status.label,
                              style: AppTextStyles.titleMedium
                                  .copyWith(color: status.color)),
                        ],
                      ),
                    ],
                  ),
                ),

                // مؤشر الانتظار — للحالات النشطة فقط
                if (status.isOpen) ...[
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
                        Icon(Icons.hourglass_top_rounded,
                            color: MyColors.warning, size: 17),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'شكواك قيد المعالجة من قِبل فريق الدعم. سيتم إشعارك عند اتخاذ قرار.',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: MyColors.warning, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ━━ رد فريق الدعم ━━
                if (complaint.resolutionNotes != null &&
                    complaint.resolutionNotes!.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: MyColors.successLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: MyColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 12.h),
                          child: Row(
                            children: [
                              Icon(Icons.support_agent,
                                  color: MyColors.success, size: 20),
                              SizedBox(width: 8.w),
                              Text('رد فريق الدعم',
                                  style: AppTextStyles.labelLarge
                                      .copyWith(color: MyColors.success)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                          child: Text(
                            complaint.resolutionNotes!,
                            style:
                                AppTextStyles.bodyMedium.copyWith(height: 1.6),
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
                    boxShadow: [
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
                                color:
                                    MyColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.report_problem_outlined,
                                  color: MyColors.primary, size: 17),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(complaint.title,
                                  style: AppTextStyles.labelLarge),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 0, thickness: 0.5),
                      Padding(
                        padding: EdgeInsets.all(14.w),
                        child: Text(
                          complaint.description,
                          style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // ━━ المرفقات ━━
                if (complaint.attachments.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Text('المرفقات', style: AppTextStyles.labelLarge),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: complaint.attachments
                        .map((a) => _AttachmentTile(attachment: a))
                        .toList(),
                  ),
                ],

                SizedBox(height: 16.h),

                // ━━ بطاقة المعلومات ━━
                Container(
                  decoration: BoxDecoration(
                    color: MyColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
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
                          height: 0, thickness: 0.5, indent: 16, endIndent: 16),
                      _InfoRow(
                        icon: type.icon,
                        label: 'نوع الشكوى',
                        value: type.label,
                        valueColor: type.color,
                      ),
                      if (complaint.assignedToName != null) ...[
                        const Divider(
                            height: 0,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16),
                        _InfoRow(
                          icon: Icons.support_agent,
                          label: 'الموظف المسؤول',
                          value: complaint.assignedToName!,
                        ),
                      ],
                      if (complaint.submittedAt != null) ...[
                        const Divider(
                            height: 0,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'تاريخ التقديم',
                          value: _formatDate(complaint.submittedAt!),
                        ),
                      ],
                      if (status.isTerminal &&
                          complaint.resolvedAt != null) ...[
                        const Divider(
                            height: 0,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16),
                        _InfoRow(
                          icon: Icons.event_available_outlined,
                          label: 'تاريخ الحل',
                          value: _formatDate(complaint.resolvedAt!),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 24.h),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Attachment Tile — صور inline وPDF ببطاقة فتح خارجي
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _AttachmentTile extends StatelessWidget {
  final ComplaintAttachmentEntity attachment;
  const _AttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    if (attachment.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          attachment.url,
          width: 90.w,
          height: 90.w,
          fit: BoxFit.cover,
          errorBuilder: (context, e, s) => Container(
            width: 90.w,
            height: 90.w,
            color: MyColors.surfaceAlt,
            child: Icon(Icons.broken_image_outlined,
                color: MyColors.textHint),
          ),
        ),
      );
    }

    // PDF أو نوع آخر — بطاقة فتح في عارض خارجي
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(attachment.url),
          mode: LaunchMode.externalApplication),
      child: Container(
        width: 150.w,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: MyColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MyColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded,
                color: MyColors.error, size: 26),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.originalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall,
                  ),
                  Text(
                    '${attachment.sizeKb.toStringAsFixed(0)} KB',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: MyColors.textHint),
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
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                  color: valueColor ?? MyColors.textPrimary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
