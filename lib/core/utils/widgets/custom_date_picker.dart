import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  return await showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DatePickerSheet(
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime.now(),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
    ),
  );
}

class _DatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _DatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime _selected;

  static const _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  static const _quickLabels = ['اليوم', 'غداً', 'بعد يومين'];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          color: MyColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, bottomPadding + 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ━━ Handle ━━
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MyColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              SizedBox(height: 20.h),

              // ━━ العنوان ━━
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: MyColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_rounded,
                        color: MyColors.primary, size: 20),
                  ),
                  SizedBox(width: 10.w),
                  Text('اختر تاريخ الرحلة', style: AppTextStyles.titleMedium),
                ],
              ),

              SizedBox(height: 16.h),

              // ━━ Quick select ━━
              Row(
                children: List.generate(_quickLabels.length, (i) {
                  final day = today.add(Duration(days: i));
                  final isSelected = DateTime(
                        _selected.year,
                        _selected.month,
                        _selected.day,
                      ) ==
                      day;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: i < 2 ? 8.w : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? MyColors.primary
                                : MyColors.background,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? MyColors.primary
                                  : MyColors.border,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _quickLabels[i],
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : MyColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '${day.day}/${day.month}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected
                                      ? Colors.white70
                                      : MyColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              SizedBox(height: 12.h),

              const Divider(),

              // ━━ التقويم ━━
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: MyColors.primary,
                    onPrimary: Colors.white,
                    surface: MyColors.surface,
                    onSurface: MyColors.textPrimary,
                  ),
                ),
                child: Localizations.override(
                  context: context,
                  locale: const Locale('ar'),
                  child: CalendarDatePicker(
                    initialDate: _selected,
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    onDateChanged: (date) => setState(() => _selected = date),
                  ),
                ),
              ),

              SizedBox(height: 8.h),

              // ━━ التاريخ المختار ━━
              Container(
                width: double.infinity,
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: MyColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: MyColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded,
                        color: MyColors.accent, size: 18),
                    SizedBox(width: 8.w),
                    Text(
                      _formatDate(_selected),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: MyColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // ━━ زر التأكيد ━━
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                  child:
                      Text('تأكيد التاريخ', style: AppTextStyles.buttonLarge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
