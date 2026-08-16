import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/trip_details/presantaion/view/widget/status_trip.dart';

/// لبنات بطاقة الرحلة — مصدر واحد لشاشتَي البحث و«رحلاتي» وتفاصيل الرحلة.
///
/// كانت كل شاشة تكرّر الصورة والشارة والسطر بمقاسات وأنصاف أقطار مختلفة،
/// فتبدو الرحلة الواحدة بثلاثة أشكال. توحيدها هنا يجعل تعديل الهوية
/// البصرية في موضع واحد، ويمنع عودة التفاوت مع أول إضافة.

/// صورة السائق بإطار من لون الهوية.
class TripAvatar extends StatelessWidget {
  final String? avatar;
  final double size;
  final VoidCallback? onTap;

  const TripAvatar({super.key, required this.avatar, this.size = 42, this.onTap});

  @override
  Widget build(BuildContext context) {
    final url = avatar?.trim() ?? '';
    // الصورة تُرسم بـ Image.network لا بـ DecorationImage: الأخيرة لا
    // تملك بديلاً عند فشل التحميل، فيبقى مكان الصورة فارغاً تماماً إن كان
    // الرابط مكسوراً أو نسبياً أو الخادم غير متاح.
    final hasImage = url.isNotEmpty && url.startsWith('http');

    final circle = Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: MyColors.primary.withValues(alpha: 0.25),
          width: 2,
        ),
        color: MyColors.primary.withValues(alpha: 0.08),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => _placeholder(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _placeholder(),
            )
          : _placeholder(),
    );

    if (onTap == null) return circle;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: circle,
    );
  }

  Widget _placeholder() => Center(
        child: Icon(Icons.person_rounded,
            color: MyColors.primary, size: (size * 0.48).sp),
      );
}

/// شارة حالة الرحلة — لونها ونصّها من [getStatusInfo] فلا يتفرّق التصنيف.
class TripStatusBadge extends StatelessWidget {
  final String? status;

  /// المصمَتة للعناوين البارزة (رأس صفحة التفاصيل)، والشفافة داخل البطاقات.
  final bool solid;

  const TripStatusBadge({super.key, required this.status, this.solid = false});

  @override
  Widget build(BuildContext context) {
    final info = getStatusInfo(status);
    // حالة لم تصل أو لم تُطابَق: الشارة تُخفى بدل عرض «غير معروف»
    if (!info.isKnown) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: solid ? info.color : info.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: solid
            ? null
            : Border.all(color: info.color.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        info.text,
        style: TextStyle(
          color: solid ? Colors.white : info.color,
          fontWeight: FontWeight.w600,
          fontSize: 11.sp,
        ),
      ),
    );
  }
}

/// رقاقة معلومة صغيرة: أيقونة ونصّ بلون واحد وخلفية شفافة منه.
class TripInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  /// يملأ العرض المتاح داخل [Expanded]؛ وإلا يأخذ عرض محتواه.
  final bool expand;

  const TripInfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// سطر موقع واحد — نقطة انطلاق أو وجهة.
class TripLocationLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final String? label;

  const TripLocationLine({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.text,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: label == null ? 0 : 2.h),
          child: Icon(icon, size: 16.sp, color: iconColor),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null) ...[
                Text(label!,
                    style: AppTextStyles.labelSmall
                        .copyWith(fontSize: 10.sp, color: MyColors.textHint)),
                SizedBox(height: 2.h),
              ],
              Text(
                text.isEmpty ? '—' : text,
                style: AppTextStyles.bodySmall.copyWith(
                  color: MyColors.textPrimary,
                  fontSize: 13.sp,
                  fontWeight: label == null ? FontWeight.w400 : FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// الخيط الواصل بين نقطتَي المسار — يُقرأ المسار كخطّ واحد لا كسطرين.
class TripRouteConnector extends StatelessWidget {
  final double height;
  const TripRouteConnector({super.key, this.height = 18});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Container(
        width: 2,
        height: height.h,
        margin: EdgeInsets.symmetric(vertical: 4.h),
        color: MyColors.border,
      ),
    );
  }
}

/// البطاقة الحاوية الموحّدة: حدّ خفيف وزاوية واحدة وظلّ واحد.
class TripSectionCard extends StatelessWidget {
  final String? title;
  final IconData? titleIcon;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Widget? trailing;

  const TripSectionCard({
    super.key,
    this.title,
    this.titleIcon,
    required this.child,
    this.padding,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18.r);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: radius,
        border: Border.all(color: MyColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: MyColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: padding ?? EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Row(
                    children: [
                      if (titleIcon != null) ...[
                        Icon(titleIcon, size: 16.sp, color: MyColors.accent),
                        SizedBox(width: 8.w),
                      ],
                      Expanded(
                        child: Text(
                          title!,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontSize: 13.sp,
                            color: MyColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
