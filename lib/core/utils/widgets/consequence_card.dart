import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/class/cancel_policy.dart';

/// بطاقة «ماذا يقع إن أتممتَ هذا» — تُعرض قبل الإجراء لا بعده.
///
/// كانت كلفة الإلغاء تُقال بعد وقوعه: «تم استرداد كذا». وهو ترتيبٌ
/// يحرم المستخدم من القرار — يعرف ما خسره حين لا يعود بيده شيء. صارت
/// تُحسب من [CancelPolicy] وتُعرض قبل الزرّ.
///
/// **النبرة جزء من المعلومة**: خطٌّ أخضر على «لن تخسر شيئاً» وأحمر على
/// «لا يُعاد شيء» يُقرأ قبل النصّ نفسه. ولا تحذير حيث لا كلفة — بطاقةٌ
/// حمراء على إلغاءٍ مجانيّ تُفزع بلا سبب.
class ConsequenceCard extends StatelessWidget {
  final List<Consequence> lines;

  /// عنوان اختياري فوق الأسطر — «ماذا يحدث الآن؟» وما شابه.
  final String? title;

  const ConsequenceCard({super.key, required this.lines, this.title});

  /// أشدّ النبرات في البطاقة — لونُ حدّها وخلفيّتها.
  ConsequenceTone get _dominant {
    if (lines.any((l) => l.tone == ConsequenceTone.bad)) {
      return ConsequenceTone.bad;
    }
    if (lines.any((l) => l.tone == ConsequenceTone.warning)) {
      return ConsequenceTone.warning;
    }
    if (lines.every((l) => l.tone == ConsequenceTone.good)) {
      return ConsequenceTone.good;
    }
    return ConsequenceTone.neutral;
  }

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    final accent = _color(_dominant);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            SizedBox(height: 8.h),
          ],
          for (int i = 0; i < lines.length; i++) ...[
            if (i > 0) SizedBox(height: 7.h),
            _Line(line: lines[i]),
          ],
        ],
      ),
    );
  }

  static Color _color(ConsequenceTone tone) => switch (tone) {
        ConsequenceTone.good => MyColors.success,
        ConsequenceTone.warning => MyColors.warning,
        ConsequenceTone.bad => MyColors.error,
        ConsequenceTone.neutral => MyColors.textSecondary,
      };

  static IconData _icon(ConsequenceKind kind) => switch (kind) {
        ConsequenceKind.money => Icons.payments_rounded,
        ConsequenceKind.points => Icons.shield_outlined,
        ConsequenceKind.people => Icons.people_alt_rounded,
        ConsequenceKind.info => Icons.info_outline_rounded,
      };
}

class _Line extends StatelessWidget {
  final Consequence line;

  const _Line({required this.line});

  @override
  Widget build(BuildContext context) {
    final color = ConsequenceCard._color(line.tone);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Icon(ConsequenceCard._icon(line.kind), size: 15.sp,
              color: color),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            line.text,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12.sp,
              height: 1.6,
              color: line.tone == ConsequenceTone.neutral
                  ? MyColors.textSecondary
                  : MyColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
