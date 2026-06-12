import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/profiles/data/model/documents_model.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// args = { 'status': String, 'userType': String, 'documents': DocumentsModel? }
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ProfileDriverVerificationScreen extends StatelessWidget {
  const ProfileDriverVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    String status = 'none';
    String userType = 'passenger';
    DocumentsModel? documents;

    if (args is Map<String, dynamic>) {
      status = (args['status'] as String? ?? 'none').toLowerCase();
      userType = (args['userType'] as String? ?? 'passenger').toLowerCase();
      documents = args['documents'] as DocumentsModel?;
    }

    final isDriver = userType == 'driver';

    return Scaffold(
      backgroundColor: MyColors.background,
      body: Column(
        children: [
          _StatusHeader(status: status, isDriver: isDriver),
          Expanded(
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: _buildBody(status, isDriver, documents),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      String status, bool isDriver, DocumentsModel? documents) {
    switch (status) {
      case 'approved':
        return _ApprovedBody(isDriver: isDriver, documents: documents);
      case 'pending':
        return _PendingBody(isDriver: isDriver, documents: documents);
      case 'rejected':
        return _RejectedBody(isDriver: isDriver);
      default:
        return _NoneBody(isDriver: isDriver);
    }
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _StatusHeader extends StatelessWidget {
  final String status;
  final bool isDriver;
  const _StatusHeader({required this.status, required this.isDriver});

  @override
  Widget build(BuildContext context) {
    final cfg = _headerConfig(status);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cfg.gradientColors,
        ),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 28.h),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 20.sp),
                  onPressed: () => Get.back(),
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 2),
                ),
                child: Icon(cfg.icon, color: Colors.white, size: 30.sp),
              ),
              SizedBox(height: 12.h),
              Text(
                cfg.title,
                style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: 6.h),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Text(
                  isDriver ? 'توثيق كسائق' : 'توثيق كراكب',
                  style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  _HeaderConfig _headerConfig(String status) {
    switch (status) {
      case 'approved':
        return _HeaderConfig(
          gradientColors: const [Color(0xFF1B5E20), MyColors.success],
          icon: Icons.verified_rounded,
          title: 'تم التوثيق بنجاح',
        );
      case 'pending':
        return _HeaderConfig(
          gradientColors: const [Color(0xFFE65100), MyColors.warning],
          icon: Icons.hourglass_top_rounded,
          title: 'طلبك قيد المراجعة',
        );
      case 'rejected':
        return _HeaderConfig(
          gradientColors: const [Color(0xFFB71C1C), MyColors.error],
          icon: Icons.cancel_outlined,
          title: 'تم رفض الطلب',
        );
      default:
        return _HeaderConfig(
          gradientColors: const [MyColors.navy, MyColors.primary, MyColors.blue],
          icon: Icons.badge_outlined,
          title: 'توثيق الحساب',
        );
    }
  }
}

class _HeaderConfig {
  final List<Color> gradientColors;
  final IconData icon;
  final String title;
  const _HeaderConfig(
      {required this.gradientColors,
      required this.icon,
      required this.title});
}

// ─── حالة: غير موثق ──────────────────────────────────────────────────────────

class _NoneBody extends StatelessWidget {
  final bool isDriver;
  const _NoneBody({required this.isDriver});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoNote(
          icon: Icons.info_outline_rounded,
          color: MyColors.primary,
          bgColor: MyColors.primary.withValues(alpha: 0.07),
          text: isDriver
              ? 'لم يتم توثيق حسابك كسائق بعد. التوثيق ضروري لإنشاء الرحلات وبناء ثقة الركاب.'
              : 'لم يتم توثيق حسابك بعد. التوثيق يضمن بيئة آمنة لجميع المستخدمين.',
        ),
        SizedBox(height: 24.h),
        _SectionTitle(title: 'لماذا التوثيق؟'),
        SizedBox(height: 12.h),
        _BenefitCard(
          icon: Icons.security_rounded,
          color: MyColors.primary,
          title: 'أمان أكبر',
          subtitle: 'بيئة موثوقة لجميع المستخدمين',
        ),
        SizedBox(height: 8.h),
        _BenefitCard(
          icon: Icons.thumb_up_alt_outlined,
          color: MyColors.accent,
          title: 'ثقة أعلى',
          subtitle: 'يظهر شارة التوثيق على ملفك الشخصي',
        ),
        SizedBox(height: 8.h),
        _BenefitCard(
          icon: Icons.lock_open_rounded,
          color: MyColors.success,
          title: 'وصول كامل',
          subtitle: isDriver
              ? 'إنشاء رحلات وتلقي الحجوزات بلا قيود'
              : 'حجز الرحلات بلا قيود',
        ),
        SizedBox(height: 32.h),
        _PrimaryButton(
          label: 'بدء عملية التوثيق',
          icon: Icons.arrow_back_rounded,
          color: MyColors.primary,
          onTap: () => Get.toNamed(
            RouteName.verfiyUser,
            arguments: isDriver ? 'driver' : 'passenger',
          ),
        ),
        SizedBox(height: 12.h),
        _SecondaryButton(
          label: 'لاحقاً',
          onTap: () => Get.back(),
        ),
      ],
    );
  }
}

// ─── حالة: قيد المراجعة ───────────────────────────────────────────────────────

class _PendingBody extends StatelessWidget {
  final bool isDriver;
  final DocumentsModel? documents;
  const _PendingBody({required this.isDriver, required this.documents});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoNote(
          icon: Icons.access_time_rounded,
          color: MyColors.warning,
          bgColor: MyColors.warningLight,
          text:
              'تم استلام مستنداتك بنجاح. يستغرق الأمر ما بين 24 إلى 48 ساعة عمل لإتمام المراجعة.',
        ),
        SizedBox(height: 20.h),
        _SectionTitle(title: 'المستندات المقدمة'),
        SizedBox(height: 12.h),
        _DocumentsCard(isDriver: isDriver, documents: documents),
        SizedBox(height: 20.h),
        _SectionTitle(title: 'الخطوات القادمة'),
        SizedBox(height: 12.h),
        _Timeline(steps: const [
          _TimelineStep(
              label: 'رفع المستندات',
              done: true,
              current: false),
          _TimelineStep(
              label: 'التحقق الأمني',
              done: false,
              current: true),
          _TimelineStep(
              label: 'تفعيل الحساب',
              done: false,
              current: false),
        ]),
        SizedBox(height: 32.h),
        _PrimaryButton(
          label: 'العودة إلى الملف الشخصي',
          icon: Icons.person_outline_rounded,
          color: MyColors.warning,
          onTap: () => Get.back(),
        ),
      ],
    );
  }
}

// ─── حالة: موثق ───────────────────────────────────────────────────────────────

class _ApprovedBody extends StatelessWidget {
  final bool isDriver;
  final DocumentsModel? documents;
  const _ApprovedBody({required this.isDriver, required this.documents});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoNote(
          icon: Icons.verified_rounded,
          color: MyColors.success,
          bgColor: MyColors.successLight,
          text: isDriver
              ? 'تهانينا! تم توثيق حسابك كسائق. يمكنك الآن إنشاء الرحلات وتلقي الحجوزات.'
              : 'تهانينا! تم توثيق حسابك. يمكنك الآن الاستمتاع بجميع ميزات التطبيق.',
        ),
        SizedBox(height: 20.h),
        _SectionTitle(title: 'المستندات الموثقة'),
        SizedBox(height: 12.h),
        _DocumentsCard(isDriver: isDriver, documents: documents),
        SizedBox(height: 32.h),
        _PrimaryButton(
          label: 'العودة إلى الملف الشخصي',
          icon: Icons.person_outline_rounded,
          color: MyColors.success,
          onTap: () => Get.back(),
        ),
      ],
    );
  }
}

// ─── حالة: مرفوض ─────────────────────────────────────────────────────────────

class _RejectedBody extends StatelessWidget {
  final bool isDriver;
  const _RejectedBody({required this.isDriver});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoNote(
          icon: Icons.error_outline_rounded,
          color: MyColors.error,
          bgColor: MyColors.errorLight,
          text:
              'للأسف، تم رفض طلب التوثيق. قد يكون السبب صورة غير واضحة أو بيانات غير مطابقة. يرجى إعادة رفع المستندات بصورة واضحة.',
        ),
        SizedBox(height: 24.h),
        _SectionTitle(title: 'ماذا تفعل الآن؟'),
        SizedBox(height: 12.h),
        _BenefitCard(
          icon: Icons.photo_camera_outlined,
          color: MyColors.primary,
          title: 'صور واضحة',
          subtitle: 'تأكد من وضوح الصورة وإضاءتها',
        ),
        SizedBox(height: 8.h),
        _BenefitCard(
          icon: Icons.crop_rotate_rounded,
          color: MyColors.accent,
          title: 'المستند كاملاً',
          subtitle: 'يجب ظهور جميع حواف البطاقة في الصورة',
        ),
        SizedBox(height: 8.h),
        _BenefitCard(
          icon: Icons.text_fields_rounded,
          color: MyColors.success,
          title: 'نص مقروء',
          subtitle: 'تأكد من وضوح جميع البيانات المكتوبة',
        ),
        SizedBox(height: 32.h),
        _PrimaryButton(
          label: 'إعادة التقديم',
          icon: Icons.refresh_rounded,
          color: MyColors.error,
          onTap: () => Get.toNamed(
            RouteName.verfiyUser,
            arguments: isDriver ? 'driver' : 'passenger',
          ),
        ),
        SizedBox(height: 12.h),
        _SecondaryButton(
          label: 'العودة',
          onTap: () => Get.back(),
        ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _DocumentsCard extends StatelessWidget {
  final bool isDriver;
  final DocumentsModel? documents;
  const _DocumentsCard({required this.isDriver, required this.documents});

  @override
  Widget build(BuildContext context) {
    final items = [
      _DocItem(
          label: 'بطاقة الهوية — الوجه الأمامي',
          icon: Icons.credit_card_rounded,
          uploaded: documents?.faceIdPic != null),
      _DocItem(
          label: 'بطاقة الهوية — الوجه الخلفي',
          icon: Icons.credit_card_outlined,
          uploaded: documents?.backIdPic != null),
      if (isDriver) ...[
        _DocItem(
            label: 'رخصة القيادة',
            icon: Icons.drive_eta_outlined,
            uploaded: documents?.licensePic != null),
        _DocItem(
            label: 'فحص السيارة',
            icon: Icons.car_repair_outlined,
            uploaded: documents?.mechanicCardPic != null),
      ],
    ];

    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [
          BoxShadow(
              color: MyColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(
                  height: 1,
                  thickness: 1,
                  color: MyColors.divider,
                  indent: 16,
                  endIndent: 16),
            _DocStatusRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _DocItem {
  final String label;
  final IconData icon;
  final bool uploaded;
  const _DocItem(
      {required this.label, required this.icon, required this.uploaded});
}

class _DocStatusRow extends StatelessWidget {
  final _DocItem item;
  const _DocStatusRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: MyColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(item.icon, size: 20.sp, color: MyColors.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(item.label, style: AppTextStyles.labelLarge),
          ),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: item.uploaded
                  ? MyColors.successLight
                  : MyColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.uploaded
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 14.sp,
                  color: item.uploaded
                      ? MyColors.success
                      : MyColors.textHint,
                ),
                SizedBox(width: 4.w),
                Text(
                  item.uploaded ? 'تم الرفع' : 'غير مرفوع',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10.sp,
                    color: item.uploaded
                        ? MyColors.success
                        : MyColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<_TimelineStep> steps;
  const _Timeline({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [
          BoxShadow(
              color: MyColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _TimelineItem(step: steps[i], isLast: i == steps.length - 1),
          ],
        ],
      ),
    );
  }
}

class _TimelineStep {
  final String label;
  final bool done;
  final bool current;
  const _TimelineStep(
      {required this.label, required this.done, required this.current});
}

class _TimelineItem extends StatelessWidget {
  final _TimelineStep step;
  final bool isLast;
  const _TimelineItem({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = step.done
        ? MyColors.success
        : step.current
            ? MyColors.warning
            : MyColors.textHint;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28.r,
              height: 28.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                step.done
                    ? Icons.check_rounded
                    : step.current
                        ? Icons.circle
                        : Icons.circle_outlined,
                size: 14.sp,
                color: color,
              ),
            ),
            if (!isLast)
              Container(
                  width: 2,
                  height: 28.h,
                  color: MyColors.border),
          ],
        ),
        SizedBox(width: 12.w),
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.label,
                style: AppTextStyles.labelLarge.copyWith(color: color),
              ),
              if (step.current)
                Text(
                  'جارٍ المراجعة...',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: MyColors.textSecondary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _BenefitCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [
          BoxShadow(
              color: MyColors.shadowLight,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: MyColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 3.w,
            height: 18.h,
            decoration: BoxDecoration(
                color: MyColors.accent,
                borderRadius: BorderRadius.circular(2.r))),
        SizedBox(width: 8.w),
        Text(title, style: AppTextStyles.titleMedium),
      ],
    );
  }
}

class _InfoNote extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String text;
  const _InfoNote({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.labelSmall.copyWith(
                  color: MyColors.textSecondary, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.sp),
            SizedBox(width: 8.w),
            Text(label, style: AppTextStyles.buttonLarge),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: TextButton(
        onPressed: onTap,
        child: Text(
          label,
          style: AppTextStyles.labelLarge
              .copyWith(color: MyColors.textSecondary),
        ),
      ),
    );
  }
}
