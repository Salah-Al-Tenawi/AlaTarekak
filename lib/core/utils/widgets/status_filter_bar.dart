import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:alatarekak/core/them/my_colors.dart';

/// شريط تصنيف أعلى القوائم — مصدر واحد لـ«حجوزاتي» و«رحلاتي».
///
/// كانت كل شاشة ستبني رقاقاتها بنفسها، فتختلف الأنصاف والحدود والوزن
/// بينها كما اختلفت بطاقات الرحلة قبل [trip_card_parts]. الشكل هنا واحد:
/// رقاقة بلون مجموعتها وعدّادها، والمختارة مصمتة بلونها.
///
/// الشريط يمرّر أفقياً بدل أن يُضغط في عرض الشاشة: خمس رقاقات عربية
/// أعرض من أي هاتف، وضغطها يجعل النصّ يتكسّر أو يُقصّ.

/// خيار واحد في [StatusFilterBar].
class StatusFilterOption {
  final String label;

  /// لون المجموعة — يُؤخذ من لون شارة حالتها حيثما أمكن، فلا يختلف لون
  /// الرقاقة عن لون الشارة داخل البطاقة.
  final Color color;

  final IconData icon;

  /// عدد عناصر المجموعة — يُعرض داخل الرقاقة، ويُخفى حين يكون صفراً.
  final int count;

  final bool isSelected;
  final VoidCallback onTap;

  const StatusFilterOption({
    required this.label,
    required this.color,
    required this.icon,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });
}

class StatusFilterBar extends StatelessWidget {
  final List<StatusFilterOption> options;

  const StatusFilterBar({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46.h,
      // صفّ كامل البناء لا قائمة كسولة: الخيارات قليلة ثابتة، والبناء
      // الكسول كان يترك آخرها غير مبنيّ فلا يصله التمرير البرمجي ولا
      // قارئ الشاشة.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        child: Row(
          children: [
            for (final option in options) ...[
              if (option != options.first) SizedBox(width: 6.w),
              _FilterChip(option: option),
            ],
          ],
        ),
      ),
    );
  }
}

/// رقاقة مجموعة واحدة. المختارة مصمتة بلونها، وغيرها شفافة منه — الفرق
/// بينهما في اللون والوزن معاً لا في الحدّ وحده، ليُقرأ الاختيار بلمحة.
class _FilterChip extends StatelessWidget {
  final StatusFilterOption option;

  const _FilterChip({required this.option});

  @override
  Widget build(BuildContext context) {
    final color = option.color;
    final isSelected = option.isSelected;
    final radius = BorderRadius.circular(24.r);
    // مجموعة فارغة تبقى قابلة للضغط لكنها تخفت: وجودها يخبر أنه لا شيء
    // فيها، وإخفاؤها يجعل الشريط يرقص كلما تغيّرت القائمة.
    final dimmed = option.count == 0 && !isSelected;

    return Semantics(
      button: true,
      selected: isSelected,
      // عقدة واحدة تحمل التسمية والعدّاد معاً — وأبناؤها مستثنون من
      // الدلالات وحدهم (لا الشجرة كلها) فيقرأ قارئ الشاشة «ملغاة، 2»
      // مرّة واحدة، ويبقى فعلا الضغط والتركيز من `InkWell` قائمَين.
      container: true,
      label: '${option.label}، ${option.count}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: option.onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.08),
              borderRadius: radius,
              border: Border.all(
                color: isSelected
                    ? color
                    : color.withValues(alpha: dimmed ? 0.12 : 0.25),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option.icon,
                    size: 14.sp,
                    color: isSelected
                        ? MyColors.textOnDark
                        : color.withValues(alpha: dimmed ? 0.45 : 1),
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? MyColors.textOnDark
                          : color.withValues(alpha: dimmed ? 0.45 : 1),
                    ),
                  ),
                  if (option.count > 0) ...[
                    SizedBox(width: 5.w),
                    _CountBadge(
                      count: option.count,
                      color: color,
                      onColor: isSelected,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// عدّاد صغير داخل الرقاقة.
class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  /// الرقاقة مختارة — فالعدّاد يُرسم على لونها المصمت لا على الخلفية.
  final bool onColor;

  const _CountBadge({
    required this.count,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: onColor
            ? MyColors.textOnDark.withValues(alpha: 0.22)
            : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.bold,
          color: onColor ? MyColors.textOnDark : color,
        ),
      ),
    );
  }
}
