import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/class/syrian_phone.dart';

/// حقل رقم هاتف سوري — بمفتاح `963+` مثبَّت على يساره.
///
/// التطبيق يطلب الرقم في أربعة مواضع (إنشاء الحساب، تفعيل المحفظة، إنشاء
/// رحلة، حجز مقعد)، وكان كل موضع يكتب حقله بنفسه: أحدهم يعرض صيغة
/// متوقَّعة وثلاثة لا، وأربعتهم بلا ما يقول إن الرقم **سوري حصراً** —
/// فيكتشفه المستخدم من رفض الخادم بعد أن يملأ النموذج.
///
/// الاختلاف بين المواضع شكليّ (لون الحشو، مؤشّر، سطر مساعد) لا في معنى
/// الحقل، فهو هنا واحد ويُمرَّر الشكل وسيطاً.
///
/// **الاتجاه:** الحقل وحده LTR وسط شاشة عربية. مع اتجاه الشاشة يقع
/// `prefixIcon` يميناً، ولو نُقل يساراً بـ `suffixIcon` لانفصل عن الأرقام
/// بعرض الحقل كلّه فلم يُقرآ رقماً واحداً.
///
/// **القبول:** [SyrianPhone] يقبل `0988626577` و`988626577` و`963...`
/// معاً — عرقلة من كتب رقمه كما يحفظه ليست تحقّقاً. والتطبيع إلى صيغة
/// الخادم يقع في مصادر البيانات.
class SyrianPhoneField extends StatelessWidget {
  final TextEditingController controller;

  /// مؤشّر على يمين الحقل — مثل علامة الصحّة في إنشاء الرحلة.
  final Widget? suffixIcon;

  /// سطر تحت الحقل يشرح الصيغ المقبولة.
  final String? helperText;

  final Color? fillColor;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  const SyrianPhoneField({
    super.key,
    required this.controller,
    this.suffixIcon,
    this.helperText,
    this.fillColor,
    this.enabled = true,
    this.onChanged,
    this.onFieldSubmitted,
  });

  /// التلميح داخل الحقل. يُسمّي المطلوب ولا يرسم صيغته: المفتاح `963+`
  /// أمامه يقول إن الرقم سوري، والصيغ المقبولة أوسع من قالب واحد
  /// (انظر [SyrianPhone]) فرسمُ واحدة منها يوحي بأنها الوحيدة.
  static const String hint = 'رقم الهاتف';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.phone,
        // المفتاح مكتوب أمامه فلا حاجة لسواه. ولصق «+963988626577» يمرّ
        // رغم الفلتر: تُحذف `+` ويقرأ [SyrianPhone] الباقي `963...`.
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: MyColors.textPrimary,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'الرجاء إدخال رقم الهاتف';
          }
          return SyrianPhone.isValid(value) ? null : SyrianPhone.error;
        },
        decoration: InputDecoration(
          hintText: hint,
          helperText: helperText,
          helperStyle: TextStyle(fontSize: 11.sp, color: MyColors.textHint),
          filled: fillColor != null,
          fillColor: fillColor,
          suffixIcon: suffixIcon,
          // prefixIcon لا prefix: الثاني لا يظهره Flutter ما دام الحقل
          // فارغاً غير مركَّز — وهي اللحظة التي يجب أن يُرى فيها.
          prefixIcon: const _CountryCodeAffix(),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }
}

/// `963+` مع فاصل يقول إنه جزء ثابت من الحقل لا نصّ كتبه المستخدم.
class _CountryCodeAffix extends StatelessWidget {
  const _CountryCodeAffix();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 14.w),
        Icon(Icons.phone_outlined, size: 18.sp, color: MyColors.textHint),
        SizedBox(width: 8.w),
        Text(
          '+963',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: MyColors.textPrimary,
          ),
        ),
        SizedBox(width: 10.w),
        Container(width: 1, height: 22.h, color: MyColors.border),
        SizedBox(width: 10.w),
      ],
    );
  }
}
