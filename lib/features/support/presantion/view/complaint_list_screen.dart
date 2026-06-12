import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';
import 'package:alatarekak/features/support/presantion/manger/complaint_list_cubit/complaint_list_cubit.dart';
import 'package:alatarekak/features/support/presantion/view/complaint_status_helper.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ComplaintListCubit>().loadComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded,
              color: MyColors.primary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text('شكاواي', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      body: BlocBuilder<ComplaintListCubit, ComplaintListState>(
        builder: (context, state) {
          if (state is ComplaintListLoading) {
            return Center(
              child: CircularProgressIndicator(color: MyColors.primary),
            );
          }
          if (state is ComplaintListFailure) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<ComplaintListCubit>().loadComplaints(),
            );
          }
          if (state is ComplaintListLoaded) {
            if (state.complaints.isEmpty) return const _EmptyView();
            return RefreshIndicator(
              color: MyColors.primary,
              onRefresh: () =>
                  context.read<ComplaintListCubit>().loadComplaints(),
              child: ListView.separated(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                itemCount: state.complaints.length,
                separatorBuilder: (context, i) => SizedBox(height: 10.h),
                itemBuilder: (context, i) =>
                    _ComplaintCard(complaint: state.complaints[i]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Complaint Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _ComplaintCard extends StatelessWidget {
  final ComplaintEntity complaint;
  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final sCfg = complaintStatusConfig(complaint.status);
    final type = complaint.type;
    final isUnread = complaint.status == 'unread';

    return InkWell(
      onTap: () => Get.toNamed(RouteName.complaintDetail, arguments: complaint),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: MyColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: isUnread
              ? Border.all(
                  color: Color(0xFF1565C0).withValues(alpha: 0.3),
                  width: 1)
              : null,
          boxShadow: [
            BoxShadow(
                color: MyColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أيقونة نوع الشكوى
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: type.bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(type.icon, color: type.color, size: 20),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // نوع الشكوى
                  Text(type.label,
                      style: AppTextStyles.labelMedium
                          .copyWith(color: type.color)),
                  SizedBox(height: 3.h),
                  // معاينة الوصف
                  Text(
                    complaint.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: MyColors.textSecondary),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      // شارة الحالة
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 7.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: sCfg.bg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(sCfg.icon, size: 11, color: sCfg.color),
                            SizedBox(width: 3.w),
                            Text(sCfg.label,
                                style: AppTextStyles.labelSmall.copyWith(
                                    color: sCfg.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.sp)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        complaint.createdAt,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: MyColors.textHint),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            Icon(Icons.arrow_back_ios_rounded,
                size: 14, color: MyColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Empty & Error
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 64,
              color: MyColors.textHint.withValues(alpha: 0.5)),
          SizedBox(height: 16.h),
          Text('لا توجد شكاوى بعد',
              style: AppTextStyles.titleMedium
                  .copyWith(color: MyColors.textSecondary)),
          SizedBox(height: 6.h),
          Text('شكاواك المُرسَلة ستظهر هنا',
              style: AppTextStyles.bodySmall
                  .copyWith(color: MyColors.textHint)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 52, color: MyColors.error),
            SizedBox(height: 12.h),
            Text(message,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: MyColors.textSecondary),
                textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text('إعادة المحاولة',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
