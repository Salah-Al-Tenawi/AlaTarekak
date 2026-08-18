import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/constant/address.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

/// اختيار المحافظة من ورقة سفلية.
///
/// كان لكل شاشة اختيارها: ورقة سفلية مرتّبة في «تعديل المعلومات»، و
/// `DropdownButtonFormField` في إنشاء الحساب — قائمة النظام الرمادية
/// تفتح فوق الحقل وتقصّ أسماء المحافظات الطويلة. الشكل واحد الآن.
///
/// يعيد المحافظة المختارة، أو `null` إن أُغلقت الورقة بلا اختيار.
Future<String?> showProvincePicker(
  BuildContext context, {
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ProvinceSheet(selected: selected),
  );
}

class ProvinceSheet extends StatelessWidget {
  final String? selected;

  const ProvinceSheet({super.key, this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(0, 12.h, 0, 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: MyColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: MyColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.location_on_outlined,
                      color: MyColors.primary, size: 17.sp),
                ),
                SizedBox(width: 10.w),
                Text('اختر المحافظة', style: AppTextStyles.titleMedium),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          const Divider(height: 0, thickness: 0.5),
          ConstrainedBox(
            // نصف الشاشة: تبقى المحافظة المختارة والعنوان ظاهرين معاً
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: syrianProvinces.length,
              separatorBuilder: (_, _) => const Divider(
                  height: 0, thickness: 0.5, indent: 16, endIndent: 16),
              itemBuilder: (ctx, i) {
                final province = syrianProvinces[i];
                final isSelected = province == selected;

                return ListTile(
                  title: Text(
                    province,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? MyColors.primary
                          : MyColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded,
                          color: MyColors.primary, size: 20.sp)
                      : null,
                  onTap: () => Navigator.pop(ctx, province),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// حقل المحافظة: يفتح [ProvinceSheet] عند الضغط.
///
/// `FormField` لا `GestureDetector` مجرّد: شاشة إنشاء الحساب تتحقّق من
/// حقولها دفعةً واحدة عند الضغط على «إنشاء»، فيجب أن يشارك هذا الحقل في
/// التحقّق ويعرض خطأه في مكانه كبقية الحقول.
class ProvinceField extends FormField<String> {
  ProvinceField({
    super.key,
    String? value,
    required ValueChanged<String> onChanged,
    String hint = 'اختر المحافظة',
    bool required = true,
  }) : super(
          initialValue: value,
          validator: required
              ? (v) => (v == null || v.isEmpty)
                  ? 'الرجاء اختيار المحافظة'
                  : null
              : null,
          builder: (field) {
            final selected = field.value;
            final hasValue = selected != null && selected.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () async {
                    final picked = await showProvincePicker(
                      field.context,
                      selected: selected,
                    );
                    if (picked == null) return;
                    field.didChange(picked);
                    onChanged(picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 15.h),
                    decoration: BoxDecoration(
                      color: MyColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: field.hasError
                            ? MyColors.error
                            : MyColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 20.sp,
                            color: hasValue
                                ? MyColors.primary
                                : MyColors.textHint),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            hasValue ? selected : hint,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: hasValue
                                  ? MyColors.textPrimary
                                  : MyColors.textHint,
                            ),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: MyColors.textHint, size: 20.sp),
                      ],
                    ),
                  ),
                ),
                if (field.hasError)
                  Padding(
                    padding: EdgeInsets.only(top: 6.h, right: 12.w),
                    child: Text(
                      field.errorText!,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: MyColors.error),
                    ),
                  ),
              ],
            );
          },
        );
}
