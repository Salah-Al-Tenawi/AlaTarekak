import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

/// أقصى عدد مقاعد لمركبة.
///
/// يطابق حدّ الخادم في الحجز («لا يمكن حجز أكثر من 8 مقاعد»). وكان حقل
/// المقاعد نصّاً حرّاً يقبل 40 أو 1000، فتُرفض المركبة عند الحفظ أو
/// تُنشأ رحلة بمقاعد لا وجود لها.
const int kMaxCarSeats = 8;
const int kMinCarSeats = 1;

/// عدّاد المقاعد: زرّا نقص وزيادة ورقم بينهما.
///
/// **عدّاد لا حقل كتابة:** المدى من 1 إلى 8، وفتح لوحة أرقام لإدخال رقم
/// من خانة واحدة ضمن مدى ضيّق تكليفٌ بلا مقابل — ويسمح بما لا يصحّ.
/// وحدّان يحرسان القيمة هنا خير من رسالة رفض بعد الحفظ.
class SeatsStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  final String label;
  final IconData icon;

  final int min;
  final int max;

  const SeatsStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'عدد المقاعد',
    this.icon = Icons.event_seat_rounded,
    this.min = kMinCarSeats,
    this.max = kMaxCarSeats,
  });

  @override
  Widget build(BuildContext context) {
    final current = value.clamp(min, max);
    final canDecrease = current > min;
    final canIncrease = current < max;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: MyColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: MyColors.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  'من $min إلى $max',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: MyColors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: canDecrease,
            tooltip: 'إنقاص',
            onTap: () => onChanged(current - 1),
          ),
          Container(
            constraints: BoxConstraints(minWidth: 40.w),
            alignment: Alignment.center,
            child: Text(
              '$current',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: MyColors.textPrimary,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            enabled: canIncrease,
            tooltip: 'زيادة',
            onTap: () => onChanged(current + 1),
          ),
        ],
      ),
    );
  }
}

/// زرّ خطوة واحدة — يُعطَّل عند الحدّ بدل أن يُضغط بلا أثر.
class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final String tooltip;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? MyColors.primary : MyColors.textHint;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? MyColors.primary.withValues(alpha: 0.08)
            : MyColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
          side: BorderSide(color: enabled ? color.withValues(alpha: 0.3) : MyColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: EdgeInsets.all(7.w),
            child: Icon(icon, size: 18.sp, color: color),
          ),
        ),
      ),
    );
  }
}
